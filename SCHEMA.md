# Orbweaver Topic Schema — Authoring Reference

Every page is authored as a single self-contained YAML **topic** file under a book bundle's `topics/` folder, and referenced from that book's `book.yaml` (the **map**). The topic schema is defined in `lib/models/topic.dart` and the book/map model in `lib/models/book.dart`; this file is the author-facing index.

This split is the **topic + map** model — the same architecture as DITA (an OASIS standard) and its lightweight, non-XML cousins (MkDocs `nav:`, Antora, Sphinx `toctree`): a *topic* is a titled unit of content that renders standalone in any context, and a *map* references topics and arranges them into a hierarchy. Orbweaver is **DITA-aligned, not DITA-conformant** — we express the model in YAML and keep our own block vocabulary (below), which is the documented *specialization* where no existing standard captures precise clinical layout. We deliberately do **not** use XML.

## Topic envelope

```yaml
topic:
  id: "pb-example"             # kebab-case; usually matches filename stem
  title: "Example Topic"
  last_reviewed: "pocketbook v1.7"  # source version string, not a date
  tags: ["tag1", "tag2"]
  category: "medical"          # universal | medical | trauma | critical_care
  page_number: 42              # source book page; drives the header badge

  blocks:
    - type: "..."              # one entry per block, rendered top-to-bottom
```

Optional top-level fields: `version`, `aliases` (list of strings).

## Book structure — the map (`book.yaml`)

A book bundle lives at `assets/books/<id>/` and is portable (zip it to share):

```
assets/books/<id>/book.yaml      metadata + contents tree (the map)
assets/books/<id>/cover.*        shelf cover
assets/books/<id>/topics/*.yaml  one self-contained topic each (flat folder)
assets/books/<id>/images/*.png   bitmaps topics reference
```

`assets/books/index.yaml` lists book ids in shelf order. `book.yaml` carries a
**`contents:`** tree that references topic files and arranges them into
chapters/sections:

```yaml
book:
  id: "who_imci"
  title: "Hospital Care for Children"
  cover: "cover.png"
  spine_color: "0xFF1565C0"        # 0xAARRGGBB | #RRGGBB
  contents:
    - topic: "topics/intro.yaml"   # a LEAF — a bare topic reference
    - title: "6. Fever"            # a GROUP — a chapter/section
      children:
        - title: "6.2 Malaria"
          topic: "topics/who_6_02_malaria.yaml"   # optional GROUP OVERVIEW page
          children:
            - topic: "topics/who_6_02_01_severe_malaria.yaml"
            - topic: "topics/who_6_02_02_uncomplicated_malaria.yaml"
```

- A **leaf** is `{ topic: <path> }`.
- A **group** has a `title:` (fold the outline number in, e.g. `"6.2 Malaria"`),
  a list of `children:`, and an optional `topic:` — its own overview page
  (a group may be both an openable page *and* a parent).
- Paths are relative to the bundle dir. The topic file owns its row metadata
  (`title` / `list_subtitle` / `tags`); the map only orders and references.
- **Depth:** the model is recursive (any depth), but keep real content to ~3
  levels (chapter → section → subsection) — the established TOC-readability
  convention; the source book rarely goes deeper.
- **File layout:** topics stay in one flat `topics/` folder with
  outline-numbered names (e.g. `who_6_02_01_severe_malaria.yaml`); the tree
  lives only in `book.yaml`. (Flutter asset globs are non-recursive, so nested
  folders would each need a `pubspec.yaml` line — and a new bundle subdir still
  does.)

Rendering: a book with top-level groups drills down (chapter → accordion of
sections/subsections); a flat book (only leaves) renders as a list; search
flattens the whole tree.

## Color palette (cascade)

Every semantic ("attention") color the renderer draws is a named **role**
(see `lib/theme/palette.dart` for the full default set). A `palette:` map —
`role: "0xAARRGGBB"` (or `"#RRGGBB"`) — may be declared at three levels and
**cascades**: **book → chapter (group) → topic**. Each level inherits its
parent's palette and overrides per-role; an orphaned/pasted topic falls back
to the defaults + a neutral accent. A topic may also declare its own
`palette:` in frontmatter. Custom role names are allowed and can be read by
content.

