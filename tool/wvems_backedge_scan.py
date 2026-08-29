#!/usr/bin/env python3
"""Screen every WVEMS flowchart page for a drawn BACK-EDGE.

Why. The WHO Chart 12 back-edge — an arrow leaving the chest-compressions box,
running along the bottom of the chart and back up — was invisible to a grep for
loop words, because the print labels it "If HR > 100/min" and uses none. It was
found only by rendering the page and looking. WVEMS has 46 flowchart pages and
its figures are strict, so the same defect there would be a dropped instruction
in a protocol nobody may reinterpret.

Rendering 46 pages by eye is the expensive part, so this narrows first. A
routed return edge in these charts is a long connector that runs OUTSIDE the
column of boxes: down the far left or far right margin, or along the bottom
below the last box. Box borders are long too, but they come in parallel pairs
that close a rectangle; a return edge does not.

The screen is deliberately high-recall. Every hit is then looked at. A page
with no hit is not proven clean by this script alone — it is proven clean by
the ones that ARE looked at showing the detector fires on real edges, which is
why WHO Chart 12 is scanned first as a positive control.

Output is written and flushed per page.
"""

import io
import os
import subprocess
import sys

from PIL import Image

ROOT = '/home/grey/dev/fhir/orbweaver'
SCRATCH = os.environ.get(
    'SCRATCH',
    '/tmp/claude-1000/-home-grey-dev-fhir/'
    'bd31e282-678a-40b4-813d-846a3094b585/scratchpad')
OUT = os.path.join(ROOT, 'tool', 'crossbook', 'wvems_backedge.tsv')

# The first version of this screen was BLIND and its own positive control said
# so: it looked for NEAR-BLACK runs in the outer sixth of the PAGE. WHO Chart
# 12's back-edge is a thin ORANGE arrow routed inside the chart's own frame, so
# both thresholds were wrong. Ink is now anything that is not near-white, and
# margins are measured against the chart's ink bounding box, not the paper.
INK_MAX = 205        # a pixel is ink if its darkest channel is below this
MIN_RUN_FRAC = 0.30  # a connector worth noticing spans a third of the box axis
MARGIN_FRAC = 0.14   # "outside the column of boxes" = outer band of the bbox
SCALE = 0.55         # downscale before the run scan; pure-Python is O(w*h)


def render(pdf, page, dpi=110):
    d = os.path.join(SCRATCH, 'backedge')
    os.makedirs(d, exist_ok=True)
    stem = os.path.join(d, 'p%04d' % page)
    hits = [f for f in os.listdir(d) if f.startswith('p%04d-' % page)]
    if not hits:
        subprocess.run(
            ['pdftoppm', '-f', str(page), '-l', str(page), '-r', str(dpi),
             '-png', pdf, stem],
            check=True, capture_output=True)
        hits = [f for f in os.listdir(d) if f.startswith('p%04d-' % page)]
    return os.path.join(d, sorted(hits)[0])


def runs(mask, w, h):
    """Longest dark run per column and per row, as fractions of the axis."""
    col = [0] * w
    row = [0] * h
    for y in range(h):
        cur = 0
        for x in range(w):
            if mask[y * w + x]:
                cur += 1
                if cur > row[y]:
                    row[y] = cur
            else:
                cur = 0
    for x in range(w):
        cur = 0
        for y in range(h):
            if mask[y * w + x]:
                cur += 1
                if cur > col[x]:
                    col[x] = cur
            else:
                cur = 0
    return col, row


