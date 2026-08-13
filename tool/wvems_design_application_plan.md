# WVEMS design application — the plan

Applying the three measured audits (`wvems_audit_colour.md`,
`wvems_audit_typography.md`, `wvems_audit_badges.md`, all committed `6c6891a`)
to the app. The audits are the evidence; this file is the work order and the
running record of what has been done.

**Rule for every batch:** `flutter test` → `flutter build apk --debug` →
uninstall + install on `emulator-5554` → look at the pages the batch touches →
commit → `git push origin HEAD:main` → `git -C /home/grey/dev/fhir/orbweaver
pull --ff-only origin main`.

**Rule for palette work:** a role that other books rely on is repointed at the
**WVEMS book level** (`assets/books/wvems/book.yaml` → `book: palette:`), not in
`kRoleDefaults`. Only roles that exist *because of* WVEMS get a global repoint.
Checked 2026-08-12: of the roles in play, only `alert` / `alert_fill` are
overridden anywhere in YAML — by all four books — so those two, and anything
else the other books' renderers reach, stay amber globally.

---

## Batch 1 — colour: put the semantic register back

Source: `wvems_audit_colour.md` §10.1 (KEEP), §10.4 (the role diff), §7–8.

The audit's one-sentence diagnosis: the book uses colour in two registers, a
**chapter** register (page circles, title bar, edge rail, page wash, Broselow
band) and a **semantic** register (everything else, fixed across all 166 pages),
and the app has moved seven semantic things into the chapter register.

- [x] **F-18 — dose-table zebra encodes population, not chapter.** Adult
      `#EFEFEF`/`#D9D9D9`, peds `#FFDCE2`/`#FFC0CB`. Four new roles
      (`adult_row_light/dark`, `peds_row_light/dark`) + `dose_table.dart`.
      The audit calls this the single highest-value fix: in print the stripe
      colour is what tells a medic at a glance whether a dose is adult or
      paediatric.
- [x] **F-9 — section bracket is `#666666` on all 117 bracketed pages**, never
      the accent. That is what lets the `#DA5798` paediatric bracket mean
      something. New `section_rule` role.
- [x] **F-25 / F-24 — borders.** Solid boxes, flow nodes and procedure cards
      are **black** in print on every chapter; dashed rules are `#999999`.
- [x] **F-8 / F-12 / F-13 — repoint the band and badge fills** to the sampled
      print values.
- [x] **F-29 + F-34 — drug-card zones become roles**, and the Notes zone is
      `#D0E0E3` cyan by default, `#D9D2E9` lavender only for Critical-Care
      drugs. One purple for both destroys the CC signal.
- [x] **F-30 / F-34 — promote the 11 content-bearing hardcodes** (procedure-card
      four, drug-card five, the two duplicated `0xFFB26A00`) to roles.
- [x] **F-3 — Drug Reference appendix accent is teal `#76A5AF`**, not Universal
      blue.
- [x] **A-7 — CC sub-tile is `#D9D2E9` with a black border.**
- [x] **A-1 / A-2 / F-23 / F-33 — the amber roles**: repoint at the WVEMS book
      level only. Print has no amber; amber currently outshouts the red octagon.
- [x] **F-4 (ADAPT) — add a 2–3 % chapter page wash.** The app is pure white, so
      `#EFEFEF` boxes and white nodes have no figure/ground separation. Must
      stay weaker than any semantic tint.
- [x] **F-1 (ADAPT)** — keep the app's darker accents for AppBar chrome
      (a `#6D9EEB` bar with white text fails contrast); derive in-page tints
      from the print's light accents.

### What Batch 1 deliberately did not do

- **`provider_paramedic` stays lavender.** The print's flat pink `#D5A6BD`
  appears exactly once in 166 pages (the p.2 legend); all 32 body `P` badges
  are the Critical-Care gradient. Repointing it before a distinct CC level
  exists would recolour 32 real badges to a colour their content does not
  mean. It belongs with the badge batch.
