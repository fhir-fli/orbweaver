# Orbweaver YAML — authoring reference

Orbweaver is a renderer. Everything it shows comes from YAML **book bundles**, and
nothing is hardcoded. This file is the author-facing reference; the machine-checkable
definition is the JSON Schema set in [`schema/`](schema/):

| file | validates |
|---|---|
| [`schema/topic.schema.json`](schema/topic.schema.json) | one topic file, `assets/books/<book>/topics/<name>.yaml` |
| [`schema/book.schema.json`](schema/book.schema.json) | a bundle's `book.yaml` (metadata + contents tree) |
| [`schema/formulary.schema.json`](schema/formulary.schema.json) | a bundle's `formulary.yaml` (faceted drug list) |
| [`schema/index.schema.json`](schema/index.schema.json) | `assets/books/index.yaml` (the shelf) |

**If a file validates, the app renders it.** The schemas are written from the parser
(`lib/models/topic.dart`, `lib/models/book.dart` via `lib/data/library.dart`,
`lib/models/formulary.dart`) and `test/schema/schema_test.dart` holds the two together:
every bundled file must validate, and every key a parser reads must be a schema property
and vice versa. Unknown keys are errors on purpose, because the renderer ignores them
silently — a misspelt `warnings:` would otherwise drop content off the page with no sign.

## Validating

