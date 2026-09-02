# Cyclic charts — the backlog, and why it is CLOSED

**NOTHING IS OPEN.** Do not re-raise these. This file exists because the
dispositions lived only in a commit message (`5ee40b7`, 2026-08-29), so a later
scan re-derived the same eight charts and started work on them again.

A loop in this app is **structural**: a branch carries `loop_to` naming an earlier
step and `loop_label` saying when. Four charts have one.

## Converted to `variant: cycle`

| chart | loop |
|---|---|
| `pb_014_cardiac_arrest` — adult ACLS | `loop_to: cpr`, every 2 min |
| `pb_029_organophosphate` — atropine titration | `loop_to: atropine`, every 5 min; bolus → check atropinisation endpoints → not met → **double** and back |
| `who_3_02_resuscitation` — WHO neonatal | `loop_to: hr_check`, if HR > 100/min |
| `pb_035_alcohol_withdrawal` — CIWA-Ar | `loop_to: rescore` (the chart the renderer was built for) |

## Already correct — no change needed

**`pb_013_pals`.** It draws its loopback as a convergence and states the 3–5
minute adrenaline interval properly.

## Rejected with a reason — do NOT convert

**`pb_142_im_potassium` (hyperkalaemia) · `pb_031_benzo_opioid` (naloxone
redosing) · `pb_039_snake_bite` (antivenom titration) · `pb_047_paediatric_dka`.**
In each the repeat is an instruction **inside one treatment box**, not a return to
an earlier node on the spine, and the chart's main axis is triage. Converting them
would be churn.

## 🛑 Three probes that DO NOT work, so nobody builds them again

- **Lexical loop words** — repeat, recheck, reassess, every N minutes, until —
  return **31 of 111** charts, nearly all dosing frequencies. `q6h` says how often
  a drug is given and nothing about the shape of the chart.
- **Explicit back-edge phrases** return 2, and **miss 3 of the 4 charts already
  known to be cycles**.
- **A structural back-reference probe** (a box naming an earlier step by its id or
  by its title words) returns 15, and **misses both real pre-conversion charts**
  when run against them from git history.

All three were measured. A negative from any of them is UNKNOWN, not NO. The scan
that found the eight was run on 2026-08-29 and every hit was read by hand; that is
what this question costs.
