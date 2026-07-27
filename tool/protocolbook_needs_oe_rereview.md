# ProtocolBook — ITEMS NEEDING A SECOND OE PASS

Accumulating list, started 2026-07-27. These are items where an **independent
research pass disagreed with OE's first answer**, or raised something OE was
never asked. Grey will put these back through OpenEvidence.

**Status: INCOMPLETE — 1 of 4 research threads still running**
(anaphylaxis/bites/envenomation).
Do not treat this as final until it lands and this header is removed.

Applied state as of writing: `6e54a47`.

---

## 1. CONFLICTS — independent research contradicts OE's first answer

### 1.1 🔴 N-acetylcysteine: 2-bag for everyone, or 3-bag under 40 kg?
- **OE said:** 2-bag for >40 kg; keep the 3-bag regimen for ≤40 kg, citing the
  FDA's caution that 2-bag comparability is unproven in that weight range.
  **This is what is currently APPLIED** (`pb_032_paracetamol.yaml`).
- **Research says:** 2-bag for **everyone**, with weight-scaled diluent volumes
  (bag 1 = 200 mg/kg in 7 mL/kg up to 500 mL over 4 h; bag 2 = 100 mg/kg in
  14 mL/kg up to 1000 mL over 16 h), per ANZ guidelines 2020.
- **The argument neither of us raised:** the 3-bag regimen's *fixed adult diluent
  volumes* in a small child risk **hyponatraemia**. That cuts against OE's
  paediatric caution rather than for it, in a paediatric-heavy service.
- **Evidence offered:** 2NAC (Chiew, n=2,211) — non-inferior for acute liver
  injury (3.1% vs 2.9%) and hepatotoxicity (1.2% vs 1.6%); anaphylactoid
  reactions **7.1% → 1.3%**, p<0.0001. Confirmed by a 2025 *Clin Toxicol*
  systematic review. ANZ adopted 2-bag as standard in 2020.
- **ASK OE:** for a paediatric-heavy district hospital, does the hyponatraemia
  risk from fixed adult diluent volumes outweigh the FDA's ≤40 kg caution?
  Should we print weight-scaled 2-bag for all ages?

### 1.2 🔴 Paediatric atropine in organophosphate poisoning: 0.02 or 0.05 mg/kg?
- **OE said:** 0.02 mg/kg confirmed, no change needed. **Currently APPLIED** (unchanged).
- **Research says:** **Uganda Clinical Guidelines 2023 prints 0.05 mg/kg** per dose,
  doubling every 3–5 min. IPCS/WHO gives 0.015–0.05 mg/kg; MSF gives 0.02–0.05.
  i.e. 0.02 is the *bottom of a range*, not a consensus point — and the national
  guideline for the country this book is used in says 0.05.
- **Both agree:** no minimum absolute dose should be printed (the 0.1 mg floor
  traces to an unsupported sentence about a 1971 paper; Barrington, *Pediatrics*
  2011 — paradoxical bradycardia only below 0.0036 mg/kg, ~14× lower).
- **Also raised, not currently on our page:** titrate to **secretions**, not heart
  rate — "do not stop atropine for tachycardia, especially in children."
- **ASK OE:** should a Ugandan manual match UCG 2023 at 0.05 mg/kg?

### 1.3 🟡 Pralidoxime: omit, or omit-with-a-footnote?
- **OE said:** adding it "where available" is reasonable, AND omitting it is
  defensible. Genuinely equivocal. **Currently NOT on the page.**
- **Research says:** omit, firmly. Eddleston 2009 (placebo-controlled, WHO dose,
  with red-cell AChE showing real reactivation) — mortality **24.8% pralidoxime
  vs 15.8% placebo**. Cochrane 2011: the WHO regimen "is not supported."
  Cureus 2020 meta-analysis: intermediate syndrome **significantly increased**,
  RR 1.63 (1.01–2.62). Not on the WHO EML.
- **The complication:** **UCG 2023 still carries pralidoxime** (30 mg/kg IV over
  30 min, child 25–50 mg/kg, then 8 mg/kg/h), gated behind "only if not
  responding to adequate atropine". So omitting it silently contradicts the
  national guideline.
