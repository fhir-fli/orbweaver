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

## 1 🔴 The two books treat NEONATAL MENINGITIS with ampicillin doses that differ two- to three-fold

**What the WHO book prints** (§3.9, meningitis in the young infant):
> - First-line: **ampicillin + gentamicin** (doses §3.14).
> - If a **third-generation cephalosporin** is used, **prefer cefotaxime** — **50 mg/kg
>   every 12 h if < 7 days**, **every 6–8 h if > 7 days** (+ gentamicin).

The §3.14 table it points at gives, as the only ampicillin entry in the book:

> **Ampicillin** — **50 mg/kg IM/IV — wk 1 q12h; wk 2–4 q8h**

That is **100 mg/kg/day in week 1 and 150 mg/kg/day thereafter** — the neonatal
**sepsis** dose. The table has no separate meningitis row, and §3.9 does not say to
increase it.

**What the other book in the same app prints** (neonatal sepsis, pp.86–87):
> If concern for meningitis: **ampicillin 100 mg/kg q8h (q12h if in the 1st week)**
> PLUS cefotaxime 50 mg/kg q8h (q12h if in the 1st week)

That is **200–300 mg/kg/day** — it explicitly doubles the dose when meningitis is
suspected. The same book gives **ampicillin 75 mg/kg IV 6-hourly (= 300 mg/kg/day)**
for Listeria in the older-child meningitis pathway (pp.54–55).

**The concern.** A clinician treating a neonate with meningitis gets **150 mg/kg/day**
if they open one book and **300 mg/kg/day** if they open the other. Ampicillin is the
Listeria and group B streptococcus drug, the CSF is the compartment that matters, and
the lower figure is the dose intended for bacteraemia without meningitis.

**Questions.**
1. What is the **correct ampicillin dose for confirmed or suspected neonatal
   meningitis**, in mg/kg and frequency, for **week 1** and for **weeks 2–4**? Please
   give each as a **standalone line with no citation after the number**.
2. Is **150 mg/kg/day adequate** for neonatal meningitis, or is it a sepsis dose that
   under-treats the CSF?
3. What is the correct **cefotaxime** dose for neonatal meningitis over the same two
   age windows? One book prints 50 mg/kg q12h then q6–8h; the other 50 mg/kg q8h then
   q12h in week 1.
4. Should a neonatal drug-dose table carry **a separate meningitis row** for
   ampicillin and cefotaxime rather than a single sepsis dose?

---

## 2 🔴 The two books give IV DIAZEPAM doses that differ two-fold in a convulsing child

**What the WHO book prints** (IMCI Chart 9, the anticonvulsant ladder):
> **After 10 min:** give a **second dose** (midazolam or diazepam; or **IV diazepam
> 0.1 ml/kg = 0.5 mg/kg**, max 10 mg, if a line is running).

Elsewhere on the same chart, **rectal** diazepam is **0.5 mg/kg (0.1 ml/kg)**, and the
chart's own header reads "Diazepam PR — 10 mg/2 ml, 0.1 ml/kg". The page also warns
that diazepam can cause **apnoea**.

**What the other book in the same app prints:**
> **IV diazepam 0.2 mg/kg** slowly over 1 minute, max 10 mg (resuscitation medications,
> p.20; and the paediatric convulsions pathway, p.42)

and, in its formulary:
> **IV diazepam: 0.3 mg/kg** slowly over 1 minute

**The concern.** The rectal and intravenous doses of diazepam are not the same — rectal
absorption is incomplete, which is why the PR dose is higher. The WHO chart appears to
carry the **rectal** figure across to the **IV** route: 0.1 ml/kg of a 5 mg/ml ampoule
is 0.5 mg/kg, roughly **double** what the other book gives intravenously. This is an IV
benzodiazepine in a fitting child, and the same page names apnoea as the hazard.

**Questions.**
1. What is the correct **IV** diazepam dose for a convulsing child, in mg/kg? Please
   give it as a **standalone line with no citation after the number**.
