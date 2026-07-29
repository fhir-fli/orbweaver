# ProtocolBook — OPEN DOSING QUESTIONS

> # 🛑 SECTIONS A–E ARE CLOSED. DO NOT PASTE THEM INTO OE AGAIN.
>
> **Verified file by file on 2026-07-28: every question in §A–§E below has been
> resolved and applied.** The quoted "current text" in those sections is from
> **2026-07-26** and was superseded by the round-2 fixes (`24fbe4d`, `18501ad`).
>
> They were pasted into OE again on 2026-07-28. OE answered them faithfully **from
> the stale quotes**, and two of its answers would have been **regressions**:
>
> - **A2 phenobarbital** — OE advised "keep 15 mg/kg". The book is at **20 mg/kg for
>   all ages** with the repeat 10 mg/kg to a cumulative max 40, gated on respiratory
>   monitoring. That gate is what reconciles WHO/UCG's 15 with the 20 standard, and
>   the load has already moved three times (20 → 15 → 20). **Do not move it a fourth.**
>   Note OE's own answer cites the FDA neonatal label, NEJM and AES — all at 20 mg/kg —
>   and then recommends 15.
> - **D2 iron** — OE advised "keep TID as printed". The book **is no longer TID**:
>   `pb_075` reads *"Children 3 mg/kg ONCE daily"*, *"Adults 65 mg ONCE daily"* and
>   *"Do not split into three daily doses"*. Reverting would contradict the AAP report
>   OE itself cites.
>
> **Everything else in §A–§E was confirmed correct as already applied** — diazepam
> (0.2 mg/kg max 10 mg in all four places), epinephrine 1 mg ceiling, the 8+1 D10
> recipe, methanol folic acid + dialysis, atropine 0.02, naloxone IM/intranasal/
> infusion (already present near-verbatim), the charcoal 2 h/4 h window, 2-bag NAC for
> all weights, the flumazenil contraindication box, all of §C, and iron-after-the-
> antimalarial-course.
>
> **Only two genuinely new things came out of §A–§E**, both minor and recorded in §I of
> the tracker: extra haemodialysis criteria for methanol (anion gap >24 mmol/L, renal
> impairment, persistent acidosis despite antidote), and the FDA's note that there are
> insufficient data for the 2-bag NAC regimen at ≤40 kg — which we already handle by
> scaling the diluent.
>
> **Live questions start at §F.**

---

Every dosing question still unresolved after audit batches 1–3 (2026-07-26).
Each entry gives the **verbatim current text**, the question, and the candidate
alternative. Setting throughout: **district hospital, Gulu, northern Uganda —
low-resource, paediatric-heavy, malaria-endemic.** Answers should assume drug
availability is limited and prefer regimens deliverable there.

Status key: 🔴 = a dose is possibly wrong · 🟡 = a dose is defensible but dated
or inconsistent · ⚪ = a gap (no dose printed where one is needed)

---

## A. Anticonvulsants & resuscitation drugs

### A1 🟡 Paediatric IV diazepam — 0.3 or 0.2 mg/kg? (and the book contradicts itself)
- **p.20 Resuscitation Medications:** "Diazepam IV — 0.3 mg/kg IV slowly over 1 minute"
- **p.42 Paediatric Convulsions** (×2): "Diazepam 0.3mg/kg IV slowly over 1min"
- **p.29 Organophosphate:** "Or IV diazepam 0.2 mg/kg (children)"

**Q:** For a child in status epilepticus in this setting, is the correct initial IV
diazepam dose **0.2 mg/kg (max 8 mg)** per the FDA label, or **0.3 mg/kg** as used by
WHO and several LMIC references? Is there a maximum single dose we should print?
And should the organophosphate page use the same dose as the convulsion pages, or is
a lower dose deliberate there (patients already receiving large escalating atropine
doses)?

**Why it matters:** whichever answer is right, the book currently says both. Changing
to 0.2 means editing 3 places; keeping 0.3 means fixing p.29.
*(Adults are internally consistent at 0.15 mg/kg — p.20 and p.101 — and appear fine.)*