- **ASK OE:** omit silently, or omit with a one-line footnote acknowledging the
  UCG divergence?

### 1.4 🟡 Flumazenil: gated on the algorithm, or off it entirely?
- **OE said:** add an explicit contraindication line; keep it available for
  confirmed isolated ingestion. **This is what is APPLIED** (`pb_031_benzo_opioid.yaml`).
- **Research says:** remove it from the overdose algorithm **entirely**; confine
  it to procedural-sedation reversal. Notes the doses we print are in fact the
  *conscious-sedation* doses (correct as such); that it is **not on the WHO EML**;
  and Penninga 2016 (13 RCTs, 994 patients) — adverse events **RR 2.85**,
  serious adverse events **RR 3.81**, mainly fits and arrhythmias.
- Same direction as what was applied, but more decisive.
- **ASK OE:** should flumazenil appear on a general overdose algorithm at all?

### 1.5 🔴 Phenobarbital loading in non-neonates: 20 mg/kg or 15 mg/kg?
- **OE said:** change 15 → **20 mg/kg** for all children. **APPLIED**
  (`pb_020_resuscitation_meds.yaml` now reads 20 mg/kg for all ages).
- **Research says: KEEP 15 mg/kg.** WHO Pocket Book prints 15 mg/kg in **three
  separate places** (Chart 9 p.14; Annex 2 p.343; pp.49–50); **Uganda Clinical
  Guidelines 2023 prints 10–15 mg/kg** in both its malaria and status-epilepticus
  sections; AES 2016 prints 15 mg/kg. FDA (15–20) and ERC (20) are the sources
  for 20 — it is not wrong, but 15 is what WHO and Uganda actually say.
- **The practical argument for 15:** it reaches the same place via an explicit
  repeat pathway with less first-pass apnoea in a hospital with no ventilator.
  (Cape Town paediatric series: respiratory depression drove 65.5% of PICU
  admissions after phenobarbital.)
- **Missing from our page either way:** the repeat pathway — **further 10 mg/kg
  doses to a cumulative maximum of 40 mg/kg** (WHO pp.49–50).
- **Maintenance:** we now print 3–5 mg/kg/day; the better-sourced range is
  **2.5–5 mg/kg/day** (WHO Annex 2 verbatim; UCG 2.5 mg/kg once–twice daily).
- **ASK OE:** for a WHO/Uganda-aligned manual, is 15 mg/kg + repeat-to-40 the
  right print, rather than a flat 20 mg/kg?

### 1.6 🔴 Paediatric diazepam maximum: 8 mg or 10 mg?
- **OE said:** 0.2 mg/kg, **max 8 mg**, per the FDA label. **APPLIED** across
  `pb_020`, `pb_042` (×2), `pb_029`.
- **Research says:** 0.2 mg/kg is right, but the cap should be **10 mg**. The
  FDA's 8 mg is an **artefact of its own fixed regimen** (0.2 mg/kg × 40 kg = 8),
  not an independently derived safety ceiling. Everyone else prints 10 mg:
  **Uganda Clinical Guidelines 2023 (0.2 mg/kg, max 10 mg)**, AES 2016, ERC 2021,
  MSF. The cap only bites above ~40 kg, i.e. adolescents.
- **Also missing:** MSF and others print **"maximum 2 doses"** before escalating
  to phenobarbital. Our pages don't say that.
