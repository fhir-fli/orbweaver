#!/usr/bin/env python3
"""Propose (and optionally apply) the print's cross-reference links to the YAML.

Reads the resolved link table from `wvems_link_resolve.py` and, for each
printed page the app ships, rewrites the phrase the print underlines as a link
in the app's own text for that page.

**Which occurrence** is decided by the line, not by counting. A phrase like
"Tylenol" appears three times on the app's p.21 and the print links two of
them; pairing by order would be a guess. So every link carries the full printed
text line it sits on, and that line is fuzzy-matched against the app's lines for
the page — the link then lands on the occurrence inside the matching line. When
one printed line links the same phrase twice, the two are paired left to right.

Weight follows the print (audit §1.5): bold and underline are orthogonal
channels there, so a cross-reference to a protocol, policy or peds page is set
in regular weight and any bold the app added is dropped, while a drug or
procedure cross-reference is bold *and* underlined and keeps its bold. The app
renders `**[text](target)**` correctly — `_parseInline` recurses into bold and
carries the weight into the link span.

Anything that cannot be placed with confidence — no matching app line, phrase
absent from the matched line, an existing link to a different target — is
reported and left alone.

    usage: pdfvenv/bin/python tool/wvems_link_apply.py <targets.tsv> <report.tsv>
                                                       [--apply] [--odd|--even]
"""
import re
import sys
from collections import defaultdict
from difflib import SequenceMatcher
from pathlib import Path

REPO = Path("/home/grey/dev/fhir/orbweaver")
TOPICS = REPO / "assets/books/wvems/topics"

# Targets whose cross-reference is bold in print as well as underlined.
BOLD_TOPICS = {"wvems-2026-drug-reference", "wvems-2026-096"}

# Below this, the printed line and the app line are not the same sentence.
LINE_MATCH_MIN = 0.55

LINK_RE = re.compile(r"\[([^\]]+)\]\((topic:[^)]+)\)")

# Words the print misspells. The app spells them correctly, so the phrase
# regex would never find them.
PRINT_TYPOS = {"behavorial": "Behavioral"}

BOLD_RUN_RE = re.compile(r"\*\*(.+?)\*\*")


def page_to_file(page):
    even = page if page % 2 == 0 else page - 1
    if 4 <= even <= 94:
        return TOPICS / f"wvems_2026_{even:03d}.yaml"
    return None


def phrase_regex(phrase):
    """Matches the app's wording of a printed phrase.

    The app writes the registered trademark the print's card header drops
    ("Versed®" vs "Versed") and sometimes hyphenates where the print spaces
    ("weight-based" vs "weight based"), so word gaps match either and a
    trailing ® is optional.
    """
    words = [re.escape(w) for w in phrase.split()]
    body = r"[\s\-/]*".join(words)
    return re.compile(rf"(?<![\w])({body})(®)?(?![\w])", re.IGNORECASE)


def normalize(s):
    s = re.sub(r"\[([^\]]+)\]\([^)]*\)", r"\1", s)  # link -> its display text
    s = s.replace("**", "")
    s = re.sub(r"[^a-z0-9]+", " ", s.lower())
    return s.strip()


def page_ranges(lines):
    """{printed page number: (start, end)} line indices for a topic file."""
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


def candidate_lines(lines, start, end):
    """App YAML lines in a page that carry body text, with a comparable form.

    Only markdown body lines are considered: keys, comments, list scalars and
    blank lines can't hold a cross-reference.
    """
    out = []
    for i in range(start, end):
        raw = lines[i]
        t = raw.strip()
        if not t or t.startswith("#") or re.match(r"^-?\s*[a-z_]+:", t):
            continue
        norm = normalize(t.lstrip("- ").strip())
        if len(norm) >= 8:
            out.append((i, norm))
    return out


