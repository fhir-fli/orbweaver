# Cross-book dose comparison — findings

**Method.** `tool/crossbook_dose_extract.py` pulls every dose-bearing fragment from
all 95 ProtocolBook topics, all 259 WHO topics and both formularies — 2,418 rows
across 356 files — attaching each dose to the nearest drug mention before it.
`tool/crossbook_dose_diff.py` lays the two books side by side per drug and unit and
reports every pair whose value sets differ: **80 candidate pairs across 43 drugs**.
Every candidate below was read against its context by hand.

**The instrument was validated against known positives before use.** Run against the
pre-fix tree (`22e3b7c`), it flags all four cross-book contradictions found by hand
in the WHO advance pass — acetylcysteine, dexamethasone, co-trimoxazole, flucytosine.
Three structural defects were found and fixed first, each of which had silently
produced zero rows: table rows split drug from dose, formulary entries nest doses
under a sibling of the drug name, and sub-bullets lost the drug named in their
parent. A fourth pass added 63 drugs that are prescribed in the text but are in
neither formulary — without them their doses were being handed to whatever drug was
nearest, which is how both antihistamine and steroid doses in the anaphylaxis bullet
were landing on adrenaline.

**Setting for every question below:** district hospital, Gulu, northern Uganda —
low-resource, paediatric-heavy, malaria-endemic. Limited drug availability; no
reliable dialysis; ICU monitoring is not routinely available.

---

---

---

# ⚡ NO QUESTIONS LIVE HERE. NOTHING IS OPEN.

**This file is the RECORD: what was ruled, where it was applied, and what was checked and
dismissed with the reason.** The open questions are in `crossbook_open_questions.md` —
three of them — and that file contains nothing but questions.

---

# ✅ 2026-08-28 — ALL TEN ANSWERED BY OE AND APPLIED

Verified by re-running the comparison: **azithromycin, zinc, vitamin K,
hydrocortisone and IV diazepam now carry identical values in both books.**

