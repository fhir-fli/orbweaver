#!/usr/bin/env python3
"""Put a hand translation (opus/<page>.json, {id: text}) into a copy of the
English page, exactly as run.py does for a model reply, then check it.
Writes outputs/opus-5-5-conversation/<page> and its .check.txt, one page at
a time. Run from tool/l10n/bakeoff/."""
import hashlib, json, os, re, subprocess, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import segments

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.abspath(os.path.join(HERE, '..', '..', '..'))
OUT = os.path.join(HERE, 'outputs', 'opus-5-5-conversation')
os.makedirs(OUT, exist_ok=True)
for page in open(os.path.join(HERE, 'pages.txt')).read().split():
    name = os.path.basename(page)
    src = os.path.join(HERE, 'opus', name + '.json')
    if not os.path.exists(src):
        continue
    english = os.path.join(REPO, page)
    tr = json.load(open(src))
    if sorted(tr) != sorted(segments.extract(english)):
        print(name, 'ids differ', flush=True); continue
    out = os.path.join(OUT, name)
    stamp = hashlib.sha256(open(english, 'rb').read()).hexdigest()
    open(out, 'w').write(f'# translated-from-sha256: {stamp}\n' + segments.reinsert(english, tr))
    r = subprocess.run(['dart', 'run', 'tool/l10n/check_pair.dart', english, out], cwd=REPO, capture_output=True, text=True)
    open(out + '.check.txt', 'w').write(r.stdout + r.stderr)
    print(name, re.search(r'problems: \S+', r.stdout).group(0), flush=True)
