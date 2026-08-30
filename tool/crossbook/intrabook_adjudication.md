# Intra-book dose contradictions — adjudication

Every row of `intrabook_contradictions.tsv`, read. A row is a drug and unit whose
values differ across two or more pages of ONE book. Most are legitimate: the same drug
dosed differently by indication, age or route. The ones that are not are listed as
findings.

Generated list: 185 rows. Verdicts below, in the order read.

## Findings

**WHO diazepam formulary note — a dose with no drug name.** The note read "Neonates:
give phenobarbital (20 mg/kg IV/IM) instead of diazepam. If convulsions continue, repeat
10 mg/kg IV/IM after 30 min." The 10 mg/kg is phenobarbital, but it sits inside the
diazepam entry with no drug named, so a reader looking up diazepam finds a repeat dose
that appears to be diazepam's. **Fixed** — it now says PHENOBARBITAL, not diazepam.

**WHO primaquine — page and formulary disagreed after the 2026-08-29 ruling.** The
formulary was updated to 0.5 mg/kg/day as the East African target; the malaria page still
read 0.25–0.5 with the higher end attributed only to East Asia and Oceania. **Fixed** —
the page now names 0.5 as the target here.

## Read and cleared (extraction artifacts, not book defects)

The dose extractor attaches a number to the nearest drug mentioned, so a value under one
drug's heading can be captured under a neighbour's name. These were checked in the file
and the file is correct:

- **WHO dexamethasone in TB meningitis, 10 / 15 / 20 / 35 mg/kg** — these are the HRZE
  regimen's own doses (isoniazid, rifampicin, ethambutol, pyrazinamide) on the same page.
- **WHO midazolam 0.3–0.5 "procedural sedation"** — the entry is correct: 0.1–0.2 mg/kg
  IV, or 0.3–0.5 intranasal/buccal/oral. The extractor merged the two labels.
- **WHO hydrocortisone 0.15 mg** — a prednisolone value under a neighbouring heading.
- **Adrenaline rows in both books (ratios up to 6000x)** — driven by concentrations
  (1:1000, 1:10 000) and volumes being read as doses.

**WHO phenobarbital formulary — one unlabelled loading dose where the print has two.**
The entry printed "Loading: IM 15 mg/kg" with weight bands and no indication, while its
own notes gave neonates 20 mg/kg. The print carries both, correctly separated: the
neonates-and-low-birth-weight table gives loading 20 mg/kg, repeat 10 mg/kg after 30 min
to a cumulative max 40 mg/kg, maintenance 5 mg/kg/day; Annex 2 gives 15 mg/kg for an
older child in status epilepticus after two doses of diazepam. Both figures are right.
The millilitre bands were checked against the 200 mg/ml solution and match 15 mg/kg
(0.34 / 0.60 / 0.94 / 1.31 / 1.84 ml), not 20, so they belong to the older-child row.
**Fixed** — all four rows now labelled by age, and the bands marked as older-child only.
Same defect as the calcium gluconate one: both figures right, neither labelled.

**🔴 ProtocolBook phenobarbital — the book contradicts itself on an anticonvulsant
loading dose. OPEN with OE.** p.154 formulary: infants/children/adults 15 mg/kg, max
initial 320 mg. p.20 resuscitation medications, paediatric AND adult tables: 20 mg/kg all
ages, no cap, cumulative max 40 mg/kg. Not reconcilable by adding the cap — 320 mg is
reached at 16 kg on the 20 mg/kg scheme. **Not merged and not decided.** The formulary
entry now shows the conflict and points to the resuscitation page for an actively
convulsing patient; the question is Q1 in the OE file and the errata entry is written.

## Band 1.9–3.2x — 61 rows, all read

This is the band where both pages look plausible and neither reads as wrong, so it is
where a real error is hardest to see. One finding.

**🔴 WHO lidocaine formulary — a maximum dose with no preparation named.** The entry read
"Local injection: 4–5 mg/kg per dose", transcribed faithfully from the printed annex.
**5 mg/kg exceeds the accepted maximum for PLAIN lidocaine, which is 4.5 mg/kg**; 7 mg/kg
is allowed only when the solution contains epinephrine. This book's own intraoperative
page already carries that split from a 2026-07 OE review, and the formulary was left
behind — the meropenem pattern again. **Fixed**: the entry now gives 4.5 plain, 7 with
epinephrine, notes the conservative 3 mg/kg used for procedures elsewhere in the book,
adds the 1% = 10 mg/ml and 2% = 20 mg/ml conversion, and says toxicity in a small child
is convulsions and cardiac arrest.

**Read and cleared — legitimate differences, correctly labelled where it matters:**

- **Two strengths of the same drug for different indications**, present identically in
  both the formulary and the page: acyclovir 400/800, adenosine 6/12, albendazole
  200/400, azithromycin 250/500, clindamycin 300/600, erythromycin 250/500, penicillin V
  250/500, ciprofloxacin 250/500/750, ampicillin 250/500, cloxacillin 250/500,
  ceftriaxone 250/500, leucovorin 5 and 10–25, pyrimethamine 0.25/0.5, rifabutin 5 and
  10–20, zinc 10/20, morphine 1–2 and 2–10, nifedipine, losartan, captopril, furosemide,
  enoxaparin, ticagrelor, tenecteplase's weight bands, alteplase's three indications.
- **Age-banded and labelled:** PB gentamicin (neonate < 7 days 3, 8–28 days 5, term
  neonate/child/adult 5–7.5), acetylcysteine's two-bag diluent 7 then 14 ml/kg,
  artemether 3.2 loading then 1.6, quinine 20 loading then 10, rabies immunoglobulin
  human 20 / equine 40, insulin's DKA rates, WHO caffeine citrate load 20 then
  maintenance 5–10.
- **Indication-driven:** WHO amoxicillin 25–50 for UTI against 80–90 for otitis and
  severe wasting; ampicillin and cefotaxime meningitis against sepsis doses, all named;
  hydrocortisone by indication; ibuprofen 5–10; bupivacaine.
- **Extraction artifacts:** WHO amodiaquine 4 mg/kg (that is artesunate's figure in
  "artesunate 4 mg/kg + amodiaquine 10 mg/kg"); WHO potassium 1 mmol/kg (sodium
  bicarbonate's salicylate dose).
- **Pyridoxine 25 vs 50 mg** across two tuberculosis pages is not a contradiction: the
  paediatric page doses by weight from 50 mg tablets, the adult page gives 25 mg daily.
- **Chlorphenamine 0.1 vs 0.25 mg/kg** in transfusion reactions is in the print both
  ways, 0.1 for a mild reaction and 0.25 for a moderate one, with the annex at 0.25. Low
  stakes: it is an adjunct that does not treat the reaction. Recorded, not raised.
