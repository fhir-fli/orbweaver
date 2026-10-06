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
| **125** | SVT flow chart: **"Is the patient stable?" → No → Adenosine**, with cardioversion demoted to a note | **The branch is inverted.** Unstable → **immediate synchronised cardioversion** (50–100 J adult, 0.5–1 J/kg child). Stable → vagal manoeuvres → adenosine. As printed the stable patient never reaches adenosine at all, and the unstable one is given a drug instead of electricity. Verified on the rendered page, not just the text |
| **143** | Hyperkalaemia: the **K > 6.5 / ECG-change** branch gets calcium, furosemide and dialysis; **insulin/glucose and salbutamol sit on the milder 6.0–6.5 branch** | Give **calcium AND insulin/glucose + salbutamol in parallel** in the severe branch. Calcium stabilises the myocardium for 30–60 min and **does not lower potassium at all**; furosemide only works if the patient passes urine. As printed, where dialysis is a day away the sickest patient's potassium is never lowered |
| **123** | Thrombolytics **"ideally within first 24 hours of chest pain"** — the only timing guidance on the page | **Within 12 hours.** Benefit is not established beyond 12 h while the bleeding risk is unchanged. Door-to-needle ≤ 30 min. Beyond 12 h only with ongoing ischaemia + persistent ST elevation, or instability, and only where PCI is unavailable |
| **123–124** | Enoxaparin and clopidogrel printed as single doses with **no age qualifier** | **At age ≥ 75 with fibrinolysis: no enoxaparin IV bolus, 0.75 mg/kg SC q12h (max 75 mg for the first 2 doses); clopidogrel 75 mg with NO 300 mg load.** The full adult regimen causes excess intracranial haemorrhage in this group |
| **140** | **"Dopamine 2-5mcg/min"** | Missing its **/kg** — and the wrong drug. Use **norepinephrine 0.05–0.5 mcg/kg/min**, or **dobutamine 2–20 mcg/kg/min** for pump failure. Every other dopamine dose in this book is per kilogram; even 2–5 mcg/kg/min is the discredited "renal dose" |
| **137** | Histoplasmosis: **"If CD4 < 50, consider adding rifabutin 300 mg PO QD"** | **Delete.** Rifabutin has no antifungal activity — the line was carried over from the MAC section on the same page. It is a strong enzyme inducer and would **lower itraconazole levels**, risking failure of the infection being treated |
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
| **60** | Splenic-sequestration box has a **third bullet that does not print** | See the investigation note at the bottom of this sheet. The text ends at "c. Otherwise treat" in **both** editions and in the tagged structure tree, and it is not recoverable from any file on this machine — **only your original Word document can settle it** |
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

## p.60 — the invisible third bullet: what the search actually found

Grey asked whether I had searched the original PDF for it. I had not — I had only
looked at p.60. Doing it properly:

1. **Whole-book text search, eBook 1.7** — "Otherwise treat" occurs **exactly once**
   in all 176 pages, at p.60, ending there.
2. **`ProtocolBook Print 1.7.pdf`** (in `~/dev/quick_reference/`, a second edition I
   had not been using) — **identical truncation**, same three words.
3. **Word bounding boxes** — the phrase has a real on-page position (x 226–275,
   y 242–249 pt), i.e. it is not parked off-page.
4. **300 dpi render of that exact strip** — pure white. Nothing is painted. The dark
   pixels inside the text's own bounding box turned out to be the two box borders
   crossing it, not glyphs.
5. **The tagged structure tree** (inflated from the PDF, and generated from Word's own
   document model) reads:
   ```
   /S/Span /ActualText(c.)
   /S/Span /ActualText(Otherwise treat )
   /S/LBody ...        <- the list item closes here
   /S/Textbox ...      <- it lives inside a Word text box
   ```
   The list item is well-formed and contains those two spans and nothing else.
