#!/usr/bin/env python3
"""Cross-book comparison of DURATIONS.

🛑 Thresholds moved to tool/threshold_extract.py on 2026-08-30.
The version here keyed a cutoff on its UNIT, which mislabelled
17 of its 244 rows (lactate and CSF glucose filed as blood
glucose, CRP and bilirubin filed as glucose) and pooled every
decision sharing a unit, so it could not report a disagreement
at all. A cutoff belongs to a decision.

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
from threshold_extract import decision_words  # noqa: E402

OUTDIR = ex.OUTDIR
DUR_OUT = os.path.join(OUTDIR, 'durations.tsv')
REPORT = os.path.join(OUTDIR, 'rules_side_by_side.md')

# "for 7 days", "× 10 days", "x 5 days", "over 4 h", "for 2–3 weeks".
_N = r'\d+(?:\.\d+)?(?:\s*[-–—]\s*\d+(?:\.\d+)?)?'
DURATION = re.compile(
    r'(?:for|over|×|x|during)\s+(' + _N + r')\s*'
    r'(days?|weeks?|months?|hours?|hrs?|h\b|years?)', re.I)



def window(text, start, end, before=190, after=190):
    """The text AROUND the match, not the first 400 characters of the unit.

    A fragment is truncated for the output column, and a match past that cut
    left the row showing text that does not contain the number the row
    reports. Six duration rows read as a malaria coma paragraph filed under
    iron; the drug and the duration were both real and both past character
    400. A row a reader cannot adjudicate from its own evidence is worse than
    no row.
    """
    a = max(0, start - before)
    b = min(len(text), end + after)
    out = text[a:b]
    if a:
        out = '…' + out
    if b < len(text):
        out = out + '…'
    return out


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



def main():
    vocab = ex.build_vocab()
    patterns = [(re.compile(ex.drug_pattern(f), re.I),
                 canon)
                for f, canon in sorted(
                    ((f, c) for c, fs in vocab.items() for f in fs),
                    key=lambda x: -len(x[0]))]
    print('vocabulary: %d drugs' % len(vocab), flush=True)

    os.makedirs(OUTDIR, exist_ok=True)
    df = io.open(DUR_OUT, 'w', encoding='utf-8')
    df.write('book\tfile\ttopic\tdrug\tvalue\tunit\tvia\tindication\tfragment\n')
    df.flush()
    n_dur = 0
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
            here_d = 0
            for frag, ctx in units:
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
                    clean = re.sub(r'[*_`]', '', window(
                        frag, m.start(), m.end())).replace('\t', ' ')
                    before = [c for p, c in mentions if p < m.start()]
                    drug = before[-1] if before else None
                    via = 'fragment' if drug else None
                    if drug is None:
                        # The old fallback searched the WHOLE joined heading
                        # stack and took the first pattern that matched, in
                        # order of surface-form LENGTH. Which drug won was
                        # therefore arbitrary, and six rows came out filed
                        # under a drug named nowhere on the page at all: a
                        # malaria coma paragraph filed under iron and under
                        # artemether, an artesunate dosing line filed under
                        # glucose, a rate-control paragraph under warfarin.
                        #
                        # A heading owns a duration only when it is the
                        # NEAREST heading and it names exactly ONE drug.
                        # Anything else is a guess, and a guessed drug is
                        # worse than a dropped row.
                        for head in reversed(ctx):
                            named = []
                            for pat, canon in patterns:
                                if pat.search(head) and canon not in named:
                                    named.append(canon)
                            if len(named) == 1:
                                drug, via = named[0], 'heading'
                                break
                            if named:
                                break
                    if drug is None:
                        continue
                    df.write('%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' % (
                        book, base, title.replace('\t', ' '), drug,
                        norm(m.group(1)), norm_unit(m.group(2)), via,
                        (title + ' › ' + ' › '.join(ctx[-2:])
                         ).replace('\t', ' ')[:200], clean))
                    df.flush()
                    n_dur += 1
                    here_d += 1

            print('%s %s: %d durations (total %d)'
                  % (book, base, here_d, n_dur), flush=True)
    df.close()
    print('DONE: %d durations -> %s' % (n_dur, DUR_OUT), flush=True)

    # ---- side by side -----------------------------------------------------
    dur = defaultdict(lambda: defaultdict(lambda: defaultdict(list)))
    with io.open(DUR_OUT, encoding='utf-8') as f:
        next(f)
        for line in f:
            c = line.rstrip('\n').split('\t')
            dur[c[3]][c[5]].setdefault(c[0], []).append(
                (c[4], c[2], c[8], c[7]))

    rf = io.open(REPORT, 'w', encoding='utf-8')
    rf.write('# Cross-book DURATIONS\n\n')
    rf.write('Generated by `tool/crossbook_rules_extract.py`. WVEMS is excluded '
             '(its figures are\nthe original protocol\'s and are strict). '
             '**Candidates, not findings** — read the context.\n\n')
    rf.write('## Durations — same drug, different course length\n\n')
    rf.flush()
    n_cand = n_same = 0
    for drug in sorted(dur):
        for unit in sorted(dur[drug]):
            books = dur[drug][unit]
            rows = [(b,) + r for b, rs in books.items() for r in rs]
            # A drug legitimately runs 5 days for one infection and 10 for
            # another, so a set of values per drug says nothing. Group by the
            # INDICATION first, the same rule the threshold half needed: a row
            # joins a group only if it shares a distinctive word with every
            # row already in it.
            buckets = []
            for r in rows:
                ws = decision_words(r[4])
                for b in buckets:
                    if all(ws & w for w in b['each']):
                        b['each'].append(ws)
                        b['rows'].append(r)
                        break
                else:
                    buckets.append({'each': [ws], 'rows': [r]})
            wrote = False
            for b in buckets:
                vals = sorted({r[1] for r in b['rows']}, key=_k)
                bks = {r[0] for r in b['rows']}
                if len(vals) < 2 or len(bks) < 2:
                    n_same += 1
                    continue
                if not wrote:
                    rf.write('### %s — %s\n\n' % (drug, unit))
                    wrote = True
                n_cand += 1
                label = ' / '.join(sorted({r[4].split(' › ')[0]
                                           for r in b['rows']}))[:110]
                rf.write('#### ⚠ %s — %s\n\n' % (label, ', '.join(vals)))
                for r in sorted(b['rows']):
                    rf.write('- `%s %s` **%s** — %s\n  > %s\n'
                             % (r[1], unit, r[0], r[4][:100], r[3][:190]))
                rf.write('\n')
                rf.flush()
            if wrote and len(buckets) > 1:
                rf.write('> NOT COMPARABLE: the other %d indication group(s) '
                         'for this drug are not compared with these.\n\n'
                         % (len(buckets) - 1))
    rf.close()
    print('DONE: %d duration candidates across both books, %d groups agreed or single-book -> %s' % (n_cand, n_same, REPORT), flush=True)


def _k(v):
    try:
        return (0, float(v.split('-')[0]))
    except ValueError:
        return (1, 0.0)


if __name__ == '__main__':
    sys.exit(main())
