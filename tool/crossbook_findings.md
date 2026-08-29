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


---

## ✅ 2026-08-29 — all 46 WVEMS flowchart pages screened for a dropped back-edge

WVEMS figures are strict, so a dropped arrow there is a lost instruction in a protocol
nobody may reinterpret. `tool/wvems_backedge_scan.py` renders each page and looks for a
connector running outside the column of boxes.

**The screen carries its own positive control and the first version FAILED it.** It hunted
near-black runs in the outer sixth of the *page*; WHO Chart 12's back-edge is a thin
**orange** arrow routed inside the chart's own frame, so both thresholds were wrong and it
reported the known back-edge as clean. Ink is now anything not near-white, margins are
measured against the chart's ink bounding box, and runs at ≥ 92% of an axis are discarded
as the page frame — which had otherwise flagged all 46 pages. The control now fires at
69% of chart width.

**Result: 13 of 46 flagged, none of them a back-edge.**

- **p68 (89%), p60 (82%)** — looked at. Both are the wide note boxes and the two branch
  arrows **converging into** a "Consider" node. All flow is downward.
- **p32 (right-band vertical 36%)** — looked at. The tall five-drug "Major" medication
  stack's right border.
- **p36 (37% at 73% height)** — looked at. A differential grid: eight cause boxes with
  **double-headed** arrows between the columns, meaning "these are alternatives". The app
  renders it `variant: differential`, which is right.
- **p4, p6, p10, p34, p44, p62, p64, p72, p74** — p4 was looked at; the other eight were
  closed by **measurement, not by sampling**: every one is a run of **175–176 px at 83% of
  chart height, 36–37% of chart width**, the identical geometry of the "Consider"
  convergence stadium seen on p4. Same pixel length at the same position is the same
  graphic element.

**Every WVEMS chart is entry → severity or cause split → parallel columns → converge into
"Consider", or a differential grid. None loops.** WHO Chart 12 remains the only routed
back-edge in the whole corpus, and it is fixed.


---

## ✅ 2026-08-29 — structural audit of all 111 flowcharts in all three books

`tool/flowchart_structure_audit.py` asks what a machine can decide on its own: can the
flow be followed? Not layout, not print fidelity. The two worst errors this project has
found were both structural — an SVT chart whose stability branch was inverted, and a
hyperkalaemia algorithm whose sickest branch contained nothing that lowers potassium.

**One real defect, in the SVT chart — the same chart as the inverted branch.**

Its final decision, *"Atrial fibrillation or atrial flutter?"*, carried **only a Yes
outcome**. A reader who answered **No fell off the bottom of the chart with no
instruction**. It is the **only one-sided decision in all 111 charts**. Fixed: the No
branch now points back at the treatment already given above (broke with vagal manoeuvres
or adenosine → nothing further; did not break → rate control then cardioversion at steps
3–4; still undiagnosed → 12-lead and treat the cause).

**The other 180 hits are the screen's own noise, and are named here so nobody re-runs it
expecting findings:**

- **94 × UNREACHED id.** In the `severity` variant a branch `id` is a render anchor, not
  a `goto` target, so nothing pointing at it is normal. The check is only meaningful for
  `cycle` and for explicit `goto`.
- **55 × BARE BOX.** A terminal box legitimately carries a title and nothing else —
  "Transfer to ICU", "No Rx necessary", "Treat underlying cause".
- **31 × DEAD END.** A `continue: true` on the last stage usually means the chart hands
  off to the prose or table block beneath it, which is how these pages are built.

Only the one-sided-decision check earned its place. The other three are kept in the
script with this note attached, because a future chart could genuinely trip them, but a
hit is not a finding.


---

## ✅ 2026-08-29 — the hyperkalaemia shape: does the sicker branch get the weaker treatment?

