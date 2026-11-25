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
| pb_028_poisoning_ingestion | s6, s12 | "toxíndrome" is not standard Spanish | Kept: standard in Spanish toxicology (Spain's Ministerio de Justicia "Toxíndromes" PDF, mjusticia.gob.es; Universidad Complutense de Madrid toxicology notes; Universidad Industrial de Santander, Colombia) |
| pb_031_benzo_opioid | s2, s10, s41 | "toxíndrome" is not standard Spanish | Kept, same as pb_028 (standard Spanish toxicology term; sources there) |
| pb_049_uti_kidney | s74 | "EL" for leukocyte esterase is not a standard abbreviation | Fixed: "¿Nitritos o esterasa leucocitaria positivos?" (EL was undefined on the page and reads as the article "el"); flowchart fit tests pass |
| pb_059_sickle_cell | s15 | "referral" and "shunt" both became "derivación": "derivación quirúrgica urgente para una derivación (shunt)" | Fixed: "derive con urgencia a cirugía para realizar un shunt". "Derive" matches how the rest of the book renders refer ("derive a un especialista quirúrgico", pb_069_mastoiditis); the Spanish book uses "referencia" only for "reference" (e.g. "referencia pediátrica"), never for referral |
| pb_067_epistaxis | s8 | "ATX" for tranexamic acid is not standard; use TXA | Fixed, here and in the ProtocolBook formulary name ("Ácido tranexámico (TXA)"). The Spanish books disagreed: WVEMS Spanish used TXA 14 times, the ProtocolBook ATX twice. Both appear in Spanish journals (PubMed "acido tranexamico" with ATX: 1 hit, Rev Esp Cir Ortop Traumatol 2014; with TXA: 16 hits, e.g. Rev Esp Anestesiol Reanim 2024), so TXA, the majority form and the one WVEMS uses. 0 "ATX" left in any book (case-insensitive word search) |
| pb_076_transfusions | s29 | "Imprima la pareja" reads as "print on paper"; the line means use the paired figures | Fixed: "Use la pareja de cifras del ensayo, no una conversión." The sentence came from 414e00b: read the packed-cell figure off TRACT's whole-blood/red-cell pairing rather than converting (the old 15 mL/kg was a conversion no source made). The other 12 "imprim-" uses in the Spanish ProtocolBook were all read: each says what the printed book said ("El libro imprimía antes…"), which is the literal meaning, so they stay |
| pb_096_im_stroke | s144, s146, s155, s157 (**patient-safety** per Gemma) | "claudicación" for drift is vascular claudication | Kept, same as calc_nihss: the Spanish NIHSS uses "claudicación" for drift (SAMUR Madrid NIHSS sheet; Junta de Andalucía stroke annex). This page and calc_nihss already agree ("Sin claudicación" / "Claudica") |
| pb_096_im_stroke | s110 | "NC" is not a standard abbreviation | Kept: the page defines it two rows up, "1a. Nivel de conciencia (NC)", as the English defines LOC at 1a; 1b and 1c then use it, as in English |
| pb_096_im_stroke | s200 | "Hemiinatención" has a double i | Kept: when a prefix ends in the vowel the base begins with, the RAE accepts both spellings (Ortografía 2010; e.g. "antiinflamatorio" / "antinflamatorio"), and the double-i form keeps "inatención" readable, matching item 11 "Extinción e inatención" and calc_nihss "Extinción / inatención" |
| pb_118_im_ecg_svt | s15 | "fibrilación" for "afib" is vague; use FA | Kept: it is a search tag, never shown (tags feed only `keywordsText` in lib/data/library.dart:255). The same tag list already holds "fibrilación auricular" and "FA", so "FA" would be a duplicate; "fibrilación" catches a reader who types only that word, and the page it finds is titled "Fibrilación auricular" |
| wvems_2026_014 | s60 | "enfermedad del seno" for SSS (sick sinus syndrome) is ambiguous (nasal sinus, breast) | Fixed: "enfermedad del nodo sinusal", which names the node and cannot be misread. Gemma's "síndrome del seno enfermo" keeps the same ambiguous "seno". The only sick-sinus mention in any book (searched English "sick sinus"/"SSS" and Spanish "seno enfermo", "nodo sinusal", "enfermedad del seno", "disfunción sinusal") |
| wvems_2026_034 | s22 | "urente" is rare in Latin America and suggests urinary burning | Fixed, for a different reason: "Dolor \"quemante\"". Gemma's premise is wrong, "dolor urente" is ordinary clinical Spanish (MSD Manual Spanish editions for Colombia and the US, dispepsia page: "dolor urente o ardor"). But the quotes mark the patient's own words in the GERD (gastro-oesophageal reflux disease) column, beside "\"Masa pulsátil\"", and a patient says it burns ("quema"), not "urente". The only "urente" in any book |
| wvems_2026_036 | s47 | "paro médico" for "Medical CODE": a CODE is the activation, not the arrest; use "código médico" | Kept: the link goes to wvems-2026-024, the medical cardiac arrest protocol (compressions / AED / epi / amio), whose Spanish title is "Paro médico (CODE)". All 13 links to it in the Spanish WVEMS use "paro"/"paro médico" with or without "(CODE)", so the page matches its target and keeps WVEMS's own word in brackets. "Código médico" says nothing about arrest to a Spanish reader |
| wvems_2026_040 | s15 | "DESCONTAMINE al paciente" is a command to do it; "Ensure" means make sure it is done | Fixed, here and in the two other "Ensure Patient DECON" lines (wvems_2026_070, wvems_2026_072): "Garantice la DESCONTAMINACIÓN del paciente", parallel to the line above it, "Garantice la SEGURIDAD del proveedor". The provider may not be the one decontaminating |
| wvems_2026_040 | s22 | "Tapón salino" is a literal calque of saline lock | Fixed across WVEMS: all 18 "tapón salino" now "vía salinizada" (15 pages, incl. the wvems_2026_096 procedure name). Spanish nursing protocols say "dejar la vía salinizada" (Portales Médicos peripheral IV protocol; Universidad de Valladolid TFG L1829); a web search found no clinical use of "tapón salino". Gemma's "catéter salinizado" is also attested; "vía" matches how the books name IV access. 0 "tapón salino" left (case-insensitive) |
| wvems_2026_044 | s24 | "Ictus de Cincinnati" reads as a stroke in Cincinnati, not the Cincinnati scale | Fixed: box title "Escala de Cincinnati" (the Cincinnati Prehospital Stroke Scale; the prose above already calls it "la exploración FAST de Cincinnati") |
| wvems_2026_044 | s27 | "Negligencia" reads as malpractice; use "Heminegligencia" | Kept: it is the N of the VAN mnemonic (**V**isión, **A**fasia, **N**egligencia), which "Heminegligencia" would break, and "negligencia" is the Spanish neurological term (the SAMUR Madrid Spanish NIHSS, item 11, scores "extinción o negligencia"; MEDISAN 2017, Cuba, "heminegligencia" review); the line itself says what it means, "¿ignora un lado?" |
| wvems_2026_048 | s33, s48 | "nalgas" is the buttocks, not the presentation; use "presentación podálica" | Fixed, but not with Gemma's term: "presentación de nalgas" is the standard Spanish for breech, and "podálica" names only the footling kind. The bare "Nalgas" / "o nalgas" is now "presentación de nalgas" here (2) and in the same bullet on wvems_2026_096 (1); "parto … de nalgas" on wvems_2026_096 was already clear and stays |
| wvems_2026_054 | s32 | Spanish says "se descompensa" where the English says "decompression" | Spanish kept; the English was wrong. The WVEMS 2026 PDF reads "Repeat immediately if decompensation after initial success" (pdftotext of 2026-WVEMS-Protocols.pdf); our English had "decompression", a transcription slip. English fixed to match the PDF; the Spanish only got a new source stamp. Gemma's fix would have copied the slip |
