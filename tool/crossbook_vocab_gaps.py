#!/usr/bin/env python3
"""Find drug-like words that sit immediately before a dose but are NOT in the
cross-book vocabulary.

A missing drug does not just lose its own doses — it silently hands them to
whichever drug IS in the vocabulary nearest by. In the anaphylaxis bullet
"Diphenhydramine 1mg/kg ... Hydrocortisone 5mg/kg", both doses were attributed
to adrenaline because neither antihistamine nor steroid was in the vocabulary.
That is a false cross-book difference, and left alone it would have wasted an
adjudication pass.

Writes a frequency-ranked list, incrementally.
"""

import io
import os
import re
import sys
from collections import Counter

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import crossbook_dose_extract as ex  # noqa: E402

OUT = os.path.join(ex.OUTDIR, 'vocab_gaps.tsv')

# Words that precede a dose but are not drugs.
NOT_DRUGS = set('''
of in on at to for with per and or the a an as by is are was give given gives
dose doses max maximum min minimum total up over under within after before
each every single first second third daily once twice thrice tablet tablets
tab tabs capsule capsules vial vials syrup solution suspension bottle sachet
sachets ampoule ampoules bag bags drop drops spoon teaspoon tablespoon
iv im po ng sc id pr nebulized nebulised oral orally infusion bolus push
child children adult adults adolescent infant infants neonate neonates
weight kg body age year years month months week weeks day days hour hours
h hr hrs min mins minute minutes plus then followed follow repeat repeated
about approximately roughly least most more less than equal than
concentration strength dilute diluted dilution mixed mix add added
normal saline ringer lactate dextrose water sterile
if but not no yes when where while use used using
level levels target goal range band bands column row
'''.split())


def main():
    vocab = ex.build_vocab()
    surfaces = sorted(
        ((f, c) for c, fs in vocab.items() for f in fs), key=lambda x: -len(x[0]))
    patterns = [(re.compile(r'(?<![\w-])' + re.escape(f) + r'(?![\w-])',
                            re.IGNORECASE), c) for f, c in surfaces]

    counts = Counter()
    examples = {}
    files = 0
    for book, book_dir in ex.BOOKS.items():
        tdir = os.path.join(ex.ROOT, book_dir, 'topics')
        paths = [os.path.join(tdir, n) for n in sorted(os.listdir(tdir))
                 if n.endswith('.yaml')]
        paths.append(os.path.join(ex.ROOT, book_dir, 'formulary.yaml'))
        for path in paths:
            files += 1
            with io.open(path, encoding='utf-8') as f:
                doc = ex.yaml.safe_load(f)
            units = []
            ex.collect(doc, [], units)
            for frag, ctx in units:
                for dm in ex.DOSE_RE.finditer(frag):
                    head = frag[:dm.start()]
                    # The word or hyphenated word immediately before the dose.
                    m = re.search(r'([A-Za-z][A-Za-z\-/]{3,})\W*$', head)
                    if not m:
                        continue
                    word = m.group(1)
                    low = word.lower().strip('-/')
                    if low in NOT_DRUGS or len(low) < 4:
                        continue
                    # Already covered by the vocabulary?
                    if any(p.search(word) for p, _ in patterns):
                        continue
                    counts[low] += 1
                    examples.setdefault(low, (book, frag[:200]))
            print('scanned %s (%d distinct unknown words so far)'
                  % (os.path.basename(path), len(counts)), flush=True)

    fh = io.open(OUT, 'w', encoding='utf-8')
    fh.write('count\tword\tbook\texample\n')
    fh.flush()
    for word, n in counts.most_common():
        book, frag = examples[word]
        fh.write('%d\t%s\t%s\t%s\n' % (n, word, book, frag.replace('\t', ' ')))
        fh.flush()
    fh.close()
    print('DONE: %d files, %d distinct unknown words -> %s'
          % (files, len(counts), OUT), flush=True)


if __name__ == '__main__':
    sys.exit(main())
