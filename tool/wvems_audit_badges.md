# WVEMS 2026 — audit: provider badges, shapes and inline symbols

**Scope of this audit.** The credentialing / scope-callout system of
`2026-WVEMS-Protocols.pdf` (166 pp, 612x1008 pt, printed page N = PDF page N),
measured page by page, compared against what
`/home/grey/dev/fhir/orbweaver-wt` renders today. Audit only — no app file was
modified.

**Method.** Every page rendered with `pdftoppm -r 150` (166 PNGs) and word
bounding boxes extracted with `pdftotext -bbox-layout`. Two *independent*
detectors were run over all 166 pages and cross-checked against each other:

1. **Text-first** — every isolated single-character word (`E`/`A`/`I`/`P`/…),
   with the background colour sampled from the rendered page around the glyph.
2. **Colour-first** — exact-RGB masks (tol 10) for each legend colour, then
   connected-component labelling (row-runs + union-find), giving every coloured
   chip's bounding box, area and aspect ratio, then joined back to the word
   whose centre falls inside it and to the words immediately to its right.

The two agree exactly on the lettered totals — **E 83 / A 70 / I 56** by both
methods, including the p.2 legend chips — so the counts below are measured, not
sampled. The colour detector additionally found one unlettered `#FFD966`
rectangle on p.125 that the text detector correctly ignored; it was inspected
visually and is the edge of a drug-card "Caution" band, not a badge, and is
excluded everywhere below. Colour values are sampled from the rendered page, so
they are what a reader actually sees.

Scratch data (session-scoped, will be gone): `badge_inventory_merged.tsv`,
`components.tsv`, `shape_inventory.tsv`, `badge_candidates.tsv`.

---

## 1. The legend (printed pp.2-3)

### 1.1 Shape vocabulary — p.2, "Protocol Flow and Intervention Symbols"

Six shapes are defined. All six are drawn with a heavy black outline and a drop
shadow.

| Legend label | Shape | Fill (sampled) | Text |
|---|---|---|---|
| **Indications** | stadium / fully-rounded rect | `#CFE2F3` light blue | black |
| **Use Judgement** | diamond | `#E6B8AF` salmon | black |
| **Don't Forget** | stadium / fully-rounded rect | `#D9EAD3` light green | black |
| **Important Note** | trapezoid, wide edge on **top** | `#674EA7` dark purple | **white** |
| **Concept** + `• And Details` | rounded rectangle (r ≈ 12) | `#EFEFEF` light grey | black, bold title + bullets |
| **WARNING** | red octagon (stop sign) | `#CC0000` | **white** |

### 1.2 Provider-level vocabulary — p.2, BLS / ALS strips

The badge is **not** a free-standing chip in the legend: it is a *tile* — a
white label box with a full-height coloured tab fused to its left edge, the
whole thing black-outlined with a drop shadow. Six levels, in two groups.

| Group | Level | Letter | Tab colour (sampled) |
|---|---|---|---|
| **Basic Life Support (BLS)** | EMR | *(none — blank tab)* | `#EFEFEF` pale grey |
| | EMT | `E` | `#FFD966` gold |
| | AEMT | `A` | `#93C47D` green |
| **Advanced Life Support (ALS)** | Intermediate | `I` | `#6FA8DC` blue |
| | Paramedic | `P` | `#D5A6BD` **dusty pink** |
| | Critical Care Paramedic | `P` | **diagonal purple gradient**, ~`#9568FD` → `#BB8FF6` → `#E9BDEE` highlight |

Three things here matter and are easy to miss:

* **EMR has no letter.** Its tab is a blank pale-grey swatch. A blank tab is
  therefore *semantic* ("any level / EMR"), not decoration or a placeholder.
* **Paramedic and Critical Care Paramedic share the letter `P`** and are
  distinguished **only by colour** — flat dusty pink vs. a purple gradient.
* **The flat pink Paramedic badge (`#D5A6BD`) is never used in the body of the
  book.** Measured: `#D5A6BD` occurs on exactly **one** page — p.2, the legend
  itself, 7 056 px, i.e. one chip. Every `P` badge in the 164 body pages is the
  Critical Care gradient. WVEMS marks interventions at the *lowest* level
  cleared for them, and nothing in the 2026 book is paramedic-only-but-not-CC.
  (Atropine on p.12, for instance, is badged `I`, not `P`.)

### 1.3 Guidance text — p.3, "Welcome to the WVEMS Protocols"

p.3 is nine bracketed sections. Seven use the ordinary grey section bracket
with no fill; **Pediatric** sits on a pink band with a pink bracket and
**Critical Care** on a lavender band with a purple bracket — the same two
population/credentialing tints used throughout the book. Content:

| Section lead (bold) | Bullets |
|---|---|
| **Welcome** to the WVEMS Protocols | tool box not a cookbook · use several protocols at once on every call · **you may use any intervention marked for your level or lower** |
| **Basic** procedures are assumed for every call | scene safe, BSI, ABCs, call for ALS, notify ED · full assessment incl. vitals · ask allergies + pregnancy before meds |
| **Call** for online Medical Direction at any time | any question/uncertainty · permission to deviate · if unable to contact, get the patient to the hospital |
| **Protocols** mean you *can*, not always that you *should* | use only enough to stabilise · skip anything unnecessary, not every box need be completed · listed order suggests importance but is not absolute |
| **Severity** is a subjective judgement | not all decisions are black and white · reassess and restart protocols · use clinical sense for precedence |
| **Presume** routine things when appropriate | SpO2, EKG, EtCO2, glucometer, saline lock, phlebotomy · layperson first aid (splinting, band-aids) · protocols may include reminders ("12-Lead") |
| **Pediatric** considerations are in every protocol *(pink band)* | **14 y/o and over = adult therapy** · **1-13 = child, <1 = infant, both peds** · Peds Reference for peds dosing **and adults under 110 lb / 50 kg** |
| **Critical Care (CC)** is for credentialed paramedics only *(lavender band)* | provider must maintain mandatory prerequisites · must be approved **for that specific protocol** by the agency OMD · deadlines expire on the last day of the month (grace period) |
| **References** are included; this text is not comprehensive | medications may appear as brand name® or generic |

That is **1 page title + 9 section leads + 25 bullets = 34 lines of governing
text**.

**Confirmed absent from the app.** Searched `assets/books/wvems/**` and `lib/**`
for `tool box`, `toolbox`, `cookbook`, `level or lower`, `not comprehensive`,
`grace period`, `deviate from these`, `black and white`, `How To Use` — **zero
hits**. The only near-match is the string "Mandatory Prerequisites", which is
the *per-protocol* CC prerequisite list on pp.79-95, not p.3's rule. So **34/34
lines (100%) of p.3 are missing**, including the three rules that make the badge
system mean anything:

* "You may use any intervention marked for **your level or lower**" — without
  this, a badge is decoration; with it, a badge is a permission boundary.
* The 14+ / 1-13 / <1 age bands, which are the general rule behind every
  `Adult (14+) / Child (1-13) / Infant (<1)` row in the book.
* The CC credentialing rules (OMD approval per protocol, prerequisites,
  grace period), which are what the purple `P` actually asserts.

`assets/books/wvems/topics/wvems_2026_about.yaml` *does* carry a
"Provider scope legend" and a "Flow & intervention symbols" section, but both
are plain markdown bullets — no rendered badge, no rendered shape. Its legend
also states `**P** — Paramedic (purple **P** = Critical Care Paramedic)`, which
mis-states the print: print Paramedic is **pink**, purple is CC only.

