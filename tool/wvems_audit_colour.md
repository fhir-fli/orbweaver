# WVEMS 2026 Protocols — COLOUR, FILLS AND HIGHLIGHTING audit

**Source of truth:** `/home/grey/dev/fhir/orbweaver/2026-WVEMS-Protocols.pdf`
(166 pages, 612 × 1008 pt. Printed page N = PDF page N.)

**App under audit:** `/home/grey/dev/fhir/orbweaver-wt` — `lib/theme/palette.dart`,
`lib/theme/topic_theme.dart`, and every widget under `lib/widgets/`.

**Scope:** colour only. Typography, badge glyphs/symbols and layout geometry belong to
other streams; they appear here only where colour is the carrier.

**Status of every claim:** every RGB below was sampled from a pixel render, not read by
eye. Where a thing could not be determined it says **unknown**.

---

## 0. Method

1. All 166 pages rendered with `pdftoppm -r 100 -png` → 850 × 1400 px per page
   (1 px = 0.72 pt). Renders at
   `/tmp/claude-1000/-home-grey-dev-fhir/8f9442b1-043e-47a0-a2fe-e29e007cc633/scratchpad/wvems_png/`.
2. **Full inventory pass** (`colour_inventory.py`): every page, every pixel, exact-RGB
   histogram excluding near-white and near-black; top 40 colours per page with pixel
   counts and bounding boxes → `colour_inventory.tsv` (6 641 rows).
3. **Chrome probe** (`probe_chrome.py`): modal colour of the page background, top bar,
   bottom bar, left rail, right rail, and both page-number circles, for all 166 pages
   → `chrome_probe.tsv`.
4. **Exact-colour census** (`census.py`): 42 named target RGBs counted exactly on all
   166 pages with bounding boxes → `census.tsv`, rolled up to `census_bycolour.tsv`
   and `perpage.tsv`.
5. **Run-length scanlines** (`scanline.py`) and **region probes** (`probe_pt.py`) for
   every structural question (band edges, bracket colours, zebra row boundaries,
   border weights, gradient badges).
6. Every script writes per iteration with `fh.flush()` and `print(..., flush=True)`.

The book is authored in a Google-Slides-family tool: **every fill in it is a member of
the standard Google swatch set** (`#FFC0CB`, `#D9EAD3`, `#CFE2F3`, `#E6B8AF`, `#FFF2CC`,
`#674EA7`, `#CC0000`, …). That is why the colours are so consistent across 166 pages and
why exact-match counting works at all — there is no gradient noise except in one place
(§4.3).

---

## 1. Page chrome — the chapter system

Sampled on all 166 pages (`chrome_probe.tsv`). Every protocol page carries **four**
chapter-coloured elements and **one** chapter-derived page wash:

| Element | Where |
| --- | --- |
| Page-number circle | top-left (all pages) and bottom-right (all pages) |
| Title bar | **top** on even pages, **bottom** on odd pages |
| Edge rail | **left** on even pages, **right** on odd pages (i.e. the *outer* edge of the spread — a thumb index) |
| Page wash | the entire page background, a ~3 % tint of the accent over white |

### 1.1 The accents and washes, as sampled

| Chapter | Pages | Print accent | Print page wash | App accent (`book.yaml`) | App `accent_fill` | Verdict |
| --- | --- | --- | --- | --- | --- | --- |
| Universal | 4–23 | `#6D9EEB` (109,158,235) | `#F5F8FD` (245,248,253) | `0xFF1E4E8C` (30,78,140) | `0xFFE8F0FA` | **ADAPT** |
| Medical | 24–51 | `#6AA84F` (106,168,79) | `#F5F9F3` (245,249,243) | `0xFF2E7D32` (46,125,50) | `0xFFEAF4EB` | **ADAPT** |
| Trauma | 52–77 | `#DD7E6B` (221,126,107) | `#FCF6F5` (252,246,245) | `0xFFC55A11` (197,90,17) | `0xFFFBEEE4` | **ADAPT** |
| Critical Care | 78–95 | `#351C75` (53,28,117) | `#F2F0F6` (242,240,246) | `0xFF6A1B9A` (106,27,154) | `0xFFF1E7F6` | **ADAPT** |
| Front matter + Procedures + Policies | 2–3, 96–117 | `#E69138` (230,145,56) | `#FDF8F2` (253,248,242) | Procedures `0xFFC55A11`, Policies `0xFF455A64` | — | **ADAPT** |
| Drug Reference | 118–143 | `#76A5AF` (118,165,175) | `#F6F9F9` (246,249,249) | `0xFF1E4E8C` (Universal blue) | `0xFFE8F0FA` | **ADAPT** |
| Peds Reference | 144–161 | `#FFC0CB` (255,192,203) | `#FFFBFB` (255,251,251) | `0xFFAD1457` | `0xFFFDE7F0` | **ADAPT** |
| Index / About | 162–165 | `#999999` (153,153,153) | `#EFEFEF` (239,239,239) | `0xFF455A64` | `0xFFECEFF1` | **ADAPT** |
| Front cover / back cover | 1, 166 | `#6AA84F` / white | — | — | — | DROP |

**Findings**

- **F-1 · The app's chapter accents are all substantially darker and more saturated than
  print.** Universal is the extreme case: print `#6D9EEB` is a light cornflower blue,
  the app uses `0xFF1E4E8C`, a near-navy. Trauma print `#DD7E6B` is a soft salmon; the
  app uses `0xFFC55A11`, a burnt orange. This is defensible on a phone (a light
  cornflower AppBar with white text fails contrast), so: **ADAPT — keep the app's darker
  accents for chrome, but derive the *content* tints from the print values**, because the
  print's light accents are what the in-page tints (rails, washes, node fills) are built
  from. Do not simply darken everything.
- **F-2 · Procedures (96–117) and the front matter (2–3) share ONE accent in print
  (`#E69138` orange); the app splits them into Procedures = Trauma orange and Policies =
  slate grey.** Print draws pp.96–117 as a single orange run, including the Policies
  pages. Verified: `acc_frontmatter_orange` is present on pages 2, 3, 96–117 continuously
  (`census_bycolour.tsv`). **ADAPT** — the app's split is a reasonable navigational
  improvement, but it is a divergence and should be a conscious one.
- **F-3 · The Drug Reference appendix has its own teal accent `#76A5AF` in print
  (pp.118–143); the app gives it Universal blue.** **KEEP the print teal** — it is the
  only cue distinguishing a drug card page from a protocol page at a glance, and the
  drug-card header fill (`#3A5D64`, §5.1) is the dark form of the same hue.
- **F-4 · The per-chapter page wash is not reproduced at all.** `topic_frame.dart:249`
  and `:339` set `Scaffold(backgroundColor: Colors.white)`. Print washes every page in a
  ~3 % accent tint; that wash is what makes a white node or a `#EFEFEF` box read as
  *raised* rather than as page. **ADAPT** — a 2–3 % wash is cheap and would restore the
  figure/ground separation the app currently loses, but it must be *chapter*-derived and
  must not be so strong that it competes with the semantic tints in §2.
- **F-5 · The edge rail is an outer-edge thumb index (left on verso, right on recto).**
  It carries the NEMSIS codes and the "Reviewed:" date in rotated type. This is a
  print-navigation affordance for a bound book. **DROP** — a phone has no spread and no
  fore-edge; the app's AppBar already carries the chapter colour.
- **F-6 · The alternating top-bar / bottom-bar placement is also spread logic** (bar at
  the top of the verso, bottom of the recto, so a spread is framed top-and-bottom).
  **DROP.** Note the appendices break the rule: pp.96–117 and 118–143 carry **both** a
  top and a bottom bar on every page.
- **F-7 · The app renders no footer bar and no page-number circle.** Print puts the
  protocol title in the bar and the page number in an accent circle at both corners.
  This is pagination, not clinical content. **DROP.**

---
## 2. The semantic palette — master table

Every one of these is **semantic**: the same RGB carries the same meaning on every page
of every chapter. None of them changes with the chapter accent. Page counts are exact
matches from `census.tsv` (threshold ≥ 40 px, so a colour used only for hairlines can be
under-counted; noted where it matters).

| # | Print RGB | Hex | Meaning | Pages | App role | App value | Δ | Verdict |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 1 | (255,192,203) | `#FFC0CB` | **Paediatric** content band / row / tab | **78** | `peds_band_fill` | `0xFFFBD5DE` (251,213,222) | −4,+21,+19 | **KEEP print value** |
| 2 | (218,87,152) | `#DA5798` | Paediatric section **bracket** | 50 (+ more under threshold) | `peds_band_rule` | `0xFFDA5798` | **exact** | KEEP |
| 3 | (255,220,226) | `#FFDCE2` | Paediatric **zebra light row** | 4 | *none* | — | missing | **KEEP** |
| 4 | (210,50,130) | `#D23282` | "Peds" dose-table **tab** | 4 | `pop_peds` `0xFFF8C9DA` | (248,201,218) | very different | **ADAPT** |
| 5 | (217,210,233) | `#D9D2E9` | **Critical Care** content band / drug-card Notes | **54** | `cc_band_fill` | `0xFFE3DCF2` (227,220,242) | +10,+10,+9 | **KEEP print value** |
| 6 | (207,226,243) | `#CFE2F3` | Flow **entry / indications** stadium | 48 | `flow_entry` | `0xFFCDE0F1` (205,224,241) | −2,−2,−2 | KEEP (≈ exact) |
| 7 | (229,239,247) | `#E5EFF7` | **Zebra inside an entry node** | 6 | *none* | — | missing | **KEEP** |
| 8 | (217,234,211) | `#D9EAD3` | Flow **convergence / "Don't Forget"**; drug-card **Use** zone | **73** | `flow_convergence` | `0xFFD5ECD6` (213,236,214) | −4,+2,+3 | KEEP (≈ exact) |
| 9 | (230,184,175) | `#E6B8AF` | Flow **decision / "Use Judgement"** diamond | 42 | `flow_decision` | `0xFFF6BDAE` (246,189,174) | **+16**,+5,−1 | **ADAPT** — app is 16 points redder |
| 10 | (103,78,167) | `#674EA7` | **"Important Note"** trapezoid (fill, white text) | 26 | `warning_caution` | `0xFF7E57C2` (126,87,194) | +23,+9,+27 | **ADAPT** |
| 11 | (204,0,0) | `#CC0000` | **WARNING** octagon (fill, white text, black border) | 11 | `warning_safety` | `0xFFD32F2F` (211,47,47) | +7,+47,+47 | **ADAPT** |
| 12 | (244,204,204) | `#F4CCCC` | Severity-tinted **branch box** (p.68 "Major Hyper") | 1 | `severity_severe_tile` `0xFFFFEBEE` | (255,235,238) | much paler | **ADAPT** |
| 13 | (255,217,102) | `#FFD966` | Provider badge **E** (EMT) | 46 | `provider_emt` | `0xFFF2C24A` (242,194,74) | −13,−23,−28 | **KEEP print value** |
| 14 | (147,196,125) | `#93C47D` | Provider badge **A** (AEMT) | 44 | `provider_als` | `0xFF7BBF86` (123,191,134) | −24,−5,+9 | **KEEP print value** |
| 15 | (111,168,220) | `#6FA8DC` | Provider badge **I** (Intermediate) | 34 | `provider_intermediate` | `0xFF6FAADB` (111,170,219) | +0,+2,−1 | KEEP (≈ exact) |
| 16 | (213,166,189) | `#D5A6BD` | Provider badge **P** (Paramedic) | **1 — p.2 legend only** | `provider_paramedic` | `0xFFAB91D8` (171,145,216) | very different | **see F-14** |
| 17 | gradient `#8E61FF`→`#FED3EA` | — | Provider badge **P** (Critical Care Paramedic) | 12 | *none* | — | missing | **ADAPT** |
| 18 | (239,239,239) | `#EFEFEF` | Neutral **"Concept" box** fill; EMR badge; **adult zebra light row** | 106 | `provider_any` `0xFFE0E0E0`; `pop_adult` `0xFFD9D9D9` | | split | ADAPT |
| 19 | (217,217,217) | `#D9D9D9` | **Adult zebra dark row** | 68 | `pop_adult` | `0xFFD9D9D9` | **exact** | KEEP (but see F-11) |
| 20 | (102,102,102) | `#666666` | **Section bracket** on every ordinary section; "Adult Doses" tab | **117** | *none* — app uses `accent` | chapter accent | **wrong kind** | **KEEP print value** |
| 21 | (153,153,153) | `#999999` | **Dashed** conditional-box border | 79 | `alert` `0xFFF6A609` amber | (246,166,9) | **wrong kind** | **KEEP print value** |

### 2.1 Findings on the semantic palette

- **F-8 · The two population/credential band fills are both too pale in the app.**
  `peds_band_fill` `0xFFFBD5DE` and `cc_band_fill` `0xFFE3DCF2` are washed-out versions
  of the print's `#FFC0CB` and `#D9D2E9`. The print value is the one that survives being
  glanced at on a moving ambulance; the app's is the one that disappears against a white
  page. **KEEP the print values.** (`palette.dart:55` and `:57`.)
- **F-9 · The section bracket is neutral grey `#666666` in print on all 117 pages that
  have one — never the chapter accent.** Verified by scanline on p.11 (Universal, blue
  chapter → bracket `#666666`) and p.71 (Trauma, salmon chapter → bracket `#666666`).
  The app draws it in `theme.header` = the chapter accent
  (`prose_block_view.dart:155`, `:160`). This is **exactly the bug class Grey already
  hit with the Pediatrics section**: a colour that is fixed and semantic in print becomes
  chapter-derived in the app. Because the *only* coloured brackets in print are the
  paediatric ones (`#DA5798`), colouring every bracket with the accent destroys that
  contrast — on a Trauma page the app draws four salmon brackets and one pink one, and
  they read as the same family. **KEEP the print value: `#666666` for ordinary sections,
  `#DA5798` for peds.**
