# CPG probe: one orbweaver page as HL7 FHIR Clinical Practice Guidelines (2026-11-09)

Question (Grey, 2026-11-09): could orbweaver's YAML be transformed into a FHIR CPG, and
what would that take? Answered by converting one page by hand and measuring, not by
estimate.

Page: ProtocolBook p.42, Paediatric convulsions
(`assets/books/protocolbook/topics/pb_042_paediatric_convulsions.yaml`): one alert callout,
one three-stage flowchart, weight-based doses for three drugs.

Target: HL7 FHIR CPG IG 2.0.0 (`hl7.fhir.uv.cpg#2.0.0` from packages.fhir.org), FHIR 4.0.1.
Patterns copied from the IG's own examples: `PlanDefinition-chf-*`,
`ActivityDefinition-chf-lasix-iv`, `ActivityDefinition-activity-example-orderservice-ad`,
`Library-CHF`.

## Files

| File | What |
|---|---|
| `build_convulsions_cpg.py` | Builds every resource by hand-written mapping; writes `ledger.tsv`; fails if any YAML leaf is unaccounted for |
| `PaediatricConvulsions.cql` | Decision logic and weight-based doses |
| `out/` | 15 resources: 1 Library, 11 ActivityDefinitions, 3 PlanDefinitions (strategy + 2 recommendations) |
| `ledger.tsv` | Every fact on the page: computable / text only / lost, and where it went |
| `validation.txt` | HL7 validator output |
| `cql_cases.txt` | The CQL run on six synthetic patients, with asserted expectations |
| `cql_check/` | Dart harness for the CQL run (uses sibling `cql` and `fhir_r4_cql` checkouts) |

Rebuild and check:

```bash
python3 tool/cpg_probe/build_convulsions_cpg.py
java -jar ~/.fhir/validator_cli.jar tool/cpg_probe/out/*.json -version 4.0.1 -ig <hl7.fhir.uv.cpg-2.0.0.tgz> > tool/cpg_probe/validation.txt
cd tool/cpg_probe/cql_check && dart pub get && dart run bin/run.dart .. ../cql_cases.txt
```

## Results

- **Validation:** 15/15 resources pass against CPG 2.0.0 with 0 errors and 0 warnings. The
  only messages are "does not match any known slice" notes on `cqf-knowledgeCapability`,
  which the IG's own examples carry too. The validator was seen to fail first: the first
  run gave 2 errors, because the CPG service profile fixes `ActivityDefinition.code` to
  `order-service`, so the clinical code (oxygen, glucose check) has to come from
  `dynamicValue`, as in the IG's orderservice example.
- **CQL:** run in our `cql` engine through `fhir_r4_cql` on six synthetic patients; 0 of 24
  assertions failed. Expected values worked by hand from the page.
- **Ledger:** 65 facts. 34 computable, 19 text only, 12 lost. All 12 lost are layout or
  book metadata (callout colour, flowchart shape, page number, edition, tags, category,
  list subtitle, bold, an editorial note). No clinical fact was lost, but 19 survive only
  as text a machine cannot act on.
- **Size:** 73 non-comment YAML lines became 1,419 lines of JSON plus 121 lines of CQL.

## What does not fit (from the ledger)

1. **No per-episode, per-kg cap.** "Cumulative maximum 40 mg/kg": `Dosage.maxDosePerLifetime`
   is lifetime and absolute. Text only.
2. **Conditional limits.** "No more than 2 doses of diazepam in 24 h once phenobarbitone
   used": `maxDosePerPeriod` cannot carry the condition. Text only.
3. **Setting preconditions.** "Only where respiratory monitoring is available." Text only.
4. **Bedside acts with no code.** Check ABC, ensure safety, observe, investigate cause:
   two SNOMED searches each found nothing usable. Text only.
5. **Bedside judgements are not EHR data.** "Still fitting after 5 more minutes" was modelled
   as a SNOMED 313289001 *Duration of seizure* Observation. That cannot say a seizure has
   ended: case F (three short seizures, latest 4 min) is read as "presents convulsing" and
   triggers stage 1 and the third-seizure branch at once. The page's own branches are
   mutually exclusive.
6. **Ambiguity the print leaves open.** Suppository bands "10–15kg 2 · 15–20kg 3" do not say
   which band 10, 15 or 20 kg is in, or what to give over 25 kg. The CQL had to choose
   (boundary takes the higher band; over 25 kg gives no dose).
7. **Product codes.** RxNorm has no diazepam 2.5 mg rectal suppository (only 10 mg,
   rxcui 104706); SNOMED International "Diazepam only product in rectal dose form"
   (778978007) was used.
8. **Nothing renders it back.** CPG carries no layout, so these resources cannot reproduce the
   page. Not attempted.

## Defect found in our own CQL translator

A misspelled identifier (`"Weight Valu kg"`) translated with **0 errors** in `cql`
(`libraryFromCql`), and at run time evaluated silently to null: a 3 kg neonate got 2
suppositories instead of 1. The asserted case run caught it (`FAIL Rectal Diazepam
Suppository Count: expected 1, got 2`). `cql/lib` contains no "could not resolve"
error anywhere. The HL7 reference translator was not run, so its behaviour here is
unmeasured.
