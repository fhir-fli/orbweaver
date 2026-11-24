# Second read (Gemma 4 31B): every finding, and what was done

Each finding was read against the English page. "Fixed" went through
`es.py apply` (checker 0 problems). "Kept" says why.

Instrument check first (2026-11-22): three errors planted in the Spanish of
wvems_2026_070 (fluid rate 500→250 mL/h, "Retire" → "No retire", "Profunda" →
"Superficial"). All three reported as patient-safety; no other findings on
that page.

## Pages 1–38 (run started 2026-11-22)

| Page | Id | Gemma said | Verdict |
|---|---|---|---|
| calc_anion_gap | s3 | tag "anion" needs the accent | Fixed: "anión" (search folds accents, so both spellings still match) |
| calc_auditc | s9 | tag "tca" (alcohol use disorder) reads as eating disorder in Spanish | Fixed: "tua" (trastorno por uso de alcohol) |
| calc_centor | s8 | tag "ebhga" not a Spanish term | Kept: EBHGA (estreptococo beta-hemolítico del grupo A) is the standard Spanish abbreviation |
| calc_cows | s55 | "Se palpa, no se observa" means palpated, not reported | Kept: the COWS tremor item is "tremor can be felt, but not observed" by the examiner; palpated is right |
| calc_glasgow_blatchford | s31 | "mejor validada … que la mortalidad" softens "not mortality" | Fixed: "…intervención/transfusión, no la mortalidad" |
| calc_heart | s14 | "mayores a 6 semanas" reads as "more than 6 weeks" | Fixed: "adversos mayores en 6 semanas" |
| calc_heart | s41 | "ensayo" (assay) reads as clinical trial | Fixed: "análisis" |
| calc_holliday_segar | s11, s15, s16 | "ritmo" for a fluid rate reads as heart rhythm | Fixed: "velocidad" (also in calc_parkland, same word, same sense) |
| credits | s3 | ProtocolBook title left in English | Kept: it cites the published English title |
| credits | s6 | WHO disclaimer left in English | Kept: WHO material stays English until WHO grants translation (licence 202610340) |
| credits | s58 | "Cricotiroidotomía" for "Cric" | Kept: "Cric" is the procedure; the parenthesis already says landmark |

## Pages 39–57 (2026-11-23 to 11-24)

Pages with no findings: calc_nexus_cspine, calc_osmolal_gap, calc_ottawa_knee,
calc_oxygenation, calc_parkland, calc_pecarn_cspine, calc_pecarn_head, calc_news2,
calc_prevent_ascvd, calc_qtc, calc_rcri, calc_reticulocyte, calc_sgarbossa, calc_sirs.
Seven pages first failed on a DNS outage and were rerun after the retry fix.

| Page | Id | Gemma said | Verdict |
|---|---|---|---|
| calc_nihss | s44, s45, s50, s51, s56, s57, s62, s63 | "claudicación"/"claudica" for drift is vascular claudication | Kept: the Spanish NIHSS uses "claudicación" for drift (SAMUR Madrid NIHSS sheet, servpub.madrid.es/manualsamur/anexos/306_02_EscalaNIHSS.pdf; Junta de Andalucía stroke annex, "Claudica pero no toca la cama") |
| calc_ottawa_ankle | s27 | "evaluadas en ~10 días" could read as "after 10 days" | Fixed: "evaluadas dentro de los ~10 días" |
| calc_perc | s19 | "en 4 semanas" reads as future | Fixed: "en las últimas 4 semanas" |
| calc_phq9 | s41 | "a sí mismo/a la familia" drops "or to" | Fixed: "a sí mismo/a o a la familia" |
| calc_qsofa | s20 | "SRIS" should be "SIRS" | Kept: SRIS (síndrome de respuesta inflamatoria sistémica) is the Spanish acronym |

## Pages 58–68 (2026-11-24)

| Page | Id | Gemma said | Verdict |
|---|---|---|---|
| protocolbook formulary | s37 | "Artemetero" should be "Arteméter" | Fixed, and the same word on pb_023 (×2 pages) and pb_024: WHO's Spanish malaria guidelines (2021, 2022) and Colombia's Ministerio de Salud malaria guide write "arteméter + lumefantrina". 0 "artemetero" left. |
| calc_wells_pe | s6 | tag "etv" should be "tev" | Kept: ETV (enfermedad tromboembólica venosa) and TEV are both standard Spanish; the book uses ETV in all 13 places, so the tag matches the text |

Every other page in this range had no findings. (calc_wells_pe was missed at first and adjudicated 2026-11-24 after a log sweep.)

## Pages 73– (2026-11-24)

| Page | Id | Gemma said | Verdict |
|---|---|---|---|
| pb_016_weight_estimation | s52 | **patient-safety**: "1 categoría de talla superior" reads as the taller band; the English "1 height-category above" means the row above in the table, a shorter band and a lower weight | Fixed: "1 categoría de talla menor, la fila de arriba en la tabla". Gemma was right: at 100 cm "superior" points to 107–120.99 cm, 16–19 kg, instead of 11–12 kg, about 40–60% more drug. The worked example (11–12 kg) was already correct, so a careful reader would have seen the conflict. No other page carries the rule (English searched for "category above", "height-category", "categories younger", "row above"). |
