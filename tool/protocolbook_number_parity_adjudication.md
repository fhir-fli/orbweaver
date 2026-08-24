# ProtocolBook numeric parity — adjudication of the 9 unexplained figures

`tool/book_number_parity.py` compared every clinical number the print carries against
the app. Of **2,335 printed figures, 49 differ**; 40 were already documented (source
errata the app corrected, or reasoned divergences). These are the **9 that appeared
nowhere**, each checked against the print page and the app topic.

| Page | Figure | Verdict |
|---|---|---|
| **16** | `11–12 kg`, `12 kg` | 🔴 **REAL — fixed.** The print gives two **worked examples** of the underweight rule ("underweight 10-month-old → use the 4–6 month weight"; "underweight at 100 cm → use **11–12 kg**"). The app carried the rule but not the examples, and the examples are what make the rule usable at speed. |
| **105** | `0.02–0.05 IU/kg/hr` | 🔴 **REAL — fixed.** The RBS<14 step-down infusion was written as the single figure **0.05**; the print gives the **range 0.02–0.05**. Narrowing a range to its top value removes the option to titrate down once dextrose is running, which is the point of a step-down. |
| **77** | `11–20% of baseline` | ✅ **Deliberate, correct as-is.** The heart-rate band belongs to the book's 8-item pain scale; OE confirmed heart rate and O₂ saturation are **not** part of the NIPS (they belong to PIPP, and are driven by fever, anaemia and lung disease as well as pain). The scale was reverted to 6 items, max 7 — the band went with it. |
| **97** | `45yo` | ✅ **Present.** The app prints "Age > 45 years" in the LAPSS criteria. Matcher false positive. |
| **99** | `> 65` | ✅ **Present.** MAP ≥ 65 is carried; this is a second instance of the same figure in a table footnote. |
| **33** | `20–40 kg` | ⚪ **Extraction artefact.** The string occurs **zero times** in the page's joined text. |
| **79** | `4–12 y` | ⚪ **Extraction artefact.** Same — zero occurrences. |
| **91** | `50 wk` | ⚪ **Extraction artefact.** The `50` is the **maximum Ballard maturity SCORE**, sitting next to the "Weeks" row header; the app carries the score→weeks table. Not a gestational age. |

## What this says about the instrument
Of 2,335 printed figures the app diverges on 49, and after adjudication **exactly two
were transcription losses** — both small, both real, both now fixed. That is a strong
result for the digitisation: **numeric fidelity to the print is essentially complete.**

The residual false-positive modes are worth knowing before re-running it:
- a figure the print states as a **range** and the app states as a point value (or the
  reverse) reads as absent — this is how p.105 was found, so it is a **useful** mode;
- **numbers adjacent to a row/column header** ("50" next to "Weeks") pick up the wrong
  unit;
- a few strings surface that occur nowhere in the page text at all — join artefacts
  across line boundaries. Always confirm a flag against the joined text before acting.