`tool/flowchart_severity_audit.py` asks the question that produced the worst defect this
project has found. That hyperkalaemia algorithm sent the K > 6.5 / ECG-changes patient to
calcium, furosemide and dialysis while **insulin-glucose and salbutamol — the only two
things that lower serum potassium in the first hour — sat on the milder 6.0–6.5 branch.**
For every decision that splits into a sicker and a milder arm, this compares what each arm
actually contains: a drug named on the milder arm and absent from the sicker one, or a
sicker arm carrying strictly fewer interventions.

**124 severity-ordered decisions compared. 18 raised. None is the hyperkalaemia shape.**

Read and dismissed with the reason:

- **`pb_047` DKA, `pb_046` severe pneumonia, `pb_039` envenomation** — in each, the sicker
  arm carries `continue: true` or hands off ("→ start DKA protocol"). The treatment is on
  the continuing spine or a dedicated page, not missing. A hand-off is not an omission.
- **`pb_042` convulsions, `pb_067` epistaxis, `pb_125` SVT** — the screen's own weakness:
  it reads "Yes" as the sicker label, but "Convulsion stops?" and "Has bleeding stopped?"
  make **Yes the good news**. The arms are the right way round.
- **`pb_125` "AF or flutter? Yes lacks adenosine"** and **`pb_075` "haemolysis lacks
  albendazole"** — the missing drug belongs to the *other* diagnosis. Adenosine is not for
  AF; albendazole is for the iron-deficiency arm.
- **`pb_030`, `pb_096`** — thinner sicker arms that read correctly: "intubate and admit to
  ICU" is two lines and outranks six outpatient steps.
- **`wvems_012`, `wvems_014`, `wvems_020`** — not touched. WVEMS is the original protocol
  and is strict.

## 🟢 One thing fell out of it: a paper reference the app cannot honour

`pb_035` read *"Score withdrawal severity with the [CIWA-Ar Scale](topic:pb-ciwa-ar)
**(next page)**"*. In the print the scale is on the facing page; in the app it is a
**separate topic** reached by that link, and there is no page to turn. Dropped.

**The other seven "(next page)" references in the book were checked and are correct** —
each points within a multi-page topic, and the app really does paginate those
(`topic_view.dart` iterates `topic.pages`), so the reader does swipe to a next page.


---

## ✅ 2026-08-29 — every ProtocolBook chart compared against the prose on its own page

`tool/chart_vs_prose_audit.py`. The move that has found the worst errors here is
comparing the book against itself; across books it caught an IV diazepam dose that two
review cycles had confirmed. This asks it *within a page*: does the chart say what the
paragraph beside it says?

47 topics carry both a chart and prose or table blocks — 62 charts against 242 prose and
table blocks. Doses are pulled from each side separately and compared per drug and unit.

**One difference across all 47 topics, and it is not a contradiction.**

`pb_042` paediatric convulsions, phenobarbitone: the chart carries **20 mg/kg, then a
further 10 mg/kg, cumulative maximum 40**; the prose carries **20 mg/kg stat, then a
further 5–10 mg/kg within 24 h, maintenance 5 mg/kg daily**. The prose paragraph is the
**"Convulsions in the 1st month of life"** section and the chart is the **over-one-month**
pathway. Both are internally coherent and each states its age group. No change.

**This instrument is worth keeping, unlike the within-topic dose spread.** One hit across
47 topics against 164 for the other, because comparing chart-side to prose-side is a real
boundary, while "two doses somewhere in one topic" is not — a topic legitimately holds
many drugs and many indications.


---

## ✅ 2026-08-29 — transfusion volume is stratified by FEVER, from TRACT

**Ruling.** Yes, stratify by fever. Threshold **37.5 °C**. **Febrile: whole blood
20 ml/kg (packed cells 10).** **Afebrile: whole blood 30 ml/kg.** The fever rule **sits
alongside** the age and malnutrition stratification and does **not** replace it, and for
the malnourished child **malnutrition takes precedence** — the conservative volume,
slowly, no repeat.

