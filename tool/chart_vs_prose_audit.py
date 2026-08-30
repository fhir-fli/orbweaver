#!/usr/bin/env python3
"""Compare a chart against the prose on its OWN page.

The move that has found the worst errors in this project is comparing the book
against itself. Across books it found a wrong IV diazepam dose that two review
cycles had confirmed. Within a page it should find the same class: a chart that
says one thing and the paragraph beside it another.

For every ProtocolBook topic that carries both a flowchart and prose or table
blocks, this pulls the doses out of each side separately, keyed by drug and
unit, and reports where the two sides carry values the other does not.

A difference is not a contradiction. Prose routinely elaborates what a chart
states briefly — a chart node saying "adrenaline" and a paragraph giving the
full weight-banded regimen is correct, not conflicting. What matters is the
same drug, same unit, with genuinely different numbers on the two sides.

Output is written and flushed per topic.
"""

import io
import os
import re
import sys
from collections import defaultdict

import yaml

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import crossbook_dose_extract as ex  # noqa: E402

ROOT = '/home/grey/dev/fhir/orbweaver/assets/books'
# 2026-08-30: this only ever ran over the ProtocolBook. WHO and WVEMS have
# charts sitting beside prose on the same page too, and the comparison is
# exactly as meaningful there. WVEMS is included DELIBERATELY: the rule that
# its figures are strict forbids comparing them to the OTHER books, not to the
# prose on its own page. A WVEMS chart disagreeing with its own paragraph is a
# transcription error in our copy, which is ours to fix.
BOOKS = ('protocolbook', 'who_imci', 'wvems')
OUT = '/home/grey/dev/fhir/orbweaver/tool/crossbook/chart_vs_prose.tsv'

DASH = chr(0x2013)
WEAK = {'ml', 'mg/ml', 'mcg/ml', 'gm', 'mmhg', 'mmol/l', 'iu', 'units',
        'ml/hr', 'ml/h', 'g'}


def num(v):
    try:
        return float(v.split('-')[0].split(DASH)[0])
    except ValueError:
        return None


def doses_of(node, patterns):
    """Every (drug, unit, value) in one block, attached nearest-mention."""
    units = []
    ex.collect(node, [], units)
    found = defaultdict(set)
    carry = [None, None]
    for frag, ctx in units:
        hits = list(ex.DOSE_RE.finditer(frag))
        if not hits:
            continue
        mentions = []
        claimed = []
        for pat, canon in patterns:
            for m in pat.finditer(frag):
                if any(m.start() < e and s < m.end() for s, e in claimed):
                    continue
                claimed.append((m.start(), m.end()))
                if ex.NOT_A_PRESCRIPTION.search(frag[m.end():m.end() + 24]):
                    continue
                mentions.append((m.start(), canon))
        mentions.sort()
        ctx_drug = None
        for head in reversed(ctx):
            for pat, canon in patterns:
                if pat.search(head):
                    ctx_drug = canon
                    break
            if ctx_drug:
                break
        if mentions:
            carry = [mentions[-1][1], ctx]
        for m in hits:
            before = [c for p, c in mentions if p < m.start()]
            after = [c for p, c in mentions if p > m.start()]
            drug = (before[-1] if before else
                    after[0] if after else
                    ctx_drug if ctx_drug else
                    carry[0] if carry[1] == ctx else None)
            if drug:
                found[(drug, m.group(2).lower())].add(m.group(1).strip())
    return found


def main():
    vocab = ex.build_vocab()
    patterns = [(re.compile(r'(?<![\w-])' + re.escape(f) + r'(?![\w-])', re.I),
                 c)
                for f, c in sorted(((f, c) for c, fs in vocab.items()
                                    for f in fs), key=lambda x: -len(x[0]))]

    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    fh = io.open(OUT, 'w', encoding='utf-8')
    fh.write('book\tfile\tdrug\tunit\tin_chart_only\tin_prose_only\tshared'
             '\tratio\n')
    fh.flush()
    n_top = n_hit = 0

    files = []
    for book in BOOKS:
        d = os.path.join(ROOT, book, 'topics')
        if not os.path.isdir(d):
            continue
        for name in sorted(os.listdir(d)):
            if name.endswith('.yaml'):
                files.append((book, name, os.path.join(d, name)))

    for book, name, path in files:
        with io.open(path, encoding='utf-8') as f:
            doc = yaml.safe_load(f)
        charts, prose = [], []

        def walk(x):
            if isinstance(x, dict):
                t = x.get('type')
                if t == 'flowchart':
                    charts.append(x)
                elif t in ('prose', 'table'):
                    prose.append(x)
                for v in x.values():
                    walk(v)
            elif isinstance(x, list):
                for v in x:
                    walk(v)
        walk(doc)
        if not charts or not prose:
            continue
        n_top += 1

        c = defaultdict(set)
        for ch in charts:
            for k, vs in doses_of(ch, patterns).items():
                c[k] |= vs
        p = defaultdict(set)
        for pr in prose:
            for k, vs in doses_of(pr, patterns).items():
                p[k] |= vs

        for key in sorted(set(c) & set(p)):
            drug, unit = key
            if unit in WEAK:
                continue
            only_c, only_p = c[key] - p[key], p[key] - c[key]
            if not only_c or not only_p:
                continue
            allv = [num(v) for v in (c[key] | p[key])]
            allv = [v for v in allv if v]
            if not allv:
                continue
            ratio = max(allv) / min(allv)
            if ratio < 1.5:
                continue
            fh.write('%s\t%s\t%s\t%s\t%s\t%s\t%s\t%.1f\n'
                     % (book, name, drug, unit, ', '.join(sorted(only_c)),
                        ', '.join(sorted(only_p)),
                        ', '.join(sorted(c[key] & p[key])), ratio))
            fh.flush()
            n_hit += 1
            print('  %-4s %-30s %-15s %-11s chart:%-16s prose:%-16s x%.1f'
                  % (book[:4], name[:30], drug[:15], unit, ', '.join(sorted(only_c))[:18],
                     ', '.join(sorted(only_p))[:18], ratio), flush=True)
    fh.close()
    print('DONE: %d topics compared, %d chart-vs-prose differences -> %s'
          % (n_top, n_hit, OUT), flush=True)


if __name__ == '__main__':
    sys.exit(main())
