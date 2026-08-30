# Durations and thresholds, book against itself — all 51 rows read

The dose version of this pass found three real defects. This one, run for the first time
over durations and thresholds within a single book rather than across the two, found
**none**. That is the result, not a shortfall: it says the two classes the dose pass could
not see are internally consistent.

## Durations — 26 rows, no findings

Every one is a different indication, correctly dosed for it. Amoxicillin runs 5 days for
pneumonia and 10 for pharyngitis; ceftriaxone 3 days for dysentery, 5 for epiglottitis,
10–14 for meningitis; metronidazole 5–7 days for giardiasis and 10 for amoebiasis;
tetracycline 3 days oral for cholera and 7 days as eye ointment for measles; fluconazole
7 days for candidiasis and 14 in the cryptococcal consolidation phase.

Two looked like undertreatment and were opened. **Both were extraction artifacts.**

- **WHO gentamicin "2 days" in neonatal serious bacterial infection.** The page says
  *"Treat for at least 7–10 days, guided by clinical response and culture results."* The 2
  belongs to something else on the page.
- **WHO dexamethasone "1 day" in TB meningitis.** The page says 0.6 mg/kg/day paediatric
  for *"2–3 weeks then reduced over a further 2–3 weeks — 6–8 weeks in total"*, in all
  cases.

## Thresholds — 25 rows, no findings

**The oxygen threshold was checked first**, because the August sweep from 94% to 90% is
the one that went wrong. It has held. Every remaining 94 is a **target**, not a trigger,
and both books already carry that distinction in their own text: WHO Chart 5 says
explicitly *"the level to start oxygen stays SpO₂ < 90%. The 88–92% figure is the target
once the child is on oxygen — a ceiling to avoid hyperoxia, not a lower start-threshold"*,
and the ProtocolBook's wheezing page header records that discharge and target criteria
were deliberately left alone by that sweep.

⚠️ **Known limitation of this half, recorded rather than papered over.** The extractor
groups a threshold by QUANTITY and comparator, so one row pools decisions that have
nothing to do with each other: "glucose mmol/L <" holds hypoglycaemia at 2.2, the severe
wasting cutoff of 3, and a DKA resolution figure of 11; "temperature °C >" holds fever at
39, a transfusion reaction at 38, and drowning-water temperature at 32. Every threshold
row here resolved to that pooling. **A cutoff belongs to a decision, and this tool does
not know the decision** — so its threshold half will keep producing rows that are not
comparisons. Grouping by decision would need the surrounding context modelled, which is
the work if this is ever run again.

## Nothing was resolved here

Every row above was read against the page or the print. Where a value looked wrong it was
checked and found to be an artifact. **No dose, duration or threshold was changed by this
pass** — after two figures were invented earlier the same day while resolving findings,
surfacing and resolving are now separate acts, and resolving needs a source.
