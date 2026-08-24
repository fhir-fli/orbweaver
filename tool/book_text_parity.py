#!/usr/bin/env python3
"""What printed content is missing from the app? (ProtocolBook / WHO Pocket Book)

Two earlier shapes of this failed and are recorded here so they are not retried:

1. `wvems_text_parity.py` compares each print page only against the one app page
   that claims it. Where a book's topics do not partition the print one-to-one —
   the ProtocolBook has 95 topics over 131 printed pages — that reports every
   relocated line as missing.

2. Line-level difflib against the whole app corpus (this file's first version)
   reported 2941 of 6412 print lines missing, which is noise, not a finding. The
   cause is measured, not guessed: PyMuPDF's dict "lines" are *visual* lines, and
   this book's narrow boxes wrap constantly, so the print side is full of
   fragments — "minora", "boluses", "urine)", "likely than DVT" — that cannot
   match a whole app sentence at any threshold.

So this compares **token shingles**, which survive both re-wrapping and
re-ordering. A print token counts as covered when it takes part in at least one
n-gram that also occurs somewhere in the app book. Runs of uncovered tokens are
reported as missing passages.

Footnote markers are dropped by typography, not by guesswork: in this PDF they are
superscript spans (size 6.0 against a 9.0 body, PyMuPDF flag bit 0), so
"Percentiles by Age143,144" becomes "Percentiles by Age" rather than a token the
app can never match.

Writes every row as it is produced.

    usage: pdfvenv/bin/python tool/book_text_parity.py <book> <out.tsv> [topics_dir]
           book = protocolbook | who_imci
           topics_dir overrides the app side, for the seeded-control run
"""
import re
import sys
from pathlib import Path

import pymupdf
import yaml

REPO = Path("/home/grey/dev/fhir/orbweaver")

BOOKS = {
    "protocolbook": {
        "pdf": REPO / "ProtocolBook eBook 1.7.pdf",
        "topics": REPO / "assets/books/protocolbook/topics",
        # measured: printed page P is PDF index P-1 (p.12 = index 11 = Triage)
        "offset": -1,
        "first": 12,
        "last": 158,
    },
    "who_imci": {
        "pdf": REPO / "9789241548373_eng.pdf",
        "topics": REPO / "assets/books/who_imci/topics",
        "offset": -1,
        "first": 1,
        "last": 412,
    },
}

N = 4              # shingle length in tokens
MIN_RUN = 4        # report a gap only once this many tokens in a row are uncovered
SUPERSCRIPT = 1    # PyMuPDF span flag bit 0

SKIP_KEYS = {
    "id", "anchor", "palette", "image", "link_id", "type", "variant", "shape",
    "severity", "kind", "provider_level", "population", "band", "scope",
    "version", "font_family", "category", "asset", "page_number", "flex",
    "column_flex", "column_widths", "column_align", "tags", "aliases",
    "last_reviewed", "layout", "list_subtitle",
}


def tokens(s):
    s = re.sub(r"\[([^\]]+)\]\([^)]*\)", r"\1", s)     # link -> label
    s = s.replace("**", "").replace("₂", "2").replace("µ", "u")
    s = s.replace("≥", ">=").replace("≤", "<=").replace("–", "-")
    s = re.sub(r"[^a-z0-9<>=./%-]+", " ", s.lower())
    return [t for t in s.split() if t not in {"-", ".", "/"}]


def shingles(toks, n=N):
    return {tuple(toks[i:i + n]) for i in range(len(toks) - n + 1)}


def print_blocks(page):
    """One joined string per printed block, superscript footnote markers removed."""
    out = []
    for block in page.get_text("dict").get("blocks", []):
        if block.get("type") != 0:
            continue
        lines = []
        for line in block.get("lines", []):
            txt = "".join(
                sp["text"] for sp in line.get("spans", [])
                if not (sp.get("flags", 0) & SUPERSCRIPT)
            )
            txt = txt.replace("\xa0", " ").strip()
            if txt:
                lines.append(txt)
        joined = " ".join(lines).strip(" •-–\t")
        joined = re.sub(r"\s+", " ", joined)
        if len(joined) >= 3 and not re.fullmatch(r"\d{1,3}", joined):
            out.append(joined)
    return out