### A2 🟡 Phenobarbital / phenobarbitone loading dose in NON-neonates
- **p.20:** "**Load** 15 mg/kg (20 mg/kg neonates) IM/IV over 20 min · **Maint** 5 mg/kg IM/IV/PO OD"
- **p.42** gives neonates 20 mg/kg stat (agrees) + "a further 5–10 mg/kg within 24 hrs".

**Q:** Should the non-neonatal paediatric loading dose be **20 mg/kg** rather than
15 mg/kg? Most paediatric references use 20 mg/kg for all children, not only neonates.
Is a maintenance of **5 mg/kg/day** correct, or should it be **3–5 mg/kg/day** (the
FDA-approved neonatal maintenance is 4.5 mg/kg/day)?

### A3 ⚪ Paediatric epinephrine ceiling — confirm the value I added
- **p.13 and p.20 now read:** "0.1 ml/kg 1:10,000, **max 10 ml (= 1 mg)**"

**Q:** Confirm **1 mg** is the correct maximum single IV/IO dose of epinephrine for a
child in cardiac arrest (i.e. the point at which a large child gets the adult dose).

### A4 🔴 D10% mixing recipe — verify my arithmetic, since I departed from OE
- **p.20 previously:** "mix 8 ml NS with 2 ml D50%, **or 4 ml D5% with 1 ml D50%**"
- **now:** "mix 8 ml NS with 2 ml D50%, **or 8 ml D5% with 1 ml D50%**"

The printed alternative was **D14%**, not D10%. OE proposed 9 ml D5% + 1 ml D50%
(= D9.5%, "close enough"); solving `(500x+50y)/(x+y)=100` gives `y=8x`, so
**8 ml D5% + 1 ml D50% = 900 mg in 9 ml = exactly D10.00%**.