- **F-19 / F-20** — the *partial* row tint (a paediatric line inside a box or
  a flow node) and the node-derived zebra inside a stadium still have no
  primitive outside `ProcedureBlock`.
- **F-27** — the `#9900FF` Critical-Care outline box in the Peds Reference
  needs a "box these rows" primitive, not a tint.
- The callout keeps its **title pill**; print sets a Concept box's title as
  plain bold text. Only the colours were taken here (black pill on a neutral
  grey card), not the form.

### The Critical-Care drug list, measured

`critical_care: true` is authored on the 11 cards whose Notes zone is
lavender in print, found by exact-RGB detection of `#D9D2E9` inside each
card's y-range across pp.118–143 (kept in the repo as `tool/wvems_cc_drug_detect.py`):
**3% Saline · Etomidate · Heparin · Lasix · Levophed · Lopressor · Neo Push ·
Propofol · Rocephin · Rocuronium · Succinylcholine.** Six other cards
returned "both" — inspection showed those are ordinary cyan Notes zones
containing a *lavender inline highlight on a Critical-Care cross-link*
(Epi Drip → Vasopressors, Fentanyl, Ketamine, Magnesium, Nitro, Versed).
**That inline CC-link highlight is itself unimplemented — it belongs to
Batch 2**, which is about cross-references.

## Batch 2 — restore the cross-reference links

Source: `wvems_audit_typography.md` §3.1, §8 finding 1.

341 underlined phrases on 45 pages; the app links **18 %**, bolds 63 % and drops
19 %. Underline in print means "this is a cross-reference" and every one
coincides with a real PDF link annotation, so the target is recoverable from the
annotation's `/Dest`, not guessed. Bolding them has also collapsed the emphasis
channel — print uses bold and underline orthogonally.

Re-derive the link table (the Aug-01 scratch data is gone), map PDF page → topic
id, rewrite the YAML, and let `test/data/cross_link_test.dart` guard it.

## Batch 3 — ship the two missing pages

Source: `wvems_audit_typography.md` §5.1.

- **p.9** — an entire protocol prose page. Related: the Universal section still
  points at the 2025 edition file for pp.8–9 (`wvems_2025_008`), which is what
  made three links dead in `44ac730`.
- **p.3** — the book's own instructions: 34 lines, including *"use any
  intervention marked for your level or lower"*, the age definitions (14+ adult,
  1–13 child, <1 infant, adults under 110 lb use paediatric dosing) and the CC
  credentialing rules. Without it every one of the 363 badges is unexplained.

## Batch 4 — badges

Source: `wvems_audit_badges.md` §6.

The biggest gap is **#5**: 31 inline badges on 21 pages, in exactly the place a
reader looks for the permission boundary, rendered today as two bold characters
because `MiniMarkdown` has no badge span. Then the policy-page chips (#4b), the
heading badge (#7), the convergence-bullet badges (#8), the three authored-as-text
tile badges (#9), the two missing flow badges (#10), a distinct Critical-Care
paramedic level (#11), the badge fills (#12), the `als` → `aemt` rename (#13),
the two legends (#14, #15), and the missing octagon / trapezoid (#20, #21).

## Batch 5 — typography

Source: `wvems_audit_typography.md` §8. In the audit's priority order after the
links: a condensed body face (already in the Flutter cache; it is what the print
uses and it makes type *bigger* on screen by relieving the fit-scaler), then
units at 0.80 of the value (0.88 on peds cards), the two bullet glyphs, the
extra 0.12 em between top-level bullets, subscript `2`, curly apostrophes,
tables not shrunk, section title ratio, and small print for URLs/attributions.

---

## Log

- 2026-08-12 — audits committed `6c6891a`; this plan written; starting Batch 1.
- 2026-08-13 — **Batch 1 applied.** 595 tests pass (the same 4 pre-existing
  failures: `formula_block_test` MAP finder + 3 `table_features_test` A5.1).
  Emulator-verified against the print on p.24 (adult grey over peds pink dose
  strips, black node borders, print badge fills), p.26 and the drug reference
  (teal chrome, cyan vs lavender Notes).