def main():
    targets_path, report_path = Path(sys.argv[1]), Path(sys.argv[2])
    do_apply = "--apply" in sys.argv
    only = "odd" if "--odd" in sys.argv else "even" if "--even" in sys.argv else None

    by_page = defaultdict(list)
    for row in targets_path.read_text().splitlines()[1:]:
        f = row.split("\t")
        src, dest, parts, phrase, topic, anchor, how, line_text = (f + [""] * 8)[:8]
        if how == "external" or how.startswith(("UNMATCHED", "NO-APP-TARGET")):
            continue
        if not phrase:
            continue
        by_page[int(src)].append(
            {
                "phrase": phrase,
                "topic": topic,
                "anchor": anchor,
                "line_text": line_text,
            }
        )

    report_path.parent.mkdir(parents=True, exist_ok=True)
    fh = open(report_path, "w")
    fh.write("status\tfile\tpage\tphrase\ttarget\tdetail\n")
    fh.flush()
    tally = defaultdict(int)

    def note(status, name, page, phrase, target, detail):
        fh.write(f"{status}\t{name}\t{page}\t{phrase}\t{target}\t{detail}\n")
        fh.flush()
        tally[status] += 1

    for page in sorted(by_page):
        if only == "odd" and page % 2 == 0:
            continue
        if only == "even" and page % 2 == 1:
            continue
        path = page_to_file(page)
        if path is None or not path.exists():
            for t in by_page[page]:
                note("no-topic-file", "-", page, t["phrase"], "", "")
            continue
        lines = path.read_text().split("\n")
        ranges = page_ranges(lines)
        if page not in ranges:
            for t in by_page[page]:
                note("no-page-block", path.name, page, t["phrase"], "", "")
            continue
        cands = candidate_lines(lines, *ranges[page])

        # Links sharing a printed line and a phrase are paired left to right,
        # which is the order they already come out of the extractor in.
        used = defaultdict(int)  # (app line, phrase) -> occurrences consumed
        edits = []
        for t in by_page[page]:
            target = t["topic"] + (f"#{t['anchor']}" if t["anchor"] else "")
            want = normalize(t["line_text"])
            best, best_ratio = None, 0.0
            for idx, norm in cands:
                r = SequenceMatcher(None, want, norm).ratio()
                if r > best_ratio:
                    best, best_ratio = idx, r
            if best is None or best_ratio < LINE_MATCH_MIN:
                note(
                    "no-line-match", path.name, page, t["phrase"], target,
                    f"best {best_ratio:.2f}: {t['line_text'][:60]}",
                )
                continue
            phrase = PRINT_TYPOS.get(t["phrase"].lower(), t["phrase"])
            rx = phrase_regex(phrase)
            occ = list(rx.finditer(lines[best]))
            k = used[(best, phrase.lower())]
            if k >= len(occ):
                # The app sometimes splits one printed line into a bullet and
                # its sub-bullet, leaving the phrase one line away. Accept a
                # neighbour only when exactly one of them carries it.
                near = [
                    j
                    for j in (best - 2, best - 1, best + 1, best + 2)
                    if 0 <= j < len(lines) and rx.search(lines[j])
                ]
                if len(near) == 1:
                    best = near[0]
                    occ = list(rx.finditer(lines[best]))
                    k = used[(best, phrase.lower())]
            used[(best, phrase.lower())] += 1
            if k >= len(occ):
                note(
                    "phrase-not-on-line", path.name, page, t["phrase"], target,
                    f"line {best + 1} ({best_ratio:.2f}): {lines[best].strip()[:70]}",
                )
                continue
            m = occ[k]
            s, e = m.start(), m.end()
            line = lines[best]
            inside = next(
                (lm for lm in LINK_RE.finditer(line) if lm.start() <= s and e <= lm.end()),
                None,
            )
            if inside:
                have = inside.group(2)[len("topic:") :]
                if have == target:
                    tally["already-correct"] += 1
                else:
                    note(
                        "conflict", path.name, page, t["phrase"], target,
                        f"line {best + 1} currently links to {have}",
                    )
                continue
            bold_wanted = t["topic"] in BOLD_TOPICS
            # Exactly bolded ("**Versed**") vs merely sitting inside a wider
            # bold run ("**Tylenol 3,000 mg**"). Wrapping the phrase again in
            # the second case would emit `****`, which is not markdown.
            exact_bold = line[max(0, s - 2) : s] == "**" and line[e : e + 2] == "**"
            in_bold_run = not exact_bold and any(
                bm.start() < s and e < bm.end() for bm in BOLD_RUN_RE.finditer(line)
            )
            if exact_bold:
                s, e = s - 2, e + 2
            new = f"[{m.group(0)}](topic:{target})"
            if bold_wanted and not in_bold_run:
                new = f"**{new}**"
            edits.append((best, s, e, new))
            note(
                "link", path.name, page, t["phrase"], target,
                f"line {best + 1} ({best_ratio:.2f})"
                + (" was bold" if exact_bold else "")
                + (" in bold run" if in_bold_run else "")
                + (" keeps bold" if bold_wanted else ""),
            )

        if do_apply and edits:
            for line_no, s, e, new in sorted(edits, key=lambda x: (-x[0], -x[1])):
                ln = lines[line_no]
                lines[line_no] = ln[:s] + new + ln[e:]
            path.write_text("\n".join(lines))
            print(f"{path.name}: {len(edits)} edits on p.{page}", flush=True)

    fh.close()
    print(f"report -> {report_path}", flush=True)
    for k in sorted(tally):
        print(f"  {k}: {tally[k]}", flush=True)


if __name__ == "__main__":
    main()