---

## 2. Inline provider badges in the body — measured inventory

### 2.1 Totals

**363 provider badges** are drawn in the 164 body pages (p.2 legend excluded):

| Badge | Tile band (28 pt wide, full tile height) | Small square (20-28 pt) | Total |
|---|---|---|---|
| `E` EMT gold `#FFD966` | 64 | 18 | **82** |
| `A` AEMT green `#93C47D` | 54 | 15 | **69** |
| `I` Intermediate blue `#6FA8DC` | 32 | 23 | **55** |
| `P` Critical Care purple gradient | 31 | 1 | **32** |
| `P` Paramedic pink `#D5A6BD` | 0 | 0 | **0** |
| *(blank)* EMR pale grey `#EFEFEF` | 124 | 1 | **125** |
| **Total** | **305** | **58** | **363** |

**238 lettered badges spread over 76 pages.** Pages carrying at least one
lettered badge:

> 4, 5, 6, 8, 10, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26,
> 27, 28, 30, 31, 32, 33, 36, 38, 39, 40, 41, 42, 43, 44, 46, 47, 48, 49, 50,
> 51, 52, 54, 56, 58, 63, 66, 68, 69, 70, 76, 78, 80, 82, 84, 86, 88, 90, 92,
> 94, 96, 97, 98, 99, 100, 101, 102, 103, 104, 105, 106, 107, 108, 112, 116,
> 117, 144

### 2.2 The two physical forms

**Form A — "tile band" (305 instances).** A 28 pt-wide, full-tile-height
coloured band fused to the **left edge** of a bordered white tile, letter
centred, black 1 pt border, drop shadow. This is the flowchart action tile and
the procedure title tile. Example p.12: `E` 12-Lead, `A` Saline Lock, `I`
Atropine, `I` Pacing, `I` Epi.

**Form B — "inline square" (58 instances).** A 20-28 pt **square** chip, letter
centred, thin black border, sitting in running text. Three sub-uses, all
measured:

* **B1 — at the head of a prose or band bullet** (most common). Usually the
  whole line is then wrapped in a **dashed rounded rectangle** running to the
  right margin. Examples: p.5 `A` `Consider placing an OG-Tube…` (inside the
  Notes section); **p.43 `A` `Versed: max peds dose is Q 2 min x4 doses`, inside
  the pink Pediatrics band** — this is the case in the brief, and it is
  confirmed exactly as described: small green boxed `A` immediately before
  Versed, inside a dashed box, inside the peds band.
  p.116 shows the same badge form used **without** the dashed box, bare at the
  head of a bullet: `I` `**ALS**: May consider STE > 1 mm…` and `P` `**CC**: May
  consider advanced criteria…`.
* **B2 — first cell of a table row** (p.104, "Antidote Procedures"): a 28 pt
  square badge is the leading column of a 12-row zebra-striped table —
  `I` Atropine, `I` Benadryl, `I` Bicarb, `I` Calcium, *(blank)* Charcoal,
  `A` CyanoKit, `A` D10, *(blank)* DuoDote, `A` Glucagon, `I` Magnesium,
  *(blank)* Narcan, `A` Versed. Nine lettered, three blank. The table also
  carries a rotated dark-grey right-edge tab reading "Adult Antidotes".
* **B3 — prefixed to a section heading** (p.144): a 28 pt gold `E` sits before
  the heading **"EMT Peds Dosing"**, scoping the entire section that follows.
  One instance in the book, but it is a distinct grammar: *badge scopes a
  section*, not a line.

Two more contexts worth naming because they are neither prose nor a tile:

* **Inside a green convergence stadium's bullets** (p.24, "Disposition"):
  `E` `BLS: Get ALS ASAP` and `I` `ALS: Try 30 min…` are badged bullets *inside*
  the terminator node. Same on p.52.
* **Procedure title tile floated top-right of a procedure block** (pp.97-108,
  17 lettered): p.97 shows *(blank)* Glucometer, `E` 12-Lead, `A` Saline Lock —
  the tile band form used as a card header, with the numbered steps to its left.
* **A whole index page built out of badge tiles** — p.96, the Procedures index:
  nine bracketed sections (General / Airway / Breathing / Advanced Adjuncts /
  Resuscitation / Bleeding / Injury / Antidotes / Cardiac / Obstetrics), each
  listing its procedures as tile-band badges (13 lettered, ~12 blank). The page
  doubles as a scope table — you can read "who may do what" off it in one look —
  and it ends with a lavender-washed, purple-bracketed entry `P 107 & 108 •
  Critical Care` pointing at the CC procedures.

### 2.3 The blank (EMR) badge is load-bearing

