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
  `protocolbook_needs_oe_rereview.md`, not here.

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
