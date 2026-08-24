# WHO Pocket Book (`who_imci`) — print-vs-app fidelity, first pass

Source: `9789241548373_eng.pdf` — WHO *Pocket Book of Hospital Care for Children*,
2nd ed, PDF CreationDate **2013-06-04**. 414 printed pages; printed page P is at PDF
index **P+23** (measured: 433 of 438 pages agree; p.47 = Chart 12, p.131 = Chart 13,
p.294 = §10.1, all confirmed).

App: 258 topics + `formulary.yaml` (Annex 2).

---

## 1. Content transfer is essentially complete — including all 16 charts

**Correction to an earlier reading of this repo.** The app has **0 `image` blocks and
0 `flowchart` blocks** across all 258 topics, and it names Charts 2–16 in its prose.
That looked like the charts were missing. They are not — they are all carried, as
prose and tables:

| Chart | Printed p. | Where the app carries it |
|---|---|---|
| 2 Triage | 5 | `who_1_chart02_triage.yaml` |
| 3 Choking | 7 | `who_1_chart03_choking.yaml` |
| 4 Airway | 9 | `who_1_chart04_airway.yaml` |
| 5 Oxygen | 11 | `who_1_chart05_oxygen.yaml` |
| 6 Positioning | 12 | `who_1_chart06_positioning.yaml` |
| 7 IV fluids, shock | 13 | `who_1_chart07_iv_fluids_shock.yaml` |
| 8 IV fluids, shock + SAM | 14 | `who_1_chart08_iv_fluids_sam.yaml` |
| 9 Rectal diazepam | 15 | `who_1_chart09_diazepam.yaml` |
| 10 IV glucose | 16 | `who_1_chart10_glucose.yaml` |
| 11 Severe dehydration | 17 | `who_1_chart11_dehydration.yaml` |
| 12 Neonatal resuscitation | 47 | `who_3_02_resuscitation.yaml` |
| 13/14/15 Diarrhoea plans C/B/A | 131 / 135 / 138 | `who_5_02_*_dehydration.yaml` |
| 16 Feeding recommendations | 302 | `who_10_01_2_sick_nutrition.yaml`, `who_12_03_nutrition_counselling.yaml` |

**So the gap is form, not content.** The print's emergency backbone is 15 flowcharts;
the app renders every one of them as running prose. Orbweaver *has* a flowchart
renderer — the ProtocolBook uses it **40 times**, and the cyclic/loop variant landed in
`cb82df7` — and the WHO book uses it **zero times**. That is the design finding, and it
sits exactly on Grey's caveat that WHO formatting should stay close to the original.

## 2. Numeric parity: the port lost almost nothing

`tool/book_number_parity.py`, output in `tool/who_imci_number_parity.tsv`.
Of **2,930 printed clinical numbers**, 193 differ from the app; after normalising
dashes, `≥`/`≤` and unit spellings, **158** appear nowhere in the app. Split by whether
the owning topic carries an OpenEvidence review header:

- **146 are on OE-reviewed pages** — i.e. they are the *deliberate* updates away from
  the 2013 text, and the topic headers say so. Spot-checked and confirmed:
  - **p.15** diazepam IV 0.05 ml/kg (0.25 mg/kg) → app gives **0.5 mg/kg (0.1 ml/kg)**,
    reasoned in the header.
  - **p.172** "600 mg/kg" is a **tool artefact** — the print reads rifampicin
    15 mg/kg, "maximum dose, 600 mg"; the range pattern glued the cap to the unit.
- **12 are on UNREVIEWED pages**, all in `who_9_03_injuries` (4) and the Annex 5 growth
  tables `who_a5_1_weight_for_age` / `who_a5_2_weight_for_length` / `_for_height` (8).

## 3. 🛑 The currency question cannot be answered by this instrument

**HIV chapter 8 contributes ZERO absent numbers.** That is not reassurance — it means
the app's HIV chapter reproduces the **2013** print faithfully, and 2013 is precisely
where paediatric HIV has moved most (dolutegravir first-line, treat-all, PMTCT B+).

Numeric parity measures *transfer* — did the port drop anything. **Currency has to be
measured against current guidance, not against the print**, and only an evidence review
can do it. The 18 topics with no review header are the target, and chapter 8 is seven
of them:

`who_8_01_suspected_hiv` · `who_8_02_art` · `who_8_03_supportive_care` ·
`who_8_04_related_conditions` · `who_8_05_pmtct` · `who_8_06_followup` ·
`who_8_07_palliative` · `who_9_01_perioperative` · `who_9_02_congenital` ·
`who_9_03_injuries` · `who_10_01_nutrition` · `who_10_06_transfusion` ·
`who_12_04_home_treatment` · `who_a3_equipment` · `who_a4_iv_fluids` ·
`who_a5_1_weight_for_age` · `who_a5_2_weight_for_height` · `who_a5_2_weight_for_length`

## ⏭️ Next
1. **Chapter 8 (HIV) evidence review** — highest yield in the book, written out in full
   and self-contained for OE.
2. **Render the 15 charts as flowcharts**, using the renderer the ProtocolBook already
   exercises, keeping the print's decision structure.
3. Adjudicate the 12 unreviewed-page numbers (growth tables and injuries).
