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

---

# F. SEVERE ACUTE MALNUTRITION GROUP AUDIT (pp.63–66) — flags raised 2026-07-28

Third advance-pass group. 3 topics. This group has an unusually strong comparator
set: **WHO Pocket Book of Hospital Care for Children ch.7** (the source the
ProtocolBook is condensing — the PDF is already in the repo root) **and UCG 2023
§19.2.2**. Source PDF pp.63–66 re-extracted line by line; **the digitization is
faithful and complete — every finding below is in the book, not in our rendering.**

**Nothing applied.** Unlike the Sickle Cell group there is no typo-class item here;
every finding is a clinical threshold, a dose, or an omission.

## F1 🔴 gentamicin is 5 mg/kg/day where both WHO and UCG say 7.5 (`pb_064`)
p.65 item 9: **"Gentamicin 5mg/kg/day x 7 days"**.

- WHO Pocket Book ch.7 §7.4.5: *"gentamicin (7.5 mg/kg IM or IV) once a day for 7 days"*
- UCG 2023 §19.2.2.3, verbatim: *"Gentamicin 7.5 mg/kg once a day for 7 days"*

Both agree, and the duration in the book already matches theirs — only the mg/kg
differs. This is a **33% underdose of the aminoglycoside in complicated SAM**, where
occult sepsis is the leading cause of death and the child is by definition
immunocompromised. Note the book's 5 mg/kg is its *general* paediatric gentamicin
dose (used elsewhere in the book); SAM has its own higher figure in both guidelines.
**Highest-priority item in this group.**

## F2 🔴 the amoxicillin step-down has no dose and no duration (`pb_064`)
p.65 item 9b: *"Switch ampicillin to amoxicillin if improved after 2 days"* — and
that is all. No dose, no duration, nothing in the formulary tying it to SAM.

- WHO: *"ampicillin 50 mg/kg IM or IV every 6 h for 2 days, then oral amoxicillin
  **25–40 mg/kg every 8 h for 5 days**"*
- UCG: same two-day ampicillin, *"then, oral amoxicillin"*; UCG's uncomplicated-SAM
  route is *"amoxicillin DT 40 mg/kg twice"* daily

The ampicillin half of the sentence is fully specified; the half the child is
actually discharged on is not.

## F3 🔴 blood transfusion in SAM has no furosemide, no monitoring, and no repeat rule (`pb_064`)
p.64 item 5 orders *"10mls/kg whole blood over 3hrs"*. The volume and the rate are
exactly WHO's. Everything WHO wraps around them is missing:

- **furosemide 1 mg/kg IV at the start of the transfusion** — WHO gives this in the
  same breath as the volume
- **monitoring**: pulse, breathing, lung fields, liver size and JVP **every 15 min
  during the transfusion**; slow down if breathing rises by 5/min or pulse by 25/min;
  **stop and give furosemide** if there are basal crepitations or an enlarging liver
- **"Do not repeat transfusion even if the Hb is still low, or within 4 days of the
  last transfusion"**

What makes this more than a completeness point: **item 6 on the very next page lists
"blood transfusion" as a common cause of cardiac failure in SAM.** The book names
transfusion as a killer in this population and then gives the transfusion order
without the precautions that exist because of it.

Two dose questions in the same item: the book transfuses at **Hgb <6 "with heart
failure"** where WHO's trigger is **Hb 4–6 with respiratory distress** (a broader and
earlier sign), and gives **5–7 ml/kg packed cells** in heart failure where WHO gives
**10 ml/kg of packed cells**.

## F4 🔴 vitamin A: no dose on the page, and the formulary forbids the schedule (`pb_064` + `formulary.yaml`)
p.65 item 7a says only **"Vitamin A on day 1, 2 and 15"**. No dose. So the reader goes
to the formulary — which then contradicts the page:

| | p.65 | `formulary.yaml` (p.157) | WHO §7.5.1 |
|---|---|---|---|
| schedule | days 1, 2, **15** | *"Once on admission; **should not be given twice within 1 month**"* | days 1, 2, **14** |
| <6 months | (no dose) | *"not recommended"* | **50 000 IU** |
| 6–12 months | (no dose) | 100 000 IU | 100 000 IU |
| >12 months | (no dose) | 200 000 IU | 200 000 IU |

