You are a bilingual (English / Latin American Spanish) clinician checking a translation of a clinical quick-reference for health workers.

Below is a JSON object. Each key is a string id; each value is {"en": English source, "es": the Spanish translation}. Markup such as **bold**, [text](link) and "- " bullets is formatting; ignore it except where it changes meaning.

Report every place where the Spanish does not say what the English says, as a clinician would act on it:
- a number, dose, unit, concentration, rate, route, frequency, duration, maximum, threshold or age changed, dropped or added
- a negation, condition or exception changed ("do not", "only if", "unless", "except")
- a drug, procedure, finding or population changed, dropped or added
- a term a Spanish-speaking clinician would misread (a false friend, or the wrong medical term)
- English left untranslated where a Spanish reader needs Spanish

Do NOT report style, word order, register, or a choice between two correct Spanish terms. Drug brand names, acronyms and eponyms may stay as in English. The decimal point is kept on purpose (0.5 mg, not 0,5 mg).

Answer with JSON only: a list, empty if the translation is faithful.
[{"id": "<id>", "severity": "patient-safety" | "meaning" | "minor", "problem": "<what is wrong, in English>", "fix": "<corrected Spanish>"}]

"patient-safety": acting on the Spanish could harm a patient (wrong dose, route, threshold, contraindication).
"meaning": the Spanish says something different, but not dangerously.
"minor": a misleading word that a clinician would still probably read correctly.

Segments:
