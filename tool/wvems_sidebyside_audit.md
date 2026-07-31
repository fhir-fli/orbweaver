# WVEMS prose-page side-by-side audit

Evidence pass: for every WVEMS protocol whose topic declares `layout: "paged"`,
the **printed prose page** (right-hand page, PDF page = printed page) was rendered
at 120 dpi and read directly, then compared against the block order the app
renders for that topic's second `page_number:` entry.

- Source PDF: `/home/grey/dev/fhir/orbweaver/2026-WVEMS-Protocols.pdf`
- Renderer primitives already available: `type: "row"` (RowBlock) and
  `type: "column"` (ColumnBlock), each child taking an optional `flex:`.
- Target viewport: ~393 x 852 logical px phone. A two-slot row gives each child
  roughly **185 px** of usable width after page padding and the 6 px gap.
  Anything whose longest unbreakable token needs more than ~24 characters at body
  size will not survive that, and is marked NOT VIABLE.

Verdict vocabulary:
- **already** — the app already pairs these with a `row`.
- **convert** — print pairs them, and both halves are narrow enough for 185 px.
- **no** — print pairs them but one half needs the full width on a phone.
- **n/a** — print itself is a single column; nothing to pair.

| Printed page | Topic | What print sets side by side | What the app stacks | Viable at 393 pt | Verdict |
|---|---|---|---|---|---|
| 5 | 004 Airway | nothing paired; **Poor Perfusion** is a centred half-width box floating between Imperatives and Notes | Imperatives / Poor Perfusion / Notes / Peds / Refs | its only narrow block has a long-prose neighbour on both sides | **n/a** |
| 7 | 006 Breathing | nothing paired; **BVM Rate** centred half-width box (2 lines) | Imperatives / BVM Rate / Notes / Peds / Refs | no narrow partner adjacent | **no** |
| 11 | 010 Hypertension | nothing — single column | Imperatives / Notes / Peds / Refs | — | **n/a** |
| 13 | 012 Bradycardia | nothing paired; centred **Poor Perfusion** box | Imperatives / Medications / Peds / Refs — print's Poor Perfusion box AND print's whole Notes section are ABSENT from the app | — | **n/a (content gap)** |
| 15 | 014 Tachycardia | **TRUE PAIR: Critical Arrhythmia | Poor Perfusion** (two boxes across) | Imperatives / Medications / Notes / Peds / Refs — NEITHER box exists in the app; the strings appear only as flowchart branch criteria on p.14 | would be viable (all lines under 30 chars) once the two callouts exist | **no (content missing)** |
| 17 | 016 Fever | nothing paired; centred **Poor Perfusion** box between Medications and Notes | Imperatives / Medications / Poor Perfusion / Notes / Peds / Refs | yes — Poor Perfusion lines under 29 chars, Notes is only 2 bullets | **CONVERT (adapted)** |
| 19 | 018 Hyperkalemia | **Hyper K+ EKG figure | K+ EKG Changes box** | Imperatives / K+ EKG Changes / Medications / Notes / Peds / Refs — the EKG figure is NOT in assets/books/wvems/images/ | right half fine; left half unavailable, so the 2-bullet Imperatives takes the left cell | **CONVERT (adapted)** |
| 21 | 020 Pain | nothing — single column | Imperatives / Medications / Notes / Peds / Refs | — | **n/a** |
| 23 | 022 Nausea / Vomiting | nothing — single column | Imperatives / Medications / Notes / Peds / Refs | — | **n/a** |
| 25 | 024 Medical CODE | **CODE Imperatives | Compressions** and **Medications | Obvious Death** (two boxes floated right) | Imperatives / Compressions / Obvious Death / Medications / Notes / Peds / Refs | long-prose-beside-narrow-box is a NET LOSS at 181 px (see note below); the two narrow boxes are already adjacent and both under 24 chars | **CONVERT (adapted: box | box)** |
| 27 | 026 Medical ROSC | nothing — single column | Imperatives / Medications / Notes / Peds / Refs | — | **n/a** |
| 29 | 028 Chest Pain | **STEMI Alert (dashed) | PDE5 Inhibitors box** | Imperatives / Medications / Notes / Peds / Refs — neither box exists; the PDE5 drugs are named inline inside one Medications bullet | would be viable once both callouts exist | **no (content missing)** |
| 31 | 030 Dyspnea | nothing — single column | Imperatives / Medications / Peds / Refs | — | **n/a** |
| 33 | 032 Allergic Reaction | nothing paired; centred **Poor Perfusion** box (absent from the app) | Imperatives / Medications / Notes / Peds / Refs | — | **n/a** |
| 35 | 034 Abdominal Pain | nothing — single column | Imperatives / Notes / Peds / Refs | — | **n/a** |
| 37 | 036 Altered LOC | **GCS scoring bullets | Glasgow Coma Scale table** | Imperatives / Notes (the GCS bullets are its last bullet group) / GCS table / Peds / Refs | yes — bullets under 22 chars, and the identical table already sits in a row on p.87 | **CONVERT (faithful)** |
| 39 | 038 Diabetic | nothing — single column | Imperatives / Medications / Notes / Peds / Refs | — | **n/a** |
| 41 | 040 Overdose / Tox | nothing — single column | Imperatives / Medications / Notes / Peds / Refs | — | **n/a** |
| 43 | 042 Seizure | nothing — single column | Imperatives / Medications / Notes / Peds / Refs | — | **n/a** |
| 45 | 044 Stroke | **Cincinnati Stroke | Stroke VAN** | already a `row` | yes | **already** |
| 47 | 046 Behavioral | nothing — single column | Imperatives / Medications / Notes / Peds / Refs | — | **n/a** |
| 49 | 048 Pregnancy / Delivery | nothing — single column | Imperatives / Notes / Peds / Refs | — | **n/a** |
| 51 | 050 Neonate | **Imperatives | column[Compressions, BVM Rate]**, then **APGAR | Normal SpO2** | already two `row`s (Compressions | BVM Rate, then APGAR | Normal SpO2) | band 2 faithful; band 1 not viable (Imperatives is 7 long bullets) | **already (partial)** |
| 53 | 052 Trauma CODE | **Imperatives | Compressions** and **TRAUMA Alert | Mortal Injuries** | Imperatives / Compressions / TRAUMA Alert / Mortal Injuries / Medications / Notes / Peds / Refs — all stacked | TRAUMA Alert under 22 and Mortal Injuries under 30 chars → viable; Imperatives | Compressions is not | **CONVERT (faithful, 1 of 2 bands)** |
| 55 | 054 Trauma ROSC | **TRAUMA Alert | Poor Perfusion** | already a `row` | yes | **already** |
| 57 | 056 Major Trauma | **TRAUMA Alert | Poor Perfusion** | already a `row` | yes | **already** |
| 59 | 058 Bleeding | **TRAUMA Alert | Poor Perfusion** | already a `row` | yes | **already** |
| 61 | 060 Immobilization | nothing — one dense justified column, no boxes at all | Imperatives / Notes / Peds / Refs | — | **n/a** |
| 63 | 062 Head Injury | **TRAUMA Alert** floated hard right with empty space to its left — not a pairing | Imperatives / TRAUMA Alert / Notes / Peds / Refs (the callout already renders centred at its intrinsic width, not full width) | no narrow partner exists on the page | **no** |
| 65 | 064 Trunk Injury | TRAUMA Alert centred; **pelvic-binder bullets | pelvic-binder figure** | Imperatives / TRAUMA Alert / Notes (holds the pelvic-binder bullets) / Peds / Refs | left half fine; the pelvic-binder figure is NOT in assets/books/wvems/images/ | **no (missing image)** |
| 67 | 066 Extremity Injury | TRAUMA Alert centred alone | Imperatives / TRAUMA Alert / Medications / Notes / Peds / Refs | no narrow partner | **no** |
| 69 | 068 Cold / Heat | nothing on the prose page (print's Active Warming | Active Cooling pair is on the FLOWCHART page p.68, and that is already a `row`) | Imperatives / Notes / Peds / Refs | — | **n/a** |
| 71 | 070 Burns | **column[ABLS rate, TRAUMA Alert] | BSA rule-of-9s figure** | `row`[ABLS rate | image], then TRAUMA Alert full width below | yes — the figure is taller than the ABLS callout, so folding TRAUMA Alert into the left column costs no height at all | **CONVERT (faithful)** |
| 73 | 072 Inhalation | nothing — single column | Imperatives / Notes / Peds / Refs | — | **n/a** |
| 75 | 074 Sting / Bite | three photos across (Rattlesnake / Copperhead / Black Widow) | already a 3-image `row` | yes | **already** |
| 77 | 076 Epistaxis | **anticoagulant-risk bullets | Anticoag Meds box** (9 drug names) | Notes (the anticoag bullets are its last group) / Anticoag Meds callout below it | yes — the longest drug line is `Xarelto (Rivaroxaban)`, 22 chars | **CONVERT (faithful)** |
| 79 | 078 Intubation / RSI | nothing — single column | Prereqs / Imperatives / Medications / Peds / Refs | — | **n/a** |
| 81 | 080 Sedation / Vent | **Typical Adult Vent Settings** is ONE box with two internal columns | one prose block that already packs two settings per line with a mid-dot separator | already the same effect; splitting it would break one box into two | **already** |
| 83 | 082 Vasopressors | **Shock Index | Poor Perfusion** | already a `row` | yes | **already** |
| 85 | 084 Blood | nothing — single column | Prereqs / Imperatives / Medications / Notes / Peds / Refs | — | **n/a** |
| 87 | 086 Elevated ICP | **Cushing's Triad | Glasgow Coma Scale table** | already a `row` | yes — proves a 4-column GCS table survives a 181 px cell | **already** |
| 89 | 088 STEMI | **STEMI Alert | Sgarbossa's figure** | already a `row` (Sgarbossa rendered as text, print uses an ECG figure that is not in assets) | yes | **already** |
| 91 | 090 Pulmonary Edema | nothing — single column | Prereqs / Imperatives / Medications / Notes / Peds / Refs | — | **n/a** |
| 93 | 092 Malignant HTN | nothing — single column | Prereqs / Imperatives / Medications / Notes / Peds / Refs | — | **n/a** |
| 95 | 094 Sepsis | **Prerequisites | SEPSIS Alert**, then **Organ Dysfunction | Suspect Infection** | band 2 is already a `row`; SEPSIS Alert is stacked full width after it | yes — Prereqs is a single bullet and SEPSIS Alert is 3 short lines | **CONVERT (faithful, adds band 1)** |

Not in the table: `wvems_2025_008.yaml` (Circulation / Shock) declares a single
`page_number: 8` and no top-level `layout:`, so it renders in the ordinary
scrolling view and has no prose page of its own. `wvems_2026_096/109/144/about/
drug_reference` are likewise not paged.

## The measurement that drives the priorities

`_FitToScreen` (lib/screens/topic_frame.dart) renders a paged PROSE page at
textScaler 1.0, measures it, and shrinks it 3% a step until it fits one screen,
stopping at a floor of 0.48. Running the existing probe
(`test/widgets/fit_overload_probe_test.dart`) at 393 x 852 gives the baseline:

- **45 of 45** paged prose pages need a textScaler **below 0.85** to fit.
- **20 of 45** are pinned at the **0.48 floor** — i.e. WVEMS prose is being read
  at roughly half size, and any further content would be clipped.
- Natural heights at scale 1.0 run **1305 px to 2315 px** against 852 px of
  available height.

So vertical space is the scarce resource on every single one of these pages, and
every row that removes a stacked block buys back text size directly. The ten
tallest pages at scale 1.0:

| nat. height | topic | printed page | can a row help? |
|---|---|---|---|
| 2315 | 050 Neonate | 51 | no — both print bands are already rows |
| 2166 | 078 Intubation / RSI | 79 | no — print is a single column |
| 2165 | 058 Bleeding | 59 | no — print band already a row |
| 2138 | 068 Cold / Heat | 69 | no — print is a single column |
| 2136 | 042 Seizure | 43 | no — print is a single column |
| 2101 | 056 Major Trauma | 57 | no — print band already a row |
| 2092 | 060 Immobilization | 61 | no — print has no boxes at all |
| 2078 | 006 Breathing | 7 | no — BVM Rate has no narrow neighbour |
| 2051 | 094 Sepsis | 95 | **yes** — Prerequisites \| SEPSIS Alert |
| 2034 | 062 Head Injury | 63 | no — lone TRAUMA Alert, no partner |

That is the honest headline: **the pages that are worst-squeezed are mostly not
the pages print sets side by side.** Side-by-side is worth doing where print does
it, but it is not the lever that fixes the 0.48 pages — those are long single
columns in print too.

## Why "narrow box beside long prose" cannot be reproduced

Arithmetic for a 2-slot row at 393 logical px:

- page padding 12 + 12 = 24 -> 369 px; minus the 6 px inter-slot gap -> **181 px per slot**
- inside a `callout: true` block the padding is 14 + 14 -> **153 px of text**
- prose body is 15.5 px; at the fit scales these pages actually run (0.48-0.70)
  that is roughly **33-45 characters per line**

So a block whose lines are already under ~30 characters (every WVEMS reference
box: dose tables, alert triads, criteria lists) survives a slot untouched. A
normal prose bullet of 60-95 characters does not — halving its width roughly
doubles its line count. Print can float a box into the right margin and let the
prose keep the full measure; `RowBlock` gives both children a hard 181 px, so
pairing a long bullet list with a small box **costs more height than it saves**.
That is why every conversion below pairs two already-narrow blocks, and why the
print bands `Imperatives | Compressions` (pp. 25, 51, 53) and
`Imperatives | column[boxes]` (p. 51) are recorded as NOT VIABLE rather than done.

Two renderer facts that made this safe (no lib/ change needed):

- `callout: true` renders inside `Align(center)` + `IntrinsicWidth`, so a short
  callout in a tall row slot centres itself instead of stretching into a big empty
  box. A `highlight: true` block does stretch its tinted background.
- plain prose (no `callout`, no `highlight`, no `boxed`) is bare text with no box
  at all, so an untitled plain prose block makes a clean left-hand slot beside a
  table — which is exactly what print does on p. 37.

## Measured result of the conversions (this is the part that changed the plan)

Eight conversions were authored first, then measured. **Measuring reversed four of
them.** Guessing from the printed page alone would have shipped regressions.

Method: `tool/wvems_fit_measure_test.dart` walks a FINE ladder (1.00 -> 0.44 in
0.02 steps) and reports the largest textScaler at which the page still fits
393 x 852. Rows are toggled on and off in place with a script that leaves every
other edit in the file untouched, and both halves of each A/B run back-to-back in
one window with the renderer md5 recorded before and after, so nothing else moves
between them. Untouched topics are carried through every run as controls; a run
is only trusted when every control reports identical numbers.

| topic | printed page | stacked | rowed | delta height | kept? |
|---|---|---|---|---|---|
| 024 Medical CODE | 25 | 0.74 / 1401 px | 0.74 / 1389 px | **-12 px** | KEPT |
| 036 Altered LOC | 37 | 0.74 / 1516 px | 0.74 / 1512 px | **-4 px** | KEPT |
| 052 Trauma CODE | 53 | 0.68 / 1588 px | 0.68 / 1604 px | +16 px, no scale change | KEPT |
| 094 Sepsis | 95 | 0.62 / 1777 px | 0.62 / 1778 px | +1 px | KEPT |
| 076 Epistaxis | 77 | 0.74 / 1349 px | 0.70 / 1475 px | **+126 px, -0.04 scale** | REVERTED |
| 016 Fever | 17 | 0.74 | 0.74 | none | reverted (deviated from print for nothing) |
| 018 Hyperkalemia | 19 | 0.74 | 0.74 | none | reverted (deviated from print for nothing) |
| 070 Burns | 71 | 0.70 | 0.70 | none | reverted (deviated from print for nothing) |

### Why the wins are small: the operating scale moved

While this pass was running, the renderer stream replaced the `prose` +
`highlight: true` Pediatrics blocks with a new `band_callout` block across all 45
WVEMS topics. That single change is worth far more than side-by-side: fit scales
went from **0.48-0.62** up to **0.62-0.74**, and natural heights dropped by
300-450 px per page. (Two earlier A/B rounds in this session were invalidated by
that work landing mid-comparison — the controls moved, which is how it was
caught. Only the back-to-back numbers above are trustworthy.)

That helps, and it also shrinks the prize here. At 0.48 a 181 px slot holds
~40 characters and narrow boxes sit side by side untouched. At 0.74 the same slot
holds only **~24 characters**, so lines like `Destruction of Trunk or Organs` (30)
and `Xarelto (Rivaroxaban)` (22 + box padding) start to wrap, and the wrap eats
the height the row was supposed to save. **Side-by-side pays off only when BOTH
children keep every line under roughly 20 characters.**

### The same test applied to the rows that already shipped

Toggling the pre-existing rows off, in one back-to-back window:

| topic | stacked | rowed | verdict |
|---|---|---|---|
| 044 Stroke (Cincinnati \| Stroke VAN) | 0.62 / 1645 px | 0.68 / 1604 px | **row wins +0.06** |
| 054 Trauma ROSC (TRAUMA Alert \| Poor Perfusion) | 0.74 / 1444 px | 0.72 / 1485 px | row costs -0.02 |

Same primitive, opposite outcomes, and the width rule predicts both: the
Cincinnati/VAN lines are short, while `Skin Pale, Cool, Diaphoretic` (29 chars) is
not. Worth re-checking 054 / 056 / 058 (all three carry that identical
TRAUMA Alert | Poor Perfusion pair) if further tuning is wanted — that is a
renderer/authoring decision, not part of this pass.

### Are there any pairs left worth doing?

No. A scan of every WVEMS prose page for adjacent block pairs where **both**
blocks keep all lines at or under 27 characters (link syntax and `**` stripped
before measuring) returns **zero hits**. Every genuinely narrow pair in the book
is already in a `row`. Stopping at four conversions is what the evidence supports;
reaching six to ten would mean shipping pairings that measure worse.

## What was NOT converted, and why

- **Long prose beside a small box** (print pp. 25, 51, 53, 63, 65, 67, 71): print
  floats the box into the right margin and lets the prose keep the full measure.
  `RowBlock` gives both children a hard 181 px instead, so the prose reflows and
  the page gets taller. Measured on p.53: adding print's
  `Imperatives | Compressions` band on top of the kept row dropped the fit scale
  from 0.56 to 0.52. Reproducing these needs a float/wrap primitive in the
  renderer, which this pass does not own.
- **p.15 Tachycardia** (`Critical Arrhythmia | Poor Perfusion`), **p.29 Chest
  Pain** (`STEMI Alert | PDE5 Inhibitors`), **p.13 Bradycardia** and **p.33
  Allergic Reaction** (`Poor Perfusion` box): print pairs or boxes content the app
  does not have as blocks at all. On p.13 print's whole `Notes` section is missing
  too, and on p.29 the PDE5 drug names are buried inline in a Medications bullet.
  These are content gaps to author, not layout to rearrange.
- **p.19 Hyperkalemia**, **p.65 Trunk Injury**, **p.89 STEMI**: print's left- or
  right-hand half of the band is a FIGURE (`Hyper K+ EKG` tracing, pelvic-binder
  photo, Sgarbossa ECG) that is not in `assets/books/wvems/images/`. Sourcing
  those belongs to the Wikimedia image plan.
- **p.81 Sedation / Vent**: print's `Typical Adult Vent Settings` is one box with
  two internal columns; the app already packs two settings per line with a mid-dot
  separator, which is the same effect in one block. Splitting it would turn one box
  into two.
- **The 20 tallest pages** (050, 078, 058, 068, 042, 056, 060, 006, 062 ...) are
  single columns in print as well. There is nothing to put beside anything. If
  those pages still read too small after the `band_callout` win, the lever is
  editorial (shorter Notes) or a scrollable prose page — not side-by-side.

## Files this pass touched

Converted (kept): `wvems_2026_024.yaml`, `wvems_2026_036.yaml`,
`wvems_2026_052.yaml`, `wvems_2026_094.yaml`.

`wvems_2026_076.yaml` carries a comment recording why it is deliberately NOT a
row, so the next reader does not re-try it. `wvems_2026_016/018/070.yaml` were
converted, measured, and fully reverted — they carry no change from this pass.

New: `tool/wvems_fit_measure_test.dart` (the fine-ladder measurement harness).
It lives in `tool/`, so a bare `flutter test` does not pick it up; run it
explicitly with `flutter test tool/wvems_fit_measure_test.dart`.

## Concurrency note

This pass ran alongside the renderer stream's `band_callout` work, which edits
the same 45 WVEMS YAML files. Two things to know:

- `fit_overload.tsv` at the repo root (untracked, owned by that stream) was
  overwritten by probe runs here and then refreshed against the current tree, so
  it holds current numbers rather than the empty header it started with.
- Whole-file restores are unsafe while both streams are live — they silently undo
  the other stream's edits. Every toggle in this pass was done with a targeted
  string replacement instead, and `band_callout` presence was re-checked in all
  45 files afterwards.