Two real problems, not one:
1. **The formulary's "not twice within 1 month" forbids the day-2 and day-15 doses
   the protocol page orders.** A clinician who looks up the dose is told not to give
   it. The two rules are about different things — the formulary states the *routine
   supplementation* rule, the page states the *deficiency treatment* rule — but the
   book never says so, and as written they simply conflict.
2. **<6 months is "not recommended" in the formulary but 50 000 IU in WHO** — and
   p.64's admission criteria explicitly include *"Children <6 months with SAM"*, so
   this gap is reachable by design.

Also worth carrying over from WHO §7.4.6: high-dose vitamin A should **not** be given
routinely when there are no eye signs and no measles history, because F-75, F-100 and
RUTF already contain enough. The formulary's "once on admission" reads as routine
dosing for everyone, which is the position WHO moved away from.

## F5 🟡 ReSoMal is given with no cholera / profuse-diarrhoea exception (`pb_064`)
p.64 item 4 gives ReSoMal unconditionally. Both guidelines carve out the same
exception in near-identical words — WHO: *"…as per the ReSoMal recipe below, **unless
the child has cholera or profuse watery diarrhoea**"*, in which case standard ORS is
used; UCG repeats it verbatim. ReSoMal is deliberately low-sodium, which is exactly
wrong in high-output sodium-losing diarrhoea.

The page's monitoring line is also softer than the source: it says *"monitor for
improvement or over hydration"* where WHO gives the actual stop rule — **if
respiratory rate rises by 5/min and pulse by 25/min, stop ReSoMal immediately and
reassess.**

## F6 🟡 the adolescent MUAC bands overlap — a MUAC of 17 cm is both MAM and SAM (`pb_063`)
Bottom row of the classification table, transcribed exactly from the source:

| Age | Indicator | MAM | SAM |
|---|---|---|---|
| 5 to <10 yrs | MUAC | ≥13.5 & <14.5 cm | <13.5 cm |
| 10 to <15 yrs | MUAC | ≥16.0 & <18.0 cm | <16.0 cm |
| **15 to 19** | **MUAC** | **≥16.5 & <21.0 cm** | **<18.5 cm** |

Every other row has MAM's lower bound **equal to** SAM's upper bound (13.5/13.5,
16.0/16.0). The last row does not: **≥16.5 and <18.5 overlap**, so a 16-year-old
measuring 17.0 cm satisfies both columns at once. That is not a judgement call, it is
arithmetically impossible.

Which bound is wrong is a clinical decision I am not making. The pattern of the
column suggests **MAM's "≥16.5" is a misprint for "≥18.5"** — the SAM cutoffs would
then run 13.5 → 16.0 → 18.5 in even steps, and the boundary rule would hold as it
does in every other row. The alternative (SAM should be <16.5) makes the SAM series
13.5 → 16.0 → 16.5, which barely moves across a five-year age gap. **Worth putting to
OE as a straight question.**

## F7 🟡 the WFH-vs-BMI crossover age contradicts itself in the same sentence (`pb_063`)
"Making sense of the measurements", as printed:
- *"Use Weight-for-Length/Height (WFL/WFH) if **<6 years (59 months)**"*
- *"Use BMI/age if **≥6 years**"*

**59 months is under 5 years, not under 6.** The sentence disagrees with its own
parenthetical, and the classification table two rows below settles it the other way —
its rows are *"6 to 59 months"* (WFL/WFH) and *"5 to 19 years"* (BMI/age), which is
also the WHO convention. So both prose lines should read **5 years**, not 6.

I did not apply this. It is a clean internal contradiction and the direction is not
really in doubt, but it is an age threshold that changes which chart a child is
classified on, so it should be Grey's line rather than mine. **Quick confirm.**

## F8 🟡 "Do not use digoxin in newborns" is a caution about a drug the book never offers (`pb_064`)
p.65 item 6d. Digoxin appears nowhere else in the cardiac-failure block, nowhere else
in the topic, and **WHO's SAM chapter does not mention digoxin at all** — its SAM
heart-failure management is stopping feeds and fluids plus furosemide, which is what
items 6a–6c already say. The line reads like a survivor from a different source's
heart-failure block that did list digoxin as an option. As printed it warns against a
treatment that was never offered, and it implicitly suggests digoxin *is* appropriate
in non-newborns, which the book never states or doses. **Either restore the digoxin
option properly or drop the line.**

