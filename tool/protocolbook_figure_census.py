#!/usr/bin/env python3
"""Which printed ProtocolBook pages carry a FIGURE the app renders as prose?

The mirror of the WHO chart pass. Grey's rule: if it is a flowchart in the
print, it is a flowchart in the app. So census what the print actually draws on
each page, and set it against what the app's topic for that page carries.

Two independent signals per printed page:
  - embedded raster images (`get_images`) — photographs and line drawings
  - vector drawing paths (`get_drawings`) — how flowcharts and boxes are drawn

Neither is a verdict. A page of tables also draws rules, so the vector count is
calibrated against known cases rather than assumed: pages whose app topic
already has a flowchart block set the "this is a figure" floor.

Writes every row as it is produced.

    usage: pdfvenv/bin/python tool/protocolbook_figure_census.py <out.tsv>
"""
import os
import re
import sys
from pathlib import Path

import pymupdf
import yaml

REPO = Path("/home/grey/dev/fhir/orbweaver")
PDF = REPO / "ProtocolBook eBook 1.7.pdf"
TOPICS = REPO / "assets/books/protocolbook/topics"
OFFSET = -1          # printed page P is PDF index P-1


def main():
    out = Path(sys.argv[1])
    out.parent.mkdir(parents=True, exist_ok=True)
    fh = open(out, "w")
    fh.write("page\ttopic\tprint_images\tprint_paths\tapp_blocks\thas_figure_block\n")
    fh.flush()

    # page -> owning topic (filenames are page-ordered: pb_016_*.yaml = p.16)
    tops = []
    for f in sorted(TOPICS.glob("*.yaml")):
        m = re.match(r"pb_(\d{3})_", f.name)
        if not m:
            continue
        d = yaml.safe_load(f.read_text(encoding="utf-8"))["topic"]
        types = sorted({t for t in re.findall(r'-\s*type:\s*"?([a-z_]+)"?',
                                              f.read_text(encoding="utf-8"))})
        tops.append((int(m.group(1)), f.name, types))
    tops.sort()

    def owner(p):
        o = None
        for pg, name, types in tops:
            if pg <= p:
                o = (pg, name, types)
            else:
                break
        return o

    doc = pymupdf.open(PDF)
    for p in range(12, 159):
        idx = p + OFFSET
        if not (0 <= idx < doc.page_count):
            continue
        pg = doc[idx]
        n_img = len(pg.get_images(full=True))
        n_path = len(pg.get_drawings())
        ow = owner(p)
        name = ow[1] if ow else "-"
        types = ow[2] if ow else []
        has_fig = any(t in types for t in ("flowchart", "image"))
        fh.write(f"{p}\t{name}\t{n_img}\t{n_path}\t{','.join(types)}\t{has_fig}\n")
        fh.flush()
        print(f"p.{p:<4} img={n_img:<3} paths={n_path:<5} {name:<36} "
              f"figure_block={has_fig}", flush=True)
    fh.close()


if __name__ == "__main__":
    main()
