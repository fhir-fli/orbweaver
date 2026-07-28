# ProtocolBook — OE re-review tracker

**Round 2 complete (2026-07-27).** Grey put the conflict list back through
OpenEvidence; OE revised on essentially every point. Everything it revised is
now applied at **`24fbe4d`**.

What follows is (A) what was resolved and applied, and (B) what is **still open** —
either because OE's reply did not reach it, or because it was never asked.

---

# A. RESOLVED AND APPLIED (`24fbe4d`)

| Item | First OE answer | Final position | Where |
|---|---|---|---|
| Famotidine in anaphylaxis | doses confirmed correct | **delete the drug** — zero RCTs ever (Nurmatov); absent from RCUK, AAAAI 2020/2023, WHO EML §3, UCG 2023 | `pb_037` |
| Anaphylaxis observation | ≥4 h | **≥6 h; 12 h if severe; admit all under-16s** — NICE's short route needs patient-held auto-injectors (none here); its 12 h criteria (out-of-hours, poor access) are routine here | `pb_037` |
| Phenobarbital load | 20 mg/kg | **revert to 15 mg/kg** + "may increase to 20 if seizures persist AND respiratory monitoring available" | `pb_020` |
| Diazepam cap | max 8 mg | **max 10 mg** + "maximum 2 doses, then phenobarbital" | `pb_020`, `pb_042` ×2, `pb_029` |
| NAC regimen | 3-bag if ≤40 kg | **2-bag for ALL**, diluent scaled 7 mL/kg → 14 mL/kg, D5W in children | `pb_032` |
| Doxycycline age | ≥8 years | **no age restriction** for courses ≤21 days | `pb_038` |
| Folic acid | not asked | **never 5 mg with SP or cotrimoxazole**; paeds 0.4–1 mg; folinic acid for antifolate-induced anaemia | `pb_075` |
| PDMC | not asked | **added** — monthly DHA-piperaquine at weeks 2, 6, 10 after severe malarial anaemia | `pb_023` |
| Snakebite anticholinesterase | not asked | **added, cobra only — explicitly NOT mamba** (WHO AFRO doses) | `pb_039` |
| Pralidoxime | equivocal | **footnote** noting UCG carries it, evidence uncertain | `pb_029` |
| Rabies IM remainder | — | **footnote** noting WHO 2018 vs UCG 2023, both acceptable | `pb_038` |
| Diazepam "0.3 was an error" | — | **withdrawn** — WHO prints a 0.2–0.3 band; we had printed its top | recorded |

**Also caught by a whole-book grep, not by either review:** `pb_104_im_gi_bleed`
still prescribed **ranitidine 50 mg IV q8h** as 2nd-line acid suppression.
Withdrawn worldwide 2020, not obtainable. Now **famotidine 20 mg IV q12h**.
This had been on the original clear-cut flag list since the Ingestions batch and
was missed for three rounds. **Lesson: after any drug-withdrawal substitution,
grep the whole book for the old drug name.**

---

# B. STILL OPEN  (updated 2026-07-27 after the pp.28-40 reviews)

## CLOSED since the last revision of this file
- ~~Methanol antidote/dialysis block~~ → **APPLIED** `18501ad` (folic acid 1 mg/kg
  or 50 mg IV q4–6h; haemodialysis referral trigger; vodka example fixed).
- ~~Activated charcoal~~ → **APPLIED** `18501ad` (p.28 gained 1 g/kg within 1 h
  guidance + the not-if-not-awake and never-intubate-for-it cautions; the p.33
  2 h / 4 h window was reviewed and called well-calibrated).
- ~~Atropine 0.02 vs 0.05 mg/kg~~ → **RESOLVED, KEEP 0.02.** It is what the 2025
  AHA table prints, and because the regimen doubles every 5 min the difference
  from a 0.05 start is one cycle. (My research pass was right to raise it and
  wrong about the direction.)