## F9 🟡 eye care is missing the part that saves the eye (`pb_064`)
p.65 item 7 gives *"1% atropine to relax the eye"* and *"Gentamycin or chloramphenical
eyedrops"*. WHO §7.5.1, for corneal clouding or ulceration, gives four things
explicitly *"to prevent corneal rupture and extrusion of the lens"*:
- chloramphenicol **or tetracycline** drops, **four times a day for 7–10 days**
- atropine, **one drop three times a day for 3–5 days**
- **cover with saline-soaked eye pads**
- **bandage the eye(s)**

The book has the two drugs without frequency or duration, names **gentamicin** drops
(not a WHO choice here) as the first option, and omits the pad and bandage entirely —
which are the mechanical steps, need no supply chain, and are what actually prevents
the globe from perforating.

## F10 🟢 smaller items
- **"Stop all oral feeds and IV fluids for 24 hours"** (p.64 item 5a) has no
  counterpart in WHO, which says only that transfusion should be given in the first
  24 h if criteria are met. Withholding feeds for a full day in a child whose item-1
  problem is hypoglycaemia deserves a second look — possibly a garbling of WHO's
  "in the first 24 h".
- **Dehydration sign "Capillary refill ≥2 seconds"** (p.64 item 4) is a very loose
  threshold; the shock criteria on the same page use **>3 seconds**, and >3 s is the
  usual abnormal cut-off.
- **Uncomplicated SAM going to OTC/RUTF** (p.64) carries no antibiotic, where both
  WHO and UCG give oral amoxicillin to uncomplicated SAM as well.
- **Kwashiorkor skin lesions** (p.65 item 8): the book has potassium permanganate and
  gentian violet. WHO adds **zinc** (deficiency is usual in kwashiorkor and the skin
  responds quickly), a **barrier cream** to raw areas, and **avoiding nappies** so the
  perineum stays dry. Item 10's "micronutrients already in F-75/F-100" may cover the
  zinc; the barrier cream and nappy advice are free and are not covered.
- **Vitamin A day 15** should be **day 14** in both WHO and the wider literature.

## ✓ VERIFIED FINE in this group (no action)
Hypoglycaemia <3 mmol/L / 54 mg/dL with the drink-vs-can't-drink split, 50 mL of 10%
dextrose or sugar water, D10 5 mL/kg IV then NGT — WHO and UCG match · hypothermia
axillary <35 / rectal <35.5 and the whole active-warming list including no hot water
bottles — WHO match · **shock: 15 mL/kg/hour, may repeat once, RL+D5% or ½NS+D5% with
20 mmol/L KCl, then whole blood 10 mL/kg if no improvement after the first bolus —
matches WHO's SAM-specific shock chart exactly**, including the deliberately slower
rate that separates SAM from non-SAM shock · the SAM shock definition (AVPU <A AND
cold extremities plus cap refill >3 s or weak/fast pulse) · ReSoMal 5 mL/kg q30min ×2 h
then 5–10 mL/kg/h alternating hourly with F-75 × 10 h, and ReSoMal after each loose
stool — WHO match · ampicillin 50 mg/kg IV q6h × 2 days — WHO and UCG match · F-75
100 mL/kg/day with oedema, 130 without, fixed total volume, 2-hourly for 48 h then
3–4 hourly, 80% completion rule, NGT trigger — WHO match · appetite test at one third
of a 92 g sachet · F-100 same volume for 2 days then +10 mL/feed to max 220 mL/kg/day
· **iron deferred to rehabilitation / day 3 of transition — WHO match, and the book
says it consistently in two places** · the whole switch-back-to-stabilization list ·
0.01% potassium permanganate for dermatosis — WHO match · the complicated-SAM
definition and the three admission criteria · MUAC/weight/length measurement technique
including the 87 cm and 0.7 cm rules.

---

# G. ENT GROUP AUDIT (pp.67–70) — flags raised 2026-07-28

Fourth advance-pass group. 6 topics (epistaxis; then otitis media, otitis externa,
mastoiditis, pharyngitis and sinusitis, which are items I–V of one printed section
split into five leaves). Source PDF pp.67–70 re-extracted; **the digitization is
faithful** — every finding is in the book.

