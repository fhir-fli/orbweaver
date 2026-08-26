# ProtocolBook advance pass — pp.114–142 (the ECG / internal-medicine tail)

**Status: PART 1 of 2.** Flags raised 2026-08-25 on the pages OE has not yet reached (the
applied rounds stop at p.113).

**Covered so far — 7 of the 19 topics in this range**, chosen drug-first because that is
where a wrong number does damage: electrolytes (pp.140–143), ACS treatment (pp.123–124),
pulmonary embolism (p.131), adult TB (pp.128–129), STIs (pp.132–134), HIV opportunistic
infections (pp.135–139), SVT (p.125).

**Still to review:** the five ECG pages (pp.114–120), chest pain / ACS diagnosis (p.121),
epigastric pain, headache and syncope (p.126), COPD & asthma (p.127), and DVT (p.130).

**Every flag below was checked against the printed PDF page**, so each is a question about
the book's content rather than about how it was transcribed. Where the print's layout
mattered — the SVT branch labels — I looked at the rendered page, not the extracted text.

**How to use this file:** every numbered item below is **self-contained** — it quotes the
verbatim printed text, states the concern, and asks something specific. Paste an item
straight into OpenEvidence. Nothing refers to a file, a page of this repo, or a previous
conversation, because OE cannot see any of it.

**Setting to state to OE:** *district hospital, Gulu, northern Uganda — low-resource,
paediatric-heavy, malaria-endemic. Limited drug availability; no reliable dialysis; ICU
monitoring is not routinely available.*

**Ask for every figure as a standalone line** — replies keep getting cut off at the number.

Each item is marked 🔴 (patient-safety), 🟡 (correctness / clarity) or 🟢 (nice to have).

---

# A. ELECTROLYTES (pp.140–143)

## A1 🔴 Severe hyperkalemia is given nothing that actually lowers the potassium

**Verbatim, as printed.** The hyperkalemia algorithm asks *"Any of the following? 1. K+ >
6.5  2. Weakness, frank muscle paralysis, palpitations, paraesthesia  3. ECG changes —
tall tented T-waves, PR prolongation, AV-block, widening QRS (may eventually begin to
merge with T-wave)"*. On **Yes**, the treatments listed are:

- *"Cardiac monitoring"*
- *"10% Calcium Gluconate IV — Children 0.5mL/kg; Adults 10mL; give over 2-3 minutes;
  repeat every 5min until ECG improves; lasts 30-60 min"*
- *"Furosemide IV — Children: 1mg/kg; Adults: 20-40mg"*
- *"Dialysis: Urgently if unstable, consider for asymptomatic patients with ESRD"*

The potassium-**shifting** treatments — *"Insulin/glucose — Adults: IV bolus Insulin 10IU
+ Glucose 40-60g; Children: Insulin IV 0.05 IU/kg/hr + Glucose IV 0.5g/kg/hr for RBS <
180"* and *"Salbutamol q1-2hr"* — are placed on the **other** branch, the one reached only
when the answer is No and *"K+ = 6.5-6"*.

**The concern.** As written, the sickest patients — K above 6.5, or with ECG changes —
receive calcium (which stabilises the myocardium for 30–60 minutes but does not lower
serum potassium at all) plus a loop diuretic, and are then sent to dialysis. Patients with
*milder* hyperkalemia are the ones who get insulin/glucose and salbutamol. Where dialysis
is not available the same day, the severe patient's potassium is never actively lowered.

**Questions.**
1. In severe hyperkalemia (K > 6.5, or any ECG change), should insulin/glucose and
   nebulised salbutamol be given **alongside** calcium, rather than being reserved for
   the 6.0–6.5 band? Please answer yes or no on its own line.
2. What is the correct **order and timing** of calcium, insulin/glucose, salbutamol and a
   loop diuretic in severe hyperkalemia at a hospital where dialysis may be a day away?
3. How long does the potassium-lowering effect of insulin/glucose and of salbutamol last,
   and how often should each be repeated?
4. After insulin/glucose, for how many hours must blood glucose be monitored, and at what
   interval? Give the duration as a standalone line.

## A2 🔴 The dopamine dose is missing its "/kg" — the book contradicts itself four ways

**Verbatim, as printed** (hyponatremia emergent management, in the branch for a patient
who is hypotensive **and** volume overloaded): *"Dopamine 2-5mcg/min"*.

**The concern.** Every other dopamine dose in this same book is written per kilogram —
*"Consider Dopamine 5–20mcg/kg per minute, titrate to effect"* (paediatric heart failure),
*"dopamine 5–20 mcg/kg/min"* (adult sepsis), *"dopamine 3–10 mcg/kg/min"* (adult heart
failure). A flat 2–5 mcg/min in an adult is roughly a hundredth of a haemodynamically
active dose and would do nothing for a hypotensive patient.

Separately, even read as 2–5 mcg/**kg**/min, that is the old "renal-dose" range, which is
not a pressor dose.

