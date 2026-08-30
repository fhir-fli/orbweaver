#!/usr/bin/env python3
"""Compare a book against ITSELF on DURATIONS and THRESHOLDS.

The dose version of this found three real defects, every one of them a
formulary entry disagreeing with the page that prescribes the drug. Durations
and thresholds have never been compared within a book at all, only across the
two, and they carry the same class of error:

  * a course that is 5 days on one page and 10 on another, for the same drug
    and the same infection;
  * an oxygen threshold of 90% in one place and 94% in another - which is
    exactly the sweep that went wrong on 2026-08-28, nine files left behind by
    a case-sensitive regex.

An internal contradiction cannot be excused as regional variation the way a
cross-book difference can. One of the two pages is wrong, or one of them is
missing the qualifier that reconciles them.

What it reports. A drug and unit whose DURATION values differ across pages of
one book, and a quantity and comparator whose THRESHOLD values differ. A
difference is not a contradiction: the same drug legitimately runs 7 days for
one infection and 14 for another, and a threshold legitimately differs by age.
Every row is a question to read, never a verdict, so the page and the
surrounding fragment are carried into the output.

🛑 It only SURFACES disagreements. Resolving one is a separate act needing a
source - see ~/.claude/rules/leave-the-blank-blank.md, written after two dose
figures were invented while resolving exactly this kind of finding.

Rows are written and flushed one at a time.
"""

import io
import os
import sys
from collections import defaultdict

OUTDIR = '/home/grey/dev/fhir/orbweaver/tool/crossbook'
DUR = os.path.join(OUTDIR, 'durations.tsv')
OUT = os.path.join(OUTDIR, 'intrabook_rules.tsv')

DASH = chr(0x2013)


def low(v):
    t = v.replace(DASH, '-').replace(chr(0x2014), '-').replace(',', '')
    t = t.replace(chr(0xa0), '').strip()
    try:
        return float(t.split('-')[0])
    except (ValueError, IndexError):
        return None


def read(path, keycols, valcol):
    """Group rows by (book, *keycols) -> {(value, file, context, fragment)}."""
    groups = defaultdict(set)
    if not os.path.exists(path):
        return groups
    with io.open(path, encoding='utf-8') as fh:
        header = fh.readline().rstrip('\n').split('\t')
        ix = {k: i for i, k in enumerate(header)}
        for line in fh:
            f = line.rstrip('\n').split('\t')
            if len(f) < len(header):
                continue
            key = tuple([f[ix['book']]] + [f[ix[c]].strip().lower()
                                           for c in keycols])
            if not all(key[1:]):
                continue
            groups[key].add((f[ix[valcol]].strip(), f[ix['file']],
                             f[ix['context']][:70], f[ix['fragment']][:150]))
    return groups


def emit(fh, kind, groups, min_ratio):
    n = 0
    for key in sorted(groups):
        items = groups[key]
        vals = {v for v, _, _, _ in items}
        pages = sorted({p for _, p, _, _ in items})
        if len(vals) < 2 or len(pages) < 2:
            continue
        nums = [low(v) for v in vals]
        nums = [x for x in nums if x]
        if len(nums) < 2:
            continue
        ratio = max(nums) / min(nums)
        if ratio < min_ratio:
            continue
        detail = ' || '.join(sorted({'%s: %s [%s]' % (p, v, c)
                                     for v, p, c, _ in items}))
        fh.write('%s\t%s\t%s\t%.1f\t%s\t%s\t%s\n'
                 % (kind, key[0], ' / '.join(key[1:]), ratio,
                    ', '.join(sorted(vals)), '; '.join(pages), detail[:800]))
        fh.flush()
        n += 1
        print('  %-10s %-4s %-34s x%-5.1f %s'
              % (kind, key[0], ' / '.join(key[1:])[:34], ratio,
                 ', '.join(sorted(vals))[:44]), flush=True)
    return n


def main():
    os.makedirs(OUTDIR, exist_ok=True)
    fh = io.open(OUT, 'w', encoding='utf-8')
    fh.write('kind\tbook\tkey\tratio\tvalues\tpages\tdetail\n')
    fh.flush()

    dur = read(DUR, ['drug', 'unit'], 'value')

    # Durations: a 1.5x spread is a different course, not a rounding.
    n_d = emit(fh, 'DURATION', dur, 1.5)
    fh.close()
    # 🛑 THRESHOLDS ARE NOT COMPARED HERE ANY MORE. This file grouped them by
    # quantity and comparator alone, which pooled every cutoff sharing a unit -
    # hypoglycaemia at 2.2 against DKA resolution at 11 - and so reported
    # nothing. tool/threshold_extract.py binds each cutoff to the decision it
    # gates and reports a within-book disagreement as a decision group whose
    # rows all come from one book.
    print('DONE: %d duration disagreements within a book -> %s'
          % (n_d, OUT), flush=True)
    print('thresholds: see tool/threshold_extract.py', flush=True)


if __name__ == '__main__':
    sys.exit(main())
