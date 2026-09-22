#!/usr/bin/env python3
"""Sweep every page of the ProtocolBook for text that is written into the PDF but
CLIPPED AWAY at paint time -- the p.60 "Otherwise treat" failure mode.

Word text boxes with a fixed height lay out their overflow, emit it into the content
stream, then clip it. Extraction ignores the clip, the renderer honours it. So the
text is in the file, is copy-pasteable and reaches screen readers, but never prints.
It is invisible to proofreading and to page renders.

Method: walk the page tree, inflate each page's content stream, track the q/Q graphics
state stack and the clip rectangle set by "x y w h re W n" / "W* n", track the text
matrix, and for every text-showing operator compare the baseline against the clip in
force. Report every run whose baseline falls outside it.

Writes incrementally.
"""
import re
import zlib
from pathlib import Path
from _repo import REPO

PDF = (REPO / 'ProtocolBook eBook 1.7.pdf')
OUT = Path('/tmp/claude-1000/-home-grey-dev-fhir/8f9442b1-043e-47a0-a2fe-e29e007cc633/scratchpad/clipped_text.tsv')

data = PDF.read_bytes()

# ---------- object index ----------
objs = {}
for m in re.finditer(rb'(?<![0-9])(\d+)\s+0\s+obj\b', data):
    objs[int(m.group(1))] = m.end()


def raw_obj(n):
    if n not in objs:
        return b''
    start = objs[n]
    end = data.find(b'endobj', start)
    return data[start:end if end != -1 else start + 4000]


def stream_of(n):
    blob = raw_obj(n)
    m = re.search(rb'stream\r?\n', blob)
    if not m:
        return None
    start = objs[n] + m.end()
    end = data.find(b'endstream', start)
    try:
        return zlib.decompress(data[start:end])
    except Exception:
        return data[start:end]


# ---------- page tree ----------
def kids_of(n, acc, seen):
    if n in seen:
        return
    seen.add(n)
    blob = raw_obj(n)[:4000].decode('latin-1', 'replace')
    if re.search(r'/Type\s*/Page\b(?!s)', blob):
        acc.append(n)
        return
    km = re.search(r'/Kids\s*\[(.*?)\]', blob, re.S)
    if not km:
        return
    for kid in re.findall(r'(\d+)\s+0\s+R', km.group(1)):
        kids_of(int(kid), acc, seen)


root = re.search(rb'/Root\s+(\d+)\s+0\s+R', data)
cat = raw_obj(int(root.group(1)))[:2000].decode('latin-1', 'replace')
pages_ref = int(re.search(r'/Pages\s+(\d+)\s+0\s+R', cat).group(1))
pages = []
kids_of(pages_ref, pages, set())
print(f'page tree: {len(pages)} pages', flush=True)

# ---------- content parsing ----------
TOKEN = re.compile(rb"""
    \((?:\\.|[^\\()])*\)      | # literal string
    /[^\s/\[\]<>(){}]+        | # name
    [-+]?\d*\.?\d+            | # number
    \[ | \] | << | >>         |
    [A-Za-z'"*]+                # operator
""", re.X)

STR = re.compile(rb'\((?:\\.|[^\\()])*\)')


def unesc(b):
    s = b[1:-1]
    s = re.sub(rb'\\([nrtbf()\\])', lambda m: {
        b'n': b'\n', b'r': b'\r', b't': b'\t', b'b': b'\b',
        b'f': b'\f', b'(': b'(', b')': b')', b'\\': b'\\'}[m.group(1)], s)
    return s.decode('latin-1', 'replace')


fh = open(OUT, 'w')
fh.write('page\tbaseline_x\tbaseline_y\tclip\tdelta\ttext\n')
fh.flush()

found = 0
pages_with = set()

for pageno, pobj in enumerate(pages, start=1):
    blob = raw_obj(pobj)[:6000].decode('latin-1', 'replace')
    cm = re.search(r'/Contents\s+(\d+)\s+0\s+R', blob)
    if cm:
        streams = [int(cm.group(1))]
    else:
        am = re.search(r'/Contents\s*\[(.*?)\]', blob, re.S)
        streams = [int(x) for x in re.findall(r'(\d+)\s+0\s+R', am.group(1))] if am else []
    content = b''
    for sn in streams:
        s = stream_of(sn)
        if s:
            content += s + b'\n'
    if not content:
        continue

    toks = [t.group(0) for t in TOKEN.finditer(content)]
    stack = []              # saved clips
    clip = None             # (x0,y0,x1,y1)
    path = []               # pending numbers for re
    tm = (0.0, 0.0)
    operands = []

    i = 0
    while i < len(toks):
        t = toks[i]
        if re.fullmatch(rb'[-+]?\d*\.?\d+', t):
            operands.append(float(t))
            i += 1
            continue
        if t.startswith(b'(') or t.startswith(b'/') or t in (b'[', b']', b'<<', b'>>'):
            i += 1
            continue

        op = t
        if op == b'q':
            stack.append(clip)
        elif op == b'Q':
            clip = stack.pop() if stack else None
        elif op == b're' and len(operands) >= 4:
            x, y, w, h = operands[-4:]
            path = [x, y, x + w, y + h]
        elif op in (b'W', b'W*'):
            if path:
                clip = tuple(path)
        elif op == b'Tm' and len(operands) >= 6:
            tm = (operands[-2], operands[-1])
        elif op in (b'Td', b'TD') and len(operands) >= 2:
            tm = (tm[0] + operands[-2], tm[1] + operands[-1])
        elif op in (b'Tj', b'TJ', b"'", b'"'):
            # gather the text of this show op
            j = i
            k = j - 1          # start BEFORE the show operator itself
            while k > 0 and toks[k] not in (b'Tj', b'TJ', b"'", b'"', b'Tm', b'Td', b'TD', b'BT'):
                k -= 1
            chunk = b''.join(x for x in toks[k:j] if x.startswith(b'('))
            txt = ''.join(unesc(m.group(0)) for m in STR.finditer(chunk))
            if clip and txt.strip():
                x, y = tm
                x0, y0, x1, y1 = clip
                # a baseline below the clip bottom (or above its top) is not painted
                dy = 0.0
                if y < y0:
                    dy = y - y0
                elif y > y1:
                    dy = y - y1
                dx = 0.0
                if x < x0:
                    dx = x - x0
                elif x > x1:
                    dx = x - x1
                if dy < -1.0 or dy > 1.0 or dx < -1.0 or dx > 1.0:
                    found += 1
                    pages_with.add(pageno)
                    fh.write(f'{pageno}\t{x:.2f}\t{y:.2f}\t'
                             f'{x0:.2f},{y0:.2f},{x1:.2f},{y1:.2f}\t'
                             f'{dy if dy else dx:.2f}\t{txt}\n')
                    fh.flush()
                    print(f'p{pageno}: y={y:.2f} clip_y={y0:.2f}..{y1:.2f} '
                          f'delta={dy:.2f}  {txt!r}', flush=True)
        operands = []
        i += 1

    if pageno % 25 == 0:
        print(f'  ... swept {pageno} pages, {found} hits so far', flush=True)

fh.write(f'# {found} clipped runs on {len(pages_with)} pages: '
         f'{sorted(pages_with)}\n')
fh.flush()
fh.close()
print(f'DONE: {found} clipped runs on {len(pages_with)} pages -> {OUT}', flush=True)