**Questions.**
1. Is *"Dopamine 2-5mcg/min"* a typographic omission of "/kg"? Please answer yes or no on
   its own line.
2. For an adult who is **hypotensive and volume-overloaded** with acute hyponatremia, what
   is the correct vasopressor or inotrope and its dose range in mcg/kg/min? Give the dose
   as a standalone line.
3. Is dopamine the right choice here at all, or should this be an inotrope
   (e.g. dobutamine) or norepinephrine? This book already prefers norepinephrine over
   dopamine elsewhere, noting "markedly more arrhythmia and higher mortality" with
   dopamine — should that preference apply here too?

## A3 🟡 The sodium infusion-rate formula has no infusate term and yields implausible rates

**Verbatim, as printed** (Calculations with Sodium, item d):

> *Rate of IVF infusion to increase Na by 0.5 mEq/L/h = 1000 / (2 × [Na]serum)*

The item immediately above it is *"Change [Na]serum per L infusate = ([Na]infusate −
[Na]serum) / (TBW + 1)"*.

**The concern.** The rate formula contains no term for the infusate's sodium concentration
and no term for body water, so the same rate is produced whether one hangs 3% saline or
0.9% saline. Worked through for a patient with serum Na 120: 1000 / (2 × 120) = 4.2 — if
that is millilitres per hour, it is far too little to shift serum sodium at all.

**Questions.**
1. Is this formula a garbled or mistyped version of a standard one? If so, what is the
   correct expression, written out in full? Put the formula on its own line.
2. What are its **units** — mL/hour?
3. Given the "change per litre of infusate" formula printed directly above it, what is the
   correct way to derive an hourly infusion rate that raises serum sodium by 0.5 mEq/L/h?

## A4 🟡 Paediatric IV potassium is given an ICU-level rate with no monitoring requirement

**Verbatim, as printed.** *"IV potassium — Indications: K < 2.5, symptomatic, or a
nonfunctioning GI tract. 40 mEq in 1 L NS (children 0.5–1 mEq/kg/hr; adult 10 mEq/hr
infusion)"*, alongside a correctly-emphasised warning that IV potassium must never be
given as a bolus.

**The concern.** Two things. First, 0.5–1 mEq/kg/hr in a child is a rate normally
restricted to intensive care with continuous cardiac monitoring — this book's setting
often has neither. Second, at the stated concentration of 40 mEq/L, a 20 kg child at
1 mEq/kg/hr would need **500 mL/hour** of fluid to deliver 20 mEq, which is not
deliverable; the concentration and the rate as printed are not compatible.

**Questions.**
1. What is the maximum safe IV potassium infusion rate for a child **without** continuous
   cardiac monitoring, in mEq/kg/hr? Give it as a standalone line.
2. What is the maximum potassium **concentration** for a peripheral line, and for a
   central line, in mEq/L? Two standalone lines please.
3. What monitoring is mandatory during paediatric IV potassium replacement, and at what
   interval?

## A5 🟡 Is sodium polystyrene sulfonate ("Resonium") still recommended?

**Verbatim, as printed:** *"Resonium q6hr — PO / PR — Children 1g/kg / 1g/kg; Adults 15g /
30-50g"*, listed as a treatment for potassium in the 6.0–6.5 band.

**Question.** Is sodium polystyrene sulfonate still recommended for acute hyperkalemia, or
has it been superseded? If it is retained where newer binders are unavailable, what should
be said about onset time and about the risk of colonic injury, particularly if it is
prepared with sorbitol? Please state plainly whether it lowers potassium quickly enough to
be counted on in an acute episode.

## A6 🟢 Magnesium replacement is prescribed 6-hourly as a standing dose

**Verbatim, as printed:** *"Unstable or symptomatic & magnesium < 1: magnesium sulfate 2 g
in 50 mL 5% dextrose, given over 30 minutes, 6 hourly (children 25–50 mg/kg)"*.

**Question.** Is a standing 2 g every 6 hours (8 g/day) correct for an adult with
symptomatic hypomagnesaemia, or should repeat dosing be guided by re-measured levels and
renal function? What is the maximum daily dose, and what should be checked before each
repeat? Give the maximum as a standalone line.

---

# B. ACUTE CORONARY SYNDROME — TREATMENT (pp.123–124)

## B1 🔴 The thrombolysis window is printed as 24 hours

**Verbatim, as printed**, under STEMI treatment: *"Thrombolytics — a. Ideally within first
24 hours of chest pain. b. Patient should be connected to defibrillator if possible."*

**The concern.** This is the only timing guidance given for fibrinolysis anywhere on the
page, and read plainly it authorises lysing a STEMI up to a day after symptom onset as
routine practice. My understanding is that the mortality benefit is concentrated in the
first hours and is not established beyond about 12 hours, while the bleeding risk is
unchanged — so a late-presenting patient could be exposed to intracranial haemorrhage risk
for little or no gain. In this setting patients frequently present late, so the cut-off is
load-bearing rather than theoretical.