**125 blank pale-grey badges** were measured (124 tile bands + 1 inline square).
On a flowchart page every action tile gets a band; grey-and-empty means "EMR /
any level". p.4 is the clearest case: `Back Blows & Thrusts`, `Reposition
Airway`, `Suction`, `NPA`, `OPA` all carry a blank band, while `Magill Forceps`
carries `A` and `BIAD` carries `E`.

The one **inline** blank square is **p.41**, and it is unambiguous: two
consecutive dashed-boxed lines, the first with a blank chip
(`May provide premeasured intranasal doses only.` — EMR), the second with a
green `A` (`Titrate dose to resps & SpO2; May start as low as 0.04 mg.`). The
blank chip is doing real work there: it says *this* line is open to everyone
while the next is not.

### 2.4 Per-page inventory

Legend for the table below: `` `X`▮ `` = tile band, `` `X`□ `` = inline square,
`—` = blank/EMR chip. The trailing text is the label extracted immediately to
the right of the chip; where a tile's label wraps to two lines the word order
may read oddly, and a handful of `—` rows on flowchart pages are
adjacent-geometry artefacts rather than chips (they are kept so the table is a
faithful dump of what was detected, not a curated one).

| page | badges (letter · form · what it scopes) |
|---|---|
| 2 | `A`▮ AEMT · `E`▮ EMT · `I`▮ Intermediate · `P(CC)`▮ Critical Paramedic Care · `P(pm)`▮ Paramedic · `—`▮ EMR |
| 4 | `A`▮ Forceps Magill · `E`▮ BIAD · `—`▮ Back &amp; Thrusts Blows · `—`▮ • Breathing · `—`▮ Reposition Airway · `—`▮ Suction · `—`▮ NPA · `—`▮ OPA |
| 5 | `A`□ Consider placing |
| 6 | `E`▮ NIPPV · `I`▮ Decompress Pleural · `—`▮ Position Comfort of · `—`▮ • Airway, Dyspnea · `—`▮ Provide O · `—`▮ BVM Assist · `—`▮ Ventilate BVM · `—`▮ Chest Seal |
| 8 | `A`▮ Saline Lock · `A`▮ NS Bolus · `A`▮ NS Bolus · `E`▮ 12-Lead · `E`▮ 12-Lead · `E`▮ 12-Lead · `I`▮ Epi Drip · `I`▮ Dopamine · `—`▮ Bleeding, Altered Bradycardia |
| 10 | `A`▮ Saline Lock · `E`▮ 12-Lead · `—`▮ Position Comfort of · `—`▮ • Cardiac, Pregnancy, SOB, |
| 12 | `A`▮ Saline Lock · `E`▮ 12-Lead · `E`▮ 12-Lead · `E`▮ 12-Lead · `I`▮ Atropine · `I`▮ Pacing · `I`▮ Epi |
| 13 | `I`□ May try pacer |
| 14 | `A`▮ NS Bolus · `A`▮ NS Bolus · `A`▮ NS Bolus · `E`▮ 12-Lead · `E`▮ 12-Lead · `E`▮ 12-Lead · `I`▮ Adenosine If QRS ≤ 120 ms · `I`▮ If Amio QRS &gt; 120 Adult · `I`▮ Cardiovert · `I`▮ Magnesium If Torsades · `—`▮ A NS Bolus |
| 15 | `I`□ May try vagal |
| 16 | `A`▮ NS Bolus · `E`▮ Tylenol · `E`▮ Ibuprofen · `—`▮ Position Comfort of · `—`▮ • • Circulation, Cold / Heat |
| 17 | `A`□ May give PO or · `E`□ May only give |
| 18 | `A`▮ Saline Lock · `A`▮ NS Bolus · `E`▮ 12-Lead · `E`▮ Albuterol · `I`▮ Calcium |
| 19 | `I`□ Bicarb (Sodium |
| 20 | `A`▮ Toradol · `A`▮ Fentanyl · `E`▮ Tylenol · `E`▮ Ibuprofen · `E`▮ Tylenol · `I`▮ Ketamine |
| 21 | `A`□ May give PO or · `E`□ May only give · `E`□ Tetracaine |
| 22 | `E`▮ Zofran · `—`▮ Keep NPO |
| 23 | `A`□ Alternate 4-10y/o · `E`□ May only give |
| 24 | `I`▮ Epi · `I`▮ Amio If VT/VF · `—`▮ Compression Chest · `—`▮ If Deﬁb Advised · `E`□ BLS: Get ALS · `I`□ ALS: Try 30 |
| 25 | `E`□ BLS: Get ALS · `I`□ ALS: Try for 30 · `I`□ Magnesium |
| 26 | `A`▮ Saline Lock · `E`▮ 12-Lead · `I`▮ Ketamine If Agitated · `—`▮ Glucometer |
| 27 | `I`□ Amiodarone |
| 28 | `A`▮ Saline Lock · `A`▮ Saline Lock · `E`▮ 12-Lead · `E`▮ Aspirin Adult · `E`▮ 12-Lead · `E`▮ Aspirin Adult · `E`▮ Nitro Adult · `—`▮ · `—`▮ · `—`▮ |
| 30 | `A`▮ Epi Neb · `A`▮ Decadron · `A`▮ Nitro Adult · `E`▮ Albuterol · `E`▮ Atrovent · `—`▮ Position Comfort of · `—`▮ |
| 31 | `I`□ Magnesium |
| 32 | `A`▮ Decadron · `E`▮ Albuterol · `E`▮ Atrovent · `E`▮ Benadryl · `E`▮ Epi · `E`▮ Albuterol · `E`▮ Atrovent · `E`▮ Benadryl |
| 33 | `A`□ Use IM meds · `E`□ May only use · `E`□ May only give · `I`□ Consider an Epi |
| 36 | `A`▮ Saline Lock · `E`▮ 12-Lead · `—`▮ Glucometer |
| 38 | `A`▮ D10 · `A`▮ NS Bolus · `E`▮ Glucose Oral · `E`▮ Glucagon · `E`▮ 12-Lead · `E`▮ 12-Lead · `—`▮ |
| 39 | `E`□ Baqsimi® |
| 40 | `A`▮ Saline Lock · `A`▮ NS Bolus · `E`▮ 12-Lead · `—`▮ Narcan If hypoxic · `—`▮ Administer Antidote |
| 41 | `A`□ Titrate dose to |
| 42 | `A`▮ Saline Lock · `A`▮ Versed · `A`▮ If Keppra Refractory · `I`▮ Magnesium If Pregnant · `—`▮ Glucometer |
| 43 | `A`□ Versed: max |
| 44 | `A`▮ Saline Lock · `E`▮ 12-Lead · `—`▮ Last Ask Normal Time · `—`▮ Do Survey Stroke · `—`▮ Head Elevate of Bed · `—`▮ Glucometer |
| 46 | `I`▮ Versed · `I`▮ Versed · `I`▮ Haldol · `—`▮ Position Comfort of · `—`▮ Call Police |
| 47 | `I`□ Benadryl ® · `I`□ Versed: max |
| 48 | `A`▮ NS Bolus · `A`▮ Saline Lock · `A`▮ NS Bolus · `E`▮ Deliver Baby · `E`▮ Emergent Transport · `E`▮ Complication Manage OB · `—`▮ Left Recumbent Lateral · `—`▮ Neonate Manage · `—`▮ Don’t Push |
| 49 | `A`□ If poor perfusion: |
| 50 | `I`▮ Epi · `—`▮ APGAR · `—`▮ Breastfeeding Encourage · `—`▮ Warm Stimulate, &amp; Dry · `—`▮ Provide O · `—`▮ T-piece Assist · `—`▮ Glucometer · `—`▮ Provide O · `—`▮ T-piece Ventilate · `—`▮ Compression Chest |
| 51 | `I`□ EKG can provide |
| 52 | `A`▮ NS Bolus · `I`▮ Decompress Pleural · `I`▮ Epi · `I`▮ Amio If VT/VF · `—`▮ Compression Chest · `—`▮ Tourniquet · `—`▮ If Deﬁb Advised |
| 54 | `A`▮ Saline Lock · `E`▮ Emergent Transport · `E`▮ 12-Lead · `I`▮ Decompress Pleural · `I`▮ Ketamine If Agitated · `—`▮ • • Bleeding, Medical ROSC Shock · `—`▮ Tourniquet |
| 56 | `A`▮ NS Bolus · `A`▮ If Major Ancef Wound · `E`▮ Emergent Transport · `I`▮ Decompress Pleural · `—`▮ Tourniquet · `—`▮ Chest Seal · `—`▮ • • Bleeding, Breathing, Pain Shoc |
| 58 | `A`▮ TXA · `—`▮ Wound Care · `—`▮ • • Breathing, Major Trauma · `—`▮ Pressure Direct · `—`▮ Tourniquet · `—`▮ Packing Wound |
| 60 | `—`▮ Spine Clear · `—`▮ C-collar SMR with |
| 63 | `E`□ Tetracaine |
| 66 | `A`▮ If Open Ancef Fracture · `E`▮ Deformity Reduce · `E`▮ Emergent Transport · `—`▮ Wound Care · `—`▮ Splint · `—`▮ Ice Pack · `—`▮ Splint |
| 68 | `A`▮ NS Bolus · `A`▮ NS Bolus · `E`▮ 12-Lead · `—`▮ Warming Active · `—`▮ Glucometer · `—`▮ Techniques Passive · `—`▮ Cooling Active |
| 69 | `A`□ If shivering from · `E`□ Ibuprofen |
| 70 | `A`▮ NS Bolus · `—`▮ Position Comfort of · `—`▮ Stop Burning the · `—`▮ Wound Care |
| 72 | `—`▮ • • Breathing, OD / Tox · `—`▮ from Remove Harm · `—`▮ Provide O |
| 74 | `—`▮ Splint · `—`▮ Removal Stinger |
| 76 | `A`▮ TXA Adult · `A`▮ Saline Lock · `E`▮ Afrin · `—`▮ Pressure Direct · `—`▮ Pressure Direct · `—`▮ |
| 78 | `P(CC)`▮ Intubate Adult · `P(CC)`▮ Induce · `P(CC)`▮ Paralyze · `P(CC)`▮ BIAD · `P(CC)`▮ Bougie Cric Adult · `P(CC)`▮ Needle Cric Peds · `—`▮ P BIAD · `—`▮ |
| 80 | `P(CC)`▮ Versed · `P(CC)`▮ Fentanyl · `P(CC)`▮ Propofol · `P(CC)`▮ Ventilator · `P(CC)`▮ Ketamine |
| 82 | `P(CC)`▮ Levophed · `P(CC)`▮ Epi Push · `P(CC)`▮ Neo Push |
| 84 | `A`▮ NS Bolus · `A`▮ NS Bolus · `P(CC)`▮ Blood · `—`▮ Bleeding Stop the |
| 86 | `P(CC)`▮ 3% Saline · `P(CC)`▮ Keppra · `—`▮ Head Treat Injury as |
| 88 | `P(CC)`▮ 15-Lead If Indicated · `P(CC)`▮ Sgarbossa V-pace or LBBB · `P(CC)`▮ Heparin Adult · `—`▮ Chest Treat Pain for · `—`▮ |
| 90 | `P(CC)`▮ Nitro Drip Adult · `P(CC)`▮ Lasix · `—`▮ Dyspnea Treat as · `—`▮ |
| 92 | `P(CC)`▮ Lopressor · `P(CC)`▮ Magnesium If Pregnant · `—`▮ Hypertension Treat as |
| 94 | `P(CC)`▮ POC Lactic · `P(CC)`▮ Cultures Blood · `P(CC)`▮ Rocephin · `—`▮ Monitor Closely |
| 96 | `A`▮ Saline Lock · `A`▮ OG-Tube · `A`▮ Forceps Magill · `A`▮ I O · `E`▮ 12-Lead · `E`▮ BIAD · `E`▮ Deformity Reduce · `E`▮ Deliver Baby · `E`▮ Complication Manage OB · `E`▮ NIPPV · `I`▮ Decompress Pleural · `I`▮ Pacing · `I`▮ Cardiovert · `—`▮ Glucometer · `—`▮ C-collar SMR with · `—`▮ Splint · `—`▮ Removal Stinger · `—`▮ Back &amp; Thrusts Blows · `—`▮ Suction · `—`▮ Compression Chest · `—`▮ Deﬁb · `—`▮ Administer Antidote · `—`▮ Wound Care · `—`▮ Tourniquet · `—`▮ Packing Wound · `—`▮ BVM · `—`▮ OPA / NPA |
| 97 | `A`▮ Saline Lock · `E`▮ 12-Lead · `—`▮ Glucometer · `E`□ May read machine · `I`□ May interpret |
| 98 | `A`▮ Forceps Magill · `—`▮ Back &amp; Thrusts Blows · `—`▮ Suction · `E`□ Nasal/BIAD/ETT/trach/stoma: · `E`□ Consider detailed |
| 99 | `E`▮ NIPPV · `—`▮ BVM · `—`▮ NPA / OPA · `I`□ Consider treatment |
| 100 | `A`▮ OG-Tube · `E`▮ BIAD · `I`▮ Decompress Pleural |
| 101 | `A`▮ I O · `—`▮ Compression Chest · `—`▮ Deﬁb · `A`□ Lidocaine: · `E`□ Use AED “analyze” · `I`□ May interpret |
| 102 | `—`▮ Wound Care · `—`▮ Tourniquet · `—`▮ Packing Wound · `E`□ May use hemostatic |
| 103 | `E`▮ Deformity Reduce · `—`▮ C-collar SMR with · `—`▮ Splint · `—`▮ Removal Stinger |
| 104 | `—`▮ Administer Antidote · `A`□ CyanoKit: · `A`□ D10: · `A`□ Glucagon: · `A`□ Versed: · `I`□ Atropine: · `I`□ Benadryl: · `I`□ Bicarb: · `I`□ Calcium: · `I`□ Magnesium: · `—`□ Charcoal: |
| 105 | `I`▮ Pacing · `I`▮ Cardiovert |
| 106 | `E`▮ Complication Manage OB · `E`▮ Deliver Baby · `A`□ If poor perfusion: |
| 107 | `P(CC)`▮ Checklist RSI Prep · `P(CC)`▮ Ventilator |
| 108 | `P(CC)`▮ Cric · `P(CC)`▮ Thoracostomy Finger |
| 109 | `—`▮ Dec Reviewed: · `—`▮ Dec Reviewed: |
| 112 | `E`□ BLS should try · `I`□ ALS should resuscitate |
| 116 | `I`□ ALS: May consider · `P(CC)`□ CC: May consider |
| 117 | `I`□ Asystole in at |
| 130 | `—`□ |
| 144 | `E`□ EMT Peds |

### 2.5 Where badges are *not* used

* **Drug Reference, pp.118-143** — 26 pages, ~50 drug cards, **zero provider
  badges**. Cards are Use / Caution / Notes bands with rotated sidebar labels.
  Scope is carried by the "Protocols:" cross-reference line, not a badge.
* **Peds Reference, pp.145-161** — zero badges. Scope here is the Handtevy
  colour-zone system (see §4.4).
* **Index, pp.162-166** — zero badges.
* p.144 is the single exception in the appendices (the `E` heading badge).

---

## 3. The shape vocabulary — measured usage

All counts are connected components of the exact legend fill colour, area
>= 8 000 px @150 dpi, joined to the words inside them. Legend instances on p.2
are excluded from the body counts.

| Shape | Fill | Body instances | Body pages | Printed size |
|---|---|---|---|---|
| Entry stadium ("Indications") | `#CFE2F3` | **46** | 46 | 250 x 99 pt, fixed |
| Decision diamond ("Use Judgement") | `#E6B8AF` | **41** | 41 | 196 x 81 pt, fixed |
| Convergence stadium ("Don't Forget") | `#D9EAD3` | **54** | 47 | 250 x 87 pt |
| Important-Note trapezoid | `#674EA7` | **24** | 23 | 122 x 75 pt, fixed |
| WARNING octagon | `#CC0000` | **10** | 7 | 87 x 87 pt, fixed |
| Concept box | `#EFEFEF` | **33** | 24 | variable, r ≈ 12 |

### 3.1 Entry stadium — 46, one per protocol flowchart

Exactly one on every even protocol page 4-94; none anywhere else. Text is the
indication ("Choking, Unstable or Unresponsive", "Cardiac Chest Discomfort",
"Suspected Organ Dysfunction from Infection"…).

Six pages (**8, 10, 12, 14, 82, 92**) use a **zebra-striped variant**: the
stadium body is split into alternating light-blue rows, one per age band —
`Adult (14+) / Child (1-13) / Infant (<1)` with a threshold on each row. That
striping is itself a population marker sitting inside the entry shape.

### 3.2 Decision diamond — 41

Fixed 196 x 81 pt on every page that has one. Label census: `Severity?` x21,
`Cause?` x5 (incl. two pages with a second diamond), `Technique?` x2,
`Assign Jobs` x2, and one each of `Active?`, `Alternate <30 min?`,
`Attempt`, `Delivery?`, `Distal Pulses?`, `GCS?`, `Indications?`, `Injury?`,
`Level?`, `Location?`, `Priorities`, `Pulse?`, `Response?`.

### 3.3 Convergence stadium — 54

Almost always labelled **`Consider`** with two bullet rows of cross-links
(p.12: "• Pain, Breathing, Hyper K+ / • Shock, N/V, OD / Tox"). Variants:
`Disposition` (pp.24, 52) and, on **p.36 only**, eight green stadiums used as
*branch headers* (Behavioral / Cardiac / Diabetic / Fever / Injury /
Overdose-Tox / Seizure / Stroke) — a second, distinct use of the shape.

**19 of these stadiums carry a lavender Critical-Care sub-tab** fused to their
bottom edge (189 x 25 pt, `#D9D2E9`), holding one extra CC-only cross-link.
Pages: 4, 6, 8, 10, 16, 26, 28, 30, 34, 36, 42, 48, 54, 56, 58, 62, 72, 86, 90.
p.72 is the clearest: green `Consider · Breathing, Shock · OD/Tox, Antidote`
with a lavender tab under it reading `• Intubation`.

### 3.4 Important-Note trapezoid — 24

Wide edge on top, `#674EA7` fill, white text, always on the **right** of the
flow. Only two strings in the whole book:

* **`Consider Destination Triage`** — 15x, pp.18, 26, 28, 44, 48, 54, 56, 58,
  66, 70, 86, 88, 106, 113, 116
* **`Use Caution if Patient Refusal`** — 9x, pp.32, 36, 38, 40, 46, 48, 50, 74, 92

(p.48 carries both.)

### 3.5 WARNING octagon — 10 on 7 pages

`#CC0000`, white text, always on the **left** of the flow. Three strings:

* **`Ensure Provider SAFETY`** — 6x, pp.40, 42, 46, 70, 72, 74
* **`Ensure Patient DECON`** — 3x, pp.40, 70, 72
* **`Need TWO RSI Medics`** — 1x, p.78

**DECON is not a separate glyph.** It is the red octagon with `Ensure Patient
DECON` in it. Likewise there is no separate "TRAUMA Alert marker" — see §4.2.

> **Caveat on colour reuse.** `#CC0000` and `#674EA7` also appear on
> pp.144-161 as the **RED** and **PURPLE** Handtevy colour zones (see §4.4), and
> `#D9EAD3` appears on pp.119-143 as the drug card "Use" band (50 instances).
> Those are *not* shapes and are excluded from the counts above.

### 3.6 Concept box — 33 on 24 pages

Rounded rectangle, `#EFEFEF` fill, heavy black border, bold centred title over
bullets. 33 in the protocol/procedure/drug range. Several are **reused
verbatim** across pages — `Poor Perfusion` alone appears **10 times** (pp.5, 9,
13, 15, 17, 33, 55, 57, 59, 83). Others: `Compressions`, `Obvious Death`,
`Mortal Injuries`, `Cincinnati Stroke`, `Must have Arm Drift` (Stroke VAN),
`PDE5 Inhibitors`, `Anticoag Meds`,
`Cushing's Triad`, `K+ EKG Changes`, `Critical Arrhythmia`, `Active Warming`,
`Active Cooling`, `Organ Dysfunction`, `Suspect Infection`, `Special Cases`,
`ALS Termination`, `BLS Termination`, `ABLS rate`, `BVM Rate`, `Shock Index`.

A Concept box can carry a **population tint per row**: p.71's `ABLS rate:` box
has row 1 (`14+ y/o: 500 mL/hr`) on grey and rows 2-3 (`6-13`, `0-5`) on pink.

---

## 4. Inline glyphs that are not text

### 4.1 The "Call ER" tile — 12 instances, recurring, semantic

A white rounded card drawn as a phone handset (heavy black outline), containing
the word **`Call`**, a bright-green rounded square (`#01FE01`) with a white
telephone glyph, and bold red **`ER`**. It always sits immediately to the right
of a dashed-box run whose last bullet is `Call a <X> Alert`.

Measured by masking the green `#01FE01`: exactly **12 pages** — 29, 45, 53, 55,
57, 59, 63, 65, 67, 71, 89, 95. The green square is 49 x 49 px @150 dpi
(~23.5 pt) on every one of them, i.e. the tile is a fixed reusable asset.

Which alert it pairs with: `STEMI Alert` pp.29, 89 · `STROKE Alert` p.45 ·
`TRAUMA Alert` pp.53, 55, 57, 59, 63, 65, 67, 71 · p.95 has the tile with a
`Call a` line that extracts without a named alert (Sepsis page).

**Verdict: semantic.** It is a recurring visual verb ("phone the receiving ED
and pre-alert"). It should be a themed vector, not a raster — it has a
fixed geometry, appears on 12 pages, and its meaning (`Call a __ Alert`) is
parameterised by one word.

### 4.2 TRAUMA / STEMI / STROKE Alert markers

There is **no separate alert badge**. The marker is the composition
`dashed rounded box { bullets… "Call a **TRAUMA Alert**" } + Call-ER tile`.
p.71 is the canonical form:

```
┌ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ┐  ┌────────┐
  • If Major Intervention             │  Call  │
  • Or Major Mechanism                │  [green│
  • Call a **TRAUMA Alert**           │  phone]│
└ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ┘  │   ER   │
                                      └────────┘
```

**Verdict: semantic** (the dashed box + tile pairing), one-off only in its
bullet wording.

### 4.3 The Rule-of-Nines figures and the palm glyph — p.71

Two black human silhouettes (front / back) with white percentage numerals
(18/9/14…), plus a black **hand/palm** glyph with a white `1` in it, keyed to
the Notes bullet "Patient's palm (with fingers) is about 1% BSA". Drawn as
vector art in the PDF but used exactly once.

**Verdict: one-off content figure** — fine as a raster image asset. It is not
part of a recurring vocabulary. **Already done correctly:**
`assets/books/wvems/images/bsa_rule_of_nines.png`, used from
`wvems_2026_070.yaml`.

### 4.4 Handtevy colour zones — pp.144-161

p.144 carries an 17-row index table mapping age → page → **colour zone**
(grey Premie/0-3 mo, pink 4-5 mo, red 6-11 mo, purple 1 yr, yellow 2 yr, white
3-4 yr, blue 5-6 yr, orange 7-8 yr, green 9-13 yr), and each of pp.145-161
repeats its zone colour as a full-height right-edge tab (25 x 295 px) plus a
zone name in the header. This is a *third* scope system in the book (age/weight
zone), independent of provider level and of the peds/adult population tint.

**Verdict: semantic**, but it is a self-contained system confined to 18 pages.
Note the app deliberately does not reproduce Handtevy's tables (see
`wvems_2026_about.yaml`, "About this digital edition").

### 4.5 Population (Adult / Peds) markers — adjacent to badges, same grammar

These are *not* provider badges but they use the same "coloured chip fused to a
tile" grammar and will collide with it visually if the badge work ignores them.

| Marker | Form | Count |
|---|---|---|
| Dose-strip **Adult** tab | dark grey `#666666` right-edge tab, white text; row fill `#EFEFEF` | **72 tabs on 35 pages** |
| Dose-strip **Peds** tab | magenta `#D23282` right-edge tab, white text; row fill `#FFDCE2` | **3 tabs on 3 pages** (12, 24, 50) |
| Action-tile **Peds** side tab | pink `#FFC0CB` full-height tab on the tile's **right** edge, rotated black `Peds` | **3** (pp.12, 50, 78) |
| **Pediatrics** band | `#FFC0CB` body tint + magenta bracket | **73 pages** |
| **Critical Care** band | `#D9D2E9` body tint + purple bracket | **20 pages** as a full-width prose wash (3, 5, 7, 9, 11, 17, 27, 29, 31, 35, 37, 43, 49, 55, 57, 59, 63, 73, 100, 116); plus the whole CC chapter pp.78-94 and drug pages |