| recipe | dextrose | volume | result |
|---|---|---|---|
| 8 ml NS + 2 ml D50% | 1000 mg | 10 ml | **D10.00%** ✓ printed primary |
| 4 ml D5% + 1 ml D50% | 700 mg | 5 ml | **D14.00%** ✗ printed alternative |
| 9 ml D5% + 1 ml D50% | 950 mg | 10 ml | D9.50% (OE's suggestion) |
| 8 ml D5% + 1 ml D50% | 900 mg | 9 ml | **D10.00%** ✓ applied |

**Q:** Sanity-check the arithmetic and confirm 8+1 is what should be printed.

---

## B. Toxicology

### B1 ⚪ Methanol — folinic acid dose, and haemodialysis criteria
- **p.28 currently gives only:** oral ethanol by NGT, 1.8 ml/kg of 43% ethanol, then
  0.2–0.4 ml/kg/hour. *(The ethanol dosing itself checks out: ≈0.61 g/kg load,
  ≈0.07–0.14 g/kg/hr maintenance.)*

**Q:** What **folinic acid (or folic acid)** dose and interval should be added for
methanol poisoning? And what are the **haemodialysis indications** worth printing
(visual symptoms / acidosis threshold / methanol level), given dialysis is the
definitive treatment and is currently not mentioned at all? Should **fomepizole**
appear as "where available", or is ethanol-only correct for this setting?

### B2 🟡 Organophosphate — paediatric atropine starting dose, and pralidoxime
- **p.29:** "Children: 0.02 mg/kg IV · Adults: 2 mg IV · **Double the previous dose and
  repeat every 5 minutes** until atropinisation"
- No oxime anywhere on the page.

**Q:** Is the paediatric atropine bolus **0.02 mg/kg** (WHO) or **0.05 mg/kg** (several
current toxicology references)? Is there a minimum dose (e.g. 0.1 mg) worth printing?
Separately: should **pralidoxime / 2-PAM** be added as "where available", and at what
dose (commonly 30 mg/kg loading over 30 min, then 8 mg/kg/hr)? The evidence is
contested — the Cochrane review and Eddleston's Sri Lanka trial found no benefit.

*(The maintenance infusion — total bolus load into 250 ml at 50 ml/hr under 25 kg,
500 ml at 100 ml/hr over 25 kg = 20%/hr — was verified correct. No question there.)*

### B3 ⚪ Naloxone — non-IV route and infusion
- **p.31:** children <5 y / <20 kg 0.1 mg/kg IV; >5 y / >20 kg 2 mg IV; adults 0.4 mg IV;
  repeat q2–3 min; may need repeating at 20–60 min. **IV only; no infusion guidance.**

**Q:** What **IM or intranasal** doses should be printed for when there is no IV?
And what **continuous infusion** rate for a long-acting opioid — is the usual
"two-thirds of the effective bolus per hour" the right thing to print?

### B4 ⚪ Paracetamol — charcoal time window, and 2-bag vs 3-bag NAC
- **p.33 charcoal box:** "In children, may consider activated charcoal, if KNOWN
  ingestion of >150mg/kg" — **no time limit stated.**
- **p.33 NAC table:** 3-bag 21-hour regimen, 150 / 50 / 100 mg/kg.

**Q1:** What time window should be printed for activated charcoal (≤1 h? ≤2 h? up to
4 h for paracetamol specifically)?
**Q2:** Should we move to the **2-bag regimen (200 mg/kg over 4 h, then 100 mg/kg over
16 h)** per SNAP, which has markedly fewer anaphylactoid reactions, or keep 3-bag?

### B5 🟡 Flumazenil — contraindications (not a dose change)
- **p.31:** "Flumazenil (if respiratory depression) — Children 0.01 mg/kg IV; Adults
  0.2 mg IV, may repeat for effect (max 1 mg), max 3 mg/hour"

**Q:** The doses are correct, but should the page carry an explicit
**contraindication line** — avoid in undifferentiated overdose, tricyclic
co-ingestion, chronic benzodiazepine use, or seizure history? As drawn, the algorithm
routes every "more likely benzodiazepine" patient to flumazenil.

---

## C. Anaphylaxis, bites & envenomation

### C1 🔴 Famotidine substitute dose — I chose this, it needs confirming
- **p.37 now reads:** "H2 receptor blocker: **Famotidine 0.25mg/kg IV (max 20mg) or
  0.5mg/kg PO (max 40mg)**"
- It previously read: "Ranitidine 1mg/kg IM/slow IV (max 50mg) or 4mg/kg PO (max 150mg)"

Ranitidine was withdrawn worldwide in April 2020 (NDMA), so the substitution had to
happen — but **the replacement dose is mine, not OE's.**

**Q:** Confirm or correct the famotidine paediatric and adult anaphylaxis dosing,
IV and PO.

### C2 ⚪ Anaphylaxis observation period
- **p.37 has no observation period and no biphasic-reaction warning anywhere.**

**Q:** What observation duration should be printed after anaphylaxis treated with
epinephrine — 4 h? 6 h? longer if severe or if repeat epinephrine was needed?

### C3 ⚪ Bite prophylaxis for the penicillin-allergic patient
- **p.38:** "**Amoxicillin-Clavulanate x 5 days** — Pediatric 25mg/kg/dose PO BD ·
  Adult 1 gram PO BD. **Alternative:** Ciprofloxacin, Azithromycin or Doxycycline"

The alternatives are listed as monotherapy and none reliably covers oral anaerobes.

**Q:** What alternative regimen and **doses** should be printed — doxycycline +
metronidazole? trimethoprim-sulfamethoxazole + metronidazole? a fluoroquinolone +
clindamycin? Please give the metronidazole paediatric and adult doses to print.

### C4 🟡 Rabies immunoglobulin — WHO 2018 changed the administration
- **p.38:** "Human Ig 20 units/kg OR Equine Ig 40 units/kg, total dose given once.
  Inject as much as possible around the wound, **give the rest IM.**"

**Q:** Confirm WHO now advises infiltrating **all** of the immunoglobulin into and
around the wound, with **no** distant intramuscular remainder. Doses (20 / 40 IU/kg)
unchanged?

### C5 ⚪ Snakebite — tetanus prophylaxis and the anticholinesterase trial
- **pp.39–40** carry no tetanus prophylaxis, and the neurotoxic arm has no
  neostigmine/edrophonium trial.

**Q1:** Should tetanus toxoid be added, and with what timing relative to coagulopathy?
**Q2:** For post-synaptic (cobra-type) neurotoxic envenoming, what
**neostigmine + atropine** trial doses should be printed, paediatric and adult?

---

## D. Malaria & anaemia

### D1 🟡 Iron in acute malaria — timing and duration
- **p.23:** "**Anemia:** if Hgb < 9, start on **iron + folic acid × 14 days** initially"

**Q:** Should iron be **deferred until after the acute episode** in a malaria-endemic
setting, and should the course be **~3 months** rather than 14 days? Please address
both the timing (safety of iron during acute infection) and the duration separately.

### D2 🟡 Iron supplementation dosing — divided vs once daily
- **p.75:** "Children: 1–2 mg/kg/dose PO q8h · Adults: 50 mg/dose PO q8h of elemental iron"

OE previously judged the TID regimen acceptable and possibly preferable here (where
only small-volume ferrous sulfate drops may be stocked), noting the 2026 AAP report
now favours **3 mg/kg once daily** and that lower once-daily adult dosing has fewer
side effects.

**Q:** Confirm whether to keep TID or move to once-daily, given the stocking argument.

---

## E. Not dosing, but open and worth asking alongside

- **E1 — p.13 PALS:** "If no improvement after 15 minutes, consider stopping."
  Is 15 minutes too short a termination threshold? (AHA sets no fixed limit;
  meaningful survival falls off after 20–30 min.) Policy decision, not a dose.
- **E2 — p.14 Adult Cardiac Arrest:** hypoglycaemia leads our H's list. It was dropped
  from the AHA H's and T's after 2005. Keep as a deliberate LMIC addition?
- **E3 — p.21 IO line:** we print a strict 90° insertion angle; classic manual-needle
  teaching is 60–90° angled away from the growth plate. Judged acceptable — confirm.

---

# F. RE-ASK LIST — what the 2026-07-28 OE round did NOT answer

> ## STATUS after the second OE pass (2026-07-28)
> **9 of 11 answered and applied** — F1 ReSoMal · F2 digoxin · F3 eye care ·
> F4 the 24-hour fast · F5 kwashiorkor skin · F6 Xpert · F7 female source case ·
> F10 crossover age (**5 years**) · F11 MUAC (**MAM ≥18.5**, confirming the inference
> that the boundary rule holds in every row).
>
> 🔴 **F8 and F9 are STILL OPEN — and F8 has now truncated in the same place three
> times.** Both answers stop exactly at the figure:
> - **F8** — *"The target for exchange transfusion in acute sickle stroke is HbS"* →
>   citation. The summary table row is also blank.
> - **F9** — *"A low reticulocyte count ("* → citation. No prose section at all in the
>   second pass.
>
> **When re-asking, ask for the two numbers on their own, outside any prose** — e.g.
> *"Give only: (1) the HbS percentage target for exchange transfusion in acute sickle
> stroke, and (2) the reticulocyte count or percentage that defines aplastic crisis in
> sickle cell disease. Numbers only."* Something in the surrounding sentence structure
> is being lost each time.

The pp.59–73 review (sections E–H of `protocolbook_needs_oe_rereview.md`) came back
thorough on 33 of 39 flags. **These 11 are still open.** Seven got no answer at all;
three had an answer that was cut off exactly where the number should have been; one
was confirmed as an error without saying which way to fix it.

**Paste this block alongside the relevant page.** Same setting as above: district
hospital, Gulu, northern Uganda.

## F1 ⚪ NOT ANSWERED — ReSoMal in cholera or profuse watery diarrhoea (p.64)
Our p.64 gives ReSoMal unconditionally: 5 mL/kg PO q30min × 2 h, then 5–10 mL/kg/h
alternating hourly with F-75 × 10 h.

WHO ch.7 and UCG both carve out the same exception in near-identical words — use
**standard ORS, not ReSoMal, if the child has cholera or profuse watery diarrhoea**,
because ReSoMal is deliberately low-sodium.

**Q:** Should that exception be printed, and in what words? WHO also gives a hard stop
rule we do not carry — *stop ReSoMal immediately if respiratory rate rises by 5/min
and pulse by 25/min*. Should that replace our softer "monitor for improvement or
over hydration"?

## F2 ⚪ NOT ANSWERED — the orphan digoxin line in SAM cardiac failure (p.65)
p.65 item 6 reads: Oxygen · Stop all IV fluids & feeds · Lasix 1 mg/kg IV ·
**"Do not use digoxin in newborns."**

Digoxin appears nowhere else in the block, nowhere else in the topic, and **WHO's SAM
chapter never mentions digoxin at all.** So the page warns against a treatment it
never offers, and implies digoxin *is* appropriate in non-newborns without ever
dosing it.

**Q:** Delete the line, or restore digoxin properly as an option with a dose? If it
stays, what dose in SAM specifically — where myocardial mass is reduced and
electrolytes are deranged?

## F3 ⚪ NOT ANSWERED — SAM eye care is missing the part that saves the eye (p.65)
p.65 item 7 gives only: *"Vitamin A on day 1, 2 and 15 · 1% atropine to relax the eye ·
Gentamycin or chloramphenical eyedrops"* — no frequencies, no durations.

WHO §7.5.1 gives four things explicitly *"to prevent corneal rupture and extrusion of
the lens"*: chloramphenicol **or tetracycline** drops **4×/day for 7–10 days**;
atropine **one drop three times a day for 3–5 days**; **cover with saline-soaked eye
pads**; and **bandage the eye(s)**.

**Q:** Confirm the drop frequencies and durations to print. Should **gentamicin** drops
be replaced by tetracycline/chloramphenicol as WHO specifies? And should the
**saline pad and bandage** be added — they need no supply chain and are the mechanical
step that stops the globe perforating.

## F4 ⚪ NOT ANSWERED — "stop all oral feeds and IV fluids for 24 hours" (p.64 item 5a)
Our severe-anaemia block opens by withholding all feeds and IV fluids for a full day.
WHO has no such instruction — it says only that transfusion should be given *in the
first 24 h* if criteria are met, which looks like the likely origin of the sentence.

**Q:** Is a 24-hour fast correct in a SAM child whose item-1 problem on the same page
is hypoglycaemia? Or should feeds be withheld only **during** the transfusion?

## F5 ⚪ NOT ANSWERED — kwashiorkor skin lesions (p.65 item 8)
We print only 0.01% potassium permanganate or gentian violet. WHO §7.5.3 adds **zinc**
(deficiency is usual in kwashiorkor and the skin responds quickly), a **barrier cream**
(zinc and castor oil ointment, petroleum jelly or tulle gras) to raw areas, and
**avoiding nappies so the perineum stays dry**.

**Q:** Item 10 says micronutrients are already in F-75/F-100 — does that cover the
zinc, or is additional zinc needed for kwashiorkor dermatosis specifically? Should the
barrier cream and nappy advice be added?

## F6 ⚪ NOT ANSWERED — Xpert MTB/RIF for children (p.71)
p.71's diagnosis section offers **gastric aspirate ×3 only**. Xpert appears nowhere in
the paediatric TB group — but **p.128 (adult TB) says "If available, perform Gene Xpert
on 1 sputum sample."** So we route adults to the WHO-recommended initial test and
children to a 1950s technique.

**Q:** Should Xpert MTB/RIF Ultra be added to the paediatric pathway — and specifically
**stool Xpert**, which is WHO-endorsed in young children and removes the need for
gastric aspirate in exactly the under-5s p.71 says cannot expectorate? What specimen
priority should we print where Xpert is available?

## F7 ⚪ NOT ANSWERED — "Source case is female" +1 (p.72, 8-point risk score)
The 8-point contact score awards a point for the source case being female. We
transcribed it verbatim.

**Q:** Is this reproducing a study-population caregiving artefact rather than a
generalisable risk factor? Should a one-line note say so, as the same table already
does for "high incidence area"?

## F8 🔴 ANSWER CUT OFF — the HbS target in sickle stroke (p.61)
The reply read *"the goal is to lower HbS to"* and stopped at the citation marker.

**Q:** State the **HbS percentage target** for exchange transfusion in acute sickle
stroke, and confirm the **simple-transfusion Hb ceiling** (we understood ~10 g/dL, and
that exceeding it risks extending the infarct through hyperviscosity).

## F9 🔴 ANSWER CUT OFF — the reticulocyte threshold for aplastic crisis (p.60)
The reply began *"A low reticulocyte count ("* and stopped at the number.

**Q:** What **reticulocyte count or percentage** should define aplastic crisis on the
p.60 cascade, so the arm can be written? We already draw a retic count in initial
management and currently never use it.

## F10 🔴 ANSWER CUT OFF — the WFH-vs-BMI crossover age (p.63)
The reply was garbled mid-sentence.

**Q:** Our prose says *"Use WFL/WFH if <6 years (59 months)"* and *"Use BMI/age if
≥6 years"* — but 59 months is under **5** years, and the table below it uses
"6 to 59 months" and "5 to 19 years". Confirm both prose lines should read **5 years**.

## F11 🟡 CONFIRMED AS AN ERROR, BUT NOT WHICH WAY (p.63)
The reply agreed the adolescent MUAC row is a source-document error, but did not say
which bound is wrong.

As printed, **15 to 19 years: MAM ≥16.5 & <21.0 cm · SAM <18.5 cm** — these overlap,
so 17.0 cm is both. Every other row has MAM's lower bound equal to SAM's upper bound
(13.5/13.5, 16.0/16.0).

**Q:** Which single number should change — **MAM's "≥16.5" → "≥18.5"** (making the SAM
series 13.5 → 16.0 → 18.5, and restoring the boundary rule), or **SAM's "<18.5" →
"<16.5"**? If neither, what are the correct 15–19-year MUAC cut-offs to print?

