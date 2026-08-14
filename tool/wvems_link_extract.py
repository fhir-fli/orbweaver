#!/usr/bin/env python3
"""Re-derive the WVEMS print cross-reference graph from the PDF's own links.

Every underline in the printed book is a hyperlink and nothing else
(`tool/wvems_audit_typography.md` §1.5): a 2.25 pt band under a phrase that
also carries a PDF link annotation, 1:1, on all 166 pages.  So the book's
navigational spine is recoverable exactly — the target comes off the
annotation's destination page, and the underlined phrase is read char-by-char
out of `rawdict` inside the annotation rectangle.  Nothing here is guessed.

Writes one TSV row per link as it is produced.

    usage: pdfvenv/bin/python tool/wvems_link_extract.py <out.tsv>
"""
import sys
from pathlib import Path

import pymupdf

PDF = "/home/grey/dev/fhir/orbweaver/2026-WVEMS-Protocols.pdf"


LIGATURES = {"ﬀ": "ff", "ﬁ": "fi", "ﬂ": "fl", "ﬃ": "ffi", "ﬄ": "ffl"}


def phrase_in_rect(page, rect):
    """The text under a link annotation, char by char from its own bboxes.

    Selection is **one line, not per char**. Every annotation in this book
    underlines exactly one line — a phrase that wraps carries one annotation
    per line (p.18 stacks three to p.116, touching edge to edge) — so the right
    unit is the single line with the most vertical overlap with the rect.

    Per-char selection fails here: the book's node text runs 25 pt in a 30 pt
    line box at a 25.5 pt pitch, so consecutive lines overlap. On p.30 the rect
    over "Breathing" (y 736.9-762.4) also contains character centres from the
    line below ("Pulmonary Edema", y 747.7-777.7), which returns
    "Breathing•Pulmona". Characters of the chosen line are then clipped to the
    rect horizontally.
    """
    best_line, best_overlap = None, 0.0
    raw = page.get_text("rawdict")
    for block in raw.get("blocks", []):
        if block.get("type") != 0:
            continue
        for line in block.get("lines", []):
            lb = line["bbox"]
            dy = min(lb[3], rect.y1) - max(lb[1], rect.y0)
            dx = min(lb[2], rect.x1) - max(lb[0], rect.x0)
            overlap = dx * dy if dx > 0 and dy > 0 else 0.0
            if overlap > best_overlap:
                best_line, best_overlap = line, overlap
    if best_line is None:
        return "", None, ""
    picked = []  # (x, char)
    for span in best_line.get("spans", []):
        for ch in span.get("chars", []):
            cb = ch["bbox"]
            cx = (cb[0] + cb[2]) / 2
            if rect.x0 - 0.5 <= cx <= rect.x1 + 0.5:
                picked.append((cb[0], LIGATURES.get(ch["c"], ch["c"])))
    picked.sort()
    text = "".join(c for _, c in picked).replace("\xa0", " ").strip()
    full = "".join(
        LIGATURES.get(ch["c"], ch["c"])
        for span in best_line.get("spans", [])
        for ch in span.get("chars", [])
    )
    full = full.replace("\xa0", " ").replace("\t", " ").strip()
    return text, best_line["bbox"], full


def main():
    out_path = Path(sys.argv[1])
    out_path.parent.mkdir(parents=True, exist_ok=True)
    fh = open(out_path, "w")
    fh.write(
        "src_page\tidx\tkind\tdest\tx0\ty0\tx1\ty1\ton_page\t"
        "line_x0\tline_x1\tphrase\tline_text\n"
    )
    fh.flush()

    doc = pymupdf.open(PDF)
    total = 0
    for pno in range(doc.page_count):
        page = doc[pno]
        links = page.get_links()
        for i, lk in enumerate(links):
            kind = lk.get("kind")
            if kind == pymupdf.LINK_GOTO:
                kind_s = "goto"
                dest = str(lk.get("page", -1) + 1)  # 0-based -> printed page
            elif kind == pymupdf.LINK_URI:
                kind_s = "uri"
                dest = lk.get("uri", "")
            else:
                kind_s = f"other:{kind}"
                dest = ""
            r = pymupdf.Rect(lk["from"])
            # Some pages carry annotations placed entirely outside the page
            # box — p.30 has six at x 1038-1397 on a 612 pt page, duplicating
            # its dose-table links plus one (Magnesium) that is not on the
            # printed page at all. They are invisible to a reader; flagged
            # here so nothing downstream treats them as cross-references.
            on_page = "y" if r.intersects(page.rect) else "n"
            phrase, lbox, line_text = phrase_in_rect(page, r)
            phrase = phrase.replace("\t", " ")
            lx0 = f"{lbox[0]:.1f}" if lbox else ""
            lx1 = f"{lbox[2]:.1f}" if lbox else ""
            fh.write(
                f"{pno + 1}\t{i}\t{kind_s}\t{dest}\t"
                f"{r.x0:.1f}\t{r.y0:.1f}\t{r.x1:.1f}\t{r.y1:.1f}\t{on_page}\t"
                f"{lx0}\t{lx1}\t{phrase}\t{line_text}\n"
            )
            fh.flush()
            total += 1
        print(f"p.{pno + 1}: {len(links)} links (running {total})", flush=True)
    fh.close()
    print(f"done: {total} links -> {out_path}", flush=True)


if __name__ == "__main__":
    main()
