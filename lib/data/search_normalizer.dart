/// Normalises clinical text so search matches across British/American
/// spellings, dosing-unit wording, casing and punctuation. The SAME function
/// is applied to the indexed content AND to the user's query, so e.g. a US
/// user typing "diarrhea" finds the British-spelled "diarrhoea" content, and
/// "100 milligrams" matches "100 mg".
///
/// Ported from `graiai/stapes/scripts/extended_normalizer.py` (the clinical
/// text normaliser built for the ASR work) — the UK→US map, suffix rules and
/// dosing map are carried over; the ASR-only pieces (backchannel suppression,
/// number-to-words) are deliberately omitted as they don't help text search.
class SearchNormalizer {
  const SearchNormalizer._();

  /// British → American spellings, medical-heavy. Token-level exact lookup.
  static const Map<String, String> _ukToUs = {
    // Medical (digestive / haematology / oncology / etc.)
    'diarrhoea': 'diarrhea', 'oedema': 'edema', 'oesophagus': 'esophagus',
    'oestrogen': 'estrogen', 'oestrogens': 'estrogens',
    'haemorrhage': 'hemorrhage', 'haemorrhages': 'hemorrhages',
    'haematology': 'hematology', 'haematological': 'hematological',
    'haematoma': 'hematoma', 'haemoglobin': 'hemoglobin',
    'haemodynamic': 'hemodynamic', 'haemoptysis': 'hemoptysis',
    'haemophilia': 'hemophilia', 'haematuria': 'hematuria',
    'haemothorax': 'hemothorax', 'haemolysis': 'hemolysis',
    'haematogenous': 'hematogenous', 'haematocrit': 'hematocrit',
    'haemolytic': 'hemolytic',
    'anaemia': 'anemia', 'anaemic': 'anemic',
    'leukaemia': 'leukemia', 'leukaemic': 'leukemic',
    'leucocyte': 'leukocyte', 'leucocytes': 'leukocytes',
    'leucocytosis': 'leukocytosis',
    'caesarean': 'cesarean', 'caesarian': 'cesarian',
    'foetus': 'fetus', 'foetal': 'fetal',
    'paediatric': 'pediatric', 'paediatrics': 'pediatrics',
    'paediatrician': 'pediatrician',
    'gynaecology': 'gynecology', 'gynaecological': 'gynecological',
    'gynaecologist': 'gynecologist',
    'orthopaedic': 'orthopedic', 'orthopaedics': 'orthopedics',
    'aetiology': 'etiology', 'aetiological': 'etiological',
    'coeliac': 'celiac',
    'amoebic': 'amebic', 'amoeba': 'ameba',
    'oedematous': 'edematous',
    'hypovolaemic': 'hypovolemic', 'hypovolaemia': 'hypovolemia',
    'hyponatraemia': 'hyponatremia', 'hypernatraemia': 'hypernatremia',
    'hypoglycaemia': 'hypoglycemia', 'hyperglycaemia': 'hyperglycemia',
    'hypocalcaemia': 'hypocalcemia', 'septicaemia': 'septicemia',
    'bacteraemia': 'bacteremia', 'ischaemia': 'ischemia',
    'ischaemic': 'ischemic', 'anaesthesia': 'anesthesia',
    'anaesthetic': 'anesthetic', 'anaesthetist': 'anesthetist',
    'diarrhoeal': 'diarrheal', 'paracetamol': 'paracetamol',
    'tumour': 'tumor', 'tumours': 'tumors', 'tumourous': 'tumorous',
    'manoeuvre': 'maneuver', 'manoeuvres': 'maneuvers',
    'speciality': 'specialty', 'specialities': 'specialties',
    'fibre': 'fiber', 'fibres': 'fibers',
    'litre': 'liter', 'litres': 'liters',
    'metre': 'meter', 'metres': 'meters',
    'millilitre': 'milliliter', 'millilitres': 'milliliters',
    'aluminium': 'aluminum',
    'sulphur': 'sulfur', 'sulphate': 'sulfate', 'sulphide': 'sulfide',
    'sulphonamide': 'sulfonamide',
    // General -our / -or
    'colour': 'color', 'colours': 'colors',
    'coloured': 'colored', 'colouration': 'coloration',
    'behaviour': 'behavior', 'behavioural': 'behavioral',
    'humour': 'humor', 'odour': 'odor',
    'flavour': 'flavor', 'savour': 'savor',
    // General -tre / -ter
    'centre': 'center', 'centres': 'centers',
    'theatre': 'theater', 'theatres': 'theaters',
    // General -ce / -se
    'defence': 'defense', 'offence': 'offense',
    // ise/ize verbs
    'analyse': 'analyze', 'analysed': 'analyzed', 'analysing': 'analyzing',
    'recognise': 'recognize', 'recognised': 'recognized',
    'organise': 'organize', 'organised': 'organized',
    'organisation': 'organization', 'organisations': 'organizations',
    'minimise': 'minimize', 'minimised': 'minimized',
    'maximise': 'maximize', 'maximised': 'maximized',
    'mobilise': 'mobilize', 'immobilise': 'immobilize',
    'immobilisation': 'immobilization',
    'hospitalise': 'hospitalize', 'hospitalised': 'hospitalized',
    'normalise': 'normalize', 'normalised': 'normalized',
    'prioritise': 'prioritize', 'prioritised': 'prioritized',
    // Misc
    'practising': 'practicing', 'practised': 'practiced',
    'enquire': 'inquire', 'enquiry': 'inquiry',
    'mould': 'mold', 'moulds': 'molds',
    'programme': 'program', 'programmes': 'programs',
    'grey': 'gray', 'greys': 'grays',
  };

  /// Dosing / measurement unit words → their abbreviation, so "100
  /// milligrams" matches "100 mg".
  static const Map<String, String> _dosing = {
    'milligrams': 'mg', 'milligram': 'mg',
    'micrograms': 'mcg', 'microgram': 'mcg',
    'kilograms': 'kg', 'kilogram': 'kg',
    'grams': 'g', 'gram': 'g',
    'milliliters': 'ml', 'milliliter': 'ml',
    'millilitres': 'ml', 'millilitre': 'ml',
    'liters': 'l', 'liter': 'l', 'litres': 'l', 'litre': 'l',
    'centimeters': 'cm', 'centimeter': 'cm',
    'centimetres': 'cm', 'centimetre': 'cm',
    'millimeters': 'mm', 'millimeter': 'mm',
    'millimetres': 'mm', 'millimetre': 'mm',
  };

  static final RegExp _digitComma = RegExp(r'(\d),(\d)');
  static final RegExp _nonWord = RegExp('[^a-z0-9\\s]');
  static final RegExp _ws = RegExp(r'\s+');

  /// Normalise [text] to a space-joined stream of normalised tokens.
  static String normalize(String text) {
    if (text.isEmpty) return '';
    var s = text.toLowerCase();
    s = s.replaceAllMapped(_digitComma, (m) => '${m[1]}${m[2]}'); // 1,000→1000
    s = s.replaceAll('-', ' '); // hyphens → spaces
    s = s.replaceAll(_nonWord, ' '); // drop punctuation/symbols
    final out = <String>[];
    for (final token in s.split(_ws)) {
      if (token.isEmpty) continue;
      // UK→US first (map then suffix rules), THEN collapse dosing units —
      // so "millilitres" → "milliliters" → "ml".
      var tok = _ukToUs[token] ?? _suffixUkToUs(token);
      tok = _dosing[tok] ?? tok;
      out.add(tok);
    }
    return out.join(' ');
  }

  /// Suffix-based UK→US rules for tokens not in the explicit map.
  static String _suffixUkToUs(String token) {
    if (token.length <= 3) return token;
    if (token.endsWith('our') &&
        token.length > 4 &&
        !_ourExceptions.contains(token)) {
      return '${token.substring(0, token.length - 3)}or';
    }
    if (token.endsWith('isation') && token.length > 8) {
      return '${token.substring(0, token.length - 7)}ization';
    }
    if (token.endsWith('ising') && token.length > 6) {
      return '${token.substring(0, token.length - 5)}izing';
    }
    if (token.endsWith('ised') && token.length > 5) {
      return '${token.substring(0, token.length - 4)}ized';
    }
    if (token.endsWith('ise') && token.length > 4) {
      return '${token.substring(0, token.length - 3)}ize';
    }
    if (token.endsWith('tre') && token.length > 4) {
      return '${token.substring(0, token.length - 3)}ter';
    }
    if (token.endsWith('bre') && token.length > 4) {
      return '${token.substring(0, token.length - 3)}ber';
    }
    return token;
  }

  static const Set<String> _ourExceptions = {
    'four', 'your', 'hour', 'tour', 'sour', 'pour', 'flour',
  };
}