6. **No source document on this machine** — no `.docx`, `.odt`, `.indd` or `.pages`
   anywhere under `/home/grey`; `~/dev/quick_reference` is a git repo but tracks only
   `LICENSE`, so there is no earlier revision of the PDF to diff against.

7. **The page content stream itself** (page object 136, contents object 1001,
   inflated) settles the mechanism exactly:
   ```
   /P <</MCID 73>> BDC q
   193.92 263.76 90 64.8 re      <- clip rectangle: y 263.76 .. 328.56
   W* n
   BT
   1 0 0 1 226.39 256.63 Tm      <- text baseline at y 256.63
   0 g                           <- fill colour BLACK, not white
   [(O)(t)(h)(e)(r)(w)(i)(se)( t)(r)(e)(at)( )] TJ
   ```

**Conclusion — it is black text, clipped, not white text.** The Word text box's clip
rectangle bottoms out at **y 263.76**. `"normal crisis"` sits at **y 265.75** — the
last line that fits. `"c. Otherwise treat"` sits at **y 256.63**, about **7 points
below the clip edge**, so the renderer discards it. It is laid out and written into
the file, then clipped away at paint time: copy-paste and screen readers get it, ink
never does. That is why it could sit in two published editions unnoticed.

**Nothing followed it.** The next marked-content item (MCID 74) is the arrow path, not
another text run, and the tagged structure closes the list item immediately after
`"Otherwise treat "`. Word emitted that single overflow line and nothing after it, so
the sentence is unfinished **in the source document too** — it is not that the PDF
lost the ending.

**Practical consequence:** simply enlarging the text box in Word will make the line
reappear as an incomplete sentence. It has to be written, not recovered.