- ~~Flumazenil placement~~ → **RESOLVED, KEEP AS APPLIED.** The gated
  contraindication box was reviewed and called consistent with AHA/ACMT consensus.
- ~~Bite prophylaxis indications~~ → **MY FLAG WAS WRONG.** p.38 already carries
  the indication list (immunocompromised, asplenic, advanced liver disease,
  moderate-severe/crush, oedema at site, hand/joint/periosteum) and it was
  confirmed consistent with published recommendations. I raised it without
  re-reading the page. Only UCG's no-co-amoxiclav fallback (amoxicillin +
  metronidazole) remains unaddressed.

## Still genuinely open
1. **Post-artesunate haemolysis** — trigger should be "received parenteral
   artesunate", not "severe malaria"; the weekly four-marker panel is not
   obtainable at a district hospital, so probably **Hb + clinical weekly, markers
   "if available"**. Incidence ~23%; days 14 and 21 highest-yield.
2. **Hgb < 9 anaemia threshold** — below WHO's 2024 thresholds. Deliberate
   rationing choice, or should it move?
3. **Phenobarbital repeat pathway** — WHO pp.49–50 give further 10 mg/kg doses to
   a cumulative max 40 mg/kg. Not on our page.
4. **Phenobarbital maintenance** — we print 3–5 mg/kg/day; better-sourced is
   **2.5–5** (WHO Annex 2 verbatim; UCG 2.5 mg/kg once–twice daily).
5. **Snakebite — the IM rule is broader than tetanus.** WHO SEARO: avoid all IM
   injections while clotting is abnormal, not just the toxoid. Use IV/oral.
6. **Rabies immunoglobulin framing** — WHO 2018 says the dose is a MAXIMUM, not a
   target ("no minimum dose"), and leftover RIG can be fractionated for another
   patient. Our text reads as a target. Also unstated: category III only, no eRIG
   skin test, dilute with saline for small children, never after day 7.
   (Lower priority — the infiltration change itself is applied and endorsed.)
7. **Bite prophylaxis — no-co-amoxiclav fallback** (UCG: amoxicillin +
   metronidazole, the realistic district-level situation).
8. 🆕 **Snakebite discharge at 1 hour** — the flowchart discharges "no skin marks,
   no symptoms an hour post-bite". OE suggests 6–8 h because envenoming
   (haemotoxic especially) can declare late. NOT changed — it is a
   discharge-safety criterion and OE hedged it. **Ask OE for the minimum
   observation period directly.**

# C. STANDING NOTES

- **Uganda Clinical Guidelines 2023** is the highest-value source for the rest of
  this audit — it is what Ugandan clinicians are formally taught, and it was
  decisive on atropine, the diazepam cap and phenobarbital. Point OE at it.
  https://library.health.go.ug/sites/default/files/resources/Uganda%20Clinical%20Guidelines%202023.pdf
- **The recurring pattern:** OE answers from FDA labels and US guidelines; WHO
  and UCG often differ, and for this book WHO/UCG usually wins. When a number
  differs, ask which body it came from before treating either as wrong.
- **Do not conflate SNAP with the 2-bag regimen.** SNAP (Bateman 2014) is a
  12-hour protocol with ondansetron. The 200-then-100 mg/kg is the 2-bag 20-hour
  regimen (Wong/Graudins, 2NAC).

---

# D. PAEDIATRIC GROUP AUDIT (pp.42–55) — flags raised 2026-07-27, NOTHING APPLIED

First never-audited group. 8 topics. Audited against current standards and, where
the text extraction allowed, Uganda Clinical Guidelines 2023.

## D1 🔴🔴 MENINGITIS — the two age-group regimens appear INVERTED (`pb_054`)
As printed:
- **> 3 months:** Cefotaxime 100 mg/kg q8h **AND** Ampicillin 50 mg/kg q6h
- **< 3 months:** Ceftriaxone 100 mg/kg once daily