- **VS Code**: install the Red Hat YAML extension (`redhat.vscode-yaml`, recommended in
  `.vscode/extensions.json`). `.vscode/settings.json` maps the schemas onto
  `assets/books/**`, so you get red squiggles, key completion and hover help while typing.
  For a bundle outside this repo, put this on the first line of each topic file:
  `# yaml-language-server: $schema=https://fhir-fli.github.io/fhir_fli_documentation/orbweaver/schema/topic.schema.json`
  (the published copy; the same files live in this repo's `schema/`).
- **Command line** (from the repo root; checks schemas *and* cross-references — topic
  paths, topic ids, image files, flowchart `loopback`/`goto`/`loop_to` ids, `topic:` links):
  ```bash
  dart run tool/validate_book.dart assets/books          # every book on the shelf
  dart run tool/validate_book.dart path/to/my_bundle     # one bundle, anywhere
  ```
  Exit code 1 on any error. A missing image is a warning (the app draws a placeholder).
- **Any JSON Schema tool** works too, e.g. `check-jsonschema --schemafile schema/topic.schema.json topics/*.yaml`.

### Writing a topic with an LLM
`schema/topic.schema.json` is ~75 KB (about 18k tokens). Paste it, then one or two of the
existing topics as examples, then describe the page you want; validate what comes back
with any of the methods above before you look at it in the app.

## Book bundle

```
assets/books/<id>/book.yaml      metadata + contents tree (the map)
assets/books/<id>/cover.*        shelf cover
assets/books/<id>/topics/*.yaml  one self-contained topic each (flat folder)
assets/books/<id>/images/*       bitmaps topics reference
assets/books/<id>/formulary.yaml optional faceted drug list
```

`assets/books/index.yaml` lists book ids in shelf order. A bundle is portable: zip it to
share. This is the DITA **topic + map** model in YAML: a *topic* renders standalone, a
*map* (`book.yaml`) references topics and arranges them.

```yaml
book:
  id: "who_imci"                  # = folder name, listed in index.yaml
  title: "Hospital Care for Children"
  subtitle: "WHO Pocket Book, 2nd ed."
  cover: "cover.png"
  spine_color: "0xFF1565C0"       # 0xAARRGGBB | 0xRRGGBB | #RRGGBB
  view: "index"                   # optional: one-page directory instead of drill-down
  font_family: "RobotoCondensed"  # optional; must be a font the app bundles
  palette: { accent: "0xFF2E7D32" }
  contents:
    - topic: "topics/intro.yaml"          # LEAF
    - title: "6. Fever"                   # GROUP (chapter/section)
      palette: { accent: "0xFFC2185B" }   # re-skins this chapter
      children:
        - title: "6.2 Malaria"
          topic: "topics/who_6_02_malaria.yaml"     # optional overview page
          children:
            - topic: "topics/who_6_02_01_severe_malaria.yaml"
    - title: "Drugs"                      # COLLECTION: a faceted formulary
      view: "collection"
      formulary: "formulary.yaml"
    - title: "Procedures"
      appendix: true                      # footer bar in the `index` view
      children: [ ... ]
```

Paths are relative to the bundle folder. Keep content to ~3 levels. Topics stay in one
flat `topics/` folder; the tree lives only in `book.yaml`. A new bundle folder needs its
own lines in `pubspec.yaml` (Flutter asset globs are non-recursive).

## Topic envelope

```yaml
topic:
  id: "pb-example"              # kebab-case, unique across ALL books; link target
  title: "Example Topic"
  list_subtitle: "one line under the title in the contents"
  last_reviewed: "pocketbook v1.7"   # source version string, not a date
  tags: ["tag1", "tag2"]        # search keywords; `aliases:` are weighted the same
  category: "medical"           # universal | medical | trauma | critical_care
  layout: "scroll"              # scroll (default) | paged (each page snaps to a screen)
  palette: { alert: "0xFFC62828" }   # optional overrides, see Palette
  pages:                        # preferred form
    - page_number: 42           # printed page; drives the header badge
      blocks:
        - type: "prose"
          markdown: "…"
    - page_number: 43
      blocks: [ ... ]
```

Single-page form: top-level `page_number:` and `blocks:` instead of `pages:` (never both).

## Palette (cascade)

Every semantic colour the renderer draws is a named **role**; `lib/theme/palette.dart`
holds the defaults. A `palette:` map (`role: colour`) may appear on the book, a group, a
topic, and on most blocks; each level inherits its parent and overrides per role. Roles:
`accent` (titles, bullets, app bar; `accent_fill` / `accent_branch` derive from it),
`alert` / `alert_fill` / `alert_text` (the prose callout), `severity_{mild,moderate,severe}_{header,tile}`,
`provider_{emt,aemt,intermediate,paramedic,critical_care,any}`, `pop_{adult,peds}`,
`warning_{safety,caution}`, `flow_{decision,entry,convergence}`, `cc_link_{fill,border}`,
`note_{fill,border,text}`, `danger_text`, `node_border`, `section_rule`, `section_title`,
`box_border`, `dash_rule`, `dash_fill`, `peds_band_*`, `cc_band_*`, `call_er_*`.
Custom role names are allowed.

## Markdown, links, badges

Every `markdown:` field (and table cells) goes through MiniMarkdown: paragraphs separated
by blank lines, `**bold**`, `- ` bullets. Links: `[text](topic:<id>)` opens another topic
(any book), `[text](topic:<id>#<anchor>)`, `[text](#<anchor>)` scrolls within this topic,
`[text](https://…)` opens externally. Any block may declare `anchor: "<slug>"`; drug and
procedure cards get one for free from their name (`'3% Saline'` → `3-saline`). Provider
badges inline: `{E}` `{A}` `{I}` `{P}` `{P(CC)}` `{}`. Unresolved `topic:` links render inert.

## Block types

Fourteen. Every block has `type:`; most accept `anchor:` and `palette:`; `prose`,
`band_callout`, `table`, `arrows`, `row`, `column` accept `flex:` (share of a parent
`row`/`column`; children of a row should sum to 12).

### `prose`
```yaml
- type: "prose"
  title: "Optional section heading"
  markdown: |
    Text. **Bold** and `- ` bullets work. [Link](topic:who-imci-chart7)
  highlight: true        # tinted body
  callout: true          # attention card with the title as a chip
  dashed: true           # dashed outline for a callout (a conditional box)
  boxed: true            # rounded tile, for a grid cell inside a `row`
  text_scale: 0.8        # smaller body (references, URLs)
  call_er: true          # pairs the box with the "Call ER" tile (WVEMS)
  critical_care_link: { text: "[Ventilator](topic:wvems-2026-080)" }   # lavender CC tab under the box
```

### `band_callout`
```yaml
- type: "band_callout"
  band: "peds"           # peds | critical_care (pink / lavender band)
  title: "Pediatrics"    # omit for the default label; "" for a bare band
  markdown: "- Dose 0.1 mg/kg"
```

### `table`
```yaml
- type: "table"
  title: "Optional title"
  columns: ["Sign", "Adult", "Child"]     # [] = no header row
  column_flex: [4, 2, 2]                  # or column_widths: [120, 80, 80] with layout: scroll
  column_align: ["left", "right", "right"]
  column_tint: ["", "#FFF3E0", ""]        # "" = none
  column_bar: [false, true, true]         # in-cell magnitude bars for numbers
  zebra: true
  layout: "standard"     # standard | boxed (each cell a tile) | scroll (wide; fixed widths)
  sticky_header: true    # scroll layout
  sticky_first_column: true
  lookup: true           # "go to row" finder on the first column
  lookup_label: "Go to weight"
  max_height: 400
  rows:
    - title: "Optional banner above the row"
      header: "Row label"                 # left header column
      group: "Compression"                # contiguous same-group rows collapse
      severity: "emergency"               # none | emergency | priority | non_urgent
      cells:
        - "Plain cell, **bold** ok"
        - ["bullet one", "bullet two"]    # a list = bullets
        - { text: "spans two", span: 2 }  # object form: text | bullets, span
        - |
          Multi-line
          markdown
```

### `flowchart` — six variants (`variant:`, default `severity`)

Shared pieces: a **node** `{text, shape: rectangle|rounded_rectangle|stadium|diamond, bands: [{label, value, cc}], cc_title}`;
an **action** `{text, kind: procedure|medication_administration|diagnostic|assessment|referral|communication, provider_level: E|A|I|P|P(CC)|CC, timing, condition, peds_only}`;
a **warning** `{type: safety|caution, text}` (red octagon left / purple trapezoid right);
a **convergence** `{text, shape, bullets: [{text, link_id}], exits: [{label, loopback}], warnings}`;
`critical_care_link: {text, link_id}`; `dose_table: [{drug, dose, route, frequency, population: adult|peds|both}]`.
`entry_chain: [node, …]` or the shorthand `entry: node` (not both).

**`severity`** — entry → (decision) → parallel branches → convergence:
```yaml
- type: "flowchart"
  entry_chain: [{ text: "Unresponsive?", shape: "stadium" }]
  pre_decision_actions: [{ text: "12-Lead", kind: "diagnostic" }]
  decision: { text: "Pulse?", shape: "diamond" }
  branches:
    - id: "no-pulse"
      label: "No Pulse"
      severity: "emergency"
      criteria: ["Start CPR"]
      actions:
        - { text: "Epinephrine 1 mg IV", kind: "medication_administration", provider_level: "A", timing: "q 3–5 min" }
      continuation:
        entry_arrow_label: "Every 2 minutes"
        nodes: [{ text: "Rhythm check", shape: "rectangle" }]
    - id: "pulse"
      label: "Pulse"
      continues: true            # label + arrow only; flows into the next block
  convergence:
    text: "Re-assess ABC"
    exits:
      - { label: "Improvement", loopback: "pulse" }
      - { label: "No change" }   # forward arrow → post_convergence
  post_convergence: { text: "Continue cycles" }
  critical_care_link: { text: "Sepsis" }
  dose_table: [{ drug: "Epinephrine", dose: "1 mg", route: "IV", frequency: "q 3–5 min", population: "adult" }]
  warnings: [{ type: "safety", text: "Scene safety" }]
```

**`linear`** — one column, no branches: `steps:` of either `{type: content, title, bullets}`
boxes or action tiles (`{text, kind, provider_level, …}`); plus `entry_chain`, `convergence`,
`post_convergence`, `critical_care_link`, `dose_table`, `warnings`.

**`differential`** — decision into a grid of cards: `decision`, `cards: [{title, bullets}]`,
`columns: 2`, plus the shared tail.

**`cascade`** — yes/no chain:
```yaml
- type: "flowchart"
  variant: "cascade"
  entry: { text: "Meningitis suspected" }
  root:
    decision: "Signs of raised ICP?"
    criteria: ["Focal signs", "GCS < 8"]
    action_answer: "yes"                 # which answer takes `action`
    action: { text: "CT before LP", kind: "diagnostic" }
    continuation:                        # the other answer; recursive
      decision: "Coagulopathy?"
      action: { text: "Correct first" }
  terminal_action: { text: "Perform LP", kind: "procedure" }
  action_width: 0.4
```

**`algorithm`** — vertical multi-decision spine; loops are `goto` references, not arrows:
```yaml
- type: "flowchart"
  variant: "algorithm"
  entry: { text: "Hydrocarbon ingestion" }
  boxes:                                 # shared named boxes
    - { id: "treat", title: "Treatment", bullets: ["Oxygen", "Observe 6 h"] }
  stages:
    - decision: "Symptomatic?"
      criteria: ["Cough", "Tachypnoea"]
      outcomes:
        - { label: "Yes", goto: "treat" }
        - { label: "No", continue: true }
    - decision: "CXR abnormal?"
      outcomes:
        - { label: "Yes", box: { title: "Admit", severity: "emergency", table: { columns: ["Test", "Result"], rows: [["CXR", "infiltrate"]] } } }
        - { label: "No", box: { title: "Discharge", severity: "non_urgent" } }
  terminal: { title: "Reassess at 6 h" }
```
A box is `{id, title, bullets, severity, table: {columns, rows, align}}`; an outcome has
`box` or `goto`, and `continue: true` to rejoin the spine.

**`cycle`** — a spine whose side boxes can loop back to a node by id (drawn as a return arrow):
```yaml
- type: "flowchart"
  variant: "cycle"
  nodes:
    - { id: "assess", shape: "box", title: "Score CIWA-Ar" }
    - shape: "decision"
      title: "Score ≥ 10?"
      down_label: "once stable"
      branches:
        - label: "Yes"
          side: "right"
          box: { title: "Diazepam 10 mg", severity: "priority" }
          loop_to: "assess"
          loop_label: "reassess q1h"
    - { title: "Discharge planning" }
```

### `drug_card`
```yaml
- type: "drug_card"
  name: "Epinephrine"
  class: "Sympathomimetic"
  indications: ["Anaphylaxis"]
  contraindications: ["None in arrest"]
  doses:
    - { text: "0.01 mg/kg IM (1:1,000)", population: "peds" }
  warnings: ["Extravasation → necrosis"]
  pearls: ["1:10,000 = 1 mg in 10 ml"]
  image: "assets/books/wvems/images/form_ampoule.jpg"
  critical_care: true
```

### `procedure_card`
```yaml
- type: "procedure_card"
  name: "Needle Decompression"
  scope: "A"             # E | A | I | P | P(CC) | CC; omit for all levels
  image: "assets/books/wvems/images/eq_ivcath.jpg"
  steps:
    - "Locate 2nd intercostal space, mid-clavicular"    # numbered
    - "- over the top of the 3rd rib"                    # sub-bullet
    - "@2a Alternative site: 5th ICS anterior axillary"  # explicit label
    - "[I] Confirm with capnography"                     # inline scope chip
    - ":[I] Sedation only if credentialed"               # dashed emphasis
    - "!Peds: 18–20 g catheter"                          # pink peds band
    - "^Critical Care: finger thoracostomy"              # lavender CC band
    - "~[E] EMTs assist only"                            # standalone scope note
    - "NOTE: reassess after each attempt"                # full-width note
```

### `image`
```yaml
- type: "image"
  path: "assets/books/who_imci/images/chart7.png"
  caption: "Optional"
  size: "full"           # small | medium | large | full
```

### `row` / `column` / `arrows` / `merge_arrows` — layout
```yaml
- type: "row"
  blocks:
    - { type: "prose", flex: 3, boxed: true, markdown: "**Treat**" }
    - type: "column"
      flex: 6
      blocks:
        - { type: "prose", boxed: true, markdown: "**Treat presumptively**" }
        - type: "row"
          blocks:
            - { type: "prose", boxed: true, markdown: "Order **RDT**" }
            - { type: "prose", boxed: true, markdown: "Order **B/S**" }
    - { type: "column", flex: 3, blocks: [] }     # empty column = spacer
- type: "arrows"
  count: 4               # evenly spaced down arrows
  label: "Yes"
  inline: true           # label beside the arrow
  direction: "down"      # down | right (right needs count 1); length: 24
- type: "merge_arrows"
  columns: 12
  sources: [1, 4, 7]     # column indices of the top arrows
  target_center: 2.5     # where the single merged arrow lands
```

### `conversion` — interactive dose converter
```yaml
- type: "conversion"
  mode: "equivalence"    # equivalence (factor to a reference) | tiers (fixed strengths)
  title: "Opioid equianalgesia"
  reference: "oral morphine"
  reference_label: "MME"
  unit: "mg"
  source: "…"            # shown; required for clinical safety
  agents:
    - { name: "Morphine", route: "PO", factor: 1 }
    - { name: "Hydromorphone", route: "PO", factor: 4 }
  excluded:
    - { name: "Methadone", reason: "non-linear conversion" }
  caveats: ["Reduce 25–50% for incomplete cross-tolerance"]
# tiers mode: tiers: ["low", "moderate", "high"], tier_note, and per agent doses: [{dose: 10, tier: "moderate"}]
```

### `formula` — numbers in → number out
```yaml
- type: "formula"
  kind: "map"            # a built-in: renal_function, map, corrected_sodium, anion_gap, aa_gradient,
                         # winters, ideal_body_weight, holliday_segar, meld3, qtc, free_water_deficit,
                         # anthropometrics, osmolal_gap, parkland, urinary_indices, anc, reticulocyte,
                         # lights, fib4, maddrey, oxygenation, dday_age, lille, prevent_ascvd,
                         # glasgow_blatchford, adrogue_madias, hba1c_eag
  title: "Mean arterial pressure"
  source: "…"
  inputs:
    - { key: "sbp", label: "Systolic", type: "number", unit: "mmHg" }
    - { key: "dbp", label: "Diastolic", type: "number", unit: "mmHg", default: 80 }
    - { key: "sex", label: "Sex", type: "select", options: [{ value: "m", label: "Male" }, "f"] }
    - { key: "on_dialysis", label: "On dialysis", type: "boolean", optional: true }
  notes: ["MAP = DBP + (SBP − DBP)/3"]
  caveats: []
```
The math is compiled into the app (`lib/data/formula_registry.dart`); YAML cannot add kinds.

### `score` — criteria → points → band
```yaml
- type: "score"
  title: "CHA₂DS₂-VASc"
  unit: "points"
  source: "…"
  items:
    - { key: "chf", label: "Heart failure", type: "toggle", points: 1 }
    - key: "age"
      label: "Age"
      type: "choice"      # toggle | choice (chips) | scale (stepper)
      options:
        - { value: "lt65", label: "< 65", points: 0 }
        - { value: "65_74", label: "65–74", points: 1 }
      default: "lt65"
  bands:
    - { min: 0, max: 0, label: "Low", severity: "none" }        # none | info | warn | alert
    - { min: 2, label: "High", detail: "Anticoagulate", severity: "alert" }   # no max = open-ended
  notes: []
  caveats: []
```

## Formulary (`formulary.yaml`)

```yaml
formulary:
  id: "who_formulary"
  title: "Drugs"
  subtitle: "…"
  intro: "optional markdown above the A–Z list"
  bands:     { label: "Dose by body weight (kg)", columns: ["3–<6", "6–<10"] }
  bands_art: { label: "…", columns: [] }
  facets:
    - { key: "alpha", label: "A–Z", mode: "alpha", tap: "detail" }
    - { key: "class", label: "By class", mode: "group", field: "class", tap: "detail" }
    - { key: "indication", label: "By indication", mode: "group", field: "indications", tap: "expand" }
  classes:     [{ key: "antibiotic", label: "Antibiotics" }]
  indications: [{ key: "pneumonia", label: "Pneumonia" }]
  drugs:
    - id: "amoxicillin"
      name: "Amoxicillin"
      class: "antibiotic"            # must be a key in `classes`, or the drug is missing from that lens
      subtitle: "penicillin"
      indications: ["pneumonia"]     # keys in `indications`
      axis: "main"                   # main | art
      page: 330
      regimen: "…"
      doses:
        - { label: "Oral", form: "250 mg tablet", regimen: "40 mg/kg twice daily", bands: ["½", "1"] }
      notes: "…"
    - { id: "morphine", name: "Morphine", class: "analgesia", dose: "**Adult** 2–10 mg IV" }  # prose-dosed form
```

## Shared enums

| Field | Values |
|---|---|
| `category` (topic) | `universal` (default), `medical`, `trauma`, `critical_care` |
| `layout` (topic) | `scroll` (default), `paged` |
| `severity` (branch / row / box / node) | `none` (default), `emergency`, `priority`, `non_urgent` |
| `severity` (score band) | `none` (default), `info`, `warn`, `alert` |
| `shape` (flow node) | `rectangle` (default), `rounded_rectangle`, `stadium`, `diamond` |
| `shape` (cycle node) | `box` (default), `decision` |
| `kind` (action) | `procedure` (default), `medication_administration`, `diagnostic`, `assessment`, `referral`, `communication` |
| `provider_level` / `scope` | `E`, `A`, `I`, `P`, `P(CC)`, `CC`; omit for any |
| `population` (dose) | `adult`, `peds`, `both` (default) |
| `size` (image) | `small`, `medium` (default), `large`, `full` |
| `layout` (table) | `standard` (default), `boxed`, `scroll` |
| `variant` (flowchart) | `severity` (default), `cascade`, `linear`, `differential`, `algorithm`, `cycle` |
| `action_answer` (cascade step) | `yes` (default), `no` |
| `band` (band_callout) | `peds`, `critical_care` (also `pediatrics`, `cc`) |
| `type` (warning) | `safety`, `caution` |
| `mode` (conversion) | `equivalence` (default), `tiers` |
| `type` (formula input) | `number` (default), `select`, `boolean` |
| `type` (score item) | `toggle` (default), `choice`, `scale` |

## Conventions

- Filenames: `pb_<stem>.yaml` (ProtocolBook), `wvems_*`, `who_*`, `calc_*` / `conv_*`; 2-space indent.
- `id` is the stable logical identity; filenames are storage. Never reuse an id across books.
- `last_reviewed` holds the source version, not a date.

## Extending the schema

When a page needs something the schema cannot say:

1. Add the field or class in `lib/models/topic.dart` and its `fromYaml` parser.
2. Extend the renderer in `lib/widgets/`.
3. Add the property to `schema/topic.schema.json` (with a `description`), and the example
   above. `test/schema/schema_test.dart` fails until the parser and the schema agree.
4. Commit schema, renderer, content in that order.