**Questions.**
1. What is the outer time limit, from symptom onset, beyond which fibrinolysis should
   **not** routinely be given for STEMI? Give the number of hours as a standalone line.
2. Within that limit, what is the target door-to-needle time? Standalone line please.
3. Are there circumstances in which lysis is still justified **after** that limit — for
   example ongoing ischaemic chest pain with persistent ST elevation, or haemodynamic
   instability? Please list them explicitly.
4. For a patient presenting at, say, 18 hours with resolved pain and no instability, what
   is the correct management where primary PCI is not available at all?

## B2 🔴 No age adjustment for enoxaparin or clopidogrel in older patients

**Verbatim, as printed** (identically in both the STEMI and NSTEMI sections):

> *"Enoxaparin — 30 mg IV bolus followed 15 minutes later by 1 mg/kg subcutaneously
> q12hrs (maximum 100 mg/dose for first 2 doses). Should not be given if creatinine
> clearance < 30."*
> *"Clopidogrel 300 mg PO × 1 dose."*

**The concern.** Both doses are printed as single values with no age qualifier. My
understanding is that in older patients receiving fibrinolysis, the enoxaparin IV bolus is
omitted and the subcutaneous dose is reduced, and the clopidogrel loading dose is not
given at all — because of excess intracranial haemorrhage. As printed, an 80-year-old
receives the full adult regimen. Renal function is addressed; age is not.

**Questions.**
1. At what age does the enoxaparin regimen change for a patient receiving fibrinolysis?
   Give the age as a standalone line.
2. At and above that age, state the enoxaparin regimen in full — whether the IV bolus is
   given, the subcutaneous dose in mg/kg, the frequency, and any per-dose cap. Please put
   the mg/kg figure on its own line.
3. At and above that age, what clopidogrel dose should be given with fibrinolysis — a
   300 mg load, a 75 mg dose, or none? Standalone line please.
4. Does the same age threshold apply when the patient is **not** receiving fibrinolysis
   (NSTEMI managed medically)?

## B3 🟡 The stroke exception in the contraindication list uses 3 hours

**Verbatim, as printed**, among the absolute contraindications to thrombolysis:
*"Ischaemic stroke within 3 months (EXCEPT ischaemic stroke within 3 hours)"*.

**Questions.**
1. Is the parenthetical window 3 hours or 4.5 hours? Give the figure as a standalone line.
2. This exception is easy to misread as permitting **coronary** thrombolysis in a patient
   who had a stroke a few hours ago. Please state in one sentence what the exception
   actually means, in wording that could be printed as-is in a pocket reference.

## B4 🟡 Beta blockade within 24 hours is printed with no contraindications

**Verbatim, as printed:** *"Oral Beta Blocker within first 24 hours (preferred metoprolol
succinate or carvedilol)"*, followed by five options — metoprolol succinate 25 mg daily,
carvedilol 6.25 mg BD, metoprolol tartrate 25 mg BD, labetalol 100 mg BD, atenolol 50 mg
daily.

**The concern.** No cautions are listed. Early beta blockade in a patient with signs of
heart failure, hypotension, or low cardiac output can precipitate cardiogenic shock, and
this page is otherwise careful to list contraindications (it does so at length for
thrombolytics).

**Questions.**
1. In which patients should an oral beta blocker be **withheld** in the first 24 hours
   after myocardial infarction? Please give the list explicitly.
2. Are labetalol and atenolol appropriate choices in this list, or should the options be
   restricted? If either should be dropped, say which and why.
3. What observations should be checked before each of the first doses?

---

# C. PULMONARY EMBOLISM (p.131)

## C1 🔴 PERC is used as the first gate, applied to every patient

**Verbatim, as printed.** The page opens with *"Pulmonary Embolism Rule-Out (PERC) — Does
the patient meet all of these? 1. Age < 50 years  2. Pulse < 100  3. SpO2 > 94%  4. No
unilateral leg swelling  5. No hemoptysis  6. No surgery or trauma within 4 weeks  7. No
previous DVT/PE  8. No oral hormone use"*. If **yes** → *"Do not treat for Pulmonary
Embolism"*. If **no** → evaluate for DVT, and only after that does the page reach the
Wells score.

**The concern.** As drawn, PERC is applied to everyone who walks in, and Wells comes
afterwards. My understanding is that PERC is only valid in patients whose pre-test
probability is **already low**, and that applying it to a patient the clinician thinks is
likely to have a PE can produce a falsely reassuring "rule out". The order on this page is
the reverse of that: the risk score that would establish low pre-test probability comes
after the rule that presupposes it.

**Questions.**
1. Is PERC valid as a first-line screen applied to all comers, or only after pre-test
   probability has been assessed as low? Please answer on its own line.
2. If it requires a low pre-test probability first, what should establish that — clinical
   gestalt, or a formal score such as Wells? If a score, state the threshold as a
   standalone line.