| # | OE ruling | Applied |
|---|---|---|
| **1** 🔴 | Neonatal meningitis needs a **higher ampicillin dose than sepsis**; the §3.14 row under-treats the CSF. A **separate meningitis row** is needed. Cefotaxime frequency **increases** with postnatal age. | §3.9 rewritten with an explicit "do not use the §3.14 sepsis row"; **new meningitis row added to §3.14** (50 mg/kg q8h wk 1, q6h wk 2–4). ✅ **settled 2026-08-28** — 150 → 200 mg/kg/day confirmed for a **term** neonate, preterm ≤ 34 wk week-1 band (100 mg/kg/day q12h) added. Cefotaxime as applied also confirmed. The other book still prints 200 → 300 and that remains open. |
| **2** 🔴 | **IV diazepam 0.2–0.3 mg/kg, max 10 mg.** 0.5 mg/kg is the rectal figure; rectal absorption is incomplete, which is why it is higher. 0.5 mg/kg IV is roughly double, and **16% of children had severe or life-threatening respiratory depression at recommended IV doses**. Max two benzodiazepine doses. | Chart 9 corrected to **0.2 mg/kg**; ProtocolBook formulary 0.3 → **0.2** to match its own p.20; both books gained the never-confuse-IV-with-rectal rule and the age-banded rectal doses |
| **3** 🟡 | **Buccal or intranasal midazolam 0.3–0.5 mg/kg (max 10 mg)** first-line with no line; **IV lorazepam 0.1 mg/kg or IV diazepam 0.2 mg/kg** with a line. The level-1 claim is correct (OR 4.1, Cochrane/McIntyre; 9-RCT meta-analysis 2026). **Where only diazepam is stocked, rectal diazepam 0.5 mg/kg remains acceptable first-line** — an available drug beats an unstocked better one. | Chart 9 restructured accordingly; intranasal widened 0.2 → 0.3–0.5 mg/kg |
| **4** 🟡 | **Day 1: 12 mg/kg (max 500 mg); days 2–5: 6 mg/kg/day (max 250 mg).** The 15/10 variant has no proven advantage and more GI upset. | `pb_043` corrected. **Both books now identical** |
| **5** 🟡 | **Both figures were right — they are different indications.** Child tetany 0.5–1 mL/kg; **neonate 1–2 mL/kg**; hyperkalaemia 0.5 mL/kg (myocardial stabilisation, does not lower K⁺). Max ~10 mL, ≤ 100 mg/min in a child. **The defect was that neither book said which.** | Both books now **label every calcium dose by indication**, with the rate cap |
| **6** 🟡 | **Hydrocortisone 2–4 mg/kg, max 100 mg in a child** (200 mg adult); same for anaphylaxis and transfusion reaction. An **adjunct of unproven benefit** that must never delay adrenaline. | ProtocolBook 5 → 2–4 mg/kg, cap 200 → 100 mg for a child; WHO 1–2 → 2–4 mg/kg. **Both books now identical** |
| **7** 🟡 | **Print the age split: 10 mg/day under 6 months, 20 mg/day at 6 months and over**, 10–14 days. A single range risks the 20 mg dose in a young infant. | `pb_043` corrected. **Both books now identical** |
| **8** 🟡 | **The split is at 1500 g, not 1 kg.** Above it, **1 mg IM** (the same as term) — not 0.5 mg. At or below it, **0.3–0.5 mg/kg**. A single IV dose is not recommended in a preterm infant. | ProtocolBook formulary corrected. **Both books now identical** |
| **9** 🟡 | **2.5 mg for most children; 5 mg for an older or larger child (≈ ≥ 5 y or > 20–25 kg) or a severe attack.** Weight and severity, not a 2-year cutoff. ⚠️ OE marked this a **practice recommendation, not a cited guideline value.** | `pb_052` corrected, and the header records that the figure is uncited — revisit if a guideline value turns up |
| **10** 🟡 | **1–2 mg/kg/day for 3–5 days, no taper.** Max **20 mg/day under 2 y, 30 mg/day at 2–5 y**, 40–60 mg older. 2 mg/kg **is** indicated in moderate-to-severe attacks. | WHO asthma page 1 → 1–2 mg/kg/day and the 2–5 y cap 20 → 30 mg. It had also disagreed with the WHO formulary, which already said 1–2 |

## 🔴 The finding behind the finding: two review cycles CONFIRMED the diazepam error

`who_1_chart09_diazepam.yaml`'s own header records it. On **2026-06-18** a review
"corrected" IV diazepam **0.25 → 0.5 mg/kg**, calling 0.25 subtherapeutic. On
**2026-07** a second review **re-confirmed 0.5 as accurate**. Both were wrong: 0.25 sits
inside the correct 0.2–0.3 range, and 0.5 is the rectal figure.

**Neither review caught it, because both were reading that page on its own.** It took
laying the two books side by side — the ProtocolBook prints 0.2 mg/kg IV — to see it.
That is the argument for the cross-book pass, and for keeping the tooling.

---

# ✅ Fixed directly, no OE needed

- **WHO formulary, spectinomycin note** still read *"ceftriaxone 25–50 mg/kg IM as a
  single dose (**max 125 mg**)"* — contradicting the **250 mg** applied to §3.12.2 and
  §3.14 from OE flag 3-1. Corrected to 250 mg.
  🔑 **It was missed in that round because the grep covered `topics/` and the formulary
  is a separate file.** Search both, always.

# ✅ Checked and NOT a contradiction

⚠️ **I said earlier that everything checked and dismissed was written down. That was
not true of nine of them** — aminophylline, artemether, artesunate, aspirin, atropine,
ciprofloxacin, dextrose, furosemide and activated charcoal were adjudicated in the pass
and never recorded. They are below now, with the rest.

**2026-08-28, second run** (after WVEMS was removed and five extractor defects fixed):

