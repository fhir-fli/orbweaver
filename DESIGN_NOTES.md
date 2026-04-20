# Orbweaver Design Notes

Captured from a design discussion on 2026-04-17. These are architectural
bearings for the project — not a spec. They supplement the schema in
`lib/models/topic.dart` and the authored topics in `assets/topics/`.

## Framing: this is a DSL, not a clinical informatics standard

The YAML block schema is a **domain-specific language** for authoring
clinical pocket-reference content. Authors don't write arbitrary YAML —
they pick a block type and fill in its fields.

Relevant prior art lives in the DSL / structured-authoring world, not the
clinical informatics standards world:
- Fowler, *Domain-Specific Languages*
- Static site generator schemas (Jekyll, Hugo, Docusaurus frontmatter)
- MDX / Notion's block model
- Sphinx directives

When weighing schema decisions, ask "what's the right DSL shape for this
domain?" — not "is there a FHIR/BPMN/GLIF pattern for this?" The answer is
consistently closer to Docusaurus than to PlanDefinition.

## What orbweaver is not (and does not need to be)

Several established clinical-knowledge standards exist. None of them fit,
and it's useful to know *why* so we don't drift toward them:

| Standard | Purpose | Why it doesn't fit |
|---|---|---|
| FHIR PlanDefinition + CQL | Executable order sets / decision support, EHR interop | Designed for machines to execute, not clinicians to render. Verbose, heavy terminology binding, CQL is the wrong authoring surface. |
| GLIF, PROforma, Asbru, EON, GLARE, SAGE | Shareable computer-interpretable guidelines | Same execution-first framing. Mostly dead standards. |
| Arden Syntax | Medical logic modules (if-then rules) | Alerting, not reference rendering. |
| BPMN | Business process modeling | Process execution, not point-of-care reference. |

The 20-year Computer-Interpretable Guidelines (CIG) research track
documents the tar pit: authoring is always harder than expected, execution
models are always too rigid for real clinical flow, and the few efforts
that survived narrowed their scope. Orbweaver's scope — **mobile rendering,
no execution** — is precisely the niche that avoids the tar pit. Stay in
the niche.

## Phase sequencing

Three phases, in order. Phase 1 must not *preclude* later phases, but it
should not *anticipate* them either.

1. **Phase 1 (current): authoring → rendering.** YAML topics render in
   Flutter. No terminology binding, no FHIR, no EHR integration. Content
   is a static reference guide that happens to be structured data instead
   of a PDF. *This is the product.*

2. **Phase 2 (future, maybe): terminology annotation.** Bind action
   strings to standard codes (LOINC for labs, RxNorm for meds, SNOMED for
   procedures). Done as a **mapping table**, not by forcing codes into the
   YAML authoring surface. Authors still write "troponin"; the mapping
   table resolves it at export time.

3. **Phase 3 (hypothetical): FHIR export.** Generate PlanDefinition /
   ActivityDefinition from annotated YAML for interop with EHRs or
   registries. **Trigger only when an external consumer needs it.** The
   composability of "MI workup = HR + BP + troponin + EKG" does not by
   itself justify Phase 3 — it's a DSL feature (YAML anchors, `$ref`
   convention) and can be delivered in Phase 1 without any FHIR weight.

## Vocabulary strategy: bottom-up extraction

Traditional informatics is top-down: pick codes from LOINC/SNOMED/RxNorm,
author against those codes. Orbweaver should go bottom-up: extract the
vocabulary that already appears in trusted pocket references.

Source corpora (all already in repo root):
- `ProtocolBook eBook 1.7.pdf` (Grey's book — primary)
- `9789241548373_eng.pdf` (WHO Pocket Book of Hospital Care for Children)
- `2026-WVEMS-Protocols.pdf`
- `Pocket Medicine, Fifth Edition ... Sabatine.mobi` (optional; scope creep risk)

Rough working-vocabulary estimate for acute-care medicine + paediatrics in
resource-variable settings:
- ~150–250 labs
- ~30–50 imaging studies
- ~300–500 medications
- ~100–200 procedures
- ~500–1000 conditions

That's the 95% of what a hospitalist actually orders. Small enough to
curate by hand once extracted; large enough that free-text authoring would
produce inconsistent strings.

**Risk to name:** a corpus-only vocabulary loses interoperability — it's
still just strings. That's acceptable for Phase 1 (authoring consistency
is the goal). Phase 2 addresses it with the mapping table; authors never
have to see a LOINC code.

**Implementation path (Phase 1 version):** don't build the extraction
pipeline yet. Maintain a running list of labs/meds/procedures as topics are
authored. After 50–100 topics, that list *is* the vocabulary. Then build
autocomplete.

## Schema insight: the PALS algorithm is a different genre

The three "gaps" that p.13 PALS surfaced — multi-node entry chain,
post-convergence action block, loop-back edges — are **not independent
gaps**. They are all symptoms of the same underlying shape mismatch.

The current `severity` flowchart variant assumes a **funnel shape**:
entry → decision → parallel branches → optional convergence → done. That
shape fits WHO-IMCI triage ("sort this patient into severity tier X, do
action list Y") but doesn't fit resuscitation algorithms, which are
fundamentally **state machines**: nodes with arbitrary incoming and
outgoing edges, loops, and re-entry.

**Implication:** don't keep bolting extensions onto the severity variant
for each resuscitation-specific need. That road ends at a graph in all but
name. Instead, introduce a separate block type for the resuscitation/code
genre when it has earned its keep — a declarative node-and-edge graph
(nodes have ids, types, content; edges have labels, conditions, optional
loop-back semantics).

Different clinical genres → different block types. The severity variant
stays clean for WHO-IMCI-style decision tables; a future `graph_flowchart`
or similar handles ACLS/PALS/ATLS/NRP. Expect the three "gaps" to recur
across those algorithms because they are the same genre.

**Decision rule:** don't introduce `graph_flowchart` speculatively. Author
p.13 PALS using the current schema as far as possible (prose + severity
flowchart + prose, accepting loss of visual loop-backs). Author 2–3 more
resuscitation-style pages. If the same three gaps recur, that's the signal
to split the variant. If they don't, the current schema was fine.

## Rejected designs (for the record)

- **`cycle` flowchart variant for ACLS-style loops.** Rejected in favor of
  `TopicAction.timing` + `condition` annotations on actions within
  existing variants. Revisit if the PALS-genre block type is introduced —
  a graph variant would subsume this anyway.
- **Aligning YAML schema with FHIR PlanDefinition now.** Premature. The
  authoring surface and the interop surface have different optimization
  targets; forcing them to share a schema compromises both.

## Open questions

- When (if ever) to introduce a graph-style flowchart block. Currently:
  wait for recurrence across ≥3 authored resuscitation pages.
- Whether to support YAML-level `$ref` / anchor composition for reusable
  action groups ("MI workup") in Phase 1, or defer. Leaning toward defer
  until an authored page actually needs it.
- Whether Pocket Medicine should contribute to the extracted vocabulary.
  Probably yes with a frequency filter (entities appearing in ≥2
  protocols); no to including rare subspecialty content wholesale.
