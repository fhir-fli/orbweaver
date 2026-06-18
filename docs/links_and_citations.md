# Design: links, anchors & citations

Status: **Links + anchors IMPLEMENTED (2026-06-18); citations not yet built.**
Implemented: inline `[text](target)` in MiniMarkdown — `topic:<id>` cross-
topic nav (reuses `LibraryIndex`/`openLinkedTopic`), external URLs via
`url_launcher`, same-topic `#<anchor>` scroll (`anchor:` field on any block +
`AnchorScope`). Not yet: cross-topic `#anchor` scroll (opens topic top), and
all of §2 Citations. Settled 2026-06-18. Principle:
use established markup conventions, invent nothing. (There is no
YAML-native link standard — links live inside the markdown string values,
so these are the established *markup* conventions applied inside our fields.)

## 1. Links

### Syntax — CommonMark
Plain `[text](target)`. Standard, universal. Add inline-link parsing to
`MiniMarkdown` (it currently has none).

### Targets
| Target | Meaning |
|---|---|
| `topic:<id>` | cross-topic link by **logical id** (path-independent; works **cross-book**) |
| `topic:<id>#<anchor>` | cross-topic + scroll to a block anchor |
| `#<anchor>` | jump within the current topic |
| `https://…`, `mailto:…` | external (opened via OS; offline-aware — never hard-fail) |

`topic:` is a **custom URI scheme** — the standard, RFC-3986 mechanism for
app-defined link targets (exactly how `mailto:`/`tel:`/app deep-links work).
We are not inventing syntax, only declaring a scheme. `#fragment` is the
universal anchor convention (URLs / HTML ids / Markdown headings).

### Anchors
Any block may declare an explicit `anchor: "<slug>"`. The renderer scrolls
to that block's `GlobalKey` — **reusing the existing scroll + GlobalKey +
`RenderAbstractViewport.getOffsetToReveal` machinery** from the sticky
page-badge system (extend from per-page to per-anchor). Explicit slugs
(not title-derived) so links survive title edits.

```yaml
- type: "prose"
  anchor: "shock-fluids"
  title: "If shock persists"
  markdown: "…see [Chart 7](topic:who-imci-chart7-iv-fluids-shock) …"
```

### Resolution
- `topic:<id>` reuses the existing `LibraryIndex` (already spans the whole
  library) + `openLinkedTopic` — an unresolved id is an **inert** link
  (graceful for pasted/standalone topics), the behavior we already have.
- The existing flowchart `link_id` fields (`ConvergenceBullet`,
  `CriticalCareLink`) stay and resolve through the same id resolver.

## 2. Citations

### Storage — structured, per topic, offline-complete
A `citations:` list in the topic envelope. **`text` is required and must be
a complete reference** (visible with no internet). `doi`/`url` optional —
opened externally only when online.

```yaml
citations:
  - key: feast
    text: "Maitland K, et al. Mortality after Fluid Bolus in African Children
           with Severe Infection. N Engl J Med. 2011;364(26):2483-95."
    doi: "10.1056/NEJMoa1101549"
```

**Granularity is per-topic** (the topic is our atom; a pocket-reference page
carries its own sources). Per-book/chapter is too coarse to tie a claim to
a source.

### Inline markers — Pandoc / GFM footnote syntax
`[^key]` in the markdown body (established: Pandoc, GitHub-Flavored Markdown,
most static-site generators). It renders as a superscript marker that links
to the References section; `key` matches a `citations:` entry.

```
…cautious boluses, not aggressive resuscitation [^feast].
```

### Rendering
A **"References" section auto-rendered at the topic end**, listing the
declared citations (text + optional tappable DOI). Inline `[^key]` markers
are always optional — many pages just want the list; the protocols
(e.g. Chart 7) use markers for claim-level attribution.

### Closes a loop
Our OpenEvidence reviews already produce citations (Chart 7 cites
FEAST/SSC/PALS), but they live in header comments + `last_reviewed`,
invisible to users. Moving them into `citations:` surfaces that evidence as
user-visible provenance.

## 3. Shared foundation

All three features — internal links, citation markers, and the conversion
block's external DOI links — depend on the **same MiniMarkdown inline-link
parsing**. Build it once.

**Build order when implementing:**
1. `MiniMarkdown` inline links (`[text](target)`) + footnote markers (`[^key]`)
   → a small resolver mapping target scheme to action (navigate topic /
   scroll anchor / open url / jump to citation).
2. Anchor scroll-to system (`anchor:` field + GlobalKey registry in
   `topic_view`).
3. `citations:` model + the auto "References" section renderer.

## 4. Decisions locked (2026-06-18)
- Link syntax: **CommonMark `[text](topic:id#anchor)`** (not wikilinks).
- Anchors: **explicit `anchor:` field** on blocks.
- Citations: **per-topic**, **both** a references list **and** optional
  `[^key]` markers, **text-first with optional DOI** (offline-aware).