Standard practice is the reverse. **Ampicillin is the Listeria drug, and Listeria is
a pathogen of the UNDER-3-month group.** So as printed:
1. **Infants < 3 months get NO Listeria cover** — the one group that needs it.
2. They get **ceftriaxone**, the cephalosporin normally AVOIDED in neonates
   (bilirubin displacement → kernicterus; fatal precipitation with calcium-
   containing fluids).
3. Over-3-months get ampicillin for a pathogen they do not have — harmless, but it
   is the mirror image, which is what suggests the two headings were swapped.

Standard: **< 3 months = ampicillin + cefotaxime** (ampicillin for Listeria,
cefotaxime rather than ceftriaxone in neonates); **> 3 months = ceftriaxone or
cefotaxime alone.**

**NOT CHANGED** — a swap is my inference and this is a neonatal meningitis page.
Hazards 1 and 2 are true regardless of whether it was a swap. **Highest-priority
item in the audit so far.** Compare with the reversed artesunate bands (`d180100`).

## D2 🔴 SEPSIS — hydrocortisone 50 mg/kg/day (`pb_045`)
"If no improvement, consider hydrocortisone 50mg/kg/day". Commonly cited paediatric
septic-shock dosing is **1–2 mg/kg/dose q6h**, or **50 mg/m²/day** — and mg/m² vs
mg/kg is exactly the confusion that produces a figure like this. **The same book
gives hydrocortisone 5 mg/kg (max 200 mg) for anaphylaxis on p.37** — a 10×
internal disagreement for one drug.
⚠️ I could NOT verify this locally: the UCG text extraction contains no
"hydrocortisone" entry at all, and I am not certain enough about "shock-dose"
hydrocortisone literature to call it wrong. **Needs OE.**

## D3 🟡 DKA — urine output target missing "/kg" (`pb_047`)
"Satisfactory urine output **1–2mL/hr**" should be **1–2 mL/kg/hr**. Two other
places get it right — line 149 of the same page says "<1mL/kg/hr", and p.49 says
"goal UOP 1mL/kg/hr". For a 20 kg child this is a 20× difference, and it sits in
DKA where urine output is the trigger for starting potassium.

## D4 🟡 DKA — soluble (regular) insulin SC every 2 hours (`pb_047`)
The published subcutaneous DKA regimens dose **q2h with a rapid-acting analogue**
(lispro/aspart) precisely because of its short duration. **Regular/soluble insulin
peaks at 2–4 h and lasts 5–8 h**, so q2h dosing stacks. Either the interval or the
insulin should change. Also absent from the page: any warning against bicarbonate
in DKA (raises cerebral-oedema risk).

## D5 🟡 SEPSIS — the D10 recipe is 9.5%, and it is the odd one out (`pb_045`)
"1mL D50% plus 9mL D5% = 10mL D10%" computes to **950 mg / 10 mL = D9.5%**. The
claim "= D10%" is arithmetically false. This is the same WHO Chart 10 recipe an
independent pass found to be slightly off. **Every other D10 recipe in the book
(p.13 ×2, p.20, p.61) uses 8 mL NS + 2 mL D50 = exactly D10%** — so consistency and
correctness point the same way. Exact D5-based alternative: 1 mL D50 + 8 mL D5
(9 mL). Minor, but it is a printed equation that does not hold.

## D6 🟢 SEPSIS — SIRS temperature line typo (`pb_045`)
"<35.4 axillary (36 **axillary**)" — the parenthetical should be **core**, matching
the ">37.9 axillary (38.5 core)" pattern on the same line.

## ✓ VERIFIED FINE in this group (no action)
Septic-shock definition requires all three of cold extremities / cap refill >3 s /
fast-and-weak pulse (matches WHO ETAT and p.12) · the 10–20 mL/kg-over-30–60-min
bolus is appropriately FEAST-conservative · ampicillin 50 mg/kg with the neonatal
interval ladder · gentamicin 3 mg/kg LBW / 5 mg/kg OD · ceftriaxone 100 mg/kg OD or
50 mg/kg q12h · amoxicillin 40 mg/kg/dose BD for pneumonia (matches the WHO fix) ·
zinc 10–20 mg × 10–14 d · ciprofloxacin 15 mg/kg BD for dysentery · salbutamol neb
2.5/5 mg · dexamethasone 0.6 mg/kg · prednisolone 1–2 mg/kg · prednisone 2 mg/kg/day
for nephrotic syndrome · nitrofurantoin 6 mg/kg ÷ q6h · DKA fluid maths (80 mL/kg +
2× maintenance − bolus, max 40 mL/kg in 4 h, "never alternate D10 & NS") · D5 bag
recipe (50 mL D50 + 450 mL = exactly 5%) · mannitol 0.5–1 g/kg.

---

# E. SICKLE CELL GROUP AUDIT (pp.59–62) — flags raised 2026-07-28

Second advance-pass group, ahead of where Grey is reading. 4 topics. Every dose
cross-checked line by line against **Uganda Clinical Guidelines 2023 §11.1.3**
(pp.579–588), which carries a full SCD chapter — the single best comparator this
group could have. Source PDF pp.59–62 re-extracted to confirm the digitization is
faithful (it is, with one exception, E10).

**Two things applied directly** under the typo/unit-slip authorisation (E12, E13).
**Everything below in E1–E11 is NOT changed — it needs Grey/OE.**

## E1 🔴 folic acid 5 mg daily is prescribed alongside monthly SP — on the same list (`pb_059`)
The p.59 discharge regimen gives **folic acid 5 mg PO daily** and **monthly
sulfadoxine-pyrimethamine chemoprophylaxis**, for life, to every child.

That is the exact combination this audit already ruled against. `pb_075` line 139,
applied at `24fbe4d`, now reads: *"Do NOT give 5 mg folic acid to anyone taking an
antifolate — sulfadoxine-pyrimethamine (SP, used for malaria chemoprevention) or
cotrimoxazole prophylaxis. High-dose folate rescues the parasite and roughly doubles
antimalarial treatment failure. Keep folic acid at ≤1 mg/day, ideally 0.4 mg."*

**The book now contradicts itself**, and the contradiction lands on the largest
standing prescription in the group.

⚠️ Important: **UCG 2023 prescribes both too** — "give folic acid 5 mg daily for
life" and monthly SP, in the same table. So this is not a transcription error and
not a book-vs-UCG divergence; it is **UCG-vs-the-interaction-evidence**, and we have
already taken the evidence side once. Grey has to decide which way the book goes.
Options worth putting to OE rather than picking myself: keep 5 mg and separate it in
time from the monthly SP dose; drop to 1 mg daily; or accept UCG as-is for SCD
specifically on the grounds that SCD folate demand from chronic haemolysis is
genuinely higher than the general anaemia case `pb_075` was written about.
**Whatever is decided, the two pages must be made to agree.**

## E2 🔴 acute chest syndrome — no incentive spirometry (`pb_062`)
UCG's ACS block says, explicitly: **"Start incentive spirometry (or blowing of a
balloon) early in acute chest syndrome."** It is absent from `pb_062` and, by grep,
from all 95 topics.

This is the highest-yield thing missing from the page. It has RCT support in exactly
this population (Bellet, NEJM 1995 — incentive spirometry in SCD with chest or back
pain markedly reduced pulmonary complications), it is in the national guideline, and
UCG supplies a zero-cost substitute for when no spirometer exists. Nothing else on
this page costs so little.

## E3 🔴 acute chest syndrome — no bronchodilator (`pb_062`)
UCG ACS: **salbutamol inhaler 2–4 puffs prn, or nebulised 5 mg (2.5 mg for under-5s).**
`pb_062` has none.