```yaml
# book.yaml — book-level default + per-chapter override
book:
  palette:
    accent: "0xFF2E7D32"          # whole-book accent
  contents:
    - title: "6. Fever"
      palette:
        accent: "0xFFC2185B"      # this chapter re-skins itself
      children: [ ... ]
```

Key roles: `accent` (titles, bullets, app bar, TOC bar; `accent_fill` /
`accent_branch` derive from it unless set), `alert` / `alert_fill` /
`alert_text` (the prose `callout`), `severity_{mild,moderate,severe}_{header,tile}`,
`provider_{emt,intermediate,als,paramedic,any}`, `pop_{adult,peds}`,
`warning_{safety,caution}`, `flow_{decision,entry,convergence}`,
`cc_link_{fill,border}`, `note_{fill,border,text}`, `danger_text`. Nothing is
hardcoded at a use site — override any role at any level to recolor it.

The WHO Pocket Book uses this to color-code by chapter (Ch.1 = magenta);
WVEMS declares each section's accent (+ `accent_fill`/`accent_branch`) so its
protocols keep their blue/green/orange/purple identity.

## Block types

### `prose` — markdown text

```yaml
- type: "prose"
  title: "Optional heading"      # rendered as a bold sub-header above markdown
  highlight: true                # true = tinted pink callout container; default false
  markdown: |
    Plain text paragraphs separated by blank lines.

    **Bold** works. `- ` at line start makes a bullet.
    Numbered lists (`1.`) render as plain text — MiniMarkdown doesn't
    handle them specially yet.
```

### `table` — columns + rows with optional severity tinting

```yaml
- type: "table"
  title: "Optional block-level title"
  columns: ["Col A", "Col B", "Col C"]     # empty list = no header row
  rows:
    - title: "Optional row banner"          # bold heading above the cells
      header: "Row label"                   # optional left-column header
      group: "Group name"                   # collapses contiguous same-group rows
      severity: "emergency"                 # none | emergency | priority | non_urgent
      cells:
        - "Simple string cell"              # renders through MiniMarkdown → **bold** works
        - text: "Wider cell"                # map form for span / explicit markdown
          span: 2                           # covers 2 column-widths
        - ["bullet one", "bullet two"]      # YAML list → bullet cell
        - |
          Multi-line string
          becomes a MarkdownCell
```

**Cell forms:** bare string (single-line, renders with `**bold**` support); bare string containing `\n` or a `|` block scalar (multi-line markdown); YAML list (bullet list); map `{text, span?, bullets?}` (for explicit span or markdown control).

**Severity colours (WHO-IMCI palette):** `emergency` = light pink, `priority` = light yellow, `non_urgent` = light green, `none` = default.

### `flowchart` — severity variant

```yaml
- type: "flowchart"
  variant: "severity"

  # Optional chain of sequential nodes before the branch fork.
  # Single-node form also accepted: `entry: { text: "...", shape: "..." }`.
  entry_chain:
    - text: "Node 1 text"
      shape: "rectangle"       # rectangle | rounded_rectangle | stadium | diamond
    - text: "Node 2 text"
      shape: "diamond"

  # Optional — usually unneeded when the branches themselves carry the
  # decision (e.g. "< 60 bpm" vs "> 60 bpm" with severity colours).
  decision:
    text: "Severity?"
    shape: "diamond"

  branches:
    - id: "branch-a"                        # used by loopback references
      label: "Branch label"
      severity: "emergency"                 # drives WHO-IMCI tint on the branch
      criteria:
        - "Bullet criterion under the label"
      actions:
        - text: "Action description"
          kind: "procedure"                 # procedure | medication_administration | diagnostic | assessment | referral | communication
          provider_level: "A"               # A (ALS) | E (EMT) | I (Intermediate) | default = any
          timing: "every 5 min"             # optional annotation
          condition: "if VT/VF"             # optional annotation
      continuation:                         # optional per-branch downstream chain
        entry_arrow_label: "Every 2 minutes"
        nodes:
          - text: "Follow-up node"
            shape: "rectangle"

  convergence:                              # optional
    text: "Re-assess ABC"
    shape: "rounded_rectangle"
    bullets:                                # legacy — plain bullet list inside the box
      - text: "Bullet one"
    exits:                                  # labeled arrows leaving the box
      - label: "Improvement"
        loopback: "branch-a"                # arrow loops back to the top of branch "branch-a"
      - label: "No change"                  # no `loopback` → forward arrow to post_convergence

  post_convergence:                         # optional — one more box below the convergence
    text: "Continue cycles ..."
    shape: "rectangle"

  dose_table:                               # optional — medication dose reference at the bottom
    - drug: "Epinephrine"
      dose: "1 mg IV"
      route: "IV"
      frequency: "q 3–5 min"
      population: "adult"                    # adult | peds | both
```

