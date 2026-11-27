#!/usr/bin/env python3
"""Translated book covers, drawn over the English cover.

The English covers have no source file; they are the source. For each line
of text on a cover this script knows its band (the rows it occupies, found
by tool/l10n/covers.py --bands), its font and its English wording. It
calibrates the font size and letter spacing so the English line rendered by
this script fills the band exactly as printed, paints the band with the
cover's own background, and draws the translated line on the same baseline
at the same size (smaller only if it would not fit the cover's width).

    python3 tool/l10n/covers.py            # writes <book>/es/cover.*
    python3 tool/l10n/covers.py --verify   # redraws the ENGLISH and reports
                                           # how far it is from the original

--verify is the check on the instrument: if redrawing the English text does
not reproduce the original cover closely, the Spanish cannot be trusted.

WVEMS is not here: its cover is WVEMS's own printed cover with its logo, a
reproduction of the print, not ours to redraw. WHO is not here: licence
202610340 does not cover translation (WHO-LICENCE.md).
"""
import os
import sys

from PIL import Image, ImageDraw, ImageFont

REPO = os.path.abspath(os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..'))
BOLD = '/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf'
REGULAR = '/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf'
MARGIN = 40  # px kept clear at each side when a translated line is wider

# band = (top row, bottom row, left col, right col) of the English ink.
COVERS = {
    'calculators/cover.png': {
        'es': [
            ((913, 962, 105, 692), BOLD, 'CALCULATORS', 'CALCULADORAS'),
            ((1006, 1031, 225, 576), REGULAR, 'Bedside clinical tools',
             'Herramientas clínicas a pie de cama'),
            ((1125, 1147, 182, 616), REGULAR, 'evidence-vetted  ·  guideline-backed',
             'verificadas con evidencia  ·  respaldadas por guías'),
        ],
    },
    'protocolbook/cover.jpg': {
        'es': [
            ((335, 434, 231, 575), BOLD, 'Quick', 'Referencia'),
            ((455, 540, 96, 709), BOLD, 'Reference', 'rápida'),
            ((676, 719, 125, 676), BOLD, 'Basic Protocols in', 'Protocolos básicos de'),
            ((746, 789, 195, 607), BOLD, 'Paediatrics &', 'Pediatría y'),
            ((816, 859, 129, 674), BOLD, 'Internal Medicine', 'Medicina interna'),
        ],
    },
}


def ink_box(font, text, track):
    """(left, top, right, bottom) of the ink, relative to a left-baseline origin."""
    x = 0
    l = t = r = b = None
    for ch in text:
        bb = font.getbbox(ch, anchor='ls')
        if bb[2] > bb[0]:
            cl, ct, cr, cb = x + bb[0], bb[1], x + bb[2], bb[3]
            l = cl if l is None else min(l, cl)
            t = ct if t is None else min(t, ct)
            r = cr if r is None else max(r, cr)
            b = cb if b is None else max(b, cb)
        x += font.getlength(ch) + track
    return l, t, r, b


def calibrate(path, band, text):
    """Font size and tracking at which `text` fills `band` as printed."""
    top, bottom, left, right = band
    best = None
    for tenth in range(80, 1600):
        size = tenth / 10
        f = ImageFont.truetype(path, size)
        _, t, _, b = ink_box(f, text, 0)
        if best is None or abs((b - t + 1) - (bottom - top + 1)) < best[0]:
            best = (abs((b - t + 1) - (bottom - top + 1)), size)
    size = best[1]
    f = ImageFont.truetype(path, size)
    l, _, r, _ = ink_box(f, text, 0)
    gaps = max(len(text) - 1, 1)
    track = ((right - left + 1) - (r - l + 1)) / gaps
    if abs(track) < 0.6:  # within a pixel over the line: no spacing
        track = 0.0
    return size, track


def ink_colour(im, band):
    """The text colour: the commonest colour among the band's fully inked
    pixels (within 10% of the furthest from the row background), so one
    stray JPEG pixel cannot set it."""
    from collections import Counter
    top, bottom, left, right = band
    px = im.load()
    cells = []
    for y in range(top, bottom + 1):
        bg = px[5, y]
        for x in range(left, right + 1):
            cells.append((sum(abs(a - c) for a, c in zip(px[x, y], bg)), px[x, y]))
    far = max(d for d, _ in cells)
    return Counter(c for d, c in cells if d >= 0.9 * far).most_common(1)[0][0]


def ink_extent(im, band):
    """(top, bottom, left, right) of pixels clearly off the row background,
    searched a few rows around the band."""
    top, bottom, _, _ = band
    px = im.load()
    w = im.size[0]
    hits = [(y, x) for y in range(top - 6, bottom + 7) for x in range(w)
            if sum(abs(a - c) for a, c in zip(px[x, y], px[5, y])) > 60]
    ys = [y for y, _ in hits]
    xs = [x for _, x in hits]
    return min(ys), max(ys), min(xs), max(xs)


def draw_line(im, band, font_path, english, text):
    top, bottom, left, right = band
    w = im.size[0]
    size, track = calibrate(font_path, band, english)
    f = ImageFont.truetype(font_path, size)
    el, et, er, eb = ink_box(f, english, track)
    baseline = bottom - eb
    colour = ink_colour(im, band)
    # Paint the band with each row's own background (the covers are flat or
    # a vertical gradient, so column 5 holds the row's background).
    px = im.load()
    for y in range(top - 2, bottom + 3):
        bg = px[5, y]
        for x in range(0, w):
            px[x, y] = bg
    # Fit the translation, shrinking only if it is wider than the cover allows.
    while True:
        l, t, r, b = ink_box(f, text, track)
        if r - l + 1 <= w - 2 * MARGIN or size < 6:
            break
        size -= 0.5
        track *= 0.97
        f = ImageFont.truetype(font_path, size)
    x = (w - (r - l + 1)) / 2 - l
    d = ImageDraw.Draw(im)
    for ch in text:
        d.text((x, baseline), ch, font=f, fill=colour, anchor='ls')
        x += f.getlength(ch) + track
    return size, track


def build(rel, lang, verify=False):
    src = os.path.join(REPO, 'assets/books', rel)
    im = Image.open(src).convert('RGB')
    orig = im.copy()
    for band, font_path, english, translated in COVERS[rel][lang]:
        draw_line(im, band, font_path, english, english if verify else translated)
    if verify:
        # Per line: where the redrawn ink lands against where it was printed,
        # and its colour. Anti-aliasing makes a pixel count meaningless.
        for band, *_ in COVERS[rel][lang]:
            print(f'{rel} {band}: printed {ink_extent(orig, band)} '
                  f'{ink_colour(orig, band)}, redrawn {ink_extent(im, band)} '
                  f'{ink_colour(im, band)}', flush=True)
        im.save(os.path.join(os.environ.get('COVERS_OUT', '/tmp/claude-1000'),
                             'verify_' + rel.replace('/', '_')))
        return
    d, n = os.path.split(rel)
    out = os.path.join(REPO, 'assets/books', d, lang, n)
    os.makedirs(os.path.dirname(out), exist_ok=True)
    if n.endswith('.jpg'):
        im.save(out, quality=92)
    else:
        im.save(out, optimize=True)
    print('wrote', os.path.relpath(out, REPO), flush=True)


def main():
    verify = '--verify' in sys.argv
    for rel in COVERS:
        for lang in COVERS[rel]:
            build(rel, lang, verify)


if __name__ == '__main__':
    main()