- **clindamycin** — ProtocolBook 7 mg/kg q8h (max 300 mg) is oral, for GAS pharyngitis
  in penicillin allergy; WHO 10–13 mg/kg 3–4×/day is for abscess and osteomyelitis,
  where deep-tissue and bone penetration is the point. Different indications, both
  standard.
- **lorazepam** — ProtocolBook 0.5–2 mg is adult agitation and alcohol withdrawal; WHO
  0.1 mg/kg (max 4 mg) is a paediatric seizure dose. Different indication and
  population.
- **benzylpenicillin** — was a candidate only because penicillin V was conflated with
  it, and because a clindamycin dose was being filed under it. With both fixed, the two
  books no longer differ. Penicillin V agrees exactly (250 mg).
- **activated charcoal** — ProtocolBook 1 g/kg, WHO 0.5–1 g/kg for ≤ 1 year. The WHO
  figure is the infant band of a per-age table; 1 g/kg is the standard above it.
- **aminophylline** — ProtocolBook's 4 mg/kg q12h is neonatal apnoea; WHO's 5 mg/kg q6h
  is childhood asthma. The 100/200/250/300 mg figures are vial and tablet strengths, not
  doses.
- **artemether, artesunate** — the WHO-only values are the partner-drug halves of ACT
  combinations (lumefantrine 12 mg/kg, mefloquine 8.3 mg/kg) and the quinine ladder.
  Artesunate itself agrees: 3 mg/kg under 20 kg, 2.4 mg/kg at or above.
- **aspirin** — ProtocolBook 300 mg stat then 75–100 mg daily is adult stroke and ACS;
  the shared 300 is the same number reached from two directions.
- **atropine** — agrees at 0.02 mg/kg. The ProtocolBook's 0.01–0.04 mg/kg is the
  anticholinesterase trial in cobra envenoming, which WHO does not carry.
- **ciprofloxacin** — ProtocolBook's 1000 mg/dose ceiling is adult; WHO's 500 mg/dose is
  the paediatric cap on 10–20 mg/kg. Not the same quantity.
- **dextrose** — agrees at 2 and 5 ml/kg after the glucose correction. The remaining
  values are diluent volumes and quinine infusion fluid.
- **furosemide** — ProtocolBook 1 mg/kg/dose BD paediatric and 40–80 mg IV adult; WHO
  1 mg/kg then 2 mg/kg in heart failure. Compatible; the WHO page is an escalation, not
  a different starting dose.

Read and dismissed with the reason, so they are not re-raised:

- **Ampicillin, cefotaxime, ceftriaxone, gentamicin, amoxicillin** outside neonatal
  meningitis — the differences track indication and age, and each book's figure is
  internally consistent with its own weight bands.
- **Isoniazid, rifampicin, pyrazinamide, ethambutol** — the ProtocolBook prints the
  **adult** daily doses (H 5, R 10, Z 25, E 15 mg/kg) and the paediatric table prints the
  **child** doses (10 / 15 / 35 / 20). Both correct; the difference is age.
- **Dexamethasone in TB meningitis** — now agrees in both books after OE flag 6-1;
  the residual difference is the adult/child split, which both books now name.
- **Co-trimoxazole for PCP** — now agrees at TMP 15–20 mg/kg/day after OE flag 4-1. The
  24 mg/kg/day still visible in the extract is the text of the correction itself, quoting
  the withdrawn figure.
- **Flucytosine 150 mg/kg/day** — same: it appears only inside the sentence that
  withdraws it.
- **Fluconazole** — the 800 mg cap is consolidation and 200 mg is maintenance; both books
  now say so.
- **Amphotericin B** — 0.5 mg/kg (candidiasis, deoxycholate), 1 mg/kg/day (cryptococcal
  induction, deoxycholate) and 3–5 mg/kg (liposomal) are different indications and
  different formulations.
