#!/usr/bin/env python3
"""Resolve every printed WVEMS cross-reference to an app link target.

Input is the raw annotation dump from `wvems_link_extract.py`.  Two things
happen here:

1. **Merge wrapped annotations.**  A phrase that wraps across lines carries one
   annotation per line — p.18 has three annotations to p.116 stacked at
   y 739.1-760.1, 760.1-781.1, 781.1-802.1, which is the single phrase
   "Consider Destination Triage".  Rects are merged only when they are exactly
   contiguous (same dest, touching edges), so p.25's three separate links to
   p.112 ("Special Case", "Transport", "Call for Termination", 5 pt apart) stay
   three cross-references.

2. **Resolve the destination page to a topic id and anchor.**  Protocol pages
   map by number.  The three appendix topics each hold dozens of cards in one
   topic, so the anchor is resolved by matching the link phrase against the
   cards that are *actually printed on the destination page* — page and phrase
   have to agree, which is what stops a name matching the wrong card.

   - drug name -> page comes from the PDF itself: the card header is the white
     EncodeSans-Bold 30 pt span in each card's dark band (verified p.121:
     "Amiodarone", "Ancef").  50 headers over pp.119-143, 1:1 with the app's 50
     drug cards.
   - procedure -> page comes from the rotated side-label spans on pp.97-108
     (Barlow-Medium 30 pt, flags 4), read out by `wvems_card_pages.py` and
     recorded in PROCEDURE_PAGES below: 31 procedures, 1:1 with the app's 31.
   - policy -> page is stated by the book's own index on p.109, whose eight
     links are labelled "Page 110 - Abuse", "Page 112 - Termination", ...

Unresolved rows are written out too, with a reason — nothing is silently
dropped.

    usage: pdfvenv/bin/python tool/wvems_link_resolve.py <links.tsv> <out.tsv>
"""
import re
import sys
from pathlib import Path

import pymupdf
import yaml

REPO = Path("/home/grey/dev/fhir/orbweaver")
PDF = REPO / "2026-WVEMS-Protocols.pdf"
TOPICS = REPO / "assets/books/wvems/topics"

DRUG_TOPIC = "wvems-2026-drug-reference"
PROC_TOPIC = "wvems-2026-096"
POLICY_TOPIC = "wvems-2026-109"
PEDS_TOPIC = "wvems-2026-144"

# Measured from the rotated side-labels on pp.97-108 (see module docstring).
PROCEDURE_PAGES = {
    97: ["Glucometer", "12-Lead", "Saline Lock"],
    98: ["Back Blows & Thrusts", "Suction", "Magill Forceps"],
    99: ["BVM", "NPA / OPA", "NIPPV"],
    100: ["BIAD", "OG-Tube", "Pleural Decompress"],
    101: ["Chest Compression", "Defib", "IO"],
    102: ["Wound Care", "Tourniquet", "Wound Packing"],
    103: ["SMR with C-collar", "Splint", "Reduce Deformity", "Stinger Removal"],
    104: ["Adult Antidotes"],
    105: ["Pacing", "Cardiovert"],
    106: ["Deliver Baby", "Manage OB Complication"],
    107: ["RSI Prep Checklist", "Ventilator"],
    108: ["Cric", "Finger Thoracostomy"],
}

# Link phrases that name a card by something other than its card title. Each
# was checked against the destination page's card list before being written
# here — the phrase alone never decides.
#   "EKG" -> p.97 holds Glucometer / 12-Lead / Saline Lock
#   "Bandage wounds" -> p.102 holds Wound Care / Tourniquet / Wound Packing
#   "vents" -> p.107 holds RSI Prep Checklist / Ventilator
#   "Baqsimi" (intranasal glucagon) -> p.130 holds Fentanyl / Glucagon
PHRASE_ALIASES = {
    ("EKG", 97): "12-Lead",
    ("Bandage wounds", 102): "Wound Care",
    ("vents", 107): "Ventilator",
    ("Baqsimi", 130): "Glucagon",
    ("EpiPen", 128): "Epi, Epi Neb",
    ("EpiPen Jr", 128): "Epi, Epi Neb",
}

# The p.109 index's own labels for each policy page.
POLICY_PAGES = {
    110: "patient-abuse-and-neglect",
    111: "verification-of-on-scene-personnel",
    112: "termination-of-resuscitation",
    113: "advanced-cardiac-devices",
    114: "ems-standbys",
    115: "patient-refusals",
    116: "destination-triage",
    117: "deceased-subjects",
}


