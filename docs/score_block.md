# `score` block

An interactive **criteria → summed points → risk band** calculator
(CHA₂DS₂-VASc, Wells, CURB-65, GCS, …). The third stateful block type, after
`conversion` and `formula`.

## Fully declarative

Unlike `formula` (real math in a Dart registry), a clinical score is a weighted
sum plus a threshold lookup, so it lives entirely in YAML. `items` carry the
points; `bands` map the total to an interpretation. The sum + band resolution is
`computeScore` in `lib/data/score_engine.dart` (pure Dart, unit-tested).

Because it's declarative, the same block serves questionnaire/screening
instruments (PHQ-9, GAD-7): items with 0–3 option points and severity bands.

## Schema

```yaml
- type: "score"
  title: "CHA₂DS₂-VASc"
  unit: "points"                 # label after the total (default "points")
  show_total: true               # false hides the total and shows only the band —
                                 # for decision trees encoded as weighted points (PECARN)
  source: "Lip, Chest 2010"      # provenance — required for safety
  items:
    - { key: "chf", label: "Congestive heart failure / LV dysfunction", type: "toggle", points: 1 }
    - key: "age"
      label: "Age"
      type: "choice"
      default: "lt65"            # a choice SHOULD declare a default
      options:
        - { value: "lt65",  label: "< 65",   points: 0 }
        - { value: "65_74", label: "65–74",  points: 1 }
        - { value: "ge75",  label: "≥ 75",   points: 2 }
  bands:                          # first matching interval wins; max null = open
    - { min: 0, max: 0, label: "Low risk",          severity: "none" }
    - { min: 1, max: 1, label: "Intermediate risk", severity: "warn" }
    - { min: 2,          label: "High risk — anticoagulation recommended", severity: "alert" }
  notes:
    - "Score of 2+ in men (3+ in women) supports oral anticoagulation."
  caveats:
    - "Bleeding risk (HAS-BLED) informs modifiable factors — never withholds OAC."
```

### Item types

| type     | contributes                                                       |
|----------|-------------------------------------------------------------------|
| `toggle` | `points` when checked on (may be negative, e.g. Wells DVT −2)      |
| `choice` | the selected option's `points`; declare a `default`. Rendered as chips. |
| `scale`  | same scoring as `choice`, but rendered as a compact 0–N stepper (the button shows each option's `points`) with the selected level's `label` shown as an anchor beneath. For graded scales (CIWA-Ar, COWS, PHQ-9) whose 5–8 levels are too busy as chips. Omit a `label` (or set it equal to the number) to show no anchor for that level. |

### Bands

Each band is `{ min, max?, label, detail?, severity? }`. The total resolves to
the **first** band where `min ≤ total ≤ max` (`max` omitted = open-ended).
`severity` (`none`/`info`/`warn`/`alert`) tints the result row. Bands should
cover the whole achievable range — `scoreRange(block)` gives that range and the
parse tests assert no gaps.

## Testing

- `test/data/score_engine_test.dart` — golden `selections → total → band`
  vectors per score, proving the encoded points/bands match the guideline.
- `test/models/score_block_parse_test.dart` — every score topic parses; choices
  have defaults; declared bands cover `scoreRange`.
- `test/widgets/score_block_test.dart` — tapping criteria updates the live total
  and band on screen.