3. Please state the correct **order** of steps for a patient with suspected PE at a
   hospital with no CT pulmonary angiography, written as a sequence that could be printed
   as a flow chart.

## C2 🔴 Low-risk patients are given "no treatment" with no test in between

**Verbatim, as printed:** *"I. Score < 2: Low Risk"* with the corresponding treatment line
*"Low risk: no treatment"*.

**The concern.** No D-dimer step appears anywhere between "low risk" and "no treatment".
Where D-dimer is available, my understanding is that low-risk patients who are not PERC
negative still need it, and a positive result still requires imaging or empiric treatment.
As printed, a low-Wells patient is discharged untested.

**Questions.**
1. For a Wells-low-risk patient who is **not** PERC negative, is a D-dimer required before
   PE can be excluded? Yes or no on its own line.
2. If D-dimer is available but CT pulmonary angiography is **not**, what should be done
   with a positive D-dimer in a low-risk patient?
3. If **no** D-dimer is available either — which is common here — what is the safest
   approach for a low-risk patient? Please be concrete about whether empiric
   anticoagulation, observation, or discharge with review is preferred.

## C3 🔴 There is no pathway at all for PE with haemodynamic instability

**The concern.** I searched the entire book: **massive / high-risk PE is not covered
anywhere.** The PE page's treatment section reads, in full, *"Low risk: no treatment.
Intermediate risk: discuss with senior if treatment is appropriate. High risk: may start
empiric treatment; discuss with senior if treatment should be continued"* — where "high
risk" means a high Wells score, not shock. Nothing addresses the patient with confirmed or
strongly suspected PE who is hypotensive.

This matters here specifically because the hospital **does** stock thrombolytics — the
same book gives tenecteplase and streptokinase dosing for STEMI two pages earlier — so the
drug is on the shelf and the indication is missing.

**Questions.**
1. What defines high-risk (massive) PE for treatment purposes — please give the blood
   pressure and duration criteria as standalone lines.
2. Is systemic thrombolysis indicated for high-risk PE where catheter therapy and surgical
   embolectomy are unavailable? Yes or no on its own line.
3. If yes, give the **regimen and dose** for the agents likely to be stocked here —
   alteplase, tenecteplase and streptokinase — each on its own line. Note whether the dose
   or infusion time differs from the STEMI regimen.
4. How should anticoagulation be handled around the lysis — stopped, continued, or
   restarted at a stated time afterwards?
5. What are the contraindications specific to this indication, and does the risk-benefit
   balance differ from STEMI given the mortality of untreated massive PE?

---

# D. ADULT TUBERCULOSIS (pp.128–129)

## D1 🔴 The HIV-positive patient is routed out of the algorithm at the first question

**Verbatim, as printed.** The TB workup flow chart's **first** decision is *"HIV?"*, and
the Yes branch leads to a single box: *"Discuss with senior"*. Everything else on the
page — chest X-ray, Gene Xpert or three AFB smears, the MDR question, the treatment
regimen — sits on the No branch.

**The concern.** In this setting HIV-TB co-infection is common rather than exceptional, so
the branch that ends the algorithm is the one many patients are on. It offers no guidance
on the things that differ in HIV: that sputum smear is markedly less sensitive, that chest
X-ray is often atypical or normal, whether urine LAM has a role, when to start ART
relative to TB treatment, and co-trimoxazole prophylaxis.

**Questions.**
1. For a person living with HIV and suspected TB, what is the recommended **diagnostic**
   sequence where Gene Xpert and chest X-ray may both be available but sputum is hard to
   obtain? Please write it as an ordered list.
2. Does urine lipoarabinomannan (LAM) testing have a role, and if so in which patients —
   please state any CD4 threshold or clinical criteria as standalone lines.
3. Once TB treatment is started in a patient not yet on ART, **how long** should ART be
   deferred? Give the interval as a standalone line, and state separately whether it
   differs for TB meningitis.
4. Is the standard 2RHZE/4RH regimen unchanged in HIV, or does the duration or drug
   selection differ?
5. Should co-trimoxazole preventive therapy be started at the same time?

## D2 🔴 Adjunctive steroids are recommended for TB pericarditis with no HIV qualifier

**Verbatim, as printed.** The adjunctive-steroid decision asks *"Any of the following
present? TB meningitis · Pulmonary TB with respiratory distress · Pulmonary TB with airway
obstruction from hilar lymph nodes · Severe miliary TB · Pericardial effusion"* → *"Add
prednisone: 60 mg/day × 2 weeks; reduce by 10 mg/day weekly."*

**The concern.** Pericardial effusion is listed alongside the others with no distinction by
HIV status, and one prednisone regimen covers all five indications. My understanding is
that the evidence for steroids in TB pericarditis is weaker than for TB meningitis, and
that there has been specific concern about harm in HIV-positive patients. Given how many
patients here are HIV-positive, a blanket recommendation may not be right.

**Questions.**
1. Are adjunctive corticosteroids still recommended for **TB pericarditis**? Please answer
   separately for HIV-negative and HIV-positive patients, each on its own line.
