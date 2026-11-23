#!/usr/bin/env python3
"""Translated copies of pictures that have English text drawn into them.

The pictures are scans or crops from the printed books; there is no source
file to re-letter. For each English label this script knows a rough box
around it, the font family, the English wording and the translation. It

  1. finds the label's ink inside the rough box: pixels that differ from the
     box's background (the commonest colour on the box's edge),
  2. calibrates a font size and a horizontal stretch so the ENGLISH wording,
     rendered by this script, has the same ink height and width as printed,
  3. paints the ink box with the background and draws the translation at
     that size and stretch, aligned the way the label is aligned (left,
     centre or right), squeezing or shrinking only if it would leave the
     space the label may use (`room`).

    python3 tool/l10n/images.py              # writes <dir>/es/<name>
    python3 tool/l10n/images.py --verify     # redraws the ENGLISH instead and
                                             # reports how far it is from the
                                             # original, label by label

--verify is the check on the instrument: when this script redraws the English
in place of the English, the picture should barely change. If it does not,
the box, font or colours are wrong and the Spanish cannot be trusted.
`--sheet DIR` also writes original | redrawn English | Spanish side by side.

Not here, on purpose:
- WHO pictures: licence 202610340 does not cover translation (WHO-LICENCE.md).
- pb_pain_faces.png: the Wong-Baker FACES scale. Its foundation allows no
  change to the scale without written permission and licenses translations
  itself; the page's score/label table already carries the Spanish words.
- Photos of real products (vials, packs, devices): the label on a real
  package is what the reader will see on the shelf.

The colour match is a mode over the box edge and the ink colour is the
pixel farthest from it; both are printed per label in --verify.
"""
import os
import sys

from PIL import Image, ImageDraw, ImageFont

