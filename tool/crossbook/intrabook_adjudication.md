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
