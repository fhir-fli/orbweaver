# ProtocolBook — printed figures the app renders as prose

The mirror of the WHO chart pass, under Grey's rule of 2026-08-24: **if it is a
flowchart in the print, it is a flowchart in the app.** Census tool:
`tool/protocolbook_figure_census.py`; raw rows in
`tool/protocolbook_flattened_figures.tsv`.

## How the candidates were found
Per printed page, count embedded raster images and vector drawing paths, then set
that against the block types of the app topic that owns the page. **Raw image
counts are useless** — this PDF comes from Word, so flowchart boxes and arrowheads
arrive as dozens of tiny images (p.30 has 27). Filtering to images larger than
60×60 pt, and to topics carrying **neither** a `flowchart` nor an `image` block,
gives 15 real candidates out of 147 pages.

Every one was then **looked at**, not inferred. Counting block types produced two
wrong conclusions in the WHO pass on the same day; rendering the page is what
settles it.

## Verdicts

| Page | Topic | What the print draws | Status |
|---|---|---|---|
| **17** | `pb_017_vital_rates` | two **percentile line charts** (RR, HR) — same class as the pp.18–19 BP charts, which the app already carries as images | ✅ both added |
| **61** | `pb_061_sickle_cell_stroke` | boxed spine: presentation → management → concurrent-issue table → monitoring → discharge | ✅ `linear` |
| **62** | `pb_062_sickle_cell_acs` | boxed spine with the CRS table inline, ICU gate, antibiotics, supportive care, discharge | ✅ `linear` |
| **29** | `pb_029_organophosphate` | **branching**: SLUDGE-BBB → atropine bolus ‖ diazepam → maintenance → over-atropinisation | ⏭️ `severity` |
| **34** | `pb_034_alcohol_intoxication` | spine: diagnostic criteria → management → management → "more than alcohol?" | ⏭️ `linear` |
| **74** | `pb_074_anaemia` | spine: history → management → bleeding? → empiric malaria/sepsis → transfusion thresholds → evaluate cause | ⏭️ `linear` |
| **94** | `pb_094_im_heart_failure` | two parallel intake boxes converging into assessment, then the **Stevenson 2×2** (congestion × perfusion) | ⏭️ `algorithm` |
| **113** | `pb_112_im_agitation` | parallel safety boxes converging → restraint indications → monitoring → sedation gate → 3-column drug table | ⏭️ `linear` + table |
| **127** | `pb_127_im_copd_asthma` | spine: management → evaluate other causes → treatment → escalation, with an oxygen-target side callout | ⏭️ `linear` |
| 130 | `pb_130_im_dvt` | outline prose + Wells table with a small risk-band annotation box — **not** a flowchart | no action |
| 12, 22, 27, 69, 80, 81 | — | small boxes/arrow glyphs, not figures | no action |

## 🛑 This reverses an authoring rule
Several of these topics carry a header saying they were deliberately rendered as
prose — `pb_061`'s reads *"a linear flow … with no decision points → titled prose +
one table, **per the hybrid rule**"*. That rule is now **superseded**: a linear flow
with no decisions is still a flowchart if the print draws it as one. Grey's words:
*"if there's a flowchart in print, it should almost always be a flowchart in the
app."*

## Renderer constraint worth knowing
`LinearContentStep` carries a **title and bullets only — no table**. Where the print
puts a table inside the spine (pp.61, 62, 113), the step names the table's contents
and the full table sits directly below the chart. Only the `algorithm` variant's
`AlgoBox` can hold a table (`AlgoTable`), which is why p.94 is queued as `algorithm`.
