#!/usr/bin/env python3
"""Cross-book comparison of DURATIONS and THRESHOLDS.

The dose pass compared how much. This compares **how long** and **at what
cutoff**, neither of which the dose extractor sees at all:

  * a duration — "for 5 days", "× 10 days", "for 2 weeks" — attached to the
    drug it belongs to, so the same drug for the same infection can be
    compared across the two books;
  * a threshold — SpO2 < 90%, temperature ≥ 37.5 °C, haemoglobin < 5 g/dL,
    glucose < 2.5 mmol/L — grouped by the QUANTITY rather than by a drug,
    because a cutoff belongs to a decision, not to a prescription.

Why it is worth running. The dose pass found a wrong IV diazepam dose that
two review cycles had confirmed, and a neonatal meningitis regimen dosed for
sepsis. A course that is five days in one book and ten in the other, or an
oxygen threshold of 90% against 94%, is the same class of defect and is
invisible to every instrument built so far.

🛑 WVEMS is excluded, for the reason recorded at the top of
crossbook_dose_extract.py: its figures are the original protocol's and are
strict.

Output is written and flushed per row.
"""

import io
import os
import re
import sys
from collections import defaultdict

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import crossbook_dose_extract as ex  # noqa: E402

OUTDIR = ex.OUTDIR
DUR_OUT = os.path.join(OUTDIR, 'durations.tsv')
THR_OUT = os.path.join(OUTDIR, 'thresholds.tsv')
REPORT = os.path.join(OUTDIR, 'rules_side_by_side.md')

# "for 7 days", "× 10 days", "x 5 days", "over 4 h", "for 2–3 weeks".
_N = r'\d+(?:\.\d+)?(?:\s*[-–—]\s*\d+(?:\.\d+)?)?'
DURATION = re.compile(
    r'(?:for|over|×|x|during)\s+(' + _N + r')\s*'
    r'(days?|weeks?|months?|hours?|hrs?|h\b|years?)', re.I)

# A comparator, a number, and a unit that names a clinical quantity.
QUANTITIES = {
    'spo2 %': r'%',
    'temperature °C': r'°\s?C',
    'haemoglobin g/dL': r'g/dl',
    'glucose mmol/L': r'mmol/l',
    'glucose mg/dL': r'mg/dl',
    'rate /min': r'(?:breaths?|beats?)\s*/\s*min',
    'blood pressure mmHg': r'mmhg',
}
CMP = r'(?:≥|≤|>=|<=|<|>|greater than|less than|at least|below|above)'
THRESHOLD = {
    name: re.compile(r'(' + CMP + r')\s*(' + _N + r')\s*(' + unit + r')', re.I)
    for name, unit in QUANTITIES.items()
}

# A percentage is only an SpO2 threshold when oxygen saturation is the subject.
# Without this every "20% of children" and "≥ 1% resistance" became a cutoff.
SPO2_SUBJECT = re.compile(
    r'(spo|sao|o2\s*sat|oxygen satur|saturation|pulse ox|hypox)', re.I)


def norm(v):
    v = re.sub(r'[‐-―−]', '-', v).replace(' ', '')
    parts = [p for p in v.split('-') if p]
    out = []
    for p in parts:
        try:
            out.append('%g' % float(p))
        except ValueError:
            out.append(p)
    return '-'.join(out)


def norm_unit(u):
    u = u.lower().rstrip('s')
    return {'hr': 'hour', 'h': 'hour'}.get(u, u)


def norm_cmp(c):
    c = c.lower().strip()
    return {'>=': '≥', '<=': '≤', 'greater than': '>', 'less than': '<',
            'at least': '≥', 'below': '<', 'above': '>'}.get(c, c)


def main():
    vocab = ex.build_vocab()
    patterns = [(re.compile(r'(?<![\w-])' + re.escape(f) + r'(?![\w-])', re.I),
                 canon)
                for f, canon in sorted(
                    ((f, c) for c, fs in vocab.items() for f in fs),
                    key=lambda x: -len(x[0]))]
    print('vocabulary: %d drugs' % len(vocab), flush=True)

    os.makedirs(OUTDIR, exist_ok=True)
    df = io.open(DUR_OUT, 'w', encoding='utf-8')
    df.write('book\tfile\ttopic\tdrug\tvalue\tunit\tcontext\tfragment\n')
    df.flush()
    tf = io.open(THR_OUT, 'w', encoding='utf-8')
    tf.write('book\tfile\ttopic\tquantity\tcmp\tvalue\tcontext\tfragment\n')
    tf.flush()

    n_dur = n_thr = 0
    for book, book_dir in ex.BOOKS.items():
        tdir = os.path.join(ex.ROOT, book_dir, 'topics')
        paths = [os.path.join(tdir, n) for n in sorted(os.listdir(tdir))
                 if n.endswith('.yaml')]
        if book_dir in ex.HAS_FORMULARY:
            paths.append(os.path.join(ex.ROOT, book_dir, 'formulary.yaml'))
        for path in paths:
            with io.open(path, encoding='utf-8') as f:
                doc = ex.yaml.safe_load(f)
            title = ex.topic_title(doc, path)
            base = os.path.basename(path)
            units = []
            ex.collect(doc, [], units)
            here_d = here_t = 0
            for frag, ctx in units:
                clean = re.sub(r'[*_`]', '', frag)[:400].replace('\t', ' ')
                ctx_s = ' › '.join(ctx[-3:]).replace('\t', ' ')[:200]

                # --- durations, attached to the nearest drug before them ---
                mentions = []
                claimed = []
                for pat, canon in patterns:
                    for m in pat.finditer(frag):
                        if any(m.start() < e and s < m.end()
                               for s, e in claimed):
                            continue
                        claimed.append((m.start(), m.end()))
                        if ex.NOT_A_PRESCRIPTION.search(
                                frag[m.end():m.end() + 24]):
                            continue
                        mentions.append((m.start(), canon))
                mentions.sort()
                for m in DURATION.finditer(frag):
                    before = [c for p, c in mentions if p < m.start()]
                    drug = before[-1] if before else None
                    if drug is None:
                        hay = ' || '.join(ctx)
                        for pat, canon in patterns:
                            if pat.search(hay):
                                drug = canon
                                break
                    if drug is None:
                        continue
                    df.write('%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' % (
                        book, base, title.replace('\t', ' '), drug,
                        norm(m.group(1)), norm_unit(m.group(2)), ctx_s, clean))
                    df.flush()
                    n_dur += 1
                    here_d += 1

                # --- thresholds, grouped by quantity ---
                for qname, rx in THRESHOLD.items():
                    if qname == 'spo2 %' and not SPO2_SUBJECT.search(
                            frag + ' ' + ' '.join(ctx)):
                        continue
                    for m in rx.finditer(frag):
                        tf.write('%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' % (
                            book, base, title.replace('\t', ' '), qname,
                            norm_cmp(m.group(1)), norm(m.group(2)),
                            ctx_s, clean))
                        tf.flush()
                        n_thr += 1
                        here_t += 1
            print('%s %s: %d durations, %d thresholds (total %d / %d)'
                  % (book, base, here_d, here_t, n_dur, n_thr), flush=True)
    df.close()
    tf.close()
    print('DONE: %d durations -> %s' % (n_dur, DUR_OUT), flush=True)
    print('DONE: %d thresholds -> %s' % (n_thr, THR_OUT), flush=True)

    # ---- side by side -----------------------------------------------------
    dur = defaultdict(lambda: defaultdict(lambda: defaultdict(list)))
    with io.open(DUR_OUT, encoding='utf-8') as f:
        next(f)
        for line in f:
            c = line.rstrip('\n').split('\t')
            dur[c[3]][c[5]].setdefault(c[0], []).append((c[4], c[2], c[7]))
    thr = defaultdict(lambda: defaultdict(list))
    with io.open(THR_OUT, encoding='utf-8') as f:
        next(f)
        for line in f:
            c = line.rstrip('\n').split('\t')
            thr[c[3]].setdefault(c[0], []).append(
                (c[4] + ' ' + c[5], c[2], c[7]))

    rf = io.open(REPORT, 'w', encoding='utf-8')
    rf.write('# Cross-book DURATIONS and THRESHOLDS\n\n')
    rf.write('Generated by `tool/crossbook_rules_extract.py`. WVEMS is excluded '
             '(its figures are\nthe original protocol\'s and are strict). '
             '**Candidates, not findings** — read the context.\n\n')
    rf.write('## Durations — same drug, different course length\n\n')
    rf.flush()
    n_cand = 0
    for drug in sorted(dur):
        for unit in sorted(dur[drug]):
            books = dur[drug][unit]
            if len(books) < 2:
                continue
            sets = {b: sorted({v for v, _, _ in rows}, key=_k)
                    for b, rows in books.items()}
            if sets.get('PB') == sets.get('WHO'):
                continue
            n_cand += 1
            rf.write('### %s — %s\n\n' % (drug, unit))
            for b in ('PB', 'WHO'):
                if b in sets:
                    rf.write('- **%s:** %s\n' % (b, ', '.join(sets[b])))
            rf.write('\n')
            for b in ('PB', 'WHO'):
                for v, topic, frag in books.get(b, [])[:3]:
                    rf.write('  - `%s %s` %s — *%s*\n    > %s\n'
                             % (v, unit, b, topic, frag[:200]))
            rf.write('\n')
            rf.flush()
    rf.write('\n## Thresholds — same quantity, different cutoff\n\n')
    for q in sorted(thr):
        books = thr[q]
        if len(books) < 2:
            continue
        sets = {b: sorted({v for v, _, _ in rows}) for b, rows in books.items()}
        rf.write('### %s\n\n' % q)
        for b in ('PB', 'WHO'):
            if b in sets:
                rf.write('- **%s:** %s\n' % (b, ', '.join(sets[b])))
        rf.write('\n')
        rf.flush()
    rf.close()
    print('DONE: %d duration candidates -> %s' % (n_cand, REPORT), flush=True)


def _k(v):
    try:
        return (0, float(v.split('-')[0]))
    except ValueError:
        return (1, 0.0)


if __name__ == '__main__':
    sys.exit(main())