**One thing applied** (G1, typo/unit-slip authorisation). The rest need Grey/OE.

The theme of this group is different from the last two: most findings are **the book
disagreeing with itself**, and in three cases the internal comparison settles the
answer on its own without needing an external guideline at all.

## G1 ✅ APPLIED — p.68 amoxicillin was missing its "/kg" (`pb_068`)
Source p.68 prints **"Amoxicillin 45mg/dose PO BD"** and **"Amoxicillin/Clavulanic
Acid 45mg/dose PO BD"**. Corrected to **45mg/kg/dose**. Three independent lines of
evidence, all internal to the book:

1. **The same page's own ceiling** is *"max/adult dose for the below is 875mg/dose PO
   BD"* — meaningless if the paediatric dose is a flat 45 mg.
2. **p.70 prints the same drug on the same twice-daily regimen with the /kg** —
   *"Amoxicillin 45mg/kg/dose BD"* for sinusitis.
3. **A whole-book grep**: every other amoxicillin dose in all 95 topics is per-kg
   (`pb_046` 40 mg/kg/dose BD, `pb_049` 50 mg/kg, `pb_070` 45 mg/kg/dose). p.68 was
   the only exception in the book.

45 mg/kg/dose BD = 90 mg/kg/day, the standard high-dose amoxicillin regimen for AOM.
As printed, **a 15 kg child would have received 45 mg BD instead of 675 mg BD — a 15×
underdose**, for the commonest childhood infection in the book. `pb_068`'s header had
already suspected this and left it as an open OE flag; the p.70 comparison settles it.
**Grey should fix the source PDF.**

## G2 🔴 otitis externa prescribes an ototoxic drop with no perforation warning (`pb_069_otitis_externa`)
The only treatment given is **Neomycin/Polymyxin B/Hydrocortisone (Cortisporin Otic)**.
Neomycin is an aminoglycoside and is **ototoxic if it reaches the middle ear** — it is
contraindicated when the tympanic membrane is perforated or a tympanostomy tube is in
place, where it can cause permanent sensorineural hearing loss.

The book supplies the exact patient one page earlier: **`pb_068`'s AOM diagnostic
criteria include "TM is perforated with discharge" and "new otorrhea not due to otitis
externa"** — and these two conditions are the classic clinical confusion, which is why
`pb_069` prints a pearl for telling them apart. A discharging ear that is misread as
otitis externa gets neomycin.

The standard answer where perforation cannot be excluded is a **fluoroquinolone otic
drop (ciprofloxacin or ofloxacin)**, which is not ototoxic. Also absent: **aural toilet
or an ear wick** when the canal is too swollen for drops to penetrate (drops into an
occluded canal do nothing), and any analgesia.

## G3 🔴 mastoiditis gives up to 6 g/day of ceftriaxone — above the book's own ceiling (`pb_069_mastoiditis`)
*"With intracranial complications: **Ceftriaxone 2g IV BD or 8 hourly** plus
Vancomycin…"*. 2 g every 8 hours is **6 g/day**. The book contradicts itself twice:

- **`formulary.yaml` (p.148)**: *"Adults: Meningitis 2 g IV q12hr; Other 2 g IV q24hr"*
  and *"Max: 2 g/dose"* — so the highest adult regimen the formulary recognises is
  4 g/day.
- **`pb_054`** prints *"max 4 g/day"* explicitly, twice.

2 g q12h is the accepted regimen for CNS infection. The *"or 8 hourly"* has no support
in the book or outside it, and it appears in the one place where the patient already
has an intracranial infection and reduced renal reserve is likely.

## G4 🟡 the same line under-doses vancomycin, relative to the book's own sepsis page (`pb_069_mastoiditis`)
*"Vancomycin 2g in 2–4 divided doses"* — a flat 2 g/day, roughly 28 mg/kg/day for a
70 kg adult. **`pb_099_im_sepsis` gives "Vancomycin 15 mg/kg IV 8-hourly"** — about
45 mg/kg/day.

So the book gives **less** vancomycin for an intracranial infection than for ordinary
sepsis, when CNS penetration is poor and CNS dosing is normally the higher of the two.
Vancomycin is also **absent from the 84-drug formulary entirely**, so there is nothing
to look up, and neither page mentions levels or renal adjustment.

