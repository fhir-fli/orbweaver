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

**Link table re-derived 2026-08-13** — `tool/wvems_link_extract.py` reads every
PDF link annotation and recovers its phrase char-by-char from the annotation
rect. **1,492 links over all 166 pages**, which is exactly the audit's 1,284
internal + 208 external, so the extraction reproduces the measurement.

### Where the print's links point, and what the app can receive

| dest range | app target | state before this batch |
|---|---|---|
| 4–95 protocols | `wvems-2026-<even page>` | works |
| 96–108 procedures | `wvems-2026-096` (31 cards, one topic) | **needs an anchor** |
| 109–117 policies | `wvems-2026-109` (24 sections, one topic) | **needs an anchor** |
| 118–143 drugs | `wvems-2026-drug-reference` (50 cards, one topic) | **needs an anchor** |
| 144–161 peds ref | `wvems-2026-144` | works |
| 1, 162–166 | index / back cover | no app target |

46 % of the graph lands in a *single* topic holding 50 drug cards or 31
procedure cards. A destination page alone would drop the reader at the top of
that topic, which is not the cross-reference the print makes — so the anchor
work is a prerequisite, not a polish item, and `mini_markdown.dart:85` currently
throws the anchor away (`split('#').first // anchor TODO`).

The *target within* the topic is not guessed either: the link phrase is the drug
or procedure name ("Versed" → p.143), so phrase → card is an exact match.

### Sub-batches

- [x] **2a — wire cross-topic anchors.** `openLinkedTopic(context, id, anchor:)`
      threaded through `TopicFrame`/`TopicPager` to `TopicView`, which already
      keeps a `GlobalKey` per `anchor:` block for same-topic `#slug` links.
- [x] **2b — give every card an anchor.** Drug cards slug from `name`,
      procedure cards from their title, policy sections from their heading.
- [x] **2c — rewrite the YAML, odd (prose) pages.** 253 restored, 53 already
      correct. Print weight followed: a protocol / policy / peds reference is
      regular weight + underline, a drug or procedure is bold + underline.
- [x] **2d — guard it.** `test/data/cross_link_test.dart` now checks the
      `#anchor` half too, and fails if the anchored-link count collapses.
- [x] **2e — even (flowchart) pages.** 323 restored. Flowchart text is not
      markdown, so this needed a renderer change (`flow_link.dart`) rather than
      a rewrite: the print puts *several* references on one line — p.34's
      "Fever, Pain, Nausea" is three links — which a per-node `link_id` cannot
      express, and that bullet had all three pointing at Pain. 73 redundant
      `link_id`s dropped; 18 exceptions reported.
- [x] **2f — outbound links from the appendix topics.** 66 restored, 96 already
      correct. Needed `appendix_range()` (a printed page → its line range inside
      a single-file topic) and the `--appendix` flag. A drug card can now reach
      the procedure that administers it and the other drug cards.

### What Batch 2 could not restore

**`tool/wvems_links_not_restorable.md`** — 65 cross-references on 13 pages
whose sentence is simply not in the app. These are the eleven rewritten pages
audit §5.1-5.2 already lists (p.11's whole *Notes* section is different copy,
p.13's and p.15's are gone, p.31 differs on the PDE5 window), so they are
content work, not link work. Two more are a genuine decision: the print points
**Dyspnea** at p.6 *Breathing* while the app points it at p.30 *Dyspnea*, and
the app's target was left alone.

### The three tools, and how to re-run them

```
pdfvenv/bin/python tool/wvems_link_extract.py  links.tsv
pdfvenv/bin/python tool/wvems_link_resolve.py  links.tsv targets.tsv
pdfvenv/bin/python tool/wvems_link_apply.py    targets.tsv report.tsv [--apply] [--odd|--even]
```

`pdfvenv` is a throwaway venv with `pymupdf` + `pyyaml`. Each writes every row
as it is produced; `wvems_link_apply.py` without `--apply` only reports.

## Batch 3 — ship the two missing pages ✅

Source: `wvems_audit_typography.md` §5.1. Applied 2026-08-14 (`6af9bef`).

- [x] **p.9** — the whole prose page, transcribed from the 2026 PDF as
      `wvems_2026_008.yaml` with the two-page shape every sibling has and the
      print's 19 cross-references. `wvems_2025_008.yaml` is gone; the 53
      references that pointed at the id it never had now resolve.
- [x] **p.3** — `wvems_2026_003.yaml`, "How To Use", in the front-matter group.
      It is what makes the badges mean anything, so it had to land before
      Batch 4.

## Batch 4 — badges 🚧

Source: `wvems_audit_badges.md` §6. Applied 2026-08-14/15 (`49c6878`,
`3af8e38`).

### Done
- [x] **#5 the badge span** — the audit's "single biggest gap". `ScopeChip`
      promoted to `lib/widgets/scope_chip.dart`; `MiniMarkdown` and the
      flowchart inline parser both take `{E}` / `{A}` / `{I}` / `{P}` /
      `{P(CC)}` / `{}`. Braces collide with nothing, so it is safe beside
      `[text](target)`. 24 literal badges converted.
