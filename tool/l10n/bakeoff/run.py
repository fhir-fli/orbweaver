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

import segments

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.abspath(os.path.join(HERE, '..', '..', '..'))
PROMPT = open(os.path.join(HERE, 'prompt.md')).read()
PAGES = [l.strip() for l in open(os.path.join(HERE, 'pages.txt')) if l.strip()]
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
    client = genai.Client(api_key=key('GOOGLE_API_KEY'))
    r = client.models.generate_content(model=model, contents=PROMPT + page_text)
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
        if backend == 'haiku':
            raw, tin, tout = call_haiku(text)
        elif backend.startswith('gemini:'):
            raw, tin, tout = call_gemini(backend.split(':', 1)[1], text)
        elif backend.startswith('ollama:'):
            raw, tin, tout = call_ollama(backend.split(':', 1)[1], text)
        else:
            raise SystemExit(f'unknown backend {backend}')
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
