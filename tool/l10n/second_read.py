#!/usr/bin/env python3
"""Independent second read of the Spanish translation by Gemma 4 31B.

Each page's reader-visible strings go to the model as English/Spanish pairs
(review_prompt.md); it answers a JSON list of meaning problems. One file per
page under tool/l10n/second_read/, written as soon as the page is done, so a
stopped run resumes where it left off. Every page also gets a row in
tool/l10n/second_read/summary.tsv.

    tool/l10n/bakeoff/.venv/bin/python tool/l10n/second_read.py [--limit N]

Pages: every page es.py translates (WHO is not among them: licence 202610340
does not cover translation, so no WHO text goes to a model). Pairs where the
Spanish has no letters are skipped (numbers and signs the checker already
compares). Long pages go in chunks of CHUNK pairs.

Model: gemma-4-31b-it on the Gemini API (free tier), API default sampling,
as in tool/l10n/bakeoff/model_notes.md. The free tier answers 503 "high
demand" often; each call retries with backoff up to ~1 hour.

The regexes here are case-sensitive on purpose: they match an environment
variable name and a code fence, not prose.
"""
import json
import os
import re
import sys
import time

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import es  # noqa: E402
import segments  # noqa: E402

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = es.REPO
OUT = os.path.join(HERE, 'second_read')
MODEL = 'gemma-4-31b-it'
CHUNK = 80
PROMPT = open(os.path.join(HERE, 'review_prompt.md')).read()


def client():
    from google import genai
    env = open(os.path.expanduser('~/.config/orbweaver-l10n/keys.env')).read()
    return genai.Client(api_key=re.search(r'GEMINI_API_KEY=(\S+)', env).group(1))


def ask(c, pairs):
    body = PROMPT + json.dumps(pairs, ensure_ascii=False, indent=1)
    for attempt in range(12):
        try:
            r = c.models.generate_content(model=MODEL, contents=body)
            return r.text or ''
        except Exception as e:
            msg = str(e)
            if not any(code in msg for code in ('503', '429', '500')) or attempt == 11:
                raise
            wait = min(60 * 2 ** attempt, 600)
            print(f'  {msg[:40]!r}, retry {attempt + 1} in {wait}s', flush=True)
            time.sleep(wait)
    return ''


def parse(text):
    t = text.strip()
    m = re.match(r'^```[a-zA-Z]*\n(.*)\n```$', t, re.S)
    t = m.group(1) if m else t
    return json.loads(t)


def pages():
    return [e for e in es.english_pages()
            if os.path.exists(os.path.join(REPO, es.target(e)))]


def main():
    limit = int(sys.argv[sys.argv.index('--limit') + 1]) if '--limit' in sys.argv else None
    os.makedirs(OUT, exist_ok=True)
    summary = os.path.join(OUT, 'summary.tsv')
    if not os.path.exists(summary):
        with open(summary, 'w') as f:
            f.write('page\tpairs\tchunks\tseconds\tfindings\tpatient_safety\terror\n')
    c = client()
    done = 0
    todo = pages()
    print(f'{len(todo)} pages', flush=True)
    for english in todo:
        name = english.replace('assets/', '').replace('books/', '').replace('/', '__')
        path = os.path.join(OUT, name + '.json')
        if os.path.exists(path):
            continue
        if limit is not None and done >= limit:
            break
        en = segments.extract(os.path.join(REPO, english))
        tr = segments.extract(os.path.join(REPO, es.target(english)))
        pairs = {k: {'en': en[k], 'es': tr[k]} for k in en if es.has_letter(tr[k])}
        ids = list(pairs)
        findings, raw, err = [], [], ''
        t0 = time.time()
        try:
            for i in range(0, len(ids), CHUNK):
                part = {k: pairs[k] for k in ids[i:i + CHUNK]}
                text = ask(c, part)
                raw.append(text)
                for f in parse(text):
                    if f.get('id') in part:
                        f['en'] = part[f['id']]['en']
                        f['es'] = part[f['id']]['es']
                    findings.append(f)
        except Exception as e:  # recorded; the page is left for a rerun
            err = str(e)[:200].replace('\t', ' ').replace('\n', ' ')
        secs = time.time() - t0
        n_chunks = (len(ids) + CHUNK - 1) // CHUNK
        if not err:
            with open(path, 'w') as f:
                json.dump({'page': english, 'model': MODEL, 'findings': findings, 'raw': raw},
                          f, ensure_ascii=False, indent=1)
        ps = sum(1 for f in findings if f.get('severity') == 'patient-safety')
        with open(summary, 'a') as f:
            f.write(f'{english}\t{len(ids)}\t{n_chunks}\t{secs:.0f}\t{len(findings)}\t{ps}\t{err}\n')
        print(f'{english}: {len(ids)} pairs, {len(findings)} findings ({ps} patient-safety), '
              f'{secs:.0f}s {err}', flush=True)
        done += 1


if __name__ == '__main__':
    main()
