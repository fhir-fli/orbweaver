#!/usr/bin/env python3
"""Which drug cards does the printed WVEMS book mark Critical Care?

Print gives every drug card a Notes zone: pale cyan #D0E0E3 normally, lavender
#D9D2E9 when the drug is Critical-Care restricted (audit §5.1). This finds the
card headers (#3A5D64 bands) on pp.118-143, reads the drug name inside each
band, and reports which colour that card's Notes zone is.

Writes every row to disk as it is produced.
"""
import re
import subprocess
import sys
from pathlib import Path

from PIL import Image
from _repo import REPO

PDF = str(REPO / '2026-WVEMS-Protocols.pdf')
OUT = Path(
    "/tmp/claude-1000/-home-grey-dev-fhir/"
    "bf69f899-5700-47a5-bab2-ea7f08d532a0/scratchpad"
)
PNG = OUT / "wvems_png"
PNG.mkdir(parents=True, exist_ok=True)

HEADER = (0x3A, 0x5D, 0x64)
CC = (0xD9, 0xD2, 0xE9)
PLAIN = (0xD0, 0xE0, 0xE3)
TOL = 10

FIRST, LAST = 118, 143


def near(px, target, tol=TOL):
    return all(abs(px[i] - target[i]) <= tol for i in range(3))


def render(page):
    stem = PNG / f"p{page:03d}"
    png = Path(f"{stem}-{page:03d}.png")
    if not png.exists():
        subprocess.run(
            ["pdftoppm", "-f", str(page), "-l", str(page), "-r", "100",
             "-png", PDF, str(stem)],
            check=True, capture_output=True,
        )
    return png


def words(page):
    """(text, x0, y0, x1, y1) in 100-dpi pixels."""
    raw = subprocess.run(
        ["pdftotext", "-f", str(page), "-l", str(page), "-bbox", PDF, "-"],
        check=True, capture_output=True, text=True,
    ).stdout
    scale = 100 / 72
    out = []
    for m in re.finditer(
        r'<word xMin="([\d.]+)" yMin="([\d.]+)" '
        r'xMax="([\d.]+)" yMax="([\d.]+)">(.*?)</word>',
        raw,
    ):
        x0, y0, x1, y1 = (float(m.group(i)) * scale for i in range(1, 5))
        out.append((m.group(5), x0, y0, x1, y1))
    return out


def row_counts(im, colour):
    """Pixel count of `colour` per image row, sampled every 4th column."""
    w, h = im.size
    px = im.load()
    counts = [0] * h
    for y in range(h):
        c = 0
        for x in range(0, w, 4):
            if near(px[x, y], colour):
                c += 1
        counts[y] = c
    return counts


def bands(counts, min_run=8, min_count=20):
    """Contiguous row runs where the colour is present in quantity."""
    out, start = [], None
    for y, c in enumerate(counts):
        if c >= min_count:
            if start is None:
                start = y
        elif start is not None:
            if y - start >= min_run:
                out.append((start, y - 1))
            start = None
    if start is not None and len(counts) - start >= min_run:
        out.append((start, len(counts) - 1))
    return out


def main():
    tsv = OUT / "wvems_cc_drugs.tsv"
    fh = open(tsv, "w")
    fh.write("page\tcard_y0\tcard_y1\tdrug\tnotes\n")
    for page in range(FIRST, LAST + 1):
        im = Image.open(render(page)).convert("RGB")
        heads = bands(row_counts(im, HEADER))
        ccs = bands(row_counts(im, CC), min_run=6, min_count=10)
        plains = bands(row_counts(im, PLAIN), min_run=6, min_count=10)
        ws = words(page)
        h = im.size[1]
        for i, (y0, y1) in enumerate(heads):
            bottom = heads[i + 1][0] if i + 1 < len(heads) else h
            name = " ".join(
                t for (t, wx0, wy0, wx1, wy1) in ws
                if y0 - 3 <= (wy0 + wy1) / 2 <= y1 + 3
            )
            has_cc = any(y0 < a < bottom for a, _ in ccs)
            has_plain = any(y0 < a < bottom for a, _ in plains)
            notes = (
                "CC" if has_cc and not has_plain
                else "plain" if has_plain and not has_cc
                else "both" if has_cc and has_plain
                else "none"
            )
            line = f"{page}\t{y0}\t{bottom}\t{name}\t{notes}"
            fh.write(line + "\n")
            fh.flush()
            print(line, flush=True)
    fh.close()
    print(f"wrote {tsv}", flush=True)


sys.exit(main())
