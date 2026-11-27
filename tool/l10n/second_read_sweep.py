#!/usr/bin/env python3
"""List second-read pages whose findings are not yet in ADJUDICATION.md.

A page counts as adjudicated when its file name (without .yaml) appears in
ADJUDICATION.md; the ProtocolBook formulary appears as "protocolbook
formulary". Prints one UNADJUDICATED line per page, then "swept N".
"""
import glob
import json
import os

HERE = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'second_read')
adj = open(os.path.join(HERE, 'ADJUDICATION.md')).read()
files = glob.glob(os.path.join(HERE, '*.json'))
for f in sorted(files):
    d = json.load(open(f))
    page = d['page']
    name = os.path.basename(page).replace('.yaml', '')
    key = 'protocolbook formulary' if page.endswith('protocolbook/formulary.yaml') else name
    if d['findings'] and key not in adj:
        print(f'UNADJUDICATED {page} {len(d["findings"])}', flush=True)
print(f'swept {len(files)}', flush=True)