For what it is worth, the a/b/c structure ("Hgb may continue to drop" / "may require
more aggressive transfusions than normal crisis" / "Otherwise treat…") reads as though
it ended something like *"…as a normal crisis"* — but that is a guess from the shape of
the list, not something found in the file, and it should not go into the book on my
say-so.

## Notes

- **p.79's typo is in the image itself**, not in text — the jerry-can artwork has to be
  regenerated. The app works around it by carrying the correct wording in an
  accompanying table.
- Additions the app made that are **not** errors in your text, so they need no PDF fix
  unless you want parity: a paediatric epinephrine ceiling on pp.13/20, and the
  clinical gaps filled during the evidence audit (priapism, incentive spirometry,
  isoniazid preventive therapy, and so on). Those are tracked in
  `protocolbook_needs_oe_rereview.md` (removed 2026-10-06, in git history), not here.

---

# 🕵️ CLIPPED-TEXT SWEEP — text that is in the PDF but never prints

**Run 2026-07-29 across all 176 pages**, after p.60 turned out to be black text sitting
below its text box's clip rectangle. Method: walk the page tree, inflate each content
stream, track the `q`/`Q` graphics stack and every `x y w h re W n` clip, track the
text matrix, and flag every text-showing operator whose baseline falls outside the clip
in force.

**Result: 21 clipped runs on 10 pages** — 37, 43, 45, 49, 53, 60, 86, 105, 106, 122.

Calibration: for 8 pt text the glyphs rise ~5.6 pt above the baseline, so a baseline
**≥ ~5.5 pt below** the clip bottom means the whole glyph is gone. p.53's run is only
1.66 pt below and **is** partially visible on the page — rendered and confirmed, which
validates the threshold. Every other hit was rendered at 300 dpi and confirmed absent.

## 🔴 Real content lost from the printed page

| Page | Printed page shows | Hidden text | Status |
|---|---|---|---|
| **37** | Epinephrine box ends "…Repeat q5-15 minutes if no improvement" | **"Note this is NOT the same "** — *truncated in the source too* | ⚠️ **needs your wording.** The book uses **1:1000 IM** here and **1:10,000 IV** on pp.13/20. This is a warning about exactly the concentration confusion that kills people, and it has never appeared in any printed copy. **The app has no such warning either** |
| **106** | Hypertensive-emergency box ends at "3. Labetalol…" | **"4. Esmolol: 500 mcg/kg/minute over 1"** — *truncated in the source too* | ⚠️ **needs your wording.** A whole fourth agent. The app has only the three |
| **49** | Dipstick criteria end at "4. Edema" | **"5. Hypertension"** | ✅ **applied** — it was missing from the app too, and it is a cardinal feature of acute glomerulonephritis |
| **43** | PLAN B box ends at "2) Continue breast feeding…" | **"3) Reassess and reclassify at 4 [hours]"** | ✅ **applied** — was missing from the app too; reassessment at 4 h is core to WHO Plan B |
| **60** | Splenic sequestration box ends at "b. …normal crisis" | **"c. Otherwise treat"** — *truncated in the source too* | ⚠️ **needs your wording** (see the section above) |
| **86** | "…only if respiratory distress or severe abdominal" | **"distension"** | ✅ **applied** — the app had guessed "signs" |
| **105** | Decision box reads "Ketones in" | **"Urine"** | ✅ app already read "Ketones in the urine?" |
| **45** | "…watch for signs of volume" | **"overload"** | ✅ app already read "volume overload" |
| **43** | PLAN A box reads "…fewer than 2 of the above signs of" | **"dehydration"** | ✅ applied |

## Not content loss
- **p.53** — "6hrs" is only 1.66 pt below the clip and **does** print, sliced but
  legible ("Requires salbutamol no more than every 6hrs").
- **p.122** — the list numbers "1." "2." "3." sit ~10 pt to the **left** of their box
  and do not print, but the three angina criteria themselves print in full. Cosmetic.

## Why this matters for the source document
This failure mode is invisible to every normal check. It does not show in a render, it
does not show on paper, and proofreading cannot catch it — the only trace is that text
extraction returns more than the page displays. **Four of the ten cases lost real
clinical content**, and in three of those the sentence is unfinished in your source as
well, so enlarging the box will reveal a fragment rather than restore a sentence.

Worth checking any text box you resize in v1.8: if a box is full to its last line,
assume something may be sitting just underneath it.

---

# 🟡 ADDED 2026-08-25 — from the pp.114–142 advance pass (OE-confirmed)

| Page | Printed | Should be |
|---|---|---|
| **140** | Rate formula *"Rate of IVF infusion to increase Na by 0.5 mEq/L/h = 1000 / (2 × [Na]serum)"* | Garbled — it has **no infusate term and no body-water term**, so it returns the same answer for 3% and 0.9% saline. Use rate (L/h) = desired rise ÷ (change per L infusate) |
| **142** | IV potassium *"40 mEq in 1 L NS (children 0.5–1 mEq/kg/hr)"* | Incompatible as printed — at 40 mEq/L a 20 kg child at 1 mEq/kg/hr needs **500 mL/hr**. Without monitoring the rate is **0.2 mEq/kg/hr**; 0.5–1 is an ICU rate. Peripheral max 40 mEq/L, central up to 400 |
| **142** | Magnesium *"2 g … over 30 minutes, 6 hourly"* as a standing order | Level-guided: 1–2 g over 15–60 min then a slower infusion; **max ~30–40 g/24 h**, far less in renal impairment; check reflexes, renal function, RR and BP before each repeat |
| **123** | *"Ischaemic stroke within 3 months (EXCEPT ischaemic stroke within 3 hours)"* | **4.5 hours** — and the exception means **stroke-dose** lysis for the stroke, not coronary-dose |
| **124** | Beta blocker within 24 h with **no contraindications listed**; options include atenolol and labetalol | Add the withhold list (Killip II–IV, low-output/shock risk, hypotension, PR > 0.24 s, AV block, bradycardia, bronchospasm). **Atenolol and labetalol are not preferred post-MI**; prefer metoprolol succinate, carvedilol or bisoprolol |
| **131** | PERC applied as the **first gate to every patient**, before Wells | PERC is valid **only after** low pretest probability is established. Order: probability → PERC → D-dimer → imaging |
| **131** | Low-risk PE → *"no treatment"* | A low Wells score alone does not exclude PE — **D-dimer required unless PERC negative** |
| **131** | **No pathway at all for high-risk (massive) PE** | The book stocks thrombolytics for STEMI two pages earlier but never gives the PE indication. Added: definition, systemic thrombolysis, agent doses, heparin handling |
| **128** | TB workup: *"HIV?" → Yes → "Discuss with senior"* — the algorithm ends there | The common case in this setting. Needs the parallel Xpert + urine LF-LAM pathway, ART timing, and co-trimoxazole |
| **129** | Adjunctive steroids listed for **pericardial effusion** with no HIV qualifier; one prednisone regimen for all five indications | **Not recommended if HIV-positive** (IMPI: no benefit, increased HIV-associated malignancy). TB meningitis uses **dexamethasone 0.3–0.4 mg/kg/day tapering over 6–8 weeks**, not a flat 60 mg |
| **129** | *"Do not change the regimen unless LFTs > 5 × ULN"* | Symptomatic patients stop at **≥ 3 × ULN**; 5 × applies to the asymptomatic |
| **134** | Gonorrhoea **ceftriaxone 250 mg IM** | **500 mg IM (1 g if ≥ 150 kg)** — raised because of declining cephalosporin susceptibility |
| **134** | Chlamydia: azithromycin first-line, doxycycline the alternative; pregnancy erythromycin 1 g q12h | **Doxycycline is first-line** in non-pregnant patients; pregnancy is **azithromycin 1 g**; erythromycin 1 g BD is not a correct regimen and erythromycin is no longer recommended in pregnancy |
| **134** | Bacterial vaginosis given the **same single 2 g dose** as trichomoniasis | BV needs **metronidazole 500 mg BD × 7 days**; single-dose is not a recommended BV regimen. The trichomoniasis regimen was copied onto it |
| **134** | Inpatient PID **ceftriaxone 250 mg IM daily** | **1 g IV every 24 hours** — these patients have sepsis, peritonitis or an abscess |
| **135** | Cryptococcal induction lists three 14-day regimens | Add the **single-dose liposomal amphotericin B 10 mg/kg** (AMBITION) regimen — now WHO-preferred, and developed for exactly this setting |
| **137** | Adult histoplasmosis maintenance **"itraconazole 200 mg PO TID"** | **200 mg TID × 3 days, then 200 mg BD.** The children's line has the step-down; the adult line dropped it, leaving an adult on 600 mg/day indefinitely |
| **137** | Paediatric rifabutin **15 mg/kg** with no cap (and **5 mg/kg** elsewhere on the page) | Treatment **10–20 mg/kg, max 300 mg/day**; prophylaxis is 5 mg/kg. State which is which |
| **136** | PCP steroids if *"O₂ sat on room air is < 90%"* | **PaO₂ < 70 mmHg, or A-a gradient ≥ 35** — by oximetry, **SpO₂ ≤ 92%**. Start within 72 h of the first TMP-SMX dose |
| **138** | Zoster **aciclovir "1 g PO TID"** — the valaciclovir dose | **800 mg five times daily.** The two drugs are not interchangeable at the same dose |
| **125** | AF: *"Needs anticoagulation. Warfarin 10 mg PO daily x 2 days"* | Anticoagulate on **CHA₂DS₂-VASc (men ≥ 2, women ≥ 3)**. **No loading dose** — routine loading increases bleeding without faster protection; start **2.5 mg** in the older or frail. First INR at 3–5 days |

---

# 🟡 ADDED 2026-08-27 — from the pp.114–142 advance pass, part 2 (OE-confirmed)

| Page | Printed | Should be |
|---|---|---|
| **114** | Limb leads *"mid-arm, lateral bicep"* and *"7.5 cm below the umbilicus"* | Those are **torso (Mason-Likar) monitoring positions**, not the standard diagnostic 12-lead. Standard is **wrists and ankles**. Torso placement alters limb-lead voltage and axis — mostly via the left arm — and distorts the **LVH voltage and inferior Q-wave/axis criteria this same chapter then uses** |
| **114** | *"R waves in lead II should be the sum of the R waves in lead I and lead III"* | Einthoven's law applies to the **net deflection at any instant**, not the R wave: **the amplitude of lead II equals the sum of leads I and III**. As printed it will often appear not to hold |
| **117** | **Complete AND incomplete LBBB both printed as "QRS 0.10–0.12 s"** | **Complete LBBB ≥ 0.12 s (120 ms); incomplete 110–120 ms.** The RBBB rows were already correct — only the LBBB pair is wrong |
| **119–120** | LBBB example strips shown with **no rule for calling STEMI in LBBB** | A new LBBB is **no longer automatically a STEMI equivalent** — apply **Sgarbossa / modified Sgarbossa**. Decision-critical here, where the thrombolytic is on the shelf |
| **119–120** | Inferior and posterior MI given standard 12-lead cues only | **Inferior → record V3R–V4R** (RV infarction changes management: no nitrates, give fluids). **Posterior → record V7–V9** (ST elevation ≥ 0.5 mm confirms) |
| **122** | "Likelihood of Coronary Artery Disease" grid | A Diamond-Forrester-style table that **substantially overestimates** current prevalence — PROMISE observed 13.9% against 40.6% predicted; another cohort 7% against 31.4%. **About half of "intermediate" patients reclassify to low.** As printed it pushes toward more testing than warranted |
| **122** | HEART score ECG row *"Significant ST depression"* | The validated criterion is significant ST **deviation** — depression **or** elevation not attributable to LBBB, LVH or digoxin |
| **130** | DVT/PE *"warfarin 10 mg PO daily × 2 days"*, no DOAC, no heparin overlap | **A DOAC is first-line for VTE.** If warfarin is all there is: **no loading dose**, and **overlap with LMWH/UFH for ≥ 5 days AND until INR ≥ 2 for 24 h** — warfarin alone from day 1 is inadequate. This also contradicted the AF page, which was already corrected |
| **130** | UFH *"80 units/kg (5000 units max), then 18 units/kg/hr (1000 units max)"* | **The caps are not part of the venous nomogram** — they belong to fibrinolysis-associated heparin on the ACS pages. They systematically underdose heavier patients (an 80 kg patient needs ~1,440 units/hr). Titrate to aPTT/anti-Xa, uncapped |
| **134** | Herpes entry says treat *"any patient with zoster"* | This entry is **genital herpes (HSV)**, not herpes zoster (VZV) — a wording slip carried in from the VZV page |
| **134** | Syphilis *"benzathine penicillin 1.2 million IU IM in each buttock"* | Correct in total but easy to misread — state **"2.4 million IU total (1.2 MU per buttock)"**. Note CDC uses a **1-year** cutoff for early syphilis where some programmes use 2 years |
| **141** | Hypernatremia block ends with *"assume hypotonic hyponatremia"* | A **copy-paste carryover** from the hyponatraemia evaluation. Removed |
| **142** | Central-line potassium *"up to 400 mEq/L"* stated without its condition | True, but the **400 mEq/L / 40 mEq/hr regimen is for urgent life-threatening hypokalaemia under ICU-level care with continuous ECG**. Routine ceiling is **10 mEq/hr, 200 mEq/24 h at ≤ 40 mEq/L** |

---

# 🟡 ADDED 2026-08-28 — from the WHO Pocket Book advance pass (OE-confirmed)

**These are ProtocolBook errata found by comparing the two books against each
other.** The flag was raised on the WHO volume; OE's answer changed the
ProtocolBook too. All corrected in the app.

| Page | Printed | Should be |
|---|---|---|
| **12, 13, 22, 45, 61, 150 (formulary)** | Paediatric hypoglycaemia: **D10% 5 mL/kg IV** — in the triage steps, both PALS bradycardia branches, severe malaria, paediatric sepsis, sickle-cell stroke and the formulary | **2 mL/kg (0.2 g/kg).** 5 mL/kg is 2.5× the PES/AAP/APLS standard; the larger osmotic and glucose load can provoke **rebound hyperinsulinaemic hypoglycaemia**, and there is no evidence 2 mL/kg under-treats. The safeguard is repeat measurement plus a maintenance infusion, not a bigger bolus. Applies at every age and in severe acute malnutrition |
| **39** | Snake bite, antivenom box: epinephrine listed only as **"ready in case of anaphylaxis"** | **Add prophylactic SC epinephrine 0.005 mg/kg (max 0.25 mg) BEFORE the infusion.** It is the only premedication with randomised evidence — severe reactions cut ~40% — and the case is strongest with the less-purified polyspecific antivenoms used across sub-Saharan Africa. Also state that **hydrocortisone cancels out epinephrine's benefit**, and that ~90% of reactions occur in the first hour with 40% needing rescue epinephrine |
| **128** | TB meningitis steroids: **"0.3–0.4 mg/kg/day, tapering weekly"** with no age qualifier | State it is the **ADULT** dose (0.4 grade II/III, 0.3 grade I) and that **children get 0.6 mg/kg/day**. Without the qualifier the two books read as contradicting each other on a mortality-reducing drug. Add the taper: wean IV by 0.1 mg/kg/day weekly × 4 weeks, then oral, tapering 1 mg/week × 4 weeks |
| **32–33** | NAC 2-bag table, no lower weight bound and no three-bag indication | Add: **under 5 kg take toxicology advice**; **three-bag** is still preferred for late presentation with established hepatotoxicity, massive or modified-release ingestion, or early severe liver injury; and **do not stop at 20–21 h** — continue until paracetamol is undetectable with INR/LFTs normal or improving and no encephalopathy |
| **135** | Cryptococcal maintenance: **"fluconazole 200 mg/day until immune reconstitution on ART"** | Give the actual stopping rule: **minimum 1 year**, and stop only after ≥ 1 year of antifungal therapy with **CD4 ≥ 100 sustained ≥ 3 months on ART and a suppressed viral load** — restart if CD4 falls |

| **106** | Essential hypertension, goals by group: **≥ 60 years (no DM/CKD) BP < 150/90**, everyone else < 140/90 | **Drop the age split.** **< 140/90 for most adults including diabetes without CKD, and for CKD**; **< 130/80 only for diabetes with high cardiovascular risk that tolerates it.** The JNC-8-style ≥ 60 / < 60 structure is out of step with every major guideline. OE was asked explicitly whether the lower target belongs in a Gulu district hospital and said no — **< 140/90 is the safer instruction here**, because the sub-130 trials depended on standardised office readings, home monitoring and close follow-up that do not exist in this setting |
| **75** | Iron studies table gives only arrows and a bare **Fe : TIBC 18%** line — no ferritin number anywhere | Print the cut-offs: **< 30 µg/L with no inflammation, < 70 µg/L (WHO) when inflammation is present, < 100 µg/L to avoid missing cases.** Inflammation is CRP > 5 mg/L, and **where CRP is unavailable — the usual case — assume inflammation for everyone.** Transferrin saturation **< 20% (or < 16%)** qualifies the 18%. Where iron studies are unavailable entirely, a **therapeutic iron trial** is a defensible diagnosis |

## Vitamin A, third dose (p.157 formulary, and the SAM management page)

**Print says days 1, 2 and 14. Correct is days 1, 2 and 15**, and day 15 is a fixed day,
not "at least 2 weeks later" — OE, 2026-08-29. The print also restricts the high dose to
eye signs or measles; **severe or persistent diarrhoea also qualifies**, and a child with
no deficiency signs on F-75/F-100/RUTF should get the low daily dose only.

For v1.8: change 14 → 15 in both places, add diarrhoea to the trigger, and state that the
referring-centre case gets days 2 and 15.

## Phenobarbital loading dose — the book disagrees with itself (p.20 vs p.154)

**p.154 formulary:** infants / children / adults, loading **15 mg/kg** IV/IM, max initial
loading dose **320 mg**, maintenance 5 mg/kg OD.
**p.20 resuscitation medications**, both the paediatric and the adult table: load
**20 mg/kg** IM/IV over 20 min, **all ages**, no milligram cap, further 10 mg/kg at
15 min, cumulative max 40 mg/kg, maintenance **3–5** mg/kg OD.

Not reconcilable by adding the cap: 320 mg is reached at 16 kg on the 20 mg/kg scheme.
Open with OE. For v1.8 the two pages must be made to agree, whichever way it is answered.

**ANSWERED 2026-08-30.** OE: 20 mg/kg at every age, no milligram cap, repeat 10–20 mg/kg
to a cumulative maximum of 40 mg/kg only with respiratory monitoring, maintenance
3–5 mg/kg/day from 12–24 h after the load. p.154 must change to match p.20 in v1.8, and
the 320 mg cap must be deleted — it underdoses everyone over about 16 kg.

## Ferrous sulfate — the anaemia work-up page underdoses by a third (p.75)

**Print says** 65 mg elemental iron = ferrous sulfate 200 mg, one tablet.
**Correct (OE 2026-08-30):** 65 mg elemental iron = one **325 mg dried (exsiccated)**
tablet. The dried salt is ~30% iron; the **heptahydrate is ~20%**, so a 200 mg tablet of
it carries about **40 mg** elemental iron, not 65.

For v1.8: prescribe by elemental iron, not salt weight, and drop the "200 mg = 65 mg"
line. The formulary's own "325 mg contains 65 mg" was right and needs the word *dried*.

---

## p.22 · Malaria — hypoglycaemia threshold, 2.2 mmol/L → 3.0

**The print says:**

> Severe = Fever PLUS any of: … Hypoglycemia (< 2.2 mmol/L)

🔁 **ANSWERED TWICE. THE SECOND ANSWER STANDS: 2.5 mmol/L.**

**2026-08-31, superseded.** OE first ruled 3.0 mmol/L for a child with malaria, and both
books were moved to it.

**2026-09-01, and this is the ruling to apply.** Asked again with the evidence the WHO
book itself carries — its Chart 10 page cites the **SugarFACT** RCT — OE reversed:
**2.5 mmol/L on both the general and the malaria pathways, and 3.0 retained ONLY for
severe acute malnutrition.** SugarFACT randomised 322 severely ill Malawian children aged
1 month to 5 years with a glucose of 2.5–5.0 mmol/L to immediate IV dextrose or to
observation, measured in-hospital mortality, found **no difference (15% against 16%)** and
was stopped for futility. It is the only randomised test of this question, in a
low-resource malaria-endemic population directly comparable to Gulu, and the 3.0 figure
rested on observational association and extrapolation.

**Applied** to the app: both books now print **2.5, with 3.0 in severe malnutrition**.
**For v1.8 the printed 2.2 must become 2.5.**

🛑 **Why this flipped, so it does not flip again.** The first question was asked without
the trial, which was sitting on the WHO book's own glucose page the whole time. Before
asking about a threshold, read what the books already cite for it.

Found by the cross-book threshold pass, which is the only instrument that has ever
compared these two figures: the number sits in a severity checklist on one page and in a
laboratory-findings list on the other, and nothing in either book pointed from one to
the other.
