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
