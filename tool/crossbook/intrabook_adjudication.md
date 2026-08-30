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

## Bands >3.2x (106 rows) and 1.5–1.9x (18 rows) — all read

**No further findings.** Everything in these two bands is either a legitimate difference
or an extraction artifact.

**The artifact mechanism, confirmed repeatedly:** the extractor attaches a number to the
nearest drug named, so a value sitting under a neighbouring drug's heading is captured
under the wrong name. Every high-ratio row checked resolved this way. Worked examples:
aminophylline "50 mg/kg" is magnesium sulfate's asthma dose; amphotericin "100 and
150 mg/kg/day" are flucytosine's; artemether "12 mg/kg" is artemether–lumefantrine's
combined figure; prednisolone "300 mg" is aminophylline's, from the asthma page; the
adrenaline rows, which carry the largest ratios in the file, are driven by 1:1000 and
1:10 000 concentrations and by millilitre volumes being read as doses; WHO glucose
"1 200 / 2 100 mg/kg" is thousands separators. None is a book defect.

**Checked specifically because the value would be dangerous if a reader took it as that
drug's dose, and all clean:**

- **Glucose 2 ml/kg** on every ProtocolBook page. The 10 ml/kg belongs to quinine's
  infusion diluent. The August sweep that missed three pages has held.
- **Co-trimoxazole.** The formulary gives 4 mg/kg TMP + 20 mg/kg SMX twice daily, which
  is TMP 8 and SMX 40 per day, correct. The 24 mg/kg/day that appears on the severe
  pneumonia page is the withdrawn figure quoted inside the text that explains why it was
  withdrawn, not a live dose. The urinary tract infection page's 40 is sulfamethoxazole,
  not trimethoprim.
- **Acetylcysteine 150 mg/kg** is the ingestion threshold for charcoal and the first bag
  of the three-bag regimen, both correct and both labelled.
- **Isoniazid's 15 and 35 mg/kg** are rifampicin and pyrazinamide from the same table.
- **Gentamicin** is age-labelled in both books: neonate under 7 days 3, 8–28 days 5, term
  neonate to adult 5–7.5 mg/kg/day.

**Low band, all legitimate by indication:** alteplase 0.6 mg/kg peri-arrest against
0.9 mg/kg stroke; heparin 12, 18 and 20 units/kg/h by indication; cefotaxime and
ampicillin meningitis doses against standard; amoxicillin tablet strengths; flucytosine
150 mg/kg/day, already marked in the entry as no longer recommended.

## Pass complete — 185 of 185 rows read

Three defects found, all fixed: the phenobarbital loading dose and its 320 mg cap, the
lidocaine maximum with no preparation named, and the diazepam note whose repeat dose
named no drug. Plus two consistency repairs: the WHO phenobarbital rows unlabelled by
age, and the primaquine page left behind by its own formulary.

**The pattern worth keeping.** Every one of the three defects was a formulary entry that
disagreed with the page prescribing the drug, and in two of the three the page had
already been corrected and the formulary was left behind. That is now five occurrences of
the same shape, counting meropenem and vancomycin. **When a page dose changes, the
formulary entry has to change in the same commit.**

## The instrument was wrong, so the pass was re-run — 2026-08-30

The extractor attributed every dose to the nearest drug MENTIONED. Inside a formulary
entry that is wrong: the drug is not in question, it is the entry you are standing in.
Phenobarbital's regimen reads "20 mg/kg ... after two doses of diazepam have failed", so
its loading dose was filed under **diazepam**. The same bug filed prednisolone's
milligrams under hydrocortisone, magnesium sulfate's under aminophylline, and
flucytosine's under amphotericin — each of which cost a read during the first pass.

Formulary rows now bind to their own entry, **unless another drug is named within 20
characters before the dose**, which is how a companion agent is quoted: cefixime's entry
ends "if neither is available: gentamicin 240 mg IM", and diazepam's note says "repeat
PHENOBARBITAL 10 mg/kg after 30 min". Both now attribute to the drug named. A drug
mentioned further away does not capture the dose, which is what keeps phenobarbital's own
regimen with phenobarbital.

Re-running surfaced **fourteen drug/unit groups the old attribution had hidden**. All
read. Two were real.

**🔴 WHO piperaquine — the page underdoses small children.** The malaria page printed a
flat "4 mg/kg DHA + 18 mg/kg piperaquine", while the formulary said ~24 mg/kg with a
higher target under 25 kg. WHO doses piperaquine higher per kilogram in small children:
**24 mg/kg under 25 kg, 18 mg/kg at 25 kg and above**. A clinician reading only the page
gives a child the adult milligrams per kilogram. Underdosed piperaquine both fails the
child and selects for resistance. **Fixed** — the page now carries both, and says why.

**🔴 Ferrous sulfate — the two pages disagreed on the tablet, and both were right.** The
anaemia page said 65 mg elemental iron equals ferrous sulfate **200 mg**; the formulary
said a **325 mg** tablet contains 65 mg. Both conventions are correct: 200 mg is the
dried (exsiccated) salt, 325 mg the heptahydrate, and each carries 65 mg of elemental
iron. Neither page said which, so a clinician holding the other form would be out by
about 40%. **Fixed** — both places now name the form.

**The other twelve, read and cleared:** fluconazole 1200 mg/day quoted inside the
amphotericin entry is cryptococcal induction and is on the page too; WHO amodiaquine
"4 mg/kg" is artesunate's half of "artesunate 4 + amodiaquine 10"; folic acid 250 µg is
the iron–folate tablet and 50 µg is a multivitamin content; cefixime, hydrocortisone,
terlipressin and ipratropium all matched their pages; WHO isoniazid 100 mg is the
ethambutol tablet in the fixed-dose combination entry and 300 mg is the adult preventive
tablet; cefalexin 100 mg/kg/day is the severe skin-infection dose, stated in the entry.

⚠️ **One extraction defect recorded, not fixed:** the dose pattern treats a space as a
thousands separator, so "bag 1 200 mg/kg over 4 h" is read as 1200 mg/kg. It produces
phantom values in the tooling only; the book text is correct. The parity baseline absorbs
them.
