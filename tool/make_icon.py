#!/usr/bin/env python3
"""Install the Orbweaver launcher icon at every size Android and iOS need.

The master is `assets/icon/orbweaver_master.png`, made from Grey's artwork with
two corrections:

  1. SOLID BACKGROUND, never a gradient. A gradient flattens badly at small
     sizes, and Apple rejects an alpha channel outright.
  2. EVERYTHING INSIDE 80% OF THE SQUARE. Android masks the icon to a circle,
     a squircle or a rounded square depending on the launcher, and the original
     ran to all four edges, so the web's left point and the book's right cover
     would have been clipped.

🛑 DO NOT "sharpen" this by drawing at the target pixel size without
supersampling. That was tried on 2026-09-03 and it is worse: hard pixel edges
give jagged, lumpy strokes. Small icons are SUPPOSED to be antialiased. The
softness that prompted the attempt was an artefact of viewing them magnified
4x with nearest-neighbour; at 1:1, which is what a phone shows, the full
composition holds down to 40 px. See assets/icon/candidates/ACTUAL_SIZE.png.

Nor is a separate simplified mark needed for the small sizes. That was also
tried, and dropping either half loses something the other cannot carry: without
the web the icon does not say Orbweaver, and without the book it does not say
what the app is.

Output is written and flushed per file.
"""

import io
import os
import sys

from PIL import Image
from _repo import REPO

ROOT = str(REPO)
NAVY = (30, 78, 140)          # 0xFF1E4E8C, the app bar colour
SAFE = 0.80                   # fraction of the square the artwork may occupy

MASTER = os.path.join(ROOT, 'assets/icon/orbweaver_master.png')

ANDROID = {'mdpi': 48, 'hdpi': 72, 'xhdpi': 96, 'xxhdpi': 144, 'xxxhdpi': 192}

IOS = {
    'Icon-App-20x20@1x.png': 20, 'Icon-App-20x20@2x.png': 40,
    'Icon-App-20x20@3x.png': 60, 'Icon-App-29x29@1x.png': 29,
    'Icon-App-29x29@2x.png': 58, 'Icon-App-29x29@3x.png': 87,
    'Icon-App-40x40@1x.png': 40, 'Icon-App-40x40@2x.png': 80,
    'Icon-App-40x40@3x.png': 120, 'Icon-App-60x60@2x.png': 120,
    'Icon-App-60x60@3x.png': 180, 'Icon-App-76x76@1x.png': 76,
    'Icon-App-76x76@2x.png': 152, 'Icon-App-83.5x83.5@2x.png': 167,
    'Icon-App-1024x1024@1x.png': 1024,
}


def load_master():
    if not os.path.exists(MASTER):
        raise SystemExit('missing master: %s' % MASTER)
    return Image.open(MASTER).convert('RGB')


def render(master, px, ss=4):
    """One icon at `px`, supersampled then downscaled so edges antialias."""
    S = px * ss
    canvas = Image.new('RGB', (S, S), NAVY)
    w, h = master.size
    k = (S * SAFE) / max(w, h)
    nw, nh = max(1, int(w * k)), max(1, int(h * k))
    art = master.resize((nw, nh), Image.LANCZOS)
    canvas.paste(art, ((S - nw) // 2, (S - nh) // 2))
    return canvas.resize((px, px), Image.LANCZOS)


def main():
    master = load_master()
    print('master %s %s' % (MASTER, master.size), flush=True)

    out = os.path.join(ROOT, 'assets/icon')
    render(master, 1024).save(os.path.join(out, 'orbweaver.png'))
    print('1024 -> assets/icon/orbweaver.png', flush=True)

    for name, px in sorted(ANDROID.items(), key=lambda kv: kv[1]):
        p = os.path.join(ROOT, 'android/app/src/main/res',
                         'mipmap-%s' % name, 'ic_launcher.png')
        os.makedirs(os.path.dirname(p), exist_ok=True)
        render(master, px).save(p)
        print('android %-8s %4d px' % (name, px), flush=True)

    for name, px in sorted(IOS.items(), key=lambda kv: kv[1]):
        p = os.path.join(ROOT,
                         'ios/Runner/Assets.xcassets/AppIcon.appiconset', name)
        render(master, px).save(p)
        print('ios     %-28s %4d px' % (name, px), flush=True)

    print('DONE', flush=True)
    return 0


if __name__ == '__main__':
    sys.exit(main())
