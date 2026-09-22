#!/usr/bin/env python3
"""Which tokens does the printed book actually set smaller than the number?

The typography audit (§3.2) says the unit runs at 0.80 of the value — 20 pt
against a 25 pt body — but does not list the vocabulary. Guessing it would be
the difference between shrinking "40 mmHg" (right) and "14 y/o" (maybe wrong),
so this reads it off the PDF: every span on the odd prose pages whose size is
below the body size, with the span that precedes it for context.

Writes every row as it is produced.

    usage: pdfvenv/bin/python tool/wvems_unit_census.py <out.tsv> [first] [last]
"""
import re
import sys
from collections import Counter
from pathlib import Path

import pymupdf
from _repo import REPO

PDF = str(REPO / '2026-WVEMS-Protocols.pdf')
BODY_PT = 25.0
# A unit tier sits below the body but above the 12 pt small print (URLs,
# `[Ver:]`, attributions), which is a different tier entirely (§3.7).
LO, HI = 14.0, 24.0


def main():
    out_path = Path(sys.argv[1])
    first = int(sys.argv[2]) if len(sys.argv) > 2 else 5
    last = int(sys.argv[3]) if len(sys.argv) > 3 else 95
    out_path.parent.mkdir(parents=True, exist_ok=True)
    fh = open(out_path, "w")
    fh.write("page\tsize\tratio\tprev_text\ttext\n")
    fh.flush()

    doc = pymupdf.open(PDF)
    tally = Counter()
    for pno in range(first - 1, last):
        page = doc[pno]
        n = 0
        for block in page.get_text("dict").get("blocks", []):
            if block.get("type") != 0:
                continue
            for line in block.get("lines", []):
                spans = line.get("spans", [])
                for i, span in enumerate(spans):
                    size = span["size"]
                    if not (LO <= size <= HI):
                        continue
                    txt = span["text"].strip()
                    if not txt:
                        continue
                    prev = spans[i - 1]["text"].strip() if i else ""
                    # only count it as a unit if a number precedes it
                    if not re.search(r"\d\s*$", prev):
                        continue
                    fh.write(
                        f"{pno + 1}\t{size:.1f}\t{size / BODY_PT:.2f}\t"
                        f"{prev[-18:]}\t{txt}\n"
                    )
                    fh.flush()
                    tally[txt] += 1
                    n += 1
        print(f"p.{pno + 1}: {n} sub-body spans after a number", flush=True)
    fh.close()

    print(f"\n{len(tally)} distinct, {sum(tally.values())} total", flush=True)
    for tok, c in tally.most_common():
        print(f"{c:5d}  {tok!r}", flush=True)


if __name__ == "__main__":
    main()
