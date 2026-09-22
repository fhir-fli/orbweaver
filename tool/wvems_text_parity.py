#!/usr/bin/env python3
"""Which printed lines are missing from the app, and which app lines are invented?

The typography audit reports the totals — 256 print body lines with no
counterpart in the app, 123 app body lines with no source in the print, across
"eleven pages" — but names only four of those pages. Restoring the book needs
the actual per-page list, so this re-derives it.

For each odd prose page: pull the print's body lines out of the PDF, pull the
app's rendered strings out of that page's YAML, normalise both, and match them
with difflib. Anything unmatched in either direction is reported.

Deliberately noisy in one direction: a line the app has *reworded* shows up
twice, once as a missing print line and once as an extra app line, which is
exactly the pair a human needs to see to judge it.

Writes every row as it is produced.

    usage: pdfvenv/bin/python tool/wvems_text_parity.py <out.tsv> [first] [last]
"""
import re
import sys
from difflib import SequenceMatcher
from pathlib import Path

import pymupdf
import yaml
from _repo import REPO

REPO = REPO
PDF = REPO / "2026-WVEMS-Protocols.pdf"
TOPICS = REPO / "assets/books/wvems/topics"

MATCH_MIN = 0.72  # the audit's threshold

# Structural furniture, not body text.
SKIP_PREFIX = ("Alias:", "NEMSIS", "Reviewed:", "Page ", "[Ver:")
SKIP_EXACT = {
    "References", "Notes", "Pediatrics", "Medication", "Medications",
    "Poor Perfusion", "Critical Arrhythmia", "PDE5 Inhibitors",
}

# YAML keys that never render as body text.
SKIP_KEYS = {
    "id", "anchor", "palette", "image", "link_id", "type", "variant", "shape",
    "severity", "kind", "provider_level", "population", "band", "scope",
    "version", "font_family", "category", "asset", "page_number", "flex",
    "column_flex", "column_widths", "column_align", "tags", "aliases",
    "last_reviewed", "layout", "list_subtitle",
}


def norm(s):
    s = re.sub(r"\[([^\]]+)\]\([^)]*\)", r"\1", s)          # link -> label
    s = re.sub(r"\{[EAIP]?(\(CC\))?\}", "", s)               # badge token
    s = s.replace("**", "").replace("₂", "2")
    s = re.sub(r"[^a-z0-9]+", " ", s.lower())
    return s.strip()


def print_lines(page, title=""):
    out = []
    for block in page.get_text("dict").get("blocks", []):
        if block.get("type") != 0:
            continue
        for line in block.get("lines", []):
            txt = "".join(
                ch["c"] for span in line.get("spans", []) for ch in span.get("chars", [])
            ) if line.get("spans") and "chars" in line["spans"][0] else "".join(
                span["text"] for span in line.get("spans", [])
            )
            txt = txt.replace("\xa0", " ").strip(" •-–")
            if len(txt) < 6 or txt.startswith(SKIP_PREFIX) or txt in SKIP_EXACT:
                continue
            # the running foot repeats the protocol title, and the margin
            # carries a "Mon YYYY" review stamp — furniture, not body text
            if re.fullmatch(r"[A-Z][a-z]{2} \d{4}", txt) or txt == title:
                continue
            out.append(txt)
    return out


def app_strings(node, acc):
    if isinstance(node, dict):
        for k, v in node.items():
            if k in SKIP_KEYS:
                continue
            app_strings(v, acc)
    elif isinstance(node, list):
        for i in node:
            app_strings(i, acc)
    elif isinstance(node, str):
        for ln in node.split("\n"):
            ln = ln.strip(" -•")
            if len(ln) >= 6 and ln not in SKIP_EXACT:
                acc.append(ln)


def main():
    out_path = Path(sys.argv[1])
    first = int(sys.argv[2]) if len(sys.argv) > 2 else 5
    last = int(sys.argv[3]) if len(sys.argv) > 3 else 95
    out_path.parent.mkdir(parents=True, exist_ok=True)
    fh = open(out_path, "w")
    fh.write("page\tside\tbest\ttext\n")
    fh.flush()

    doc = pymupdf.open(PDF)
    totals = {}
    for pno in range(first, last + 1, 2):
        even = pno - 1
        f = TOPICS / f"wvems_2026_{even:03d}.yaml"
        if not f.exists():
            continue
        doc_y = yaml.safe_load(f.read_text())["topic"]
        block = next(
            (p for p in doc_y.get("pages", []) if p.get("page_number") == pno), None
        )
        if block is None:
            continue
        app = []
        app_strings(block.get("blocks", []), app)
        pri = print_lines(doc[pno - 1], doc_y.get("title", ""))

        def best(needle, hay):
            b = 0.0
            for h in hay:
                r = SequenceMatcher(None, norm(needle), norm(h)).ratio()
                b = max(b, r)
            return b

        miss = [(t, best(t, app)) for t in pri]
        miss = [(t, r) for t, r in miss if r < MATCH_MIN]
        extra = [(t, best(t, pri)) for t in app]
        extra = [(t, r) for t, r in extra if r < MATCH_MIN]
        for t, r in miss:
            fh.write(f"{pno}\tprint-only\t{r:.2f}\t{t}\n")
        for t, r in extra:
            fh.write(f"{pno}\tapp-only\t{r:.2f}\t{t}\n")
        fh.flush()
        totals[pno] = (len(miss), len(extra))
        print(f"p.{pno}: {len(miss)} print-only, {len(extra)} app-only", flush=True)
    fh.close()

    print("\nworst pages by print-only lines:", flush=True)
    for pno, (m, e) in sorted(totals.items(), key=lambda kv: -kv[1][0])[:14]:
        print(f"  p.{pno}: {m} missing, {e} invented", flush=True)


if __name__ == "__main__":
    main()
