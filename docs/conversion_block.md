# Design: the `conversion` block (interactive dose conversion)

Status: **IMPLEMENTED (2026-06-18).** Both modes built and verified on-device
(`ConversionBlock` in topic.dart; `conversion_block_view.dart`). Live
content: Conversions book with opioid (MME) + benzodiazepine (diazepam-eq)
`equivalence` converters and a statin `tiers` matrix — all carrying
illustrative factors **pending OpenEvidence review**. The open §8 ideas
(cross-tolerance reduced-range line; methadone/patch sub-tool) remain future
work. Original design discussion below (2026-06-18).

## 1. Why this exists

Dose-equivalence conversions (opioids, benzodiazepines, corticosteroids,
statins, inhaled steroids) are high-frequency, easy to get wrong, and
annoyingly hard to find quickly online. They are the one calculator class
worth building *into* orbweaver rather than linking out, for one decisive
reason: **offline**. A pocket guide used in a resource-limited setting
cannot assume MDCalc is reachable. So:

- **Build in-app:** dose-equivalence conversions (this doc).
- **Link out:** large one-off calculators (GFR, Wells, etc.) where the
  maintenance cost isn't justified.

Orbweaver is a *static renderer by default, not by constraint*. A
`conversion` is simply a new block type whose widget holds state. The
topic stays the atom; a converter can be its own topic or a block inside a
broader topic (e.g. a pain/palliative page).

## 2. Two modes, because there are two pharmacologies

`conversion` is **one block type with a `mode:` discriminator**, because the
domain splits cleanly in two:

| Mode | Drugs | Why | Input | Math |
|---|---|---|---|---|
| `equivalence` | opioids, benzos, steroids | **titratable** — any dose is valid | free numeric entry | factor arithmetic via a reference anchor |
| `tiers` | statins, inhaled steroids | **fixed manufactured strengths** — only certain doses exist | **selection only** (tap a real strength) | tier match (same-tier = equivalent) |

Selection-only in `tiers` mode is itself a **safety feature**: you cannot
enter a strength that doesn't exist, and you cannot imply a precision the
equivalence doesn't support.

Common fields (both modes):

```yaml
- type: "conversion"
  mode: "equivalence" | "tiers"
  title: "..."
  source: "..."            # the reference these factors/tiers come from — REQUIRED
  last_reviewed: "..."     # same review workflow as protocols
  caveats: ["...", "..."]  # shown as alert callouts
```

## 3. Mode A — `equivalence` (titratable; the opioid model)

### 3.1 Layout — three sections, direct conversion

The agreed UX is a **three-section** widget:

```
┌─────────────────────────────────────────────┐
│ FROM:  [ Drug ▾ ]  [ Route ▾ ]   [ dose: __ ]│   ← source
├─────────────────────────────────────────────┤
│            = 30 MME                           │   ← reference anchor (always shown)
├─────────────────────────────────────────────┤
│ TO:    [ Drug ▾ ]  [ Route ▾ ]   = 20 mg      │   ← target (computed)
└─────────────────────────────────────────────┘
```

**Direct conversion only — no "past 24 hours" framing.** The clinical
question this answers is "switch this patient from X to Y *now*", not
"total this patient's daily intake." We never ask for a 24-hour sum and we
never aggregate.

**The middle line is the reference anchor** (MME for opioids,
diazepam-equivalent mg for benzos, prednisone-equivalent mg for steroids).
It is always visible and updates from the *source* alone, independent of
the target. This is deliberate:

- **Transparency** — the user sees the anchor value, not a black box.
- **Optional manual totaling** — if someone *does* want a 24h total, they
  enter each agent in turn, read each MME off the middle line, and add
  them up themselves. The tool stays direct; the user opts into summing.

### 3.2 Math

```
referenceEquivalents = sourceDose × sourceFactor      (the middle line)
targetDose           = referenceEquivalents ÷ targetFactor
```