REPO = os.path.abspath(os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..'))
URW = '/usr/share/fonts/opentype/urw-base35/'
SERIF = URW + 'NimbusRoman-Regular.otf'        # Times: the scanned charts
SERIF_BOLD = URW + 'NimbusRoman-Bold.otf'
CENTURY = URW + 'C059-Roman.otf'          # the charts' axis titles
SANS = '/usr/share/fonts/truetype/liberation/LiberationSans-Regular.ttf'
SANS_BOLD = '/usr/share/fonts/truetype/liberation/LiberationSans-Bold.ttf'
CONDENSED_BOLD = os.path.join(REPO, 'assets/fonts/RobotoCondensed-Bold.ttf')
CONDENSED = os.path.join(REPO, 'assets/fonts/RobotoCondensed-Regular.ttf')

PB = 'assets/books/protocolbook/images/'
WV = 'assets/books/wvems/images/'

# One label: rough box (left, top, right, bottom), font, English, Spanish,
# and options: align 'l'|'c'|'r' (default 'c'); rot 90 = text reads bottom
# to top; room (left, right) = how far the translation may spread.
def L(box, font, en, es, **opt):
    return dict(box=box, font=font, en=en, es=es, **opt)


def bp_chart(boxes, axis, axis_es, title=None, top_axis=False):
    """The four AAP 2017 BP-for-stature charts share their labels; only the
    positions differ. Order of [boxes]: title (SBP charts), top Stature (SBP
    charts), Stage 2, Stage 1, Elevated, Normal, Hypotension, left axis,
    right axis, bottom Stature (DBP charts)."""
    labels = []
    if title:
        # Right-aligned so the citation superscript after it stays attached.
        labels.append(L(None, SERIF, title[0], title[1], align='r', room=(330, 1150)))
    if top_axis:
        labels.append(L(None, CENTURY, 'Stature (cm)', 'Talla (cm)'))
    labels += [
        L(None, SERIF, 'Stage 2 HTN', 'HTA estadio 2'),
        L(None, SERIF, 'Stage 1 HTN', 'HTA estadio 1'),
        L(None, SERIF, 'Elevated BP', 'PA elevada', align='r'),
        L(None, SERIF, 'Normal BP', 'PA normal'),
        L(None, SERIF, 'Hypotension', 'Hipotensión'),
        L(None, CENTURY, axis, axis_es, rot=90),
        L(None, CENTURY, axis, axis_es, rot=90),
    ]
    if not top_axis:
        labels.append(L(None, CENTURY, 'Stature (cm)', 'Talla (cm)'))
    return with_boxes(labels, boxes)


IMAGES = {}  # path -> list of labels


def with_boxes(labels, boxes):
    assert len(labels) == len(boxes), (len(labels), len(boxes))
    return [dict(l, box=b) for l, b in zip(labels, boxes)]


def two_line_header(top_box, bottom_box, sup_box, sup, en, es, room):
    # flat: the table rule under the cell touches the descenders; the cell
    # itself is plain white.
    return [L(top_box, SERIF_BOLD, en[0], es[0], room=room, flat=True),
            L(bottom_box, SERIF_BOLD, en[1], es[1], room=room, sup=(sup_box, sup), flat=True)]


IMAGES[PB + 'pb_ecg_atrial_enlargement.png'] = (
    two_line_header((460, 30, 665, 68), (470, 68, 661, 107), (661, 68, 676, 89), 'b',
                    ('Left Atrial', 'Enlargement'), ('Crecimiento', 'auricular izquierdo'),
                    room=(418, 715))
    + two_line_header((820, 30, 1012, 68), (812, 68, 1006, 107), (1006, 70, 1018, 89), 'c',
                      ('Right Atrial', 'Enlargement'), ('Crecimiento', 'auricular derecho'),
                      room=(748, 1060)))

# Row labels of the ECG tables: Spanish abbreviations as the Spanish pages
# use them (BRD/BRI, HVI/HVD). "normal" is the same word and stays.
IMAGES[PB + 'pb_ecg_conduction.png'] = [
    L((27, 312, 121, 344), SERIF, 'RBBB', 'BRD', align='l', flat=True, sup=((121, 311, 132, 330), 'f')),
    L((27, 575, 118, 606), SERIF, 'LBBB', 'BRI', align='l', flat=True, sup=((118, 575, 131, 598), 'g')),
]
IMAGES[PB + 'pb_ecg_lvh.png'] = [
    L((0, 272, 70, 302), SERIF, 'LVH', 'HVI', align='l', flat=True, sup=((70, 272, 80, 290), 'e')),
]
IMAGES[PB + 'pb_ecg_rvh.png'] = [
    L((20, 314, 93, 346), SERIF, 'RVH', 'HVD', align='l', flat=True, sup=((92, 313, 104, 332), 'd')),
]

IMAGES[PB + 'pb_ecg_st_diagram.png'] = [
    # Right-aligned: the arrow to the baseline leaves from the label's end.
    # core 0.8: a soft scan, the letters are mostly grey; flat: arrows and
    # guide lines run beside the labels on a white ground.
    L((72, 273, 158, 296), SERIF, 'Baseline', 'Línea de base', align='r', room=(4, 158),
      core=0.8, flat=True),
    L((316, 176, 432, 200), SERIF, 'ST-elevation', 'Elevación del ST', align='l', room=(316, 440),
      core=0.8, flat=True),
    L((316, 318, 428, 345), SERIF, 'ST-segment', 'Segmento ST', core=0.8, flat=True),
]

# Two-line labels keep two lines; Spanish puts the noun first, so "PR /
# segment" becomes "Segmento / PR". Wave letters (P, Q, S, T, U) stay.
# The QRS label must stay between the Q and S lines (x 200 and 292).
GRID = (54, 48)  # ECG paper period in px, measured by autocorrelation
IMAGES[PB + 'pb_ecg_waveform.png'] = [
    L((143, 195, 190, 223), SERIF_BOLD, 'PR', 'Segmento', room=(95, 235), period=GRID),
    L((108, 232, 222, 264), SERIF_BOLD, 'segment', 'PR', period=GRID),
    L((315, 138, 358, 166), SERIF_BOLD, 'ST', 'Segmento', room=(272, 402), period=GRID),
    L((280, 176, 392, 206), SERIF_BOLD, 'segment', 'ST', period=GRID),
    L((80, 386, 140, 412), SERIF_BOLD, 'PR', 'Intervalo', room=(30, 190), period=GRID),
    L((52, 418, 165, 448), SERIF_BOLD, 'Interval', 'PR', period=GRID),
    L((212, 537, 286, 568), SERIF_BOLD, 'QRS', 'Intervalo', room=(204, 289), period=GRID),
    L((212, 571, 322, 600), SERIF_BOLD, 'interval', 'QRS', room=(204, 289), period=GRID),
    L((350, 468, 500, 496), SERIF_BOLD, 'ST interval', 'Intervalo ST', room=(300, 590), period=GRID),
    L((348, 590, 512, 619), SERIF_BOLD, 'QT interval', 'Intervalo QT', room=(300, 590), period=GRID),
    L((630, 676, 790, 714), SERIF, '1 large box', '1 cuadro grande', room=(560, 1085), period=GRID),
]

# Spanish sign names as pb_090's Spanish text gives them.
LEFT = (2, 176)  # the sign-name column
IMAGES[PB + 'pb_neo_ballard_neuro.png'] = [
    L((25, 6, 262, 48), SERIF_BOLD, 'Ballard Score', 'Puntuación de Ballard', align='l', room=(25, 470)),
    L((40, 55, 145, 98), SERIF_BOLD, 'SIGN', 'SIGNO', align='l', room=(25, 300)),
    L((495, 55, 1210, 98), SERIF_BOLD, 'NEUROMUSCULAR MATURITY SCORE',
      'PUNTUACIÓN DE MADUREZ NEUROMUSCULAR', room=(260, 1760)),
    L((35, 232, 150, 272), SERIF, 'Posture', 'Postura', room=LEFT),
    L((40, 383, 145, 420), SERIF, 'Square', 'Ventana', room=LEFT),
    L((30, 422, 157, 462), SERIF, 'Window', 'cuadrada', room=LEFT),
    L((55, 550, 130, 588), SERIF, 'Arm', 'Retroceso', room=LEFT),
    L((42, 590, 146, 630), SERIF, 'Recoil', 'del brazo', room=LEFT),
    L((28, 710, 157, 748), SERIF, 'Popliteal', 'Ángulo', room=LEFT),
    L((50, 750, 140, 790), SERIF, 'Angle', 'poplíteo', room=LEFT),
    L((50, 850, 135, 888), SERIF, 'Scarf', 'Signo de', room=LEFT),
    L((55, 890, 130, 930), SERIF, 'Sign', 'la bufanda', room=LEFT),
    L((40, 980, 145, 1020), SERIF, 'Heel to', 'Talón a', room=LEFT),
    L((63, 1020, 123, 1060), SERIF, 'Ear', 'oreja', room=LEFT),
]

# "MT normal", as the Spanish caption under the picture says it.
IMAGES[PB + 'pb_otitis_media_tm.png'] = [
    L((180, 32, 360, 76), SERIF, 'Normal TM', 'MT normal', flat=True),
    L((675, 32, 948, 76), SERIF, 'Acute Otitis Media', 'Otitis media aguda', room=(560, 1075), flat=True),
]

# Jerry-can pain scale (ProtocolBook art). Labels read bottom to top, one
# per band between the rules; Spanish as pb_079's Spanish table. The print's
# "Overwhelmign" typo is the English input here, so the redraw check
# compares like with like; the Spanish has no typo to carry.
IMAGES[PB + 'pb_pain_jerrycans.png'] = [
    L((390, 36, 432, 366), SERIF_BOLD, 'Overwhelmign Pain', 'Dolor insoportable', rot=90, flat=True),
    L((390, 374, 432, 660), SERIF_BOLD, 'Severe Pain', 'Dolor intenso', rot=90, flat=True),
    L((390, 668, 432, 969), SERIF_BOLD, 'Moderate Pain', 'Dolor moderado', rot=90, flat=True),
    L((390, 977, 432, 1268), SERIF_BOLD, 'More Pain', 'Más dolor', rot=90, flat=True),
    L((390, 1276, 432, 1549), SERIF_BOLD, 'Mild Pain', 'Dolor leve', rot=90, flat=True),
    L((390, 1557, 432, 1821), SERIF_BOLD, 'No Pain', 'Sin dolor', rot=90, flat=True),
]

# Rumack-Matthew nomogram. "acetaminofén", as the Spanish caption under it.
IMAGES[PB + 'pb_paracetamol_nomogram.png'] = [
    L((572, 68, 892, 100), SANS_BOLD, 'Rumack-Matthew Line', 'Línea de Rumack-Matthew',
      room=(542, 922), flat=True),
    L((468, 446, 684, 474), SANS_BOLD, 'Treatment Line', 'Línea de tratamiento',
      room=(432, 720), flat=True),
    L((452, 761, 934, 789), SANS_BOLD, 'Treatment should be administered',
      'Administre el tratamiento si el nivel', room=(388, 998), flat=True),
    L((506, 791, 881, 818), SANS_BOLD, 'if level is above solid line',
      'está por encima de la línea continua', room=(388, 998), flat=True),
    L((60, 20, 96, 900), SANS_BOLD, 'ACETAMINOPHEN PLASMA CONCENTRATION',
      'CONCENTRACIÓN PLASMÁTICA DE ACETAMINOFÉN', rot=90, flat=True),
    # Cut off by the bottom of the picture; same lettering as the axis title
    # above, whose capitals are 22 px (ink 66–88 across).
    L((700, 955, 1040, 976), SANS_BOLD, 'HOURS POSTINGESTION', 'HORAS TRAS LA INGESTA',
      cap=22, room=(600, 1185), flat=True),
]

# Heart- and breathing-rate percentile charts: the age axis.
IMAGES[PB + 'pb_vitals_heart_rate.png'] = [
    L((48, 468, 104, 490), SANS, 'Birth', 'Nacimiento', room=(8, 114), flat=True, core=0.8),
    L((158, 498, 265, 522), SANS, 'Age in Months', 'Edad en meses', room=(110, 320), flat=True, core=0.8),
    L((512, 496, 604, 519), SANS, 'Age in Years', 'Edad en años', room=(450, 680), flat=True, core=0.8),
]
IMAGES[PB + 'pb_vitals_resp_rate.png'] = [
    L((103, 486, 210, 507), SANS, 'Age in Months', 'Edad en meses', room=(60, 268), flat=True, core=0.8),
    L((467, 485, 557, 506), SANS, 'Age in Years', 'Edad en años', room=(400, 640), flat=True, core=0.8),
]

# WVEMS rule of nines; "SCT" as the Spanish caption under it.
IMAGES[WV + 'bsa_rule_of_nines.png'] = [
    L((548, 40, 1162, 150), CONDENSED_BOLD, 'BSA percentage', 'Porcentaje de SCT', align='r',
      room=(20, 1210)),
    L((548, 151, 1162, 254), CONDENSED, '(front and back)', '(frente y espalda)', align='r',
      room=(20, 1210)),
]

IMAGES[PB + 'pb_bp_boys_dbp.png'] = bp_chart([
    (470, 120, 735, 180), (635, 290, 895, 355), (1168, 246, 1408, 281),
    (795, 530, 1025, 590), (1000, 880, 1255, 945),
    (165, 470, 220, 675), (1530, 470, 1590, 675), (750, 1140, 1010, 1195)],
    'DBP (mmHg)', 'PAD (mmHg)')
IMAGES[PB + 'pb_bp_girls_dbp.png'] = bp_chart([
    (470, 130, 725, 185), (630, 310, 885, 365), (1165, 305, 1405, 355),
    (770, 585, 995, 640), (1055, 915, 1300, 970),
    (160, 465, 210, 665), (1540, 470, 1595, 665), (745, 1135, 1005, 1190)],
    'DBP (mmHg)', 'PAD (mmHg)')
IMAGES[PB + 'pb_bp_boys_sbp.png'] = bp_chart([
    (520, 0, 1145, 40), (765, 43, 995, 80),
    (460, 250, 712, 305), (615, 545, 870, 600), (1165, 492, 1405, 540),
    (770, 788, 995, 842), (1042, 1045, 1288, 1097),
    (170, 590, 228, 790), (1540, 590, 1598, 790)],
    'SBP (mmHg)', 'PAS (mmHg)',
    title=('1 to 17 years: Boys BP-for-Stature', '1 a 17 años: PA según talla, niños'),
    top_axis=True)
IMAGES[PB + 'pb_bp_girls_sbp.png'] = bp_chart([
    (520, 0, 1141, 40), (745, 38, 1005, 85),
    (475, 250, 725, 305), (580, 470, 830, 525), (1160, 420, 1400, 470),
    (770, 718, 995, 772), (980, 1015, 1225, 1072),
    (170, 590, 228, 790), (1530, 590, 1590, 790)],
    'SBP (mmHg)', 'PAS (mmHg)',
    title=('1 to 17 years: Girls BP-for-Stature', '1 a 17 años: PA según talla, niñas'),
    top_axis=True)


# ---------------------------------------------------------------- drawing

def colour_distance(a, b):
    return sum(abs(x - y) for x, y in zip(a[:3], b[:3]))


def background(im, box):
    """Commonest colour on the edge of [box]."""
    l, t, r, b = box
    px = im.load()
    counts = {}
    edge = [(x, y) for x in range(l, r) for y in (t, b - 1)] + \
           [(x, y) for y in range(t, b) for x in (l, r - 1)]
    for x, y in edge:
        c = tuple(px[x, y][:3])
        counts[c] = counts.get(c, 0) + 1
    return max(counts, key=counts.get)


def ink_bbox(im, box, bg, thresh=90, skip=None, core=0.35):
    """Tight box of the label's ink inside [box], and the ink colour.

    The ink colour is the pixel farthest from [bg]. A pixel counts as ink when
    it is much nearer the ink colour than the background, so the edge of a
    neighbouring grey band (between the two) is not mistaken for text.
    """
    l, t, r, b = box
    px = im.load()
    far, far_d = bg, 0
    for y in range(t, b):
        for x in range(l, r):
            d = colour_distance(px[x, y], bg)
            if d > far_d:
                far, far_d = px[x, y][:3], d
    assert far_d > thresh, f'no ink in {box}'
    xs, ys = [], []
    for y in range(t, b):
        for x in range(l, r):
            if skip and skip[0] <= x < skip[2] and skip[1] <= y < skip[3]:
                continue  # another label's ink (a superscript) inside this box
            p = px[x, y]
            if colour_distance(p, far) < core * colour_distance(p, bg):
                xs.append(x)
                ys.append(y)
    return (min(xs), min(ys), max(xs) + 1, max(ys) + 1), far


def render(text, font_path, size, stretch):
    """Coverage mask of the text, tight to its ink, stretched horizontally.

    Returns the mask and the ink's top and bottom relative to the baseline.
    """
    f = ImageFont.truetype(font_path, size)
    l, t, r, b = f.getbbox(text, anchor='ls')
    mask = Image.new('L', (r - l, b - t), 0)
    ImageDraw.Draw(mask).text((-l, -t), text, font=f, fill=255, anchor='ls')
    if stretch != 1:
        mask = mask.resize((max(1, round(mask.width * stretch)), mask.height), Image.LANCZOS)
    return mask, (t, b)


def erase(im, box, bg, flat=False, orig=None, ink=None, period=None):
    """Remove the old label inside [box].

    On a plain background ([bg] all round the box), or when [flat], it is a
    flat fill. Otherwise (ECG paper, a band edge crossing the label) only the
    ink itself is removed: the pixels near the ink colour, grown by 2 px for
    the antialiased edge, are filled in from their surroundings (OpenCV's
    Telea inpainting), so the grid or the band edge carries on through.
    """
    l, t, r, b = box
    px = im.load()
    above = [px[x, t - 1] for x in range(l, r)] if t > 0 else []
    below = [px[x, b] for x in range(l, r)] if b < im.height else []
    sides = [px[l - 1, y] for y in range(t, b)] if l > 0 else []
    sides += [px[r, y] for y in range(t, b)] if r < im.width else []
    ring = above + below + sides
    if flat or all(colour_distance(p, bg) < 40 for p in ring):
        ImageDraw.Draw(im).rectangle((l, t, r - 1, b - 1), fill=bg)
        return
    import cv2
    import numpy as np
    src = orig if orig is not None else im
    crop = np.array(im.crop(box))
    ocrop = np.array(src.crop(box)).astype(int)
    far = np.array(ink, dtype=int)
    d_ink = np.abs(ocrop - far).sum(axis=2)
    d_bg = np.abs(ocrop - np.array(bg, dtype=int)).sum(axis=2)
    mask = (d_ink < 0.8 * d_bg).astype(np.uint8) * 255
    mask = cv2.dilate(mask, np.ones((5, 5), np.uint8))
    if period:
        # Printed grid paper: copy each ink pixel from the same spot one grid
        # period away (the nearest such spot that is not ink itself).
        fill_from_period(im, src, box, mask > 0, period, far, np.array(bg, dtype=int))
        return
    out = cv2.inpaint(crop, mask, 3, cv2.INPAINT_TELEA)
    im.paste(Image.fromarray(out), (l, t))


def fill_from_period(im, src, box, mask, period, far, bg):
    import numpy as np
    l, t, r, b = box
    a = np.array(src).astype(int)
    out = np.array(im)
    d_ink = np.abs(a - far).sum(axis=2)
    d_bg = np.abs(a - bg).sum(axis=2)
    inky = d_ink < 0.8 * d_bg
    px, py = period
    offsets = sorted(((i * px, j * py) for i in range(-3, 4) for j in range(-3, 4) if i or j),
                     key=lambda o: o[0] ** 2 + o[1] ** 2)
    h, w = inky.shape
    for yy, xx in zip(*np.nonzero(mask)):
        x, y = l + xx, t + yy
        for dx, dy in offsets:
            sx, sy = x + dx, y + dy
            if 0 <= sx < w and 0 <= sy < h and not inky[max(sy - 2, 0):sy + 3, max(sx - 2, 0):sx + 3].any() \
                    and not (l <= sx < r and t <= sy < b):
                out[y, x] = a[sy, sx]
                break
    im.paste(Image.fromarray(out.astype(np.uint8)))


def calibrate(en, font_path, w, h):
    """Font size whose English ink is [h] tall, and the stretch that makes it [w] wide."""
    best = None
    for size in range(6, 400):
        tile, _ = render(en, font_path, size, 1)
        if best is None or abs(tile.height - h) < abs(best[1].height - h):
            best = (size, tile)
        if tile.height > h + 2:
            break
    size, tile = best
    return size, w / tile.width


def draw_label(im, orig, lab, text, report):
    """Measure the label on the untouched [orig]; paint on [im].

    Measuring on the original matters: a translation drawn earlier can reach
    into the next label's box and would be taken for its ink.
    """
    rot = lab.get('rot', 0)
    l, t, r, b = lab['box']
    if rot:
        # Work on the crops turned so the text reads left to right.
        region = im.crop((l, t, r, b)).rotate(-rot, expand=True)
        region_orig = orig.crop((l, t, r, b)).rotate(-rot, expand=True)
        sub = dict(lab, box=(0, 0, region.width, region.height), rot=0)
        draw_label(region, region_orig, sub, text, report)
        im.paste(region.rotate(rot, expand=True), (l, t))
        return
    bg = background(orig, lab['box'])
    ink, colour = ink_bbox(orig, lab['box'], bg, skip=lab['sup'][0] if 'sup' in lab else None,
                           core=lab.get('core', 0.35))
    il, it, ir, ib = ink
    # cap: the label runs off the picture's edge, so its visible ink is not
    # its height; the printed cap height is given instead (see the label).
    size, stretch = calibrate(lab['en'], lab['font'], ir - il, lab.get('cap', ib - it))
    room_l, room_r = lab.get('room', (l, r))
    tile, (top, _) = render(text, lab['font'], size, stretch)
    if tile.width > room_r - room_l:  # squeeze to the room, no further than 80%
        squeeze = max(0.8, (room_r - room_l) / tile.width)
        tile, (top, _) = render(text, lab['font'], size, stretch * squeeze)
        while tile.width > room_r - room_l and size > 6:
            size -= 1
            tile, (top, _) = render(text, lab['font'], size, stretch * squeeze)
    align = lab.get('align', 'c')
    if align == 'l':
        x = il
    elif align == 'r':
        x = ir - tile.width
    else:
        x = (il + ir) // 2 - tile.width // 2
    x = min(max(x, room_l), room_r - tile.width)
    # Same baseline as the English: its ink bottom sits [en_bottom] below it.
    _, (_, en_bottom) = render(lab['en'], lab['font'], size, stretch)
    y = ib - en_bottom + top
    if 'cap' in lab:  # cut at the bottom: keep the top of the letters instead
        _, (en_top, _) = render(lab['en'], lab['font'], size, stretch)
        y = it - en_top + top
    pad = 5  # the antialiased edge around the ink core
    erase(im, (max(il - pad, l), max(it - pad, t), min(ir + pad, r), min(ib + pad, b)), bg,
          flat=lab.get('flat', False), orig=orig, ink=colour, period=lab.get('period'))
    if 'sup' in lab:
        # A citation superscript after the label: erased now, redrawn after
        # the label's new end, same size and offset from the last letter.
        sbox, letter = lab['sup']
        sbg = background(orig, sbox)
        sink, scol = ink_bbox(orig, sbox, sbg)
        erase(im, (sink[0] - 2, sink[1] - 2, sink[2] + 2, sink[3] + 2), sbg, flat=True)
    im.paste(Image.new('RGB', tile.size, colour), (x, y), tile)
    if 'sup' in lab:
        ssize, sstretch = calibrate(letter, lab['font'], sink[2] - sink[0], sink[3] - sink[1])
        stile, _ = render(letter, lab['font'], ssize, sstretch)
        sx = x + tile.width + (sink[0] - ir)
        im.paste(Image.new('RGB', stile.size, scol), (sx, sink[1]), stile)
    report.append(dict(en=lab['en'], text=text, bg=bg, colour=colour, size=size,
                       stretch=round(stretch, 3), ink=ink, at=(x, y, x + tile.width, y + tile.height)))


def build(path, labels, english):
    orig = Image.open(os.path.join(REPO, path)).convert('RGB')
    im = orig.copy()
    report = []
    for lab in labels:
        draw_label(im, orig, lab, lab['en'] if english else lab['es'], report)
    return im, report


def diff(a, b, box):
    """Mean per-pixel channel difference inside [box], 0..255."""
    ca, cb = a.crop(box), b.crop(box)
    pa, pb = ca.load(), cb.load()
    total = 0
    for y in range(ca.height):
        for x in range(ca.width):
            total += colour_distance(pa[x, y], pb[x, y]) / 3
    return total / (ca.width * ca.height)


def out_path(path):
    d, n = path.rsplit('/', 1)
    return f'{d}/es/{n}'


def main():
    verify = '--verify' in sys.argv
    sheet = sys.argv[sys.argv.index('--sheet') + 1] if '--sheet' in sys.argv else None
    only = sys.argv[sys.argv.index('--only') + 1] if '--only' in sys.argv else None
    for path, labels in IMAGES.items():
        if only and only not in path:
            continue
        assert '/who_imci/' not in path, path
        original = Image.open(os.path.join(REPO, path)).convert('RGB')
        en, report = build(path, labels, english=True)
        for lab, rep in zip(labels, report):
            box = lab['box']
            print(f"{path.rsplit('/', 1)[1]}\t{lab['en']}\tsize {rep['size']}\tstretch {rep['stretch']}"
                  f"\tbg {rep['bg']}\tink {rep['colour']}\tdiff {diff(original, en, box):.1f}", flush=True)
        es, _ = build(path, labels, english=False)
        if not verify:
            target = os.path.join(REPO, out_path(path))
            os.makedirs(os.path.dirname(target), exist_ok=True)
            es.save(target)
            print(f'wrote {out_path(path)}', flush=True)
        if sheet:
            os.makedirs(sheet, exist_ok=True)
            w, h = original.size
            s = Image.new('RGB', (w * 3 + 20, h), (255, 255, 255))
            s.paste(original, (0, 0))
            s.paste(en, (w + 10, 0))
            s.paste(es, (2 * w + 20, 0))
            s.save(os.path.join(sheet, path.rsplit('/', 1)[1]))


if __name__ == '__main__':
    main()
