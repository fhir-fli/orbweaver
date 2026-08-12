# WVEMS 2026 — Typography & Text Audit (print vs app)

**Scope:** typography and text only. Colour, badges and layout belong to other
streams and are touched here only where they interact with type.

**Source of truth:** `/home/grey/dev/fhir/orbweaver/2026-WVEMS-Protocols.pdf`
— 166 pages, 612 x 1008 pt (US Legal). Printed page N = PDF page N.

**App under audit:** `/home/grey/dev/fhir/orbweaver-wt`
(`assets/books/wvems/**`, `lib/widgets/mini_markdown.dart`,
`lib/widgets/blocks/prose_block_view.dart`, `lib/widgets/section_bracket.dart`,
`lib/widgets/blocks/table_block_view.dart`, `lib/theme/**`,
`lib/widgets/topic_view.dart`).

---

## Method

Everything below is measured, not inferred. Three independent extractions over
**all 166 pages**, each written to disk incrementally:

1. **Per-span typography** — PyMuPDF `get_text("dict")`: exact font name, point
   size, style flags, colour and bbox for all 20,000+ text spans. Point sizes
   are read from the PDF's own text matrix, not estimated from rendered glyphs.
2. **Vector rules and link annotations** — `get_drawings()` and `get_links()`.
   The print's underlines are drawn as 2.25 pt filled bands 1.7-3.9 pt below the
   baseline, and every one of them coincides exactly with a PDF link annotation.
   Underline targets are therefore read off the annotation (`/Dest` page number
   or URI), and the underlined phrase is recovered char-by-char from
   `get_text("rawdict")` char bboxes inside the link rect.
3. **Rendered pages** — `pdftoppm -r 100` for visual confirmation of pp. 25, 121
   and 150 (checked against the extracted numbers before any claim was made).

App-side measurement:

- Declared sizes read directly from the widget sources.
- **Line measure and wrapping were NOT measured in `flutter_test`.** That
  harness renders in Ahem (square em advance, ~2x Roboto) and has already
  produced one wrong conclusion in this project. Instead, advance widths were
  taken from the actual TTFs the app gets on device
  (`$FLUTTER_ROOT/bin/cache/artifacts/material_fonts/Roboto-*.ttf`) via
  `fontTools` `hmtx`/`cmap`, and applied to the real WVEMS corpus.
- Per-page shrink factors are the app's own recorded values from
  `page_fits.tsv` (produced by `test/widgets/page_fits_screen_test.dart`, which
  loads real Roboto).

Anything that could not be measured is written as **unknown**, not guessed.

---

## 1. The print's type system, measured

### 1.1 Size and family ladder (protocol prose pages, odd 3-95)

Every one of the 47 odd prose pages uses the same ladder — verified per page,
not extrapolated from a sample.

| role | face | size | ratio to body | pages carrying it |
|---|---|---|---|---|
| page number (corner tabs, x2) | Barlow SemiBold | 50 pt | 2.00 | 93/93 |
| section title / footer page title | **Barlow Bold** (not condensed) | 30 pt | 1.20 | 93/93 |
| **body** | **Barlow Condensed Regular** | **25 pt** | **1.00** | 93/93 |
| inline emphasis | Barlow Condensed **Bold** | 25 pt | 1.00 | 69/93 |
| drug names + dose numerals | **Encode Sans Bold** (a second family) | 25 pt | 1.00 | 69/93 |
| **units after a value** | Barlow Condensed Regular | **20 pt** | **0.80** | 67/93 |
| slashes, ampersands, parens | Barlow Condensed Regular | 22-23 pt | 0.88-0.92 | 93/93 |
| superscript ordinals, ®, † | Barlow Condensed Regular | 16.67 pt | 0.667 | 46/93 |
| subscript numerals (O2, EtCO2) | Barlow Condensed Medium | 15 pt | 0.60 | most prose pages |
| reference book title | Barlow Condensed *Italic* | 25 pt | 1.00 | 46/93 |
| URLs and `[Ver: …]` | Encode Sans Regular | 12 pt | 0.48 | 46/93 |
| source attributions / captions | Barlow Condensed Light or Encode Sans | 9-12 pt | 0.36-0.48 | 23 pages |
| rotated right-margin stamp | Barlow SemiBold | 10 pt | 0.40 | 93/93 |

Two structural points that matter more than the numbers:

- The section title is not merely "bigger and bolder". It changes **family
  width class** — Barlow Bold is roughly 28% wider per character than Barlow
  Condensed, so a 30 pt title against 25 pt condensed body is a far stronger
  step than 1.20x suggests.
- **Drug names and dose numerals switch family** to Encode Sans Bold. That is a
  third axis of emphasis the app has no equivalent for (see §3.4).

### 1.2 Leading (measured over all 47 prose pages, n = 806 line pairs)

| relationship | median pitch | ratio to 25 pt |
|---|---|---|
| within a wrapped bullet (continuation line) | 24.0 pt | 0.96 |
| top-level bullet -> its sub-bullet | 24.1 pt | 0.96 |
| **top-level bullet -> next top-level bullet** | **27.0 pt** | **1.08** |

> **Correction to an existing app comment.** `prose_block_view.dart` states
> *"The print puts no extra space between bullets at all (its bullet-to-bullet
> pitch equals its within-bullet wrap pitch), measured on PDF pp.11 and 71"*.
> Measured across all 47 prose pages that is true for continuations and for
> sub-bullets, but **false for top-level bullet to top-level bullet**: 27.0 pt
> vs 24.0 pt, mode 27 in 210 of 306 pairs. The print adds ~0.12 em between
> top-level bullets and nothing anywhere else. Two pages were not enough.

### 1.3 Bullet markers — two levels, two glyphs

Across the odd prose pages: **717 level-0 bullets set as `•`** and **419
level-1 bullets set as `-`** (hyphen) at a 4-space indent. Deeper levels are
essentially absent (a handful of 5-7 space continuations). The marker itself
carries the level; indent alone never does.

### 1.4 Line measure and wrapping

- Body measure runs x = 12 to ~588 pt: **~576 pt = 23.0 em** at 25 pt.
- Full lines carry **68-73 characters** (max per page ranges 67-73 over pp. 5-95).
- **The print never hyphenates.** Zero hyphenated line-ends across all 166
  pages. Copy is written to fit the measure instead.
- Text is set ragged-right, never justified (no inter-word stretching found).

### 1.5 Underline = hyperlink, and nothing else

Every visible underline in the book is a 2.25 pt band (1.08 pt for the 12 pt
URLs) drawn under a phrase that also carries a PDF link annotation. There is a
1:1 correspondence — on p.25, 16 underline bands and 16 link annotations, same
rectangles. **The print never underlines for emphasis.** Bold and underline are
strictly independent channels:

- **bold, not underlined** = emphasis (`**pit crew**`, `**30 min**`, `**ROSC**`)
- **underlined, not bold** = cross-reference to another protocol/policy
  (`Special Case` -> p.112, `Hypoglycemia` -> p.38)
- **bold + underlined** = a drug or procedure cross-reference
  (`Amiodarone` -> p.121, `compressions` -> p.101)

### 1.6 Superscripts and subscripts

- superscript `th`/`st`/`nd` at 16.67 pt (0.667) — the edition number in the
  Limmer citation on **46 of the 47 odd prose pages** (all except p.3, which
  carries no References section), and "1st Gen Ceph" on the drug pages.
- superscript `®` at 16.67-20 pt on brand names.
- superscript `†` at 13.33 pt on the back cover (p.166), 6 instances.
- subscript `2` at 15 pt (0.60) in O2 / SpO2 / EtCO2 / FiO2.

---

## 2. The app's type system, measured

Declared sizes (from source):

| role | widget / constant | size | ratio to prose body |
|---|---|---|---|
| prose body | `MiniMarkdown.fontSize` default | **14.0** | 1.00 |
| section title | `prose_block_view.dart:158` | 15.5 w800 | 1.107 |
| band-callout title | `band_callout_block_view.dart:53` | 15.5 | 1.107 |
| boxed-prose title | `prose_block_view.dart:62` | 15.0 w800 | 1.071 |
| attention-callout chip | `prose_block_view.dart:117` | 14.0 w800 | 1.00 |
| **table body** | `table_block_view.dart:32,465` `_fontSize` | **12.0** | **0.857** |
| bullet glyph | `mini_markdown.dart:289` | `fontSize * 0.95` w900 | 0.95 |
| sub-level indent | `mini_markdown.dart:266` | `level * fontSize * 0.9` | 12.6 px/level |
| line height | `kProseLineHeight` | 1.18 | — |
| gap below every unit | `kProseUnitSpacing` | 1.0 px | — |
| drug card name / body / footnote | `drug_card_block_view.dart` | 17 / 13 / 9 | — |
| procedure card | `procedure_card_block_view.dart` | 16 / 13.5 | — |
| flowchart node / branch / criteria / dose row | flowchart widgets | 16 / 15 / 12.5 / 11-12 | — |

Effective on-screen size on the Pixel-3a proxy (393 x 852 logical) after the
paged fit-scaler, from the app's own `page_fits.tsv`: **14 pages at 1.00, 7 at
0.95, 17 at 0.90, 7 at 0.85** — so real body type runs **11.9 to 14.0 px**.

**Measured measure (real Roboto, not Ahem):**

| | em measure | chars/line | avg advance |
|---|---|---|---|
| print body (Barlow Condensed 25 pt on 576 pt) | 23.0 em | 68-73 | 0.329 em |
| app @ scale 1.00 (Roboto 14 px on 351 px) | 25.1 em | 59.4 | 0.4222 em |
| app @ scale 0.85 (Roboto 11.9 px) | 29.5 em | 69.9 | 0.4222 em |

Roboto is **28% wider per character** than the print's Barlow Condensed on this
corpus. The app buys back the print's line length only by shrinking type to
0.85. **1016 prose bullets were measured; 424 of them (42%) wrap to more than
one line.**

Roboto Condensed already ships in Flutter's `material_fonts` cache (no new
asset): avg advance 0.3776 em, **66.4 chars/line at 14 px** — 12% more copy per
line at full size, i.e. most of the gap closed without shrinking anything.

---

## 3. Systematic differences — KEEP / DROP / ADAPT

### 3.1 Underline = cross-reference. **The app drops 82% of them.** — KEEP

The print underlines **1,284 internal cross-references** and 208 external links
across the book. On the 45 prose pages the app actually ships, the print
underlines **341 distinct cross-reference phrases**. Their fate in the app:

| fate in app | count | share |
|---|---|---|
| rendered as a tappable link (underlined) | **61** | 18% |
| rendered `**bold**`, not linked | **214** | 63% |
| rendered as plain body text | **66** | 19% |

This is the single largest typographic divergence in the book, and it is a
double fault:

1. A reader cannot get from Bradycardia to Atropine, or from CODE to
   Hypoglycemia, by tapping — the print's whole navigational spine is gone.
2. The 214 bolded ones **collide with the print's emphasis channel**. In print,
   bold and underline are orthogonal (§1.5). The app has collapsed two signals
   onto one, so "this word matters" and "this word is another protocol" now look
   identical. On p.43 the app bolds `Altered LOC`, `OD / Tox`, `Hypotension`,
   `Preeclampsia`, `Peds Reference` — every one of which the print sets in
   **regular weight with an underline**.

**KEEP.** The app's link rendering is already correct (`MiniMarkdown._parseInline`
underlines link spans, `mini_markdown.dart:174-178`) — it is simply not applied.
The mechanism exists; the authoring does not use it. Restoring the links also
restores the bold channel to meaning only emphasis.

**Where the print's links point** (358 distinct cross-references across all 47
odd prose pages, incl. the two the app does not ship):

| target range | count | share | app links to this range |
|---|---|---|---|
| protocol pages 4-95 | 192 | 54% | yes — all 61 of the app's links |
| **drug reference 118-143** | **89** | **25%** | **zero** |
| **procedures 96-108** | **38** | **11%** | **zero** |
| peds reference 144-161 | 33 | 9% | 3 |
| **policies 109-117** | **6** | **2%** | **zero** |

Verified by enumerating every `](topic:…)` target in
`assets/books/wvems/topics/*.yaml`: the app links only to protocol topics, plus
three links to `wvems-2026-144`. **Nothing in the app links to a drug, a
procedure or a policy** — which is 46% of the print's cross-reference graph and
the half a medic is most likely to need mid-call ("what dose of Amiodarone?",
"how do I do a pleural decompression?", "when may I terminate?").

### 3.2 Units set smaller than the value — **the app does not do this at all** — ADAPT

The print sets the unit at **0.80 of the number** (20 pt against 25 pt) —
**143 instances on the odd prose pages**, 301 across pp.3-95, plus 155 more on
the peds pages. `10 **mg** max`, `300 mg -> 150 mg`, `5 mg/kg`, `2 grams`,
`120 /min`, `40 mmHg`, `6 L/min`, `5 mcg/kg/min`, `28 lbs`.

Related smaller tiers in the same system: separators `/` and `&` at 0.88, parens
at 0.92, so a compound like `Ketamine (pain): 3 mg` steps down twice.

The app renders `**10 mg max**` at one flat size. Nothing in `MiniMarkdown`
supports a size change inside a run.

**ADAPT.** The intent — the numeral is the thing you read, the unit is a label
— survives a phone screen well, and at 11.9-14 px a 0.80 step is still legible
(9.5-11.2 px). But the print's exact 0.80 was chosen for 25 pt paper; on a
backlit 12 px body it is worth testing 0.85 before committing. Implementation
would be a new inline mark in `MiniMarkdown` (the parser already recurses, so a
`~unit~`-style span emitting a smaller `TextSpan` is a small change).

### 3.3 Superscripts and subscripts — **absent from the app** — ADAPT (super) / KEEP (sub)

- The app writes `EtCO2`, `SpO2`, `O2`, `FiO2` as ASCII (13 + 17 + 18 + 4
  occurrences). The print sets the `2` as a 15 pt subscript (0.60). **KEEP** —
  `O₂` is the clinically correct form and the app is currently rendering a
  chemically wrong string.