2. What is the correct **rectal** dose, on its own line — and is it the same figure as
   the IV dose or higher?
3. Is **0.5 mg/kg IV** an overdose in a child, and what is the risk if it is given?
4. The other book is internally inconsistent — **0.2 mg/kg** on its resuscitation page
   and **0.3 mg/kg** in its formulary. Which should it print?
5. What is the **maximum single dose**, and the maximum number of benzodiazepine doses
   before moving to phenobarbital or phenytoin?

---

## 3 🟡 The two books lead with DIFFERENT first-line anticonvulsants, and one says the other's choice is inferior

**What the WHO book prints** (IMCI Chart 9):
> **Intranasal midazolam 0.2 mg/kg (max 10 mg)** … (level-1 evidence over rectal
> diazepam). If midazolam is unavailable, give **rectal diazepam 0.5 mg/kg**.

Its Annex 1 repeats the preference: *"Midazolam (preferred benzodiazepine): 0.1–0.2 mg/kg
IV, or 0.3–0.5 mg/kg intranasal / buccal / oral when there is no IV line."*

**What the other book prints** — its paediatric convulsions pathway leads with
**diazepam** (IV 0.2 mg/kg, or rectal 2.5 mg suppositories by weight), with midazolam
appearing only as *"No IV access? IM midazolam 10 mg — as effective as IV lorazepam and
faster to give."*

**The concern.** This is not a dose difference but a **first-line drug** difference, in
the commonest paediatric emergency in the book, and one volume explicitly states that
the other volume's first choice has weaker evidence.

**Questions.**
1. For a convulsing child **with no IV access**, what should a pocket reference print as
   **first-line** — buccal or intranasal midazolam, or rectal diazepam? One line.
2. For a convulsing child **with a line running**, what is first-line? One line.
3. Is the "level-1 evidence over rectal diazepam" claim for midazolam correct as stated?
4. Does the answer change where **only diazepam is reliably stocked**, which is the
   usual situation here?

---

## 4 🟡 The two books give different AZITHROMYCIN regimens for dysentery

**WHO** (§5.4, bloody diarrhoea / Shigella):
> **Azithromycin 12 mg/kg on day 1, then 6 mg/kg on days 2–5.**

**The other book** (paediatric dehydration protocol, antibiotics for bloody diarrhoea):
> Alternative: **Azithromycin 15 mg/kg PO on day 1 then 10 mg/kg PO OD days 2–5**

Same organism, same indication, same age group, different numbers on both days.

**Question.** Which regimen should be printed for shigellosis in a child — give the
day-1 dose and the days-2-to-5 dose as **standalone lines with no citation after the
number** — and does either exceed or fall short of what is needed?

---

## 5 🟡 The two books give different CALCIUM GLUCONATE doses for hypocalcaemic convulsions

**WHO** (§3.7, convulsions in the young infant):
> If **hypocalcaemic**, symptoms may settle with **2 ml/kg of 10% calcium gluconate** as
> a slow IV infusion.

**The other book**, formulary:
> Tetany / convulsions: **0.6–1 ml/kg of 10% solution** via slow push

and, for hyperkalaemia (a different indication, listed for completeness):
> 10% calcium gluconate IV — children **0.5 mL/kg**, adults 10 mL, over 2–3 min

**The concern.** For the same indication — a fitting child with hypocalcaemia — the two
books differ two- to three-fold.

**Questions.**
1. What is the correct dose of **10% calcium gluconate for symptomatic hypocalcaemia /
   hypocalcaemic convulsions** in a child, in ml/kg? Standalone line, no citation after
   the number.
2. Does it differ for a **neonate**?
3. What is the **maximum single dose** and the maximum rate?
4. Is the lower 0.5 ml/kg figure correct for **hyperkalaemia**, where calcium is given
   to stabilise the myocardium rather than to replace a deficit?

---

## 6 🟡 The two books give different HYDROCORTISONE doses as an allergic-reaction adjunct

