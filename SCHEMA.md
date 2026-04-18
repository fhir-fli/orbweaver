# Orbweaver Topic Schema — Authoring Reference

Every page of the ProtocolBook is authored as a single YAML file under `assets/topics/` and added as an entry to `lib/screens/topic_list_screen.dart`. The schema is defined in `lib/models/topic.dart`; this file is the author-facing index.

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

### `row` — side-by-side layout primitive

```yaml
- type: "row"
  blocks:
    - type: "table"
      # ...
    - type: "table"
      # ...
```

Renders child blocks in a `Row` with `IntrinsicHeight + CrossAxisAlignment.start`. Each child gets `Expanded` (equal horizontal share). Any block type can nest inside, including nested rows.

Use this when two narrow blocks read better alongside each other than stacked (e.g. p.16 age-based and height-based weight tables).

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