## G5 🟡 mastoiditis in children: AND or OR? (`pb_069_mastoiditis`)
Printed as two unnumbered-in-our-render bullets:
- Ampicillin-Sulbactam IV 50 mg/kg 8 hourly
- Cloxacillin or Flucloxacillin IV 50 mg/kg 6 hourly

The source prints them as items 1 and 2 of a list with no conjunction, so our two
bullets read as "give both". **Ampicillin-sulbactam already covers MSSA**, so giving
cloxacillin alongside it duplicates the anti-staphylococcal cover and adds nothing;
if the intent was "either", the page should say so. Separately, ampicillin-sulbactam
is normally dosed **q6h**, and stated per the ampicillin component — neither is
specified here.

## G6 🟡 mastoiditis: no imaging, and no surgical route for adults (`pb_069_mastoiditis`)
Children get *"if no response within 48 hours or the child deteriorates, refer to a
surgical specialist to consider incision and drainage"*. **Adults get no surgical
referral line at all** — including in the intracranial-complications bullet, where
drainage is emergent rather than something to trial for 48 hours. No imaging (CT
temporal bone) is mentioned anywhere in the topic, for either age group.

## G7 🟡 pharyngitis: the amoxicillin cap looks like a per-day figure applied per-dose (`pb_070_pharyngitis`)
Treatment table: **"Amoxicillin 25mg/kg/dose (max 1g) BD x 10 days"**. The mg/kg is
right — 25 mg/kg/dose BD = 50 mg/kg/day. But the cap as written is **1 g per dose,
i.e. 2 g/day**. The usual regimens are 50 mg/kg once daily to a **maximum of 1000 mg
per day**, or 25 mg/kg/dose BD to a **maximum of 500 mg per dose**. Either way the
daily ceiling is 1 g, not 2 g. Likely a per-day maximum written into a per-dose cell.

## G8 🟡 pharyngitis never says why it is being treated — and the book has the page (`pb_070_pharyngitis`)
The topic explains that only streptococcal pharyngitis warrants antibiotics, and gives
a Centor threshold, but never states the reason the threshold exists: **preventing
acute rheumatic fever**. In this setting that is the whole point, and **the book
already has a rheumatic fever topic — `pb_058`, in the Paediatric Cardiac group.**
There is no cross-link in either direction. One sentence and one `topic:` link would
connect the two, and would also justify completing the full 10 days.

Smaller items on the same page: the **benzathine penicillin G row gives no frequency**
(it is a single dose, but the table does not say so, while every other row carries
"x 10 days"), and **clindamycin is not labelled as the penicillin-allergy option**, so
it reads as a peer alternative.

## G9 🟡 epistaxis takes no blood pressure and no anticoagulant history (`pb_067`)
The Management block checks *"PR, RR, spO2, Temp, Weight"* — **no BP**. BP appears only
in the two disposition boxes at the end of the algorithm, so the book clearly regards
it as relevant; it is simply missing from the point where it matters. Nothing anywhere
on the page asks about **anticoagulants or antiplatelets**, which in adults is among
the most useful questions in epistaxis and changes both the risk and the disposition.

## G10 🟡 epistaxis: the posterior balloon has no inflation volume (`pb_067`)
*"Pass a lubricated foley catheter through the bleeding nostril into the nasopharynx,
**fill with NS** and pull forward"* — no volume is given anywhere. There is also no
warning about over-inflation (alar and septal pressure necrosis), no analgesia or
sedation note for a procedure that is very painful, and no **silver nitrate cautery**
step, which is the usual intermediate between a topical pledget and packing where a
visible anterior bleeding point exists.

## G11 🟢 otitis media offers no analgesia (`pb_068`)
The Presentation section is almost entirely pain — ear pain, ear rubbing, restless
sleep, irritability — and the Treatment section is antibiotics only. Analgesia is the
intervention that actually helps in the first 24 hours, and it is the one the parent
came for.