- `15th ed.` appears **37 times** in the app as plain text; the print
  superscripts `th` at 16.67 pt on every odd prose page. **ADAPT** — a
  superscripted ordinal in a citation is print convention; on a phone the
  citation line is the least important thing on the page and a raised 8 px
  glyph is close to unreadable. Setting it plain is defensible; setting the
  whole citation smaller (§3.7) is the better version of the same intent.
- `®` appears **109 times** in the app at full body size; the print sets it at
  16.67-20 pt (0.667-0.80). **ADAPT** — shrink it; a full-size ® next to a drug
  name is visually louder than the drug name's own emphasis.

### 3.4 Family switching (Encode Sans for drugs and doses) — DROP

The print uses **Encode Sans Bold** — a visibly wider, different family — for
drug names and dose numerals inside Barlow Condensed body text, on 69 of 93
pages. The app has one family throughout.

**DROP.** On paper at 25 pt a second family reads as a deliberate signal; at
12 px on a phone two sans families 0.05 em apart in width will read as an
accident. The same job is already done on screen by weight + the restored link
underline (§3.1), which is cheaper and unambiguous. Do not add a second font.

### 3.5 Italic — **the app cannot render it** — mixed

`MiniMarkdown` has no italic (`CLAUDE.md`: single-asterisk pairs render
literally). The print uses italic in exactly two places:

- **Reference book titles** — `Emergency Care` in Barlow Condensed Italic 25 pt,
  on all 46 odd prose pages that carry references. **DROP** — bibliographic
  italic on a phone citation buys nothing.
- **`< do not use >`** — 81 instances across peds pages 145-161, italic 20 pt,
  marking a drug that must not be given at that age. **This is a clinical
  signal, not a stylistic one, and it is currently unrepresentable.** KEEP the
  intent: it needs a distinct treatment (the app's existing danger/alert roles
  are the natural home). See §5.3.

### 3.6 Section title contrast — ADAPT

| | print | app |
|---|---|---|
| title : body size | 30 : 25 = **1.20** | 15.5 : 14 = **1.107** |
| title width class | Barlow Bold (~28% wider than body face) | same family |
| title weight | Bold | w800 |

The app's title is proportionally smaller **and** stays in the body's width
class, so the section step is materially weaker than print. The
`SectionBracket` (already an accurate 393/1275-scaled copy of the print's
bracket, p.71) carries most of the load instead.

**ADAPT.** Raising the title to ~16.8 px (1.20 x 14) restores the print ratio
at a cost of ~1.3 px per section — five sections a page, ~7 px total, well
inside the headroom the fit-scaler already has on 14 of the 45 paged prose
pages (those already fitting at 1.00).

### 3.7 Small print: URLs, `[Ver: …]`, attributions — ADAPT

The print drops URLs and version stamps to **12 pt (0.48 of body)** on every
prose page, and source attributions to 9-12 pt (0.36-0.48). The app renders the
whole reference bullet at body size, so a Medscape URL occupies the same visual
weight as a drug dose.

**ADAPT.** The print's 0.48 is too small at 12 px body (5.8 px). Keep the
intent — references must recede — with a References-section body size of
~0.8 x and the URL itself as a link (it already is).

### 3.8 Bullet markers and levels — ADAPT

Print: `•` for level 0 (717 instances), `-` for level 1 (419). App: `▪` at every
level, distinguished only by a 12.6 px indent.

**ADAPT.** Two glyphs are worth keeping — a sub-bullet that is only 12.6 px
inboard is easy to lose when a level-0 bullet has just wrapped. Use `•` / `–`
rather than the print's exact glyphs (`▪` is already heavier than the print's
round dot; that is a reasonable screen choice).

### 3.9 Leading — ADAPT (small, precise)

Within a line the app's `height: 1.18` on Roboto is the right analogue of the
print's 0.96 on Barlow Condensed: 1.18 is approximately Roboto's own
ascent+descent, i.e. also "set solid". That part is correct.

What is wrong is the **ratio between units**:

| | print | app |
|---|---|---|
| continuation / sub-bullet pitch | 24.0 pt | 14 x 1.18 + 1 = 17.5 px |
| top-level bullet -> top-level bullet | 27.0 pt | 17.5 px (same) |
| **ratio** | **1.125** | **1.00** |

**ADAPT.** `kProseUnitSpacing` is a single flat 1 px. It should be ~2 px before
a level-0 bullet and ~0 before a level-1 bullet or a continuation, which
reproduces the print's 1.125 : 1.00 relationship. (`_UnitLine` already knows the
unit's level — `mini_markdown.dart:256-260` — so this is a one-line change.)

### 3.10 Line measure — ADAPT

The app is 28% wider per character than print and pays for it by shrinking
17 of the 45 paged prose pages to 0.90 and 7 to 0.85. Roboto Condensed ships with Flutter
already and recovers 12% of that at no asset cost (§2).

**ADAPT.** A condensed body face is the print's actual choice (Barlow
*Condensed*, not Barlow) and it is what makes 68-73 character lines possible.
This is the highest-leverage single change available: it makes type *larger* on
screen by letting the fit-scaler run nearer 1.0.

### 3.11 Hyphenation — DROP (nothing to do)

The print never hyphenates (0 hyphenated line-ends in 166 pages). Flutter does
not hyphenate by default. Already aligned; do not add it.

### 3.12 Rotated margin furniture — DROP the form, KEEP the content

Every odd prose page carries a rotated 10 pt right-margin stamp:
`Reviewed: <Mon Year>` and `NEMSIS: <codes>`. Rotated marginalia is a paper
device (it uses the gutter, which a phone does not have).

**DROP** the rotation and the 10 pt size; **KEEP** the data. The app already
carries `last_reviewed:` in topic metadata and puts NEMSIS codes as a trailing
paragraph in References on most pages — that is the right adaptation. But see
§5.2: some pages carry the wrong codes and some carry none.

---

## 4. Per-page findings — protocol prose pages (odd 3-95)

Column key:
- **sections** — app section count / print section count (a 30 pt bold heading
  anywhere on the page, including the right-column boxes).
- **xrefs L/B/P** — the page's underlined cross-references, by what the app does
  with them: **L**inked / **B**old-only / **P**lain.
- **units** — runs the print sets at 0.80 of body (units after a value). The app
  sets none of them smaller, on any page.
- **bold** — print bold runs (Barlow Condensed Bold + Encode Sans Bold, body
  size) vs app `**…**` runs.
- **fit** — the app's own recorded shrink factor for that page.
- **parity** — print body lines with no app counterpart / app body lines with no
  print counterpart (fuzzy match at 0.72; section headings and the `Alias:` line
  excluded).

| page | sections app/print | xrefs L/B/P | URLs | units@0.80 | super+sub | bold print/app | fit | parity -/+ | NEMSIS |
|---|---|---|---|---|---|---|---|---|---|
| **3** | **ABSENT** | 0 / 0 / 0 | 3 | 3 | 10 | 24 / — | — | 25 / 0 | none in either |
| **5** | 5 / 5 | 0 / 5 / 0 | 2 | 0 | 3 | 8 / 19 | 0.85 | 0 / 0 | MISMATCH ['9914001', '9914011'] |
| **7** | 5 / 5 | 1 / 4 / 3 | 2 | 7 | 10 | 18 / 19 | 0.90 | 0 / 0 | OK |
| **9** | **ABSENT** | 0 / 0 / 0 | 3 | 7 | 4 | 18 / — | — | 31 / 0 | APP MISSING |
| **11** | 4 / 4 | 1 / 4 / 7 | 3 | 0 | 2 | 7 / 9 | 1.00 | 11 / 5 | OK |
| **13** | 4 / 6 | 1 / 4 / 6 | 3 | 0 | 3 | 13 / 9 | 1.00 | 18 / 9 | OK |
| **15** | 5 / 7 | 0 / 2 / 9 | 3 | 4 | 6 | 16 / 13 | 1.00 | 23 / 13 | OK |
| **17** | 6 / 6 | 2 / 4 / 0 | 3 | 0 | 2 | 10 / 14 | 0.90 | 0 / 0 | OK |
| **19** | 6 / 7 | 1 / 7 / 0 | 3 | 1 | 6 | 12 / 17 | 0.95 | 0 / 0 | APP MISSING |
| **21** | 5 / 5 | 0 / 6 / 6 | 2 | 9 | 10 | 24 / 20 | 0.90 | 0 / 1 | MISMATCH ['9914131'] |
| **23** | 5 / 5 | 3 / 4 / 0 | 1 | 0 | 2 | 9 / 8 | 1.00 | 4 / 0 | OK |
| **25** | 7 / 7 | 1 / 6 / 6 | 3 | 6 | 6 | 20 / 20 | 0.95 | 3 / 2 | APP MISSING |
| **27** | 5 / 5 | 2 / 5 / 2 | 3 | 4 | 5 | 12 / 16 | 1.00 | 0 / 0 | OK |
| **29** | 5 / 6 | 4 / 3 / 1 | 3 | 5 | 6 | 16 / 10 | 1.00 | 17 / 6 | OK |
| **31** | 4 / 5 | 1 / 6 / 8 | 4 | 7 | 11 | 14 / 13 | 1.00 | 20 / 14 | OK |
| **33** | 5 / 6 | 0 / 8 / 3 | 2 | 1 | 4 | 16 / 19 | 1.00 | 16 / 11 | OK |
| **35** | 4 / 4 | 4 / 5 / 0 | 1 | 0 | 1 | 7 / 13 | 1.00 | 0 / 0 | MISMATCH ['9914061', '9914109'] |
| **37** | 5 / 5 | 2 / 2 / 0 | 3 | 0 | 1 | 20 / 13 | 0.95 | 0 / 0 | APP MISSING |
| **39** | 5 / 5 | 0 / 7 / 2 | 2 | 3 | 4 | 22 / 13 | 1.00 | 20 / 11 | OK |
| **41** | 5 / 5 | 1 / 5 / 7 | 1 | 1 | 3 | 20 / 11 | 1.00 | 15 / 11 | MISMATCH ['9914135', '9914215', '9914217', '9914219'] |
| **43** | 5 / 5 | 3 / 9 / 1 | 1 | 6 | 8 | 14 / 18 | 0.90 | 0 / 0 | OK |
| **45** | 7 / 13 | 0 / 2 / 0 | 2 | 0 | 8 | 12 / 20 | 0.85 | 1 / 7 | OK |
| **47** | 5 / 5 | 0 / 4 / 1 | 2 | 1 | 4 | 19 / 12 | 1.00 | 16 / 11 | OK |
| **49** | 4 / 4 | 2 / 3 / 0 | 2 | 2 | 3 | 22 / 23 | 0.90 | 0 / 0 | MISMATCH ['9914145', '9914155'] |
| **51** | 7 / 7 | 0 / 4 / 0 | 3 | 11 | 12 | 24 / 25 | 0.85 | 12 / 6 | MISMATCH ['9914133', '9914145', '9914163'] |
| **53** | 8 / 7 | 1 / 5 / 0 | 2 | 7 | 3 | 19 / 20 | 0.90 | 1 / 0 | APP MISSING |
| **55** | 7 / 6 | 0 / 7 / 1 | 2 | 5 | 6 | 9 / 15 | 0.90 | 1 / 0 | OK |
| **57** | 7 / 6 | 1 / 4 / 0 | 1 | 1 | 2 | 17 / 21 | 0.85 | 1 / 0 | OK |
| **59** | 7 / 6 | 1 / 8 / 0 | 3 | 0 | 1 | 12 / 17 | 0.85 | 1 / 0 | APP MISSING |
| **61** | 4 / 4 | 0 / 5 / 0 | 1 | 2 | 7 | 14 / 17 | 0.90 | 0 / 0 | MISMATCH ['9914107'] |
| **63** | 5 / 4 | 3 / 5 / 0 | 1 | 0 | 1 | 19 / 21 | 0.90 | 1 / 0 | OK |
| **65** | 5 / 4 | 2 / 2 / 0 | 2 | 0 | 1 | 15 / 16 | 1.00 | 1 / 0 | OK |
| **67** | 6 / 5 | 1 / 4 / 0 | 2 | 0 | 1 | 18 / 18 | 0.90 | 1 / 0 | OK |
| **69** | 4 / 4 | 2 / 3 / 0 | 3 | 0 | 2 | 30 / 28 | 0.90 | 0 / 0 | MISMATCH ['9914029'] |
| **71** | 6 / 12 | 2 / 6 / 0 | 1 | 1 | 2 | 20 / 25 | 0.90 | 4 / 3 | OK |
| **73** | 4 / 4 | 3 / 4 / 0 | 2 | 1 | 5 | 14 / 20 | 0.90 | 0 / 0 | OK |
| **75** | 4 / 7 | 0 / 1 / 0 | 2 | 0 | 1 | 9 / 12 | 1.00 | 0 / 6 | OK |
| **77** | 6 / 6 | 4 / 4 / 0 | 1 | 0 | 2 | 9 / 13 | 0.85 | 2 / 1 | OK |
| **79** | 5 / 5 | 0 / 6 / 1 | 4 | 8 | 9 | 24 / 25 | 0.90 | 0 / 0 | APP MISSING |
| **81** | 6 / 6 | 2 / 8 / 1 | 1 | 13 | 12 | 18 / 22 | 0.95 | 0 / 0 | APP MISSING |
| **83** | 8 / 8 | 0 / 4 / 0 | 3 | 0 | 1 | 14 / 17 | 0.90 | 1 / 1 | OK |
| **85** | 6 / 6 | 3 / 2 / 0 | 2 | 2 | 2 | 21 / 22 | 0.95 | 0 / 0 | OK |
| **87** | 8 / 8 | 2 / 9 / 0 | 2 | 5 | 6 | 21 / 21 | 0.90 | 2 / 1 | OK |
| **89** | 8 / 6 | 0 / 3 / 1 | 4 | 2 | 3 | 29 / 25 | 0.90 | 5 / 3 | OK |
| **91** | 6 / 6 | 3 / 8 / 0 | 2 | 5 | 6 | 16 / 17 | 0.95 | 0 / 0 | OK |
| **93** | 6 / 6 | 2 / 3 / 0 | 2 | 5 | 6 | 12 / 16 | 0.95 | 0 / 0 | OK |
| **95** | 8 / 7 | 0 / 4 / 0 | 1 | 8 | 21 | 16 / 18 | 0.85 | 3 / 1 | APP MISSING |