- **F-10 · The print's section titles are BLACK.** `band_callout_block_view.dart:22-26`
  documents deliberately diverging (title takes the band colour). That divergence is
  defensible *for the band* — it is the fix for the earlier salmon-Pediatrics bug — but
  the same file's reasoning has leaked into `prose_block_view.dart:160`, where ordinary
  section titles also take the chapter accent. Print: black. **ADAPT** — keep the pink
  "Pediatrics" title (it is a real improvement over print), but set ordinary section
  titles black so the coloured ones still mean something.
- **F-11 · There is no purple bracket on a Critical Care band in print.** Scanline on
  p.11 at y=370 and y=880: the lavender run begins at x=10, immediately right of the
  *enclosing* section's `#666666` bracket, and no rule of its own is drawn. Confirmed on
  every CC run sampled (pp.3, 4, 11, 100). The app draws a `cc_band_rule` `0xFF6A1B9A`
  bracket around every CC band (`band_callout_block_view.dart:41`). **ADAPT** — the app's
  bracket is not wrong on a phone (a bare tint with no left edge is easy to miss when it
  is not adjacent to its parent bracket), but it is an addition, not a reproduction, and
  it should be recorded as such.
- **F-12 · The provider badge colours are all shifted.** E is 13/23/28 points darker,
  A is 24 points less red, P is a different colour entirely. The badges are a
  colour-coded credentialing key printed on p.2; they only work if they match. **KEEP the
  print values** for `provider_emt` `#FFD966`, `provider_als` `#93C47D` (already correct
  for `provider_intermediate`).
- **F-13 · `provider_any` should be `#EFEFEF`, not `0xFFE0E0E0`.** The EMR badge on p.2
  and the blank badge on p.30's "Position of Comfort" tile both sample `#EFEFEF`.
- **F-14 · The flat mauve Paramedic badge `#D5A6BD` appears on exactly ONE page in the
  whole book — p.2, the legend.** Low-threshold scan (≥5 px, `paramedic_scan.tsv`)
  across all 166 pages found it nowhere else. Every in-book "P" badge is the Critical
  Care Paramedic gradient (F-15). The app maps `ProviderLevel.paramedic → 'P' →
  0xFFAB91D8` and uses it everywhere. **ADAPT:** the app needs *two* P levels — a flat
  `#D5A6BD` paramedic (which the content will almost never use) and a distinct
  critical-care paramedic.
- **F-15 · The Critical Care Paramedic badge is a diagonal gradient, `#8E61FF` violet →
  `#FED3EA` pale pink.** Sampled on p.2 and on pages **78, 80, 82, 84, 86, 88, 90, 92,
  94, 107, 108, 116** — i.e. *every even page of the Critical Care chapter*. It is the
  only gradient anywhere in the book. **ADAPT** — a two-stop `LinearGradient` is trivial
  in Flutter and is the single strongest "you need a credential for this" signal in the
  print; but if it is judged too fussy for a 20 px chip, a flat mid-violet is an
  acceptable substitute. It must not stay identical to the plain paramedic badge.
- **F-16 · The dashed conditional box is `#999999`, not amber.** See §3.2.
- **F-17 · Two colour meanings collide on `#674EA7`.** It is the Important-Note trapezoid
  fill (26 protocol pages) *and* the Broselow PURPLE band on p.149. Same for `#CC0000`
  (warning octagon *and* the Broselow RED band, p.148), `#E69138` (front-matter accent
  *and* Broselow ORANGE, pp.155–156) and `#DA5798` (peds bracket *and* Broselow PINK,
  p.147). The collisions are confined to the Peds Reference appendix, where the colour is
  naming a Broselow tape band and nothing else. No action — but do not "unify" these into
  one role.

---
## 3. TABLE ROW COLOURING

There are **four different row-colouring systems** in the book, and they mean different
things. A previous pass generalised from a couple of pages and got this wrong; each of
the four is stated below with the pages it was verified on.

### 3.1 Dose-table zebra — striping is **POPULATION**, not decoration

Every flowchart page (even pages 4–94) ends with a medication dose strip. The rows
alternate, and **the pair of alternating colours encodes who the doses are for**:

| Population | Light row | Dark row | Right-hand tab |
| --- | --- | --- | --- |
| **Adult** | `#EFEFEF` (239,239,239) | `#D9D9D9` (217,217,217) | `#666666` grey, white text "Adult / Doses" |
| **Paediatric** | `#FFDCE2` (255,220,226) | `#FFC0CB` (255,192,203) | `#D23282` magenta, white text "Peds" |

Verified by column scanline:

- **p.18** `col100 y1205-1320`: `#EFEFEF` → `#D9D9D9` → `#EFEFEF`; tab at
  `x760-820` is `#666666`. Pure adult table.
- **p.24** `col100 y1168-1318`: an **adult** table (`#EFEFEF`/`#D9D9D9`) stacked directly
  above a **peds** table (`#FFDCE2`/`#FFC0CB`), with `#666666` "Adult" and `#D23282`
  "Peds" tabs respectively. This page is the proof that the colour is the population and
  not the page.
- **p.12** and **p.50**: single peds-only dose rows, `#FFDCE2` with a `#D23282` "Peds"
  tab, on Universal-blue and Medical-green pages respectively — the stripe colour does
  not follow the chapter.
- Zebra always starts light: row 1 is `#EFEFEF` / `#FFDCE2`.
- Pages 8, 14, 16, 18, 20, 24, 28, 30, 32, 38, 40, 42, 46, 52, 56, 76, 78, 80, 82, 84,
  86, 90, 92 carry ≥ 2 rows and therefore show visible alternation; the remaining even
  pages have 1-row strips where only the light colour appears.

**What the app does:** `lib/widgets/flowchart/dose_table.dart:38-40` —

```dart
color: i.isEven ? theme.nodeFill : theme.nodeFill.withValues(alpha: 0.5),
```

`theme.nodeFill` is `accent_fill`, i.e. **the chapter colour**. So the app stripes the
dose table in pale blue on Universal, pale green on Medical, pale salmon on Trauma and
pale lavender on Critical Care, *identically for adult and paediatric rows*. The only
population cue left is the thin `_PopulationLabel` band (`popAdult` `0xFFD9D9D9`,
`popPeds` `0xFFF8C9DA`) above each group.

> **F-18 · KEEP — the dose-table zebra must be population-derived, not chapter-derived.**
> This is the single most load-bearing colour decision in the book: a medic reading a
> dose row can tell at a glance whether it is an adult or a paediatric dose from the row
> fill alone, without finding a group header. The app currently throws that away and
> replaces it with a chapter tint that carries no clinical information. Fix: stripe
> `#EFEFEF`/`#D9D9D9` for `DosePopulation.adult` and `both`, `#FFDCE2`/`#FFC0CB` for
> `DosePopulation.peds`. `pop_peds` should become `#FFC0CB` (currently `0xFFF8C9DA`),
> and two new roles are needed for the light stripes.
>
> **ADAPT** the group label: print puts it in a right-hand vertical tab
> (`#666666` / `#D23282`, white text); the app's full-width horizontal band is a
> sensible phone adaptation and should stay, but should take the tab colours.

### 3.2 Semantic row tint inside a box — the paediatric row(s)

**p.71 "ABLS rate:" box** (`col100` and `col310`, y 340–545):

| Row | Fill |
| --- | --- |
| "ABLS rate:" title | `#EFEFEF` |
| `14+ y/o: 500 mL/hr` | `#EFEFEF` |
| `6-13 y/o: 250 mL/hr` | **`#FFC0CB`** |
| `0-5 y/o: 125 mL/hr` | **`#FFC0CB`** |