The reference agent (e.g. oral morphine) has `factor: 1.0`, so its MME
equals its dose. Keep full decimal precision through the calculation;
**do not pre-round** — opioid dosing uses exact decimals and premature
rounding compounds. Display the computed value at a sensible precision and
leave clinical rounding to the user.

### 3.3 Schema

```yaml
- type: "conversion"
  mode: "equivalence"
  title: "Opioid Conversion"
  reference: "oral morphine"      # the anchor
  reference_label: "MME"          # short label for the middle line
  unit: "mg"                      # default dose unit
  source: "CDC 2022 MME conversion factors"   # ILLUSTRATIVE pending review
  last_reviewed: "pending OpenEvidence review"
  agents:
    # factor = multiplier to the reference. unit overrides the block unit.
    - { name: "Morphine",      route: "PO",    factor: 1.0 }
    - { name: "Morphine",      route: "IV/SC", factor: 3.0 }   # 1 IV ≈ 3 PO
    - { name: "Oxycodone",     route: "PO",    factor: 1.5 }
    - { name: "Hydromorphone", route: "PO",    factor: 4.0 }
    - { name: "Hydromorphone", route: "IV",    factor: 20.0 }
    - { name: "Codeine",       route: "PO",    factor: 0.15 }
    - { name: "Fentanyl",      route: "IV",    factor: 0.3, unit: "mcg" } # caution
  excluded:                       # offered but NOT auto-convertible
    - { name: "Methadone",      reason: "Nonlinear, dose-dependent ratio — use a specialist tool." }
    - { name: "Fentanyl patch", reason: "Patch kinetics — not a linear factor." }
    - { name: "Buprenorphine",  reason: "Partial agonist / ceiling — specialist conversion." }
  caveats:
    - "Reduce the calculated dose 25–50% for incomplete cross-tolerance."
    - "Estimates only — re-titrate to effect and reassess."
```

Notes:
- `route` is part of an agent's identity (PO vs IV morphine differ). The
  drug dropdown lists distinct names; the route dropdown lists routes
  available for the selected drug.
- Per-agent `unit` (e.g. fentanyl `mcg`) overrides the block `unit`.
- `excluded` agents appear in the dropdowns greyed/with their reason, so
  the user learns *why* they can't be naively converted — they don't just
  silently vanish.

## 4. Mode B — `tiers` (fixed-strength; the statin model)

### 4.1 Layout — the matrix

Render a **matrix: agents (rows) × tiers (columns)**, with each real
manufactured strength as a **tappable chip** in its cell. Tapping a chip
highlights the **whole tier column** — its equivalents across all agents.
No numeric entry.

```
                 Low        Moderate          High
Atorvastatin      —        [10] [20]        [40] [80]
Rosuvastatin      —        [5]  [10]        [20] [40]
Simvastatin     [10]       [20] [40]           —
        (tap any chip → its tier column highlights = the equivalents)
```

The matrix doubles as a **static reference table** before anyone taps —
useful on its own.

### 4.2 Schema

```yaml
- type: "conversion"
  mode: "tiers"
  title: "Statin Intensity"
  tiers: ["Low", "Moderate", "High"]    # ordered low→high
  tier_note: "LDL-C lowering intensity"
  source: "2018 ACC/AHA Cholesterol Guideline"   # ILLUSTRATIVE pending review
  last_reviewed: "pending OpenEvidence review"
  agents:
    - name: "Atorvastatin"
      doses:
        - { dose: "10 mg", tier: "Moderate" }
        - { dose: "20 mg", tier: "Moderate" }
        - { dose: "40 mg", tier: "High" }
        - { dose: "80 mg", tier: "High" }
    - name: "Rosuvastatin"
      doses:
        - { dose: "5 mg",  tier: "Moderate" }
        - { dose: "10 mg", tier: "Moderate" }
        - { dose: "20 mg", tier: "High" }
        - { dose: "40 mg", tier: "High" }
    - name: "Simvastatin"
      doses:
        - { dose: "10 mg", tier: "Low" }
        - { dose: "20 mg", tier: "Moderate" }
        - { dose: "40 mg", tier: "Moderate" }
  caveats:
    - "Intensity equivalence ≠ interchangeable — consider drug interactions,
       myopathy risk, and renal/hepatic dosing."
```