## ✓ VERIFIED FINE in this group (no action)
Modified Centor / McIsaac transcribed exactly, including the age adjustment (+1 for
3–14, 0 for 15–44, −1 for ≥45) and all four clinical criteria · the child-vs-adult
scoring thresholds · penicillin VK 250 mg BD paeds / 500 mg BD adult × 10 days ·
benzathine penicillin G 600 000 IU / 1.2 million IU by the 27 kg split · clindamycin
7 mg/kg (max 300 mg) q8h × 10 days · AOM diagnostic criteria (they mirror the AAP
definition) · AOM duration 10 days if <2 years, 7 days if older · **sinusitis is
correct throughout** — the 2-major-or-1-major-plus-2-minor rule, all three
bacterial-sinusitis triggers including double-sickening and the ≥10-day and
severe-plus-fever routes, amoxicillin 45 mg/kg/dose BD × 7 days, the amox-clav
indications (<2 years, moderate-severe, daycare, antibiotic in the last 4 weeks), and
the 72-hour reassessment · otitis externa presentation and examination findings
including the tragus-tenderness pearl that distinguishes it from otitis media ·
mastoiditis presentation and the postauricular findings · epistaxis first aid (lean
forward, pinch, do not tilt the head back, a full 15 minutes) · **topical tranexamic
acid before packing, which is well supported and more current than much of the book** ·
the escalation order pledget → anterior pack → contralateral pack → posterior balloon ·
vaseline TID for 7–10 days on discharge.

---

# H. PAEDIATRIC TB GROUP AUDIT (pp.71–73) — flags raised 2026-07-28

Fifth advance-pass group. 3 topics (diagnosis + Keith Edwards score; the three
pulmonary scoring systems; treatment). Checked against **UCG 2023 §TB** and the **WHO
Pocket Book**. pp.71–72 are faithful verbatim reproductions of published scoring
systems and need no dose review; everything below is on p.73 or is a gap across the
group.

**One thing applied** (H1). The rest need Grey/OE.

## H1 ✅ APPLIED — the paediatric steroid cap was a dropped zero (`pb_073`)
Source p.73 prints the adjunctive steroid as **"2mg/kg (max 6mg/day) x 4 weeks"**.
Corrected to **max 60 mg/day**.

**Verified visually** at 200 dpi before touching it — the source really does print
6mg, so this is not a `pdftotext` artifact. Why 60 is certain, three ways, all
internal to the book:

1. **A 6 mg/day cap on a 2 mg/kg/day dose binds at 3 kg** — that is, for every single
   patient who reaches this box. A cap that never allows the weight-based dose to
   apply is self-evidently a misprint rather than a clinical choice.
2. **`pb_049_uti_kidney` prints the same drug at the same 2 mg/kg/day for the same
   4 weeks with "max 60mg/day".**
3. **`pb_128_im_tb` (adult TB, same indication) gives prednisone 60 mg/day.** Without
   the correction the book gives an adult 60 mg and caps a child at 6 mg.

This one matters more than most typos: the gate immediately above the box is **TB
meningitis / severe miliary TB / pericardial effusion**, which is precisely where
adjunctive corticosteroids reduce mortality. A tenfold under-cap would have made them
close to placebo. **Grey should fix the source PDF.**

## H2 🔴 pulmonary TB gets an 8-month course where UCG and WHO give 6 (`pb_073`, also `pb_128_im_tb`)
p.73, after the intensive phase: *"Cerebral TB requires 10 more months of treatment ·
**Pulmonary TB requires 6 more months of treatment**"* — a 2 + 6 = **8-month** total.

UCG 2023 is explicit and tabulated:
- *"All forms of TB in adults: **2RHZE / 4RH**"* — a **4-month** continuation, 6 months total
- *"TB meningitis, Bone: **2RHZE / 10RH**"*
- and in the text: *"Treat as per pulmonary TB but continuation phase is 10 months
  instead of **4** (2RHZE/10RH)"*

**The book gets the CNS number exactly right** (10 more months, matching UCG
character for character) **and the pulmonary one wrong**, which is what makes it look
like an error rather than a deliberate local policy. It is also consistent across the
book — `pb_128_im_tb` prints the same "6 more months" for adults — so it must be fixed
in **both** places, and it is not the sort of thing I would correct unilaterally.

Two extra months of rifampicin and isoniazid for every pulmonary TB patient means
extra hepatotoxicity exposure, extra adherence burden, and a course that does not
match the fixed-duration packs the national programme dispenses. Worth noting to OE
as well: **WHO has since endorsed a 4-month regimen (2HRZ(E)/2HR) for non-severe
drug-susceptible TB in children aged 3 months to 16 years**, so the book is two months
longer than the standard course and four months longer than the modern paediatric one.

