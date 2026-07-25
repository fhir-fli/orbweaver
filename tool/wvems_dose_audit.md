# WVEMS Drug Reference — evidence-audit worksheet

> ## ✅ COMPLETE — all flags OpenEvidence-verified by Grey and APPLIED (commit after `a850e37`)
> All 11 flags (+ naloxone) were run through OpenEvidence and corrected in the
> Drug Reference cards + mirrored in `tool/peds_dose_compute.py`:
> - **Adenosine** adult → 6 mg then 12 mg. **Epi** → 0.3 mg IM anaphylaxis added,
>   distinct from 1 mg IV CODE. **Atropine** → organophosphate 2 mg double q5min.
>   **Glucagon** → β-blocker/CCB OD 2–10 mg IV. **Charcoal** → 50 g (1 g/kg).
>   **Ancef** peds → 25–30 mg/kg. **Decadron** peds → 0.6 mg/kg, max 12.
>   **Epi Push** → 10 mcg/mL push-dose added. **Rocephin** → sepsis 50/2 g vs
>   meningitis 100/4 g. **TXA** → CRASH-2 1 g (not 2 g). **Albuterol** peds →
>   fixed 2.5 mg. **Narcan** peds → 0.01 mg/kg initial, titrate to 0.1.
> Evidence: PALS 2025, AHA 2023/2025 poisoning updates, CRASH-2, GINA 2026, FDA
> labels, per OpenEvidence (references in the conversation/commit).

Systematic review of all 50 cards in `wvems_2026_drug_reference.yaml` against
current guideline/standard EMS dosing. Flags below were from model knowledge,
then OpenEvidence-confirmed and applied (history kept for reference).

Status: ✅ looks guideline-consistent · ⚠️ CHECK (concern below). The benzo /
Keppra / Rocuronium / Atropine-minimum items were already corrected (commit
`0268e43`) — not re-listed.

---

## 🔴 Priority flags (safety-relevant) — check these first

### 1. Adenosine — adult dose missing the first (6 mg) step
- **Card:** adult **12 mg** IV/IO.
- **Concern:** standard SVT dosing is **6 mg rapid IV first**, then **12 mg** if
  no conversion. The card jumps straight to 12 mg (skips the 6 mg step).
- **Likely fix (confirm):** adult "6 mg, then 12 mg IV/IO (rapid push + flush)".

### 2. Epinephrine — anaphylaxis IM dose not distinguished from the CODE dose
- **Card:** indications include **Allergy**, but the adult dose shown is
  **1 mg IV/IO (CODE)**.
- **Concern:** **anaphylaxis is 0.3 mg IM (0.01 mg/kg, max 0.3–0.5 mg)** — giving
  the 1 mg IV CODE dose for anaphylaxis would be dangerous. The card should show
  the IM anaphylaxis dose distinctly.
- **Likely fix (confirm):** add adult "Anaphylaxis: **0.3 mg IM**" (peds
  0.01 mg/kg IM, max 0.3 mg) alongside the CODE dose.

### 3. Atropine — organophosphate dose not shown (only bradycardia)
- **Card:** indications include **Organophosphate OD**, adult dose shown is
  **1 mg IV/IO (brady)**.
- **Concern:** organophosphate/nerve-agent atropinization is **2 mg+ IV,
  doubling q3–5 min to effect** — far above the 1 mg brady dose. (DuoDote covers
  this separately, so may be intentional — confirm whether to note it here.)
- **Likely fix (confirm):** add "Organophosphate: 2 mg, double q3–5 min" or a
  pointer to DuoDote.

### 4. Glucagon — β-blocker/CCB OD dose higher than the hypoglycemia dose
- **Card:** indications include **β-blocker OD**, adult dose **1 mg IM**.
- **Concern:** **β-blocker/CCB toxicity uses 3–10 mg IV** (often followed by an
  infusion) — the 1 mg hypoglycemia dose is sub-therapeutic for OD.
- **Likely fix (confirm):** add "β-blocker/CCB OD: 3–10 mg IV".

---

## 🟡 Minor flags — worth a look

- **Charcoal** — adult **25 g**; usual activated-charcoal dose is **1 g/kg
  (≈ 50 g adult)**. 25 g may be low.
- **Ancef (cefazolin)** — peds **10–30 mg/kg**; surgical-prophylaxis standard is
  ~**30 mg/kg** (low end of 10 seems light).
- **Decadron (dexamethasone)** — peds **0.5 mg/kg**; croup standard is
  **0.6 mg/kg (max 10–16 mg)**.
- **Epi Push / Drip** — mix shown is **1 mcg/mL** (1 mg in 1 L); **push-dose epi**
  is usually **10 mcg/mL (1 mg in 100 mL)**. Confirm the intended prep (push vs
  infusion) and concentration.
- **Rocephin (ceftriaxone)** — **1 g / 25–50 mg/kg**; if the meningitis
  indication is intended, that's **2 g / 100 mg/kg**.
- **TXA** — adult **2 g** bolus; CRASH-2 uses **1 g** bolus + 1 g infusion (2 g
  single bolus is a newer EMS approach — confirm intent).
- **Albuterol** — peds **0.15 mg/kg**; nebulised albuterol is typically a
  **fixed 2.5 mg** regardless of weight — confirm which to show.

---

## ✅ Reviewed, look guideline-consistent (no change proposed)

3% Saline · Afrin · Amiodarone · Aspirin · Ativan* · Atrovent · Benadryl ·
Bicarb · Calcium · CyanoKit · D10 · Dopamine · DuoDote · Etomidate · Fentanyl ·
Glucose · Haldol · Heparin · Ibuprofen · Keppra* · Ketamine · Lasix · Levophed ·
Lidocaine · Lopressor · Magnesium · Morphine · Narcan · Neo Push · Nitro ·
NS Bolus · Propofol · Rocuronium* · Succinylcholine · Tetracaine · Toradol ·
Tylenol · Versed* · Zofran

