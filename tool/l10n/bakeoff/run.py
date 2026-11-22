#!/usr/bin/env python3
"""Translation test: send the same pages, with the same prompt, to one model.

Only the page's text goes to the model, as {id: text} JSON (segments.py);
the structure is copied from the English file, never from the model.

    .venv/bin/python run.py haiku        # Claude Haiku 5.5 (API)
    .venv/bin/python run.py gemini:<model-id>
    .venv/bin/python run.py ollama:<model-tag>   # local, via `ollama serve`

Writes each page to outputs/<label>/<file>.yaml as it finishes, runs the
structural/safety checker on it, and appends one row per page to
results.tsv (label, page, seconds, input/output tokens, checker problems).
Keys are read from the graiai .env files Grey pointed to; never printed.
Run from orbweaver/tool/l10n/bakeoff/.
"""
import hashlib
import json
import os
import re
import subprocess
import sys
import time
import urllib.request

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), '..'))
import segments  # tool/l10n/segments.py

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.abspath(os.path.join(HERE, '..', '..', '..'))
PROMPT = open(os.path.join(HERE, 'prompt.md')).read()
PAGES = [l.strip() for l in open(os.path.join(HERE, 'pages.txt')) if l.strip()]
# The three WHO pages in pages.txt were run once (2026-11-21) before we read that
# WHO licence 202610340 excludes translation (WHO-LICENCE.md, "Translating: No").
# Their outputs were removed; never send WHO text to a model again without a licence.
_who = [p for p in PAGES if '/who_imci/' in p]
if _who:
    print(f'skipping {len(_who)} WHO pages: WHO licence does not cover translation', flush=True)
    PAGES = [p for p in PAGES if p not in _who]
ENV = '/home/grey/dev/graiai/thalamus/.env'


def key(name):
    for line in open(ENV):
        m = re.match(r'\s*([A-Z_]+)\s*=\s*(.*?)\s*$', line)
        if m and m.group(1) == name:
            return m.group(2).strip('"\'')
    raise SystemExit(f'{name} not in {ENV}')


def strip_fences(text):
    t = text.strip()
    m = re.match(r'^```[a-zA-Z]*\n(.*)\n```$', t, re.S)
    return m.group(1) if m else t


def call_haiku(page_text):
    import anthropic
    client = anthropic.Anthropic(api_key=key('ANTHROPIC_API_KEY'))
    with client.messages.stream(
        model='claude-haiku-5-5',
        max_tokens=32000,
        messages=[{'role': 'user', 'content': PROMPT + page_text}],
    ) as stream:
        msg = stream.get_final_message()
    if msg.stop_reason != 'end_turn':
        print(f'  stop_reason={msg.stop_reason}', flush=True)
    text = ''.join(b.text for b in msg.content if b.type == 'text')
    return text, msg.usage.input_tokens, msg.usage.output_tokens


def call_gemini(model, page_text):
    from google import genai
    # Grey's AI Studio key, kept out of every repo.
    env = open(os.path.expanduser('~/.config/orbweaver-l10n/keys.env')).read()
    client = genai.Client(api_key=re.search(r'GEMINI_API_KEY=(\S+)', env).group(1))
    # Free-tier models answer 503 "high demand" often; wait and try again,
    # up to ~1 hour per page, logging each wait.
    for attempt in range(12):
        try:
            r = client.models.generate_content(model=model, contents=PROMPT + page_text)
            break
        except Exception as e:
            if '503' not in str(e) or attempt == 11:
                raise
            wait = min(60 * 2 ** attempt, 600)
            print(f'  503, retry {attempt + 1} in {wait}s', flush=True)
            time.sleep(wait)
    u = r.usage_metadata
    return r.text, u.prompt_token_count, u.candidates_token_count


def call_ollama(tag, page_text):
    body = json.dumps({
        'model': tag,
        'prompt': PROMPT + page_text,
        'stream': False,
        'think': False,
        # Gemma 4 card settings (see model_notes.md).
        'options': {'num_ctx': 16384, 'temperature': 1.0, 'top_p': 0.95,
                    'top_k': 64},
    }).encode()
    req = urllib.request.Request('http://127.0.0.1:11434/api/generate', body,
                                 {'Content-Type': 'application/json'})
    r = json.load(urllib.request.urlopen(req, timeout=7200))
    return r['response'], r.get('prompt_eval_count', 0), r.get('eval_count', 0)


