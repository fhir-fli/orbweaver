#!/usr/bin/env python3
"""What colours does the print use for the zebra rows of an entry stadium?

Audit item #24 says the age-band entry stadiums are striped, one stripe per
age row, with a fused Critical-Care column on p.8. Reproducing that needs the
actual fills, not an eyeballed guess off a screenshot.

Finds the entry stadium on each page (the top-most wide filled rounded rect in
the flowchart region) and reports every fill rectangle inside it together with
the words that sit in it, so each stripe is identifiable by its own text.

Writes every row as it is produced.

    usage: pdfvenv/bin/python tool/wvems_entry_band_colors.py <out.tsv> [pages…]
"""
import sys
from pathlib import Path

import pymupdf

PDF = "/home/grey/dev/fhir/orbweaver/2026-WVEMS-Protocols.pdf"
DEFAULT_PAGES = [8, 10, 12, 14, 82, 92]


def hexc(c):
    if c is None:
        return ""
    return "#" + "".join(f"{round(v * 255):02X}" for v in c)


def main():
    out_path = Path(sys.argv[1])
    pages = [int(a) for a in sys.argv[2:]] or DEFAULT_PAGES
    out_path.parent.mkdir(parents=True, exist_ok=True)
    fh = open(out_path, "w")
    fh.write("page\tx0\ty0\tx1\ty1\tw\th\tfill\tstroke\ttype\ttext\n")
    fh.flush()

    doc = pymupdf.open(PDF)
    for pno in pages:
        page = doc[pno - 1]
        words = page.get_text("words")
        # The entry stadium is the top band of the flowchart, above the
        # decision diamond. Anchor on the diamond (it is the first thing
        # below the stadium) rather than on the age labels — "Adult" also
        # appears in the dose strip at the foot of several of these pages.
        dia = [w for w in words if w[4].rstrip("?") in ("Severity", "Technique")]
        bot = min(w[1] for w in dia) - 6 if dia else 200.0
        top = 0.0
        n = 0
        for d in page.get_drawings():
            r = pymupdf.Rect(d["rect"])
            if r.y0 < top - 4 or r.y1 > bot or r.get_area() < 40:
                continue
            inside = [
                w[4] for w in words
                if pymupdf.Rect(w[:4]).get_area()
                and (pymupdf.Rect(w[:4]) & r).get_area()
                / pymupdf.Rect(w[:4]).get_area() > 0.5
            ]
            fh.write(
                f"{pno}\t{r.x0:.1f}\t{r.y0:.1f}\t{r.x1:.1f}\t{r.y1:.1f}"
                f"\t{r.width:.1f}\t{r.height:.1f}\t{hexc(d.get('fill'))}"
                f"\t{hexc(d.get('color'))}\t{d['type']}"
                f"\t{' '.join(inside)}\n"
            )
            fh.flush()
            n += 1
        print(f"p.{pno}: {n} fills in the entry band", flush=True)
    fh.close()
    print(f"done -> {out_path}", flush=True)


if __name__ == "__main__":
    main()
