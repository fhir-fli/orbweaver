#!/usr/bin/env python3
"""Write the print's flowchart-page cross-references into the YAML.

Companion to `wvems_link_apply.py`, which handles the prose pages. Flowchart
pages hold their text in structured fields, not markdown, so the target is the
*field* the phrase lives in — located by `wvems_flowchart_link_sites.py` and
fed in here as its report.

Only fields that actually route through a link-aware renderer are written
(`LINKABLE`). Writing the syntax anywhere else would print its brackets: a
`branches[].id` is never displayed, and a `critical_care_link` is a whole-node
`link_id` pill.

When a convergence bullet gains inline links its `link_id:` is dropped — the
two would say different things about the same bullet, and the inline form is
strictly better: on p.34 "Fever, Pain, Nausea" is three links in print and the
`link_id` could only point the whole bullet at one of them (it pointed at Pain).

    usage: pdfvenv/bin/python tool/wvems_flowchart_link_apply.py \
               <sites.tsv> <report.tsv> [--apply]
"""
import re
import sys
from collections import defaultdict
from difflib import SequenceMatcher
from pathlib import Path
from _repo import REPO

REPO = REPO
TOPICS = REPO / "assets/books/wvems/topics"

# Field paths whose renderer understands the inline cross-reference syntax.
# Each was traced to a `FlowLinkText` or a `FitText` (which delegates to it).
LINKABLE = {
    "[].convergence.bullets[].text",
    "[].convergence.warnings[].text",
    "[].post_convergence.text",
    "[].post_convergence.bullets[].text",
    "[].branches[].actions[].text",
    "[].branches[].criteria[]",
    "[].branches[].label",
    "[].warnings[].text",
    "[].cards[].bullets[]",
    "[].cards[].title",
    "[].steps[].bullets[]",
    "[].steps[].text",
    "[].entry.text",
    "[].entry_chain[].text",
    "[].pre_decision_actions[].text",
    "[].dose_table[].drug",
    "[].dose_table[].dose",
}

# Bold is not available in flowchart text — it renders through a single style —
# so the print's bold-plus-underline drug reference degrades to underline only.
BOLD_UNAVAILABLE = True


def phrase_regex(phrase):
    # Split on slashes as well as spaces: the print sets "OD/Tox" closed up
    # where the app writes "OD / Tox".
    words = [re.escape(w) for w in re.split(r"[\s/]+", phrase) if w]
    return re.compile(
        rf"(?<![\w])({r'[\s\-/]*'.join(words)})(®)?(?![\w])", re.IGNORECASE
    )


def page_ranges(lines):
    marks = [
        (int(m.group(1)), i)
        for i, ln in enumerate(lines)
        if (m := re.match(r"\s*- page_number:\s*(\d+)", ln))
    ]
    out = {}
    for k, (pg, start) in enumerate(marks):
        end = marks[k + 1][1] if k + 1 < len(marks) else len(lines)
        out[pg] = (start, end)
    return out


LINK_ANY = re.compile(r"\[[^\]]+\]\(topic:[^)]+\)")


# `[Albuterol](topic:wvems-2026-drug-reference#albuterol)` -> `Albuterol`.
LINK_UNWRAP = re.compile(r"\[([^\]]+)\]\(topic:[^)]+\)")


def norm(s):
    """Compare on what the page *says*, not on links already written into it.

    Without the unwrap this script is not idempotent: on p.30 the print's one
    Albuterol link sits on the dose-table line ("Albuterol: 2.5 mg"), and once
    that row is linked its raw text carries the whole target inside it. The
    similarity against the printed line then drops below the bare action tile's
    ("E Albuterol medication_administration"), the tile wins the second run,
    and the page ends up with two links where the print has one.
    """
    return re.sub(r"[^a-z0-9]+", " ", LINK_UNWRAP.sub(r"\1", s).lower()).strip()


def companion_link_id(lines, i, end):
    """The `link_id:` belonging to the bullet on line `i`, if it has one.

    Same shape as the drop-link_id sweep below: the id sits on one of the next
    two lines, indented to the bullet's own text.
    """
    if "text:" not in lines[i]:
        return None
    indent = len(lines[i]) - len(lines[i].lstrip(" -"))
    for j in (i + 1, i + 2):
        if j < end:
            m = re.match(rf'\s{{{indent}}}link_id:\s*"([^"]+)"', lines[j])
            if m:
                return m.group(1)
    return None


def line_matcher(field):
    """Which YAML lines can hold this field.

    Without it, "Albuterol" in `dose_table[].drug` also matches the action
    tile's `text: "Albuterol"` higher up the page, and the two counts never
    line up.
    """
    leaf = field.rsplit(".", 1)[-1]
    if leaf.endswith("[]"):  # a bare list item: criteria, bullets
        return re.compile(r'^\s*-\s*"')
    return re.compile(rf'^\s*-?\s*{re.escape(leaf)}:\s*"')