The pink starts at y = 442 and runs to the box's inner bottom edge at y ≈ 533. **Both**
paediatric rows are tinted, not just the 6–13 one — the tint marks *paediatric*, and
6–13 and 0–5 are both paediatric. (The 14+ row stays on the box's `#EFEFEF` base.) Box
border is black ≈ 4 px (2.9 pt), corner radius ≈ 10 px, with a grey drop shadow.

This is **the same pink as everything else paediatric** — not a severity colour, not a
"highlight this row" colour. `#FFC0CB` used as a partial row-run tint inside a box also
appears at:

- **p.30** — the line "• Croup in Peds" inside the white "Reactive" branch box is tinted
  `#FFC0CB` (sampled at `60,505–290,535`). A *single line* of a bulleted list inside a
  flow node.
- **p.100** — the step "- Peds: 2nd intercostal midclavicular" tinted `#FFC0CB`, and the
  step below it "- Consider Finger Thoracostomy … cleared for CC" tinted `#D9D2E9`, both
  inside a numbered procedure list.
- **p.78** — a per-tile vertical population tab: `#EFEFEF` reading "Adult" on the
  "Bougie Cric" tile, `#FFC0CB` reading "Peds" on the "Needle Cric" tile directly below.
  Same on **p.30** ("Adult" on the Nitro tile).

> **F-19 · KEEP.** The app has no equivalent of the *partial* row tint. `RowSeverity`
> tints a whole table row; there is no "tint the paediatric row(s) of this box" and no
> per-tile Adult/Peds tab. The procedure card gets closest (`!` → `_highlightBg`,
> `^` → `_ccHighlightBg` — see F-25) but only inside `ProcedureBlock`.

### 3.3 Zebra inside a flow node — striping is **NODE-DERIVED**

**pp.8, 10, 12, 14, 82, 92.** The entry stadium's bulleted body alternates between the
node fill `#CFE2F3` and a paler tint of the same hue `#E5EFF7` (229,239,247).
Verified p.8 `col280`: `#CFE2F3` (y100-117) → `#E5EFF7` (120-148) → `#CFE2F3` (151-180)
→ `#E5EFF7` (184-198). Row pitch ≈ 30 px.

> **F-20 · ADAPT.** Here the zebra genuinely *is* derived from its container's colour —
> which is what the app's `zebraBg()` does (`theme.header @ 6 %`). The app's rule is
> right for this case and wrong for §3.1. The distinction the app is missing is
> *whose* colour: a node's own fill (correct here) versus the page's chapter accent
> (what `zebraBg` actually uses).

### 3.4 Peds Reference zebra — striping is **BROSELOW-BAND-DERIVED**

pp.145–161. Each page is one Broselow tape band and the whole page is tinted from it.
The dense drug tables alternate two very pale tints of the band colour:

| Pages | Band | Band hex | Zebra A | Zebra B |
| --- | --- | --- | --- | --- |
| 145–146 | GREY | `#555555` | `#E7E7E7` | `#F5F5F5` |
| 147 | PINK | `#DA5798` | `#F4E7ED` | `#FAF5F8` |
| 148 | RED | `#CC0000` | `#F2DEDE` | `#FAF2F2` |
| 149 | PURPLE | `#674EA7` | `#E9E6EF` | `#F6F5F8` |
| 150 | YELLOW | `#F1C232` | `#F6F1E3` | `#FBF9F4` |
| 151–152 | WHITE | `#F3F3F3` | `#F6F6F6` | `#FBFBFB` |
| 153–154 | BLUE | `#1155CC` | `#E0E7F2` | `#F2F5FA` |
| 155–156 | ORANGE | `#E69138` | `#F5EDE4` | `#FBF7F4` |
| 157–161 | GREEN | `#38761D` | `#E4EAE1` | `#F4F6F3` |

Zebra A is roughly the band at 8 % over white, zebra B at ~3 %.

> **F-21 · ADAPT — and note the app deliberately does not reproduce these pages.**
> `wvems_2026_144.yaml:2` covers **page 144 only**; its own note at line 260 records that
> the Handtevy Peds Reference (pp.145–161) is proprietary and is "deliberately NOT
> reproduced" — it is regenerated as age-banded tables instead. So there is no
> band-page-per-Broselow-colour to get wrong today. What *is* worth carrying across when
> those regenerated bands land: **the band colour should be a topic-level
> `palette: {accent: …}` override, not the one Peds-Reference chapter accent
> `0xFFAD1457`.** The Broselow colour is the lookup key ("get me the pink kid's card");
> one accent for every band would remove the only thing distinguishing p.147 from p.157.
> The palette cascade already supports this; the six `zebra: true` tables in
> `wvems_2026_144.yaml` currently stripe in `theme.header @ 6 %`, which is correct for a
> single combined page.

### 3.5 What does NOT stripe

- **Drug Reference cards (pp.118–143)** are zone-coloured, not striped (§5.1).
- **Ordinary protocol prose (odd pages)** has no striping at all.
- **The index (pp.162–165)** is flat `#EFEFEF` with `#999999` rules — no striping,
  no chroma anywhere. (Confirmed: `chrome_probe.tsv` rows 162–165, and the census finds
  zero chroma-bearing target colours on those pages.)

### 3.6 Column tint

**Print uses no per-column tint anywhere in the 166 pages.** Every fill found is either a
whole-row band, a partial-row run, or a zone within a card. The app's `column_tint`
support (`topic.dart:1581`, `table_block_view.dart:368-372`) is real and is used — but
only by the ProtocolBook and WHO IMCI books (`pb_063_sam_assessment.yaml`,
`who_a5_*.yaml`); **zero WVEMS topics use it**. Nothing to port. **DROP** (for WVEMS).

---
## 4. Banded regions and boxed callouts

### 4.1 The two content bands

| Band | Fill | Rule / bracket | Title | Pages |
| --- | --- | --- | --- | --- |
| Paediatric | `#FFC0CB` | `#DA5798`, 4 px (2.9 pt), full `[` bracket with top and bottom arms | **black** | 78 |
| Critical Care | `#D9D2E9` | **none** | **none** — it is a bare tinted run | 54 |

- The peds band is a *section*: on every odd protocol page 3–95 there is a "Pediatrics"
  section whose bracket is `#DA5798` and whose body is filled `#FFC0CB` from just below
  the heading to the bottom arm. Verified p.11 `col25`: `#DA5798` arm at y1015-1018,
  `#FFC0CB` fill y1019-1089, `#DA5798` arm at y1090-1093. Same on p.71 (y1131-1209).
  The fill runs the full text width (verified p.71 `row1170`, x6→x830).
- The CC band is *not* a section. p.11 `row370` and `row880`: the `#D9D2E9` fill starts at
  x = 10, immediately right of the enclosing section's `#666666` bracket, and continues to
  the right margin. It has no bracket and no heading — it is one or more consecutive
  *lines* of somebody else's bulleted list, tinted. Same construction on pp.3, 4, 100.
- Both bands also occur as *sub-lobes of a flow node*: **p.8 / p.82** the blue entry
  stadium has a lavender "Or MAP" lobe attached to its right, fill `#D9D2E9`, striped with
  a paler `#ECE4FF` — the same node-fill + paler-tint zebra rule as §3.3.
- Both bands also occur as *single tinted lines inside a numbered list* — p.100 steps
  under "Pleural Decompress" (`#FFC0CB` for the peds step, `#D9D2E9` for the CC step),
  p.25 ("- For peds, give 5 mg/kg …", `#FFC0CB`).

> **F-22 · ADAPT.** The app models both as `BandCalloutBlock` with an optional title, which
> covers the section form and the bare-run form. It does **not** cover the *node sub-lobe*
> form or the *single line inside a step list* form outside `ProcedureBlock`. 45 `band: peds`
> + 8 `band: critical_care` blocks exist in the WVEMS topics — that is well short of the
> 78 + 54 pages that carry the tints in print, so a lot of these are currently rendered
> flat.

### 4.2 Boxed callouts

| Kind | Fill | Border | Radius | Pages / examples |
| --- | --- | --- | --- | --- |
| **"Concept" box** (firm/always-true) | `#EFEFEF` | **black**, ~4 px (2.9 pt), solid | ~10 px, with a grey drop shadow | p.2 legend, p.25 "Compressions" / "Obvious Death", p.71 "ABLS rate:", p.112 ×3 |
| **Dashed conditional card** | `#FDFAFA` (near-white, distinct from the page wash) | `#999999`, ~4 px, **dashed** (≈ 7 px dash / 5 px gap) | ~10 px | p.71 "If Major Intervention … Call a TRAUMA Alert" |
| **Dashed conditional line** | **none** — the page wash or the underlying band shows through | `#999999`, ~3 px, dashed | ~6 px | p.25 (two lines), p.43 (drawn *over* the pink peds band) |
| **WARNING octagon** | `#CC0000` | black ~3 px | — | pp.2, 40, 42, 46, 69, 70, 72, 74, 78, 144, 148 |
| **"Important Note" trapezoid** | `#674EA7` | black ~3 px | — | pp.2, 18, 26, 28, 32, 36, 38, 40, 44, 46, 48, 50, 54, 56, 58, 66, 70, 74, 86, 88, 92, 106, 113, 116, 144, 149 |
| **Critical-Care outline box** (Peds Reference only) | interior shifts ~4 points toward violet (`#F6EDF8` vs `#FAF5F8`) | `#9900FF`, 4 px, solid | square | pp.145–161 |
| **Severity-tinted branch box** | `#F4CCCC` | black | — | p.68 "Major Hyper" (only instance in the book) |

**Findings**

- **F-23 · The app's "callout" and "note" roles are amber; print has no amber callout at
  all.** `alert` `0xFFF6A609`, `alert_fill` `0xFFFFF6D6`, `alert_text` `0xFFB9770A`,
  `note_fill` `0xFFFFFDE7`, `note_border` `0xFFF9A825`. Measured against every colour in
  `colour_inventory.tsv`, the three *saturated* ambers have no counterpart anywhere in the
  166 pages — `alert` is 36 points (max-channel) from the nearest colour in the book,
  `alert_text` 29, `note_border` 23. The two pale fills do land near something —
  `alert_fill` is 10 points from the drug-card **Caution** zone `#FFF2CC` and `note_fill`
  8 points from an anti-aliased blend on p.2 — but `#FFF2CC` is a different role (§5.1),
  not a callout. The only ambers in the book are the `#FFD966` EMT badge, the
  `#FFF2CC`/`#FFE599` drug-card Caution zone, the `#E69138` front-matter accent and the
  `#F1C232` Broselow YELLOW band.
  `prose_block_view.dart:74-97` renders every `callout: true` prose block as an amber card
  with an amber pill title and a dashed amber border when `dashed: true`. The print's
  equivalent is a **neutral** card: `#EFEFEF` + black solid, or `#FDFAFA` + `#999999`
  dashed. **ADAPT — repoint the callout roles at the print's neutrals.** The amber is
  doing the job of shouting, which the print reserves for the red octagon; using it for
  ordinary conditional boxes devalues the octagon.
- **F-24 · The dashed border colour should be `#999999`, not the accent/alert colour.**
  79 pages carry `#999999` dashes. `prose_block_view.dart:96` passes `theme.alert`.
  `procedure_card_block_view.dart:29` hardcodes `Colors.black45` — closer, but still not
  the print value and still hardcoded.
- **F-25 · Solid boxes in print have a *black* border, not an accent border.** The app's
  boxed prose uses `theme.nodeBorder.withValues(alpha: 0.6)` (`prose_block_view.dart:48`)
  = the chapter accent at 60 %, and the procedure card uses `theme.header`
  (`procedure_card_block_view.dart:45`, `:57`). Print: black on every one of them, on
  every chapter. **KEEP the print value.**
- **F-26 · Both warning shapes are close but not exact.** Octagon print `#CC0000` vs app
  `0xFFD32F2F`; trapezoid print `#674EA7` vs app `0xFF7E57C2`. Both app values are
  Material-palette picks. **ADAPT to the print values** — they are the same swatches the
  Broselow RED and PURPLE bands use, so matching them keeps the book internally coherent.
- **F-27 · The `#9900FF` Critical-Care outline box (Peds Reference) has no app
  equivalent.** It is the only place in the book where CC restriction is signalled by a
  *border* rather than a lavender fill, and it groups a contiguous run of drug rows.
  **ADAPT** — the app could reuse `cc_band_fill` on those rows instead, but the print's
  grouping (one box round 13 rows) carries information a per-row tint would not.
- **F-28 · Drop shadows.** Every solid box, every flow node and every page-number circle
  in print carries a soft grey drop shadow (sampled as the `#B3B3B3`…`#C2C2C2` runs
  adjacent to box borders throughout, e.g. p.71 `col100` y421-424). This is skeuomorphic
  print styling. **DROP** — it costs GPU and adds nothing on a phone; the app already
  omits it.

---

## 5. Appendices — do they differ?

Sampled in full; they do differ, and each has its own system.

### 5.1 Drug Reference, pp.118–143 (teal, `#76A5AF`)

Two drug cards per page. Each card is four coloured zones plus a photo panel:

| Zone | Body fill | Left spine strip | Meaning |
| --- | --- | --- | --- |
| Card header | `#3A5D64` (dark teal), white text | — | drug name / generic name |
| **Use** | `#D9EAD3` | `#B6D7A8` | indications + adult/peds dosing |
| **Caution** | `#FFF2CC` | `#FFE599` | contraindications, pregnancy category |
| **Notes** (ordinary drug) | `#D0E0E3` | `#A4C2F4` | protocol links, pharmacology, reference URL |
| **Notes** (Critical-Care drug) | **`#D9D2E9`** | **`#B4A7D6`** | same, but the drug is CC-restricted |

Verified p.124 (Benadryl, Bicarb — cyan Notes) and pp.119, 129, 132, 134, 135, 137, 139,
140 (lavender Notes). p.139 (Propofol) confirms that **only the Notes zone changes** —
Use stays green and Caution stays yellow on a CC drug.

The zone colours are a green/amber/blue "safe / careful / reference" triad, and the
lavender substitution reuses the book's Critical-Care colour exactly (`#D9D2E9`).

**What the app does** — `lib/widgets/blocks/drug_card_block_view.dart:24-27`:

```dart
static const _header    = Color(0xFF3E5C6B);   // print #3A5D64
static const _useBg     = Color(0xFFCDE9CD);   // print #D9EAD3
static const _cautionBg = Color(0xFFFBE9BE);   // print #FFF2CC
static const _notesBg   = Color(0xFFE3D7F1);   // print #D0E0E3  ← wrong hue
```

> **F-29 · The app's Notes zone is purple for *every* drug.** Print uses pale cyan
> `#D0E0E3` for ordinary drugs and reserves lavender `#D9D2E9` for Critical-Care drugs.
> The app hardcodes `0xFFE3D7F1` (a near-miss of `cc_band_fill`) for all of them, so the
> CC signal is destroyed and every drug reads as CC. **KEEP the print system**: cyan
> Notes by default, lavender Notes when the drug is CC-restricted.
> **F-30 · All four drug-card fills are hardcoded and none is a palette role.** They also
> all differ from print by 8–20 points per channel. **ADAPT: promote to roles**
> (`drug_card_header`, `drug_use_fill`, `drug_caution_fill`, `drug_notes_fill`,
> `drug_notes_cc_fill`) **with the print values as defaults.**
> **F-31 · The app has no spine strips.** Print draws a darker 6 px strip down the left of
> each zone carrying the rotated zone label. **ADAPT** — the label is another stream's
> business, but the darker strip is a cheap, useful edge cue.

### 5.2 Procedures + Policies, pp.96–117 (orange, `#E69138`)

- Page wash `#FDF8F2`; **both** a top bar and a bottom bar on every page (unlike the
  protocol chapters' alternating single bar).
- Procedure cards are ordinary `#666666`-bracketed sections with a header tile at the top
  right: provider badge + white title box, black border.
- Inline `#FFC0CB` and `#D9D2E9` line tints inside numbered step lists (p.100).
- `#EFEFEF` Concept boxes with black borders (p.112 ×3).
- Otherwise identical to the protocol pages' system. **No new colours.**

### 5.3 Peds Reference, pp.144–161 (Broselow bands)

Covered in §3.4. Distinct system: page-level Broselow colour (9 bands), band-derived
zebra, `#9900FF` CC outline boxes, `#FFC0CB` bottom bar on every page. Page wash
`#FFFBFB`. **The app deliberately does not reproduce pp.145–161** — the Handtevy source
is proprietary and `wvems_2026_144.yaml:260` records the decision to regenerate rather
than reproduce. Everything in §3.4 is therefore forward-looking guidance for the
regenerated bands, not a description of a current defect.

### 5.4 Index / About, pp.162–165 (`#999999` on `#EFEFEF`)

**Entirely monochrome.** The census finds zero chroma-bearing colours on these four
pages. Nothing to port. **DROP.**

### 5.5 Covers, pp.1 and 166

Cover artwork (`#B7CEF6`, `#FF6E66`, `#064A89`, `#DD7F6C`, `#341B74`). Not a system.
**DROP** — the app has `assets/books/wvems/cover.png`.

### 5.6 Photographic / illustrative colour

Drug-vial photographs (pp.118–143), anatomical illustrations (p.88 lead placement,
p.108 "Safe Triangle", p.71 BSA figures). Skin tones `#DDA981`, `#F6DACE` etc. are image
content, not palette. **DROP** from the colour system; they belong to the image stream.

---
## 6. CHAPTER-derived vs SEMANTIC — the classification

This is the distinction that already caused one real bug (the app tinting "Pediatrics"
with the chapter accent, so it rendered salmon on Trauma and green on Medical where print
is pink on both). Here is the complete classification, evidence-backed.

### 6.1 Chapter-derived in print (only five things)

| Element | Evidence |
| --- | --- |
| Page-number circles (both) | `chrome_probe.tsv` — accent on every page of every chapter |
| Title bar (top on verso / bottom on recto) | ditto |
| Outer-edge rail | ditto |
| Page wash | ditto — `#F5F8FD` / `#F5F9F3` / `#FCF6F5` / `#F2F0F6` / `#FDF8F2` / `#F6F9F9` / `#FFFBFB` |
| Broselow band colour (pp.145–161 only) | `pedsref_bands.tsv` — and here the "chapter" *is* the clinical datum |

**Nothing else in the book changes colour with the chapter.** Verified by cross-chapter
census: `flow_entry_blue` appears on Universal, Medical, Trauma *and* Critical Care pages;
so do `flow_convergence_green`, `flow_decision_salmon`, `peds_pink`, `cc_lavender`,
`bracket_666`, all four badge colours, and both zebra pairs.

### 6.2 Semantic in print but CHAPTER-derived in the app

These are the live bugs, in descending severity:

| # | Element | Print | App | Where |
| --- | --- | --- | --- | --- |
| B-1 | Dose-table zebra | population (grey / pink) | `theme.nodeFill` = accent | `dose_table.dart:38-40` |
| B-2 | Section bracket | `#666666` fixed | `theme.header` = accent | `prose_block_view.dart:155` |
| B-3 | Section title | black | `theme.header` = accent | `prose_block_view.dart:160` |
| B-4 | Solid-box border | black | `theme.nodeBorder` @ 60 % = accent | `prose_block_view.dart:48` |
| B-5 | Procedure-card border + header rule | black | `theme.header` = accent | `procedure_card_block_view.dart:45,57` |
| B-6 | Flow-node border | black | `theme.nodeBorder` = accent | `flow_node.dart:64`, `algorithm_flowchart_view.dart:80,467` |
| B-7 | Non-stadium flow-node fill | white | `theme.nodeFill` = accent tint | `flow_node.dart:53` |
| B-8 | Cascade / algorithm node fills | **unknown** — WVEMS uses only `severity` (36), `linear` (6) and `differential` (4) variants, so `cascade` has no printed counterpart to compare against | `theme.nodeFill`, `theme.branchAccent @ 15 %` | `cascade_flowchart_view.dart:136,174,277` |
| B-9 | Table header row | black text on tint (no bar) | solid `theme.header` bar, white text | `table_block_view.dart:58,70,609,728` |
| B-10 | Table zebra | population (§3.1) or node-derived (§3.3) | `theme.header @ 6 %` | `table_block_view.dart:378` |
| B-11 | In-cell magnitude bar | not present in print | `theme.header @ 16 %` | `table_block_view.dart:405` |
| B-12 | Peds-Reference zebra | Broselow-band-derived | one chapter accent for all 17 band pages | `book.yaml` "Peds Reference" + `wvems_2026_144.yaml` |

> **F-32.** B-1, B-2, B-12 are the ones that lose clinical information. B-4 to B-8 are
> aesthetic: the app's accent-tinted flow chrome is a coherent look, but it means the
> print's *only* two coloured borders (`#9900FF` CC boxes, `#DA5798` peds bracket) no
> longer stand out, because everything has a coloured border. **ADAPT** — pick one:
> either go black-and-neutral like the print and let colour mean something, or keep the
> accent chrome and find a stronger cue for the semantic ones.

### 6.3 Semantic in print and correctly semantic in the app

`flow_entry` ✓, `flow_convergence` ✓, `flow_decision` ✓ (hue drift, F-9),
`provider_*` ✓ (value drift, F-12), `peds_band_rule` ✓ (exact),
`peds_band_fill` / `cc_band_fill` ✓ (value drift, F-8) — the *structure* is right in all
of these; only the values need repointing.

---

## 7. Colour the app renders monochrome, and colour the app invents

### 7.1 Print has colour, app does not

| # | Thing | Print | App |
| --- | --- | --- | --- |
| M-1 | Per-chapter page wash | 3 % accent over white, all 165 content pages | `Colors.white` (`topic_frame.dart:249,339`) |
| M-2 | Paediatric dose rows | `#FFDCE2` / `#FFC0CB` stripes | chapter tint, same as adult |
| M-3 | Per-tile Adult/Peds side tab | `#EFEFEF` / `#FFC0CB` (pp.30, 78) | not rendered |
| M-4 | Paediatric row tint inside a box | `#FFC0CB` on the peds rows only (p.71) | not rendered |
| M-5 | Single peds / CC line inside a list | `#FFC0CB` / `#D9D2E9` (pp.25, 30, 100) | only inside `ProcedureBlock` (`!` / `^` prefixes) |
| M-6 | Node-fill zebra inside a stadium | `#CFE2F3`/`#E5EFF7`, `#D9D2E9`/`#ECE4FF` (pp.8, 10, 12, 14, 82, 92) | not rendered |
| M-7 | Lavender CC sub-lobe on an entry node | `#D9D2E9` (pp.8, 82) | not rendered |
| M-8 | Critical-Care Paramedic gradient badge | `#8E61FF`→`#FED3EA`, 12 pages | flat `provider_paramedic` |
| M-9 | Drug-card CC Notes zone | `#D9D2E9` vs `#D0E0E3` | one purple for all |
| M-10 | Drug-card zone spine strips | `#B6D7A8` / `#FFE599` / `#A4C2F4` / `#B4A7D6` | not rendered |
| M-11 | `#9900FF` CC outline boxes in Peds Reference | 17 pages | not rendered |
| M-12 | Broselow band colour per page | 9 distinct band colours | one accent |
| M-13 | Severity-tinted branch box | `#F4CCCC` (p.68) | `RowSeverity` exists for tables, not for branch boxes |

### 7.2 App has colour, print does not

| # | Thing | App | Print |
| --- | --- | --- | --- |
| A-1 | Amber attention callout | `alert` `#F6A609`, `alert_fill` `#FFF6D6`, `alert_text` `#B9770A` | `#EFEFEF` + black, or `#FDFAFA` + `#999999` dashed |
| A-2 | Amber note/inset | `note_fill` `#FFFDE7`, `note_border` `#F9A825`, `note_text` `#5D4037` | no equivalent — nothing in the book uses these |
| A-3 | Accent-tinted flow-node fills and borders | `nodeFill` / `nodeBorder` | white fills, black borders |
| A-4 | Accent table header bars | `theme.header`, white text | no filled header bar anywhere except the drug-card `#3A5D64` |
| A-5 | Accent-tinted section brackets and titles | `theme.header` | `#666666` bracket, black title |
| A-6 | In-cell magnitude bars | `theme.header @ 16 %` | not present |
| A-7 | Purple CC-link fill | `cc_link_fill` `#F1E7F6` + purple border | `#D9D2E9` + **black** border (verified p.30 `row1122`) |
| A-8 | Purple CC band bracket | `cc_band_rule` `#6A1B9A` | no bracket (verified p.11) |
| A-9 | Three-level severity palette | mild green / moderate amber / severe pink tiles | only `#F4CCCC` on p.68 — the book has no three-level severity scale |

> **F-33.** A-1/A-2 are the biggest inventions: five palette roles' worth of amber that
> nothing in the source uses. A-9 is inherited from the WHO IMCI book and is legitimate
> *there*; it just has no WVEMS content behind it (0 WVEMS topics set a row `severity:`).

---

## 8. Hardcoded colours — every use site that bypasses the palette

`palette.dart`'s doc comment claims "nothing is hardcoded at a use site". That is not true.

| File:line | Constant | Should be |
| --- | --- | --- |
| `blocks/procedure_card_block_view.dart:26` | `_headerBg = 0xFFF3EFE6` | a role; print's procedure-card header tile is pure **white** with a black 3 px border (verified p.100 `col700` y143-172 = `#FFFFFF`, `row130`), not a cream |
| `blocks/procedure_card_block_view.dart:27` | `_highlightBg = 0xFFFBD5DE` | **`peds_band_fill`** (already flagged) |
| `blocks/procedure_card_block_view.dart:28` | `_ccHighlightBg = 0xFFE3DCF2` | **`cc_band_fill`** (already flagged) |
| `blocks/procedure_card_block_view.dart:29` | `_dashColor = Colors.black45` | a `dash_rule` role; print `#999999` |
| `blocks/drug_card_block_view.dart:24` | `_header = 0xFF3E5C6B` | role; print `#3A5D64` |
| `blocks/drug_card_block_view.dart:25` | `_useBg = 0xFFCDE9CD` | role; print `#D9EAD3` |
| `blocks/drug_card_block_view.dart:26` | `_cautionBg = 0xFFFBE9BE` | role; print `#FFF2CC` |
| `blocks/drug_card_block_view.dart:27` | `_notesBg = 0xFFE3D7F1` | **two** roles; print `#D0E0E3` ordinary / `#D9D2E9` CC |
| `blocks/drug_card_block_view.dart:147` | `BorderSide(color: Color(0xFF3E5C6B))` | same role as `_header` |
| `blocks/score_block_view.dart:390` | `FormulaSeverity.warn => Color(0xFFB26A00)` | role |
| `blocks/formula_block_view.dart:267` | `FormulaSeverity.warn => Color(0xFFB26A00)` | role (duplicated) |
| `blocks/image_block_view.dart:79,80,90` | `0xFFF5F5F5`, `0xFFBDBDBD`, `0xFF757575` | placeholder chrome — acceptable as fixed structural greys |
| `flowchart/warning_callouts.dart:16,109` | `_stroke = Colors.black87` | print is pure black; minor, but it is a hardcode |
| `flowchart/branch_column.dart:163,164,230,231,306,307,390` | `Colors.white` fills, `Colors.black87` borders | these happen to match print — but by coincidence, not by role |
| `screens/drug_index_screen.dart:36,38,115,142,385,388,577,627` | `0xFF5981BF`, `0xFFEEF2F9`, `0xFFE3E7EE`, `0xFF55606F`, `0xFFDDE1E8`, `0x11000000`, `0xFFFAFAFB` | app-screen chrome, outside the print's scope — **out of audit scope**, noted for completeness |
| `screens/book_screen.dart:47,314`, `shelf_screen.dart:16`, `topic_frame.dart:452`, `drug_index_screen.dart:67` | `0xFFEFEFEF` | app chrome; coincidentally the print's neutral box fill |
| `screens/shelf_screen.dart:19` | `0xFF1E4E8C` | duplicate of the Universal accent literal |
| `main.dart:31` | `ColorScheme.fromSeed(seedColor: Colors.indigo)` | Material default; never surfaces in topic rendering |

> **F-34 · ADAPT.** Eleven content-bearing hardcodes (the procedure-card four, the
> drug-card five, and the two `0xFFB26A00` duplicates) should become palette roles so a
> book/chapter/topic can re-skin them, which is the whole point of the cascade.

---
## 9. Per-page inventory

Every page, its chapter accent, its page wash (modal background colour, sampled), and
every semantic fill found on it with an approximate pixel area. Pixel areas are exact
matches from `census.tsv`; a fill under 40 px on a page is not listed. The `#DA5798` peds
bracket clears the threshold on **every odd page 3–95** (47 pages) plus pp.110, 144 and
147 — the "Pediatrics" section is a standing section on every text page of every protocol
chapter.

Reading the table: `entry`, `decision`, `converge` = flow-chart shapes; `peds` /
`peds-rule` / `peds-zebra` = paediatric; `CC` = Critical Care; `bracket` = the neutral
grey section bracket; `dash` = dashed conditional outline; `neutral #EFEFEF` doubles as
the Concept-box fill, the EMR badge, the Adult side-tab and the adult zebra light row.

| Page | Chapter | Accent | Page wash | Semantic fills present (approx. px) |
|---|---|---|---|---|
| 1 | Cover | `—` | `#6AA84F` | peds #FFC0CB (4k) · zebra-dk #D9D9D9 (177) |
| 2 | Front matter | `#E69138` | `#FDF8F2` | entry #CFE2F3 (21k) · neutral #EFEFEF (20k) · converge/Use #D9EAD3 (15k) · decision #E6B8AF (10k) · note-trap #674EA7 (10k) · WARNING #CC0000 (9k) · badge-I #6FA8DC (3k) · badge-P #D5A6BD (3k) · badge-E #FFD966 (3k) · badge-A #93C47D (3k) · bracket #666666 (1k) · dash #999999 (1k) |
| 3 | Front matter | `#E69138` | `#FDF8F2` | peds #FFC0CB (70k) · CC #D9D2E9 (68k) · bracket #666666 (4k) · peds-rule #DA5798 (760) |
| 4 | Universal | `#6D9EEB` | `#F5F8FD` | entry #CFE2F3 (36k) · converge/Use #D9EAD3 (35k) · neutral #EFEFEF (16k) · decision #E6B8AF (13k) · CC #D9D2E9 (6k) · badge-E #FFD966 (3k) · badge-A #93C47D (3k) · dash #999999 (52) · zebra-dk #D9D9D9 (45) |
| 5 | Universal | `#6D9EEB` | `#F5F8FD` | peds #FFC0CB (70k) · neutral #EFEFEF (62k) · CC #D9D2E9 (31k) · bracket #666666 (3k) · dash #999999 (1k) · peds-rule #DA5798 (702) · badge-A #93C47D (649) |
| 6 | Universal | `#6D9EEB` | `#F5F8FD` | entry #CFE2F3 (38k) · converge/Use #D9EAD3 (34k) · neutral #EFEFEF (16k) · decision #E6B8AF (13k) · CC #D9D2E9 (6k) · badge-I #6FA8DC (3k) · badge-E #FFD966 (3k) · zebra-dk #D9D9D9 (60) |
| 7 | Universal | `#6D9EEB` | `#F5F8FD` | peds #FFC0CB (104k) · CC #D9D2E9 (28k) · neutral #EFEFEF (27k) · bracket #666666 (4k) · peds-rule #DA5798 (834) |
| 8 | Universal | `#6D9EEB` | `#F5F8FD` | neutral #EFEFEF (41k) · converge/Use #D9EAD3 (29k) · zebra-dk #D9D9D9 (21k) · entry #CFE2F3 (17k) · entry-zebra #E5EFF7 (15k) · decision #E6B8AF (13k) · CC #D9D2E9 (12k) · badge-E #FFD966 (9k) · badge-A #93C47D (8k) · badge-I #6FA8DC (6k) · bracket #666666 (5k) · dash #999999 (46) |
| 9 | Universal | `#6D9EEB` | `#F5F8FD` | peds #FFC0CB (120k) · neutral #EFEFEF (62k) · CC #D9D2E9 (44k) · bracket #666666 (4k) · peds-rule #DA5798 (866) |
| 10 | Universal | `#6D9EEB` | `#F5F8FD` | converge/Use #D9EAD3 (30k) · entry #CFE2F3 (17k) · entry-zebra #E5EFF7 (14k) · decision #E6B8AF (13k) · CC #D9D2E9 (5k) · neutral #EFEFEF (3k) · badge-A #93C47D (3k) · badge-E #FFD966 (3k) |
| 11 | Universal | `#6D9EEB` | `#F5F8FD` | CC #D9D2E9 (78k) · peds #FFC0CB (52k) · bracket #666666 (4k) · peds-rule #DA5798 (566) |
| 12 | Universal | `#6D9EEB` | `#F5F8FD` | converge/Use #D9EAD3 (30k) · neutral #EFEFEF (21k) · peds-zebra #FFDCE2 (20k) · entry #CFE2F3 (18k) · entry-zebra #E5EFF7 (15k) · decision #E6B8AF (13k) · badge-I #6FA8DC (9k) · badge-E #FFD966 (8k) · badge-A #93C47D (3k) · peds #FFC0CB (2k) · bracket #666666 (1k) · zebra-dk #D9D9D9 (63) |
| 13 | Universal | `#6D9EEB` | `#F5F8FD` | peds #FFC0CB (186k) · neutral #EFEFEF (62k) · bracket #666666 (3k) · peds-rule #DA5798 (1k) · dash #999999 (1k) · badge-I #6FA8DC (800) |
| 14 | Universal | `#6D9EEB` | `#F5F8FD` | neutral #EFEFEF (44k) · zebra-dk #D9D9D9 (43k) · converge/Use #D9EAD3 (31k) · entry #CFE2F3 (18k) · entry-zebra #E5EFF7 (14k) · decision #E6B8AF (13k) · badge-I #6FA8DC (12k) · badge-A #93C47D (8k) · badge-E #FFD966 (8k) · bracket #666666 (6k) · dash #999999 (67) |
| 15 | Universal | `#6D9EEB` | `#F5F8FD` | neutral #EFEFEF (107k) · peds #FFC0CB (75k) · bracket #666666 (4k) · dash #999999 (1k) · badge-I #6FA8DC (800) · peds-rule #DA5798 (566) · zebra-dk #D9D9D9 (48) |
| 16 | Universal | `#6D9EEB` | `#F5F8FD` | neutral #EFEFEF (46k) · entry #CFE2F3 (38k) · converge/Use #D9EAD3 (32k) · zebra-dk #D9D9D9 (22k) · decision #E6B8AF (13k) · CC #D9D2E9 (6k) · badge-E #FFD966 (6k) · bracket #666666 (5k) · badge-A #93C47D (3k) · dash #999999 (40) |
| 17 | Universal | `#6D9EEB` | `#F5F8FD` | peds #FFC0CB (156k) · neutral #EFEFEF (62k) · CC #D9D2E9 (34k) · bracket #666666 (3k) · dash #999999 (1k) · peds-rule #DA5798 (1k) · badge-E #FFD966 (673) · badge-A #93C47D (649) |
| 18 | Universal | `#6D9EEB` | `#F5F8FD` | neutral #EFEFEF (42k) · entry #CFE2F3 (35k) · converge/Use #D9EAD3 (32k) · zebra-dk #D9D9D9 (22k) · decision #E6B8AF (13k) · badge-A #93C47D (6k) · bracket #666666 (5k) · badge-E #FFD966 (5k) · note-trap #674EA7 (5k) · badge-I #6FA8DC (3k) · dash #999999 (41) |
| 19 | Universal | `#6D9EEB` | `#F5F8FD` | neutral #EFEFEF (83k) · peds #FFC0CB (51k) · bracket #666666 (3k) · dash #999999 (1k) · badge-I #6FA8DC (830) · peds-rule #DA5798 (566) · zebra-dk #D9D9D9 (44) |
| 20 | Universal | `#6D9EEB` | `#F5F8FD` | neutral #EFEFEF (64k) · zebra-dk #D9D9D9 (41k) · entry #CFE2F3 (40k) · converge/Use #D9EAD3 (31k) · decision #E6B8AF (13k) · bracket #666666 (9k) · badge-E #FFD966 (8k) · badge-A #93C47D (5k) · badge-I #6FA8DC (3k) · dash #999999 (70) |
| 21 | Universal | `#6D9EEB` | `#F5F8FD` | peds #FFC0CB (51k) · bracket #666666 (4k) · dash #999999 (2k) · badge-E #FFD966 (1k) · badge-A #93C47D (649) · peds-rule #DA5798 (566) |
| 22 | Universal | `#6D9EEB` | `#F5F8FD` | entry #CFE2F3 (40k) · converge/Use #D9EAD3 (32k) · neutral #EFEFEF (25k) · decision #E6B8AF (13k) · badge-E #FFD966 (3k) · bracket #666666 (1k) |
| 23 | Universal | `#6D9EEB` | `#F5F8FD` | peds #FFC0CB (70k) · bracket #666666 (4k) · dash #999999 (1k) · badge-E #FFD966 (673) · badge-A #93C47D (649) · peds-rule #DA5798 (566) |
| 24 | Medical | `#6AA84F` | `#F5F9F3` | entry #CFE2F3 (34k) · neutral #EFEFEF (31k) · converge/Use #D9EAD3 (28k) · peds-zebra #FFDCE2 (23k) · peds #FFC0CB (20k) · zebra-dk #D9D9D9 (18k) · decision #E6B8AF (12k) · badge-I #6FA8DC (7k) · bracket #666666 (1k) · badge-E #FFD966 (673) · dash #999999 (293) |
| 25 | Medical | `#6AA84F` | `#F5F9F3` | peds #FFC0CB (110k) · neutral #EFEFEF (79k) · bracket #666666 (4k) · dash #999999 (2k) · badge-I #6FA8DC (1k) · peds-rule #DA5798 (834) · badge-E #FFD966 (673) |
| 26 | Medical | `#6AA84F` | `#F5F9F3` | entry #CFE2F3 (41k) · converge/Use #D9EAD3 (31k) · neutral #EFEFEF (25k) · note-trap #674EA7 (5k) · CC #D9D2E9 (5k) · badge-I #6FA8DC (3k) · badge-A #93C47D (2k) · badge-E #FFD966 (2k) · bracket #666666 (1k) · zebra-dk #D9D9D9 (49) |
| 27 | Medical | `#6AA84F` | `#F5F9F3` | peds #FFC0CB (70k) · CC #D9D2E9 (26k) · bracket #666666 (3k) · dash #999999 (943) · badge-I #6FA8DC (800) · peds-rule #DA5798 (698) |
| 28 | Medical | `#6AA84F` | `#F5F9F3` | entry #CFE2F3 (38k) · converge/Use #D9EAD3 (30k) · neutral #EFEFEF (29k) · zebra-dk #D9D9D9 (22k) · badge-E #FFD966 (14k) · decision #E6B8AF (13k) · CC #D9D2E9 (6k) · badge-A #93C47D (5k) · note-trap #674EA7 (5k) · bracket #666666 (2k) |
| 29 | Medical | `#6AA84F` | `#F5F9F3` | peds #FFC0CB (70k) · neutral #EFEFEF (43k) · CC #D9D2E9 (25k) · bracket #666666 (4k) · dash #999999 (1k) · peds-rule #DA5798 (698) |
| 30 | Medical | `#6AA84F` | `#F5F9F3` | neutral #EFEFEF (71k) · zebra-dk #D9D9D9 (44k) · entry #CFE2F3 (38k) · converge/Use #D9EAD3 (30k) · decision #E6B8AF (13k) · bracket #666666 (9k) · badge-A #93C47D (8k) · peds #FFC0CB (7k) · badge-E #FFD966 (5k) · CC #D9D2E9 (5k) · dash #999999 (67) |
| 31 | Medical | `#6AA84F` | `#F5F9F3` | peds #FFC0CB (151k) · CC #D9D2E9 (26k) · bracket #666666 (4k) · peds-rule #DA5798 (1k) · dash #999999 (971) · badge-I #6FA8DC (800) |
| 32 | Medical | `#6AA84F` | `#F5F9F3` | neutral #EFEFEF (63k) · zebra-dk #D9D9D9 (44k) · entry #CFE2F3 (37k) · converge/Use #D9EAD3 (33k) · badge-E #FFD966 (20k) · decision #E6B8AF (13k) · bracket #666666 (9k) · note-trap #674EA7 (4k) · badge-A #93C47D (3k) · dash #999999 (75) |
| 33 | Medical | `#6AA84F` | `#F5F9F3` | peds #FFC0CB (75k) · neutral #EFEFEF (62k) · bracket #666666 (4k) · dash #999999 (4k) · badge-E #FFD966 (1k) · badge-I #6FA8DC (800) · badge-A #93C47D (653) · peds-rule #DA5798 (566) |
| 34 | Medical | `#6AA84F` | `#F5F9F3` | entry #CFE2F3 (39k) · converge/Use #D9EAD3 (31k) · decision #E6B8AF (13k) · CC #D9D2E9 (6k) · neutral #EFEFEF (238) · zebra-dk #D9D9D9 (65) · dash #999999 (57) · bracket #666666 (42) |
| 35 | Medical | `#6AA84F` | `#F5F9F3` | peds #FFC0CB (74k) · CC #D9D2E9 (26k) · bracket #666666 (3k) · peds-rule #DA5798 (702) |
| 36 | Medical | `#6AA84F` | `#F5F9F3` | converge/Use #D9EAD3 (254k) · entry #CFE2F3 (36k) · decision #E6B8AF (13k) · CC #D9D2E9 (6k) · note-trap #674EA7 (4k) · neutral #EFEFEF (3k) · badge-A #93C47D (3k) · badge-E #FFD966 (2k) |
| 37 | Medical | `#6AA84F` | `#F5F9F3` | peds #FFC0CB (98k) · neutral #EFEFEF (67k) · zebra-dk #D9D9D9 (33k) · CC #D9D2E9 (23k) · bracket #666666 (4k) · peds-rule #DA5798 (866) |
| 38 | Medical | `#6AA84F` | `#F5F9F3` | neutral #EFEFEF (45k) · zebra-dk #D9D9D9 (44k) · entry #CFE2F3 (38k) · converge/Use #D9EAD3 (32k) · decision #E6B8AF (13k) · badge-E #FFD966 (11k) · bracket #666666 (5k) · badge-A #93C47D (5k) · note-trap #674EA7 (4k) · dash #999999 (51) |
| 39 | Medical | `#6AA84F` | `#F5F9F3` | peds #FFC0CB (69k) · bracket #666666 (5k) · dash #999999 (1k) · peds-rule #DA5798 (702) · badge-E #FFD966 (673) |
| 40 | Medical | `#6AA84F` | `#F5F9F3` | entry #CFE2F3 (35k) · converge/Use #D9EAD3 (30k) · neutral #EFEFEF (28k) · zebra-dk #D9D9D9 (21k) · decision #E6B8AF (13k) · WARNING #CC0000 (10k) · badge-A #93C47D (6k) · note-trap #674EA7 (4k) · badge-E #FFD966 (3k) · bracket #666666 (2k) · dash #999999 (42) |
| 41 | Medical | `#6AA84F` | `#F5F9F3` | peds #FFC0CB (81k) · bracket #666666 (4k) · dash #999999 (1k) · neutral #EFEFEF (900) · peds-rule #DA5798 (802) · badge-A #93C47D (649) |
| 42 | Medical | `#6AA84F` | `#F5F9F3` | neutral #EFEFEF (44k) · entry #CFE2F3 (39k) · converge/Use #D9EAD3 (30k) · zebra-dk #D9D9D9 (21k) · decision #E6B8AF (13k) · badge-A #93C47D (9k) · bracket #666666 (5k) · CC #D9D2E9 (5k) · WARNING #CC0000 (4k) · badge-I #6FA8DC (3k) · dash #999999 (53) |
| 43 | Medical | `#6AA84F` | `#F5F9F3` | peds #FFC0CB (126k) · CC #D9D2E9 (21k) · bracket #666666 (4k) · peds-rule #DA5798 (1k) · dash #999999 (1k) · badge-A #93C47D (649) |
| 44 | Medical | `#6AA84F` | `#F5F9F3` | entry #CFE2F3 (38k) · converge/Use #D9EAD3 (29k) · neutral #EFEFEF (13k) · note-trap #674EA7 (5k) · badge-A #93C47D (3k) · badge-E #FFD966 (2k) |
| 45 | Medical | `#6AA84F` | `#F5F9F3` | neutral #EFEFEF (128k) · peds #FFC0CB (51k) · bracket #666666 (3k) · dash #999999 (1k) · peds-rule #DA5798 (566) |
| 46 | Medical | `#6AA84F` | `#F5F9F3` | entry #CFE2F3 (37k) · converge/Use #D9EAD3 (32k) · neutral #EFEFEF (27k) · zebra-dk #D9D9D9 (23k) · decision #E6B8AF (13k) · badge-I #6FA8DC (9k) · WARNING #CC0000 (4k) · note-trap #674EA7 (4k) · bracket #666666 (2k) · dash #999999 (42) |
| 47 | Medical | `#6AA84F` | `#F5F9F3` | peds #FFC0CB (66k) · bracket #666666 (4k) · dash #999999 (2k) · badge-I #6FA8DC (1k) · peds-rule #DA5798 (702) |
| 48 | Medical | `#6AA84F` | `#F5F9F3` | entry #CFE2F3 (35k) · converge/Use #D9EAD3 (31k) · neutral #EFEFEF (31k) · decision #E6B8AF (13k) · note-trap #674EA7 (10k) · badge-A #93C47D (9k) · badge-E #FFD966 (8k) · CC #D9D2E9 (5k) · bracket #666666 (1k) · zebra-dk #D9D9D9 (96) · dash #999999 (55) |
| 49 | Medical | `#6AA84F` | `#F5F9F3` | peds #FFC0CB (52k) · CC #D9D2E9 (22k) · bracket #666666 (4k) · dash #999999 (736) · badge-A #93C47D (649) · peds-rule #DA5798 (566) |
| 50 | Medical | `#6AA84F` | `#F5F9F3` | entry #CFE2F3 (39k) · converge/Use #D9EAD3 (32k) · neutral #EFEFEF (29k) · peds-zebra #FFDCE2 (21k) · decision #E6B8AF (13k) · note-trap #674EA7 (4k) · badge-I #6FA8DC (3k) · peds #FFC0CB (2k) · zebra-dk #D9D9D9 (70) · dash #999999 (43) |
| 51 | Medical | `#6AA84F` | `#F5F9F3` | peds #FFC0CB (164k) · peds-zebra #FFDCE2 (31k) · neutral #EFEFEF (27k) · peds-rule #DA5798 (3k) · badge-I #6FA8DC (800) · dash #999999 (774) |
| 52 | Trauma | `#DD7E6B` | `#FCF6F5` | neutral #EFEFEF (49k) · entry #CFE2F3 (35k) · converge/Use #D9EAD3 (34k) · zebra-dk #D9D9D9 (24k) · decision #E6B8AF (12k) · badge-I #6FA8DC (9k) · bracket #666666 (5k) · badge-A #93C47D (3k) · dash #999999 (303) |
| 53 | Trauma | `#DD7E6B` | `#FCF6F5` | neutral #EFEFEF (103k) · peds #FFC0CB (51k) · bracket #666666 (4k) · dash #999999 (1k) · peds-rule #DA5798 (566) · zebra-dk #D9D9D9 (54) |
| 54 | Trauma | `#DD7E6B` | `#FCF6F5` | entry #CFE2F3 (41k) · converge/Use #D9EAD3 (31k) · neutral #EFEFEF (25k) · badge-I #6FA8DC (6k) · badge-E #FFD966 (5k) · note-trap #674EA7 (5k) · CC #D9D2E9 (5k) · badge-A #93C47D (2k) · bracket #666666 (1k) · zebra-dk #D9D9D9 (58) |
| 55 | Trauma | `#DD7E6B` | `#FCF6F5` | neutral #EFEFEF (62k) · peds #FFC0CB (51k) · CC #D9D2E9 (32k) · bracket #666666 (3k) · dash #999999 (1k) · peds-rule #DA5798 (566) |
| 56 | Trauma | `#DD7E6B` | `#FCF6F5` | entry #CFE2F3 (38k) · converge/Use #D9EAD3 (32k) · neutral #EFEFEF (28k) · zebra-dk #D9D9D9 (22k) · decision #E6B8AF (13k) · CC #D9D2E9 (6k) · badge-A #93C47D (5k) · note-trap #674EA7 (5k) · badge-I #6FA8DC (3k) · badge-E #FFD966 (3k) · bracket #666666 (2k) · dash #999999 (59) |
| 57 | Trauma | `#DD7E6B` | `#FCF6F5` | neutral #EFEFEF (62k) · peds #FFC0CB (51k) · CC #D9D2E9 (26k) · bracket #666666 (4k) · dash #999999 (1k) · peds-rule #DA5798 (566) |
| 58 | Trauma | `#DD7E6B` | `#FCF6F5` | entry #CFE2F3 (40k) · neutral #EFEFEF (36k) · converge/Use #D9EAD3 (32k) · decision #E6B8AF (13k) · CC #D9D2E9 (6k) · note-trap #674EA7 (5k) · badge-A #93C47D (3k) · bracket #666666 (1k) · zebra-dk #D9D9D9 (43) |
| 59 | Trauma | `#DD7E6B` | `#FCF6F5` | peds #FFC0CB (71k) · neutral #EFEFEF (62k) · CC #D9D2E9 (32k) · bracket #666666 (4k) · dash #999999 (1k) · peds-rule #DA5798 (698) |
| 60 | Trauma | `#DD7E6B` | `#FCF6F5` | neutral #EFEFEF (93k) · entry #CFE2F3 (37k) · converge/Use #D9EAD3 (34k) · decision #E6B8AF (12k) · zebra-dk #D9D9D9 (62) |
| 61 | Trauma | `#DD7E6B` | `#FCF6F5` | peds #FFC0CB (51k) · bracket #666666 (4k) · peds-rule #DA5798 (566) |
| 62 | Trauma | `#DD7E6B` | `#FCF6F5` | entry #CFE2F3 (38k) · converge/Use #D9EAD3 (31k) · decision #E6B8AF (13k) · CC #D9D2E9 (5k) · neutral #EFEFEF (162) · zebra-dk #D9D9D9 (63) · bracket #666666 (44) · dash #999999 (42) |
| 63 | Trauma | `#DD7E6B` | `#FCF6F5` | peds #FFC0CB (72k) · CC #D9D2E9 (22k) · bracket #666666 (4k) · dash #999999 (2k) · peds-rule #DA5798 (698) · badge-E #FFD966 (673) |
| 64 | Trauma | `#DD7E6B` | `#FCF6F5` | entry #CFE2F3 (37k) · converge/Use #D9EAD3 (32k) · decision #E6B8AF (13k) · neutral #EFEFEF (174) · bracket #666666 (42) · dash #999999 (40) |
| 65 | Trauma | `#DD7E6B` | `#FCF6F5` | peds #FFC0CB (53k) · neutral #EFEFEF (5k) · bracket #666666 (3k) · dash #999999 (1k) · peds-rule #DA5798 (566) · zebra-dk #D9D9D9 (527) |
| 66 | Trauma | `#DD7E6B` | `#FCF6F5` | entry #CFE2F3 (40k) · neutral #EFEFEF (36k) · converge/Use #D9EAD3 (32k) · decision #E6B8AF (12k) · badge-E #FFD966 (6k) · note-trap #674EA7 (5k) · badge-A #93C47D (3k) · bracket #666666 (1k) · zebra-dk #D9D9D9 (52) |
| 67 | Trauma | `#DD7E6B` | `#FCF6F5` | peds #FFC0CB (50k) · bracket #666666 (4k) · dash #999999 (1k) · peds-rule #DA5798 (566) |
| 68 | Trauma | `#DD7E6B` | `#FCF6F5` | neutral #EFEFEF (122k) · entry #CFE2F3 (61k) · converge/Use #D9EAD3 (31k) · severity #F4CCCC (23k) · decision #E6B8AF (13k) · badge-A #93C47D (6k) · badge-E #FFD966 (2k) · bracket #666666 (1k) · zebra-dk #D9D9D9 (101) · dash #999999 (44) |
| 69 | Trauma | `#DD7E6B` | `#FCF6F5` | peds #FFC0CB (70k) · WARNING #CC0000 (5k) · bracket #666666 (4k) · dash #999999 (1k) · peds-rule #DA5798 (702) · badge-E #FFD966 (673) · badge-A #93C47D (649) |
| 70 | Trauma | `#DD7E6B` | `#FCF6F5` | entry #CFE2F3 (37k) · converge/Use #D9EAD3 (32k) · neutral #EFEFEF (31k) · decision #E6B8AF (13k) · WARNING #CC0000 (10k) · note-trap #674EA7 (5k) · badge-A #93C47D (3k) · bracket #666666 (1k) · zebra-dk #D9D9D9 (51) |
| 71 | Trauma | `#DD7E6B` | `#FCF6F5` | peds #FFC0CB (68k) · neutral #EFEFEF (18k) · bracket #666666 (3k) · dash #999999 (1k) · peds-rule #DA5798 (566) |
| 72 | Trauma | `#DD7E6B` | `#FCF6F5` | entry #CFE2F3 (38k) · converge/Use #D9EAD3 (31k) · WARNING #CC0000 (10k) · neutral #EFEFEF (6k) · CC #D9D2E9 (6k) |
| 73 | Trauma | `#DD7E6B` | `#FCF6F5` | peds #FFC0CB (51k) · CC #D9D2E9 (23k) · bracket #666666 (4k) · peds-rule #DA5798 (566) |
| 74 | Trauma | `#DD7E6B` | `#FCF6F5` | entry #CFE2F3 (39k) · converge/Use #D9EAD3 (33k) · neutral #EFEFEF (6k) · WARNING #CC0000 (4k) · note-trap #674EA7 (4k) |
| 75 | Trauma | `#DD7E6B` | `#FCF6F5` | peds #FFC0CB (51k) · neutral #EFEFEF (33k) · bracket #666666 (3k) · peds-rule #DA5798 (566) |
| 76 | Trauma | `#DD7E6B` | `#FCF6F5` | entry #CFE2F3 (39k) · converge/Use #D9EAD3 (32k) · neutral #EFEFEF (32k) · zebra-dk #D9D9D9 (23k) · decision #E6B8AF (13k) · badge-A #93C47D (6k) · badge-E #FFD966 (3k) · bracket #666666 (2k) |
| 77 | Trauma | `#DD7E6B` | `#FCF6F5` | neutral #EFEFEF (100k) · peds #FFC0CB (71k) · bracket #666666 (4k) · peds-rule #DA5798 (702) · zebra-dk #D9D9D9 (43) |
| 78 | Critical Care | `#351C75` | `#F2F0F6` | neutral #EFEFEF (53k) · entry #CFE2F3 (37k) · converge/Use #D9EAD3 (31k) · zebra-dk #D9D9D9 (21k) · decision #E6B8AF (13k) · WARNING #CC0000 (5k) · peds #FFC0CB (2k) · bracket #666666 (2k) · dash #999999 (54) |
| 79 | Critical Care | `#351C75` | `#F2F0F6` | peds #FFC0CB (73k) · neutral #EFEFEF (5k) · bracket #666666 (4k) · peds-rule #DA5798 (566) |
| 80 | Critical Care | `#351C75` | `#F2F0F6` | neutral #EFEFEF (45k) · entry #CFE2F3 (40k) · zebra-dk #D9D9D9 (39k) · converge/Use #D9EAD3 (32k) · decision #E6B8AF (12k) · bracket #666666 (6k) · dash #999999 (74) |
| 81 | Critical Care | `#351C75` | `#F2F0F6` | neutral #EFEFEF (98k) · peds #FFC0CB (81k) · bracket #666666 (3k) · peds-rule #DA5798 (566) |
| 82 | Critical Care | `#351C75` | `#F2F0F6` | neutral #EFEFEF (45k) · converge/Use #D9EAD3 (32k) · zebra-dk #D9D9D9 (21k) · entry #CFE2F3 (17k) · entry-zebra #E5EFF7 (15k) · decision #E6B8AF (12k) · CC #D9D2E9 (6k) · bracket #666666 (5k) · dash #999999 (44) |
| 83 | Critical Care | `#351C75` | `#F2F0F6` | neutral #EFEFEF (94k) · peds #FFC0CB (63k) · bracket #666666 (4k) · peds-rule #DA5798 (666) |
| 84 | Critical Care | `#351C75` | `#F2F0F6` | entry #CFE2F3 (40k) · converge/Use #D9EAD3 (31k) · neutral #EFEFEF (29k) · zebra-dk #D9D9D9 (22k) · decision #E6B8AF (12k) · badge-A #93C47D (6k) · bracket #666666 (2k) · dash #999999 (48) |
| 85 | Critical Care | `#351C75` | `#F2F0F6` | peds #FFC0CB (63k) · neutral #EFEFEF (4k) · bracket #666666 (4k) · peds-rule #DA5798 (666) |
| 86 | Critical Care | `#351C75` | `#F2F0F6` | entry #CFE2F3 (37k) · converge/Use #D9EAD3 (31k) · neutral #EFEFEF (30k) · zebra-dk #D9D9D9 (20k) · decision #E6B8AF (13k) · CC #D9D2E9 (6k) · note-trap #674EA7 (5k) · bracket #666666 (2k) · dash #999999 (49) |
| 87 | Critical Care | `#351C75` | `#F2F0F6` | neutral #EFEFEF (112k) · peds #FFC0CB (63k) · zebra-dk #D9D9D9 (33k) · bracket #666666 (4k) · peds-rule #DA5798 (666) |
| 88 | Critical Care | `#351C75` | `#F2F0F6` | neutral #EFEFEF (89k) · entry #CFE2F3 (35k) · converge/Use #D9EAD3 (31k) · note-trap #674EA7 (5k) · bracket #666666 (1k) · zebra-dk #D9D9D9 (55) · dash #999999 (41) |
| 89 | Critical Care | `#351C75` | `#F2F0F6` | peds #FFC0CB (90k) · neutral #EFEFEF (12k) · bracket #666666 (3k) · dash #999999 (1k) · peds-rule #DA5798 (830) |
| 90 | Critical Care | `#351C75` | `#F2F0F6` | entry #CFE2F3 (39k) · neutral #EFEFEF (32k) · converge/Use #D9EAD3 (31k) · zebra-dk #D9D9D9 (22k) · decision #E6B8AF (13k) · CC #D9D2E9 (6k) · bracket #666666 (2k) |
| 91 | Critical Care | `#351C75` | `#F2F0F6` | peds #FFC0CB (63k) · neutral #EFEFEF (6k) · bracket #666666 (4k) · peds-rule #DA5798 (666) |
| 92 | Critical Care | `#351C75` | `#F2F0F6` | neutral #EFEFEF (31k) · converge/Use #D9EAD3 (30k) · zebra-dk #D9D9D9 (20k) · entry #CFE2F3 (17k) · entry-zebra #E5EFF7 (14k) · decision #E6B8AF (13k) · note-trap #674EA7 (4k) · bracket #666666 (2k) |
| 93 | Critical Care | `#351C75` | `#F2F0F6` | peds #FFC0CB (45k) · neutral #EFEFEF (6k) · bracket #666666 (4k) · peds-rule #DA5798 (530) |
| 94 | Critical Care | `#351C75` | `#F2F0F6` | entry #CFE2F3 (34k) · converge/Use #D9EAD3 (32k) · neutral #EFEFEF (30k) · decision #E6B8AF (13k) · bracket #666666 (1k) · zebra-dk #D9D9D9 (43) |
| 95 | Critical Care | `#351C75` | `#F2F0F6` | neutral #EFEFEF (148k) · peds #FFC0CB (50k) · bracket #666666 (3k) · dash #999999 (1k) · peds-rule #DA5798 (566) · zebra-dk #D9D9D9 (77) |
| 96 | Procedures | `#E69138` | `#FFFFFF` | neutral #EFEFEF (47k) · badge-E #FFD966 (18k) · CC #D9D2E9 (12k) · badge-A #93C47D (12k) · badge-I #6FA8DC (9k) · bracket #666666 (4k) · zebra-dk #D9D9D9 (110) · dash #999999 (49) |
| 97 | Procedures | `#E69138` | `#FDF8F2` | bracket #666666 (4k) · badge-E #FFD966 (3k) · neutral #EFEFEF (3k) · badge-A #93C47D (3k) · dash #999999 (803) · badge-I #6FA8DC (775) |
| 98 | Procedures | `#E69138` | `#FDF8F2` | peds #FFC0CB (23k) · neutral #EFEFEF (6k) · bracket #666666 (4k) · badge-A #93C47D (3k) · dash #999999 (1k) · badge-E #FFD966 (1k) |
| 99 | Procedures | `#E69138` | `#FDF8F2` | peds #FFC0CB (23k) · neutral #EFEFEF (6k) · bracket #666666 (5k) · badge-E #FFD966 (3k) · dash #999999 (1k) · badge-I #6FA8DC (775) |
| 100 | Procedures | `#E69138` | `#FDF8F2` | CC #D9D2E9 (19k) · peds #FFC0CB (12k) · bracket #666666 (5k) · badge-I #6FA8DC (3k) · badge-A #93C47D (3k) · badge-E #FFD966 (3k) |
| 101 | Procedures | `#E69138` | `#FDF8F2` | peds #FFC0CB (63k) · neutral #EFEFEF (26k) · bracket #666666 (7k) · badge-A #93C47D (4k) · dash #999999 (1k) · badge-I #6FA8DC (800) · badge-E #FFD966 (673) |
| 102 | Procedures | `#E69138` | `#FDF8F2` | neutral #EFEFEF (10k) · bracket #666666 (5k) · dash #999999 (1k) · badge-E #FFD966 (673) |
| 103 | Procedures | `#E69138` | `#FDF8F2` | neutral #EFEFEF (10k) · bracket #666666 (5k) · badge-E #FFD966 (3k) |
| 104 | Procedures | `#E69138` | `#FDF8F2` | neutral #EFEFEF (134k) · zebra-dk #D9D9D9 (131k) · bracket #666666 (17k) · badge-I #6FA8DC (6k) · badge-A #93C47D (4k) · dash #999999 (69) |
| 105 | Procedures | `#E69138` | `#FDF8F2` | peds #FFC0CB (46k) · badge-I #6FA8DC (6k) · bracket #666666 (4k) · neutral #EFEFEF (3k) |
| 106 | Procedures | `#E69138` | `#FDF8F2` | badge-E #FFD966 (6k) · note-trap #674EA7 (5k) · bracket #666666 (4k) · dash #999999 (1k) · badge-A #93C47D (649) |
| 107 | Procedures | `#E69138` | `#FDF8F2` | neutral #EFEFEF (93k) · bracket #666666 (5k) · zebra-dk #D9D9D9 (47) |
| 108 | Procedures | `#E69138` | `#FDF8F2` | neutral #EFEFEF (126k) · peds #FFC0CB (66k) · bracket #666666 (5k) · zebra-dk #D9D9D9 (792) · dash #999999 (306) |
| 109 | Policies | `#E69138` | `#FDF8F2` | bracket #666666 (5k) · badge-E #FFD966 (2k) |
| 110 | Policies | `#E69138` | `#FDF8F2` | peds #FFC0CB (131k) · bracket #666666 (4k) · peds-rule #DA5798 (966) |
| 111 | Policies | `#E69138` | `#FDF8F2` | bracket #666666 (5k) |
| 112 | Policies | `#E69138` | `#FDF8F2` | neutral #EFEFEF (156k) · bracket #666666 (5k) · badge-I #6FA8DC (775) · badge-E #FFD966 (673) · zebra-dk #D9D9D9 (79) |
| 113 | Policies | `#E69138` | `#FDF8F2` | note-trap #674EA7 (5k) · bracket #666666 (4k) |
| 114 | Policies | `#E69138` | `#FDF8F2` | bracket #666666 (4k) |
| 115 | Policies | `#E69138` | `#FDF8F2` | bracket #666666 (5k) |
| 116 | Policies | `#E69138` | `#FDF8F2` | converge/Use #D9EAD3 (24k) · CC #D9D2E9 (20k) · decision #E6B8AF (13k) · note-trap #674EA7 (6k) · bracket #666666 (4k) · badge-I #6FA8DC (808) |
| 117 | Policies | `#E69138` | `#FDF8F2` | bracket #666666 (5k) · dash #999999 (1k) · badge-I #6FA8DC (775) |
| 118 | Drug Reference | `#76A5AF` | `#F6F9F9` | bracket #666666 (5k) · neutral #EFEFEF (2k) · dash #999999 (1k) · zebra-dk #D9D9D9 (494) · entry #CFE2F3 (40) |
| 119 | Drug Reference | `#76A5AF` | `#FFF2CC` | Caution #FFF2CC (153k) · converge/Use #D9EAD3 (128k) · card-hdr #3A5D64 (120k) · CC #D9D2E9 (97k) · Notes #D0E0E3 (89k) · Caution-spine #FFE599 (19k) · Use-spine #B6D7A8 (16k) · Notes-spine-CC #B4A7D6 (5k) · Notes-spine #A4C2F4 (5k) |
| 120 | Drug Reference | `#76A5AF` | `#D0E0E3` | Notes #D0E0E3 (188k) · Caution #FFF2CC (159k) · converge/Use #D9EAD3 (131k) · card-hdr #3A5D64 (125k) · Caution-spine #FFE599 (19k) · Use-spine #B6D7A8 (16k) · Notes-spine #A4C2F4 (11k) |
| 121 | Drug Reference | `#76A5AF` | `#D0E0E3` | Notes #D0E0E3 (173k) · Caution #FFF2CC (155k) · card-hdr #3A5D64 (127k) · converge/Use #D9EAD3 (122k) · Caution-spine #FFE599 (19k) · Use-spine #B6D7A8 (16k) · Notes-spine #A4C2F4 (11k) |
| 122 | Drug Reference | `#76A5AF` | `#D0E0E3` | Notes #D0E0E3 (191k) · Caution #FFF2CC (158k) · converge/Use #D9EAD3 (131k) · card-hdr #3A5D64 (129k) · Caution-spine #FFE599 (19k) · Use-spine #B6D7A8 (16k) · Notes-spine #A4C2F4 (11k) |
| 123 | Drug Reference | `#76A5AF` | `#D0E0E3` | Notes #D0E0E3 (183k) · Caution #FFF2CC (165k) · converge/Use #D9EAD3 (130k) · card-hdr #3A5D64 (121k) · Caution-spine #FFE599 (19k) · Use-spine #B6D7A8 (16k) · Notes-spine #A4C2F4 (11k) |
| 124 | Drug Reference | `#76A5AF` | `#D0E0E3` | Notes #D0E0E3 (189k) · Caution #FFF2CC (156k) · converge/Use #D9EAD3 (127k) · card-hdr #3A5D64 (117k) · Caution-spine #FFE599 (19k) · Use-spine #B6D7A8 (16k) · Notes-spine #A4C2F4 (11k) |
| 125 | Drug Reference | `#76A5AF` | `#D0E0E3` | Notes #D0E0E3 (184k) · Caution #FFF2CC (150k) · card-hdr #3A5D64 (124k) · converge/Use #D9EAD3 (122k) · Caution-spine #FFE599 (19k) · Use-spine #B6D7A8 (16k) · Notes-spine #A4C2F4 (11k) · zebra-dk #D9D9D9 (58) · neutral #EFEFEF (44) |
| 126 | Drug Reference | `#76A5AF` | `#D0E0E3` | Notes #D0E0E3 (185k) · Caution #FFF2CC (161k) · converge/Use #D9EAD3 (131k) · card-hdr #3A5D64 (123k) · Caution-spine #FFE599 (19k) · Use-spine #B6D7A8 (16k) · Notes-spine #A4C2F4 (11k) · neutral #EFEFEF (44) |
| 127 | Drug Reference | `#76A5AF` | `#D0E0E3` | Notes #D0E0E3 (192k) · Caution #FFF2CC (154k) · converge/Use #D9EAD3 (125k) · card-hdr #3A5D64 (122k) · Caution-spine #FFE599 (19k) · Use-spine #B6D7A8 (16k) · Notes-spine #A4C2F4 (11k) · neutral #EFEFEF (61) · zebra-dk #D9D9D9 (48) |
| 128 | Drug Reference | `#76A5AF` | `#D0E0E3` | Notes #D0E0E3 (183k) · Caution #FFF2CC (150k) · converge/Use #D9EAD3 (120k) · card-hdr #3A5D64 (112k) · Caution-spine #FFE599 (19k) · Use-spine #B6D7A8 (16k) · Notes-spine #A4C2F4 (11k) |
| 129 | Drug Reference | `#76A5AF` | `#FFF2CC` | Caution #FFF2CC (154k) · converge/Use #D9EAD3 (119k) · card-hdr #3A5D64 (114k) · CC #D9D2E9 (109k) · Notes #D0E0E3 (77k) · Caution-spine #FFE599 (19k) · Use-spine #B6D7A8 (16k) · Notes-spine-CC #B4A7D6 (5k) · Notes-spine #A4C2F4 (5k) |
| 130 | Drug Reference | `#76A5AF` | `#D0E0E3` | Notes #D0E0E3 (159k) · Caution #FFF2CC (146k) · converge/Use #D9EAD3 (127k) · card-hdr #3A5D64 (120k) · CC #D9D2E9 (25k) · Caution-spine #FFE599 (19k) · Use-spine #B6D7A8 (16k) · Notes-spine #A4C2F4 (11k) |
| 131 | Drug Reference | `#76A5AF` | `#D0E0E3` | Notes #D0E0E3 (197k) · Caution #FFF2CC (158k) · converge/Use #D9EAD3 (128k) · card-hdr #3A5D64 (119k) · Caution-spine #FFE599 (19k) · Use-spine #B6D7A8 (16k) · Notes-spine #A4C2F4 (11k) · neutral #EFEFEF (49) · zebra-dk #D9D9D9 (47) |
| 132 | Drug Reference | `#76A5AF` | `#FFF2CC` | Caution #FFF2CC (156k) · converge/Use #D9EAD3 (128k) · card-hdr #3A5D64 (122k) · CC #D9D2E9 (99k) · Notes #D0E0E3 (96k) · Caution-spine #FFE599 (19k) · Use-spine #B6D7A8 (16k) · Notes-spine-CC #B4A7D6 (5k) · Notes-spine #A4C2F4 (5k) |
| 133 | Drug Reference | `#76A5AF` | `#D0E0E3` | Notes #D0E0E3 (172k) · Caution #FFF2CC (155k) · card-hdr #3A5D64 (126k) · converge/Use #D9EAD3 (118k) · Caution-spine #FFE599 (19k) · Use-spine #B6D7A8 (16k) · Notes-spine #A4C2F4 (11k) · CC #D9D2E9 (8k) |
| 134 | Drug Reference | `#76A5AF` | `#D9D2E9` | CC #D9D2E9 (187k) · Caution #FFF2CC (151k) · card-hdr #3A5D64 (125k) · converge/Use #D9EAD3 (124k) · Caution-spine #FFE599 (19k) · Use-spine #B6D7A8 (16k) · Notes-spine-CC #B4A7D6 (11k) · neutral #EFEFEF (448) |
| 135 | Drug Reference | `#76A5AF` | `#FFF2CC` | Caution #FFF2CC (154k) · card-hdr #3A5D64 (125k) · converge/Use #D9EAD3 (124k) · CC #D9D2E9 (98k) · Notes #D0E0E3 (97k) · Caution-spine #FFE599 (19k) · Use-spine #B6D7A8 (16k) · Notes-spine-CC #B4A7D6 (5k) · Notes-spine #A4C2F4 (5k) |
| 136 | Drug Reference | `#76A5AF` | `#D0E0E3` | Notes #D0E0E3 (174k) · Caution #FFF2CC (147k) · converge/Use #D9EAD3 (129k) · card-hdr #3A5D64 (116k) · Caution-spine #FFE599 (19k) · Use-spine #B6D7A8 (16k) · Notes-spine #A4C2F4 (11k) · CC #D9D2E9 (5k) |
| 137 | Drug Reference | `#76A5AF` | `#FFF2CC` | Caution #FFF2CC (150k) · converge/Use #D9EAD3 (126k) · card-hdr #3A5D64 (126k) · Notes #D0E0E3 (94k) · CC #D9D2E9 (90k) · Caution-spine #FFE599 (19k) · Use-spine #B6D7A8 (16k) · Notes-spine #A4C2F4 (5k) · Notes-spine-CC #B4A7D6 (5k) |
| 138 | Drug Reference | `#76A5AF` | `#D0E0E3` | Notes #D0E0E3 (165k) · Caution #FFF2CC (151k) · converge/Use #D9EAD3 (124k) · card-hdr #3A5D64 (111k) · Caution-spine #FFE599 (19k) · Use-spine #B6D7A8 (16k) · CC #D9D2E9 (15k) · Notes-spine #A4C2F4 (11k) · neutral #EFEFEF (132) · zebra-dk #D9D9D9 (50) |
| 139 | Drug Reference | `#76A5AF` | `#D9D2E9` | CC #D9D2E9 (189k) · Caution #FFF2CC (147k) · converge/Use #D9EAD3 (127k) · card-hdr #3A5D64 (125k) · Caution-spine #FFE599 (19k) · Use-spine #B6D7A8 (16k) · Notes-spine-CC #B4A7D6 (11k) |
| 140 | Drug Reference | `#76A5AF` | `#D9D2E9` | CC #D9D2E9 (190k) · Caution #FFF2CC (152k) · converge/Use #D9EAD3 (128k) · card-hdr #3A5D64 (120k) · Caution-spine #FFE599 (19k) · Use-spine #B6D7A8 (16k) · Notes-spine-CC #B4A7D6 (11k) |
| 141 | Drug Reference | `#76A5AF` | `#D0E0E3` | Notes #D0E0E3 (196k) · Caution #FFF2CC (153k) · converge/Use #D9EAD3 (127k) · card-hdr #3A5D64 (123k) · Caution-spine #FFE599 (19k) · Use-spine #B6D7A8 (16k) · Notes-spine #A4C2F4 (11k) · zebra-dk #D9D9D9 (459) |
| 142 | Drug Reference | `#76A5AF` | `#D0E0E3` | Notes #D0E0E3 (183k) · Caution #FFF2CC (160k) · card-hdr #3A5D64 (123k) · converge/Use #D9EAD3 (122k) · Caution-spine #FFE599 (19k) · Use-spine #B6D7A8 (16k) · Notes-spine #A4C2F4 (11k) |
| 143 | Drug Reference | `#76A5AF` | `#FFF2CC` | Caution #FFF2CC (162k) · Notes #D0E0E3 (154k) · converge/Use #D9EAD3 (130k) · card-hdr #3A5D64 (127k) · CC #D9D2E9 (25k) · Caution-spine #FFE599 (19k) · Use-spine #B6D7A8 (16k) · Notes-spine #A4C2F4 (11k) |
| 144 | Peds Reference | `#FFC0CB` | `#FFFBFB` | peds #FFC0CB (64k) · Broselow #38761D (51k) · Broselow #1155CC (21k) · note-trap #674EA7 (11k) · peds-rule #DA5798 (11k) · WARNING #CC0000 (10k) · dash #999999 (5k) · bracket #666666 (5k) · badge-E #FFD966 (1k) |
| 145 | Peds Reference | `Broselow GREY #555555` | `#F5F5F5` | peds #FFC0CB (31k) · CC-box #9900FF (8k) · bracket #666666 (264) · zebra-dk #D9D9D9 (262) · neutral #EFEFEF (259) · dash #999999 (157) |
| 146 | Peds Reference | `Broselow GREY #555555` | `#F5F5F5` | peds #FFC0CB (28k) · CC-box #9900FF (8k) · zebra-dk #D9D9D9 (286) · bracket #666666 (229) · neutral #EFEFEF (169) · dash #999999 (155) |
| 147 | Peds Reference | `Broselow PINK #DA5798` | `#FAF5F8` | peds-rule #DA5798 (80k) · peds #FFC0CB (29k) · CC-box #9900FF (8k) |
| 148 | Peds Reference | `Broselow RED #CC0000` | `#FAF2F2` | WARNING #CC0000 (67k) · peds #FFC0CB (28k) · CC-box #9900FF (8k) |
| 149 | Peds Reference | `Broselow PURPLE #674EA7` | `#F6F5F8` | note-trap #674EA7 (77k) · peds #FFC0CB (32k) · CC-box #9900FF (8k) |
| 150 | Peds Reference | `Broselow YELLOW #F1C232` | `#FBF9F4` | peds #FFC0CB (30k) · CC-box #9900FF (8k) |
| 151 | Peds Reference | `Broselow WHITE #F3F3F3` | `#FBFBFB` | peds #FFC0CB (31k) · CC-box #9900FF (8k) · dash #999999 (478) · neutral #EFEFEF (309) · zebra-dk #D9D9D9 (178) · bracket #666666 (126) |
| 152 | Peds Reference | `Broselow WHITE #F3F3F3` | `#FBFBFB` | peds #FFC0CB (31k) · CC-box #9900FF (8k) · dash #999999 (485) · neutral #EFEFEF (316) · zebra-dk #D9D9D9 (193) · bracket #666666 (130) |
| 153 | Peds Reference | `Broselow BLUE #1155CC` | `#F2F5FA` | Broselow #1155CC (84k) · peds #FFC0CB (31k) · CC-box #9900FF (8k) |
| 154 | Peds Reference | `Broselow BLUE #1155CC` | `#F2F5FA` | Broselow #1155CC (84k) · peds #FFC0CB (31k) · CC-box #9900FF (8k) |
| 155 | Peds Reference | `Broselow ORANGE #E69138` | `#FBF7F4` | peds #FFC0CB (30k) · CC-box #9900FF (8k) |
| 156 | Peds Reference | `Broselow ORANGE #E69138` | `#FBF7F4` | peds #FFC0CB (30k) · CC-box #9900FF (8k) |
| 157 | Peds Reference | `Broselow GREEN #38761D` | `#F4F6F3` | Broselow #38761D (78k) · peds #FFC0CB (31k) · CC-box #9900FF (8k) |
| 158 | Peds Reference | `Broselow GREEN #38761D` | `#F4F6F3` | Broselow #38761D (73k) · peds #FFC0CB (30k) · CC-box #9900FF (8k) |
| 159 | Peds Reference | `Broselow GREEN #38761D` | `#F4F6F3` | Broselow #38761D (75k) · peds #FFC0CB (30k) · CC-box #9900FF (8k) |
| 160 | Peds Reference | `Broselow GREEN #38761D` | `#F4F6F3` | Broselow #38761D (73k) · peds #FFC0CB (30k) · CC-box #9900FF (8k) |
| 161 | Peds Reference | `Broselow GREEN #38761D` | `#F4F6F3` | Broselow #38761D (73k) · peds #FFC0CB (31k) · CC-box #9900FF (8k) |
| 162 | Index/About | `#999999` | `#EFEFEF` | neutral #EFEFEF (898k) · dash #999999 (73k) · zebra-dk #D9D9D9 (670) · bracket #666666 (454) |
| 163 | Index/About | `#999999` | `#EFEFEF` | neutral #EFEFEF (918k) · dash #999999 (72k) · zebra-dk #D9D9D9 (585) · bracket #666666 (387) |
| 164 | Index/About | `#999999` | `#EFEFEF` | neutral #EFEFEF (897k) · dash #999999 (74k) · zebra-dk #D9D9D9 (662) · bracket #666666 (448) |
| 165 | Index/About | `#999999` | `#EFEFEF` | neutral #EFEFEF (899k) · dash #999999 (73k) · zebra-dk #D9D9D9 (615) · bracket #666666 (393) |
| 166 | Back cover | `—` | `#FFFFFF` | bracket #666666 (1k) · neutral #EFEFEF (883) · zebra-dk #D9D9D9 (334) · dash #999999 (157) |

---

## 10. Summary — every finding, with a verdict

### 10.1 KEEP (the app should adopt the print behaviour)

| # | Finding | Where to fix |
| --- | --- | --- |
| **F-18** | **Dose-table zebra must encode POPULATION, not chapter**: adult `#EFEFEF`/`#D9D9D9`, peds `#FFDCE2`/`#FFC0CB`. The single highest-value fix in this audit. | `dose_table.dart:38-40` + 4 new roles |
| **F-9** | Section bracket is `#666666` on all 117 bracketed pages, never the accent — that is what lets the `#DA5798` peds bracket mean something. | `prose_block_view.dart:155` |
| **F-8** | `peds_band_fill` → `#FFC0CB`, `cc_band_fill` → `#D9D2E9`. The app's values are washed-out. | `palette.dart:55,57` |
| **F-12/13** | `provider_emt` → `#FFD966`, `provider_als` → `#93C47D`, `provider_any` → `#EFEFEF`. (`provider_intermediate` is already right.) | `palette.dart:37,39,41` |
| **F-19** | Paediatric tint applies to *part* of a box (p.71 ABLS rows), to *single lines* of a list (pp.25, 30, 100) and to *per-tile side tabs* (pp.30, 78) — not just whole sections. | model + renderers |
| **F-16** | The dashed conditional outline is `#999999` with **no fill** when it wraps a single line (pp.25, 43) and a `#FDFAFA` fill when it is a card (p.71). | `prose_block_view.dart:88-97` |
| **F-25** | Solid boxes, flow nodes and procedure cards have **black** borders in print, on every chapter. | `prose_block_view.dart:48`, `procedure_card_block_view.dart:45,57`, `flow_node.dart:64` |
| **F-24** | Dashed borders are `#999999`. | `prose_block_view.dart:96`, `procedure_card_block_view.dart:29` |
| **F-29** | Drug-card Notes zone is `#D0E0E3` cyan by default and `#D9D2E9` lavender only for Critical-Care drugs. The app's single purple destroys the CC signal. | `drug_card_block_view.dart:27` |
| **F-3** | Drug Reference appendix accent is teal `#76A5AF`, not Universal blue. | `book.yaml` |
| **A-7** | The CC sub-tile under a convergence node is `#D9D2E9` with a **black** border, not `#F1E7F6` with a purple one — one colour, one meaning. | `palette.dart:68`, `flowchart_view.dart:1087-1088` |

### 10.2 ADAPT (print behaviour understood, app should diverge deliberately)

| # | Finding | Why adapt rather than copy |
| --- | --- | --- |
| **F-1** | Chapter accents: keep the app's darker accents for AppBar chrome (contrast), but derive in-page tints from the print's light accents. | a `#6D9EEB` AppBar with white text fails contrast |
| **F-4** | Add a 2–3 % chapter page wash. Print washes every page; the app is pure white, so `#EFEFEF` boxes and white nodes have no figure/ground separation. | must stay under the semantic tints in strength |
| **F-2** | Procedures/Policies are one orange run in print; the app splits them. | the split is a navigational improvement |
| **F-10** | Ordinary section titles should be black; keep the pink "Pediatrics" title (an improvement on print). | contrast between coloured and uncoloured titles is the point |
| **F-11** | The CC band has no bracket in print; the app adds one. Keep the addition, record it. | a bare tint with no left edge is easy to miss on a phone |
| **F-15** | The Critical-Care Paramedic badge is a `#8E61FF`→`#FED3EA` gradient on 12 pages; the app has no such level. Add a distinct CC-paramedic level; a flat mid-violet is acceptable if a gradient is too fussy at chip size. | must not stay identical to plain paramedic |
| **F-14** | The flat `#D5A6BD` paramedic badge appears on **one** page (p.2, legend) in the entire book. | keep the role, expect near-zero use |
| **F-9(hue)** | `flow_decision` `0xFFF6BDAE` is 16 red-points hotter than print `#E6B8AF`. | small; repoint when convenient |
| **F-26** | `warning_safety` → `#CC0000`, `warning_caution` → `#674EA7`. | matches the Broselow RED/PURPLE swatches, keeping the book coherent |
| **F-23/33** | Repoint the five amber roles (`alert*`, `note*`) at the print's neutrals. Print has **no** amber callout. | amber is currently outshouting the red octagon |
| **F-27** | `#9900FF` CC outline boxes group a run of drug rows in the Peds Reference; a per-row lavender tint would lose the grouping. | needs a "box these rows" primitive, not just a tint |
| **F-31** | Drug-card zone spine strips (`#B6D7A8`/`#FFE599`/`#A4C2F4`/`#B4A7D6`). | cheap edge cue; label rotation is another stream's problem |
| **F-30/34** | Promote the 11 content-bearing hardcodes to palette roles with print defaults. | the cascade exists precisely for this |
| **B-9** | The app's solid accent table-header bar has no print counterpart (print headers are black-on-tint). | fine as an app convention, but it is an invention |
| **F-21** | When the regenerated Broselow band pages land, the band colour must be a topic-level `palette: {accent: …}`, not the one Peds-Reference accent. pp.145–161 are deliberately not reproduced (Handtevy is proprietary), so nothing is broken today. | `wvems_2026_144.yaml` successors |
| **F-32** | Choose one: neutral/black chrome like print so colour means something, or accent chrome throughout with a stronger cue for the semantic colours. Currently the app is halfway. | this is a design decision, not a bug |

### 10.3 DROP (print artifact, not worth carrying to a phone)

| # | Finding |
| --- | --- |
| **F-5** | The outer-edge thumb-index rail — a bound-book affordance with no phone equivalent. |
| **F-6** | Top-bar-on-verso / bottom-bar-on-recto alternation — spread logic. |
| **F-7** | Footer title bar and the two page-number circles — pagination. |
| **F-28** | Drop shadows on every box, node and circle. |
| **§3.6** | `column_tint` — the print uses no per-column tint anywhere in 166 pages (the app's support is used only by ProtocolBook and WHO IMCI). |
| **§5.4** | The index/About pages (162–165) are entirely monochrome — nothing to port. |
| **§5.5** | Cover artwork (pp.1, 166). |
| **§5.6** | Photographic and illustrative colour (drug vials, anatomical figures, skin tones). |

### 10.4 Proposed `kRoleDefaults` diff

Repointing only; no role removed. New roles marked **NEW**.

```
  'peds_band_fill':        0xFFFBD5DE  →  0xFFFFC0CB
  'cc_band_fill':          0xFFE3DCF2  →  0xFFD9D2E9
  'provider_emt':          0xFFF2C24A  →  0xFFFFD966
  'provider_als':          0xFF7BBF86  →  0xFF93C47D
  'provider_any':          0xFFE0E0E0  →  0xFFEFEFEF
  'provider_paramedic':    0xFFAB91D8  →  0xFFD5A6BD
  'flow_decision':         0xFFF6BDAE  →  0xFFE6B8AF
  'flow_entry':            0xFFCDE0F1  →  0xFFCFE2F3
  'flow_convergence':      0xFFD5ECD6  →  0xFFD9EAD3
  'warning_safety':        0xFFD32F2F  →  0xFFCC0000
  'warning_caution':       0xFF7E57C2  →  0xFF674EA7
  'cc_link_fill':          0xFFF1E7F6  →  0xFFD9D2E9
  'cc_link_border':        0xFF6A1B9A  →  0xFF000000
  'pop_peds':              0xFFF8C9DA  →  0xFFD23282   (it is the tab, not the row)
  'pop_adult':             0xFFD9D9D9  →  0xFF666666   (ditto)
  'alert':                 0xFFF6A609  →  0xFF999999   (dashed conditional outline)
  'alert_fill':            0xFFFFF6D6  →  0xFFFDFAFA
  'alert_text':            0xFFB9770A  →  0xFF000000
  'note_fill':             0xFFFFFDE7  →  0xFFEFEFEF   (Concept box)
  'note_border':           0xFFF9A825  →  0xFF000000
  'note_text':             0xFF5D4037  →  0xFF000000

NEW 'section_rule':        0xFF666666   section bracket, all ordinary sections
NEW 'peds_row_light':      0xFFFFDCE2   peds dose-table light stripe
NEW 'peds_row_dark':       0xFFFFC0CB   peds dose-table dark stripe
NEW 'adult_row_light':     0xFFEFEFEF   adult dose-table light stripe
NEW 'adult_row_dark':      0xFFD9D9D9   adult dose-table dark stripe
NEW 'provider_cc_medic_a': 0xFF8E61FF   CC-paramedic badge gradient stop 1
NEW 'provider_cc_medic_b': 0xFFFED3EA   CC-paramedic badge gradient stop 2
NEW 'drug_card_header':    0xFF3A5D64
NEW 'drug_use_fill':       0xFFD9EAD3   spine 0xFFB6D7A8
NEW 'drug_caution_fill':   0xFFFFF2CC   spine 0xFFFFE599
NEW 'drug_notes_fill':     0xFFD0E0E3   spine 0xFFA4C2F4
NEW 'drug_notes_cc_fill':  0xFFD9D2E9   spine 0xFFB4A7D6
NEW 'cc_outline':          0xFF9900FF   Peds-Reference CC group box border
NEW 'page_wash':           per-chapter, e.g. 0xFFF5F8FD / 0xFFF5F9F3 / 0xFFFCF6F5 / 0xFFF2F0F6
```

### 10.5 The one-sentence version

The WVEMS book uses colour in exactly two registers — a **chapter register** (five things:
page circles, title bar, edge rail, page wash, Broselow band) and a **semantic register**
(everything else, fixed across all 166 pages) — and the app's principal defect is that it
has moved seven semantic things into the chapter register, most damagingly the dose-table
zebra, which in print tells a medic at a glance whether a dose is adult or paediatric.

---

*Audit produced 2026-08-01. Raw data:
`colour_inventory.tsv`, `chrome_probe.tsv`, `census.tsv`, `census_bycolour.tsv`,
`perpage.tsv`, `chroma_colours.tsv`, `pedsref_bands.tsv`, `paramedic_scan.tsv`,
`scanline_log.tsv`, `probe_log.tsv`, `unexplained.tsv` — all in the session scratchpad
`/tmp/claude-1000/-home-grey-dev-fhir/8f9442b1-043e-47a0-a2fe-e29e007cc633/scratchpad/`.
Scripts: `colour_inventory.py`, `probe_chrome.py`, `census.py`, `scanline.py`,
`probe_pt.py`.*