**Rendering notes for `severity`:**
- Branches with `severity` get tinted label bands and tile backgrounds.
- The decision fork renders one `▼` arrow per branch column (not a single centered arrow).
- When a convergence has a loopback exit, the convergence row becomes a 2-column layout `[Reassess | → Waypoint]` with painted arrows going back up to the loopback target.
- When only one branch has a `continuation`, those nodes render full-width below the branches row; when both do, they render in two columns aligned to their source branches.

### `flowchart` — cascade variant

Used for linear yes/no question chains (e.g. pre-procedure contraindication checklists).

```yaml
- type: "flowchart"
  variant: "cascade"
  entry:
    text: "Chain title / indication"
    shape: "rectangle"
  root:
    decision: "First yes/no question?"
    criteria:
      - "Optional bullet detail"
    action_answer: "yes"                    # which answer triggers `action`; default yes
    action:                                  # taken on the action_answer
      text: "Terminal action"
      kind: "procedure"
    continuation:                            # taken on the opposite answer
      decision: "Second yes/no question?"
      # ... same shape, recursive
  terminal_action:                            # fires if every step falls through without matching
    text: "Default terminal action"
    kind: "procedure"
  action_width: 0.5                           # fraction of cascade width for the action column
```

### `drug_card` — canonical drug reference

```yaml
- type: "drug_card"
  name: "Epinephrine"
  class: "Sympathomimetic / vasopressor"
  indications:
    - "Anaphylaxis"
    - "Cardiac arrest"
  contraindications:
    - "None in arrest"
  doses:
    - text: "0.01 mg/kg IM (1:1,000) — repeat q 5 min"
      population: "peds"                    # adult | peds | both
    - text: "0.3–0.5 mg IM (1:1,000) — repeat q 5 min"
      population: "adult"
  warnings:
    - "Extravasation causes tissue necrosis"
  pearls:
    - "1:10,000 = 1 mg in 10 ml — IV/IO arrest dose"
  image: "assets/images/epi_vial.png"       # optional
```

### `image` — figure with caption

```yaml
- type: "image"
  path: "assets/images/figure.png"
  caption: "Optional caption"
  size: "medium"                            # small | medium | large | full
```

### `row` / `column` — layout primitives

```yaml
- type: "row"
  blocks:
    - type: "prose"
      flex: 3
      boxed: true
      markdown: "**Treat**"
    - type: "column"
      flex: 6
      blocks:
        - type: "prose"
          boxed: true
          markdown: "**Treat presumptively**"
        - type: "row"
          blocks:
            - type: "prose"
              boxed: true
              markdown: "Order **RDT**"
            - type: "prose"
              boxed: true
              markdown: "Order **B/S**"
    - type: "prose"
      flex: 3
      boxed: true
      markdown: "**Don't treat**"
```

`row` lays children out in a `Row` with `IntrinsicHeight`; `column` stacks them in a `Column`. Both use a 6px gap between children.