The action-tile Peds side tab is the mirror image of the provider badge: same
28 pt band, same full tile height, but on the right and pink. p.12's `I` `Epi`
tile carries both at once — blue `I` on the left, pink `Peds` on the right.

---

## 5. What the app renders today

### 5.1 The two places a badge can actually be drawn

There are exactly **two** badge widgets in the codebase.

**`_ProviderBadge`** — `lib/widgets/flowchart/branch_column.dart:366-410`.
A 26 px-wide, full-height coloured band with a 1 px black right border, letter
centred at 16 px w800, fused to the left of an `ActionTile`. This is a faithful
translation of the print's tile band (§2.2 Form A), including the blank-band
placeholder for `ProviderLevel.any`. Driven by `provider_level:` in YAML.

**`_ScopeChip`** — `lib/widgets/blocks/procedure_card_block_view.dart:313-352`.
A square chip, `BorderRadius.circular(4)`, `Colors.black26` border, letter at
0.62 × size, w800. Used twice: in a `procedure_card` header (next to the
procedure name) and inline on a step, driven by the `[E]` / `[A]` / `[I]` /
`[P]` prefix mini-syntax documented at `lib/models/topic.dart:1781`. The `:`
prefix adds the dashed border and `~` makes it a standalone note — together
these reproduce the print's "dashed box + inline square" idiom (§2.2 B1) well.

**Nothing else can render a badge.** Verified by grep for
`scope|badge|Badge|provider` across `table_block_view.dart`,
`prose_block_view.dart`, `drug_card_block_view.dart`, `dose_table.dart`,
`band_callout_block_view.dart` — **zero hits in all five**.

**`mini_markdown.dart` has no badge concept.** Its entire inline grammar is
`**bold**`, `[text](target)`, bare URLs, `- ` bullets and blank-line paragraph
gaps (`_parseInline`, lines 160-223). Since prose blocks, band callouts and
table cells all render their text through `MiniMarkdown`, a badge is
**structurally impossible** in any of them today.

### 5.2 How the 42-odd inline scope markers in the YAML are actually authored

Counting every scope-looking marker in `assets/books/wvems/**`:

| Authoring form | Count | Renders as |
|---|---|---|
| `provider_level: "X"` on a flow action | **146** | real badge (tile band) ✔ |
| `scope: "X"` on a `procedure_card` | **17** | real chip in the card header ✔ |
| `[X]` prefix inside a `procedure_card` step | **19** | real inline chip ✔ |
| `**X**` at the head of a prose / band bullet | **13** | **literal bold letter, no chip** ✘ |
| `(X)` at the head of a prose / band bullet | **8** | **literal parenthesised letter** ✘ |
| `(X)` inside a flow-node `text:` string | **3** | **literal text inside the tile label** ✘ |

The 24 markers in the last three rows are the print's inline square badges
degraded to plain characters. Examples, each matched to its printed page:

* `wvems_2026_042.yaml:152` — `- **A** Versed: max peds dose is **Q 2 min x4 doses**.`
  → print p.43 renders a green boxed `A` inside a dashed box inside the pink
  Pediatrics band. The app renders the two asterisk-bolded characters `A`.
* `wvems_2026_004.yaml:135` — `- **A** Consider placing an **OG-Tube**…` → print p.5.
* `wvems_2026_020.yaml:142-152` — three markers → print p.21 (`E`, `A`, `E`).
* `wvems_2026_109.yaml:250` — `- **CC** (Critical Care): May consider advanced
  criteria…` → print p.116 renders the **purple-gradient `P`** chip on a
  lavender line. The app renders the letters `CC`.
* `wvems_2026_066.yaml:88` — `- text: "Ancef (A) — If Open Fracture"` → print
  p.66 gives this tile a real green `A` band. Same bug in
  `wvems_2026_084.yaml:44` (`"(A) NS Bolus"`) and `wvems_2026_094.yaml:42`
  (`"(P) POC Lactic"`).

### 5.3 Flowchart tile bands — near-complete, 5 discrepancies

Per-page comparison of print tile-band badges vs `provider_level:` entries,
pages 4-94:

* **41 of 46 pages match exactly**, letter for letter.
* **5 pages are one badge short**: p.48 (missing an `E`), p.66 (`A` authored as
  the literal text `Ancef (A)`), p.80 (missing a `P`), p.84 (`A` authored as
  `"(A) NS Bolus"`), p.94 (`P` authored as `"(P) POC Lactic"`).
* p.96 shows 13 print tile bands and 0 `provider_level:` — expected, because
  the procedures section is authored as `procedure_card`s with `scope:`
  (17 of them) rather than flow actions.

This dimension is in good shape. The gap is inline, not structural.

### 5.4 Colour fidelity

`lib/theme/palette.dart:36-41` vs the print:

| Role | App | Print | Δ |
|---|---|---|---|
| `provider_emt` (`E`) | `#F2C24A` | `#FFD966` | app is darker / more saturated |
| `provider_als` (`A`) | `#7BBF86` | `#93C47D` | different hue (app cooler) |
| `provider_intermediate` (`I`) | `#6FAADB` | `#6FA8DC` | effectively identical ✔ |
| `provider_paramedic` (`P`) | `#AB91D8` **lavender** | `#D5A6BD` **dusty pink** | **wrong family** |
| `provider_any` (blank) | `#E0E0E0` | `#EFEFEF` | app is darker |
| *(no role)* Critical Care `P` | — | purple **gradient** | **missing entirely** |

The `provider_paramedic` / Critical Care problem is the substantive one, not the
hex drift. `ProviderLevel` (`lib/models/topic.dart:68-82`) has five members
(`als`, `emt`, `intermediate`, `paramedic`, `any`) and **no Critical Care
member**; `'P' => paramedic` maps both printed levels onto one lavender colour.
That happens to *look* right for the CC chapter (pp.78-95, where every `P` is
in fact Critical Care) and would look wrong the moment a genuine
paramedic-but-not-CC badge appeared. It also makes the app's own legend text in
`wvems_2026_about.yaml` self-contradictory: it says purple `P` = Critical Care,
but every `P` the app draws is purple.

Also note the enum member name `als` maps to the letter `A` = **AEMT**, which is
a *Basic* Life Support level in the print (p.2 puts EMR/EMT/AEMT under BLS and
Intermediate/Paramedic/CC under ALS). The name is actively misleading.

### 5.5 Shapes, warnings and bands — mostly present

* `NodeShape` (`topic.dart:34-47`) has `stadium`, `diamond`, `rectangle`,
  `roundedRectangle`. Entry stadium (`flow_entry`), decision diamond
  (`flow_decision`) and convergence stadium (`flow_convergence`) are all
  themed roles and used. ✔
