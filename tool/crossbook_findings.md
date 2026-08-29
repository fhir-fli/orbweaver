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

# ⚡ ONE ITEM OPEN. Everything else on this page is CLOSED.

**Ten findings came out of this pass. OE answered all ten and all ten are applied.**
Only the neonatal-meningitis ampicillin **number** is unresolved, and it is the first
section below. The ten question write-ups have been deleted now they are answered —
leaving answered questions sitting in a queue is how OE ended up re-answering settled
ones twice.

---

## 🛑 THE ONE THING NOT CLOSED — neonatal meningitis ampicillin

**OE's own reply gives two different figures, and the ProtocolBook prints a third.**

- **OE answer 1** quotes the FDA neonatal-meningitis table: **100 mg/kg/day in week 1,
  150 mg/kg/day in weeks 2–4** — which is exactly what §3.14 already said.
- **OE answer 2** then says 150 mg/kg/day **is** the sepsis dose and is inadequate, and
  to use **≥ 150 mg/kg/day in week 1 rising to 200 mg/kg/day** thereafter.
- **The ProtocolBook prints 200 mg/kg/day in week 1 and 300 mg/kg/day thereafter**, and
  300 mg/kg/day for Listeria in the older child.

I applied **answer 2** (150 → 200 mg/kg/day) to the WHO volume, because it is the direct
response to "is 150 adequate" and because it is strictly safer than the sepsis row that
was there. **I did not touch the ProtocolBook.** So the two books still differ, and the
number is not settled.

**Question for OE.** For **confirmed or suspected neonatal meningitis**, give the
ampicillin dose as **standalone lines with no citation after the number**:
1. **≤ 7 days:** ___ mg/kg/day, and the dosing interval.
2. **8–28 days:** ___ mg/kg/day, and the dosing interval.
3. Is **300 mg/kg/day** in a neonate — what the other book prints — too much, or is it
   the right Listeria/GBS cover?
4. Your earlier reply gave both "100/150 mg/kg/day per the FDA table" **and** "150 is a
   sepsis dose, use ≥150 rising to 200". Which is it?

---

# ✅ 2026-08-28 — ALL TEN ANSWERED BY OE AND APPLIED

Verified by re-running the comparison: **azithromycin, zinc, vitamin K,
hydrocortisone and IV diazepam now carry identical values in both books.**

| # | OE ruling | Applied |
|---|---|---|
| **1** 🔴 | Neonatal meningitis needs a **higher ampicillin dose than sepsis**; the §3.14 row under-treats the CSF. A **separate meningitis row** is needed. Cefotaxime frequency **increases** with postnatal age. | §3.9 rewritten with an explicit "do not use the §3.14 sepsis row"; **new meningitis row added to §3.14** (50 mg/kg q8h wk 1, q6h wk 2–4). ⚠️ **number not settled — see below** |
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