2. If they are contraindicated or not recommended in HIV-positive patients, what is the
   reason, and should the book say so explicitly?
3. For **TB meningitis**, is prednisone the right drug, or should this be dexamethasone?
   Please give the preferred drug, the starting dose in mg/kg or mg/day, and the total
   duration of the taper — each as a standalone line.
4. Is a single steroid regimen appropriate for all five listed indications, or do the dose
   and duration differ between them? If they differ, please give each.

## D3 🟡 "MDR TB?" is asked with no stated way to answer it

**Verbatim, as printed.** The workup flow reaches a decision box reading simply *"MDR
TB?"* with outcomes *"Yes → Consult specialist"* and *"No → Begin treatment"*. Two steps
earlier the same flow says *"If available, perform Gene Xpert on 1 sputum sample; if not,
3 sputum specimens for AFB smear"*.

**The concern.** Nothing on the page tells the clinician what makes the answer yes. Gene
Xpert reports rifampicin resistance directly, but the flow never connects that result to
this question, and a smear-only workup gives no resistance information at all.

**Questions.**
1. What should trigger a presumption of drug-resistant TB in a setting where Gene Xpert
   MTB/RIF is the only resistance test available? Please list the criteria.
2. If Xpert reports rifampicin resistance, what should happen immediately — before the
   specialist is reached — regarding treatment and infection control?
3. If **only** AFB smear is available, what clinical or history features should raise
   suspicion of MDR-TB? Please list them explicitly (for example previous treatment,
   contact with a known resistant case, failure to convert).

## D4 🟡 The two hepatotoxicity thresholds differ and the reason is not stated

**Verbatim, as printed.** Before starting: *"ALT > 3 × upper limit of normal?"* → *"Consult
senior about a possible alternate regimen"*; and *"Abnormal LFTs but ALT < 3 × upper limit
of normal?"* → *"Recheck LFTs monthly"*. Then at the end of the treatment page: *"LFT
monitoring: if liver tenderness, hepatomegaly or jaundice, recheck LFTs. Do not change the
regimen unless LFTs > 5 × upper limit of normal."*

**The concern.** Three times ULN stops you starting, but five times ULN is required to
change course once running, and the page does not say why the thresholds differ. The
on-treatment rule also makes no allowance for a **symptomatic** patient with a lower ALT —
it is phrased as a single number.

**Questions.**
1. Are the baseline and on-treatment ALT thresholds genuinely different? Please give each
   as a standalone line, as a multiple of the upper limit of normal.
2. What is the threshold for stopping TB drugs in a patient **with** symptoms of
   hepatitis (nausea, vomiting, right-upper-quadrant pain, jaundice)? Standalone line.
3. Once drugs are stopped for hepatotoxicity, what is the recommended sequence for
   reintroducing them, and in what order?

---

# E. SEXUALLY TRANSMITTED INFECTIONS (pp.132–134)

## E1 🔴 Gonorrhoea is dosed at ceftriaxone 250 mg — is that still adequate?

**Verbatim, as printed:** *"Gonorrhea: Ceftriaxone 250mg IM x 1 dose. Alternative: Cefixime
400mg PO x 1 dose."* The same 250 mg single dose is also given for chancroid and inside the
ambulatory upper-genital-tract regimen.

**The concern.** 250 mg is the figure I remember from older guidance, and my understanding
is that it was raised because of declining gonococcal susceptibility to cephalosporins.
Oral cefixime has, I believe, also been moved down or discouraged for the same reason.
Syndromic management in a high-prevalence, low-testing setting depends entirely on the
first dose working, since there is usually no test of cure.

**Questions.**
1. What is the currently recommended ceftriaxone dose for uncomplicated gonorrhoea? Give
   the dose in mg on its own line, and state whether it changes with body weight.
2. Should azithromycin still be co-administered with ceftriaxone for gonorrhoea, or is
   ceftriaxone now given alone? Yes or no on its own line.
3. Is oral cefixime 400 mg still an acceptable alternative when ceftriaxone is not
   available? If it is only conditionally acceptable, please state the condition.
4. Does the answer change for pharyngeal infection?

## E2 🟡 Chlamydia first-line and alternative may be the wrong way round

**Verbatim, as printed:** *"Chlamydia: Azithromycin 1g PO x 1 dose. Alternative for
non-pregnant Women/Men: Doxycycline 100mg/dose q12hrs x 7 days. Alternative for pregnant
women: Erythromycin 1g/dose q12hrs x 7 days."*

**The concern.** My understanding is that first-line has moved to doxycycline for
non-pregnant patients, with azithromycin as the alternative — the reverse of what is
printed — because of better cure rates, particularly for rectal infection. Separately,
erythromycin 1 g twice daily is a higher dose than the regimen I am familiar with, and I
am not sure it is still the preferred option in pregnancy.