def app_strings(node, acc):
    if isinstance(node, dict):
        for k, v in node.items():
            if k not in SKIP_KEYS:
                app_strings(v, acc)
    elif isinstance(node, list):
        for i in node:
            app_strings(i, acc)
    elif isinstance(node, str):
        acc.append(node)


def main():
    book = sys.argv[1]
    out_path = Path(sys.argv[2])
    cfg = BOOKS[book]
    topics = Path(sys.argv[3]) if len(sys.argv) > 3 else cfg["topics"]
    out_path.parent.mkdir(parents=True, exist_ok=True)

    fh = open(out_path, "w")
    fh.write("page\tuncovered_tokens\tcoverage_pct\tmissing_passage\n")
    fh.flush()

    # --- app side: every shingle the app says anywhere ------------------
    app_sh = set()
    app_tok_total = 0
    for f in sorted(topics.glob("*.yaml")):
        d = yaml.safe_load(f.read_text(encoding="utf-8"))["topic"]
        acc = []
        app_strings(d.get("blocks", []), acc)
        app_strings(d.get("pages", []), acc)
        if d.get("title"):
            acc.append(d["title"])
        # one token stream per topic, so a shingle may span adjacent strings
        t = []
        for s in acc:
            t.extend(tokens(s))
        app_tok_total += len(t)
        app_sh |= shingles(t)

    # The formulary is a sibling file, not a topic — pp.146-158 of the
    # ProtocolBook and Annex 2 of the WHO book live there, and leaving it out
    # scored those pages 0% covered when they are in fact fully carried.
    fpath = topics.parent / "formulary.yaml"
    if fpath.exists():
        acc = []
        app_strings(yaml.safe_load(fpath.read_text(encoding="utf-8")), acc)
        t = []
        for s in acc:
            t.extend(tokens(s))
        app_tok_total += len(t)
        app_sh |= shingles(t)
        print(f"--- formulary: {len(t)} tokens", flush=True)
    print(f"--- app: {app_tok_total} tokens, {len(app_sh)} distinct {N}-grams "
          f"from {len(list(topics.glob('*.yaml')))} topics", flush=True)

    doc = pymupdf.open(cfg["pdf"])
    grand_tok = grand_unc = 0
    for p in range(cfg["first"], cfg["last"] + 1):
        idx = p + cfg["offset"]
        if not (0 <= idx < doc.page_count):
            continue
        page_tok = page_unc = 0
        for blk in print_blocks(doc[idx]):
            t = tokens(blk)
            if not t:
                continue
            page_tok += len(t)
            covered = [False] * len(t)
            for i in range(len(t) - N + 1):
                if tuple(t[i:i + N]) in app_sh:
                    for j in range(i, i + N):
                        covered[j] = True
            # a block too short to shingle is covered only if it appears whole
            if len(t) < N:
                whole = any(tuple(t) == s[:len(t)] for s in app_sh) or \
                        any(all(x in s for x in t) for s in app_sh)
                covered = [whole] * len(t)
            i = 0
            while i < len(t):
                if covered[i]:
                    i += 1
                    continue
                j = i
                while j < len(t) and not covered[j]:
                    j += 1
                run = j - i
                page_unc += run
                if run >= MIN_RUN:
                    frag = " ".join(t[i:j])
                    fh.write(f"{p}\t{run}\t\t{frag}\n")
                    fh.flush()
                i = j
        cov = 100.0 * (page_tok - page_unc) / page_tok if page_tok else 100.0
        grand_tok += page_tok
        grand_unc += page_unc
        print(f"p.{p}: {cov:5.1f}% covered  ({page_unc}/{page_tok} tokens uncovered)",
              flush=True)
    overall = 100.0 * (grand_tok - grand_unc) / grand_tok if grand_tok else 100.0
    print(f"=== {book}: {overall:.1f}% of {grand_tok} printed tokens covered by the app; "
          f"{grand_unc} uncovered", flush=True)
    fh.close()


if __name__ == "__main__":
    main()
