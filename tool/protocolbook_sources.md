# ProtocolBook audit — source corpus (re-fetch list)

During the 2026-07-27 audit a set of guideline PDFs was downloaded to the session
scratchpad, which is **session-scoped and is now gone**. These are the fetch URLs,
so any later session can rebuild the corpus. Everything below is free and public.

## The one that matters most

**Uganda Clinical Guidelines 2023** — the national guideline for the country this
book is used in. It was decisive on four disputed doses and is the reference that
shows where the book diverges from what Ugandan clinicians are formally taught.
https://library.health.go.ug/sites/default/files/resources/Uganda%20Clinical%20Guidelines%202023.pdf

Extracts cleanly with `pdftotext`. ~2.4 MB of text. Note it still carries two
pre-2018/pre-evidence positions the book now diverges from (pralidoxime; the
rabies IM remainder) — both are footnoted in the topics.

## WHO

- **Pocket Book of Hospital Care for Children**, 2nd ed. 2013 —
  https://www.afro.who.int/sites/default/files/2017-06/pocket_booklet_hospital_care_0.pdf
  (Chart 9 p.14 convulsions · Chart 10 p.15 hypoglycaemia · Annex 2 p.336 diazepam,
  p.343 phenobarbital · pp.28–29 organophosphates · pp.49–50 phenobarbital repeat)
- **Model List of Essential Medicines, 24th list (2025)** —
  https://iris.who.int/server/api/core/bitstreams/17642505-ecd3-4940-a691-4f1dfa0d835a/content
  (used to check what is realistically stocked — flumazenil and pralidoxime are
  absent; naloxone is 400 µg/mL, which is why intranasal is not deliverable)
- **Guidelines for the Prevention and Clinical Management of Snakebite in Africa**,
  AFRO 2010 — https://iris.who.int/handle/10665/204458
  PDF mirror: https://biomedicalsciences.unimelb.edu.au/__data/assets/pdf_file/0008/2774195/AFRO-Snakebite-Management-Guidelines-2010.pdf
  (§15.1.1 tetanus · §15.4 anticholinesterase trial, incl. the mamba exclusion)
- **Guidelines for the Management of Snakebites**, SEARO 2016, 2nd ed —
  https://iris.who.int/handle/10665/249547
  (the "avoid even minor trauma including intramuscular injections" rule)
- **Rabies FAQ for clinicians (2018)** —
  https://cdn.who.int/media/docs/default-source/ntds/rabies/rabies-clinicians-faqs-20sep2018.pdf
- **Rabies position paper, April 2018** —
  https://cdn.who.int/media/docs/default-source/immunization/position_paper_documents/rabies/pp-rabies-summary-2018.pdf
- **Information note on delayed haemolytic anaemia after artesunate** —
  https://www.who.int/docs/default-source/documents/publications/gmp/information-note-on-delayed-haemolytic-anaemia-following-treatment-with-artesunate.pdf
- **IMCI chart booklet, 2014** —
  https://cdn.who.int/media/docs/default-source/mca-documents/child/imci-integrated-management-of-childhood-illness/imci-in-service-training/imci-chart-booklet.pdf
- **Guidelines for malaria, 13 Aug 2025** —
  https://iris.who.int/server/api/core/bitstreams/26a6af2d-060c-4449-8207-1f25e63c6cc3/content
  ⚠️ IRIS 403'd on direct fetch and the PDF would not text-extract. The PDMC and
  delayed-haemolysis facts were taken from the GMP information note + CDC instead.

## Resuscitation / emergency

- **ERC 2021 Paediatric Life Support** — http://www.pemdatabase.org/European_Guideliens.pdf
- **Resuscitation Council UK, paediatric emergency drug chart 2025** —
  https://www.resus.org.uk/sites/default/files/2025-10/Paediatric%20emergency%20drug%202025.pdf
- **RCUK, Emergency treatment of anaphylaxis 2021** —
  https://www.resus.org.uk/sites/default/files/2021-05/Emergency%20Treatment%20of%20Anaphylaxis%20May%202021_0.pdf
- **AES 2016 status epilepticus algorithm** —
  https://aesnet.org/docs/default-source/press-releases-assets/cse-treatment-chart-final_rerelease.pdf
- **AAAAI/ACAAI anaphylaxis practice parameter 2020** —
  https://www.aaaai.org/Aaaai/media/Media-Library-PDFs/Professional%20Education/Podcasts/Anaphylaxis-2020-grade-document.pdf
- **NICE NG258, anaphylaxis assessment and referral (May 2026)** —
  https://www.nice.org.uk/guidance/ng258/chapter/period-of-observation
- **NICE NG184, human and animal bites** —
  https://www.nice.org.uk/guidance/ng184/chapter/Recommendations

## Toxicology

- **MSF / Oslo International Methanol Poisoning Protocol, 2nd ed. 2023** —
  https://methanolpoisoning.msf.org/wp-content/uploads/2023/03/MSF_International_Methanol-Poisoning_Protocol_v2_20230110_EN.pdf
- **EXTRIP methanol recommendations** — https://www.extrip-workgroup.org/methanol
- **IPCS/WHO antidote monograph: atropine** —
  https://www.inchem.org/documents/antidote/antidote/atropine.htm
- **EPA Recognition and Management of Pesticide Poisonings, 6th ed** —
  https://www.epa.gov/sites/default/files/2015-01/documents/rmpp_6thed_final_lowresopt.pdf
- **CHEMM nerve-agent hospital management** — https://chemm.hhs.gov/na_hospital_mmg.htm
- MSF Medical Guidelines (essential drugs, per-drug pages) —
  https://medicalguidelines.msf.org/en/viewport/EssDr/english/

## Method notes worth keeping

- `pdftotext` on the UCG and WHO PDFs works; a few WHO PDFs are image-only and
  will not extract — check before relying on a grep returning nothing. The
  hydrocortisone question could not be settled locally for exactly this reason
  (UCG's extracted text has no "hydrocortisone" entry at all).
- Building a drug×dose inventory across all 95 topics and grepping each drug name
  against the UCG text found that **197 of 222 drug terms in the book also appear
  in UCG** — i.e. most of the book is cross-checkable against the national
  guideline. The extraction script pattern is in the audit memory.
