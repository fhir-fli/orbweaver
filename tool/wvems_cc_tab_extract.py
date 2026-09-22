#!/usr/bin/env python3
"""What does each printed Critical-Care sub-tab say?

The badge audit (§6.4 #34) counts 19 lavender CC tabs fused under a convergence
stadium on the flowchart pages, against 3 in the app. Authoring the missing 16
needs each tab's text, and reading 16 rendered pages by eye is both slow and a
chance to mis-transcribe.

The tab is a filled rounded rect in the Critical-Care lavender (#D9D2E9, the
same fill `wvems_cc_drug_detect.py` used on the drug cards). So: find the
lavender fills on each page, then take the text spans that sit inside them.

Writes one row per tab as it is produced.

    usage: pdfvenv/bin/python tool/wvems_cc_tab_extract.py <out.tsv> [pages…]
"""
import sys
from pathlib import Path

import pymupdf
from _repo import REPO

PDF = str(REPO / '2026-WVEMS-Protocols.pdf')

# #D9D2E9 as PyMuPDF's 0-1 floats, with room for rounding in the PDF's own
# colour operators.
LAVENDER = (0xD9 / 255, 0xD2 / 255, 0xE9 / 255)
TOL = 0.02

# The pages the audit lists as carrying a CC sub-tab.
DEFAULT_PAGES = [4, 6, 8, 10, 16, 26, 28, 30, 34, 36, 42, 48, 54, 56, 58, 62,
                 72, 86, 90]


def is_lavender(color):
    if color is None:
        return False
    if len(color) != 3:
        return False
    return all(abs(a - b) <= TOL for a, b in zip(color, LAVENDER))


def main():
    out_path = Path(sys.argv[1])
    pages = [int(a) for a in sys.argv[2:]] or DEFAULT_PAGES
    out_path.parent.mkdir(parents=True, exist_ok=True)
    fh = open(out_path, "w")
    fh.write("page\tx0\ty0\tx1\ty1\ttext\n")
    fh.flush()

    doc = pymupdf.open(PDF)
    found = 0
    for pno in pages:
        page = doc[pno - 1]
        rects = [
            pymupdf.Rect(d["rect"])
            for d in page.get_drawings()
            if is_lavender(d.get("fill"))
        ]
        # merge overlapping bands so one tab is one row
        merged = []
        for r in sorted(rects, key=lambda r: (round(r.y0), r.x0)):
            if merged and merged[-1].intersects(r):
                merged[-1] |= r
            else:
                merged.append(+r)

        words = page.get_text("words")
        n = 0
        for r in merged:
            inside = [
                w[4]
                for w in words
                if pymupdf.Rect(w[:4]).intersects(r)
                and pymupdf.Rect(w[:4]).get_area()
                and (pymupdf.Rect(w[:4]) & r).get_area()
                / pymupdf.Rect(w[:4]).get_area()
                > 0.5
            ]
            text = " ".join(inside).strip()
            if not text:
                continue
            fh.write(
                f"{pno}\t{r.x0:.0f}\t{r.y0:.0f}\t{r.x1:.0f}\t{r.y1:.0f}\t{text}\n"
            )
            fh.flush()
            n += 1
            found += 1
        print(f"p.{pno}: {len(merged)} lavender bands, {n} with text", flush=True)
    fh.close()
    print(f"done: {found} tabs -> {out_path}", flush=True)


if __name__ == "__main__":
    main()
