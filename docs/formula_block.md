# `formula` block

An interactive **numbers-in → number-out** calculator (Cockcroft-Gault, MAP,
corrected sodium, anion gap, …). The second stateful block type after
`conversion`.

## Split of responsibility

- **YAML declares the form** — a `kind` (which calculation) and a list of
  `inputs` (the fields). It carries no math.
- **`lib/data/formula_registry.dart` owns the math** — one pure-Dart,
  unit-tested function per `kind`. This is deliberate: a clinical formula must
  never be a free-text arithmetic string an author could typo into a wrong
  dose. Adding a calculator means adding a tested function to the registry and
  a `case` in `computeFormula`.

## Schema

```yaml
- type: "formula"
  kind: "corrected_sodium"        # registry key (must match computeFormula)
  title: "Sodium correction for hyperglycemia"
  source: "Hillier, Am J Med 1999"   # provenance — required for safety
  inputs:
    - { key: "sodium",  label: "Measured Na⁺", unit: "mEq/L", type: "number" }
    - key: "glucose"
      label: "Glucose"
      type: "number"
    - key: "glu_unit"             # a unit toggle is just a select input
      label: "Glucose unit"
      type: "select"
      default: "mg/dL"
      options:
        - { value: "mg/dL" }
        - { value: "mmol/L" }
    - { key: "albumin", label: "Albumin", unit: "g/dL", type: "number", optional: true }
  notes:                          # static lines under the result (e.g. the formula)
    - "Corrected Na⁺ = measured + 2.4 × (glucose − 100)/100"
  caveats:                        # rendered in the red alert box
    - "Interpretive aid for fluid tonicity — not a treatment target."
```

### Input fields

| field      | meaning                                                            |
|------------|-------------------------------------------------------------------|
| `key`      | how the registry function reads this value (must match the code)  |
| `label`    | shown beside the field                                            |
| `type`     | `number` (text field) or `select` (dropdown)                      |
| `unit`     | suffix on a number field / display only                          |
| `help`     | small hint under the label                                        |
| `default`  | initial value (number) or selected option value (select)         |
| `options`  | for `select`: `{ value, label? }` (label defaults to value)      |
| `optional` | blank doesn't block the calculation (e.g. albumin, actual weight) |

## Outputs

`computeFormula(kind, values)` returns a `FormulaResult` of one or more
`FormulaOutput` rows (`label`, `value`, `unit`, optional `interpretation` and a
`severity` of `none`/`info`/`warn`/`alert` that tints the row). An empty result
(missing/invalid required inputs) renders an "Enter values to calculate"
placeholder — it never shows a wrong number. The first `primary: true` output is
the headline (larger) number.

Every registry function has golden unit tests in
`test/data/formula_registry_test.dart`.