- [x] **#11 a distinct Critical Care level** + **#12 fills** + **#13 `als` →
      `aemt`.** `provider_paramedic` is the print's pink, `provider_critical_care`
      the purple; the 29 body `P` badges are reclassified, since the audit found
      the pink `P` exactly once in 166 pages.
- [x] **#4b** policy chips · **#7** heading badge · **#9** three tile badges
      authored as text · **#10** two missing flow badges · **#14/#15** the
      legend now draws real badges and carries the "your level or lower"
      sentence · **#20** the missing octagon · **#21** the missing trapezoid ·
      **#27** the twelfth alert box.

### Left in batch 4
- [x] **#8** p.24's two convergence-bullet chips. (The summary names p.52 too;
      that page's own badge dump has none.)
- [x] **#22 / #23** the three box registers. The colour batch had already made
      a callout grey; what was missing was the *form* — `dashed: true` had
      never been used, so every conditional box rendered solid. The twelve
      alert boxes are dashed now, and a dashed box's title is plain bold text
      rather than the firm box's solid chip.
- [x] **#33** the seven Critical-Care bands whose line exists. The other five
      are missing *text*, not a missing band — see
      `wvems_links_not_restorable.md`.
- [x] **#34 (form)** the pill is a tab fused to the stadium's bottom edge, with
      no arrow: it is not a next step, it is the same disposition for a
      credentialed provider.
- [x] **#34 (coverage)** all 19 CC sub-tabs authored. Text extracted from the
      print's lavender fills (`wvems_cc_tab_extract.py`), every target confirmed
      against the page's own link annotations. pp.4 and 72 had the tab modelled
      as a `post_convergence:` stadium with a dangling empty `exits:`; both
      removed in favour of the real form.
- [ ] **#3b** the p.96 procedures index is itself a scope table ("who may do
      what", at a glance) — the app uses a book-level `view: "index"` with no
      badges. Marked ADAPT → *decide*, so it needs Grey.
- [x] **#26** the "Call ER" phone tile, on the 12 pages the audit measured.
      Drawn as a vector (fixed geometry, twelve pages, one varying word), with
      its green and red as palette roles. `call_er:` is explicit rather than
      inferred from `dashed:` — a dashed box is also the print's ordinary
      conditional (p.43), which gets no tile.