- **Morphine, paracetamol, ibuprofen, phenytoin, phenobarbital, magnesium sulfate,
  iron, folic acid, erythromycin, adrenaline** — differences all reduce to indication,
  age, or route.
- **Vitamin A** — reads as a difference only if the extractor mis-parses the thousands
  separator. Both books carry **50 000 / 100 000 / 200 000 IU** exactly. Fixed in the
  tool; the two books agree.

# 🟢 Noted, below the threshold for OE

- **WHO §3.14** lists a *"Ceftriaxone (meningitis) 50 mg/kg IV q12h"* row in a table of
  **neonatal** doses. The avoid-in-neonates caveat is in the notes below the table, and
  §3.9 carries a red callout — but the row is what gets read at speed. Worth considering
  a marker on the row itself.
- **WHO morphine** — the formulary says oral **0.2–0.4 mg/kg q4–6h**; §10.4 and §8.7.1
  both say **0.15–0.3 mg/kg q4h**. Internal to the WHO volume.
- **ProtocolBook iron** — the anaemia page says 65 mg elemental iron **= ferrous sulfate
  200 mg**; the formulary says a **325 mg** ferrous sulfate tablet contains 65 mg
  elemental. Both are true of different salt forms, but a reader cannot tell which tablet
  is in front of them.

---


---

## 🛑 OE has now misread the same parenthetical TWICE

Both replies on neonatal meningitis called the ProtocolBook's cefotaxime schedule
inverted — *"the other book's 50 mg/kg q8h then q12h inverts the age direction; frequency
should increase with postnatal age, not decrease"*.

The book actually prints **"cefotaxime 50 mg/kg q8h (q12h if in the 1st week)"**, which
means **q12h in week 1, q8h thereafter** — frequency increasing with age, exactly as OE
says it should. The same shape appears on the ampicillin line beside it.

**No inversion was applied, either time.** Recorded here so a third reply does not
persuade someone to "fix" a page that is already right. If a question about that page
goes back to OE, quote the parenthetical in full and say what it expands to.


---

# ✅ 2026-08-28 — the three durations/thresholds questions, answered and applied

| # | OE ruling | Applied |
|---|---|---|
| **1** | **300 mg/kg/day of ampicillin is too much for a NEONATE and correct BEYOND 4 weeks.** Term neonate: **150 mg/kg/day week 1 (50 mg/kg q8h), 200 mg/kg/day weeks 2–4 (50 mg/kg q6h)**; very preterm (≤ 34 wk) in week 1 takes **100 mg/kg/day q12h**. The ceiling is set by **immature renal clearance** — ampicillin is renally eliminated and accumulation risks CNS excitation and seizures. Adult ceiling 12 g/day. **Child > 4 weeks with meningitis: 300 mg/kg/day is right.** | `pb_086` neonatal meningitis brought down from 200→300 to **150→200**, with the preterm band and the reason. The older-child 300 mg/kg/day is **left as it was — it is correct** |
| **2** | **3HR first-line** — isoniazid 10 mg/kg/day (7–15, max 300 mg) + rifampicin 15 mg/kg/day (10–20, max 600 mg) daily × 3 months. Higher completion at equal efficacy. **6H stays acceptable where rifampicin FDCs are not stocked** — an available regimen given reliably beats an unstocked better one. Same for a child with HIV or under 5; if ART interactions rule out a rifamycin, isoniazid 6–9 months. **Pyridoxine 12.5–25 mg/day** if HIV-positive or malnourished. | `pb_071` rewritten from 6H-only to 3HR first-line with 6H named as the stocked-out alternative, plus the HIV/under-5 case and pyridoxine |
| **3** | **A routine 94% trigger is not defensible here.** It commits oxygen to a much larger group without mortality benefit; thresholds as low as 88% are safe (OxyKids, OxyPICU) and the paediatric Surviving Sepsis panel now conditionally recommends **88–92%** after resuscitation. **Harmonise the 94%-adult / 90%-child split down to 90%.** Separate the **trigger** from the **target**, and cap the target in hypercapnia-prone patients. | **25 ProtocolBook topics** swept from `< 94%` to `< 90%`. COPD target 90–92% → **88–92%**, with the trigger-is-not-the-target line. Discharge and CCHD-screening criteria are different figures and were **left alone**. The WHO oxygen page already carried < 90% trigger, > 90% target and the 88–92% note, and needed no change |