- **Worth knowing — our original 0.3 mg/kg was not wrong:** WHO Pocket Book
  Annex 2 p.336 prints **"IV: 0.2–0.3 mg/kg"**, and Chart 9 p.14 prints
  0.25 mg/kg. So WHO gives a band and we had printed its top. The change to 0.2
  is still defensible (it is the bottom of WHO's band and matches UCG), but the
  framing "0.3 was an error" was too strong.
- **ASK OE:** 8 mg or 10 mg, given WHO prints a 0.2–0.3 band and UCG says 10 mg?

### 1.7 🟡 Organophosphate seizures — reduce the diazepam dose?
- Both OE and the research agree: **no**, use the same dose. Recorded here only
  because the research adds a reason to be careful in the opposite direction —
  OP-induced status becomes **benzodiazepine-refractory** as GABA-A receptors
  internalise, so **under**-dosing is the documented failure mode. The
  OP-specific caution is **airway**, not dose. No action needed; no re-query.

---

## 2. NEW CONTENT — OE's answer was truncated before it reached these

### 2.1 Methanol — full antidote/dialysis block (nothing applied yet)
Research supplied what OE's truncated reply did not:
- **Folinic acid 1 mg/kg (max 50 mg) IV q4h** in 5% dextrose over 30–60 min,
  ≥24–48 h. If unavailable, **folic acid at the same dose** PO/IV q4–6h.
  **Repeat a dose after every dialysis session** (folate is dialysed out).
- **Dialysis criteria** (any one): new visual loss · coma/fits · pH ≤7.15 or
  HCO₃ <10 · acidosis persisting despite bicarbonate + ethanol · >30 mL (or
  >1 g/kg) ingested · methanol >50 mg/dL · renal failure.
- **⚠️ Ethanol maintenance should be DOUBLED in regular drinkers** and during
  dialysis — under-dosing is called the commonest error, and regular drinkers
  are exactly who drinks bad waragi. Our printed 0.2–0.4 mL/kg/h band is correct
  but has no such flag.
- **No dialysis available:** continue ethanol **5–7 days**; bicarbonate
  mmol = 0.3 × weight × base deficit.
- **Gulu Regional Referral Hospital is itself a dialysis centre** — this turns
  "refer for dialysis" from advice into a concrete instruction.
- Fomepizole as a one-line "where available"; never together with ethanol.
- **Honest caveat from the research:** human efficacy data for folate in methanol
  poisoning are essentially absent (primate data are good). Recommended on
  plausibility/safety/cost, not on trial evidence.
- **ASK OE:** confirm the folinic/folic dose and the dialysis criteria; confirm
  the regular-drinker ethanol adjustment.

### 2.1b Dextrose — WHO's own alternative recipe is slightly wrong
Independent verification confirmed the 8:1 correction is **exactly D10.00%**, and
turned up a bonus finding: **WHO Pocket Book Chart 10 p.15 says "dilute 1 part
50% glucose to 9 parts 5% glucose"**, which computes to **9.5%**, not 10%. WHO's
*other* recipe — **1 part D50 + 4 parts sterile water = exactly 10%** — is the
clean one, and it is what **Uganda Clinical Guidelines 2023** prints ("DO NOT GIVE
UNDILUTED 50% dextrose").
Suggested: print all three exact options (1+4 water · 2+8 NS · 1+8 D5) and an
explicit warning that **1 part D50 into 4 parts D5 gives 14%** — the failure mode
is substituting D5 where the recipe says water.
Also confirmed: **5 mL/kg of D10 (= 0.5 g/kg) is the WHO figure and the modal
real-world practice** (81% of surveyed emergency physicians chose 500 mg/kg),
though the defensible range is 0.2–1 g/kg.
**No re-query needed — this is arithmetic. Listed so Grey knows the source is
imperfect here.**

### 2.2 Activated charcoal — dose and window refinement
- **Currently APPLIED:** "within 2 h of ingestion (up to 4 h for a large ingestion)".
- **Research refines this** using the Clinical Toxicology Recommendations
  Collaborative guideline 2026 (first full revision since the 1990s/2000s):
  **≤2 h strong recommendation, ≤3 h conditional, suggest against beyond 6 h.**
  The 4 h figure belongs specifically to **massive (≥30 g)** ingestion; modified-
  release paracetamol extends to 5–6 h.
- **We do not print a charcoal DOSE anywhere** — CTRC 2026 gives **50 g adult,
  1 g/kg child**.
- Two safety lines worth adding: never intubate solely to give charcoal; if not
  fully awake, do not give it.
- **ASK OE:** confirm CTRC 2026 windows and the dose.

---

## 3. RAISED BY RESEARCH, NEVER PUT TO OE

### 3.1 🔴 Folic acid + antifolate antimalarials — a real interaction
Cochrane, **February 2026** (8 trials, 3,486 participants): in people on
antifolate antimalarials, folic acid **reduced day-3 parasite clearance**
(RR 0.89) and **increased treatment failure** at days 7/14/28 (RR 2.12 / 1.97 /
1.35), all moderate certainty. **Dose-dependent** — trials using >1 mg showed
the effect; the single 400 µg trial showed little to none. Ouma's RCT: day-14
failure 13.9% placebo / 14.5% at 0.4 mg / **27.1% at 5 mg**.
Relevant because we pair iron with folate by default, and **cotrimoxazole
prophylaxis is widespread in Ugandan paediatrics — trimethoprim is an antifolate
too.** MSF is explicit that antifolate-induced anaemia is treated with *folinic*
acid, not folic acid.
**ASK OE:** should the book drop routine folate alongside iron, cap it at 400 µg,
or carry a "never 5 mg with SP or cotrimoxazole" caveat?

### 3.2 🔴 Post-discharge malaria chemoprevention (PDMC) is absent from the book
Full ACT course at discharge, 1 month and 2 months after severe anaemia.
Kwambai *NEJM* 2020 and pooled trials: **all-cause mortality −77%, readmissions
−55% at 6 months.** WHO added it to the chemoprevention recommendations in June
2022. Research argues this carries the strongest mortality evidence of anything
in the anaemia section, and it aligns the follow-up visits with the delayed-
haemolysis monitoring window.
**ASK OE:** confirm PDMC and its regimen for this setting.

### 3.3 🟡 Post-artesunate delayed haemolysis — trigger and lab panel
Currently applied: "weekly CBC plus haemolysis markers (LDH, bilirubin,
haptoglobin, reticulocytes) for 4 weeks" for all children treated for severe
malaria. Research says the interval and duration are right (WHO 4–6 weeks; CDC
4 weeks) but two things need changing: the trigger should be **"received
parenteral artesunate"**, and the four-marker panel weekly is **not obtainable at
a Ugandan district hospital** — mandating it converts a life-saving instruction
into a dead letter, when **haemoglobin plus a clinical look** is what drives the
decision to transfuse. Incidence in African children is **~23%** (Carret, *CID*
2025), not the ~5% often assumed, so restricting to hyperparasitaemia would miss
most cases. Days 14 and 21 are the high-yield visits.
**ASK OE:** confirm trigger and whether to downgrade the marker panel to
"if available".

### 3.4 🟡 Anaemia treatment threshold Hgb < 9
Below WHO's 2024 thresholds (10.5 g/dL at 6–23 months, 11.0 at 24–59 months,
11.5 at 5–11 years). Probably a deliberate rationing choice — but it is currently
an inherited number rather than a decided one.
**ASK OE / Grey:** deliberate, or should it move?

