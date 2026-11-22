#!/usr/bin/env python3
"""Spanish translation of the book pages, done by hand in a Claude session.

Only the reader-visible text is handled ({id: text}, segments.py); the YAML
structure is always copied from the English file. Every file written is
checked with tool/l10n/check_pair.dart, the same comparison the test suite
runs, and stamped with the sha256 of the English it was made from.

    python tool/l10n/es.py status
    python tool/l10n/es.py next <out.json> [N] [--book B]
        writes the text of the next N untranslated pages (missing, or the
        English changed since) as {"<english path>": {"s1": ...}, ...}
    python tool/l10n/es.py apply <translated.json>
        same shape back; writes topics/es/<file>.yaml for each, checks them,
        appends one row per page to tool/l10n/es_progress.tsv

Run with tool/l10n/bakeoff/.venv/bin/python (needs ruamel.yaml), from the
repo root.
"""
import hashlib
import json
import os
import re
import subprocess
import sys
import time

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import segments  # noqa: E402

REPO = os.path.abspath(os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..'))
BOOKS = ['calculators', 'protocolbook', 'wvems', 'who_imci']
LOG = os.path.join(REPO, 'tool', 'l10n', 'es_progress.tsv')


def sha(path):
    with open(os.path.join(REPO, path), 'rb') as f:
        return hashlib.sha256(f.read()).hexdigest()


def target(english):
    d, n = os.path.split(english)
    return os.path.join(d, 'es', n)


def english_pages(book=None):
    out = []
    for b in BOOKS:
        if book and b != book:
            continue
        d = f'assets/books/{b}/topics'
        out += sorted(f'{d}/{n}' for n in os.listdir(os.path.join(REPO, d)) if n.endswith('.yaml'))
    return out


def state(english):
    t = os.path.join(REPO, target(english))
    if not os.path.exists(t):
        return 'missing'
    with open(t) as f:
        m = re.match(r'# translated-from-sha256: ([0-9a-f]{64})', f.readline())
    return 'current' if m and m.group(1) == sha(english) else 'stale'


def cmd_status():
    for b in BOOKS:
        pages = english_pages(b)
        counts = {}
        for p in pages:
            s = state(p)
            counts[s] = counts.get(s, 0) + 1
        print(b, len(pages), counts, flush=True)


def cmd_next(out, n, book):
    todo = [p for p in english_pages(book) if state(p) != 'current'][:n]
    # Strings with no letters are left out; apply copies them unchanged.
    dump = {p: {k: v for k, v in segments.extract(os.path.join(REPO, p)).items()
                if re.search(r'[^\W\d_]', v)} for p in todo}
    with open(out, 'w') as f:
        json.dump(dump, f, ensure_ascii=False, indent=1)
        f.flush()
    for p in todo:
        print(p, os.path.getsize(os.path.join(REPO, p)), flush=True)


def cmd_apply(src):
    with open(src) as f:
        pages = json.load(f)
    pairs = []
    for english, tr in pages.items():
        en_abs = os.path.join(REPO, english)
        want = segments.extract(en_abs)
        # A string with no letters (a number, range, sign or blank) is kept
        # as it is (prompt rule 6), so it may be left out of the JSON.
        for k, v in want.items():
            if k not in tr and not re.search(r'[^\W\d_]', v):
                tr[k] = v
        if sorted(tr) != sorted(want):
            print(f'{english}: ids differ {sorted(set(tr) ^ set(want))}', flush=True)
            continue
        out = os.path.join(REPO, target(english))
        os.makedirs(os.path.dirname(out), exist_ok=True)
        with open(out, 'w') as f:
            f.write(f'# translated-from-sha256: {sha(english)}\n' + segments.reinsert(en_abs, tr))
            f.flush()
        pairs += [english, target(english)]
    if not pairs:
        return
    r = subprocess.run(['dart', 'run', 'tool/l10n/check_pair.dart', *pairs], cwd=REPO,
                       capture_output=True, text=True)
    report = r.stdout + r.stderr
    blocks = re.split(r'^== ', report, flags=re.M) if len(pairs) > 2 else ['x\n' + report]
    with open(LOG, 'a') as log:
        for i, english in enumerate(pairs[0::2]):
            body = blocks[i + 1] if len(pairs) > 2 else blocks[0]
            m = re.search(r'problems: (\d+)', body)
            n = m.group(1) if m else 'unparsable'
            log.write(f'{time.strftime("%Y-%m-%d %H:%M")}\t{english}\t{n}\n')
            log.flush()
            print(f'{english}: problems {n}', flush=True)
            if n != '0':
                print(body, flush=True)


if __name__ == '__main__':
    a = sys.argv[1:]
    if a[:1] == ['status']:
        cmd_status()
    elif a[:1] == ['next']:
        book = a[a.index('--book') + 1] if '--book' in a else None
        rest = [x for x in a[1:] if x not in ('--book', book)]
        cmd_next(rest[0], int(rest[1]) if len(rest) > 1 else 1, book)
    elif a[:1] == ['apply']:
        cmd_apply(a[1])
    else:
        sys.exit(__doc__)