---

# G. OPEN QUESTIONS, WRITTEN OUT IN FULL (2026-07-29)

**Standing format from here on.** Every question below is self-contained: it quotes the
**verbatim current text** of the page, states the concern, and asks a specific
question. OE cannot see the repository, so nothing here refers to a file, a section
letter, or a previous conversation. Paste any block on its own.

Setting for all of them: **district hospital, Gulu, northern Uganda — low-resource,
paediatric-heavy, malaria-endemic. Assume limited drug availability and prefer regimens
deliverable there.**

---

## G1 🔴 Neonatal pain scale — is this the NIPS, and if not, what should it be called?

Our neonatal pain page is headed **"Neonatal Infant Pain Score (NIPS) — < 1 year old"**
and scores **eight** variables:

| Variable | Options (points) |
|---|---|
| Facial expression | Relaxed 0 · Grimace 1 |
| Cry | No cry 0 · Whimper 1 · Vigorous crying 2 |
| Breathing pattern | Relaxed 0 · Change in breathing 1 |
| Arms | Relaxed 0 · Flexed/extended 1 |
| Legs | Relaxed 0 · Flexed/extended 1 |
| State of arousal | Sleeping/awake 0 · Fussy 1 |
| **Heart rate** | Within 10% of baseline 0 · 11–20% 1 · >20% 2 |
| **O₂ saturation** | No additional O₂ needed 0 · Additional O₂ required 1 |