def scan(png):
    im = Image.open(png).convert('RGB')
    im = im.resize((max(1, int(im.width * SCALE)),
                    max(1, int(im.height * SCALE))))
    w, h = im.size
    px = im.load()
    mask = bytearray(w * h)
    for y in range(h):
        base = y * w
        for x in range(w):
            r, g, b = px[x, y]
            if r < INK_MAX or g < INK_MAX or b < INK_MAX:
                mask[base + x] = 1

    # Bound the drawing, so margins mean "outside the boxes" and not "outside
    # the paper". Page furniture (crop marks, colour bars, the spine tab) sits
    # outside the chart, and measuring against the sheet buried the arrow.
    xs = [x for x in range(w) if any(mask[y * w + x] for y in range(h))]
    ys = [y for y in range(h) if any(mask[y * w + x] for x in range(w))]
    if not xs or not ys:
        return []
    x0, x1, y0, y1 = xs[0], xs[-1], ys[0], ys[-1]
    # Inset past the page frame. Every WVEMS chart page is enclosed in a
    # coloured border, which is a run the full height of the bounding box and
    # flagged all 46 pages until it was excluded.
    inx = max(2, int((x1 - x0) * 0.035))
    iny = max(2, int((y1 - y0) * 0.035))
    x0, x1, y0, y1 = x0 + inx, x1 - inx, y0 + iny, y1 - iny
    if x1 <= x0 or y1 <= y0:
        return []
    bw, bh = x1 - x0 + 1, y1 - y0 + 1

    col = [0] * w
    row = [0] * h
    for y in range(y0, y1 + 1):
        cur = 0
        for x in range(x0, x1 + 1):
            if mask[y * w + x]:
                cur += 1
                if cur > row[y]:
                    row[y] = cur
            else:
                cur = 0
    for x in range(x0, x1 + 1):
        cur = 0
        for y in range(y0, y1 + 1):
            if mask[y * w + x]:
                cur += 1
                if cur > col[x]:
                    col[x] = cur
            else:
                cur = 0

    band = max(1, int(bw * MARGIN_FRAC))
    need_v = int(bh * MIN_RUN_FRAC)
    need_h = int(bw * MIN_RUN_FRAC)

    left = max(col[x0:x0 + band])
    right = max(col[x1 - band + 1:x1 + 1])
    bottom = max(row[y0 + int(bh * 0.70):y1 + 1])

    # A run at or near the full axis is a rule or a frame, not a routed edge.
    FRAME = 0.92
    if left >= bh * FRAME:
        left = 0
    if right >= bh * FRAME:
        right = 0
    if bottom >= bw * FRAME:
        bottom = 0

    flags = []
    if left >= need_v:
        flags.append('left-band vertical %d px (%.0f%% of chart height)'
                     % (left, 100.0 * left / bh))
    if right >= need_v:
        flags.append('right-band vertical %d px (%.0f%% of chart height)'
                     % (right, 100.0 * right / bh))
    if bottom >= need_h:
        flags.append('bottom horizontal %d px (%.0f%% of chart width)'
                     % (bottom, 100.0 * bottom / bw))
    return flags


def main():
    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    fh = io.open(OUT, 'w', encoding='utf-8')
    fh.write('source\tpage\tflags\n')
    fh.flush()

    # POSITIVE CONTROL first. WHO Chart 12 (PDF p.71) carries a real routed
    # back-edge. If the screen does not fire on it, the screen is worthless and
    # every clean WVEMS page below means nothing.
    who = os.path.join(ROOT, '9789241548373_eng.pdf')
    ctrl = scan(render(who, 71))
    fh.write('CONTROL who-chart-12\t71\t%s\n'
             % ('; '.join(ctrl) if ctrl else 'NO FLAGS'))
    fh.flush()
    print('POSITIVE CONTROL, WHO Chart 12 (pdf p.71): %s'
          % ('; '.join(ctrl) if ctrl else '*** NO FLAGS — SCREEN IS BLIND ***'),
          flush=True)
    if not ctrl:
        print('Stopping: a screen that misses the known back-edge proves '
              'nothing about the pages it calls clean.', flush=True)
        fh.close()
        return 1

    pdf = os.path.join(ROOT, '2026-WVEMS-Protocols.pdf')
    pages = [int(n.split('_')[-1].split('.')[0])
             for n in sorted(os.listdir(
                 os.path.join(ROOT, 'assets/books/wvems/topics')))
             if n.endswith('.yaml') and n.split('_')[-1][:-5].isdigit()]
    charts = []
    for p in pages:
        y = os.path.join(ROOT, 'assets/books/wvems/topics',
                         'wvems_2026_%03d.yaml' % p)
        if 'type: "flowchart"' in io.open(y, encoding='utf-8').read():
            charts.append(p)
    print('%d WVEMS flowchart pages to screen' % len(charts), flush=True)

    hits = 0
    for p in charts:
        flags = scan(render(pdf, p))
        fh.write('wvems\t%d\t%s\n'
                 % (p, '; '.join(flags) if flags else 'clean'))
        fh.flush()
        if flags:
            hits += 1
        print('  p%-4d %s' % (p, '; '.join(flags) if flags else 'clean'),
              flush=True)
    fh.close()
    print('DONE: %d of %d pages flagged for a look -> %s'
          % (hits, len(charts), OUT), flush=True)
    return 0


if __name__ == '__main__':
    sys.exit(main())