(* = already updated to evidence in `0268e43`.)

---

## Full dose table (for OE input)

| Drug | Class | Indication | Adult | Peds |
|---|---|---|---|---|
| 3% Saline | Hypertonic Saline | TBI | 250 mL IV/IO | 2–5 mL/kg |
| Adenosine⚠️ | Adenocard | SVT | 12 mg IV/IO | 0.1–0.2 mg/kg |
| Afrin | Oxymetazoline | Nosebleed | 1 spray IN | ≥6 y/o |
| Albuterol🟡 | Ventolin | Wheezing, HyperK | 2.5 mg neb | 0.15 mg/kg |
| Amiodarone | Pacerone | VT/VF | 300 then 150 mg | 5 mg/kg ×3 |
| Ancef🟡 | Cefazolin | Wounds/fx | 2 g IV/IO/IM | 10–30 mg/kg |
| Aspirin | Baby ASA | Angina | 324 mg PO chew | do not use |
| Ativan✅ | Lorazepam | Seizure/sed | 4 mg (SE)/1 mg sed | 0.1 mg/kg SE |
| Atropine⚠️ | AtroPen | Brady, OP-OD | 1 mg (brady) | 0.02 mg/kg |
| Atrovent | Ipratropium | Wheezing | 0.5 mg neb | 0.25 mg <6y |
| Benadryl | Diphenhydramine | Allergy/dystonia | 25–50 mg | 1 mg/kg |
| Bicarb | Na Bicarb | Acidosis | 50 mEq | 1 mEq/kg |
| Calcium | CaCl | HyperK/CCB | 1 g | 20 mg/kg |
| Charcoal🟡 | Activated | Poisoning | 25 g PO | 1 g/kg |
| CyanoKit | Hydroxocobalamin | Cyanide | 5 g/10 min | 70 mg/kg |
| D10 | Dextrose 10% | Hypoglycemia | 100 mL | 5 mL/kg |
| Decadron🟡 | Dexamethasone | Inflammation | 10 mg | 0.5 mg/kg |
| Dopamine | Intropin | Shock | 5 mcg/kg/min | 5 mcg/kg/min |
| DuoDote | Atropine/2-PAM | OP poisoning | auto-inj IM | ≤40 kg N/A |
| Epi⚠️ | Epinephrine | Brady/CODE/allergy | 1 mg IV (CODE) | 0.01 mg/kg |
| Epi Drip🟡 | Epinephrine | Shock | drip (1 mcg/mL) | micro drip |
| Etomidate | Amidate | RSI | 0.3 mg/kg | 0.3 mg/kg (10+) |
| Fentanyl | Sublimaze | Pain | 50–100 mcg | 0.5–2 mcg/kg |
| Glucagon⚠️ | — | Hypogly/BB-OD | 1 mg IM | 0.5 mg <6y |
| Glucose | Oral | Hypoglycemia | 15 g PO | 0.5 g/kg |
| Haldol | Haloperidol | Psychosis | 5 mg IM | 0.075–0.15 mg/kg |
| Heparin | — | STEMI | 5000 u | do not use |
| Ibuprofen | Advil | Fever/pain | 600 mg | 10 mg/kg |
| Keppra✅ | Levetiracetam | SE | 60 mg/kg | 40–60 mg/kg |
| Ketamine | Ketalar | Pain | 20 mg | 0.25–0.5 mg/kg |
| Lasix | Furosemide | CHF | 40 mg | 1–2 mg/kg |
| Levophed | Norepinephrine | Shock | 5–20 mcg/min | 0.05 mcg/kg/min |
| Lidocaine | Xylocaine | IO pain/VT | 10 mg IO | 1–1.5 mg/kg |
| Lopressor | Metoprolol | HTN/tachy | 5 mg | 0.5 mcg/kg/min |
| Magnesium | MgSO4 | TdP/eclampsia | 1–4 g | 25–50 mg/kg |
| Morphine | — | Pain | 2–4 mg | 0.1–0.2 mg/kg |
| Narcan | Naloxone | Opiate OD | 0.04–4 mg | 0.1 mg/kg |
| Neo Push | Phenylephrine | Shock | 50–200 mcg | 5–20 mcg/kg |
| Nitro | Nitroglycerin | Angina/CHF | 0.4 mg SL | — |
| NS Bolus | 0.9% NS | Hypovolemia | 500 mL | 20 mL/kg |
| Propofol | Diprivan | Sedation | 150 mcg/kg/min | 200 mcg/kg/min |
| Rocephin🟡 | Ceftriaxone | Infection | 1 g | 25–50 mg/kg |
| Rocuronium✅ | Zemuron | RSI | 1 mg/kg | 1 mg/kg |
| Succinylcholine | Anectine | RSI | 1.5 mg/kg | 2 mg/kg |
| Tetracaine | 0.5% ophth | Eye pain | 1–2 gtt | 1–2 gtt |
| Toradol | Ketorolac | Pain | 15 mg | 0.5 mg/kg (2+) |
| TXA🟡 | Tranexamic | Bleeding | 2 g | 10–25 mg/kg |
| Tylenol | Acetaminophen | Fever/pain | 1000 mg | 15 mg/kg |
| Versed✅ | Midazolam | Seizure/sed | 10 mg IM SE | 0.1–0.2 mg/kg SE |
| Zofran | Ondansetron | N/V | 4 mg | 0.1 mg/kg |