The page's own Clinical Respiratory Score grades wheeze in 3 of its 6 rows and scores
"severe wheezing" as a 2 — so the page measures bronchospasm and then never treats
it. Availability is not the reason: salbutamol is used freely elsewhere in the book
(`pb_052`, `pb_127`, `pb_030`, `pb_142`).

## E4 🔴 stroke — transfusion has a floor and no ceiling (`pb_061`)
The page says **"Simple transfusion, PRBCs, to Hgb >9"**. UCG agrees on the trigger
("transfuse if Hb <9 g/dl"), so the floor is right. The problem is what is not said:

- **No upper limit.** In acute sickle stroke the accepted ceiling is about **10 g/dL**
  — raising the haematocrit without lowering HbS raises viscosity and can extend the
  infarct. "To Hgb >9" with no cap invites transfusion to 12–13.
- **No mention of exchange transfusion** (target HbS <30%), which is the guideline
  standard for acute stroke where it exists. May well be out of reach at a district
  hospital — but if so, that should be a stated fallback, not an omission.
- **No neuroimaging or referral line.** UCG's stroke block ends "Refer for
  neuroimaging and advanced management." Adults with SCD have a substantial rate of
  *haemorrhagic* stroke, which transfusion does not treat.

## E5 🔴 priapism is an admission criterion with no treatment anywhere in the book
p.59 admits for **priapism >4 hours**. Grep across all 95 topics **and** the 84-drug
formulary: "priapism" appears only in that one admission line and the `pb_059` tag
list. There is no management, no drug, no referral.

>4 hours is ischaemic priapism — a compartment-syndrome-equivalent emergency where
delay causes permanent impotence, and it is a common SCD presentation in exactly this
age group. Standard is aspiration and irrigation of the corpora ± intracavernosal
sympathomimetic (phenylephrine; etilefrine is the agent named in African SCD
literature), plus urology involvement. The book currently admits the patient and then
falls silent. **Worth asking OE for a district-hospital-realistic priapism block.**

## E6 🟡 the retic count is drawn and never used — no aplastic-crisis arm (`pb_060`)
Initial management draws "CBC, retic count". The cascade then branches on splenic
sequestration (Hgb drop >2 g/dL + sudden splenomegaly) but has **no branch for
aplastic crisis** — the other cause of acute anaemia in SCD, which UCG lists
alongside sequestration. It is distinguished by a **low** reticulocyte count with no
splenomegaly, typically post-Parvovirus B19, and it needs transfusion rather than
observation. As written, that child passes every decision and lands in "Supportive
Care". The one test that separates the two is already being sent.

## E7 🟡 ceftriaxone — three different numbers in four pages (`pb_060`, cf. `pb_061`/`pb_062`)
- `pb_060` fever box: **100 mg/kg OD IV, no maximum**
- `pb_061` infection row: **80 mg/kg IV daily, max 2 g**
- `pb_062` antibiotics: **80 mg/kg IV daily, max 2 g**

UCG uses 80 mg/kg (80–100 for ACS) with an adult ceiling of 1–2 g. The 100 mg/kg on
p.60 is defensible on its own terms — fever in a functionally asplenic child is
presumed sepsis — but **the missing cap is a real hazard**: a 60 kg adolescent in
crisis with fever is prescribed 6 g. Compare `pb_054`, which does cap it (max 4 g/day).
**`pb_045` (paediatric sepsis) carries the same uncapped 100 mg/kg line** — if this is
fixed, fix both.

## E8 🟡 hydroxyurea threshold is ~2× stricter than the national guideline (`pb_059`)
Book: "Frequent crises **>5/year**". UCG 2023: "Frequent crises: **>3 crises in a
year**", and UCG adds an indication the book does not have — **"pain interfering with
activities of daily living"**. TCD >200 cm/s, prior ACS and prior stroke all match.

## E9 🟡 the hydroxyurea hedge is out of date (`pb_059`)
Book: "Likely beneficial in all children with Sickle Cell Disease, although **larger
studies are still pending**."

