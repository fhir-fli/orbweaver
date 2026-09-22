#!/usr/bin/env python3
"""Which printed page does each drug / procedure card start on?

A link into the drug reference (dest pp.118-143) or the procedures
(pp.96-108) names its target in the link phrase, but the phrase has to be
checked against the page the annotation actually points at before it can be
trusted to identify a card.  This dumps every card-header span in those two
ranges with its page, so the phrase -> card match can be verified per item
instead of assumed.

Card headers are the largest text on their page: the drug pages set the name
in the dark band at the top of each card, the procedure pages in the scope
band.  Rather than guess a threshold, every span >= MIN_PT is written out with
its size and position, and the caller decides.

    usage: pdfvenv/bin/python tool/wvems_card_pages.py <out.tsv> <first> <last>
"""
import sys
from pathlib import Path

import pymupdf
from _repo import REPO

PDF = str(REPO / '2026-WVEMS-Protocols.pdf')
MIN_PT = 24.0


def main():
    out_path = Path(sys.argv[1])
    first = int(sys.argv[2])
    last = int(sys.argv[3])
    out_path.parent.mkdir(parents=True, exist_ok=True)
    fh = open(out_path, "w")
    fh.write("page\tsize\tflags\tfont\tcolor\tx0\ty0\tx1\ty1\ttext\n")
    fh.flush()

    doc = pymupdf.open(PDF)
    kept = 0
    for pno in range(first - 1, last):
        page = doc[pno]
        d = page.get_text("dict")
        n = 0
        for block in d.get("blocks", []):
            if block.get("type") != 0:
                continue
            for line in block.get("lines", []):
                for span in line.get("spans", []):
                    if span["size"] < MIN_PT:
                        continue
                    txt = span["text"].strip().replace("\t", " ")
                    if not txt:
                        continue
                    b = span["bbox"]
                    fh.write(
                        f"{pno + 1}\t{span['size']:.1f}\t{span['flags']}\t"
                        f"{span['font']}\t{span['color']}\t"
                        f"{b[0]:.0f}\t{b[1]:.0f}\t{b[2]:.0f}\t{b[3]:.0f}\t{txt}\n"
                    )
                    fh.flush()
                    n += 1
                    kept += 1
        print(f"p.{pno + 1}: {n} spans >= {MIN_PT}pt (running {kept})", flush=True)
    fh.close()
    print(f"done: {kept} spans -> {out_path}", flush=True)


if __name__ == "__main__":
    main()
