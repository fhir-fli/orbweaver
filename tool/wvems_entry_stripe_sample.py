#!/usr/bin/env python3
"""What are the stripe colours of a WVEMS entry stadium, exactly?

The stripes are not in `get_drawings()` — the stadium outlines are stroke-only
and the banding is painted underneath by a shading/image the vector walker
does not report. So sample the rendered pixels instead, down a column that
misses the text, and report every colour run with its y-extent.

One column each for the blue (left) stadium and the lavender (right) one.

Writes every run as it is produced.

    usage: pdfvenv/bin/python tool/wvems_entry_stripe_sample.py <out.tsv> [pages…]
"""
import sys
from pathlib import Path

import pymupdf
from _repo import REPO

PDF = str(REPO / '2026-WVEMS-Protocols.pdf')
DPI = 400
SCALE = DPI / 72
# PDF-space x of a column inside each stadium that no glyph crosses: just
# right of the blue stadium's bullet gutter, and the far right of the
# lavender one past "mmHg".
COLUMNS = {"blue": 196.0, "lavender": 531.0}
CLIP = pymupdf.Rect(175, 45, 545, 165)


def main():
    out_path = Path(sys.argv[1])
    pages = [int(a) for a in sys.argv[2:]] or [8]
    out_path.parent.mkdir(parents=True, exist_ok=True)
    fh = open(out_path, "w")
    fh.write("page\tcolumn\ty_top_pt\ty_bot_pt\theight_pt\tcolor\n")
    fh.flush()

    doc = pymupdf.open(PDF)
    for pno in pages:
        pix = doc[pno - 1].get_pixmap(dpi=DPI, clip=CLIP)
        for name, x_pt in COLUMNS.items():
            px = round((x_pt - CLIP.x0) * SCALE)
            if not 0 <= px < pix.width:
                print(f"p.{pno} {name}: column off-image", flush=True)
                continue
            runs = []
            for py in range(pix.height):
                c = pix.pixel(px, py)
                if runs and runs[-1][0] == c:
                    runs[-1][2] = py
                else:
                    runs.append([c, py, py])
            for c, y0, y1 in runs:
                h = (y1 - y0 + 1) / SCALE
                if h < 1.5:  # anti-aliasing seam, not a band
                    continue
                fh.write(
                    f"{pno}\t{name}\t{CLIP.y0 + y0 / SCALE:.1f}"
                    f"\t{CLIP.y0 + y1 / SCALE:.1f}\t{h:.1f}"
                    f"\t#{c[0]:02X}{c[1]:02X}{c[2]:02X}\n"
                )
                fh.flush()
            print(f"p.{pno} {name}: {len(runs)} runs at x={x_pt}", flush=True)
    fh.close()
    print(f"done -> {out_path}", flush=True)


if __name__ == "__main__":
    main()
