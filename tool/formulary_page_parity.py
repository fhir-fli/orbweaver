#!/usr/bin/env python3
"""Guard: a formulary dose that appears on NO page prescribing that drug.

Why this exists. Five times now, a dose was corrected on the protocol page and
the formulary entry for the same drug was left behind:

  meropenem and vancomycin  generic dose kept under a CNS indication
  phenobarbital, both books loading 15 mg/kg kept while every page moved to 20
  lidocaine                 4-5 mg/kg kept while the page carried 4.5 plain / 7
                            with epinephrine

The formulary is read WITHOUT the page around it, which is what makes this
dangerous: the reader looking up a drug gets the stale number and no context
telling them a protocol page says otherwise.

The check. For each book, drug and unit, compare the values in the formulary
against the values on every topic page that prescribes that drug. A formulary
value that appears on no page is an ORPHAN. An orphan is not automatically a
defect - the formulary legitimately covers indications the topics never
mention, which is why there are hundreds of them - so this compares against a
committed baseline and fails only on ones that are NEW.

A new orphan means one of three things, and all three want a human:
  1. a page dose changed and the formulary was not changed with it   <- the bug
  2. a formulary dose changed and no page carries it
  3. a new formulary entry was added for an indication no page covers <- fine,
     add it to the baseline with a one-line reason

Run it after any dose change:  python3 tool/formulary_page_parity.py
Rebuild the baseline on purpose: python3 tool/formulary_page_parity.py --bless

Rows are written and flushed as they are found.
"""

import io
import os
import subprocess
import sys
from collections import defaultdict

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DOSES = os.path.join(ROOT, 'tool', 'crossbook', 'doses.tsv')
BASELINE = os.path.join(ROOT, 'tool', 'formulary_page_parity_baseline.tsv')
EXTRACT = os.path.join(ROOT, 'tool', 'crossbook_dose_extract.py')

# Units too weak to compare on: a bare volume or concentration says nothing
# without knowing what is dissolved in it.
WEAK = {'ml', 'mg/ml', 'mcg/ml', 'gm', 'mmhg', 'mmol/l', 'iu', 'units', 'g',
        'ml/hr', 'ml/h', '%', 'mm', 'kg', 'cm', ''}


def orphans():
    form = defaultdict(set)
    page = defaultdict(set)
    with io.open(DOSES, encoding='utf-8') as fh:
        header = fh.readline().rstrip('\n').split('\t')
        ix = {k: i for i, k in enumerate(header)}
        for line in fh:
            f = line.rstrip('\n').split('\t')
            if len(f) < len(header):
                continue
            unit = f[ix['unit']].lower()
            if unit in WEAK:
                continue
            key = (f[ix['book']], f[ix['drug']], unit)
            bucket = form if f[ix['file']] == 'formulary.yaml' else page
            bucket[key].add(f[ix['value']].strip())
    out = set()
    for key in form:
        for v in form[key] - page.get(key, set()):
            out.add((key[0], key[1], key[2], v))
    return out


def read_baseline():
    if not os.path.exists(BASELINE):
        return set()
    rows = set()
    with io.open(BASELINE, encoding='utf-8') as fh:
        for line in fh:
            if line.startswith('#') or not line.strip():
                continue
            f = line.rstrip('\n').split('\t')
            if len(f) >= 4:
                rows.add(tuple(f[:4]))
    return rows


def write_baseline(rows):
    with io.open(BASELINE, 'w', encoding='utf-8') as fh:
        fh.write('# Formulary doses that appear on no page prescribing that '
                 'drug.\n'
                 '# Frozen so the test fails only on NEW ones. See\n'
                 '# tool/formulary_page_parity.py for what a new row means.\n'
                 '# book\tdrug\tunit\tvalue\n')
        for r in sorted(rows):
            fh.write('\t'.join(r) + '\n')
            fh.flush()


def main():
    bless = '--bless' in sys.argv
    if not os.path.exists(DOSES) or bless or '--extract' in sys.argv:
        r = subprocess.run([sys.executable, EXTRACT], capture_output=True,
                           text=True)
        if r.returncode != 0:
            # Show why, or a CI failure reads as a bare CalledProcessError.
            sys.stderr.write(r.stderr)
            sys.stderr.flush()
            r.check_returncode()
    found = orphans()
    if bless:
        write_baseline(found)
        print('baseline rewritten: %d rows -> %s' % (len(found), BASELINE),
              flush=True)
        return 0
    base = read_baseline()
    new = sorted(found - base)
    gone = len(base - found)
    for book, drug, unit, value in new:
        print('NEW ORPHAN  %-4s %-24s %-12s %s' % (book, drug, unit, value),
              flush=True)
    if new:
        print('\n%d formulary dose(s) appear on no page prescribing that drug '
              'and are not in the baseline.\n'
              'If a page dose changed, change the formulary entry in the same '
              'commit.\n'
              'If the entry is legitimately broader than any page, run '
              '--bless and say why in the commit.' % len(new), flush=True)
        return 1
    print('OK: no new orphan formulary doses (%d in baseline, %d of them no '
          'longer orphaned)' % (len(base), gone), flush=True)
    return 0


if __name__ == '__main__':
    sys.exit(main())