- [ ] **#30/#31** population edge tabs — the pink `Peds` right-edge tab on an
      action tile (3 instances) and the per-row Adult/Peds tab in a dose table
      (the app draws a full-width section band instead; §6.4 calls that "form
      differs, meaning preserved").
- [ ] **#24** zebra-striped age-band entry stadium (6 pages) — marked
      DROP → decide, low value, content already present.

## Batch 5 — typography 🚧

Source: `wvems_audit_typography.md` §8, in the audit's own priority order.

- [x] **A condensed body face** (§3.10, the audit's third priority overall).
      `font_family:` joins the book → chapter → topic cascade and WVEMS asks
      for `RobotoCondensed`; the other books keep the default, because the face
      is a property of the printed source.
      ⚠️ **The audit's "already in the Flutter cache, no new asset" is wrong.**
      It is in the SDK cache but a built APK bundles no Roboto at all — the
      FontManifest holds only MaterialIcons — so the family fell back silently
      and the first build looked identical. The five faces ship under
      `assets/fonts/` now (Apache 2.0). Check by unzipping the APK, never by
      looking at the screenshot twice.
      ⚠️ **`page_fits.tsv` cannot measure this** — that harness renders in Ahem.
- [x] **Units set smaller than the value** (§3.2, the audit's fourth priority).
      Applied by rule, not authored: `unitAwareSpans` shrinks any unit token
      that follows a number, in both parsers, so no YAML churn. **Vocabulary
      measured off the PDF** (`wvems_unit_census.py`), which corrected two
      guesses: an age is never a unit here, and abbreviated time shrinks while
      spelled-out time does not. Scale 0.85, not the print's 0.80 — the audit
      asks for a screen test first; one constant to change.
- [x] Two bullet glyphs (§3.8) · the bullet pitch ratio (§3.9) · section-title
      step 1.107 → 1.20 (§3.6) · subscript `₂`, 54 (§3.3) · the ® at 0.70, 109
      (§3.3) · typographic apostrophes, 99 (§5.5) · References at 0.8 (§3.7).
- [x] **Tables — deliberately NOT raised** (§6.6). The print sets its GCS,
      APGAR and Shock Index tables at full prose body, so both were tried at
      1.167 and 1.083; the GCS broke five and then three cells mid-word. The
      print's rule assumes a 576 pt page. **Instead the real defect was fixed:**
      the GCS shared its row 1:1 with prose and broke "confused" / "withdraw" /
      "localizes" *at the default size*; the row is 6:4 now.

### Batch 5 leftovers
- [ ] Superscript ordinals (`15th`) — audit says leave plain on a phone, and
      §3.7's smaller References line already carries the intent. Nothing to do
      unless Grey disagrees.
- [ ] The print's `/` at 0.88 and parens at 0.92 (a compound like
      "Ketamine (pain): 3 mg" steps down twice). Fine detail; not attempted.

---

## Log

- 2026-08-12 — audits committed `6c6891a`; this plan written; starting Batch 1.
- 2026-08-13 — **Batch 1 applied.** 595 tests pass (the same 4 pre-existing
  failures: `formula_block_test` MAP finder + 3 `table_features_test` A5.1).
  Emulator-verified against the print on p.24 (adult grey over peds pink dose
  strips, black node borders, print badge fills), p.26 and the drug reference
  (teal chrome, cyan vs lavender Notes).
- 2026-08-13 — **Batch 2 prose pages applied.** Link graph re-derived from the
  PDF (1,492 annotations, matching the audit exactly); cross-topic anchors
  wired; 253 links restored, 65 reported as unrestorable. 597 tests pass, same
  4 pre-existing failures. Emulator-verified: p.21 shows the two weights
  correctly side by side, tapping **Fentanyl** lands on the Fentanyl card 23
  cards into the drug reference, tapping **Tourniquet** lands on the Tourniquet
  card 17 cards into the procedures.
- 2026-08-14 — **Batch 2 flowchart pages applied** (`ef03212`). 323 links over
  the 46 even pages. Verified on p.34 (three references in one bullet, Nausea
  now opens p.22) and p.22 (the dose table's Zofran opens the drug reference;
  the action tile above it stays unlinked, as in print).
- 2026-08-14 — **Batch 2 complete** (`944958a`). 642 cross-references restored
  in total: 253 prose, 323 flowchart, 66 appendix. Unrestorable and conflicting
  ones are listed in `tool/wvems_links_not_restorable.md`.
- 2026-08-14 — **Batch 3 applied** (`6af9bef` + `9192de3`). WVEMS book 51 → 52
  topics. Verified on the emulator: p.8, p.9 and How To Use.
- 2026-08-14/15 — **Batch 4 part 1** (`49c6878`, `3af8e38`). The badge span, the
  two `P` levels split, and every discrete missing chip/shape the audit lists.
  ⚠️ Two traps cost time: a stale asset bundle survived uninstall+install
  because `flutter build apk` skipped the asset copy (fix: `flutter clean`), and
  the shared `~/.pub-cache` loses packages mid-build when another session runs
  `pub get` (fix: re-run `flutter pub get`, don't chase it).
- 2026-08-15 — **Batch 5 begun** (`5814eb5`): the condensed body face, book-scoped.
- 2026-08-16 — **Batch 5 complete** (`9e47e71`, `9e18d35`, `1035199`): units,
  bullet glyphs and pitch, section step, subscripts, ®, apostrophes, References.
  Tables left at their reduction on evidence, and the GCS row rebalanced.
- 2026-08-17 — **#34 complete** (`ae10347`): all 19 CC sub-tabs. What is left of
  the three audits is #3b, #26, #30/#31, #24 — three of the four are marked
  "decide" in the audit and want Grey's call, and #26 is a new vector asset.
- 2026-08-17 — **#26 done** (`ebe8467`, fixed in `761a0fd`). **Every build item
  in the three audits is now applied.** What is left is only the three the
  audits themselves mark "decide": #3b, #30/#31, #24.

---

## The three "decide" items, investigated 2026-08-17

Each was measured before recommending, rather than argued from the audit text.

**#3b — the p.96 procedures index as a scope table.** The print devotes a page
to a 9-section grid: every procedure as a tile with its scope badge, "who may
do what" at a glance. **Checked: the app already holds this information and it
is exactly right** — all 27 card `scope:` values match the print's index badges,
**0 mismatches**, and the 4 the grid omits are the Critical Care procedures it
summarises as "P 107 & 108". So this is a missing *view*, not a missing fact,
and it is now cheap: a `table` whose cells carry `{E}` badges needs no code.
**The judgement is whether a scan-view earns its place** — in print you flip to
it; in the app you would scroll past it every time you open Procedures.
→ Grey's call. Genuinely optional.

**#30 — the action-tile pink `Peds` side tab (3 instances, pp.12, 50, 78).**
Mostly already conveyed, in a different form: p.12's Epi carries
`condition: "Peds"` and p.78's Intubate / Bougie Cric carry `condition:
"Adult"`, which partitions the same way. Only p.50's appears unrepresented.
→ **Recommend skip.** One instance, meaning largely preserved.

**#31 — the dose-row Adult/Peds edge tabs.** The colour batch made the dose
row's *fill* encode population (adult grey, peds pink), which the audit itself
calls the print's primary signal — the tab is the label on it. §6.4 already
grades this "form differs, meaning preserved".
→ **Recommend skip.** Done in substance.

**#24 — the zebra-striped age-band entry stadium (6 pages).** Only the striping
is lost; every threshold is present in the stadium text.
→ **Recommend skip.** The audit marks it low value itself.