Maximum total **10**. The page then bands it: **0–3 mild · 4–6 moderate · 7–10 severe**.

The validated NIPS (Lawrence 1993) has **six** items — the first six above — with a
maximum of **7**, and the usual treatment threshold is **>3**. Our last two items,
heart rate and oxygen saturation, are not part of it; they belong to scales such as
PIPP/PIPP-R.

**Q1.** Is the eight-item version above a recognised published variant of the NIPS, or
is it a local composite? If it is a variant, what is its name and source?

**Q2.** For a district hospital in northern Uganda, which is better: (a) revert to the
six-item NIPS with a maximum of 7 and re-band the tiers, or (b) keep the eight items
and rename the tool so it is not confused with the validated NIPS?

**Q3.** If we revert to the six-item scale, give the exact tier bands to print for
mild / moderate / severe on a 0–7 scale, and confirm the threshold at which analgesia
should be given.

**Q4.** If we keep heart rate and oxygen saturation, does that change the score at
which analgesia should start, given the two extra points are physiological rather than
behavioural and can be driven by non-pain causes?

---

## G2 🟡 Anaemia — are our transfusion thresholds right for a malaria-endemic district hospital?

Our page prints this table verbatim:

| Setting | Transfuse if haemoglobin |
|---|---|
| **High malaria areas** — low blood supply | <4 g/dL, or <5 g/dL and unstable |
| **High malaria areas** — good blood supply | <5 g/dL |
| **Low malaria areas** | <7 g/dL, or <10 g/dL and unstable |