**Applied to `pb_076`** as an explicit hierarchy, because a malnourished febrile child
previously had two answers: malnourished first, then febrile, then afebrile, with age as
the fallback where temperature is not deciding.

**Framed as a volume-selection rule, not a mortality claim** — OE's own caveat. The fever
effect is a **prespecified subgroup interaction in a trial whose primary endpoint was
null** (TRACT, 3,196 Ugandan and Malawian children with severe anaemia). The direction is
well supported and drawn from exactly this population; the size of the benefit is not
established. The page says so.

**Also carried across:** TRACT found **no benefit in transfusing uncomplicated moderate
anaemia** (Hb 4–6 g/dL, no severity signs), so a conservative trigger belongs with the
conservative volumes.

### 🛑 Still open, and narrowed to one number

**Afebrile packed cells: 15 ml/kg or 20?** The WHO volume prints 20; the adjudication
gave 15. Whole blood is 30 on both. 15 against 20 is a third more blood in a setting
where supply is the binding constraint, and the ProtocolBook's own conversion — 10 ml
PRBC = 20 ml whole blood — implies 15. Printed as **15–20** until it is settled.

### ⚠️ The reference list on that reply did not match its content

The answer is entirely about TRACT and paediatric transfusion. Its three references were
the **FDA ampicillin label** and **two Lancet bacterial-meningitis reviews** — the
citation list from an earlier, unrelated question. The substance was checkable and is
recorded, but **nothing in it was accepted on the strength of those citations**.


---

## ✅ 2026-08-29 — afebrile packed cells settled at 20 ml/kg, and WHY 15 was wrong

**Ruling. Print the trial's pairing, not a conversion.** TRACT randomised to
**30 ml/kg whole blood OR 20 ml/kg red cells** (higher volume) against **20 ml/kg whole
blood OR 10 ml/kg red cells** (lower), treating each pair as equivalent. So the afebrile
child gets **20 ml/kg** packed cells and the febrile child **10 ml/kg**.

**The 15 came from applying a bedside rule to a figure the trial had already paired.**
`pb_076`'s own "10 mL PRBCs = 20 mL whole blood" halves 30 to 15. That rule reflects the
roughly doubled haematocrit of packed cells in the abstract, but it is not what TRACT
paired, and 15 would **under-transfuse the afebrile child** against the very evidence the
volumes come from.

Applied: the fever lines now read **30 WB or 20 PRBC** and **20 WB or 10 PRBC**, in that
order, so the whole-blood figure leads and the packed-cell figure is read off rather than
computed. The rule of thumb is kept — it is useful elsewhere — but now carries an
explicit **do not use it to derive these volumes**. The malnutrition brake is unchanged.

⭐ **The lesson is general: a conversion factor applied on top of a paired figure
manufactures a third number that no source states.** The two books never disagreed about
blood; one of them had done arithmetic the trial had not.

### ⚠️ Second reply in a row whose reference list did not match its content

This answer is about TRACT and paediatric transfusion. Its two references were the same
**Lancet bacterial-meningitis reviews** attached to the previous transfusion answer.
Twice now. The substance was checkable against the trial's own arm definitions and is
recorded on that basis; **nothing was accepted on the strength of the citations.**


---

## ✅ 2026-08-29 — every ProtocolBook formulary entry diffed against every page dose

The formulary is the lookup a clinician opens at the bedside. If a protocol prescribes a
dose the formulary does not carry, the lookup fails at the moment it is needed.

Every PB dose row was grouped by drug and unit and split into formulary-side and
page-side. **34 drug+unit pairs carry a page value the formulary lacks.** Read one by one:

**Three are real gaps, and all three are common emergencies. Added, copied from the pages
that already carry them with their qualifiers, so no new clinical claim is introduced:**

- **Omeprazole** — the formulary had only `20–40 mg PO OD`. The upper-GI-bleed page
  prescribes **80 mg IV bolus, then 40 mg IV q8–12h (or 8 mg/hr), at least 72 hours**.
