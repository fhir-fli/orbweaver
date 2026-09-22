#!/usr/bin/env python3
"""Where do the flowchart pages' cross-references actually live in the YAML?

The prose pages could be rewritten in place because their text is markdown.
Flowchart pages cannot: node and action text renders as a plain `Text`, so a
`[label](topic:id)` written there shows literal brackets on screen. Restoring
those 370 cross-references means giving the *model* a link field wherever the
print underlines something — and which fields those are is a measurement, not
a guess.

For every printed link leaving an even page, this finds the field in the app's
YAML whose value contains the phrase, and tallies the field paths. The result
says exactly which classes need a link field and how many links each unlocks.

    usage: pdfvenv/bin/python tool/wvems_flowchart_link_sites.py <targets.tsv> <out.tsv>
"""
import re
import sys
from collections import defaultdict
from pathlib import Path

import yaml
from _repo import REPO

REPO = REPO
TOPICS = REPO / "assets/books/wvems/topics"


def phrase_regex(phrase):
    # Split on slashes as well as spaces: the print sets "OD/Tox" closed up
    # where the app writes "OD / Tox".
    words = [re.escape(w) for w in re.split(r"[\s/]+", phrase) if w]
    return re.compile(rf"(?<![\w])({r'[\s\-/]*'.join(words)})(®)?(?![\w])", re.IGNORECASE)


def record_text(record):
    """All the strings in one YAML record, joined — its printed line, roughly.

    A dose-table row keeps its drug, dose, route and frequency in separate
    fields; the print keeps them on one line ("Albuterol: 2.5 mg NEB Q 5 min
    x4"). Joining them is what lets that row be told apart from the flow node
    that says only "Albuterol".
    """
    if isinstance(record, dict):
        return " ".join(v for v in record.values() if isinstance(v, str))
    return record if isinstance(record, str) else ""


def walk(node, path, out, record=None):
    """Every string in the tree, with a structural path and its own record."""
    if isinstance(node, dict):
        for k, v in node.items():
            walk(v, f"{path}.{k}" if path else str(k), out, node)
    elif isinstance(node, list):
        for item in node:
            walk(item, f"{path}[]", out, record)
    elif isinstance(node, str):
        out.append((path, node, record_text(record) or node))


def main():
    targets_path, out_path = Path(sys.argv[1]), Path(sys.argv[2])
    by_page = defaultdict(list)
    for row in targets_path.read_text().splitlines()[1:]:
        f = (row.split("\t") + [""] * 8)[:8]
        src, dest, parts, phrase, topic, anchor, how, line_text = f
        if not phrase or how == "external" or how.startswith(("UNMATCHED", "NO-APP")):
            continue
        page = int(src)
        if page % 2 or not 4 <= page <= 94:
            continue
        by_page[page].append((phrase, topic, anchor, line_text))

    out_path.parent.mkdir(parents=True, exist_ok=True)
    fh = open(out_path, "w")
    fh.write("page\tlink_no\tphrase\ttarget\tfield_path\tvalue\trecord\tprint_line\n")
    fh.flush()
    tally = defaultdict(int)
    unfound = 0

    for page in sorted(by_page):
        path = TOPICS / f"wvems_2026_{page:03d}.yaml"
        if not path.exists():
            continue
        doc = yaml.safe_load(path.read_text())["topic"]
        pages = doc.get("pages") or []
        block = next((p for p in pages if p.get("page_number") == page), None)
        if block is None:
            continue
        strings = []
        walk(block.get("blocks", []), "", strings)
        for link_no, (phrase, topic, anchor, line_text) in enumerate(by_page[page]):
            rx = phrase_regex(phrase)
            hits = [(fp, val, rec) for fp, val, rec in strings if rx.search(val)]
            target = topic + (f"#{anchor}" if anchor else "")
            if not hits:
                fh.write(
                    f"{page}\t{link_no}\t{phrase}\t{target}\t-\t-\t-\t{line_text}\n"
                )
                fh.flush()
                unfound += 1
                tally["(phrase not in this page's YAML)"] += 1
                continue
            # Every candidate is written out; the applier scores them against
            # the printed line rather than taking the first.
            for fp, val, rec in hits:
                fh.write(
                    f"{page}\t{link_no}\t{phrase}\t{target}\t{fp}\t{val}\t"
                    f"{rec}\t{line_text}\n"
                )
                fh.flush()
            tally[hits[0][0]] += 1
    fh.close()

    print(f"report -> {out_path}", flush=True)
    for k in sorted(tally, key=lambda k: -tally[k]):
        print(f"  {tally[k]:4d}  {k}", flush=True)


if __name__ == "__main__":
    main()