**Q1.** Are these the correct cut-offs to print for a high-malaria-transmission district
hospital, or should any of the four numbers move?

**Q2.** "Unstable" is not defined anywhere on the page. What should it mean here —
which specific findings should trigger transfusion at the higher haemoglobin?

**Q3.** Should the high-malaria thresholds differ for a child with **severe acute
malnutrition**, who is separately covered on another page at Hb <4, or Hb 4–6 with
respiratory distress?

---

## G3 🟡 Anaemia — is an SpO₂ threshold of 94% the right oxygen trigger in severe anaemia?

Our anaemia page prints, in its management list:

> Check vital signs (BP, PR, RR, **SpO₂**, Temp, Weight)
> Insert 2 IVs; **start oxygen if SpO₂ < 94%**

**Q1.** Is "start oxygen if SpO₂ <94%" the right trigger in **severe anaemia
specifically**? Pulse oximetry measures saturation of the haemoglobin present, so a
child with Hb 3 g/dL can read 99% while being profoundly oxygen-deficient in terms of
delivery.

**Q2.** Should the page warn that a normal SpO₂ does **not** exclude critical anaemia,
and should oxygen be given on clinical grounds (respiratory distress, altered
consciousness, shock) regardless of the saturation reading?

---

## G4 🟡 Anaemia — is a single Fe:TIBC cut-off of 18% safe to print?