## H3 🟡 the LFT gate and its own footnote give different thresholds (`pb_073`)
The flowchart routes **ALT > 3 × ULN** to *"consult senior about a possible alternate
regimen"*. The footnote rendered directly beneath it says *"**Do not change the
regimen unless LFTs > 5 × the upper limit of normal**"*.

Both numbers are real, but they belong to different situations — the usual rule stops
anti-TB drugs at **>3 × ULN with symptoms** and at **>5 × ULN without**. The page
states both figures without the symptomatic/asymptomatic distinction that reconciles
them, so as printed the chart and its footnote simply disagree. One clause would fix
it.

## H4 🟡 nothing on the paediatric TB pathway tests for HIV (`pb_071`–`pb_073`)
HIV is not mentioned anywhere in the user-facing content of any of the three topics —
only inside a file-header comment. That is out of step with the rest of the book and
with the setting: **`pb_064` (SAM) explicitly says "Check mom for HIV if <18 months,
otherwise check patient"**, and paediatric TB in Uganda is heavily HIV-associated. HIV
status changes prognosis, mandates co-trimoxazole preventive therapy, and creates
rifampicin–ART interactions that alter the regimen. The book has an HIV OI page
(`pb_135`) to link to.

## H5 🟡 contacts are scored but never treated (`pb_071`, `pb_072`)
p.71 lists *"close contact with someone with tuberculosis within the last 2 years"* as
a risk factor, and **the entire first table on p.72 is a risk score for children in
contact with infected persons** — yet nothing anywhere in the group says what to do
for a well child contact who does not have TB.

The WHO Pocket Book already in the repo gives it plainly: **isoniazid preventive
therapy, 10 mg/kg daily for at least 6 months**, for under-5 contacts. This is a core
national-programme activity. As it stands the book helps you score a contact and then
stops.

## H6 🟡 children get no bacteriological confirmation route, but adults do (`pb_071`)
p.71's Diagnosis section offers **gastric aspirate ×3 only**. **Xpert MTB/RIF appears
nowhere in the paediatric group** — while **`pb_128_im_tb` (adult) says "If available,
perform Gene Xpert on 1 sputum sample"**. So the book routes adults to the
WHO-recommended initial diagnostic test and children to a 1950s technique.

This matters more for children than adults, because **Xpert Ultra is validated on
stool in young children** — which removes the need for gastric aspirate altogether in
exactly the group p.71 says cannot expectorate. The three scoring systems on p.72 are
all pre-Xpert clinical scores, which the file header already noted; this is the
actionable half of that observation.

## H7 🟢 "Source case is female" (+1) will puzzle readers (`pb_072`)
The 8-point risk score awards a point for the source case being female. It is
faithfully transcribed from the published score, where it reflects the caregiving
contact pattern in one specific study population, and it is not a risk factor to
generalise from. A one-line note would prevent it being read as a general rule — the
table already carries a footnote for the "high incidence area" criterion, so there is
a precedent on the same table.

## ✓ VERIFIED FINE in this group (no action)
**All four intensive-phase drug doses match WHO exactly** — isoniazid 10 mg/kg
(7–15, max 300 mg/day), rifampicin 15 mg/kg (10–20, max 600 mg/day), pyrazinamide
35 mg/kg (30–40, max 1.5 g/day), ethambutol 20 mg/kg (15–25, max 1.6 g/day) · the
continuation phase being isoniazid + rifampicin only, at the same doses · **cerebral
TB "10 more months" — matches UCG's 2RHZE/10RH exactly** · the steroid indication list
(TB meningitis, pulmonary TB with respiratory distress, airway obstruction from hilar
nodes, severe miliary TB, pericardial effusion) · the steroid taper shape
(2 → 1 → 0.5 mg/kg) · pyridoxine throughout treatment and its three weight bands ·
gastric aspirate ×3 on separate early mornings before eating or ambulating · the
"consider TB" and "more likely" lists · **all three scoring systems transcribed
verbatim and correctly**, including the Keith Edwards ≥7 threshold, the modified
Edwards ≥7 threshold, and the Brazilian ≥40 / 30–39 / ≤29 bands and every point value.