**Questions.**
1. For a **non-pregnant** adult with chlamydia, which is first-line — doxycycline 100 mg
   BD for 7 days, or azithromycin 1 g once? Please name the first-line agent on its own
   line.
2. For a **pregnant** woman, what is the preferred regimen and dose? Standalone line.
3. Is erythromycin 1 g every 12 hours for 7 days a correct erythromycin regimen for
   chlamydia? If not, give the correct dose and salt.
4. Does a single-dose regimen remain preferable in a setting where follow-up is unreliable
   and directly observed therapy is possible? Please weigh adherence against cure rate
   explicitly.

## E3 🟡 Bacterial vaginosis and trichomoniasis are given the same single-dose regimen

**Verbatim, as printed:**
- *"Bacterial Vaginosis: Tinidazole 2g PO x 1 dose. Alternative: Metronidazole 2g PO x 1
  dose."*
- *"Trichomoniasis: Metronidazole 2g PO x 1 dose. Alternative: Tinidazole 2g PO x 1 dose."*

**The concern.** The two conditions are given the identical pair of drugs at the identical
single 2 g dose, only with the order swapped. A single 2 g dose of metronidazole is the
regimen I associate with **trichomoniasis**; for bacterial vaginosis I understood the
recommended course to be a multi-day one, because single-dose treatment has a higher
recurrence rate. This looks like one regimen may have been copied onto both conditions.

**Questions.**
1. What is the recommended regimen for bacterial vaginosis — drug, dose, frequency and
   duration? Please give it as a standalone line.
2. Is single-dose 2 g metronidazole or tinidazole acceptable for bacterial vaginosis at
   all, or should it not be offered?
3. For trichomoniasis, is single-dose 2 g metronidazole still first-line for **women**, or
   has that changed to a multi-day regimen? Please answer separately for women and men.
4. Should partners be treated in each of the two conditions? The book says all partners
   are treated except herpes and candidiasis — is bacterial vaginosis an exception too?

## E4 🟡 Inpatient pelvic infection is treated with ceftriaxone 250 mg IM daily

**Verbatim, as printed**, under upper genital tract infection: *"Inpatient treatment:
1. Ceftriaxone 250mg IM daily  2. Doxycycline 100mg/dose PO BID x 14 days
3. Metronidazole 500mg PO/IV BID x 14 days"*.

**The concern.** The admission criteria immediately above include sepsis, toxic appearance,
peritonitis and abscess — yet the inpatient antibiotic dose is the same 250 mg used for
uncomplicated outpatient gonorrhoea, given intramuscularly rather than intravenously.

**Questions.**
1. What is the correct parenteral regimen and dose for **inpatient** pelvic inflammatory
   disease? Please give the ceftriaxone dose and route on its own line.
2. Should a patient admitted with suspected tubo-ovarian abscess or peritonitis receive
   broader cover than ceftriaxone, doxycycline and metronidazole?
3. When can parenteral treatment be stepped down to oral, and what completes the course?

## E5 🟢 The antiviral timing statements read as absolute

**Verbatim, as printed:** *"Herpes: Initial outbreak — ineffective if started after 5 days
from onset … Recurrence — ineffective if given after 24 hours from onset."*

**Question.** Is aciclovir genuinely **ineffective** outside these windows, or is the
benefit reduced? Please suggest wording that conveys diminishing benefit without implying
that a patient presenting on day 6 of a first episode should be refused treatment —
particularly in HIV-positive patients, where I understand episodes are more severe and
prolonged. If treatment is still warranted in HIV, please say so explicitly and give the
dose.

---

# F. HIV OPPORTUNISTIC INFECTIONS (pp.135–139)

## F1 🔴 Cryptococcal induction does not include the single-high-dose liposomal regimen

**Verbatim, as printed.** Induction (2 weeks), *"first option preferred"*:
- *"(Preferred) Liposomal amphotericin B 4 mg/kg/day IV plus flucytosine 25 mg/kg/dose PO
  4 times daily × 2 weeks"*
- *"Amphotericin B deoxycholate 1 mg/kg/day IV plus flucytosine 25 mg/kg/dose PO 4 times
  daily"*
- *"Fluconazole 800 mg/day (12 mg/kg/day in children < 19 kg) plus flucytosine 25 mg/kg/dose
  PO 4 times daily"*

Consolidation: *"Fluconazole 400 mg/day (10 mg/kg/day in children < 19 kg)"* for 8 weeks.

**The concern.** All three induction options require **fourteen days** of a daily infusion
or of high-dose oral therapy. A regimen based on a **single** high dose of liposomal
amphotericin B, given with oral flucytosine and fluconazole, was developed specifically
for African hospitals where daily infusions and daily monitoring are hard to sustain — and
that option does not appear here at all.

**Questions.**
1. Is single-high-dose liposomal amphotericin B now a recommended induction regimen for
   HIV-associated cryptococcal meningitis in resource-limited settings? Yes or no on its
   own line.
2. If yes, please give the complete regimen — the liposomal amphotericin dose in mg/kg and
   how many doses; the flucytosine dose and duration; and the fluconazole dose and
   duration — each on its own line.