Every `tier` referenced by a dose must be one of the declared `tiers`
(validated at parse/test time).

## 5. Safety requirements (cross-cutting — non-negotiable)

Dose conversion is among the most dangerous things a clinical app can do.
Safety is part of the *design*, not just the content:

1. **Exclusions are first-class.** Methadone, fentanyl patch, buprenorphine
   are never linearly converted; they appear with a reason, not silently.
2. **Show the math.** The middle MME line and the factor table are always
   visible — never a black box.
3. **Cross-tolerance reduction** is surfaced on every equivalence result,
   not buried in a footnote.
4. **`source` is required** and shown — equivalence factors genuinely
   differ between references; the user must know which one.
5. **Conservative display** — full precision internally, no misleading
   false precision; clinical rounding left to the user.
6. Every converter goes through the **same OpenEvidence review** as the
   protocols before `last_reviewed` loses its "pending" marker.
7. Visually, harm-weighted caveats reuse the palette `alert` role; a
   converter topic may override `alert` to red (as Chart 7 does).

## 6. Testing strategy (extensive — opioids & benzos especially)

These are dangerous if wrong, so the converter gets a dedicated, thorough
test suite *beyond* the usual parse tests:

- **Golden conversion pairs** — a table of clinically-accepted conversions
  asserted exactly, e.g. oxycodone 20 mg PO → 30 MME → morphine 30 mg PO;
  hydromorphone 4 mg PO → 16 MME; lorazepam 1 mg → 10 mg diazepam-eq.
  Sourced from the cited reference; reviewed.
- **Reference identity** — the reference agent at its reference route has
  factor 1.0, so MME == dose exactly.
- **Round-trip** — A→reference→B→reference→A returns the original within
  float tolerance, for every linear agent pair.
- **Route variants** — morphine PO vs IV/SC apply the correct distinct
  factors; same for hydromorphone.
- **Unit overrides** — fentanyl computes in mcg, reference stays mg.
- **Exclusions** — methadone / fentanyl-patch / buprenorphine are flagged
  and cannot produce a naive linear result.
- **Tiers** — selecting a dose highlights exactly its tier; equivalents are
  precisely the same-tier doses of other agents; free numeric entry is
  impossible by construction.
- **Schema/data integrity** (run against the authored YAML): every agent
  has a positive factor; `source` present; the reference agent exists with
  factor 1.0; every tier dose references a declared tier.

The golden-pair tables are the heart of it: a reviewer can read them and
verify clinical correctness directly, and any factor edit that breaks an
accepted conversion fails loudly.

## 7. Architecture / implementation notes

- New sealed `ConversionBlock` (+ `ConversionMode`, `ConversionAgent`,
  `ConversionDose`) in `lib/models/topic.dart`, parsed in `Block.fromYaml`.
- A `StatefulWidget` renderer under `lib/widgets/blocks/` — the first
  interactive block. Palette-themed like everything else (chips, the
  highlighted tier column, and caveat callouts use palette roles).
- Converters likely live together in a **"Conversions" (or "Tools") book**
  on the shelf, each converter its own topic, though a converter block can
  also sit inside any topic.
- Document the block in `SCHEMA.md` once the shape is settled.

## 8. Open questions / future

- **Methadone / fentanyl patch** — excluded from linear conversion now; a
  future dedicated (non-linear, dose-banded) sub-tool could handle them.
- **Optional cross-tolerance toggle** — should the equivalence result
  optionally *show* the 25–50%-reduced range alongside the raw value?
  (Leaning yes — display a "reduced: X–Y" line, never silently apply it.)
- **First cut** — opioids + benzos + steroids (equivalence) and statins
  (tiers); inhaled steroids (tiers) and beta-blockers (messy — probably a
  plain table, not a converter) come later.