**Reading the table.** Three shapes appear:

- **Pages at parity** (5, 7, 17, 21, 27, 35, 37, 43, 49, 53-73, 77-95):
  parity -/+ of roughly 1-3 / 5-10, where the misses are the `Alias:` line and
  the Limmer citation and the extras are the app's added alert callouts. These
  pages were transcribed.
- **Pages that were rewritten, not transcribed** (11, 13, 15, 29, 31, 33, 39,
  41, 45, 47, 51): 12-24 print lines with no counterpart and 10-19 app lines
  with no print source. See §5.1.
- **Pages absent entirely** (3, 9). See §5.1.

Every page in the book shows the same *systematic* gaps regardless of shape:
zero units set smaller, zero superscripts/subscripts, and the majority of
cross-references de-linked.
---

## 5. Text parity — what is in print and not in the app, and vice versa

Totals over the odd prose pages 3-95, line-level fuzzy match at 0.72, with
section headings, the `Alias:` line and the NEMSIS trailer excluded:

- **256 print body lines have no counterpart in the app.**
- **123 app body lines have no source in the print.**

### 5.1 Whole pages and whole sections that are missing

**Two entire prose pages are absent from the app:**

| PDF page | title | print sections | status |
|---|---|---|---|
| **3** | *How To Use* | 10 run-in headings, 25 body lines, 24 bold runs | no app topic; `wvems_2026_about.yaml` covers p.2 only |
| **9** | *Circulation / Shock* | Shock Imperatives · Poor Perfusion · Medication · Notes · Pediatrics · References — 31 body lines, 9 cross-references, 7 units | `wvems_2025_008.yaml` declares `page_number: 8` only. The flowchart page shipped; the prose page did not. |

p.3 is the book's own instructions for reading itself (what bold means, that
protocols are a tool box not a cookbook, that Basic procedures are assumed, when
to call Medical Direction). p.9 is the Shock protocol's entire text page.

**Sections dropped from pages that otherwise shipped:**

| page | dropped |
|---|---|
| 13 | *Poor Perfusion*, *Notes* |
| 15 | *Poor Perfusion*, *Critical Arrhythmia* |
| 19 | *Hyper K+ EKG* (the app's *K+ EKG Changes* covers part of it) |
| 29 | *PDE5 Inhibitors* |
| 31 | *Notes* |
| 33 | *Poor Perfusion* |
| 45 | the seven Cincinnati/VAN item headings (restructured into two app blocks) |
| 71 | the rule-of-nines numerals on the body diagram (`9 / 18 / 9 …`) |
| 75 | *Rattlesnake*, *Copperhead*, *Black Widow* headings (the app keeps the three photos and their captions but not the headed ID boxes) |

*Poor Perfusion* is the same shared criteria box the print repeats on pp.5, 9,
13, 15, 17, 33, 55, 57, 59, 83. The app carries it on some pages and not others,
so the same clinical construct is present in one protocol and absent in the next.

### 5.2 Rewritten rather than transcribed

On eleven pages the app's body text is not the print's text. Examples, all
verifiable in Appendix A:

- **p.11 Hypertension — the whole *Notes* section is different copy.** Print
  lists eight `Consider <protocol>` cross-reference bullets (Cardiac, Dyspnea &
  CHF, OD/Tox, Stroke, Behavioral, Head Injury, Malignant HTN, Pulmonary Edema)
  plus "Ask about new or recent changes to cardiac or BP medications". The app
  replaces all of it with two invented bullets about beta-blockers and cocaine.
  References differ too: print cites ACLS, PALS, Medscape 2172054, Limmer ch.13;
  app cites Medscape 1952052 and Limmer ch.17.
- **p.13 Bradycardia** — print's *Notes* (pacing at 80 bpm / 80 mA, pads on any
  unstable patient, treat pain from pacing, single-pill overdoses, maternal
  medication in breast milk, Ca2+/beta-blocker overdose) is gone; the app
  substitutes generic pacing advice.
- **p.15 Tachycardia** — print's rate thresholds *Adult(14+) 150 /min, Child
  (1-13) 180 /min, Infant (<1) 220 /min*, and *Cardiovert: enable SYNC, start at
  200 J, defib if unable to SYNC*, are absent. The app substitutes QRS-width
  criteria the print does not state.
- **p.31 Dyspnea** — print: *"Contraindicated if recent (36 h) use of any PDE5
  inhibitor"*; app: *"Do not give within 24 h of PDE5 inhibitors"*. Print brand
  for Albuterol is *Ventolin®*; the app writes *Proventil®*. Print's Magnesium
  bullet and dose line (`1 gram IV/IO over 10 min`) are absent.

These are content defects surfaced by a typography audit, not typography
defects. Flagging them here because the brief asks for every omission and
addition; the clinical-content stream should own the fixes.

### 5.3 Text present in print with no representable form in the app

- **`< do not use >`** — 81 instances on peds pages 145-161, set in italic.
  Marks a drug that must not be given at that age band. `MiniMarkdown` has no
  italic, so this cannot currently be rendered as anything but plain text
  identical to a dose.
- **Rotated margin stamps** — `Reviewed:` and `NEMSIS:` (see §5.4).
- **Superscript / subscript** — see §3.3.

### 5.4 `Reviewed:` and NEMSIS codes

The print stamps both on every odd prose page. Comparing print margin against
app content:

- **9 pages carry no NEMSIS codes in the app at all**: 9, 19, 25, 37, 53, 59,
  79, 81, 95.
- **8 pages carry wrong or truncated codes**: p.5 (app `9914011`, print
  `9914001`), p.21 (app adds `9914131`), p.35 (app `9914061`, print `9914109`),
  p.41 (app truncated to `9914043,` — four codes lost), p.49 (app `9914145`,
  print `9914155`), p.51 (app `9914145`, print `9914133, 9914163`), p.61 (app
  truncated to `9914073,`), p.69 (app adds `9914029`).
- 30 pages match exactly.

`Reviewed:` is carried correctly as `last_reviewed:` topic metadata.

### 5.5 Punctuation and glyph hygiene

| glyph class | print (pp.3-95) | app |
|---|---|---|
| apostrophe / quotes | 71 `’`, 9 `“`, 9 `”`, 1 `‘`; only 10 straight | **0 curly, 92 straight `'`** |
| en / em dash | **0** | 200 `–`, 305 `—` |
| arrow | 6 `￫` (MS-PGothic) | 30 `→` |
| `≤` `≥` `°` | 6 / 1 / 19 | 8 / 9 / 19 |
| fi / fl ligature | 72 / 25 (as ligature codepoints) | plain `fi`/`fl` — Roboto applies `liga` automatically, no defect |

**ADAPT.** The app's arrow, `≤`, `≥`, `°` and dash usage is good — better than a
literal copy would be, since the print's `￫` comes from a Japanese fallback
font. Two things to fix: use typographic apostrophes (`’`) to match print, and
note that the em-dash is an app invention — the print writes `• ACLS:` where the
app writes `- ACLS — `. Harmless, but it is an addition, not a transcription.

---

## 6. Appendices — do they differ? Yes, in four measurable ways

Sampled: pp.1-2 (cover index / How To Use spread), 96-108 (procedures),
109-117 (policies), 118-143 (drug reference), 144-161 (peds reference),
162-165 (index), 166 (back cover).

### 6.1 Index pages (1, 96, 109, 118, 144) — link density explodes

| page | role | underlined cross-references |
|---|---|---|
| 1 | cover contents | **101** |
| 96 | Procedures index | 13 |
| 109 | Policies index | 8 |
| 118 | Drug Reference index | **73** (every drug, name + page number) |
| 144 | Peds Reference index | **65** |

Whole-book totals: **1,284 internal link annotations + 208 external**. On these
index pages the underline is set on **bold** text (page numbers and drug names),
which is the only place in the book where bold+underline is the default rather
than the exception.

The app replaces all five with different structures: a book-level index view
(`book.yaml: view: "index"`), one `wvems_2026_096.yaml` topic of
`procedure_card` blocks for 13 printed pages, one `wvems_2026_144.yaml` for 18,
and a dedicated `drug_index_screen.dart`. **ADAPT** — a scrolling index is the
right screen form; but the print's per-entry link is exactly what the app's
index gives back, so this is the one place where the app's navigation is at
parity or better.

### 6.2 Drug pages 119-143 — same ladder, one deliberate exception

