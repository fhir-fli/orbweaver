# Flowchart shape audits — structure and severity, all books

Run for the first time across all three books on 2026-08-30. **No defect found in any
chart.** What the run actually produced was two broken audits, both now fixed, and that
is the more useful result: as written they reported 198 problems and every single one was
noise.

## Structure audit — 180 reported, 180 false, 0 real

| check | fired | verdict |
|---|---|---|
| DEAD END | 31 | **false.** `continue: true` on the last stage is not a dead end when the chart ends in a `terminal:` block, which is what the reader continues INTO. All 20 files carried one. |
| UNREACHED id | 90 | **false.** An `id:` here is both a goto target and a plain anchor on a branch box, so a node nothing targets is usually just an anchor. Narrowing it to charts that navigate at all still flagged pb_013's "slow" beside its one real loopback target. **Check removed** — it cannot tell the two uses apart. |
| BARE BOX | 55 | **false.** Every one was a legitimate single-line action box: "Continue close monitoring of respiratory status", "→ Post Cardiac Arrest Algorithm". A box whose whole instruction fits in its title is normal here. **Check removed**, replaced by one for a box with no title at all. |
| DANGLING goto | 0 | kept — a target naming an id that does not exist is a genuine break however the ids are used |
| ONE-SIDED, EMPTY BRANCH | 0 | kept |

After the fixes: **0 of 111 charts**. That zero was validated, not assumed. Injecting one
dangling `loopback` into pb_013 and deleting pb_037's `terminal:` block produced exactly
three findings naming both defects, and removing them returned it to zero.

## Severity audit — 18 reported, 5 real questions, 0 defects

The check exists for the hyperkalaemia shape: a drug on the milder arm and absent from the
sicker one. Six of the eighteen were an **inversion**: `yes` was scored as severe, so on
"Convulsion stops after 5 more minutes?" and "Has bleeding stopped?" the recovering child
was compared as the sicker one. `yes` and `no` carry no severity on their own — the
decision text decides what they mean — so both were removed from the vocabulary. That also
dropped the comparison count from 124 to 37, correctly: a yes/no decision has no severity
ordering and should never have been ranked.

The five that survive are all correct, and three of them are the logic being **right**:

- **pb_047 DKA** — the emergency arm lacks glucose and insulin because it says "→ start
  DKA protocol (next page)", and the protocol is on p.48. The audit does not follow a
  hand-off. **This is the standing positive control for the whole check**: it is the
  hyperkalaemia shape, detected correctly, benign only because of where the arm points.
- **wvems 014** — the severe arm lacks adenosine and amiodarone because unstable
  tachycardia gets **cardioversion**. This is the inverted-SVT-branch defect *not* present.
- **wvems 012** — severe bradycardia gets pacing, not atropine.
- **wvems 020** — severe pain gets an opioid, not paracetamol or ketorolac.
- **pb_046** — severe pneumonia gets injectable ampicillin and gentamicin, not oral
  amoxicillin.

## What this pass changed

Nothing in any book. Two tools, from 198 findings of which 0 were real, to 5 questions of
which 0 are defects. **An audit that cries wolf is worth nothing**, so the fix was to the
audits, not to the charts.

## Chart against the prose on its own page — extended to all three books

It had only ever run over the ProtocolBook. WHO and WVEMS have charts beside prose on the
same page too. **WVEMS is included deliberately:** the rule that its figures are strict
forbids comparing them to the OTHER books, not to the prose on its own page. A WVEMS chart
disagreeing with its own paragraph would be a transcription error in our copy, which is
ours to fix.

95 topics compared, 6 differences.

**All five WVEMS differences are faithful transcriptions**, checked line by line against
the 2026 protocol PDF. In every case the print itself carries a chart figure and a
separate note figure:

| our chart | our prose | the print |
|---|---|---|
| nitroglycerin 0.4 mg | 0.8 mg | *"Nitro: 0.4 mg SL Q 5 min x3"* and *"May use double dose (0.8 mg) if hypertensive & requiring NIPPV"* |
| diphenhydramine 25 mg | 50 mg | *"Benadryl: 25 mg IV/IO, IM, PO Q 15 min x2"* and *"May give adults 50 mg PO x1"* |
| midazolam 2.5–5 mg (×2 pages) | 10 mg | *"Versed: 2.5-5 mg IV/IO, IM/IN Q 2 min (max 10)"* — the 10 is the max on the same line |
| propofol 50–200 mcg/kg/min | 100, 150, 200 | *"Propofol: 50-200 mcg/kg/min IV/IO Titrated Drip"* and *"Start gtt near 150 mcg/kg/min"* |

That is a clean result for WVEMS on this axis: our copy matches the print wherever the two
sides of a page differ.

**One real finding, in the ProtocolBook.** `pb_042` paediatric convulsions: the chart's
terminal box said phenobarbitone maintenance **5 mg/kg**, while the prose on the same page
said **3–5**. OE ruled 3–5 on 2026-08-30, printed as a range so it prompts a lower dose in
a sedated or hepatically impaired child. Chart corrected.

🔒 **The parity guard then fired, on its first real occasion, and it was right.** Changing
that page stranded the ProtocolBook formulary's flat 5 mg/kg maintenance, which no page
carried any more — the exact "page corrected, formulary left behind" failure it was built
for, five days after the fifth instance of it. Formulary brought to 3–5 in the same commit.