3. How does it compare with 14-day amphotericin-based induction for mortality and for
   toxicity?
4. What consolidation and maintenance follow it, and for how long?
5. If liposomal amphotericin is unavailable and only **deoxycholate** is stocked, what is
   the best available induction, and what monitoring does it require?

## F2 🔴 Histoplasmosis maintenance is printed as itraconazole 200 mg three times daily

**Verbatim, as printed:**
> *"Maintenance: Children: itraconazole 2–5 mg/kg/dose TID × 3 days, then BID.
> Adults: itraconazole 200 mg PO TID."*

**The concern.** The children's line contains a loading step — three days three times
daily, **then twice daily**. The adult line has no such step: it reads as 200 mg three
times daily continued as maintenance. If the adult regimen is also meant to be loaded then
stepped down, the "then BD" has been dropped, and as printed an adult would stay on 600 mg
daily for months.

**Questions.**
1. For an adult on itraconazole maintenance for disseminated histoplasmosis, is the dose
   200 mg twice daily or three times daily? Please give the maintenance dose on its own
   line.
2. Is there a loading period of 200 mg three times daily first, and if so for how many
   days? Standalone line.
3. How long should maintenance continue, and what allows it to stop?

## F3 🔴 Rifabutin is added to histoplasmosis, where it should interact badly with itraconazole

**Verbatim, as printed**, as the last line of the histoplasmosis treatment block: *"If CD4
< 50, consider adding rifabutin 300 mg PO QD."*

**The concern.** Rifabutin has no antifungal activity. The identical sentence and dose
appear in the Mycobacterium avium complex section on the previous page, where rifabutin
does belong — so this looks like it was carried across in error. It also worries me
clinically: rifabutin is a strong enzyme inducer and I would expect it to lower
itraconazole levels substantially, so adding it to a patient being maintained on
itraconazole could cause treatment failure of the very infection being treated.

**Questions.**
1. Does rifabutin have any role in the treatment of disseminated histoplasmosis? Yes or no
   on its own line.
2. If a patient with histoplasmosis and CD4 < 50 also needs MAC prophylaxis, is rifabutin
   safe to combine with itraconazole? Please state the interaction and its direction.
3. If it must be co-prescribed, what dose adjustment or monitoring is required — and is an
   alternative MAC prophylaxis (for example azithromycin) preferable in that situation?

## F4 🟡 The paediatric rifabutin dose appears twice in this page at 5 mg/kg and at 15 mg/kg

**Verbatim, as printed.** MAC **prophylaxis**: *"alternative rifabutin 5 mg/kg PO daily"*.
MAC **treatment**: *"If CD4 < 50, consider adding rifabutin 15 mg/kg PO QD."*

**The concern.** A threefold difference in the same drug on the same page. The treatment
figure also carries no maximum, so a 30 kg child would be calculated to 450 mg — half again
the adult dose of 300 mg printed a few lines away.

**Questions.**
1. What is the correct paediatric rifabutin dose for MAC **prophylaxis**, in mg/kg/day?
   Standalone line.
2. What is the correct paediatric rifabutin dose for MAC **treatment**, in mg/kg/day?
   Standalone line.
3. What is the maximum daily dose in children, in mg? Standalone line.

## F5 🟡 The steroid trigger for PCP is an oxygen saturation below 90%

**Verbatim, as printed:** *"If initial O₂ sat on room air is < 90%: add prednisone /
prednisolone"*, followed by the 21-day taper.

**The concern.** The threshold I associate with adjunctive steroids in PCP is defined by
arterial oxygen tension or the A-a gradient, and where saturation is used as a proxy I
thought the cut-off was higher than 90%. If so, patients between those two figures would
be denied a treatment that reduces mortality. Blood gases are not available here, so the
saturation figure is the one that will actually be used.

**Questions.**
1. What is the correct arterial criterion for adjunctive corticosteroids in PCP? Please
   give the PaO₂ threshold and the A-a gradient threshold as two standalone lines.
2. Where only pulse oximetry is available, what **SpO₂** threshold best corresponds to it?
   Standalone line.
3. Must steroids be started within a particular window from the first dose of TMP-SMX? If
   so, how many hours? Standalone line.

## F6 🟡 Aciclovir for zoster is printed as 1 g three times daily

**Verbatim, as printed**, in the VZV table: *"Valacyclovir — Children 20 mg/kg/dose PO TID;
Adults 1 g PO TID. Acyclovir — Children 20 mg/kg/dose PO QID; Adults 1 g PO TID."*

**The concern.** Valaciclovir 1 g three times daily is the regimen I recognise for zoster.
Aciclovir at the same 1 g three times daily is not — I associate oral aciclovir for zoster
with a smaller dose given five times a day. The two drugs appear to have been given the
same adult dose.

**Questions.**
1. What is the correct **oral aciclovir** regimen for herpes zoster in an adult — dose and
   frequency? Standalone line.
