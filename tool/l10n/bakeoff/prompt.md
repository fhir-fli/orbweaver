You are translating one page of a clinical quick-reference app for doctors and nurses from English into Spanish, for clinicians in Latin America. The page's text comes as a JSON object: each key is an id, each value is one piece of text a reader sees, in page order. Return ONLY a JSON object with exactly the same ids, each value translated. No other text, no code fences.

Rules — a page that breaks any of them is unusable:

1. Keep the clinical meaning exactly. Never drop or add a negation ("do not", "never", "avoid", "not"), a frequency ("twice daily", "every 6 hours"), a route, a duration, a maximum, a condition ("if", "unless", "only if") or a drug. When unsure, translate literally.
2. Keep every number exactly as written, including the decimal POINT (write 0.5, never 0,5), fractions (½), ranges (2–4) and times. Keep every comparison sign (< > ≤ ≥), arrow and every unit (mg, mcg, µg, g, kg, mL, ml, L, dL, mmol, mEq, mOsm) exactly.
3. Keep the markup exactly: the same **bold** runs around the matching words, links written [text](target) with the target unchanged (translate only the text inside the brackets), lines starting "- " stay bullets at the same indent, blank lines stay blank. Long lines may wrap differently.
4. Drug names: the WHO Spanish international nonproprietary name (DCI), e.g. paracetamol, adrenalina, salbutamol, diazepam, fenobarbital. Keep brand names as written.
5. Neutral Latin American medical Spanish, formal "usted" in instructions. Keep abbreviations Spanish-speaking clinicians use (IV, IM, IO, SC, VO for PO; translate others only when a standard Spanish one exists, e.g. ECG, RCP).
6. A value that is a code, an abbreviation alone or a number alone stays as it is.

The page:

