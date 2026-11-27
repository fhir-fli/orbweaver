#!/usr/bin/env python3
"""Write review/<page>.md: each text piece in English, then each model's
Spanish, for reading by eye. Short pieces (< 25 chars) are grouped at the
end. Run from tool/l10n/bakeoff/."""
import json, os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), '..'))
import segments  # tool/l10n/segments.py
HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.abspath(os.path.join(HERE, '..', '..', '..'))
MODELS = ['haiku', 'gemini_gemini-3.1-flash-lite', 'gemini_gemma-4-31b-it', 'litert_gemma-4-E4B-it', 'opus-5-5-conversation']
os.makedirs(os.path.join(HERE, 'review'), exist_ok=True)
for page in open(os.path.join(HERE, 'pages.txt')).read().split():
    name = os.path.basename(page)
    en = segments.extract(os.path.join(REPO, page))
    tr = {}
    for m in MODELS:
        f = os.path.join(HERE, 'outputs', m, name)
        if os.path.exists(f):
            tr[m] = segments.extract(f)
    with open(os.path.join(HERE, 'review', name + '.md'), 'w') as out:
        out.write(f'# {page}\n\n')
        for k, v in en.items():
            if len(v) < 25:
                continue
            out.write(f'## {k}\nEN: {v.strip()}\n')
            for m, t in tr.items():
                out.write(f'{m}: {t[k].strip()}\n')
            out.write('\n')
        out.write('## short pieces\n')
        for k, v in en.items():
            if len(v) < 25:
                out.write(f'{k} EN={v!r} ' + ' | '.join(f'{m[:8]}={t[k]!r}' for m, t in tr.items()) + '\n')
        out.flush()
    print(name, list(tr), flush=True)
