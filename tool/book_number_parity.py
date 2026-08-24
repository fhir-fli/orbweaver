#!/usr/bin/env python3
"""Which printed doses, thresholds and ages does the app not carry?

Text parity does not work on this book, and the evidence is in
`book_text_parity.py`: the ProtocolBook's app text is a deliberate rewrite, not a
transcription, so shingle coverage scores p.16 at 0.0% while the app in fact
carries that page in full — the print says "1-3 weeks", the app says "1 - 3 wk".
Measured false-positive rate made the 63.9% headline meaningless.

Numbers survive rewording. A dose, a threshold, an age cut-off and a rate are the
same tokens in both, whatever the prose around them does, and they are also the
part of a clinical book where an omission actually hurts. So this compares the
*numeric* content of each printed page against the app topic that owns it.

Attribution: topic filenames are page-ordered (`pb_016_*.yaml` = p.16), so a topic
owns every printed page from its own up to the next topic's. A number is looked
for in the owning topic first and then anywhere in the book, because the app
legitimately moves content between pages; only a number found nowhere is reported.

Writes every row as it is produced.

    usage: pdfvenv/bin/python tool/book_number_parity.py <book> <out.tsv> [topics_dir]
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
        "offset": -1, "first": 12, "last": 158,
    },
    "who_imci": {
        "pdf": REPO / "9789241548373_eng.pdf",
        "topics": REPO / "assets/books/who_imci/topics",
        "offset": -1, "first": 1, "last": 412,
    },
}

SUPERSCRIPT = 1

SKIP_KEYS = {
    "id", "anchor", "palette", "image", "link_id", "type", "variant", "shape",
    "severity", "kind", "provider_level", "population", "band", "scope",
    "version", "font_family", "category", "asset", "page_number", "flex",
    "column_flex", "column_widths", "column_align", "tags", "aliases",
    "last_reviewed", "layout", "list_subtitle",
}

# A number carrying clinical weight: a figure with a unit, a ratio, a range or a
# percentage. A bare small integer is a list marker far more often than a dose.
UNIT = (r"(?:mg/kg/day|mg/kg/hr|mg/kg/dose|mcg/kg/min|mcg/kg/hr|mcg/kg|ml/kg/hr|"
        r"ml/kg|mmol/l|mmol|mequiv|meq/kg|meq|units/kg|units|iu/kg|iu|mg/kg|"
        r"g/dl|g/l|mg/dl|mg/ml|mcg/ml|ng/ml|mmhg|kcal|kg|mg|mcg|ug|ml|mls|litre|l|"
        r"g|%|hrs?|hours?|mins?|minutes?|secs?|seconds?|days?|weeks?|wks?|"
        r"months?|mo|years?|yrs?|yo)")

PATTERNS = [
    re.compile(r"\b\d+(?:[.,]\d+)?\s*:\s*\d+(?:[.,]\d+)?\b"),          # 1:10,000
    re.compile(r"\b\d+(?:\.\d+)?\s*-\s*\d+(?:\.\d+)?\s*" + UNIT, re.I),  # 15-18 g
    re.compile(r"\b\d+(?:\.\d+)?\s*" + UNIT + r"\b", re.I),              # 250 mg
    re.compile(r"[<>]=?\s*\d+(?:\.\d+)?"),                               # >= 95
    re.compile(r"\bq\s*\d+\s*h(?:rs?|ours?)?\b", re.I),                  # q6hr
]


def canon(tok):
    """One spelling for a number+unit, so 250 mg / 250mg / 250 Mg all agree."""
    t = tok.lower().replace(",", "").replace(" ", "")
    t = t.replace("µ", "u").replace("mcg", "ug")
    t = t.replace("millilitres", "ml").replace("mls", "ml").replace("litre", "l")
    t = re.sub(r"hours?\b", "h", t)
    t = re.sub(r"hrs?\b", "h", t)
    t = re.sub(r"minutes?\b", "min", t)
    t = re.sub(r"mins?\b", "min", t)
    t = re.sub(r"seconds?\b", "s", t)
    t = re.sub(r"secs?\b", "s", t)
    t = re.sub(r"weeks?\b", "wk", t)
    t = re.sub(r"wks?\b", "wk", t)
    t = re.sub(r"months?\b", "mo", t)
    t = re.sub(r"years?\b", "y", t)
    t = re.sub(r"yrs?\b", "y", t)
    t = re.sub(r"\byo\b", "y", t)
    t = re.sub(r"days?\b", "d", t)
    t = re.sub(r"^0+(?=\d)", "", t)
    t = re.sub(r"(\d)\.0+(?!\d)", r"\1", t)
    return t


def numbers(text):
    # The print uses hyphens in ranges and the app uses en-dashes ("4-7 weeks"
    # vs "4 - 7 wk"), which silently cost five false hits on p.16 alone before
    # this line existed. Same for the minus sign and the non-breaking space.
    text = re.sub(r"[\u2010-\u2015\u2212]", "-", text).replace("\xa0", " ")
    found = set()
    for pat in PATTERNS:
        for m in pat.finditer(text):
            found.add(canon(m.group(0)))
    return found


def print_text(page):
    parts = []
    for block in page.get_text("dict").get("blocks", []):
        if block.get("type") != 0:
            continue
        for line in block.get("lines", []):
            txt = "".join(sp["text"] for sp in line.get("spans", [])
                          if not (sp.get("flags", 0) & SUPERSCRIPT))
            if txt.strip():
                parts.append(txt.strip())
    return " ".join(parts)


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
    book, out_path = sys.argv[1], Path(sys.argv[2])
    cfg = BOOKS[book]
    topics = Path(sys.argv[3]) if len(sys.argv) > 3 else cfg["topics"]
    out_path.parent.mkdir(parents=True, exist_ok=True)

    fh = open(out_path, "w")
    fh.write("page\towning_topic\tnumber\tin_owning_topic\tanywhere_in_app\tprint_context\n")
    fh.flush()

    per_topic, book_nums = [], set()
    for f in sorted(topics.glob("*.yaml")):
        d = yaml.safe_load(f.read_text(encoding="utf-8"))["topic"]
        acc = []
        app_strings(d.get("blocks", []), acc)
        app_strings(d.get("pages", []), acc)
        n = numbers(" ".join(acc))
        per_topic.append((d.get("page_number"), f.name, n))
        book_nums |= n
    fpath = topics.parent / "formulary.yaml"
    if fpath.exists():
        acc = []
        app_strings(yaml.safe_load(fpath.read_text(encoding="utf-8")), acc)
        book_nums |= numbers(" ".join(acc))
    per_topic.sort(key=lambda x: (x[0] is None, x[0]))
    print(f"--- app: {len(book_nums)} distinct clinical numbers over "
          f"{len(per_topic)} topics", flush=True)

    def owner(p):
        o = None
        for pg, name, n in per_topic:
            if pg is not None and pg <= p:
                o = (pg, name, n)
            elif pg is not None:
                break
        return o

    doc = pymupdf.open(cfg["pdf"])
    tot = miss_here = miss_all = 0
    for p in range(cfg["first"], cfg["last"] + 1):
        idx = p + cfg["offset"]
        if not (0 <= idx < doc.page_count):
            continue
        raw = print_text(doc[idx])
        pn = numbers(raw)
        if not pn:
            continue
        ow = owner(p)
        oname = ow[1] if ow else "-"
        onums = ow[2] if ow else set()
        here = absent = 0
        for num in sorted(pn):
            in_own = num in onums
            in_book = num in book_nums
            if not in_own:
                here += 1
            if not in_book:
                absent += 1
                m = re.search(r".{0,45}" + re.escape(num.split()[0][:4]) + r".{0,45}",
                              raw, re.I)
                ctx = (m.group(0) if m else "").replace("\t", " ")
                fh.write(f"{p}\t{oname}\t{num}\t{in_own}\t{in_book}\t{ctx}\n")
                fh.flush()
        tot += len(pn)
        miss_here += here
        miss_all += absent
        print(f"p.{p}: {len(pn)} numbers, {here} not in {oname}, "
              f"{absent} nowhere in the app", flush=True)
    print(f"=== {book}: {tot} printed clinical numbers; {miss_here} absent from the "
          f"owning topic; {miss_all} absent from the whole app", flush=True)
    fh.close()


if __name__ == "__main__":
    main()
