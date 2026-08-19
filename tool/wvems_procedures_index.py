#!/usr/bin/env python3
"""What does the printed Procedures index (p.96) actually list?

Audit item #3b: p.96 is a visual index — a 3-column grid of cards, one per
procedure page, each a "Page NN" heading, a category name, and a stack of
scope-badged procedure rows. The app inlined pp.97-108's cards into one topic
and never built this view.

Authoring it needs the exact grid, and reading 27 rows off a render by eye is
where a badge quietly becomes the wrong letter. So: find the badge fills by
their measured colours, take the label text sitting to their right in the same
row box, and group rows under the "Page NN" heading above them.

Badge colours, the same ones the branch columns use:
  #FFD966 E  ·  #93C47D A  ·  #6FA8DC I  ·  #B4A7D6 P  ·  grey/none = all levels

Writes every row as it is produced.

    usage: pdfvenv/bin/python tool/wvems_procedures_index.py <out.tsv>
"""
import re
import sys
from pathlib import Path

import pymupdf

PDF = "/home/grey/dev/fhir/orbweaver/2026-WVEMS-Protocols.pdf"
PAGE = 96

BADGES = {
    (0xFF, 0xD9, 0x66): "E",
    (0x93, 0xC4, 0x7D): "A",
    (0x6F, 0xA8, 0xDC): "I",
    (0xB4, 0xA7, 0xD6): "P",
}
TOL = 6


def classify(fill):
    if fill is None:
        return None
    rgb = tuple(round(v * 255) for v in fill)
    if len(rgb) != 3:
        return None
    for ref, letter in BADGES.items():
        if all(abs(a - b) <= TOL for a, b in zip(rgb, ref)):
            return letter
    return ""  # a fill that is not a badge colour: the blank/grey gutter


def main():
    out_path = Path(sys.argv[1])
    out_path.parent.mkdir(parents=True, exist_ok=True)
    fh = open(out_path, "w")
    fh.write("heading\tcategory\tbadge\tlabel\tx0\ty0\n")
    fh.flush()

    doc = pymupdf.open(PDF)
    page = doc[PAGE - 1]
    words = page.get_text("words")

    # "Page 97" headings and the category word under each.
    headings = []
    for i, w in enumerate(words):
        if w[4] == "Page" and i + 1 < len(words) and words[i + 1][4].isdigit():
            headings.append((f"Page {words[i + 1][4]}", w[0], w[1]))
        elif w[4] == "P" and i + 2 < len(words) and words[i + 1][4] == "107":
            headings.append(("P 107 & 108", w[0], w[1]))
    headings.sort(key=lambda h: (round(h[2]), h[1]))
    print(f"headings: {[h[0] for h in headings]}", flush=True)

    def category_for(hx, hy):
        # the small word(s) on the line just below the heading
        cand = [
            w for w in words
            if hy + 8 < w[1] < hy + 34 and abs(w[0] - hx) < 190
        ]
        cand.sort(key=lambda w: w[0])
        return " ".join(w[4] for w in cand)

    def heading_for(x, y):
        best, bestd = None, 1e9
        for name, hx, hy in headings:
            if hy > y or abs(hx - x) > 200:
                continue
            d = y - hy
            if d < bestd:
                best, bestd = (name, hx, hy), d
        return best

    rows = 0
    for d in page.get_drawings():
        letter = classify(d.get("fill"))
        if letter is None:
            continue
        r = pymupdf.Rect(d["rect"])
        # a badge cell is a narrow tall-ish swatch at a row's left edge
        if not (14 < r.width < 34 and 20 < r.height < 70):
            continue
        label = [
            w[4] for w in words
            if r.x1 - 2 < w[0] < r.x1 + 190
            and r.y0 - 4 < (w[1] + w[3]) / 2 < r.y1 + 4
        ]
        text = " ".join(label).strip()
        if not text or re.fullmatch(r"Page|\d+", text):
            continue
        head = heading_for(r.x0, r.y0)
        if head is None:
            continue
        name, hx, hy = head
        fh.write(
            f"{name}\t{category_for(hx, hy)}\t{letter}\t{text}"
            f"\t{r.x0:.0f}\t{r.y0:.0f}\n"
        )
        fh.flush()
        print(f"{name} [{letter or '-'}] {text}", flush=True)
        rows += 1
    fh.close()
    print(f"done: {rows} rows -> {out_path}", flush=True)


if __name__ == "__main__":
    main()
