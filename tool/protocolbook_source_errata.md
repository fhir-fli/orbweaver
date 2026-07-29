# ProtocolBook — SOURCE PDF ERRATA

**Every error found in `ProtocolBook eBook 1.7.pdf` during the digitization and the
evidence audit.** All of these are **already corrected in the app**. This sheet exists
because the **master document still has them**, so they would come back in v1.8.

Compiled 2026-07-28 from the correction notes in each topic file's header.
Format: **what is printed** → **what it should say**.

Unless noted, each was confirmed against a 150–300 dpi render of the page, not just a
text extraction.

---

# 🔴 FIX THESE FIRST — these can harm a patient if followed as printed

| Page | Printed | Should be |
|---|---|---|
| **80** | Adults: Morphine **2–10 mg/kg/dose** PO | **2–10 mg/dose**. As printed this is ~140–700 mg in an adult — a lethal dose. The child mg/kg row and the Step-3 adult "1–2 mg/dose" both confirm the intent |
| **146–158 (formulary)** | Morphine adult dose **per kg** | **per dose** — same error as p.80 |
| **136** | Flucytosine **25 gm/kg/dose** | **25 mg/kg/dose** QID (100 mg/kg/day). A grams-per-kg dose is physically impossible |
| **73** | Prednisone 2 mg/kg **(max 6 mg/day)** × 4 weeks | **max 60 mg/day**. A 6 mg cap binds at 3 kg, i.e. for every patient — the mg/kg becomes meaningless. p.49 prints the same regimen at max 60 mg, and p.129 gives an adult 60 mg. The gate above this box is TB meningitis / miliary TB / pericardial effusion, where steroids reduce mortality |
| **68** | Amoxicillin **45 mg/dose** PO BD (and amox-clav, same line) | **45 mg/kg/dose**. As printed a 15 kg child gets 45 mg BD instead of 675 mg — a 15× underdose for the commonest childhood infection in the book. p.70 prints the same drug and regimen *with* the /kg |
| **129** | Both FDC tables: 30–37 kg and 38–54 kg tablet counts **swapped** | **30–37 kg → 2, 38–54 kg → 3, 55–70 kg → 4, >70 kg → 5** (intensive). As printed the lighter patient receives MORE tablets than the heavier one |
| **45** | Hydrocortisone **50 mg/kg/day** | **2 mg/kg bolus then 1 mg/kg q6h**, and only in refractory shock with suspected adrenal insufficiency. ~25× the paediatric stress dose as printed; p.37 gives 5 mg/kg for anaphylaxis — a 10× internal disagreement for one drug |
| **55** | Meningitis: **>3 months** = cefotaxime + ampicillin · **<3 months** = ceftriaxone | **Inverted.** Ampicillin is the Listeria drug and Listeria is an under-3-month pathogen. As printed, infants <3 months get no Listeria cover *and* get the cephalosporin normally avoided in neonates (bilirubin displacement; fatal precipitation with calcium) |
| **38** | Rabies **Vaccine** row prints "Human Ig 20 U/kg OR Equine Ig 40 U/kg … days 0, 3, 7, 14" | The Ig doses belong to the **immunoglobulin** row (given **once**); days 0/3/7/14 is the **vaccine** schedule. Followed as printed: repeated RIG on four days and **no vaccine at all** |
| **22–23** | Artesunate weight bands **reversed** (<20 kg 2.4 / ≥20 kg 3 mg/kg) | **<20 kg → 3 mg/kg · ≥20 kg → 2.4 mg/kg** (WHO, and the book's own severe-malaria medications page) |
| **39** | "**DO NOTE** treat with ice" | "**DO NOT** treat with ice" — the line sits in a DO-NOT list, so the typo inverts a contraindication |
| **88** | "Phototherapy will not treat **indirect** hyperbilirubinemia" | "**direct** (conjugated)". Inverted — phototherapy treats indirect bilirubin; it does nothing for conjugated hyperbilirubinaemia, which points to obstruction |
| **100** | Gentamicin "**(also for MRSA)**" | Delete. Gentamicin has no reliable MRSA activity; the MRSA agents are clindamycin/vancomycin, already listed under gram positives |
| **134** | Regimen (e) labelled "**Trichomoniasis**", lists clotrimazole / nystatin | Those are antifungals — relabel **Candidiasis**, and add the real trichomoniasis regimen: **metronidazole 2 g PO × 1** (alt tinidazole 2 g) |
| **47** | "Satisfactory urine output **1–2 mL/hr**" | **1–2 mL/kg/hr**. For a 20 kg child that is a 20× difference, and it sits in DKA where urine output gates potassium. The same page says "<1 mL/kg/hr" 15 lines later |
| **63** | MUAC 15–19 y: MAM **≥16.5** & <21.0 · SAM <18.5 | MAM **≥18.5** & <21.0. As printed the bands **overlap** — 17.0 cm is both MAM and SAM. Every other row has MAM's lower bound equal to SAM's upper bound |
| **33** | NAC load, >40 kg: "**150 mL/kg** in 200 mL diluent" | **150 mg/kg**. Self-contradictory as printed, and the other two weight rows are mg/kg |
| **20** | D10% alternative: "**4 ml D5% with 1 ml D50%**" | **8 ml D5% + 1 ml D50%** = 900 mg in 9 ml = exactly D10.00%. As printed it is **D14%** |
| **73 / 129** | "Pulmonary TB requires **6 more months**" (8 total) | **4 more months** (6 total, 2RHZE/4RH per UCG and WHO). The CNS figure of 10 more months is already correct |

---

# 🟡 Wrong, but lower consequence

| Page | Printed | Should be |
|---|---|---|
| **45** | "1 mL D50% + 9 mL D5% = D10%" | Computes to **D9.5%**. Use 8 mL NS + 2 mL D50%, or 1 mL D50% + 8 mL D5% |
| **45** | SIRS temp "<35.4 axillary (36 **axillary**)" | "(36 **core**)" — matches the ">37.9 axillary (38.5 core)" pattern on the same line |
| **47** | Soluble/regular insulin SC 0.15 IU/kg **q2h** | **q4h** for regular insulin (peaks 2–4 h, lasts 5–8 h, so q2h stacks). q2h belongs to a rapid-acting analogue |
| **60** | Splenic-sequestration box has a **third bullet that does not print** | The PDF text layer contains "c. Otherwise treat" but the box **clips it**, and it is truncated mid-sentence even in the text layer. **Only you know what it was meant to say** — and the box needs enlarging |
| **61** | Table titled "Does the patient have any contraindication?:" | The table beneath is concurrent-issue **management** (fever, hypoglycaemia, convulsions, anaemia, infection, hydration). Retitle — looks like a template paste |
| **62** | "**pO2** >94% on room air" | "**SpO2** >94%". A percentage on room air is a saturation; the same page says spO2 twice |
| **63** | "Use WFL/WFH if **<6 years** (59 months)" and "BMI/age if **≥6 years**" | **5 years** in both. 59 months is under five, and the table below uses "6 to 59 months" / "5 to 19 years" |
| **65** | "Do not use digoxin in newborns" | **Delete.** Digoxin is never offered anywhere on the page or in WHO's SAM chapter — it warns against a treatment that was never given, while implying it is fine in older children |
| **69** | Mastoiditis: "Ceftriaxone 2 g IV BD **or 8 hourly**" | Delete "or 8 hourly" — that reaches **6 g/day**, above the 4 g/day ceiling in your own formulary and on p.54 |
| **70** | Amoxicillin "25 mg/kg/dose (**max 1 g**) BD" | **max 500 mg/dose** — the 1 g looks like a per-day figure written into a per-dose cell |
| **146–158** | Lorazepam "0.5–2 mg IV **12–4hrs**" | **q2–4hrs** |
| **146–158** | Sulfadiazine notes "**for PCP**" | **for toxoplasmosis** — sulfadiazine + pyrimethamine + leucovorin, matching your own p.136. Sulfadiazine has no role in PCP |
| **146–158** | Ceftriaxone "q23hr" · Cloxacillin "q4hr5" | **q24hr** · **q4hr** |
| **136** | Leucovorin "5 mg PO **QD once every 3 days**" | Contradictory — "5 mg PO once every 3 days" |
| **62** | Discharge criteria: 2-column list numbers its "4" as a **second "2"** | Renumber 1–6 |

---

# 🟢 Spelling and wording

| Page | Printed | Should be |
|---|---|---|
| 28 | ant-hypertensives | anti-hypertensives |
| 35 | delirium **trements** | delirium **tremens** |
| 38 | Immunocrompromised | Immunocompromised |
| 38 | dangling "*" footnote marker with no footnote text | remove, or add the footnote |
| 39 | "Consider the **follow** labs" | "**following** labs" |
| 39 | "**effected** limb" (×2) | "**affected** limb" |
| 40 | "…paralysis and respiratory failure **paralysis**" | duplicated word — delete the second |
| 44 | **Paramomycin** (×2) | **Paromomycin** |
| 49 | footnote "*" on item 1 with no matching footnote text | remove, or add the footnote |
| 59 | **Sulphadoxinepiremetamine** | **Sulfadoxine-pyrimethamine (SP)** |
| 67 | heading "Epistaxis*" — trailing marker with no footnote | remove |
| 72 | CXR "**military** pattern" | **miliary** pattern |
| 73 | "Severe **military** TB" | "Severe **miliary** TB" |
| 79 | jerry-can label "**Overwhelmign** Pain" | **Overwhelming** — ⚠️ this is baked into the artwork, so the image must be regenerated |
| 126 | "**spacy-occupying** lesion" | **space-occupying** |
| 129 | "Severe **military** TB" | **miliary** |
| 146–158 | Gancyclovir · Valgancyclovir · Paramomycin | Ganciclovir · Valganciclovir · Paromomycin (correct INN spellings) |

---

## Notes

- **p.79's typo is in the image itself**, not in text — the jerry-can artwork has to be
  regenerated. The app works around it by carrying the correct wording in an
  accompanying table.
- **p.60's missing bullet is the one item on this sheet I cannot write for you.** The
  sentence is incomplete in your own source file.
- Additions the app made that are **not** errors in your text, so they need no PDF fix
  unless you want parity: a paediatric epinephrine ceiling on pp.13/20, and the
  clinical gaps filled during the evidence audit (priapism, incentive spirometry,
  isoniazid preventive therapy, and so on). Those are tracked in
  `protocolbook_needs_oe_rereview.md`, not here.