* `WarningType.safety` → red octagon and `WarningType.caution` → purple
  trapezoid exist (`warning_callouts.dart`), with the doc comment quoting the
  exact printed strings. YAML has 12 `Consider Destination Triage` (print 15 —
  the 3 missing are on pp.106/113/116, which are not app topics), 8
  `Use Caution if Patient Refusal` (print 9), 6 `Ensure Provider SAFETY`
  (print 6 ✔), 2 `Ensure Patient DECON` (print 3), 1 `Need TWO RSI Medics`
  (print 1 ✔). **Two genuine omissions**: one Refusal trapezoid and one DECON
  octagon.
* Concept box → `prose` with `boxed: true`. ✔ (Present as a capability; not
  audited here for per-page coverage.)
* Peds / CC bands → `band_callout` with `band: "peds"` / `"critical_care"`.
  YAML has **45 peds** bands (print: pink band on 73 pages, ~46 of them inside
  the app's page range) ✔ and **8 critical_care** bands against **20** printed
  full-width lavender CC runs. The **12 missing CC bands** are on print pages
  11, 13, 15, 19, 27, 29, 31, 37, 43, 49, 63, 73 — i.e. topics `010`, `012`,
  `014`, `018`, `026`, `028`, `030`, `036`, `042`, `048`, `062`, `072`.
  p.43's is a concrete example: `- Consider **Preeclampsia** if indicated and
  credentialed for CC.` sits inside the plain Medications prose block in
  `wvems_2026_042.yaml:134`, where the print puts it on a lavender wash.
* Critical-Care sub-tab under a convergence stadium → `critical_care_link:` +
  `_CriticalCareLinkPill` (`flowchart_view.dart:1075-1105`) ✔ — but used in
  only **2** topics (`034`, `036`) against **19** printed instances, and drawn
  as a free-floating rounded pill rather than a rectangular tab fused to the
  stadium's bottom edge.
* Dose-row population markers → `dose_table.dart` draws a full-width `Adult` /
  `Peds` **section band above** the rows; the print uses a coloured **right-edge
  tab on each row** plus a row tint. Different form, same meaning.
* The action-tile pink `Peds` **right-edge** side tab (3 instances, pp.12, 50,
  78) has **no representation at all** — `ActionTile` has a left badge and a
  mirror-width invisible spacer on the right.
* **Alert markers** (§4.1/4.2) *are* represented, as `prose` with
  `callout: true` — an amber card with the title in a solid amber pill.
  11 in the YAML (`TRAUMA Alert` x8 in topics 052/054/056/058/062/064/066/070,
  `STROKE Alert` in 044, `STEMI Alert` in 088, `SEPSIS Alert` in 094) against
  **12** printed Call-ER pages; the missing one is **print p.29** (STEMI, topic
  028). The **Call-ER phone tile itself has no representation** — grepped `lib/`
  and `assets/books/wvems/` for any Call-ER widget or asset: none. The amber
  card is the app's own invention; the print's box is a plain **dashed grey
  outline with no fill**, and all of its visual weight comes from the phone tile
  beside it.
* `ProseBlock.dashed` exists (`prose_block_view.dart:74-90`, doc comment cites
  p.71 and p.43 explicitly) but **`dashed: true` appears zero times** in the
  WVEMS YAML — so every alert box and every scoped callout renders solid.
* **Concept boxes are authored as amber callouts, not as Concept boxes.**
  `callout: true` is used **31** times in the WVEMS book — including
  `Poor Perfusion`, `Compressions`, `Cushing's Triad`, `ABLS rate`,
  `Anticoag Meds`, `Cincinnati Stroke`, `Stroke VAN`, `Shock Index`,
  `BVM Rate` — while `boxed: true` (the neutral rounded tile that matches the
  print's grey Concept box) is used **5** times, none of them on a protocol
  page. The print keeps *reference detail* (grey Concept) visually distinct from
  *act now* (red octagon) and *caveat* (purple trapezoid); rendering all the
  Concept boxes in attention-amber collapses that distinction.
* The **Rule-of-Nines silhouettes and the palm 1% glyph are present** and
  correctly handled — recreated as a single raster,
  `assets/books/wvems/images/bsa_rule_of_nines.png`, used once from
  `wvems_2026_070.yaml:124`. Verified by opening it: both silhouettes, all the
  percentages and the dashed palm glyph with the `1` are there.

---

## 6. Summary — KEEP / DROP / ADAPT

**KEEP** = the app already does this and it matches the print; leave it alone.
**ADAPT** = the vocabulary exists in the app but the form, colour or coverage
is wrong; change it. **DROP** = present in the print, absent from the app;
add it (or make a deliberate decision not to).

### 6.1 Provider badges

| # | Item | Print evidence | App today | Verdict |
|---|---|---|---|---|
| 1 | Tile-band badge on flow action tiles | 305 instances, 46 protocol pages | `_ProviderBadge`, 146 `provider_level:` entries, 41/46 pages exact | **KEEP** |
| 2 | Blank pale-grey band = EMR | 124 tile bands | `ProviderLevel.any` renders a blank band | **KEEP** |
| 3 | Procedure-card scope chip | pp.97-108, **17** procedure title tiles | `scope:` + `_ScopeChip`, **17** uses | **KEEP** — exact match (form differs: print floats a tile top-right of the card, app puts a chip in a header row) |
| 3b | **p.96 procedures index grid** — 9 bracketed sections, every procedure listed as a badge tile (13 lettered + ~12 blank) | p.96 | the app uses a book-level `view: "index"` with no badges | **ADAPT → decide** — the printed index is itself a scope table ("who may do what", at a glance) |
| 4 | Inline square chip in a procedure step, dashed box | pp.97-106, **19** squares | `[X]` / `:[X]` / `~[X]`, **19** uses in `wvems_2026_096.yaml` | **KEEP** — exact match |
| 4b | Same, on the **policy** pages | pp.112, 116, 117 — **5** squares (`E`,`I` / `I`,`P(CC)` / `I`) | `wvems_2026_109.yaml` has **0** chips; one is degraded to `**CC**` text, four have no marker | **DROP → add** |
| 5 | Inline square chip **in prose / band bullets** | pp.5, 13, 15, 17, 19, 21, 23, 25, 27, 31, 33, 39, 41, 43, 47, 49, 51, 63, 69 — **30 lettered + 1 blank (p.41)** | **impossible**: `MiniMarkdown` has no badge span; authored as literal `**A**` (13x) or `(A)` (8x) | **DROP → add** |
| 6 | Inline square chip **in a table cell** | p.104, 9 lettered + 3 blank, leading column | re-authored as a `procedure_card` with `~[X]` notes — chips do render | **ADAPT** (content preserved, structure changed; acceptable, but `table` still cannot hold a badge) |
| 7 | Inline square chip **prefixed to a section heading** | p.144 `E` before "EMT Peds Dosing" | plain prose title, no badge | **DROP → add** |
| 8 | Badge inside a convergence-stadium bullet | pp.24, 52 (`E` BLS…, `I` ALS…) | flow bullets are plain text | **DROP → add** |
| 9 | Badge inside a flow-tile *label* authored as text | print gives the tile a real band on pp.66, 84, 94 | `"Ancef (A) …"`, `"(A) NS Bolus"`, `"(P) POC Lactic"` | **ADAPT** — move to `provider_level:` (3 one-line fixes) |
| 10 | Two missing flow badges | p.48 (an `E`), p.80 (a `P`) | absent | **DROP → add** |
| 11 | `P` Paramedic pink vs `P` Critical Care gradient | print: pink `#D5A6BD` (legend only, 0 body uses) vs purple gradient (32 body uses) | one `ProviderLevel.paramedic` → lavender `#AB91D8` for both | **ADAPT** — add a `criticalCare` level; give `paramedic` the pink and CC the purple, so the two `P`s are distinguishable if a pink `P` ever appears |
| 12 | Badge fill hexes | `#FFD966` / `#93C47D` / `#6FA8DC` / `#EFEFEF` | `#F2C24A` / `#7BBF86` / `#6FAADB` / `#E0E0E0` | **ADAPT** (coordinate with the colour stream — these are palette roles) |
| 13 | Enum naming `als` = letter `A` = AEMT | print puts AEMT under **BLS** | `ProviderLevel.als` | **ADAPT** — rename to `aemt` (mechanical, no behaviour change) |

Two per-page correspondences are worth recording because they show the
authoring is systematic, not ad hoc: the print's **17** procedure title tiles on
pp.97-108 map 1:1 onto the app's **17** `scope:` keys, and the print's **19**
inline squares on pp.97-106 map 1:1 onto the app's **19** `[X]` step prefixes.
Everything that had a place to live got transcribed; everything that did not
(prose, bands, headings, policy pages) was dropped to plain characters.

**The single biggest gap is #5.** 31 badges on 21 pages, in exactly the place a
reader looks for the permission boundary (the medication detail page), rendered
today as two bold characters. The example in the brief — p.43's green `A` before
Versed — is one of these.

### 6.2 The legend and its governing text

| # | Item | Print | App | Verdict |
|---|---|---|---|---|
| 14 | p.2 shape legend | six drawn shapes | 6 markdown bullets naming them | **ADAPT** — render the actual shapes |
| 15 | p.2 provider legend | six drawn badge tiles, BLS/ALS grouped | 5 markdown bullets | **ADAPT** — render the actual badges; fix "purple P = CC" (print's plain P is pink) |
| 16 | **p.3 guidance in full** | 1 title + 9 section leads + 25 bullets = **34 lines** | **0 of 34 present** | **DROP → add** |
| 16a | "use any intervention marked for **your level or lower**" | p.3 | absent | **DROP → add** — this is the sentence that makes every one of the 363 badges mean something |
| 16b | 14+ adult / 1-13 child / <1 infant, + adults under 110 lb use peds dosing | p.3 | absent as a general rule (the numbers appear ad hoc inside individual entry stadiums) | **DROP → add** |
| 16c | CC credentialing rules (OMD approval per protocol, prerequisites, month-end grace period) | p.3 | absent | **DROP → add** |

### 6.3 Shapes

| # | Item | Print | App | Verdict |
|---|---|---|---|---|
| 17 | Entry stadium | 46 | `NodeShape.stadium` + `flow_entry` | **KEEP** |
| 18 | Decision diamond | 41 | `NodeShape.diamond` + `flow_decision` | **KEEP** |
| 19 | Convergence stadium | 54 | `flow_convergence` | **KEEP** |
| 20 | Red octagon | 10 (6 SAFETY, 3 DECON, 1 RSI) | `WarningType.safety`, 8 in YAML | **ADAPT** — one `Ensure Patient DECON` missing |
| 21 | Purple trapezoid | 24 (15 Destination Triage, 9 Refusal) | `WarningType.caution`, 20 in YAML | **ADAPT** — one `Use Caution if Patient Refusal` missing (the other 3 are on non-topic pages 106/113/116) |
| 22 | Grey Concept box | 33 on 24 pages | authored as amber `callout: true` (31x); `boxed: true` used 5x, none on a protocol page | **ADAPT** — the print's Concept box is neutral grey; amber is the print's *nothing*, and it steals emphasis from the octagon/trapezoid |
| 23 | Dashed conditional box | the print's alert boxes and scoped lines are all dashed | `dashed: true` supported, **used 0 times** | **ADAPT** |
| 24 | Zebra-striped age-band entry stadium | pp.8, 10, 12, 14, 82, 92 | entry text is a single `\n`-joined string | **DROP → decide** (low value; the content is present, only the striping is lost) |
| 25 | Green stadium used as a *branch header* | p.36, 8 instances | unknown — not audited | **unknown** |

### 6.4 Inline glyphs and population markers

| # | Item | Print | App | Verdict |
|---|---|---|---|---|
| 26 | "Call ER" phone tile | **12 pages** (29, 45, 53, 55, 57, 59, 63, 65, 67, 71, 89, 95), fixed geometry | none | **DROP → add as a themed vector.** Recurring visual vocabulary, parameterised by one word (TRAUMA / STROKE / STEMI / SEPSIS) |
| 27 | `Call a __ Alert` box | 12 | 11 amber callouts; missing p.29 STEMI | **ADAPT** |
| 28 | Rule-of-Nines + palm 1% figure | p.71 only | `bsa_rule_of_nines.png` | **KEEP** — correctly a raster |
| 29 | Handtevy colour-zone tabs | pp.144-161 | deliberately not reproduced (see `about.yaml`) | **KEEP** (settled decision) |
| 30 | Pink `Peds` **right-edge** tab on an action tile | 3 (pp.12, 50, 78) | none | **DROP → decide** — 3 instances; either add a right-edge population tab to `ActionTile` or fold the information into the dose row |
| 31 | Dose-row `Adult` / `Peds` right-edge tab + row tint | 72 Adult tabs / 3 Peds tabs | `dose_table.dart` draws a full-width section band above the rows | **ADAPT** (form differs, meaning preserved) |
| 32 | Pink Pediatrics band | 73 pages | `band: "peds"` x45 | **KEEP** |
| 33 | Lavender Critical Care band (full-width prose wash) | 20 pages | `band: "critical_care"` x8 | **DROP → add 12**, on print pp. 11, 13, 15, 19, 27, 29, 31, 37, 43, 49, 63, 73 (topics 010, 012, 014, 018, 026, 028, 030, 036, 042, 048, 062, 072) |
| 34 | Lavender CC sub-tab fused under a convergence stadium | **19** (pp.4, 6, 8, 10, 16, 26, 28, 30, 34, 36, 42, 48, 54, 56, 58, 62, 72, 86, 90) | `critical_care_link:` in **2** topics, drawn as a floating pill | **ADAPT** — add the missing 17; reshape the pill into a tab fused to the stadium's bottom edge |

### 6.5 What a fix would need, minimally

1. **A badge span in `MiniMarkdown`.** One inline token (e.g. `{E}` or reuse the
   procedure card's `[E]`) producing a `WidgetSpan` around the existing
   `_ScopeChip`. That single change unlocks items 5, 7, 8 and makes items 6 and
   14/15 authorable, because prose blocks, band callouts, table cells and flow
   bullets all funnel through `MiniMarkdown`. Note the token must not collide
   with the existing `[text](target)` link syntax.
2. **A `criticalCare` member on `ProviderLevel`** plus a `provider_critical_care`
   palette role holding the purple gradient, and `provider_paramedic` corrected
   to the printed pink. (Item 11.)
3. **A p.3 topic** carrying the 34 lines of governing text, linked from the book
   index — and reachable from any badge, because a badge without "your level or
   lower" is decoration.

---

*Audit produced from `/home/grey/dev/fhir/orbweaver/2026-WVEMS-Protocols.pdf`
(166 pp) against `/home/grey/dev/fhir/orbweaver-wt` at the time of writing.
All 166 pages were rendered and scanned; every count above is measured, not
estimated. Items marked "unknown" were not determined.*