2. Does it differ in HIV-positive patients, and does disseminated or ophthalmic
   involvement require intravenous therapy from the start?
3. For how many days should oral therapy continue?

## F7 🟢 CMV induction is given without a duration or a maintenance phase

**Verbatim, as printed:** *"Induction (one of the following): Adults: valganciclovir 900 mg
PO BD. Alternatives for adults and children: Ganciclovir 5 mg/kg/dose IV q12hrs; Foscarnet
90 mg/kg/dose IV q12hrs."*

**Questions.**
1. How long should CMV induction continue before stepping down? Give the number of days as
   a standalone line.
2. What is the maintenance regimen and dose after induction? Standalone line.
3. When can maintenance be stopped — please state the CD4 threshold and the duration on ART
   required.

---

# G. SUPRAVENTRICULAR TACHYCARDIA (p.125)

## G1 🔴 The stability branch appears inverted — the UNSTABLE patient is sent to adenosine

**Verbatim, as printed.** The flow chart's first box is *"Is the patient stable?"*. The
arrow labelled **No** leads right, into the adenosine box:

> *"Adenosine — 1. Give each dose as rapidly as possible  2. Follow each dose immediately
> with flush of 20mL IV NS  3. 6mg IV push (followed by NS flush)  4. Wait 1-2 minutes
> 5. No response, give 12mg IV push (followed by NS flush)  6. Wait 1-2 minutes  7. No
> response, give 12mg IV push (followed by NS flush)  8. Do not use more than 3 doses.
> Note: Electrical Cardioversion per ACLS protocol is preferred for unstable patients if
> available."*

The arrow labelled **Yes** runs downward to *"Sinus Tachycardia?"*, and from there to a
beta blocker or to atrial fibrillation management.

I have checked this against the printed page itself rather than the text alone, so the
branch labels are as described: unstable → adenosine, stable → down the beta-blocker path.

**The concern.** Two consequences follow from that arrangement:
1. The **unstable** patient's first-listed treatment is adenosine, with cardioversion
   demoted to a note at the bottom of the same box.
2. The **stable** patient with a regular narrow-complex tachycardia never reaches adenosine
   at all — the stable path goes to "sinus tachycardia?" and then to an oral beta blocker.

That is the opposite of the order I would expect, where adenosine is the drug for the
**stable** regular narrow-complex tachycardia and immediate synchronised cardioversion is
for the unstable one.

**Questions.**
1. For an **unstable** patient with a regular narrow-complex tachycardia — hypotension,
   altered mental status, ischaemic chest pain or acute heart failure — what is the
   first-line treatment? Please answer on its own line.
2. Is there any role for adenosine before cardioversion in that patient, and if so exactly
   when? Please be explicit about whether attempting adenosine may delay cardioversion.
3. For a **stable** patient with the same rhythm, what is the correct sequence — vagal
   manoeuvres, then adenosine, then what? Please write it as an ordered list.
4. Where a defibrillator with synchronised mode is **not** available, what should be done
   for the unstable patient? This is the realistic case here, and the answer determines
   whether the current chart is merely mislabelled or is actually the best available
   advice.
5. What synchronised cardioversion energy should be used for a narrow regular tachycardia
   in an adult, and in a child in J/kg? Two standalone lines.

## G2 🟡 Warfarin is started at 10 mg daily for two days with no risk stratification

**Verbatim, as printed**, for atrial fibrillation or flutter: *"1. Can consider digoxin for
rate control  2. Needs anticoagulation  3. Warfarin 10mg PO daily x 2 days, then base on
INR (goal 2-3)"*.

**The concern.** Three things. The anticoagulation indication is unqualified — "needs
anticoagulation" with no stroke-risk assessment. The loading dose is 10 mg for two days,
which I understood to be reserved for younger, well patients and to risk over-shooting in
the elderly, the malnourished, and those with liver disease — all common here. And no
interval for INR checking is given.

**Questions.**
1. Should anticoagulation in atrial fibrillation be decided by a risk score such as
   CHA₂DS₂-VASc, and if so what threshold should trigger it? Please give the score
   threshold on its own line, separately for men and women.
2. What warfarin starting regimen is appropriate for an older or frail adult? Give the
   starting dose in mg on its own line.
3. When should the first INR be checked after starting, and how often thereafter until
   stable? Two standalone lines.
4. Where INR monitoring is unreliable, is warfarin still the right choice, or is rate
   control alone preferable? Please answer directly — this is the common situation here.

## G3 🟢 Digoxin is offered for rate control with no dose

**Verbatim, as printed:** *"Can consider digoxin for rate control"* — no dose, route,
loading regimen or monitoring is given, on a page that gives full dosing for everything
else.

**Question.** Please give a complete digoxin regimen for rate control in atrial
fibrillation — loading and maintenance dose, route, and what to check before and during
treatment — with each figure on its own line. Please also state where digoxin sits against
a beta blocker for rate control in a patient who may have heart failure.