- **Dexamethasone** — the formulary had extubation, croup and `cerebral oedema 2 mg TID`.
  The adult meningitis page prescribes **10 mg IV q6h × 4 days**, carried across with its
  "not routine here" qualifier intact.
- **Propranolol** — the formulary had `adults initial 40 mg BD`. The liver-failure page
  prescribes **20 mg PO BD** for variceal prophylaxis, second to carvedilol, with the
  HR target and the SBP < 90 stop.

**The rest are not gaps** and are named so they are not re-raised: the formulary states a
range the page picks a point inside (`carvedilol 3.125 → max 25` covers the page's 6.25
and 12.5; `nifedipine up to 120 mg/day` covers `30–120`; `furosemide 40 mg or double the
maintenance` covers `40–80`), or the same regimen expressed differently (`itraconazole
200 mg TID` **is** the page's `600 mg/day`; `nitrofurantoin 1.5 mg/kg/dose q6h` **is** the
page's `6 mg/kg/day`), or the page names a drug the formulary lists under a different
entry (`ceftriaxone 8 mg/kg/day` is the cefixime line beside it).

⭐ **This diff is what found the three glucose pages my own sweep had missed.** It earns
its place for the same reason the chart-versus-prose audit does: formulary-side against
page-side is a real boundary, so its hits mean something.


---

## 🔴 2026-08-29 — both formularies are missing drugs their own protocols prescribe

Running the formulary-versus-page diff on the WHO book turned into a bigger question than
the one it was asked. Not "does the formulary carry every DOSE" but **"does it carry the
DRUG at all"**.

Verified by matching each dosed drug against the actual entry names, not by a lookup
table — the first count was inflated by name mapping and was not trusted until checked.
Full list in `tool/crossbook/formulary_missing_drugs.tsv`.

**ProtocolBook: 40 of 129 dosed drugs have no formulary entry.** Among them:

| Drug | Rows | Where the protocols prescribe it |
|---|---|---|
| **atropine** | 14 | organophosphate poisoning, snake bite |
| **naloxone** | 12 | opioid overdose |
| **labetalol** | 11 | its own **first choice** in hypertensive emergency, and stroke |
| **acetylcysteine** | 10 | the paracetamol **antidote** |
| **aspirin** | 7 | ACS, stroke, rheumatic fever |
| **hydrocortisone** | 5 | anaphylaxis, paediatric sepsis |
| **midazolam** | 4 | status epilepticus, agitation |

**WHO Pocket Book: 42 of 94 dosed drugs have no formulary entry.** Among them:

| Drug | Rows | Where the protocols prescribe it |
|---|---|---|
| **glucose / dextrose** | 92 | every hypoglycaemia pathway in the book |
| **whole blood** | 26 | every transfusion page |
| **caffeine citrate** | 21 | neonatal apnoea |
| **naloxone** | 12 | opioid poisoning, neonatal resuscitation |
| **azithromycin** | 12 | pertussis, cholera, dysentery, typhoid |
| **vitamin K** | 6 | given to **every newborn** |
| **midazolam** | 5 | **Chart 9's own first-line anticonvulsant** |
| **magnesium sulfate** | 5 | severe asthma |
| **flucytosine** | 6 | cryptococcal induction |

**Why it matters.** The formulary is the lookup. A clinician who opens it for the
paracetamol antidote, the first-line drug in hypertensive emergency, or the anticonvulsant
the book's own chart tells them to reach for, finds nothing.

**What is safe to fix and what is not.**

- **The ProtocolBook entries can simply be written**, from the doses its own pages already
  carry and that have already been through review. No new clinical claim is introduced.
- **The WHO formulary is the print's Annex 2.** Adding drugs the printed annex does not
  list is a departure from the source, not a transcription fix. Grey's WHO caveat allows
  reorganisation that helps the reader, and a formulary that omits the glucose dose while
  the book prescribes it 92 times is arguably the clearest case for it — **but that is his
  call, not mine.**
