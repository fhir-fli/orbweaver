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