def slug(name):
    """Mirrors `anchorSlug` in lib/models/topic.dart."""
    return re.sub(r"^-+|-+$", "", re.sub(r"[^a-z0-9]+", "-", name.lower()))


def norm(s):
    return re.sub(r"[^a-z0-9]+", " ", s.lower()).strip()


def drug_pages_from_pdf():
    """{printed page: [drug card name as printed]} for pp.118-143."""
    doc = pymupdf.open(PDF)
    out = {}
    for pno in range(117, 143):
        page = doc[pno]
        for block in page.get_text("dict").get("blocks", []):
            if block.get("type") != 0:
                continue
            for line in block.get("lines", []):
                for span in line.get("spans", []):
                    is_header = (
                        span["font"] == "EncodeSans-Bold"
                        and span["color"] == 0xFFFFFF
                        and span["size"] >= 24
                    )
                    if is_header and span["text"].strip():
                        out.setdefault(pno + 1, []).append(span["text"].strip())
    return out


def card_names(asset, block_type):
    """The app's authored card names for a topic, in file order."""
    doc = yaml.safe_load((TOPICS / asset).read_text())["topic"]
    blocks = doc.get("blocks") or [
        b for p in doc.get("pages", []) for b in p.get("blocks", [])
    ]
    return [b["name"] for b in blocks if b.get("type") == block_type]


def best_match(phrase, candidates):
    """The candidate a link phrase names, or None.

    Only one card per destination page usually shares any word with the
    phrase, so a token-overlap score decides; ties and zero-overlap return
    None so the row lands in the manual pile rather than guessing.
    """
    if not candidates:
        return None
    if len(candidates) == 1:
        return candidates[0]
    p = set(norm(phrase).split())
    if not p:
        return None
    scored = []
    for c in candidates:
        c_tokens = set(norm(c).split())
        overlap = len(p & c_tokens)
        # a phrase like "compressions" against "Chest Compression": no exact
        # token match, so also score on stem containment either way
        if not overlap:
            overlap = sum(
                1
                for a in p
                for b in c_tokens
                if len(a) > 3 and len(b) > 3 and (a.startswith(b) or b.startswith(a))
            )
        scored.append((overlap, c))
    scored.sort(key=lambda t: -t[0])
    if scored[0][0] == 0:
        return None
    if len(scored) > 1 and scored[0][0] == scored[1][0]:
        return None
    return scored[0][1]


EDGE_TOL = 2.0


def merge(rows):
    """Fold wrapped annotations (same dest, exactly touching rects) into one.

    Touching rects alone are not enough: p.59 carries two separate links to
    p.102 on consecutive lines, both the word "Tourniquet", and p.73 two to
    p.104 both reading "Antidote". A phrase that actually *wrapped* runs to the
    end of its line and resumes at the start of the next, so the merge also
    requires the earlier rect to reach its line's right edge and the later one
    to start at its line's left edge. On p.18's "Consider / Destination /
    Triage" each rect equals its whole line; on p.59 the rect is a 97 pt
    fragment of a 574 pt line.
    """
    merged = []
    for r in rows:
        prev = merged[-1] if merged else None
        if (
            prev
            and prev["src"] == r["src"]
            and prev["dest"] == r["dest"]
            and prev["kind"] == r["kind"]
            and abs(prev["y1"] - r["y0"]) < 1.0
            and min(prev["x1"], r["x1"]) - max(prev["x0"], r["x0"]) > 0
            and prev["line_x1"] - prev["x1"] <= EDGE_TOL
            and r["x0"] - r["line_x0"] <= EDGE_TOL
        ):
            prev["phrase"] = f"{prev['phrase']} {r['phrase']}".strip()
            prev["y1"] = r["y1"]
            prev["x0"] = min(prev["x0"], r["x0"])
            prev["x1"] = max(prev["x1"], r["x1"])
            if r["line_text"] not in prev["line_text"]:
                prev["line_text"] = f"{prev['line_text']} {r['line_text']}".strip()
            prev["line_x0"] = r["line_x0"]
            prev["line_x1"] = r["line_x1"]
            prev["parts"] += 1
            continue
        r["parts"] = 1
        merged.append(r)
    return merged