def main():
    sites_path, report_path = Path(sys.argv[1]), Path(sys.argv[2])
    do_apply = "--apply" in sys.argv

    # Rows are one candidate field each; group them back into one entry per
    # printed link so the candidates can be scored against each other.
    grouped = defaultdict(list)
    order = []
    for row in sites_path.read_text().splitlines()[1:]:
        page, link_no, phrase, target, field, value, record, print_line = (
            row.split("\t") + [""] * 8
        )[:8]
        key = (int(page), int(link_no))
        if key not in grouped:
            order.append(key)
        grouped[key].append(
            {
                "phrase": phrase,
                "target": target,
                "field": field,
                "value": value,
                "record": record,
                "print_line": print_line,
            }
        )
    by_page = defaultdict(list)
    for key in order:
        by_page[key[0]].append(grouped[key])

    report_path.parent.mkdir(parents=True, exist_ok=True)
    fh = open(report_path, "w")
    fh.write("status\tpage\tphrase\ttarget\tfield\tdetail\n")
    fh.flush()
    tally = defaultdict(int)

    def note(status, page, phrase, target, field, detail=""):
        fh.write(f"{status}\t{page}\t{phrase}\t{target}\t{field}\t{detail}\n")
        fh.flush()
        tally[status] += 1

    for page in sorted(by_page):
        path = TOPICS / f"wvems_2026_{page:03d}.yaml"
        if not path.exists():
            continue
        lines = path.read_text().split("\n")
        ranges = page_ranges(lines)
        if page not in ranges:
            continue
        start, end = ranges[page]
        # All searching happens against a pristine copy: inserting the link
        # syntax into a line changes the very text later groups look for.
        # Edits are collected and applied at the end, per line, right to left.
        orig = list(lines)
        edits = []
        touched = set()

        # Pass 1 — pick the field each printed link belongs to.
        chosen = []
        for candidates in by_page[page]:
            phrase = candidates[0]["phrase"]
            target = candidates[0]["target"]
            print_line = candidates[0]["print_line"]
            if candidates[0]["field"] == "-":
                note("phrase-not-in-yaml", page, phrase, target, "-")
                continue
            usable = [c for c in candidates if c["field"] in LINKABLE]
            if not usable:
                note(
                    "field-not-linkable", page, phrase, target,
                    candidates[0]["field"], candidates[0]["value"],
                )
                continue
            # The printed line decides which field. A drug named both in a
            # flow node and in the dose table is one link in print, and the
            # printed line ("Albuterol: 2.5 mg NEB Q 5 min x4" vs "Albuterol")
            # says which of the two it underlines.
            want = norm(print_line)
            usable.sort(
                key=lambda c: -SequenceMatcher(None, want, norm(c["record"])).ratio()
            )
            chosen.append((phrase, target, usable[0]["field"], usable[0]["value"]))

        placements = []
        # Pass 2 — place them. When one phrase occupies several lines of the
        # same field, the print's links and the app's occurrences are both in
        # reading order, so they pair off only if there are equally many. An
        # unequal count is reported, never guessed at.
        groups = defaultdict(list)
        for phrase, target, field, value in chosen:
            groups[(phrase.lower(), field)].append((phrase, target, value))
        for (_, field), items in groups.items():
            rx = phrase_regex(items[0][0])
            stubs = {v for _, _, v in items}
            key_rx = line_matcher(field)
            hits = [
                i
                for i in range(start, end)
                if key_rx.match(orig[i])
                and rx.search(orig[i])
                and any(v and v in orig[i] for v in stubs)
            ]
            if not hits:
                note("value-line-not-found", page, items[0][0], items[0][1], field)
                continue
            if len(hits) != len(items):
                note(
                    "count-mismatch", page, items[0][0], items[0][1], field,
                    f"print {len(items)}x, app {len(hits)}x",
                )
                continue
            for (phrase, target, _), i in zip(items, hits):
                taken = {(pl[1].start(), pl[1].end()) for pl in placements if pl[0] == i}
                m = next(
                    (
                        m
                        for m in rx.finditer(orig[i])
                        if (m.start(), m.end()) not in taken
                        and not any(
                            lm.start() <= m.start() and m.end() <= lm.end()
                            for lm in LINK_ANY.finditer(orig[i])
                        )
                    ),
                    None,
                )
                if m is None:
                    note("already-linked", page, phrase, target, field, f"line {i + 1}")
                    continue
                placements.append((i, m, phrase, target, field))

        # A bullet whose whole text is one cross-reference already carries it
        # as `link_id:`, and that renders as the same tap target. Rewriting it
        # inline would only churn the form — so the inline write is reserved
        # for bullets the print links *more than once*, which is the case
        # `link_id` cannot express. Without this the tool is not idempotent
        # against its own earlier output: p.88's "Chest Pain" bullet came back
        # as a proposed edit on every re-run.
        per_line = defaultdict(int)
        for i, *_ in placements:
            per_line[i] += 1
        for i, m, phrase, target, field in placements:
            if per_line[i] == 1 and companion_link_id(orig, i, end) == target:
                note(
                    "already-linked", page, phrase, target, field,
                    f"line {i + 1} (link_id)",
                )
                continue
            edits.append((i, m.start(), m.end(), f"[{m.group(0)}](topic:{target})"))
            touched.add(i)
            note("link", page, phrase, target, field, f"line {i + 1}")

        for i, st, en, new in sorted(edits, key=lambda e: (-e[0], -e[1])):
            if do_apply:
                lines[i] = lines[i][:st] + new + lines[i][en:]

        # A bullet that now carries inline links has no use for `link_id`.
        dropped = []
        for i in sorted(touched, reverse=True):
            if "text:" not in orig[i]:
                continue
            indent = len(orig[i]) - len(orig[i].lstrip(" -"))
            for j in (i + 1, i + 2):
                if j < end and re.match(rf"\s{{{indent}}}link_id:", orig[j]):
                    dropped.append(j)
                    break
        for j in sorted(dropped, reverse=True):
            note("drop-link_id", page, "", "", "", f"line {j + 1}")
            if do_apply:
                del lines[j]

        if do_apply and (touched or dropped):
            path.write_text("\n".join(lines))
            print(f"{path.name}: {len(touched)} links on p.{page}", flush=True)

    fh.close()
    print(f"report -> {report_path}", flush=True)
    for k in sorted(tally):
        print(f"  {k}: {tally[k]}", flush=True)


if __name__ == "__main__":
    main()