⚠️ **The oxygen sweep took two passes.** The first regex required a lowercase `s` in
`spO`, so the sixteen `spO2` files changed and the nine `SpO₂` files did not. Both are
done; the check is that no `oxygen if …` line reads 94% anywhere.


---

## ✅ 2026-08-28 — adrenaline in adult cardiac arrest, settled from the sources

**Not sent to OE.** It was queued as a confirm-me, then withdrawn: the published sources
settle it and there was nothing to adjudicate.

**What the sources say.** The AHA ACLS reference states *"Patients who remain in pulseless
ventricular tachycardia or ventricular fibrillation after defibrillation and 1 cycle of
CPR should receive **1 mg of IV epinephrine every 3 to 5 minutes** while high-quality CPR
is ongoing"*, and for non-shockable rhythms *"IV epinephrine (**1 mg every 3 to 5
minutes**)"*. The **2-minute** figure is the **rhythm-check / compressor-change** interval,
and the same reference does not tie the drug to it.

**The defect was exactly that conflation.** The chart drew one "Every 2 minutes" cycle
node and put epinephrine inside it, so the page read as 1 mg every 2 minutes. The
interval now sits on its own, separated from the 2-minute cycle. The paediatric page of
the same book already printed 3–5 minutes and is unchanged.

Read: [ACLS, StatPearls / NCBI](https://www.ncbi.nlm.nih.gov/books/NBK613285/) ·
[2019 AHA Focused Update on ACLS](https://www.ahajournals.org/doi/10.1161/CIR.0000000000000732).
The AHA's own 2025 algorithm PDF at cpr.heart.org returns 403 to an automated fetch and
was **not** read — naming it here so the gap is on the record rather than implied.


---

## ✅ 2026-08-29 — every WHO chart page rendered and checked for dropped arrows

The loop-word grep was the wrong instrument for the WHO charts: **a printed back-edge
can use no loop words at all, and Chart 12's did not.** So all eleven chart pages were
rendered from the source PDF at 120 dpi and looked at, rather than read through the text
layer.

**Result: Chart 12 was the only one with a drawn back-edge, and it is fixed.** The others
carry no return arrows to lose —

- **Charts 2, 7, 8, 11** are assess/treat columns and weight tables. Chart 7 and Chart 8
  *describe* reassessment loops ("reassess after first infusion… if no improvement,
  repeat"), but the print sets them as prose and tables, not as a flowchart, and the app
  matches.
- **Charts 3, 4, 5, 6** are procedure illustrations — choking, airway, oxygen delivery,
  positioning. No decision flow at all.
- **Charts 9, 10** are procedure text plus a dose-by-weight table.
- **§11.2 monitoring** is a bulleted list, not a chart.

## 🔑 Chart 9's print settles the diazepam question the other way round

The print reads: *"or give diazepam IV at **0.05 ml/kg = 0.25 mg/kg** if IV infusion is
running"*.

So the 2026-06-18 note on that page — that 0.25 mg/kg "was a transcription error" and
that 0.5 mg/kg was the figure "per WHO" — **was wrong about WHO as well as about the
drug.** WHO printed 0.25. The page now gives **0.2 mg/kg**, the FDA label figure, which
sits inside the same 0.2–0.3 range, and the print's own 0.25 is recorded on the page so
nobody re-derives it. The rectal table (0.1 ml/kg = 0.5 mg/kg) and the two-dose cap match
the print exactly.

**Twice now, checking the actual source has overturned a claim made about that source.**