Our iron studies table prints:

| | Fe | TIBC | Ferritin | Fe : TIBC |
|---|---|---|---|---|
| Iron deficiency | ↓ | ↑ | ↓ | **<18%** |
| Anaemia of chronic inflammation | ↓ | nL | ↑ | **>18%** |

**Q1.** Is a single **18%** transferrin-saturation cut-off adequate to separate iron
deficiency from anaemia of chronic inflammation, or does it need a caveat?

**Q2.** In a setting with **very high rates of malaria, HIV and chronic infection**,
where ferritin is an acute-phase reactant and will be raised by inflammation
regardless of iron status, what is the most reliable practical way to identify iron
deficiency? Should we print a raised ferritin cut-off in the presence of
inflammation, or add CRP?

**Q3.** Given iron studies are often unavailable at district level, is there a
defensible way to decide on iron treatment without them?

---

## G5 🔴 Epinephrine concentration — we need the warning text

Our anaphylaxis page gives, in a box:

> Epinephrine (1mg/1ml **1:1000**) · 0.01 mL/kg (max dose 0.3 mL) · IM anterolateral
> thigh · Repeat q5–15 minutes if no improvement

Elsewhere the same book uses **1:10,000** for cardiac arrest — "Epinephrine 0.1 mL/kg
1:10,000, max 10 mL (= 1 mg), mix 1 mL of 1:1,000 in 9 mL normal saline".

So both concentrations appear in one pocket book, for different emergencies, by
different routes.

**Q1.** What warning should be printed alongside the anaphylaxis dose to prevent the
1:1000 / 1:10,000 mix-up? Please give the exact wording you would print.

**Q2.** Should the same warning appear on the cardiac-arrest pages as well, or only
next to the IM anaphylaxis dose?

**Q3.** Is there a formulation or labelling convention (e.g. writing "1 mg/mL" and
"0.1 mg/mL" instead of ratios) that is safer to print in a setting where both ampoule
types may be on the same trolley?

---

## G6 🔴 Esmolol in hypertensive emergency — we need the full dose

Our hypertensive-emergency box currently lists three agents:

> 1. Nicardipine: initial 5 mg/H, increase 2.5 mg/hr q5min to max of 15 mg/H
> 2. Sodium nitroprusside: 0.3–0.5 mcg/kg/min, increase 0.5 mcg/kg/minute every few
>    minutes to max 10 mcg/kg/min
> 3. Labetalol: 10–20 mg IV, then bolus of 20–80 mg q10min until BP at target or
>    300 mg total dose

A fourth agent was intended — the source reads **"4. Esmolol: 500 mcg/kg/minute over 1"**
and stops mid-sentence.

**Q1.** Give the complete esmolol regimen for hypertensive emergency in an adult:
loading dose, infusion rate, titration steps and maximum.

**Q2.** In a district hospital without an infusion pump or arterial line, is esmolol
appropriate to list at all, or should it be marked "where an infusion pump is
available"?

**Q3.** Of these four agents, which should be **first-line** in a setting where
nicardipine and nitroprusside are frequently out of stock?

---