Body 25 pt Barlow Condensed, units 20 pt (0.80), drug name **30 pt Encode Sans
Bold** reversed out white, brand **30 pt Barlow Regular** reversed out white with
a superscript `®` at 20 pt, `Use` / `Caution` / `Notes` rotated 90° in 30 pt
Barlow Bold, cross-references to protocols underlined in regular weight. (The
generic/brand pair is set at the *same size* but in two different families — the
same Encode-Sans-for-drugs rule as §3.4, used here as the card's whole identity.)

**The exception: URLs on drug pages are set at 20 pt, not the 12 pt used on
protocol pages** (51 spans, all Encode Sans Regular 20 pt). The Medscape link is
a primary affordance on a drug card, and the print sizes it accordingly.

App equivalent: `drug_card_block_view.dart` — name 17, brand 12.5, body 13,
footnote 9. Ratios 1.31 / 0.96 / 1.00 / 0.69 against the card body, against
print's 1.20 / 1.20 / 1.00 / 0.80. **The app's brand name is smaller than its
body text; the print's is 1.2x larger.**

### 6.3 Peds Reference pages 145-161 — a different unit tier

These 17 age-band cards do **not** use the protocol pages' 0.80 unit step. They
use **0.88 (22 pt)** — 865 instances, against 155 at 0.80 and 17 at 0.75. Units
and parenthetical qualifiers alike drop to 22 pt: `mg`, `mL`, `mcg`, `grams`,
`J`, `/min`, `mmHg`, `(allergy)`, `(brady/code)`, `(pain)`, `(RSI)`, `(IO)`,
`(blue)`, `(gray)`, `(1/10)`, `(50 mg/mL)`.

They also carry:
- zero cross-reference underlines (0 links on pp.145-161) — the index page 144
  does all the linking;
- an italic **`< do not use >`** at 20 pt, 81 instances (§5.3);
- a 12 pt Barlow Condensed Light attribution footer ("Adapted from 2022 Handtevy
  Pediatric Emergency Standards, Inc. Reproduced with permission.");
- a two-part page tab: a 60 pt numeral with a smaller `YR` beside it.

**KEEP the 0.88.** The distinction is real and deliberate: on a dense dose table
every line is a value + unit, so an aggressive 0.80 step would make the whole
page look like it was set in two sizes at random. 0.88 is enough to
de-emphasise without fragmenting.

### 6.4 Index pages 162-165 — an entirely separate scale

Four pages set almost wholly at **10 pt** (2,686 of 2,736 spans), in Barlow
Medium / Roboto Regular / Barlow Italic, three columns, with italic used for the
connectives `see`, `in`, `for`. That is 0.40 of the protocol body size — the
only place in the book where a *different type scale* is used rather than a
different tier of the same scale. No app equivalent (the app substitutes
search). **DROP** — a printed back-of-book index is a paper artefact; search
replaces it.

### 6.5 Back cover 166 — superscript daggers

Six superscript `†` at 13.33 pt keyed to editor credits, plus a `mailto:` link.
No app equivalent. **DROP.**

### 6.6 Tables — the print does NOT shrink table type; the app does

Measured on the print's three in-prose tables:

| page | table | body size inside the table |
|---|---|---|
| 37 | Glasgow Coma Scale | 25 pt — same as prose body |
| 51 | APGAR | 25 pt — same as prose body |
| 83 | Shock Index | 25 pt — same as prose body |

Only the *citation* under the GCS table drops (9 pt Encode Sans, "Teasdale, SG
glasgowcomascale.org").

The app's `TableBlockView._fontSize` is **12** against a prose body of 14 —
a 0.857 step the print does not have. After the paged fit-scaler on a 0.85 page
that is **10.2 px**, versus 11.9 px for the prose around it.

**ADAPT.** Table cells are short and columns are narrow on a phone, so some
reduction is defensible where prose gets a full-width measure. But 0.857 is not
derived from the print, and on the GCS / APGAR / Shock Index tables — which are
scored, numeric, and read under pressure — the print's answer is explicitly "no
reduction". At minimum these three should be set at prose size.

---

## 7. Even-numbered flowchart pages (4-94) — brief

Not the focus of this audit (they are diagrams, and the flowchart stream owns
them), but measured for completeness:

- Node text is **Barlow Medium 30 pt** — a *heavier and larger* face than the
  prose body, not smaller. Severity band headings are Barlow Bold 30 pt; drug
  names inside nodes are Encode Sans Bold 30 pt; criteria lists drop to Barlow
  Condensed 25 pt; dose-table units to 20-23 pt.
- Cross-references are underlined here too (e.g. p.6: `Ventilator`→p.80,
  `Airway`→p.4, `Dyspnea`→p.30; p.8: nine of them including three bold drug
  links). **370 distinct underlined cross-references across the 46 even pages.**
  The app *does* support this — `flowchart_view.dart:985,1099` underlines any
  node carrying `link_id`, using the same underline-means-link rule as prose —
  and the WVEMS YAML uses it **88 times**. So even pages carry ~24% of the
  print's flowchart cross-reference graph, better than the 18% on prose pages
  but the same shortfall. As on prose pages, none of the 88 point at a drug,
  procedure or policy topic.
- App equivalents: `flow_node.dart` 16 px, `branch_column.dart` 15 / 12.5 / 13,
  `dose_table.dart` 11-12, `algorithm_flowchart_view.dart` 10.5-13.5. Against a
  14 px prose body the app's node text is 1.14x; print's is 1.20x — the same
  under-contrast as §3.6.
- Even pages carry **no** `Reviewed:`/NEMSIS margin stamp, no references, no
  italic and no 12 pt tier. Those belong to the odd page of each spread.

---

## 8. Summary of systematic differences

| # | difference | evidence | verdict |
|---|---|---|---|
| 1 | Underline = cross-reference; app links only 18% of them, bolds 63%, drops 19% | 341 phrases on 45 pages; 1,284 internal links book-wide | **KEEP** |
| 2 | Bold and underline are orthogonal in print; the app has collapsed them | §3.1, p.43 worked example | **KEEP** |
| 3 | Units set at 0.80 of the value (301 runs pp.3-95) | §3.2 | **ADAPT** |
| 4 | Subscript `2` in O2/SpO2/EtCO2/FiO2 (app writes ASCII, 52 occurrences) | §3.3 | **KEEP** |
| 5 | Superscript ordinals (`15th`, 37 occurrences) and `®` (109) | §3.3 | **ADAPT** (shrink ®; leave ordinals plain) |
| 6 | Second family (Encode Sans Bold) for drugs and dose numerals | 69/93 pages | **DROP** |
| 7 | Italic for reference book titles | 46 pages | **DROP** |
| 8 | Italic for `< do not use >` on peds cards | 81 instances | **KEEP the intent** (app has no italic; use a danger role) |
| 9 | Section title 1.20x body and a wider family; app is 1.107x, same family | §3.6 | **ADAPT** |
| 10 | URLs / `[Ver:]` / attributions at 0.36-0.48; app sets them at body size | §3.7 | **ADAPT** |
| 11 | Two bullet glyphs for two levels (`•` 717, `-` 419); app uses one | §3.8 | **ADAPT** |
| 12 | Extra 0.12 em only between top-level bullets (27.0 vs 24.0 pt) | n=806 line pairs | **ADAPT** |
| 13 | 23.0 em / 68-73 char measure in a condensed face; app is 25.1 em / 59 chars in Roboto and shrinks 24 of 45 pages to compensate | §2, real-TTF measurement | **ADAPT** (Roboto Condensed already in the Flutter cache) |
| 14 | No hyphenation anywhere | 0 in 166 pages | already aligned |
| 15 | Rotated 10 pt margin stamp (`Reviewed:` / NEMSIS) | 93 pages | **DROP the form, KEEP the data** |
| 16 | Print does not shrink table type; app sets tables at 0.857 | pp.37, 51, 83 all 25 pt | **ADAPT** |
| 17 | Peds cards use a 0.88 unit tier, not 0.80 | 865 vs 155 instances | **KEEP** the distinction |
| 18 | Typographic apostrophes (71 curly, 10 straight); app is 92 straight, 0 curly | §5.5 | **ADAPT** |
| 19 | Back-of-book index at a separate 10 pt scale | pp.162-165 | **DROP** |

### The four that matter most, in order

1. **Restore the cross-reference links** (§3.1). 280 of 341 links are missing
   and the substitute (bold) has broken the emphasis channel. This is both a
   navigation loss and a typographic one.
2. **Ship pages 3 and 9** (§5.1). An entire protocol's prose page and the book's
   own instructions are absent.
3. **Move to a condensed body face** (§3.10). It is what the print does, it costs
   nothing (already in the Flutter cache), and it makes type *bigger* on screen
   by relieving the fit-scaler.
4. **Give units their own size** (§3.2). 301 runs on the protocol pages alone,
   and it is the print's clearest signal that the numeral is what you read.

---

## 9. What could not be measured — stated as unknown

- **On-device rendered size.** All app figures are logical pixels on the 393x852
  Pixel-3a proxy the project targets, using the app's own recorded fit factors.
  Physical rendered size on Grey's actual device is **unknown** (not measured).
- **Whether the print's 25 pt body is viewed at 100%.** The page is 8.5x14 in;
  whether the book is issued at that trim or reduced is **unknown**, so all
  print sizes here are stated as ratios as well as points.
- **Barlow Condensed's exact per-character advance.** Derived from the PDF
  (576 pt of measure / 68-73 characters / 25 pt = 0.329 em/char) rather than from
  the font binary, which is subset-embedded. Accurate to about ±3%.
- **Colour of type.** Out of scope by instruction, and not audited; the only
  colour fact recorded is that drug-card names/brands are reversed out white
  (needed to describe the size hierarchy).
- **Rendered leading in the app.** `height: 1.18` is stated as declared;
  the resulting pixel pitch was computed, not measured in a live frame, because
  a widget test would have measured Ahem.
- **The app's flowchart pages** were surveyed only at the level of declared font
  sizes; no per-node parity check was run against the print.

---

## Appendix A — per-page evidence (odd prose pages 3-95)

Generated from the extractions described in *Method*. For each page: the print's
section headings, the app's, every underlined cross-reference with its target
page and what the app does with it, the runs the print sets at 0.80, every
superscript/subscript, and the unmatched lines in both directions.

Two caveats on reading the raw rows:

- The `super/sub` detector compares a span's vertical centre against the tallest
  spans on the same line. On a **run-in heading** (a 30 pt section title with
  25 pt body continuing on the same line, e.g. p.3 "**Protocols** mean you
  **can**…") it therefore labels the ordinary 25 pt body as `sub`. Entries at
  `@25.00` are that artefact; the real superscripts and subscripts are the ones
  at 15, 16.67, 20 and 13.33 pt.
- Unmatched-line counts use a 0.72 fuzzy threshold, so a line the app reworded
  slightly can appear on both sides. The narrative in §5 was checked by hand
  against the rendered pages; the rows here are the raw evidence behind it.


### p.3
- print sections: How To Use · Welcome to the WVEMS Protocols · Basic procedures are assumed for every call. · Call for online Medical Direction at any time for advice on: · Protocols mean you can, but not always that you should. · Severity is a subjective judgement that requires thought. · Presume routine things when appropriate, like: · Pediatric considerations are included in every protocol. · Critical Care(CC) is for credentialed paramedics only. · References are included. This text is not comprehensive.
- app sections: **PAGE ABSENT FROM APP**
- underlined xrefs (1): Peds Reference→p144
  - LINKED in app: none
  - bold-only in app: none
  - plain in app: none
- units set smaller (3): (, kg), lbs
- super/sub (10): sub 'can'@25.00, sub '.'@25.00, sub 'is a'@25.00, sub '2'@15.00, sub '2'@15.00, sub 'lbs'@20.00, sub '('@20.00, sub 'kg)'@20.00, sub '(CC)'@20.00, sub '.'@25.00
- print lines with no app counterpart (25):
    - • Think of this like a tool box, not a cookbook.
    - • You should use several protocols at the same time on every call.
    - • You may use any intervention marked for your level or lower.
    - • Don’t forget: scene safe, BSI, ABC’s, call for ALS, notify the ED, etc.
    - • Every patient should have a full assessment including vital signs.
    - • Ask about medical allergies and pregnancy before giving meds.
    - • Any questions, problems, or if uncertain for any reason.
    - • Getting permission to deviate from these protocols.
    - • If unable to contact, remember: get the patient to the hospital.
    - • Use only enough to stabilize and/or improve. Don’t follow blindly.
    - • Skip anything unnecessary. Not every box needs to be completed.
    - • The listed order suggests importance, but it is not absolute.
    - • Not all decisions are black and white. Use this text as a guide.
    - • Reassess and restart protocols as needed during a call.
    - • Use good clinical sense to decide what takes precedence.
    - • SpO2, EKG, EtCO2, glucometer, saline lock, phlebotomy, etc.
    - • Regular layperson ﬁrst aid treatments like splinting & band-aids.
    - • Note: protocols may also include reminders (like “12-Lead”).
    - • Patients 14 y/o and over (14+) are generally given adult therapy.
    - • Children ( 1 - 13 y/o) and Infants ( < 1 y/o) are considered peds.
    - • Use Peds Reference for peds dosing & adults under 110 lbs(50 kg).
    - • Provider’s responsibility to maintain mandatory prerequisites.
    - • Must be approved for that speciﬁc protocol by the agency OMD.
    - • All deadlines expire on the last day of the month (a grace period).
    - • Medications may appear as brand name®or generic.
- app lines with no print counterpart (0):

### p.5
- print sections: Airway Imperatives · Poor Perfusion · Notes · Pediatrics · References
- app sections: Airway Imperatives · Poor Perfusion · Notes · Pediatrics · References
- underlined xrefs (5): BIAD→p100(bold), BIAD→p100, Back Blows & Abd. Thrusts→p98, NPA→p99, BIAD→p100, Intubation→p78, OG-Tube→p100
  - LINKED in app: none
  - bold-only in app: biad, back blows & abd. thrusts, npa, intubation, og-tube
  - plain in app: none
- units set smaller (0): 
- super/sub (3): sub '2'@15.00, sub '2'@15.00, super(flag) 'th'@16.67
- print lines with no app counterpart (0):
- app lines with no print counterpart (0):

### p.7
- print sections: Breathing Imperatives · BVM Rate · Notes · Pediatrics · References
- app sections: Breathing Imperatives · BVM Rate · Notes · Pediatrics · References
- underlined xrefs (8): Neonate→p50, Neonates→p50, trunk→p64, Pleural Decompress→p100, Hypotension→p8, BVM→p99, NIPPV→p99, Ventilator→p80
  - LINKED in app: neonate
  - bold-only in app: pleural decompress, bvm, nippv, ventilator
  - plain in app: neonates, trunk, hypotension
- units set smaller (7): %, /, L/min, mmHg
- super/sub (10): super(flag) 'th'@16.67, sub '2'@15.00, sub 'mmHg'@20.00, sub '2'@15.00, sub '2'@15.00, sub '2'@15.00, sub '%'@20.00, sub '2'@15.00, sub '%'@20.00, sub '2'@15.00
- print lines with no app counterpart (0):
- app lines with no print counterpart (0):

### p.9
- print sections: Shock Imperatives · Poor Perfusion · Medication · Notes · Pediatrics · References
- app sections: **PAGE ABSENT FROM APP**
- underlined xrefs (16): Bradycardia→p12, Tachycardia→p14, Cardiac→p28, Anaphylaxis→p32, Diabetic→p38, Overdose / Tox→p40, Major Trauma→p56, Exposure→p68, Peds Reference→p144, trauma→p56, Pressors→p82, Blood→p84, NS Bolus→p138(bold), Epi Drip→p129(bold), STEMI→p28, Dopamine→p127(bold)
  - LINKED in app: none
  - bold-only in app: none
  - plain in app: none
- units set smaller (7): gtt/mL, mL, mcg/mL, mg
- super/sub (4): super(flag) 'th'@16.67, sub 'mL'@20.00, sub 'mg'@20.00, sub 'mL'@20.00
- print lines with no app counterpart (31):
    - • Consider underlying causes:
    - • Suspect if several of these:
    - - Bradycardia, Tachycardia
    - - Altered Mental Status
    - - Cardiac, Anaphylaxis
    - - Skin Pale, Cool, Diaphoretic
    - - Diabetic, Overdose / Tox
    - - Tachycardia, Hypotension
    - - Major Trauma, Exposure
    - - Dyspnea, Tachypnea
    - • NS Bolus (0.9% Saline): indicated for poor perfusion.
    - - Monitor for edema & rales before & after ﬂuid administration.
    - • Epi Drip (Epinephrine): Mix bag of 1 mcg/mL and use as follows:
    - - Add 1 mg Epi into 1,000 mL bag -or- 0.5 mg in 500 mL bag of NS
    - - Adults (14+ y/o): Use a macro drip (10 or 15 gtt/mL) set.
    - - Peds(0-13 y/o): Use a micro drip (60 gtt/mL) set.
    - - Start at 1 drop per second and titrate as needed.
    - - Avoid Epi if active chest pain and conﬁrmed STEMI.
    - • Dopamine (Intropin®): for medical causes refractory to Epi.
    - - Use a micro drip (60 gtt/mL) set. May titrate up to 4x if needed.
    - - Average adults start around 1 drop every 5 sec (with micro set).
    - • Use balanced resuscitation in trauma. Pressors are a last resort.
    - • Mean Arterial Pressure (MAP) is a better indicator when available.
    - - Consider Pressors or Blood if indicated and credentialed for CC.
    - • The majority of peds decompensation is airway related.
    - • Fluids are important for hypotension. Pressors are a last resort.
    - • Use Peds Reference or other approved source for peds dosing.
    - • ACLS: https://www.ahajournals.org/doi/10.1161/CIR.0000000000001376
    - • PALS: https://www.ahajournals.org/doi/full/10.1161/CIR.0000000000001368
    - • Medscape Vitals: https://emedicine.medscape.com/article/2172054
    - • Limmer D, O’Keefe MF. Emergency Care 15th ed. Chapter 7, 29
- app lines with no print counterpart (0):

### p.11
- print sections: Hypertension Imperatives · Notes · Pediatrics · References
- app sections: Hypertension Imperatives · Notes · Pediatrics · References
- underlined xrefs (12): Pain→p20, Pregnancy→p48, Seizures→p42, Preeclampsia→p92, Cardiac→p28, Dyspnea→p30, OD/Tox→p40, Stroke→p44, Behavioral→p46, Head Injury→p62, Malignant HTN→p92, Pulmonary Edema→p90
  - LINKED in app: pain
  - bold-only in app: pregnancy, seizures, preeclampsia, stroke
  - plain in app: cardiac, dyspnea, od/tox, behavioral, head injury, malignant htn, pulmonary edema
- units set smaller (0): 
- super/sub (2): sub 'mmhg'@15.00, super(flag) 'th'@16.67
- print lines with no app counterpart (11):
    - • Many other underlying causes can result in signiﬁcant HTN.
    - - Consider Cardiac pathology if any chest pain.
    - - Consider Dyspnea and CHF if any rales or pedal edema.
    - - Consider OD/Tox if any recent stimulant or illicit drug use.
    - - Consider Stroke if any acute focal neurologic deﬁcits.
    - - Consider Behavioral if anxiety from recent emotional triggers.
    - - Consider Head Injury if any history of trauma or signs of injury.
    - • Ask about new or recent changes to cardiac or BP medications.
    - • Pathologic HTN is unlikely in peds. Treat underlying causes.
    - • ACLS: https://www.ahajournals.org/doi/10.1161/CIR.0000000000001376
    - • PALS: https://www.ahajournals.org/doi/full/10.1161/CIR.0000000000001368
- app lines with no print counterpart (5):
    + - Beta-blocker use prior to **Cocaine** can result in unopposed alpha
    + stimulation — significantly worsens HTN and may cause cardiac ischemia.
    + - Hypertensive emergencies require careful titrated therapy in the ED.
    + - Hypertension is unusual in peds — investigate the underlying cause.
    + - Use **Peds Reference** or other approved source for peds dosing.

### p.13
- print sections: Bradycardia Imperatives · Poor Perfusion · Medications · Notes · Pediatrics · References
- app sections: Bradycardia Imperatives · Medications · Pediatrics · References
- underlined xrefs (11): Neonate→p50, Breathing→p6, Overdose→p40, Peds Reference→p144, Hypothermia→p68, Overdose→p40, Hyperkalemia→p18, Pacing→p105, Pain→p20, Anxiety→p46, Atropine→p123(bold), Epi→p128(bold), Atropine→p123(bold)
  - LINKED in app: hyperkalemia
  - bold-only in app: overdose, pacing, atropine, epi
  - plain in app: neonate, breathing, peds reference, hypothermia, pain, anxiety
- units set smaller (0): 
- super/sub (3): super(flag) 'th'@16.67, sub '2'@15.00, super(flag) '2+'@16.67
- print lines with no app counterpart (18):
    - • Suspect if several of these:
    - - Altered Mental Status
    - - Skin Pale, Cool, Diaphoretic
    - - Hypotension, Orthostasis
    - - Dyspnea, Tachypnea
    - • Atropine: less effective with: heart transplant, 3° heart block
    - • Epi (Epinephrine): Preferred agent over Atropine in peds.
    - • Consider placing pacing (deﬁb) pads on any unstable patient.
    - • Pacing: Can start at 80 bpm / 80 mA. Escalate mA as needed.
    - - Treat Pain and/or Anxiety from pacing as soon as appropriate.
    - • Refer to Neonate for any peds under 1 month ( ≤ 30 days) old.
    - • Frequently a Breathing problem: don't forget O2 and BVM.
    - • Even a single pill of some meds can cause severe bradycardia.
    - - Consider opiate, Ca2+ or ß-blocker Overdose.
    - • Consider effects of maternal medication in breast milk.
    - • Use Peds Reference or other approved source for peds dosing.
    - • Medscape Vitals: https://emedicine.medscape.com/article/2172054
    - • Limmer D, O’Keefe MF. Emergency Care 15th ed. Chapter 13, 20
- app lines with no print counterpart (9):
    + - **Atropine**: first-line for symptomatic, narrow-complex bradycardia.
    + - Less effective in heart-transplant patients (denervated heart).
    + - Doses smaller than 0.5 mg may paradoxically slow the heart.
    + - **Pacing** (transcutaneous): mechanical capture is the goal.
    + - Confirm electrical AND mechanical capture (palpate pulse).
    + - Sedate as tolerated for awake patients.
    + - **Epi** (Peds): infusion or repeat boluses for refractory bradycardia.
    + - Bradycardia in peds is most often **hypoxia** — assist ventilations first.
    + - Use **PALS** rate thresholds and weight-based dosing.

### p.15
- print sections: Tachycardia Imperatives · Poor Perfusion · Critical Arrhythmia · Medications · Notes · Pediatrics · References
- app sections: Tachycardia Imperatives · Medications · Notes · Pediatrics · References
- underlined xrefs (11): Shock→p8, Pain→p20, Fever→p16, Bleeding→p58, OD / Tox→p40, Behavorial→p46, Anaphylaxis→p32, Cardiovert→p105, Peds Reference→p144, Adenosine→p119(bold), Amiodarone→p121(bold)
  - LINKED in app: none
  - bold-only in app: adenosine, amiodarone
  - plain in app: shock, pain, fever, bleeding, od / tox, behavorial, anaphylaxis, cardiovert, peds reference
- units set smaller (4): min, w/, w/pulse
- super/sub (6): sub 'w/'@20.00, super(flag) 'th'@16.67, sub 'min'@20.00, sub '/min'@12.00, sub '/min'@12.00, sub '/min'@12.00
- print lines with no app counterpart (23):
    - - Treat the cause. Avoid anti-arrhythmics or cardioversion.
    - • Critical Arrhythmias (e.g. SVT, V-Tach w/pulse) are usually faster.
    - - But a fast pulse is not always critical. Judgement is necessary.
    - -      May try vagal maneuvers (e.g. modiﬁed valsalva).
    - • Suspect if several of these:
    - • Suspect if pulse over:
    - - Altered Mental Status
    - - Adult(14+): 150 /min
    - - Skin Pale, Cool, Diaphoretic
    - - Child (1-13): 180 /min
    - - Tachycardia, Hypotension
    - - Infant  (<1): 220 /min
    - - Dyspnea, Tachypnea
    - • Adenosine(Adenocard®): Give rapid IV push.
    - - Use caution in patients with a history of WPW, COPD or asthma.
    - • Amiodarone (Pacerone®): Give over 10 min IV drip.
    - - Prehospital Amio is not indicated for pediatric tachycardia.
    - • Consider placing cardioversion (deﬁb) pads on any unstable pt.
    - • Cardiovert: Enable SYNC. Start at 200 J. Deﬁb if unable to SYNC.
    - - Alternative: follow manufacturer’s or OMD’s dosing guidance.
    - • Use Peds Reference or other approved source for peds dosing.
    - • Medscape Vitals: https://emedicine.medscape.com/article/2172054
    - • Limmer D, O’Keefe MF. Emergency Care 15th ed. Chapter 13, 20
- app lines with no print counterpart (13):
    + - Treat the **underlying cause** before targeting the rate itself.
    + - **Adenosine** (Adenocard®): only for narrow-complex SVT (QRS ≤ 120 ms).
    + - Push fast through a proximal IV with saline flush.
    + - Warn the patient about the brief sense of impending doom.
    + - **Amiodarone** (Pacerone®): for wide-complex tachycardia (QRS > 120 ms).
    + - Give over **10 min** for stable patients.
    + - **Magnesium** (Sulfate): for **Torsades** (polymorphic VT).
    + - **NS Bolus**: useful in shock states or rate from hypovolemia.
    + - Synchronized **Cardioversion** for unstable patients with a pulse.
    + - Sedate first if time and patient stability allow.
    + - Reassess rate and rhythm after every intervention.
    + - Use **PALS** rate thresholds and weight-based dosing.
    + - Vagal manoeuvres (ice to face) may convert SVT in stable peds.

### p.17
- print sections: Fever Imperatives · Medications · Poor Perfusion · Notes · Pediatrics · References
- app sections: Fever Imperatives · Medications · Poor Perfusion · Notes · Pediatrics · References
- underlined xrefs (6): Seizure→p42, Seizure→p42, Peds Reference→p144, Hyperthermia→p68, Sepsis→p94, Tylenol→p142(bold), Ibuprofen→p132(bold), Tylenol→p142(bold)
  - LINKED in app: seizure, sepsis
  - bold-only in app: peds reference, hyperthermia, tylenol, ibuprofen
  - plain in app: none
- units set smaller (0): 
- super/sub (2): super(flag) 'th'@16.67, super(flag) '®'@16.67
- print lines with no app counterpart (0):
- app lines with no print counterpart (0):

### p.19
- print sections: Hyperkalemia Imperatives · K+ EKG Changes · Hyper K+ EKG · Medications · Notes · Pediatrics · References
- app sections: Hyperkalemia Imperatives · K+ EKG Changes · Medications · Notes · Pediatrics · References
- underlined xrefs (8): Bicarb→p124(bold), Peds Reference→p144, extremity injury→p66, Albuterol→p120(bold), NS Bolus→p138(bold), Hypotension→p8, Calcium→p125(bold), Rocephin→p139(bold), Bicarb→p124(bold)
  - LINKED in app: extremity injury
  - bold-only in app: bicarb, peds reference, albuterol, ns bolus, hypotension, calcium, rocephin
  - plain in app: none
- units set smaller (1): ms
- super/sub (6): super(flag) '+'@16.67, super(flag) '+'@16.67, super(flag) 'th'@16.67, super(flag) '+'@20.00, sub 'ms'@20.00, super(flag) '+'@20.00
- print lines with no app counterpart (0):
- app lines with no print counterpart (0):

### p.21
- print sections: Pain Imperatives · Medications · Notes · Pediatrics · References
- app sections: Pain Imperatives · Medications · Notes · Pediatrics · References
- underlined xrefs (12): Peds Reference→p144, Major trauma→p56, fractures→p66, abdominal→p34, chest pain→p28, weight based peds dosing→p144, Tylenol→p142(bold), Tylenol→p142(bold), Ibuprofen→p132(bold), Toradol→p141(bold), Fentanyl→p130(bold), Ketamine→p133(bold), Tetracaine→p141(bold)
  - LINKED in app: none
  - bold-only in app: peds reference, tylenol, ibuprofen, toradol, fentanyl, ketamine
  - plain in app: major trauma, fractures, abdominal, chest pain, weight based peds dosing, tetracaine
- units set smaller (9): %, (, -, kg), lbs, mcg, mcg/kg, mg
- super/sub (10): super(flag) 'th'@16.67, sub 'lbs'@20.00, sub '('@20.00, sub 'kg)'@20.00, sub 'mg'@20.00, sub 'mg'@20.00, super(flag) '®'@16.67, sub '-'@20.00, sub 'mcg'@20.00, sub '%'@20.00
- print lines with no app counterpart (0):
- app lines with no print counterpart (1):
    + - **Ketamine** (Ketalar®):

### p.23
- print sections: Nausea / Vomiting Imperatives · Medications · Notes · Pediatrics · References
- app sections: Imperatives · Medications · Notes · Pediatrics · References
- underlined xrefs (7): Zofran→p143(bold), Cardiac→p28, overdose→p40, Zofran→p143(bold), Peds Reference→p144, Zofran→p143(bold), Bradycardia→p12, Overdose / Tox→p40, 12-Lead→p97
  - LINKED in app: overdose, bradycardia, overdose / tox
  - bold-only in app: zofran, cardiac, peds reference, 12-lead
  - plain in app: none
- units set smaller (0): 
- super/sub (2): super(flag) '®'@16.67, super(flag) 'th'@16.67
- print lines with no app counterpart (4):
    - - Strongly consider Zofran with any invasive airway device.
    - • Vomiting is a protective mechanism in overdose (such as EtOH).
    - - But intentionally inducing vomiting (i.e. ipecac) is not indicated.
    - - May consider Zofran for dry heaving after stomach is empty.
- app lines with no print counterpart (0):

### p.25
- print sections: Compressions · CODE Imperatives · Obvious Death · Medications · Notes · Pediatrics · References
- app sections: CODE Imperatives · Compressions · Obvious Death · Medications · Notes · Pediatrics · References
- underlined xrefs (13): Neonate→p50, Peds Reference→p144, compressions→p101(bold), deﬁb→p101(bold), Shock→p8, OD/Tox→p40, Hypoglycemia→p38, Hyperkalemia→p18, Special Case→p112, Call for Termination→p112, Transport→p112, Amiodarone→p121(bold), Magnesium→p136(bold)
  - LINKED in app: neonate
  - bold-only in app: peds reference, compressions, special case, call for termination, amiodarone, magnesium
  - plain in app: deﬁb, shock, od/tox, hypoglycemia, hyperkalemia, transport
- units set smaller (6): grams, mg, mg/kg, min
- super/sub (6): super(flag) 'th'@16.67, sub '2'@15.00, sub 'mg'@20.00, sub 'mg'@20.00, sub 'st'@10.00, sub 'nd'@10.00
- print lines with no app counterpart (3):
    - - Transport ASAP if ROSC, or peds,
    - or pregnant,or any Special Case.
    - 300mg, ￫150 mg
- app lines with no print counterpart (2):
    + - Transport ASAP if **ROSC**, or **peds**, or **pregnant**, or any **Special Case**.
    + - (1) 300 mg → (2) 150 mg

### p.27
- print sections: Medical ROSC Imperatives · Medications · Notes · Pediatrics · References
- app sections: Medical ROSC Imperatives · Medications · Notes · Pediatrics · References
- underlined xrefs (9): Ketamine→p133(bold), weight based peds dosing→p144, Hypotension→p8(bold), Hypotension→p8, Fever→p16(bold), Intubation→p78, Vent→p80, Peds Reference→p144, →p135, →p121, der maintenance Amiodarone→p121
  - LINKED in app: fever, 
  - bold-only in app: ketamine, hypotension, intubation, vent, peds reference
  - plain in app: weight based peds dosing, der maintenance amiodarone
- units set smaller (4): (, kg), lbs, mg/min
- super/sub (5): sub 'lbs'@20.00, sub '('@20.00, sub 'kg)'@20.00, super(flag) 'th'@16.67, sub '2'@15.00
- print lines with no app counterpart (0):
- app lines with no print counterpart (0):

### p.29
- print sections: Chest Pain Imperatives · Medications · PDE5 Inhibitors · Notes · Pediatrics · References
- app sections: Chest Pain Imperatives · Medications · Notes · Pediatrics · References
- underlined xrefs (8): Trunk Injury→p64, Tachycardia→p14, Bradycardia→p12, STEMI→p88, Aspirin→p122(bold), Nitro→p138(bold), Aspirin→p122(bold), Nitro→p138(bold), Hypotension→p8, Hypotensive→p8
  - LINKED in app: trunk injury, tachycardia, bradycardia, stemi
  - bold-only in app: aspirin, nitro, hypotension
  - plain in app: hypotensive
- units set smaller (5): **, h, mg, mmHg
- super/sub (6): super(flag) 'th'@16.67, sub '**'@20.00, sub '**'@20.00, sub 'mg'@20.00, sub 'mmHg'@20.00, sub 'h'@20.00
- print lines with no app counterpart (17):
    - - Use caution if Hypotensive or suspected inferior/right STEMI.
    - - Contraindicated if SBP under 110 mmHgwithout IV/IO access.
    - - Contraindicated if recent (36 h) use of any PDE5 inhibitors:
    - Call
    - • If you see a STEMI
    - • Sildenaﬁl (Viagra®)
    - • Or EKG says **AMI**
    - • Tadalaﬁl (Cialis®)
    - • Call a STEMI Alert
    - • Vardenaﬁl (Levitra®)
    - • Avanaﬁl (Stendra®)
    - • Consider an atypical cardiac presentation in diabetics &elderly.
    - - Actual chest pain is not always present. Ask about cardiac hx.
    - - May have SOB or "discomfort" or nausea or be weak & sweaty.
    - • Consider advanced STEMI care if indicated & credentialed for CC.
    - • Aspirin and Nitro are contraindicated in peds chest pain.
    - • Limmer D, O’Keefe MF. Emergency Care 15th ed. Chapter 20
- app lines with no print counterpart (6):
    + - Hold for SBP < 100 mmHg or HR < 50 / > 100.
    + - Do **not** give within 24 h of PDE5 inhibitors (sildenafil, etc).
    + - 12-Lead within **10 min** of patient contact when feasible.
    + - Transmit STEMI ECG to the receiving facility before arrival if possible.
    + - Atypical presentations are common in **diabetics**, **women**, and the **elderly**.
    + (musculoskeletal, anxiety, GERD, costochondritis).

### p.31
- print sections: Dyspnea Imperatives · Medications · Notes · Pediatrics · References
- app sections: Dyspnea Imperatives · Medications · Pediatrics · References
- underlined xrefs (15): Breathing→p6, Cardiac→p28, Anxiety→p46, Pulmonary Edema→p90, choking→p4, Peds Reference→p144, Albuterol→p120(bold), Atrovent→p123(bold), Epi Neb→p128(bold), Decadron→p127(bold), Nitro→p138(bold), Hypotension→p8, NIPPV→p99, PDE5 inhibitor→p29(bold), Magnesium→p136(bold), Magnesium→p136(bold)
  - LINKED in app: breathing
  - bold-only in app: peds reference, albuterol, atrovent, epi neb, decadron, nitro
  - plain in app: cardiac, anxiety, pulmonary edema, choking, hypotension, nippv, pde5 inhibitor, magnesium
- units set smaller (7): gram, h, mg, mg/mL, min
- super/sub (11): sub '2'@15.00, sub '2'@15.00, sub '2'@15.00, super(flag) 'th'@16.67, super(flag) '®'@16.67, super(flag) '®'@16.67, sub 'mg'@20.00, sub 'mg'@20.00, sub 'h'@20.00, sub 'gram'@20.00, sub 'min'@20.00
- print lines with no app counterpart (20):
    - • Albuterol (Ventolin®) & Atrovent®(Ipratropium bromide):
    - - May combine in same nebulizer. May cause palpitations.
    - • Epi Neb (Epinephrine): Use 1 mg/mL vial (not0.1 mg/mL preﬁll).
    - - Good choice for severe croup, bronchiolitis or asthma in peds.
    - • Decadron®(Dexamethasone): Alternate dose: 8 mg IV/IO, IM x1
    - • Nitro (Nitroglycerin): May cause Hypotension.
    - - May use double dose (0.8 mg) if hypertensive & requiring NIPPV.
    - - Contraindicated if recent (36 h) use of any PDE5 inhibitor.
    - • May consider Magnesium for severe asthma and/or wheezing.
    - Magnesium (Sulfate):  1 gram   IV/IO   over 10 min
    - • Consider an atypical Cardiac cause in diabetics and the elderly.
    - • Anxiety can also cause dyspnea and hyperventilation.
    - - Consider simple reassurance for obvious benign anxiety.
    - • Consider Pulmonary Edema if indicated & credentialed for CC.
    - • Defer aggressive evaluation if any concern for epiglottitis.
    - - Agitation can make it much worse.  (Unlikely if vaccinated.)
    - • Croup is an infection that is best treated like a reactive cause.
    - - Stridor may be present (but choking may also cause stridor).
    - • Use Peds Reference or other approved source for peds dosing.
    - • Limmer D, O’Keefe MF. Emergency Care 15th ed. Chapter 10, 19
- app lines with no print counterpart (14):
    + - Identify the **cause** before reaching for medications.
    + - The wrong med for the wrong cause may cause harm.
    + - **Albuterol** (Proventil®): bronchodilator for reactive disease.
    + - **Atrovent** (Ipratropium): give once with first Albuterol.
    + - **Epi Neb**: nebulised for upper airway swelling (croup, anaphylaxis).
    + - **Decadron** (Dexamethasone): single steroid dose to delay rebound.
    + - **Nitro** (Nitroglycerin): for pulmonary edema / heart failure dyspnea.
    + - Hold for SBP < 100 mmHg.
    + - Do **not** give within 24 h of PDE5 inhibitors.
    + - Stridor and barking cough → **croup** — give **Epi Neb** + Decadron.
    + - Wheezing → **asthma/RAD** — Albuterol + Atrovent.
    + - Use **Peds Reference** for weight-based dosing.
    + - GINA Asthma — https://ginasthma.org/ [Ver: 2024]
    + - GOLD COPD — https://goldcopd.org/ [Ver: 2024]

### p.33
- print sections: Allergic Reaction Imperatives · Medications · Poor Perfusion · Notes · Pediatrics · References
- app sections: Allergic Reaction Imperatives · Medications · Notes · Pediatrics · References
- underlined xrefs (11): Peds Reference→p144, Epi→p128(bold), Airway→p4, Breathing→p6, Circulation→p8, Albuterol→p120(bold), Decadron→p127(bold), Benadryl→p124(bold), auto-injecEpi Drip→p129, ded admdyspnea→p30, ystemshock→p8
  - LINKED in app: none
  - bold-only in app: peds reference, epi, airway, breathing, circulation, albuterol, decadron, benadryl
  - plain in app: auto-injecepi drip, ded admdyspnea, ystemshock
- units set smaller (1): mg
- super/sub (4): super(flag) 'th'@16.67, super(flag) '®'@16.67, sub 'mg'@20.00, super(flag) '®'@16.67
- print lines with no app counterpart (16):
    - May only use auto-injector or color coded admin system.
    - Consider an Epi Drip for persistent dyspnea or shock.
    - • Albuterol (Ventolin®): Use for any dyspnea or wheezing.
    - - Unlikely to help with rash or itching. May cause palpitations.
    - • Decadron®(Dexamethasone): Alternate dose: 8 mg IV/IO, IM x1
    - • Benadryl®(Diphenhydramine): May give adults 50 mg PO x1.
    - May only give PO (may use OTC formulation and dosing).
    - • Suspect if several of these:
    - - Altered Mental Status
    - - Skin Pale, Cool, Diaphoretic
    - - Tachycardia, Hypotension
    - - Dyspnea, Tachypnea
    - • Rapid onset of symptoms indicates a more severe reaction.
    - • Severe food allergies may also induce N/V and abdominal pain.
    - • Use Peds Reference or other approved source for peds dosing.
    - • Limmer D, O’Keefe MF. Emergency Care 15th ed. Chapter 23
- app lines with no print counterpart (11):
    + - **Albuterol** (Proventil®, Ventolin®): nebulised for bronchospasm.
    + - **Atrovent** (Ipratropium): nebulised — give once with first Albuterol.
    + - **Benadryl** (Diphenhydramine): blunts the histamine response.
    + - Sedating — use caution if monitoring mental status.
    + - **Decadron** (Dexamethasone): single steroid dose to delay rebound.
    + - Be ready to repeat **Epi** if symptoms persist or rebound.
    + - Patients on **beta-blockers** may be refractory to Epi —
    + consider **Glucagon** if available.
    + - **Biphasic** reactions can recur 4–12 h after the initial response.
    + - Use **Peds Reference** for all other weight-based dosing.
    + - WAO Anaphylaxis Guidelines — https://www.worldallergy.org/UserFiles/file/WAO-Anaphylaxis-Guidance-2020.pdf [Ver: 2020]

### p.35
- print sections: Abdominal Pain Imperatives · Notes · Pediatrics · References
- app sections: Abdominal Pain Imperatives · Notes · Pediatrics · References
- underlined xrefs (9): Trunk Injury→p64, Hypotension→p8, Pregnancy→p48, shock→p8, Cardiac→p28, Fever→p16, Pain→p20, Nausea→p22, Sepsis→p94
  - LINKED in app: trunk injury, fever, pain, sepsis
  - bold-only in app: hypotension, pregnancy, shock, cardiac, nausea
  - plain in app: none
- units set smaller (0): 
- super/sub (1): super(flag) 'th'@16.67
- print lines with no app counterpart (0):
- app lines with no print counterpart (0):

### p.37
- print sections: Altered LOC Imperatives · Notes · Glasgow Coma Scale · Pediatrics · References
- app sections: Altered LOC Imperatives · Notes · Glasgow Coma Scale · Pediatrics · References
- underlined xrefs (4): Medical CODE→p24, Intoxication→p40, Cardiac→p28, Sepsis→p94
  - LINKED in app: medical code, sepsis
  - bold-only in app: intoxication, cardiac
  - plain in app: none
- units set smaller (0): 
- super/sub (1): super(flag) 'th'@16.67
- print lines with no app counterpart (0):
- app lines with no print counterpart (0):

### p.39
- print sections: Diabetic Imperatives · Medications · Notes · Pediatrics · References
- app sections: Diabetic Imperatives · Medications · Notes · Pediatrics · References
- underlined xrefs (9): Oral Glucose→p131(bold), D10→p126(bold), Glucagon→p130(bold), D10→p126(bold), Glucagon→p130(bold), Cardiac→p28, Altered LOC→p36, shock→p8, Peds Reference→p144, →p141, Baqsimi→p130(bold)
  - LINKED in app: none
  - bold-only in app: oral glucose, d10, glucagon, cardiac, altered loc, peds reference, 
  - plain in app: shock, baqsimi
- units set smaller (3): %, mg, †
- super/sub (4): sub '%'@20.00, super(flag) 'th'@16.67, super '†'@20.00, sub 'mg'@20.00
- print lines with no app counterpart (20):
    - • Hypoglycemia from sulfonylureas can be refractory & profound.
    - - E.g. glipizide (Glucotrol®), glyburide, glimepiride (Amaryl®)
    - - Call Medical Control for any refusal if taking sulfonylureas.
    - • Oral Glucose (Glutose 15™): Avoid if patient cannot swallow.
    - - Consider regular food as an alternative if available.
    - - Prioritize food & drink with simple sugar (like juice & candy).
    - - Also provide complex carbs/protein (like peanut butter).
    - • D10 (Dextrose 10%): Recheck glucose prior to repeat dosing.
    - - May attempt without glucometer if hypoglycemia is likely.
    - • Glucagon (Glucagen®): Caution - improvement is temporary!
    - - Must provide additional glucose or D10 after admin.
    - - Call Medical Control for any refusal after Glucagon.
    - - Can substitute intranasal preﬁll device (instead of IM dosing):
    - †Baqsimi® (Glucagon IN preﬁll):  3 mg  IN  x1  for ≥ 1 y/o
    - • Avoid starting an IV in the legs or feet of a diabetic patient.
    - • Hyperglycemia with fruity odor may be DKA - emphasize IV ﬂuids.
    - • Look for an insulin pump. May unplug the tube if hypoglycemic.
    - • Only use NS Bolus for shock. Hypervolemia can cause harm.
    - • Use Peds Reference or other approved source for peds dosing.
    - • Limmer D, O’Keefe MF. Emergency Care 15th ed. Chapter 22
- app lines with no print counterpart (11):
    + - **Oral Glucose** (gel or sweetened liquid): only if airway is protected.
    + - **D10** (Dextrose 10%): titrate to mental status, not a fixed dose.
    + - **D50** is being phased out — D10 is gentler on veins.
    + - **Glucagon**: IM rescue if no IV access. Slow onset (~10 min).
    + - **NS Bolus**: backbone of DKA / hyperosmolar prehospital care.
    + - Recheck glucose **5–10 min** after every intervention.
    + - Patients on insulin pumps: leave the pump alone unless directed otherwise.
    + - **DKA** patients may have fruity breath (acetone) and Kussmaul respirations.
    + - **Hypoglycemia** in peds is dangerous and underrecognized.
    + - Always check glucose in any peds with altered LOC or seizure.
    + - Use **Peds Reference** for weight-based dosing.

### p.41
- print sections: Overdose / Tox Imperatives · Medications · Notes · Pediatrics · References
- app sections: Overdose / Tox Imperatives · Medications · Notes · Pediatrics · References
- underlined xrefs (13): Antidote→p104, Antidote→p104, Airway→p4, Antidotes→p104, Burns→p70, Inhalation→p72, shock→p8, Peds Reference→p144, Narcan→p137(bold), Hypoxia→p6(bold), Narcan→p137(bold), NS Bolus→p138(bold), Hypotension→p8, CHF→p30, dialysis→p18
  - LINKED in app: airway
  - bold-only in app: antidote, peds reference, narcan, hypoxia, ns bolus
  - plain in app: antidotes, burns, inhalation, shock, hypotension, chf, dialysis
- units set smaller (1): 2
- super/sub (3): super(flag) 'th'@16.67, super(flag) '®'@16.67, sub '2'@20.00
- print lines with no app counterpart (15):
    - - May try for any substance OD or exposure w/ dyspnea or shock.
    - - Call Medical Control for any refusal after Narcan.
    - May provide premeasured intranasal doses only.
    - Titrate dose to resps & SpO2; May start as low as 0.04 mg.
    - • NS Bolus (0.9% Saline): Fluids may help dilute toxins.
    - - Consider even without Hypotension. Avoid with CHF or dialysis.
    - • If poison is known, consider Poison Control: 800-222-1222.
    - - Most Antidotes require online orders (and dosing instructions).
    - • This protocol includes poisoning and toxic ingestions.
    - - For chemical burns and skin exposures, refer to Burns.
    - - For gasses and smoke inhalation, refer to Inhalation.
    - • Just a single pill of some adult meds can cause profound shock.
    - - Ingested cigarettes or vape ﬂuid (nicotine) can be fatal.
    - • Use Peds Reference or other approved source for peds dosing.
    - • Limmer D, O’Keefe MF. Emergency Care 15th ed. Chapter 25
- app lines with no print counterpart (11):
    + - Goal is restored breathing — **not** full alertness.
    + - Repeat doses titrated to effect; long-acting opioids may need redosing.
    + - **NS Bolus**: supportive in shock from hypovolemia or sepsis-like states.
    + - **Patient DECON**: remove contaminated clothing and irrigate skin/eyes
    + before transport when contamination is suspected.
    + - Use **Poison Control** (1-800-222-1222) for exposure-specific guidance.
    + - Treat **co-ingestions** assuming worst-case mixed effect.
    + - Pediatric exposures often involve household chemicals and meds left
    + accessible — gather history from caregivers and bring containers if safe.
    + - Use **Peds Reference** for weight-based dosing.
    + - Poison Control — 1-800-222-1222

### p.43
- print sections: Seizure Imperatives · Medications · Notes · Pediatrics · References
- app sections: Seizure Imperatives · Medications · Notes · Pediatrics · References
- underlined xrefs (13): Altered LOC→p36, Behavioral→p46, OD / Tox→p40, Fever→p16, Fever→p16, Peds Reference→p144, Versed→p143(bold), Keppra→p133(bold), weight based peds dosing→p144, Magnesium→p136(bold), Hypotension→p8, Dyspnea→p6, Pregnancy→p48(bold), Preeclampsia→p92, Versed→p143(bold)
  - LINKED in app: behavioral, fever, dyspnea
  - bold-only in app: altered loc, od / tox, peds reference, versed, keppra, magnesium, hypotension, pregnancy, preeclampsia
  - plain in app: weight based peds dosing
- units set smaller (6): (, kg), lbs, min
- super/sub (8): super(flag) 'th'@16.67, sub 'min'@20.00, sub 'min'@20.00, super(flag) '®'@16.67, super(flag) '®'@16.67, sub 'lbs'@20.00, sub '('@20.00, sub 'kg)'@20.00
- print lines with no app counterpart (0):
- app lines with no print counterpart (0):

### p.45
- print sections: Stroke Imperatives · Cincinnati Stroke · Stroke VAN · • Facial Droop? · • Vision: Partial / Total Loss? · • Arm Drift? · • Aphasia: Trouble Speaking? · • Slurred Speech? · • Neglect: Ignoring One Side? · • Time Last Normal? · Notes · Pediatrics · References
- app sections: Stroke Imperatives · Cincinnati Stroke · Stroke VAN · STROKE Alert · Notes · Pediatrics · References
- underlined xrefs (2): Saline Lock→p97, Altered LOC→p36
  - LINKED in app: none
  - bold-only in app: saline lock, altered loc
  - plain in app: none
- units set smaller (0): 
- super/sub (8): super(flag) 'th'@16.67, sub '•'@25.00, sub '•'@25.00, sub '•'@25.00, sub '•'@25.00, sub '•'@25.00, sub '•'@25.00, sub '•'@25.00
- print lines with no app counterpart (1):
    - Call
- app lines with no print counterpart (7):
    + - **F**acial Droop?
    + - **A**rm Drift?
    + - **S**lurred Speech?
    + - **T**ime Last Normal?
    + - **V**ision: Partial / Total Loss?
    + - **A**phasia: Trouble Speaking?
    + - **N**eglect: Ignoring One Side?

### p.47
- print sections: Behavioral Imperatives · Medications · Notes · Pediatrics · References
- app sections: Behavioral Imperatives · Medications · Notes · Pediatrics · References
- underlined xrefs (5): capacity to refuse→p115, Peds Reference→p144, Versed→p143(bold), Haldol→p131(bold), Benadryl→p124(bold), Versed→p143(bold)
  - LINKED in app: none
  - bold-only in app: capacity to refuse, peds reference, versed, haldol
  - plain in app: benadryl
- units set smaller (1): min
- super/sub (4): super(flag) 'th'@16.67, super(flag) '®'@16.67, super(flag) '®'@16.67, super(flag) '®'@16.67
- print lines with no app counterpart (16):
    - - Use only when risk of harm is greater than risk of restraint.
    - - Peds, elderly or frail patients are unlikely to need restraint.
    - • Physical restraint should only be used in conjunction with Police.
    - - Ask for Police help if the patient is physically combative.
    - - Beware any physical or verbal threats, aggression, or agitation.
    - - Never use hobble restraints. Never restrain a patient prone.
    - • Use caution with needles - increased risk of provider injury.
    - • Versed®(Midazolam): Use with caution with peds and elderly.
    - • Haldol®(Haloperidol): Requires transport and ALS monitoring.
    - - May potentiate dystonic muscle jerking & spasms (not seizure).
    - - Consider treatment with Benadryl if spasms are severe.
    - Benadryl® (diphenhydramine): 25 mg PO, IV/IO, IM x1
    - • SI / HI: Suicidal or Homicidal Ideation (any recent thoughts or acts)
    - • Use Peds Reference or other approved source for peds dosing.
    - Versed: max peds dose is Q 2 minx4 doses
    - • Limmer D, O’Keefe MF. Emergency Care 15th ed. Chapter 27
- app lines with no print counterpart (11):
    + - **Versed®** (Midazolam): rapid-onset benzo for agitation.
    + - **Haldol** (Haloperidol): IM antipsychotic for severe agitation.
    + - Useful for delirium/psychosis where benzos alone are insufficient.
    + - Watch for QT prolongation and dystonic reactions.
    + - Always rule out medical causes of altered behavior:
    + - **Hypoxia**, **hypoglycemia**, [head injury](topic:wvems-2026-062), **OD / Tox**, [sepsis](topic:wvems-2026-094).
    + - Document a clear scene description and the indication for any restraint.
    + - **Excited delirium** is a medical emergency — sudden death is possible.
    + - Acute behavioral changes in peds are usually medical, not psychiatric.
    + - Use **Peds Reference** for weight-based dosing.
    + - NAEMSP Excited Delirium — https://naemsp.org/resources/position-statements/ [Ver: 2024]

### p.49
- print sections: Pregnancy / Delivery Imperatives · Notes · Pediatrics · References
- app sections: Pregnancy / Delivery Imperatives · Notes · Pediatrics · References
- underlined xrefs (5): Preeclampsia→p92, Seizure→p42, Manage OB Complications→p106(bold), Neonate→p50, TXA→p142(bold)
  - LINKED in app: seizure, neonate
  - bold-only in app: preeclampsia, manage ob complications, txa
  - plain in app: none
- units set smaller (2): ,, mmHg
- super/sub (3): super(flag) 'th'@16.67, sub 'mmHg'@20.00, sub ','@20.00
- print lines with no app counterpart (0):
- app lines with no print counterpart (0):

### p.51
- print sections: Compressions · Neonate Imperatives · BVM Rate · APGAR: · Normal SpO2: · Notes · References
- app sections: Neonate Imperatives · Compressions · BVM Rate · APGAR · Normal SpO2 · Notes · References
- underlined xrefs (4): BVM→p99, PTX→p6, Hypoglycemia→p38, Shock→p8
  - LINKED in app: none
  - bold-only in app: bvm, ptx, hypoglycemia, shock
  - plain in app: none
- units set smaller (11): /, 2, min, sec
- super/sub (12): super(flag) 'th'@16.67, sub 'sec'@20.00, sub '2'@20.00, sub 'sec'@20.00, sub '2'@20.00, sub '2'@25.00, sub 'min'@20.00, sub 'min'@20.00, sub 'min'@20.00, sub 'min'@20.00, sub 'min'@20.00, sub 'min'@20.00
- print lines with no app counterpart (12):
    - 1 min
    - 60-65%
    - 2 min
    - 65-70%
    - 3 min
    - 70-75%
    - 4 min
    - 75-80%
    - 5 min
    - 80-85%
    - 10 min
    - 85-95%
- app lines with no print counterpart (6):
    + - 1 min: **60–65%**
    + - 2 min: **65–70%**
    + - 3 min: **70–75%**
    + - 4 min: **75–80%**
    + - 5 min: **80–85%**
    + - 10 min: **85–95%**

### p.53
- print sections: Compressions · CODE Imperatives · Mortal Injuries · Medications · Notes · Pediatrics · References
- app sections: CODE Imperatives · Compressions · TRAUMA Alert · Mortal Injuries · Medications · Notes · Pediatrics · References
- underlined xrefs (6): Tourniquets→p102(bold), Pleural Decompression→p100(bold), Medical CODE→p24, Peds Reference→p144, NS Bolus→p138(bold), Amiodarone→p121(bold)
  - LINKED in app: medical code
  - bold-only in app: tourniquets, pleural decompression, peds reference, ns bolus, amiodarone
  - plain in app: none
- units set smaller (7): (x2), (x3), mg, min, mmHg
- super/sub (3): super(flag) 'th'@16.67, sub '2'@15.00, sub 'mmHg'@20.00
- print lines with no app counterpart (1):
    - Call
- app lines with no print counterpart (0):

### p.55
- print sections: Trauma ROSC Imperatives · Poor Perfusion · Medications · Notes · Pediatrics · References
- app sections: Trauma ROSC Imperatives · TRAUMA Alert · Poor Perfusion · Medications · Notes · Pediatrics · References
- underlined xrefs (8): Pleural Decompression→p100, Tourniquets→p102, pack wounds→p102, Ketamine→p133(bold), weight based peds dosing→p144, Peds Reference→p144, Intubation→p78, Vent→p80
  - LINKED in app: none
  - bold-only in app: pleural decompression, tourniquets, pack wounds, ketamine, peds reference, intubation, vent
  - plain in app: weight based peds dosing
- units set smaller (5): (, ), kg), lbs
- super/sub (6): super(flag) 'th'@16.67, sub 'lbs'@20.00, sub '('@20.00, sub 'kg)'@20.00, sub '('@20.00, sub ')'@20.00
- print lines with no app counterpart (1):
    - Call
- app lines with no print counterpart (0):

### p.57
- print sections: Major Trauma Imperatives · Poor Perfusion · Medications · Notes · Pediatrics · References
- app sections: Major Trauma Imperatives · TRAUMA Alert · Poor Perfusion · Medications · Notes · Pediatrics · References
- underlined xrefs (5): c-collar→p60, Blood→p84, Peds Reference→p144, NS Bolus→p138(bold), Ancef→p121(bold)
  - LINKED in app: blood
  - bold-only in app: c-collar, peds reference, ns bolus, ancef
  - plain in app: none
- units set smaller (1): mmHg
- super/sub (2): super(flag) 'th'@16.67, sub 'mmHg'@20.00
- print lines with no app counterpart (1):
    - Call
- app lines with no print counterpart (0):

### p.59
- print sections: Bleeding Imperatives · Poor Perfusion · Medications · Notes · Pediatrics · References
- app sections: Bleeding Imperatives · TRAUMA Alert · Poor Perfusion · Medications · Notes · Pediatrics · References
- underlined xrefs (9): Tourniquet→p102(bold), Tourniquet→p102, Packing→p102, Anticoagulation→p77, Bandage wounds→p102, Blood→p84, Shock→p8, Peds Reference→p144, TXA→p142(bold), postpartum→p48(bold)
  - LINKED in app: blood
  - bold-only in app: tourniquet, packing, anticoagulation, bandage wounds, shock, peds reference, txa, postpartum
  - plain in app: none
- units set smaller (0): 
- super/sub (1): super(flag) 'th'@16.67
- print lines with no app counterpart (1):
    - Call
- app lines with no print counterpart (0):

### p.61
- print sections: Immobilization Imperatives · Notes · Pediatrics · References
- app sections: Immobilization Imperatives · Notes · Pediatrics · References
- underlined xrefs (5): SMR→p103(bold), c-collar→p103(bold), SMR→p103(bold), Glasgow Coma Scale→p37, Burn→p70, extremity→p66, SMR→p103(bold)
  - LINKED in app: none
  - bold-only in app: smr, c-collar, glasgow coma scale, burn, extremity
  - plain in app: none
- units set smaller (2): min, mph
- super/sub (7): super(flag) '†'@16.67, super(flag) 'th'@16.67, super(flag) '†'@16.67, super(flag) '†'@16.67, super(flag) '†'@16.67, sub 'min'@20.00, sub 'mph'@20.00
- print lines with no app counterpart (0):
- app lines with no print counterpart (0):

### p.63
- print sections: Head Injury Imperatives · Notes · Pediatrics · References
- app sections: Head Injury Imperatives · TRAUMA Alert · Notes · Pediatrics · References
- underlined xrefs (8): Elevated ICP→p86, Hypoxia→p6, Hypotension→p8, Anticoagulation→p77, Airway→p4, Epistaxis→p76, Peds Reference→p144, Tetracaine→p141(bold)
  - LINKED in app: elevated icp, airway, epistaxis
  - bold-only in app: hypoxia, hypotension, anticoagulation, peds reference, tetracaine
  - plain in app: none
- units set smaller (0): 
- super/sub (1): super(flag) 'th'@16.67
- print lines with no app counterpart (1):
    - Call
- app lines with no print counterpart (0):

### p.65
- print sections: Trunk Injury Imperatives · Notes · Pediatrics · References
- app sections: Trunk Injury Imperatives · TRAUMA Alert · Notes · Pediatrics · References
- underlined xrefs (4): chest seal→p6, Immobilization→p60, Pneumothorax→p6, Dyspnea→p6
  - LINKED in app: immobilization, dyspnea
  - bold-only in app: chest seal, pneumothorax
  - plain in app: none
- units set smaller (0): 
- super/sub (1): super(flag) 'th'@16.67
- print lines with no app counterpart (1):
    - Call
- app lines with no print counterpart (0):

### p.67
- print sections: Extremity Injury Imperatives · Medications · Notes · Pediatrics · References
- app sections: Extremity Injury Imperatives · TRAUMA Alert · Medications · Notes · Pediatrics · References
- underlined xrefs (5): Tourniquet→p102(bold), Tourniquet→p102, Hyperkalemia→p18(bold), traction splint→p103, Child Abuse→p110(bold), Ancef→p121(bold)
  - LINKED in app: hyperkalemia
  - bold-only in app: tourniquet, traction splint, child abuse, ancef
  - plain in app: none
- units set smaller (0): 
- super/sub (1): super(flag) 'th'@16.67
- print lines with no app counterpart (1):
    - Call
- app lines with no print counterpart (0):

### p.69
- print sections: Cold / Heat Imperatives · Notes · Pediatrics · References
- app sections: Cold / Heat Imperatives · Notes · Pediatrics · References
- underlined xrefs (5): Fever→p16, Fever→p16, Medical Code→p24, Peds Reference→p144, Versed→p143(bold), Ibuprofen→p132(bold)
  - LINKED in app: fever, medical code
  - bold-only in app: peds reference, versed, ibuprofen
  - plain in app: none
- units set smaller (0): 
- super/sub (2): super(flag) 'th'@16.67, super(flag) '®'@16.67
- print lines with no app counterpart (0):
- app lines with no print counterpart (0):

### p.71
- print sections: Burn Imperatives · ABLS rate: · 9 · 18 · 9            9 · 18 · 9   9 · 1 · Notes · 9   9 · Pediatrics · References
- app sections: Burn Imperatives · ABLS rate · TRAUMA Alert · Notes · Pediatrics · References
- underlined xrefs (8): Inhalation→p72, OD / Tox→p40, Destination Triage→p116, Hypothermia→p68, Airway→p4, Antidote→p104, EKG→p97, Peds Reference→p144
  - LINKED in app: inhalation, airway
  - bold-only in app: od / tox, destination triage, hypothermia, antidote, ekg, peds reference
  - plain in app: none
- units set smaller (1): V
- super/sub (2): super(flag) 'th'@16.67, sub 'V'@20.00
- print lines with no app counterpart (4):
    - BSA percentage
    - (front and back)
    - 14   14
    - Call
- app lines with no print counterpart (3):
    + assets/books/wvems/images/bsa_rule_of_nines.png
    + full
    + Rule of 9's (adult BSA) — palm (with fingers) ≈ 1%, perineum 1%.

### p.73
- print sections: Inhalation Imperatives · Notes · Pediatrics · References
- app sections: Inhalation Imperatives · Notes · Pediatrics · References
- underlined xrefs (7): Airway→p4, Intubation→p78, Antidote→p104, Antidote→p104, Hypoxia→p6, Dyspnea→p30, Burns→p70, OD / Tox→p40
  - LINKED in app: airway, dyspnea, burns
  - bold-only in app: intubation, antidote, hypoxia, od / tox
  - plain in app: none
- units set smaller (1): 2
- super/sub (5): super(flag) 'th'@16.67, sub '2'@15.00, sub '2'@15.00, sub '2'@20.00, sub '2'@15.00
- print lines with no app counterpart (0):
- app lines with no print counterpart (0):

### p.75
- print sections: Sting / Bite Imperatives · Notes · Rattlesnake · Copperhead · Black Widow · Pediatrics · References
- app sections: Sting / Bite Imperatives · Notes · Pediatrics · References
- underlined xrefs (1): Anaphylaxis→p32
  - LINKED in app: none
  - bold-only in app: anaphylaxis
  - plain in app: none
- units set smaller (0): 
- super/sub (1): super(flag) 'th'@16.67
- print lines with no app counterpart (0):
- app lines with no print counterpart (6):
    + assets/books/wvems/images/snake_rattlesnake.jpg
    + Rattlesnake · Jonathunder / Wikimedia, CC BY-SA 3.0
    + assets/books/wvems/images/snake_copperhead.jpg
    + Copperhead · Holger Krisp / Wikimedia, CC BY 3.0
    + assets/books/wvems/images/spider_black_widow.jpg
    + Black Widow · Shenrich91 / Wikimedia, CC BY-SA 3.0

### p.77
- print sections: Epistaxis Imperatives · Medications · Notes · Anticoag Meds · Pediatrics · References
- app sections: Epistaxis Imperatives · Medications · Notes · Anticoag Meds · Pediatrics · References
- underlined xrefs (8): shock→p8, Major Trauma→p56, Bleeding→p58, Head Injury→p62, Peds Reference→p144, Afrin→p120(bold), chest pain→p28, TXA→p142(bold)
  - LINKED in app: major trauma, bleeding, head injury, chest pain
  - bold-only in app: shock, peds reference, afrin, txa
  - plain in app: none
- units set smaller (0): 
- super/sub (2): super(flag) 'th'@16.67, super(flag) '®'@16.67
- print lines with no app counterpart (2):
    - • Anticoagulants (“blood thinners”)
    - also increase risk in:
- app lines with no print counterpart (1):
    + - Anticoagulants (**blood thinners**) also increase risk in:

### p.79
- print sections: RSI Mandatory Prerequisites · Imperatives · Medications · Pediatrics · References
- app sections: RSI Mandatory Prerequisites · Imperatives · Medications · Pediatrics · References
- underlined xrefs (7): Preoxygenate→p6(bold), RSI Prep Checklist→p107(bold), pressors→p82, shock index→p83, Etomidate→p129(bold), Ketamine→p133(bold), Ketamine→p133(bold), Ketamine→p133(bold), Etomidate→p129(bold), Rocuronium→p140(bold)
  - LINKED in app: none
  - bold-only in app: preoxygenate, rsi prep checklist, shock index, etomidate, ketamine, rocuronium
  - plain in app: pressors
- units set smaller (8): %, 2, mmHg
- super/sub (9): super(flag) 'th'@16.67, sub '2'@20.00, sub '2'@20.00, sub '2'@20.00, sub '%'@20.00, sub '2'@20.00, sub 'mmHg'@20.00, sub 'mmHg'@20.00, sub '2'@20.00
- print lines with no app counterpart (0):
- app lines with no print counterpart (0):

### p.81
- print sections: Sedation / Vent Mandatory Prerequisites · Imperatives · Typical Adult Vent Settings · Medications · Pediatrics · References
- app sections: Sedation / Vent Mandatory Prerequisites · Imperatives · Typical Adult Vent Settings · Medications · Pediatrics · References
- underlined xrefs (11): Fentanyl→p130(bold), Versed→p143(bold), Ketamine→p133(bold), Propofol→p139(bold), vents→p107, Suction→p98, Airway→p4, ventilator→p107, Peds Reference→p144, →p123, →p4, →p98, →p4, →p22, Vent→p107(bold)
  - LINKED in app: airway, 
  - bold-only in app: fentanyl, versed, ketamine, propofol, suction, ventilator, peds reference, vent
  - plain in app: vents
- units set smaller (13): %, &, /min, mL, mL/kg, mcg/kg/min, min, mmHg
- super/sub (12): sub 'mL'@20.00, sub '%'@20.00, sub 'min'@20.00, super(flag) 'th'@16.67, sub '&'@20.00, sub '2'@15.00, sub '2'@15.00, sub 'mL'@20.00, sub 'mL'@20.00, sub '/min'@20.00, sub 'mmHg'@20.00, sub 'mmHg'@20.00
- print lines with no app counterpart (0):
- app lines with no print counterpart (0):

### p.83
- print sections: Vasopressors Mandatory Prerequisites · Imperatives · Medications · Poor Perfusion · Shock Index · Notes · Pediatrics · References
- app sections: Vasopressors Mandatory Prerequisites · Imperatives · Medications · Shock Index · Poor Perfusion · Notes · Pediatrics · References
- underlined xrefs (4): Peds Reference→p144, Peds Reference→p144, Levophed→p134(bold), Epi Push→p129(bold), Neo Push→p137(bold)
  - LINKED in app: none
  - bold-only in app: peds reference, levophed, epi push, neo push
  - plain in app: none
- units set smaller (0): 
- super/sub (1): super(flag) 'th'@16.67
- print lines with no app counterpart (1):
    - Pulse
- app lines with no print counterpart (1):
    + SI = **Pulse / SBP**

### p.85
- print sections: Blood Mandatory Prerequisites · Imperatives · Medications · Notes · Pediatrics · References
- app sections: Blood Mandatory Prerequisites · Imperatives · Medications · Notes · Pediatrics · References
- underlined xrefs (5): NS Bolus→p138(bold), fever→p16, dyspnea→p30, allergic reaction→p32, Peds Reference→p144
  - LINKED in app: fever, dyspnea, allergic reaction
  - bold-only in app: ns bolus, peds reference
  - plain in app: none
- units set smaller (2): mL/kg, mmHg
- super/sub (2): sub 'mmHg'@20.00, super(flag) 'th'@16.67
- print lines with no app counterpart (0):
- app lines with no print counterpart (0):

### p.87
- print sections: Elevated ICP Mandatory Prerequisites · Imperatives · Glasgow Coma Scale · Cushing’s Triad · Medications · Notes · Pediatrics · References
- app sections: Elevated ICP Mandatory Prerequisites · Imperatives · Cushing's Triad · Glasgow Coma Scale · Medications · Notes · Pediatrics · References
- underlined xrefs (12): Seizures→p42, Pain→p20, Vomiting→p22, Agitation→p46, Fever→p16, anti-coagulation→p76, Hypoxia→p6, Hypotension→p8, Peds Reference→p144, Peds Reference→p144, 3% Saline→p119(bold), Keppra→p133(bold), seizures→p42
  - LINKED in app: pain, fever
  - bold-only in app: seizures, vomiting, agitation, anti-coagulation, hypoxia, hypotension, peds reference, 3% saline, keppra
  - plain in app: none
- units set smaller (5): %, 2, mmHg
- super/sub (6): super(flag) 'th'@16.67, sub 'mmHg'@20.00, sub '2'@20.00, sub '%'@20.00, sub '2'@20.00, sub 'mmHg'@20.00
- print lines with no app counterpart (2):
    - • 3% Saline (Hypertonic):
    - - Inform the ED after use.
- app lines with no print counterpart (1):
    + - **3% Saline** (Hypertonic): **Inform the ED** after use.

### p.89
- print sections: STEMI Mandatory Prerequisites · Imperatives · Medications · Notes · Pediatrics · References
- app sections: STEMI Mandatory Prerequisites · Imperatives · STEMI Alert · Sgarbossa's (modified) · Medications · Notes · Pediatrics · References
- underlined xrefs (4): the basics→p28, shock→p8, Heparin→p132(bold), →p138, →p132, →p144, →p132, →p38, →p124
  - LINKED in app: none
  - bold-only in app: shock, heparin, 
  - plain in app: the basics
- units set smaller (2): &, 2
- super/sub (3): super(flag) 'th'@16.67, sub '2'@20.00, sub '&'@20.00
- print lines with no app counterpart (5):
    - Sgarbossa's
    - -QRS
    - Call
    - +QRS
    - -QRS
- app lines with no print counterpart (3):
    + - **+ST** > 25% of QRS size (any lead)
    + - **+ST** with **+QRS** (concordant)
    + - **−ST** with **−QRS** in V1, V2 or V3

### p.91
- print sections: Pulmonary Edema Mandatory Prerequisites · Imperatives · Medications · Notes · Pediatrics · References
- app sections: Pulmonary Edema Mandatory Prerequisites · Imperatives · Medications · Notes · Pediatrics · References
- underlined xrefs (11): pain or headache→p20, dyspnea→p30, O2 & NIPPV→p6(bold), airway→p4, Peds Reference→p144, arrhythmia→p14, Nitro Drip→p138(bold), hypotension→p8, PDE5 inhibitor→p29(bold), vasopressors→p82, hypotension→p8, Lasix→p134(bold)
  - LINKED in app: dyspnea, airway, vasopressors
  - bold-only in app: pain or headache, o2 & nippv, peds reference, arrhythmia, nitro drip, hypotension, pde5 inhibitor, lasix
  - plain in app: none
- units set smaller (5): 2, h, mg, mmHg
- super/sub (6): super(flag) 'th'@16.67, sub '2'@20.00, sub '2'@20.00, sub 'mmHg'@20.00, sub 'mg'@20.00, sub 'h'@20.00
- print lines with no app counterpart (0):
- app lines with no print counterpart (0):

### p.93
- print sections: Malignant HTN Mandatory Prerequisites · Imperatives · Medications · Notes · Pediatrics · References
- app sections: Malignant HTN Mandatory Prerequisites · Imperatives · Medications · Notes · Pediatrics · References
- underlined xrefs (5): Hypertension→p10, Stroke→p44, underlying causes→p10, Lopressor→p135(bold), Magnesium→p136(bold)
  - LINKED in app: hypertension, stroke
  - bold-only in app: underlying causes, lopressor, magnesium
  - plain in app: none
- units set smaller (5): %, /min, mmHg
- super/sub (6): super(flag) 'th'@16.67, sub '%'@20.00, sub '%'@20.00, sub 'mmHg'@20.00, sub '/min'@20.00, sub 'mmHg'@20.00
- print lines with no app counterpart (0):
- app lines with no print counterpart (0):

### p.95
- print sections: Sepsis Mandatory Prerequisites · Organ Dysfunction · Suspect Infection · Imperatives · Medications · Pediatrics · References
- app sections: Sepsis Mandatory Prerequisites · SEPSIS Alert · Organ Dysfunction · Suspect Infection · Imperatives · Medications · Pediatrics · References
- underlined xrefs (4): Rocephin→p139(bold), NS→p138(bold), Lidocaine→p135(bold), Calcium→p125(bold)
  - LINKED in app: none
  - bold-only in app: rocephin, ns, lidocaine, calcium
  - plain in app: none
- units set smaller (8): ..., °, …
- super/sub (21): super(flag) '†'@16.67, super(flag) 'th'@16.67, sub '…'@20.00, super(flag) '†'@16.67, super(flag) '†'@16.67, sub '…'@20.00, super(flag) '†'@16.67, sub '…'@20.00, super(flag) '†'@16.67, sub '...'@20.00, super(flag) '†'@16.67, super(flag) '®'@16.67, sub '/min'@10.00, sub '/min'@10.00, sub '2'@15.00, sub 'mmHg'@10.00, sub '°'@20.00, sub '°'@20.00, sub '°'@20.00, sub '°'@20.00, sub '2'@15.00
- print lines with no app counterpart (3):
    - • In the last 12 months: pass a
    - Call
    - critical care in-service training.
- app lines with no print counterpart (1):
    + - In the last 12 months: pass a critical-care in-service training.