They are not pending any more. REACH (NEJM 2019, 606 children across Angola, DRC,
Kenya and **Uganda**) and NOHARM (Uganda) settled safety and efficacy of hydroxyurea
in sub-Saharan African children, including in a malaria-endemic setting. UCG 2023 has
already moved: **"Children of 9 months and above should be initiated on hydroxyurea."**
The book's own "start after 9 months" and "20 mg/kg" match UCG exactly — only the
hedge is stale.

## E10 🟡 the splenic-sequestration box has an invisible third bullet (`pb_060`)
The source PDF's text layer contains a third item — **"c. Otherwise treat"** — that
the printed box **clips and does not display**. I confirmed this by rendering p.60 at
150 dpi: only a and b are visible. Our YAML matches what a reader sees, so nothing is
wrong in the app.

Two things for Grey: (1) the sentence is **truncated in the source document itself**
— "Otherwise treat" what? — so only he knows what it was meant to say; (2) the source
text box needs enlarging or the line will stay invisible in the PDF.

While here — UCG's one explicit warning on this complication is also absent from the
box: **"Avoid splenectomy in acute sequestration (high mortality)."**

## E11 🟡 ACS discharge at "Hgb > 5" vs the same page's transfuse-below-9 (`pb_062`)
The page transfuses for Hgb <9 on admission and then discharges at Hgb >5. p.59's
admission criteria include "symptomatic with Hgb <7". So a child can meet the ACS
discharge criteria at Hgb 5.5 while simultaneously meeting an admission criterion.
Possibly deliberate — SCD baseline is 6–9 g/dL and re-admission thresholds differ
from steady-state ones — but it reads as an internal contradiction and should be
either justified or aligned.

## ✅ APPLIED 2026-07-28 (typo/unit-slip authorisation, no clinical change)
- **E12 — `pb_062` "pO2 >94% on room air" → "SpO2 >94% on room air".** A percentage
  measured on room air is a saturation, not a partial pressure. The book writes spO2
  everywhere else *including twice on this same page*, and the CRS table on this page
  says "O2sat"; "pO2" occurred exactly once in all 95 topics. **The source PDF prints
  it too — Grey should fix the source.**
- **E13 — `pb_062` discharge criteria re-ordered** to the source's own numbering. The
  source is a 2-column list that reads column-first (and misprints its "4" as a second
  "2"); we had flattened it row-first while the file header claimed "order kept". All
  six criteria are conjunctive, so nothing clinical turns on it.

## ✓ VERIFIED FINE in this group (no action)
Penicillin V prophylaxis 125 mg BD / 250 mg BD by age — **exact UCG match** · SP
chemoprophylaxis bands ½ / 1 / 2 / 3 tabs by age — **exact UCG match** · erythromycin
250 mg q12h as the sulphur-allergy alternative — exact UCG match · hydroxyurea 20 mg/kg
from 9 months — exact UCG match · TCD >200 cm/s — exact UCG match · transfuse-if-Hb<9
in both stroke and ACS — UCG match · cefotaxime 50 mg/kg q8h max 2 g · azithromycin
10 mg/kg day 1 then 5 mg/kg (UCG uses erythromycin; azithromycin is the better agent) ·
paracetamol 15 mg/kg q6h paeds / 650 mg q6h adult (UCG 10–15 mg/kg 6–8h) · the D10
recipe "8 mL NS + 2 mL D50 = D10%" — **arithmetically exact, and the correct one**
(contrast the 9.5% recipe flagged at D5 in `pb_045`) · O2 for spO2 <94% — UCG stroke
target · "1.5 × MIVF, goal euvolemia, DO NOT BOLUS if not hypotensive" — appropriately
conservative and consistent with UCG's restricted-fluid stance in ACS · admission
criteria including the ≥2 g/dL drop — matches UCG's transfusion indications · CRS
table transcribed exactly · p.61 transcribed exactly.
