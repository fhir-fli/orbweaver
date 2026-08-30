#!/usr/bin/env python3
"""Compare a book against ITSELF: the same drug, the same unit, two pages.

This is the move that found the worst errors in this project. Grepping the
ProtocolBook for one drug and reading every page that mentions it surfaced
doses that disagreed with each other inside a single book, and an internal
contradiction cannot be excused as regional variation the way a cross-book
difference can. One of the two pages is wrong.

It was never run over the WHO book. This runs it over every book, from the
dose rows already extracted by crossbook_dose_extract.py.

What it reports: a drug and unit whose values are not all the same across the
topic pages of one book. A difference is NOT a contradiction — the same drug is
legitimately dosed differently for different indications, ages and routes, which
is why every row here is a question to read rather than a verdict. The output
carries the page and the surrounding fragment so the reading can happen without
opening each file.

The formulary is included deliberately: a formulary entry that disagrees with
the page that prescribes the drug is the exact defect that produced the
meropenem and vancomycin CNS underdoses.

Rows are written and flushed one at a time.
"""

import io
import os
import sys
from collections import defaultdict

SRC = '/home/grey/dev/fhir/orbweaver/tool/crossbook/doses.tsv'
OUT = '/home/grey/dev/fhir/orbweaver/tool/crossbook/intrabook_contradictions.tsv'

# Units too weak to compare on: a bare volume or concentration says nothing
# without knowing what is in it.
WEAK = {'ml', 'mg/ml', 'mcg/ml', 'gm', 'mmhg', 'mmol/l', 'iu', 'units', 'g',
        'ml/hr', 'ml/h', '%', 'mm', 'kg', 'cm'}

DASH = chr(0x2013)


def low(v):
    """Lowest number in a value, so 5-10 and 5 compare as the same floor."""
    t = v.replace(DASH, '-').replace(chr(0x2014), '-').split('-')[0]
    t = t.replace(',', '').replace(chr(0xa0), '').strip()
    try:
        return float(t)
    except ValueError:
        return None


def main():
    rows = defaultdict(list)
    with io.open(SRC, encoding='utf-8') as fh:
        header = fh.readline().rstrip('\n').split('\t')
        ix = {k: i for i, k in enumerate(header)}
        for line in fh:
            f = line.rstrip('\n').split('\t')
            if len(f) < len(header):
                continue
            unit = f[ix['unit']].lower()
            if unit in WEAK or not unit:
                continue
            rows[(f[ix['book']], f[ix['drug']], unit)].append(
                (f[ix['file']], f[ix['value']], f[ix['context']],
                 f[ix['fragment']][:200]))

    fh = io.open(OUT, 'w', encoding='utf-8')
    fh.write('book\tdrug\tunit\tratio\tn_values\tvalues\tpages\tfragments\n')
    fh.flush()
    n_group = n_hit = 0
    for key in sorted(rows):
        book, drug, unit = key
        items = rows[key]
        vals = {v for _, v, _, _ in items}
        if len(vals) < 2:
            continue
        n_group += 1
        nums = [low(v) for v in vals]
        nums = [n for n in nums if n]
        if len(nums) < 2:
            continue
        ratio = max(nums) / min(nums)
        if ratio < 1.5:          # same figure written two ways, or a range
            continue
        pages = sorted({p for p, _, _, _ in items})
        if len(pages) < 2:       # one page dosing by age/route is not a clash
            continue
        frags = ' || '.join(sorted({'%s: %s %s [%s]' % (p, v, unit, c[:60])
                                    for p, v, c, _ in items}))
        fh.write('%s\t%s\t%s\t%.1f\t%d\t%s\t%s\t%s\n'
                 % (book, drug, unit, ratio, len(vals),
                    ', '.join(sorted(vals)), '; '.join(pages), frags[:900]))
        fh.flush()
        n_hit += 1
        print('  %-4s %-26s %-12s x%-5.1f %s'
              % (book, drug[:26], unit, ratio, ', '.join(sorted(vals))[:60]),
              flush=True)
    fh.close()
    print('DONE: %d drug/unit groups differ within a book, %d with a spread '
          '>= 1.5x across >= 2 pages -> %s' % (n_group, n_hit, OUT), flush=True)


if __name__ == '__main__':
    sys.exit(main())