## G7 🟡 Sickle cell splenic sequestration — what is the third management point?

Our splenic sequestration box reads:

> **Splenic sequestration** (sudden splenic enlargement with a drop in Hb >2 g/dL from
> baseline, usually with abdominal pain, under 5 years)
> a. Hgb may continue to drop, monitor carefully
> b. May require more aggressive transfusions than normal crisis
> c. *(the source begins "Otherwise treat" and stops)*

**Q1.** What should the third point say? Is the intended meaning "otherwise treat as a
normal vaso-occlusive crisis"?

**Q2.** What else belongs in an acute splenic sequestration box for a district
hospital — in particular, transfusion volume (given the risk of autotransfusion and
hyperviscosity as the spleen releases sequestered cells), and what to tell the family
about recurrence and splenectomy?

---

## Answering format — please note
Several previous replies were **cut off exactly at the number** (an HbS target, a
reticulocyte threshold, an age cut-off). Where a question asks for a figure, please
give the figure as a plain standalone line — for example "HbS target: 15–20%" — rather
than inside a sentence.

---

# H. STILL OPEN AFTER THE 2026-07-29 ROUND

## H1 🔴 NAC — the two OE rounds contradict each other, and we have already applied one

**Round 1 (2026-07-28):** *"2-bag for ALL weights, diluent scaled 7 mL/kg → 14 mL/kg,
D5W in children."* **We applied exactly that**, and our page now reads:

> **N-acetylcysteine (NAC) — 2-bag regimen, ALL weights**
> Child ≤40 kg: 200 mg/kg in **7 mL/kg** diluent (max 500 mL), then 100 mg/kg in
> **14 mL/kg** diluent (max 1 L)
> \>40 kg: 200 mg/kg (max 22 g) in 500 mL diluent, then 100 mg/kg (max 11 g) in 1 L

**Round 2 (2026-07-29):** *"Move to the 2-bag regimen for patients >40 kg. **Keep the
3-bag regimen for patients ≤40 kg** per the FDA label"* — citing the label's
"insufficient data to recommend the two-bag regimen in patients ≤40 kg."

**Nothing changed between the two rounds except the question wording. We have not
changed the page — it still says 2-bag for all weights.**

**Q1.** Which is right for a paediatric-heavy district hospital: 2-bag for everyone
with the diluent scaled to weight, or 2-bag only above 40 kg and 3-bag below?

**Q2.** The FDA's caution says "insufficient data", not "evidence of harm". Is there
any actual signal of worse outcomes with 2-bag in children, or is this an absence of
paediatric trials?

**Q3.** Which consideration should win here: fewer bag changes and fewer anaphylactoid
reactions (favouring 2-bag for all, and fewer medication errors in a busy ward with
one nurse), or label conformity (favouring 3-bag under 40 kg)?

Please answer with a single recommendation for what to print.

## H2 ⚪ NOT ANSWERED — the SpO₂ trigger in severe anaemia

This was asked as G3 and the reply did not reach it. Restating it alone:

Our anaemia page prints, in its management list:

> Check vital signs (BP, PR, RR, **SpO₂**, Temp, Weight)
> Insert 2 IVs; **start oxygen if SpO₂ < 94%**

**Q1.** Is "start oxygen if SpO₂ <94%" the right trigger in **severe anaemia
specifically**? Pulse oximetry reports the saturation of the haemoglobin that is
present, so a child with Hb 3 g/dL can read 99% while being profoundly deficient in
oxygen *delivery*.

**Q2.** Should the page state that a normal SpO₂ does **not** exclude critical anaemia,
and that oxygen should be given on clinical grounds — respiratory distress, altered
consciousness, shock — regardless of the reading?

Please answer these two points only.

## H3 🟡 Pralidoxime — a dose was offered; confirm before we print it

Our organophosphate page currently carries a footnote saying UCG includes pralidoxime
and the evidence is uncertain, but **prints no dose**. The suggested line was:

> Pralidoxime (where available): 25–50 mg/kg IV over 30 min, then 10–20 mg/kg/hr;
> evidence of benefit is uncertain.

**Q.** Confirm those figures, including the adult dose and any maximum, and confirm
this is worth printing at all for a hospital where pralidoxime is very unlikely to be
stocked.