def main():
    links_path, out_path = Path(sys.argv[1]), Path(sys.argv[2])
    out_path.parent.mkdir(parents=True, exist_ok=True)

    drug_pages = drug_pages_from_pdf()
    app_drugs = card_names("wvems_2026_drug_reference.yaml", "drug_card")
    app_procs = card_names("wvems_2026_096.yaml", "procedure_card")
    # The printed header drops the ® the app authors, so match on the slug.
    drug_by_slug = {slug(n): n for n in app_drugs}
    proc_by_slug = {slug(n): n for n in app_procs}

    rows = []
    skipped_offpage = 0
    for line in links_path.read_text().splitlines()[1:]:
        f = line.split("\t")
        if f[8] != "y":  # annotation placed outside the page box — invisible
            skipped_offpage += 1
            continue
        rows.append(
            {
                "src": int(f[0]),
                "kind": f[2],
                "dest": f[3],
                "x0": float(f[4]),
                "y0": float(f[5]),
                "x1": float(f[6]),
                "y1": float(f[7]),
                "line_x0": float(f[9]) if f[9] else float(f[4]),
                "line_x1": float(f[10]) if f[10] else float(f[6]),
                "phrase": f[11] if len(f) > 11 else "",
                "line_text": f[12] if len(f) > 12 else "",
            }
        )
    rows = merge(rows)

    fh = open(out_path, "w")
    fh.write("src_page\tdest\tparts\tphrase\ttopic\tanchor\thow\tline_text\n")
    fh.flush()
    counts = {}
    for r in rows:
        topic = anchor = ""
        how = ""
        if r["kind"] == "uri":
            how = "external"
            topic = r["dest"]
        else:
            d = int(r["dest"])
            if 4 <= d <= 95:
                even = d if d % 2 == 0 else d - 1
                # pp.8-9 (Circulation / Shock) still ship as the 2025 file:
                # the flowchart page was carried over and the prose page never
                # was (audit §5.1). Batch 3 replaces it; until then this is
                # where a link to p.8 has to land.
                topic = "wvems-2025-008" if even == 8 else f"wvems-2026-{even:03d}"
                how = "protocol-page"
            elif 96 <= d <= 108:
                topic = PROC_TOPIC
                cands = PROCEDURE_PAGES.get(d, [])
                hit = PHRASE_ALIASES.get((r["phrase"], d)) or best_match(
                    r["phrase"], cands
                )
                anchor = slug(hit) if hit else ""
                how = "procedure-card" if hit else f"UNMATCHED-procedure p.{d}"
            elif 109 <= d <= 117:
                topic = POLICY_TOPIC
                anchor = POLICY_PAGES.get(d, "")
                how = "policy-page" if anchor else "policy-index"
            elif 118 <= d <= 143:
                topic = DRUG_TOPIC
                printed = drug_pages.get(d, [])
                hit = PHRASE_ALIASES.get((r["phrase"], d)) or best_match(
                    r["phrase"], printed
                )
                if hit and slug(hit) in drug_by_slug:
                    anchor = slug(hit)
                    how = "drug-card"
                else:
                    how = f"UNMATCHED-drug p.{d}"
            elif 144 <= d <= 161:
                topic = PEDS_TOPIC
                how = "peds-reference"
            else:
                how = f"NO-APP-TARGET p.{d}"
        counts[how.split()[0]] = counts.get(how.split()[0], 0) + 1
        fh.write(
            f"{r['src']}\t{r['dest']}\t{r['parts']}\t{r['phrase']}\t"
            f"{topic}\t{anchor}\t{how}\t{r['line_text']}\n"
        )
        fh.flush()
    fh.close()

    print(
        f"{len(rows)} merged links -> {out_path} "
        f"({skipped_offpage} off-page annotations skipped)",
        flush=True,
    )
    for k in sorted(counts):
        print(f"  {k}: {counts[k]}", flush=True)
    unused_d = sorted(set(drug_by_slug) - {slug(n) for ns in drug_pages.values() for n in ns})
    print(f"app drug slugs with no printed header: {unused_d}", flush=True)
    unused_p = sorted(
        set(proc_by_slug) - {slug(n) for ns in PROCEDURE_PAGES.values() for n in ns}
    )
    print(f"app procedure slugs not in the page map: {unused_p}", flush=True)


if __name__ == "__main__":
    main()