---

## 4. NEW SOURCE WORTH POINTING OE AT

**Uganda Clinical Guidelines 2023** — the national guideline for the country this
book is used in, freely downloadable, with dosing for most of what the book
covers. It is the reference that shows where this book diverges from what Ugandan
clinicians are formally taught, which matters more here than divergence from AHA
or FDA. Already the decisive source for two items above (atropine 0.05 mg/kg;
pralidoxime still carried nationally).
https://library.health.go.ug/sites/default/files/resources/Uganda%20Clinical%20Guidelines%202023.pdf

---

## 5. CORRECTIONS TO MY OWN EARLIER WORK (already applied, listed for the record)

- **Intranasal naloxone** — I printed "adults 4 mg one nostril", which assumes a
  concentrated nasal spray. The WHO EML / Uganda formulation is 400 µg in 1 mL,
  so 2 mg intranasally is 5 mL against a nasal capacity of ~1 mL per nostril.
  Not deliverable. Corrected in `6e54a47` to say so and direct to IM.
- **"The SNAP regimen"** — in the question list I called the 200/100 mg/kg
  regimen "SNAP". It is not. SNAP (Bateman, *Lancet* 2014) is a 12-hour protocol
  (100 mg/kg over 2 h then 200 mg/kg over 10 h) with ondansetron. The 200-then-100
  is the **2-bag 20-hour** regimen (Wong/Graudins, 2NAC). Do not conflate them
  when re-querying.