def call_litert(model_file, page_text):
    """Gemma through LiteRT-LM on the CPU, the runtime graiai uses for the
    same .litertlm files. Sampling and thinking as in model_notes.md.
    Token counts are not reported by the CLI; 0 is written."""
    cmd = [os.path.expanduser('~/.local/bin/uv'), 'tool', 'run', '--from',
           'litert-lm==0.19.0', 'litert-lm', 'run',
           f'/home/grey/dev/graiai/models/{model_file}.litertlm',
           '--backend', 'cpu', '--thinking', 'false', '--cache', 'memory',
           '--max-num-tokens', '8192', '--temperature', '1.0', '--top-p',
           '0.95', '--top-k', '64', '--prompt', PROMPT + page_text]
    r = subprocess.run(cmd, capture_output=True, text=True, timeout=7200,
                       env={**os.environ, 'LLVM_PROFILE_FILE': '/dev/null'})
    if r.returncode != 0 or not r.stdout.strip():
        raise RuntimeError(f'litert-lm exit {r.returncode}: {r.stderr.strip()[-200:]}')
    return r.stdout, 0, 0


def call(backend, text):
    if backend.startswith('litert:'):
        return call_litert(backend.split(':', 1)[1], text)
    if backend == 'haiku':
        return call_haiku(text)
    if backend.startswith('gemini:'):
        return call_gemini(backend.split(':', 1)[1], text)
    if backend.startswith('ollama:'):
        return call_ollama(backend.split(':', 1)[1], text)
    raise SystemExit(f'unknown backend {backend}')


def main():
    backend = sys.argv[1]
    label = re.sub(r'[^A-Za-z0-9._-]', '_', backend)
    outdir = os.path.join(HERE, 'outputs', label)
    os.makedirs(outdir, exist_ok=True)
    results = open(os.path.join(HERE, 'results.tsv'), 'a')
    for page in PAGES:
        english = os.path.join(REPO, page)
        out = os.path.join(outdir, os.path.basename(page))
        if os.path.exists(out):
            print(f'skip {page} (done)', flush=True)
            continue
        source = segments.extract(english)
        text = json.dumps(source, ensure_ascii=False, indent=1)
        t0 = time.time()
        try:
            raw, tin, tout = call(backend, text)
        except Exception as e:  # an API refusal or outage is a result row, not a crash
            msg = str(e).splitlines()[0][:200]
            results.write(f'{label}\t{page}\t{time.time() - t0:.1f}\t0\t0\tapi-error: {msg}\n')
            results.flush()
            print(f'{page}: api error: {msg}', flush=True)
            continue
        secs = time.time() - t0
        stamp = hashlib.sha256(open(english, 'rb').read()).hexdigest()
        with open(out + '.raw.txt', 'w') as f:
            f.write(raw)
        try:
            translated = json.loads(strip_fences(raw))
            if sorted(translated) != sorted(source):
                raise ValueError(f'ids differ: {sorted(set(source) ^ set(translated))}')
            page_yaml = segments.reinsert(english, translated)
        except ValueError as e:  # JSONDecodeError is a ValueError
            results.write(f'{label}\t{page}\t{secs:.1f}\t{tin}\t{tout}\tbad-reply: {e}\n')
            results.flush()
            print(f'{page}: bad reply: {e}', flush=True)
            continue
        with open(out, 'w') as f:
            f.write(f'# translated-from-sha256: {stamp}\n{page_yaml}')
            f.flush()
        chk = subprocess.run(['dart', 'run', 'tool/l10n/check_pair.dart', english, out],
                             cwd=REPO, capture_output=True, text=True)
        with open(out + '.check.txt', 'w') as f:
            f.write(chk.stdout + chk.stderr)
        m = re.search(r'problems: (\d+)', chk.stdout)
        problems = m.group(1) if m else 'unparsable'
        results.write(f'{label}\t{page}\t{secs:.1f}\t{tin}\t{tout}\t{problems}\n')
        results.flush()
        print(f'{page}: {secs:.1f}s in={tin} out={tout} problems={problems}', flush=True)


if __name__ == '__main__':
    main()