**Use a 12-column grid convention.** Each `row`'s children's `flex` values should sum to 12. This keeps rows aligned across a page — a row of `[6, 6]` sits under a row of `[3, 3, 3, 3]` with cells lining up. 12 divides evenly into halves, thirds, quarters, and sixths; no content in the ProtocolBook or WVEMS protocols needs a finer split. Tables have their own `span` field per cell (which also should sum to 12).

Any block type can nest inside. `prose` gains a `boxed: true` flag that renders it as a rounded-border centered tile, matching boxed-layout table cells — useful when a prose block is acting as a grid cell.

### `arrows` — down or right arrow(s) spanning a row

```yaml
- type: "arrows"
  count: 4            # evenly-spaced down arrows
- type: "arrows"
  direction: "right"  # horizontal arrow (count must be 1)
  label: "No"
  length: 24
- type: "arrows"
  count: 1
  label: "Yes"
  inline: true        # label beside the arrow, not stacked above
```

Use between rows of a flow-grid to indicate flow direction. `count` is the number of evenly-spaced arrows; `label` optionally annotates them; `inline: true` puts the label beside the glyph (saves a line when the arrow is on its own row).

### `merge_arrows` — N arrows converging to 1

```yaml
- type: "merge_arrows"
  columns: 12            # grid width
  sources: [1, 4, 7]     # col indices of top arrows
  target_center: 2.5     # col index (fractional ok) of merged arrow
```

Used when several grid cells funnel into a narrower target below (e.g. three "treat" outcomes merging into a half-width severe-signs box). Renders top short arrows at each source col, a horizontal connector joining their bases, a vertical stub descending from `target_center`, and a final longer arrow landing at `target_center`.

## Shared enums

| Field | Values |
|-------|--------|
| `category` (topic) | `universal`, `medical`, `trauma`, `critical_care` |
| `severity` (branch / row) | `none` (default), `emergency`, `priority`, `non_urgent` |
| `shape` (flow node) | `rectangle` (default), `rounded_rectangle`, `stadium`, `diamond` |
| `kind` (action) | `procedure` (default), `medication_administration`, `diagnostic`, `assessment`, `referral`, `communication` |
| `provider_level` | `A` (ALS), `E` (EMT), `I` (Intermediate); omit for any |
| `population` (dose) | `adult`, `peds`, `both` (default) |
| `size` (image) | `small`, `medium` (default), `large`, `full` |
| `action_answer` (cascade step) | `yes` (default), `no` |

## Conventions

- **Filename:** `pb_<topic_stem>.yaml` for ProtocolBook pages; `wvems_*` for WVEMS; `who_*` for WHO IMCI.
- **Topic id:** kebab-case matching the filename stem.
- **`last_reviewed`:** holds source version, not a date.
- **YAML indentation:** 2 spaces. Lists are `-` prefixed.
- **After creating a new topic file:** add an entry to `lib/screens/topic_list_screen.dart` so it appears in the app's topic list.

## Common clinical patterns

| Pattern | Block types | Example |
|---------|-------------|---------|
| Triage matrix (emergency / priority / non-urgent rows) | `table` with row `severity` + `title` | p.12 |
| Resuscitation algorithm with reassess loop | `flowchart` with entry_chain + convergence.exits loopback + post_convergence | p.13 |
| Asymmetric algorithm (one branch continues, other terminates) | `flowchart` with `branch.continuation` | p.14 |
| Comparison across populations | `table` with cell `span` | p.15 |
| Reference lookup (narrow 2-column tables) | `row` of two `table` blocks | p.16 |
| Drug quick-reference card | `drug_card` | — |
| Pre-procedure contraindication chain | `flowchart` variant `cascade` | p.55 |

## Extending the schema

When a page needs a feature not in the schema:

1. Add the field / class in `lib/models/topic.dart` and its `fromYaml` parser.
2. Extend the relevant renderer(s) in `lib/widgets/`.
3. Update this file with the new field in the right block section.
4. Commit in the standard three-part cadence: schema, renderer, content.
