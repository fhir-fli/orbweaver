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