**The other book** (anaphylaxis, p.37):
> Steroids: **Hydrocortisone 5 mg/kg IM/slow IV (max 200 mg)**

**WHO** (§10.6.5, transfusion reactions — both the moderate and the life-threatening
branch):
> Give **hydrocortisone 1–2 mg/kg IV (max 100 mg)**

Both books are explicit that steroids do not treat airway, breathing or circulation and
must never delay adrenaline, so this is an adjunct in both. The doses differ by up to
five-fold and the caps by two-fold.

**Question.** What single hydrocortisone dose and maximum should a pocket reference print
for a severe allergic reaction in a child — mg/kg and cap, as **standalone lines** — and
does it differ between anaphylaxis and a transfusion reaction?

---

## 7 🟡 ZINC for diarrhoea: one book splits the dose by age, the other does not

**WHO** (§5.2.2 and its formulary):
> **10 mg/day under 6 months, 20 mg/day at 6 months and over** — with a note that a 2020
> trial found 5–10 mg noninferior with less vomiting, but the WHO standard is unchanged.

**The other book** (paediatric dehydration protocol):
> All cases to receive **Zinc 10–20 mg/day × 10–14 days**

**The concern.** The range covers both WHO figures but says nothing about **which age
gets which**, so an infant under 6 months could be given the 20 mg dose. The duration
also differs — 10–14 days here against WHO's usual 10–14 days, which agrees, but the age
split does not carry.

**Question.** Should the age split (**10 mg under 6 months, 20 mg at 6 months and over**)
be printed rather than a single range? Does giving 20 mg to an infant under 6 months
cause harm, or is it only the vomiting signal from the 2020 trial?

---

## 8 🟡 VITAMIN K in the preterm infant: the two books split at different weights

**WHO** (§3.3, routine newborn care):
> Infants **≤ 1500 g: 0.3–0.5 mg/kg IM** (a single IV dose is not recommended in preterm
> infants).

**The other book**, formulary:
> Preterm **< 1 kg: 0.3 mg/kg IM stat** · Preterm **> 1 kg: 0.5 mg IM stat**

**The concern.** The threshold differs (1 kg against 1500 g) and, above it, one book
gives a **flat 0.5 mg** where the other gives **0.3–0.5 mg/kg**. For a 1.2 kg infant
those are 0.5 mg and 0.36–0.6 mg — close — but the rules are stated differently and a
reader cannot reconcile them.

**Question.** What weight threshold and dose should be printed for vitamin K in the
preterm infant? Give the threshold and each dose as **standalone lines**.

---

## 9 🟡 Nebulised SALBUTAMOL: 5 mg or 2.5 mg in a child over 2 years?

**The other book** (wheezing child, pp.52–53):
> Nebulizer: **< 2 years 2.5 mg** in 3 mL NS; **> 2 years 5 mg** in 5 mL NS

**WHO** (§4.5.2, asthma) uses **2.5 mg** nebulised for a child, with no 5 mg step.

**Question.** Should a child over 2 years receive **5 mg** or **2.5 mg** of nebulised
salbutamol? One line. Is there an age or weight at which the dose steps up?

---

## 10 🟡 Oral PREDNISOLONE for acute wheeze: 1 mg/kg or 1–2 mg/kg?

**WHO** (§4.5.2): *"oral prednisolone **1 mg/kg (max 60 mg; 20 mg for ages 2–5 y)** for
3–5 days"*, and its formulary: *"Acute wheeze/asthma: **1–2 mg/kg/day** for 3–5 days"* —
**the WHO volume already disagrees with itself here.**

**The other book** (wheezing child): *"Prednisolone **1–2 mg/kg** PO × 1 dose"* and
*"Prednisolone **1–2 mg/kg** OD × 3 days"*.

**Question.** What is the correct oral prednisolone dose for acute asthma or wheeze in a
child — mg/kg, maximum, and whether the 2–5 year cap of 20 mg is right — as **standalone
lines**? Is 2 mg/kg ever indicated?

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
