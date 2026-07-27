# ProtocolBook — OE re-review tracker

**Round 2 complete (2026-07-27).** Grey put the conflict list back through
OpenEvidence; OE revised on essentially every point. Everything it revised is
now applied at **`24fbe4d`**.

What follows is (A) what was resolved and applied, and (B) what is **still open** —
either because OE's reply did not reach it, or because it was never asked.

---

# A. RESOLVED AND APPLIED (`24fbe4d`)

| Item | First OE answer | Final position | Where |
|---|---|---|---|
| Famotidine in anaphylaxis | doses confirmed correct | **delete the drug** — zero RCTs ever (Nurmatov); absent from RCUK, AAAAI 2020/2023, WHO EML §3, UCG 2023 | `pb_037` |
| Anaphylaxis observation | ≥4 h | **≥6 h; 12 h if severe; admit all under-16s** — NICE's short route needs patient-held auto-injectors (none here); its 12 h criteria (out-of-hours, poor access) are routine here | `pb_037` |
| Phenobarbital load | 20 mg/kg | **revert to 15 mg/kg** + "may increase to 20 if seizures persist AND respiratory monitoring available" | `pb_020` |
| Diazepam cap | max 8 mg | **max 10 mg** + "maximum 2 doses, then phenobarbital" | `pb_020`, `pb_042` ×2, `pb_029` |
| NAC regimen | 3-bag if ≤40 kg | **2-bag for ALL**, diluent scaled 7 mL/kg → 14 mL/kg, D5W in children | `pb_032` |
| Doxycycline age | ≥8 years | **no age restriction** for courses ≤21 days | `pb_038` |
| Folic acid | not asked | **never 5 mg with SP or cotrimoxazole**; paeds 0.4–1 mg; folinic acid for antifolate-induced anaemia | `pb_075` |
| PDMC | not asked | **added** — monthly DHA-piperaquine at weeks 2, 6, 10 after severe malarial anaemia | `pb_023` |
| Snakebite anticholinesterase | not asked | **added, cobra only — explicitly NOT mamba** (WHO AFRO doses) | `pb_039` |
| Pralidoxime | equivocal | **footnote** noting UCG carries it, evidence uncertain | `pb_029` |
| Rabies IM remainder | — | **footnote** noting WHO 2018 vs UCG 2023, both acceptable | `pb_038` |
| Diazepam "0.3 was an error" | — | **withdrawn** — WHO prints a 0.2–0.3 band; we had printed its top | recorded |

**Also caught by a whole-book grep, not by either review:** `pb_104_im_gi_bleed`
still prescribed **ranitidine 50 mg IV q8h** as 2nd-line acid suppression.
Withdrawn worldwide 2020, not obtainable. Now **famotidine 20 mg IV q12h**.
This had been on the original clear-cut flag list since the Ingestions batch and
was missed for three rounds. **Lesson: after any drug-withdrawal substitution,
grep the whole book for the old drug name.**

---

# B. STILL OPEN

## B1 — OE's round-2 reply did not reach these
1. **Methanol antidote/dialysis block** (nothing applied). Folinic acid
   1 mg/kg (max 50 mg) q4h, folic acid same dose if unavailable, repeat after
   dialysis · dialysis criteria (visual loss, coma/fits, pH ≤7.15 or HCO₃ <10,
   persisting acidosis, >30 mL or >1 g/kg ingested, methanol >50 mg/dL, renal
   failure) · **ethanol maintenance DOUBLED in regular drinkers** (under-dosing
   is the commonest error, and regular drinkers are who drinks bad waragi) ·
   no-dialysis path (ethanol 5–7 days; bicarbonate = 0.3 × wt × base deficit) ·
   fomepizole "where available", never with ethanol · **Gulu RRH is itself a
   dialysis centre**, which makes "refer" concrete.
2. **Activated charcoal** — window refinement (CTRC 2026: ≤2 h strong, ≤3 h
   conditional, against beyond 6 h; the 4 h figure is for ≥30 g specifically)
   and **we still print no charcoal DOSE anywhere** (50 g adult, 1 g/kg child).
3. **Atropine paediatric start** — 0.02 (applied, OE round 1) vs **0.05 mg/kg
   (UCG 2023)**. Also not on our page: titrate to **secretions, not heart rate** —
   "do not stop atropine for tachycardia, especially in children".
4. **Flumazenil** — currently gated on the algorithm with contraindications.
   The research argued for removing it from the overdose algorithm entirely
   (not on WHO EML; Penninga 13-RCT meta-analysis AE **RR 2.85**, serious
   **RR 3.81**). OE round 2 did not revisit.
5. **Post-artesunate haemolysis** — trigger should be "received parenteral
   artesunate" not "severe malaria"; and the weekly four-marker panel is not
   obtainable at a district hospital, so it should probably be **Hb + clinical
   weekly, markers "if available"**. Incidence ~23%, days 14 and 21 highest-yield.
6. **Hgb < 9 anaemia threshold** — OE's reply truncated mid-sentence. Below WHO's
   2024 thresholds. Deliberate rationing choice, or should it move?

## B2 — never put to OE
7. **Bite prophylaxis indications** — neither our page nor OE states *when* to
   give it. UCG and IDSA agree: deep/cat puncture · human bite · severe or
   extensive · face, genitalia, hands · over joint or bone · immunocompromised,
   diabetic, asplenic · already infected — i.e. **not routine for a small
   uncomplicated dog bite**. Plus UCG's no-co-amoxiclav fallback (amoxicillin +
   metronidazole), which is the realistic district-level situation.
8. **Phenobarbital repeat pathway** — WHO pp.49–50 give further **10 mg/kg doses
   to a cumulative max 40 mg/kg**. Not on our page.
9. **Phenobarbital maintenance** — we print 3–5 mg/kg/day; better-sourced is
   **2.5–5** (WHO Annex 2 verbatim; UCG 2.5 mg/kg once–twice daily).
10. **Snakebite — the IM rule is broader than tetanus.** WHO SEARO: "avoid even
    minor trauma **including intramuscular injections**" — applies to every IM
    drug while clotting is abnormal, not just the toxoid. Use IV/oral instead.
11. **Rabies immunoglobulin framing** — WHO 2018 says the dose is a **MAXIMUM,
    not a target** ("there is no minimum dose"), and leftover RIG can be
    **fractionated for another patient** rather than given IM. Our text still
    reads as a target. Also unstated: category III only, no eRIG skin test,
    dilute with saline for small children, never after day 7.

---

# C. STANDING NOTES

- **Uganda Clinical Guidelines 2023** is the highest-value source for the rest of
  this audit — it is what Ugandan clinicians are formally taught, and it was
  decisive on atropine, the diazepam cap and phenobarbital. Point OE at it.
  https://library.health.go.ug/sites/default/files/resources/Uganda%20Clinical%20Guidelines%202023.pdf
- **The recurring pattern:** OE answers from FDA labels and US guidelines; WHO
  and UCG often differ, and for this book WHO/UCG usually wins. When a number
  differs, ask which body it came from before treating either as wrong.
- **Do not conflate SNAP with the 2-bag regimen.** SNAP (Bateman 2014) is a
  12-hour protocol with ondansetron. The 200-then-100 mg/kg is the 2-bag 20-hour
  regimen (Wong/Graudins, 2NAC).
