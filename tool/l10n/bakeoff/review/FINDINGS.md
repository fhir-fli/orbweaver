# Meaning review of the ten test pages (read by eye, Claude Opus 5.5, 2026-11-21)

Severity: **ERROR** = a clinician could act differently (meaning changed, content added or
dropped); **minor** = wrong word, typo, untranslated word, register; meaning intact.

## who_1_chart09_diazepam
- All five: no meaning errors. Doses, maxima, negations, sequence intact.
- haiku minor: s36 moved bold off the negation ("No administre **medicamentos por vía oral**"; EN bolds "no oral medication").
- gemma-31b minor: "un bolsa-válvula-mascarilla" (gender).
- E4B minor: typos "O R 4.1", "énexito"; informal "Desviste"; "status epilepticus" and "Fosphenytoin" left in English.
- opus: none found.

## who_1_chart11_dehydration (E4B unreadable)
- gemma-31b (retry run): no meaning errors. All rates, volumes and Plan C arithmetic intact.
- haiku, flash-lite, opus: no meaning errors.
- haiku minor: "Gráfico" for Chart (AIEPI Spanish uses "Cuadro"); s16 dropped "oral" from "oral WHO-ORS"; "sal" singular.
- flash-lite minor: "MAS" for SAM (used by some PAHO material; opus wrote DAS).

## who_8_03_2_cotrimoxazole
- **flash-lite ERROR**: "Single-strength" → "Dosis única" (single dose) and "Double-strength" → "Dosis doble" (double dose), in the table headers and in s52 ("tableta de dosis única"). A tablet strength now reads as a dosing instruction.
- **E4B ERROR**: the same strength → dose error (s25, s26, s52). **E4B ERROR**: "Reinstitute if CD4 falls below it" → "Reinstale suspensión si el CD4 cae" (reinstate the STOP) — reversed. E4B minor: "decladamente" (not a word), "bonificación" for benefit, "ART" left in English, informal "mantenlo".
- **gemma-31b ERROR** (retry run): the same strength → dose error — "Dosis simple 400/80", "Dosis doble 800/160", "tableta de dosis simple". "Reiniciar si el CD4 cae" is correct.
- haiku: no meaning errors. minor: alias "HIV" left in English.
- opus: none found.

## pb_086_neo_sepsis_treatment
- gemma-31b (retry run): no meaning errors. minor: chest-wall indrawing → "tiraje intercostal" (AIEPI says "tiraje subcostal"); "q8h", "OD" left as in English.
- All doses, intervals, durations, "do not" and contraindication lines intact in haiku, flash-lite, E4B.
- **E4B ERROR**: "Severe chest-wall indrawing, grunting" → "Inducción grave del tórax, gemitaciones" (not Spanish clinical terms; the danger sign is unreadable). minor: "q8h"/"OD"/"LP"/"PROM"→"PRM" left untranslated, "partera" for maternity.
- haiku minor: "Trate como oftalmia neonatal" (treat AS, not FOR); "Pocas ampollas" (few, not a few).
- flash-lite minor: "Mantener al calor"; "manchas sépticas".
- opus: none found.

## pb_028_poisoning_ingestion (31B refused)
- **haiku ERROR**: "Gastric lavage: almost NEVER INDICATED" → "**NUNCA ESTÁ INDICADO**, casi siempre" (reads "NEVER indicated, almost always").
- **flash-lite ERROR**: charcoal "for substances known to be adsorbed" → "que se sabe que se absorben" (absorbed, not adsorbed — the reason to give charcoal is lost).
- **E4B ERROR**: "Bedside RBS" → "Glucosa en sangre rápida (GCS)" — labels glucose with the Glasgow abbreviation two lines above GCS < 12. minor: "ABCD" → "ABC", "bag" left in English, "Td" for Rx.
- opus: none found.

## pb_014_cardiac_arrest
- gemma-31b (retry run): no meaning errors. minor: "cambiar compresores" (compressors = machines), "ROSC" and "sec" left in English, "Tensión neumotórax" word order, flush → "bolo".
- haiku: no meaning errors. minor: five search aliases left in English (adult, cardiac_arrest, cpr, resuscitation, emergency) — Spanish search misses them; "Pulso definitivo".
- flash-lite: no meaning errors. minor: swapped the two T items (s33 tension pneumothorax ↔ s35 tamponade); both still listed. "ROSC" left in English.
- **E4B ERROR**: page title "Adult Cardiac Arrest" → "Paroencefaliosis" (not a word); "Algoritmo post-paroencefálico"; "Huérón de hidrógeno"; "Empneumotórax". Gibberish in the title and the H/T list.
- opus: none found.

## pb_037_anaphylaxis (all five returned)
- haiku, flash-lite, gemma-31b: no meaning errors. IM-only / not-IV warning, doses, BP cut-offs, observation rules intact.
- **E4B ERROR**: "Assess GCS" → "Evaluar EVC" (EVC is the Spanish abbreviation for stroke). minor: "Anafilaxis", "Fluidoterapia … (NS)".
- gemma-31b minor: "prn" left untranslated.
- opus: none found.

## wvems_2026_020 pain
- gemma-31b (retry run): no meaning errors; kept the brand names as the prompt asks. minor: typo "Tetricaína"; references line left in English.
- haiku: no meaning errors. minor: "angustia" for distress (reads as anxiety).
- flash-lite: no meaning errors. minor but against the prompt: replaced the brand names the protocol uses (Tylenol → "Paracetamol®", Toradol → "Ketorolaco®", with a ® on a generic).
- **E4B ERROR**: invented a link — "EMS" became a link to the Major Trauma page. minor: "náuicos" (not a word) for narcotic-naive; bold dropped from "not".
- opus: none found.

## wvems_2026_062 head injury (all five returned)
- haiku, flash-lite, gemma-31b, E4B: no meaning errors.
- gemma-31b minor: "No empaquete los oídos" (pack = taponar).
- E4B minor: "LOC", "ICP" left in English; "Lavarse cualquier sustancia química"; "Protejer".
- opus: none found.

## conv_steroids (all five returned)
- haiku, flash-lite, gemma-31b: no meaning errors. haiku minor: "desde"/"hacia" stranded in bold at the end of clauses.
- E4B minor: the from/to sentence garbled ("del que está cambiando **y**, … **hacia**").
- opus: none found.

## Tally (meaning ERRORs / pages read)
| Model | Errors | Pages read | Unreadable / refused |
|---|---|---|---|
| Opus 5.5 (this conversation) | 0 | 10 | 0 |
| Haiku 5.5 | 1 | 10 | 0 |
| Gemini 3.1 Flash-Lite | 2 | 10 | 0 |
| Gemma 4 31B (Gemini API) | 1 | 9 | poisoning lost to 503 ×12; rerun in progress |
| Gemma 4 E4B (laptop) | 7 | 9 | 1 not valid JSON |
| Gemma 4 E2B (laptop) | not read in full; checker found 2 link errors | 8 | 2 not valid JSON |

Caveat: one reader (Claude Opus 5.5), who also wrote the opus column — self-graded, not blind.
