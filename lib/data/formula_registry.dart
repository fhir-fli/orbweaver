// formula_registry.dart
//
// The compute half of the `formula` block. Pure Dart — NO Flutter imports —
// so every clinical formula is unit-testable in isolation with golden values.
//
// Design rule (safety): clinical formulas are implemented as named Dart
// functions here, NOT as free-text arithmetic strings in YAML. A YAML-authored
// expression could silently mis-dose a patient on a typo; a named `kind` gets a
// golden test and a code review. The YAML declares inputs (for the form) and a
// `kind`; this registry owns the math. New calculator ⇒ new tested function.
//
// Each function receives the parsed input map (numbers as `num`, selects as
// `String`) keyed by the input `key`s declared in the topic YAML, and returns a
// [FormulaResult]. Missing/invalid required inputs ⇒ [FormulaResult.empty] so
// the view shows a placeholder rather than a wrong number.

import 'dart:math' as math;

/// Visual/severity flag for an output line (mapped to colors in the view).
enum FormulaSeverity { none, info, warn, alert }

/// One computed output row.
class FormulaOutput {
  const FormulaOutput({
    required this.label,
    required this.value,
    this.unit,
    this.interpretation,
    this.severity = FormulaSeverity.none,
    this.primary = false,
  });

  final String label;
  final String value;
  final String? unit;

  /// Optional band/flag text (e.g. "high anion gap", "MAP < 65").
  final String? interpretation;
  final FormulaSeverity severity;

  /// Emphasized (larger) output — the headline number of the calculator.
  final bool primary;
}

/// Result of a computation: zero or more output rows. Empty ⇒ inputs
/// incomplete/invalid; the view renders a "enter values" placeholder.
class FormulaResult {
  const FormulaResult(this.outputs);
  const FormulaResult.empty() : outputs = const [];

  final List<FormulaOutput> outputs;

  bool get isEmpty => outputs.isEmpty;
}

/// Formats a number: integer when whole, else up to [decimals] places with
/// trailing zeros trimmed — no false precision.
String fmtNum(double v, {int decimals = 1}) {
  if (v.isNaN || v.isInfinite) return '—';
  if (v == v.roundToDouble()) return v.toStringAsFixed(0);
  final s = v.toStringAsFixed(decimals);
  return s.contains('.')
      ? s.replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '')
      : s;
}

double? _num(Map<String, dynamic> v, String k) => (v[k] as num?)?.toDouble();
String? _sel(Map<String, dynamic> v, String k) => v[k] as String?;

/// Serum creatinine → mg/dL, honoring an optional unit select (`µmol/L`).
double? _creatinineMgDl(Map<String, dynamic> v, String key, String unitKey) {
  final raw = _num(v, key);
  if (raw == null || raw <= 0) return null;
  final unit = _sel(v, unitKey);
  return unit == 'µmol/L' ? raw / 88.4 : raw;
}

/// Glucose → mg/dL, honoring an optional unit select (`mmol/L`).
double? _glucoseMgDl(Map<String, dynamic> v, String key, String unitKey) {
  final raw = _num(v, key);
  if (raw == null) return null;
  final unit = _sel(v, unitKey);
  return unit == 'mmol/L' ? raw * 18.0 : raw;
}

/// The single entry point. Returns [FormulaResult.empty] for an unknown kind
/// so an author typo fails safe (placeholder) rather than throwing at runtime.
FormulaResult computeFormula(String kind, Map<String, dynamic> v) {
  return switch (kind) {
    'renal_function' => _renalFunction(v),
    'map' => _map(v),
    'corrected_sodium' => _correctedSodium(v),
    'anion_gap' => _anionGap(v),
    'aa_gradient' => _aaGradient(v),
    'winters' => _winters(v),
    'ideal_body_weight' => _idealBodyWeight(v),
    'holliday_segar' => _hollidaySegar(v),
    'meld3' => _meld3(v),
    'qtc' => _qtc(v),
    'free_water_deficit' => _freeWaterDeficit(v),
    'anthropometrics' => _anthropometrics(v),
    'osmolal_gap' => _osmolalGap(v),
    'parkland' => _parkland(v),
    _ => const FormulaResult.empty(),
  };
}

// ── anthropometrics: BMI (+ category) and BSA (Mosteller) ─────────────

FormulaResult _anthropometrics(Map<String, dynamic> v) {
  final height = _num(v, 'height');
  final wt = _num(v, 'weight');
  if (height == null || height <= 0 || wt == null || wt <= 0) {
    return const FormulaResult.empty();
  }
  final cm = _sel(v, 'height_unit') == 'in' ? height * 2.54 : height;
  final m = cm / 100;
  final bmi = wt / (m * m);
  final bsa = math.sqrt(cm * wt / 3600); // Mosteller

  final String cat;
  final FormulaSeverity sev;
  if (bmi < 18.5) {
    cat = 'Underweight';
    sev = FormulaSeverity.warn;
  } else if (bmi < 25) {
    cat = 'Normal';
    sev = FormulaSeverity.none;
  } else if (bmi < 30) {
    cat = 'Overweight';
    sev = FormulaSeverity.warn;
  } else {
    cat = 'Obese';
    sev = FormulaSeverity.alert;
  }
  return FormulaResult([
    FormulaOutput(
      label: 'BMI',
      value: fmtNum(bmi),
      unit: 'kg/m²',
      primary: true,
      severity: sev,
      interpretation: '$cat (WHO). Asian cutoffs: overweight ≥23, obese ≥27.5.',
    ),
    FormulaOutput(
      label: 'BSA (Mosteller)',
      value: fmtNum(bsa, decimals: 2),
      unit: 'm²',
      interpretation: 'Body-surface area for dosing (chemo convention).',
    ),
  ]);
}

// ── osmolal_gap ──────────────────────────────────────────────────────

FormulaResult _osmolalGap(Map<String, dynamic> v) {
  final measured = _num(v, 'measured');
  final na = _num(v, 'sodium');
  final glucose = _num(v, 'glucose'); // mg/dL
  final bun = _num(v, 'bun'); // mg/dL
  if (measured == null || na == null || glucose == null || bun == null) {
    return const FormulaResult.empty();
  }
  final ethanol = _num(v, 'ethanol'); // mg/dL, optional
  var calc = 2 * na + glucose / 18 + bun / 2.8;
  if (ethanol != null) calc += ethanol / 3.7;
  final gap = measured - calc;
  final high = gap > 10;
  return FormulaResult([
    FormulaOutput(
      label: 'Osmolal gap',
      value: fmtNum(gap),
      unit: 'mOsm/kg',
      primary: true,
      severity: high ? FormulaSeverity.warn : FormulaSeverity.none,
      interpretation: high
          ? 'Elevated (> 10) — consider unmeasured osmoles (toxic alcohol).'
          : 'Normal ≤ 10 — but a normal gap does NOT exclude toxic alcohol.',
    ),
    FormulaOutput(
      label: 'Calculated osmolality',
      value: fmtNum(calc),
      unit: 'mOsm/kg',
    ),
  ]);
}

// ── parkland: burn resuscitation fluid ───────────────────────────────

FormulaResult _parkland(Map<String, dynamic> v) {
  final wt = _num(v, 'weight');
  final tbsa = _num(v, 'tbsa');
  if (wt == null || wt <= 0 || tbsa == null || tbsa <= 0) {
    return const FormulaResult.empty();
  }
  final coeff = _sel(v, 'coefficient') == '4' ? 4.0 : 2.0;
  final total = coeff * wt * tbsa;
  final firstHalf = total / 2;
  return FormulaResult([
    FormulaOutput(
      label: '24-hour volume',
      value: fmtNum(firstHalf * 2),
      unit: 'mL',
      primary: true,
      interpretation: 'Lactated Ringer\'s; titrate to urine output 0.5 mL/kg/h.',
    ),
    FormulaOutput(
      label: 'First 8 h (from burn time)',
      value: '${fmtNum(firstHalf)} mL',
      unit: '≈ ${fmtNum(firstHalf / 8)} mL/h',
    ),
    FormulaOutput(
      label: 'Next 16 h',
      value: '${fmtNum(firstHalf)} mL',
      unit: '≈ ${fmtNum(firstHalf / 16)} mL/h',
    ),
  ]);
}

// ── meld3: MELD 3.0 (OPTN 2023, age ≥12) ─────────────────────────────

FormulaResult _meld3(Map<String, dynamic> v) {
  final bili0 = _num(v, 'bilirubin');
  final na0 = _num(v, 'sodium');
  final inr0 = _num(v, 'inr');
  final cr0 = _creatinineMgDl(v, 'creatinine', 'cr_unit');
  final alb0 = _num(v, 'albumin');
  final sex = _sel(v, 'sex');
  if (bili0 == null ||
      na0 == null ||
      inr0 == null ||
      cr0 == null ||
      alb0 == null ||
      sex == null) {
    return const FormulaResult.empty();
  }
  final female = sex == 'F';
  // Bounds per OPTN policy.
  final bili = bili0 < 1 ? 1.0 : bili0;
  final inr = inr0 < 1 ? 1.0 : inr0;
  var cr = cr0 < 1 ? 1.0 : cr0;
  if (_sel(v, 'dialysis') == 'yes') cr = 3.0; // ≥2 sessions/wk or 24h CVVHD
  if (cr > 3) cr = 3.0;
  var na = na0;
  if (na < 125) na = 125;
  if (na > 137) na = 137;
  var alb = alb0;
  if (alb < 1.5) alb = 1.5;
  if (alb > 3.5) alb = 3.5;

  final score = 1.33 * (female ? 1 : 0) +
      4.56 * math.log(bili) +
      0.82 * (137 - na) -
      0.24 * (137 - na) * math.log(bili) +
      9.09 * math.log(inr) +
      11.14 * math.log(cr) +
      1.85 * (3.5 - alb) -
      1.83 * (3.5 - alb) * math.log(cr) +
      6;
  var meld = score.round();
  if (meld < 6) meld = 6;
  if (meld > 40) meld = 40;

  final FormulaSeverity sev;
  if (meld >= 30) {
    sev = FormulaSeverity.alert;
  } else if (meld >= 20) {
    sev = FormulaSeverity.warn;
  } else {
    sev = FormulaSeverity.none;
  }
  return FormulaResult([
    FormulaOutput(
      label: 'MELD 3.0',
      value: '$meld',
      primary: true,
      severity: sev,
      interpretation: '90-day mortality rises steeply above ~20; range 6–40.',
    ),
  ]);
}

// ── qtc: corrected QT (Fridericia default) ───────────────────────────

FormulaResult _qtc(Map<String, dynamic> v) {
  final qt = _num(v, 'qt'); // ms
  final hr = _num(v, 'hr'); // bpm
  if (qt == null || hr == null || hr <= 0) return const FormulaResult.empty();
  final rr = 60 / hr; // seconds
  final fridericia = qt / _pow(rr, 1 / 3);
  final bazett = qt / math.sqrt(rr);
  final framingham = qt + 154 * (1 - rr);
  final hodges = qt + 1.75 * (hr - 60);

  final FormulaSeverity sev;
  final String interp;
  if (fridericia > 500) {
    sev = FormulaSeverity.alert;
    interp = 'QTc > 500 ms — high torsades risk.';
  } else if (fridericia >= 460) {
    sev = FormulaSeverity.warn;
    interp = 'Prolonged (≈ ≥ 460 ms).';
  } else {
    sev = FormulaSeverity.none;
    interp = 'Fridericia is the preferred correction (FDA / AHA).';
  }
  return FormulaResult([
    FormulaOutput(
      label: 'QTc (Fridericia)',
      value: fmtNum(fridericia, decimals: 0),
      unit: 'ms',
      primary: true,
      severity: sev,
      interpretation: interp,
    ),
    FormulaOutput(
      label: 'QTc (Bazett)',
      value: fmtNum(bazett, decimals: 0),
      unit: 'ms',
      interpretation: 'Overestimates at high HR, underestimates at low HR.',
    ),
    FormulaOutput(
        label: 'QTc (Framingham)', value: fmtNum(framingham, decimals: 0), unit: 'ms'),
    FormulaOutput(
        label: 'QTc (Hodges)', value: fmtNum(hodges, decimals: 0), unit: 'ms'),
  ]);
}

// ── free_water_deficit (hypernatremia) ───────────────────────────────

FormulaResult _freeWaterDeficit(Map<String, dynamic> v) {
  final wt = _num(v, 'weight');
  final sex = _sel(v, 'sex');
  final current = _num(v, 'sodium');
  if (wt == null || wt <= 0 || sex == null || current == null) {
    return const FormulaResult.empty();
  }
  final target = _num(v, 'target') ?? 140;
  if (target <= 0) return const FormulaResult.empty();
  final tbwFactor = sex == 'F' ? 0.5 : 0.6;
  final tbw = wt * tbwFactor;
  final deficit = tbw * (current / target - 1);
  return FormulaResult([
    FormulaOutput(
      label: 'Free water deficit',
      value: fmtNum(deficit),
      unit: 'L',
      primary: true,
      interpretation: 'Deficit only — add ongoing/insensible losses.',
    ),
  ]);
}

// ── renal_function: Cockcroft-Gault CrCl + CKD-EPI 2021 eGFR ──────────

FormulaResult _renalFunction(Map<String, dynamic> v) {
  final age = _num(v, 'age');
  final sex = _sel(v, 'sex');
  final scr = _creatinineMgDl(v, 'creatinine', 'cr_unit');
  if (age == null || age <= 0 || sex == null || scr == null) {
    return const FormulaResult.empty();
  }
  final female = sex == 'F';
  final out = <FormulaOutput>[];

  // Cockcroft-Gault (mL/min) — needs weight.
  final wt = _num(v, 'weight');
  if (wt != null && wt > 0) {
    final crcl = (140 - age) * wt * (female ? 0.85 : 1.0) / (72 * scr);
    out.add(FormulaOutput(
      label: 'CrCl (Cockcroft-Gault)',
      value: fmtNum(crcl),
      unit: 'mL/min',
      primary: true,
      interpretation: 'Use for drug dosing (matches legacy label cut-points).',
    ));
  }

  // CKD-EPI 2021 creatinine, race-free (mL/min/1.73m²).
  final kappa = female ? 0.7 : 0.9;
  final alpha = female ? -0.241 : -0.302;
  final ratio = scr / kappa;
  final egfr = 142 *
      _pow(ratio < 1 ? ratio : 1, alpha) *
      _pow(ratio > 1 ? ratio : 1, -1.200) *
      _pow(0.9938, age) *
      (female ? 1.012 : 1.0);
  out.add(FormulaOutput(
    label: 'eGFR (CKD-EPI 2021, race-free)',
    value: fmtNum(egfr),
    unit: 'mL/min/1.73m²',
    interpretation: 'For CKD staging. De-index (×BSA/1.73) before drug dosing.',
  ));
  return FormulaResult(out);
}

// ── map ──────────────────────────────────────────────────────────────

FormulaResult _map(Map<String, dynamic> v) {
  final sbp = _num(v, 'sbp');
  final dbp = _num(v, 'dbp');
  if (sbp == null || dbp == null || sbp < dbp) return const FormulaResult.empty();
  final map = dbp + (sbp - dbp) / 3;
  return FormulaResult([
    FormulaOutput(
      label: 'Mean arterial pressure',
      value: fmtNum(map),
      unit: 'mmHg',
      primary: true,
      severity: map < 65 ? FormulaSeverity.alert : FormulaSeverity.none,
      interpretation: map < 65 ? 'MAP < 65 — organ-perfusion concern.' : null,
    ),
  ]);
}

// ── corrected_sodium (Hillier 2.4 primary; Katz 1.6 shown too) ────────

FormulaResult _correctedSodium(Map<String, dynamic> v) {
  final na = _num(v, 'sodium');
  final glu = _glucoseMgDl(v, 'glucose', 'glu_unit');
  if (na == null || glu == null) return const FormulaResult.empty();
  final delta = (glu - 100) / 100;
  final hillier = na + 2.4 * delta;
  final katz = na + 1.6 * delta;
  return FormulaResult([
    FormulaOutput(
      label: 'Corrected Na⁺ (Hillier ×2.4)',
      value: fmtNum(hillier),
      unit: 'mEq/L',
      primary: true,
      interpretation: 'Evidence-preferred factor (esp. glucose > 400 mg/dL).',
    ),
    FormulaOutput(
      label: 'Corrected Na⁺ (Katz ×1.6)',
      value: fmtNum(katz),
      unit: 'mEq/L',
      interpretation: 'Legacy factor — shown for comparison.',
    ),
  ]);
}

// ── anion_gap (+ optional albumin correction) ─────────────────────────

FormulaResult _anionGap(Map<String, dynamic> v) {
  final na = _num(v, 'sodium');
  final cl = _num(v, 'chloride');
  final hco3 = _num(v, 'bicarbonate');
  if (na == null || cl == null || hco3 == null) return const FormulaResult.empty();
  final ag = na - (cl + hco3);
  final high = ag > 12;
  final out = <FormulaOutput>[
    FormulaOutput(
      label: 'Anion gap',
      value: fmtNum(ag),
      unit: 'mEq/L',
      primary: true,
      severity: high ? FormulaSeverity.warn : FormulaSeverity.none,
      interpretation: high
          ? 'High anion gap (normal ≈ 8–12).'
          : 'Normal range ≈ 8–12 mEq/L.',
    ),
  ];
  final albumin = _num(v, 'albumin');
  if (albumin != null && albumin > 0) {
    final corrected = ag + 2.5 * (4.0 - albumin);
    final cHigh = corrected > 12;
    out.add(FormulaOutput(
      label: 'Albumin-corrected AG',
      value: fmtNum(corrected),
      unit: 'mEq/L',
      severity: cHigh ? FormulaSeverity.warn : FormulaSeverity.none,
      interpretation:
          'Unmasks occult gap when albumin is low — not a lactate surrogate.',
    ));
  }
  return FormulaResult(out);
}

// ── aa_gradient ───────────────────────────────────────────────────────

FormulaResult _aaGradient(Map<String, dynamic> v) {
  final fio2pct = _num(v, 'fio2');
  final paco2 = _num(v, 'paco2');
  final pao2 = _num(v, 'pao2');
  final age = _num(v, 'age');
  if (fio2pct == null || paco2 == null || pao2 == null) {
    return const FormulaResult.empty();
  }
  final patm = _num(v, 'patm') ?? 760.0; // sea level default
  const ph2o = 47.0;
  const r = 0.8;
  final pAO2 = (fio2pct / 100) * (patm - ph2o) - paco2 / r;
  final aa = pAO2 - pao2;
  final out = <FormulaOutput>[
    FormulaOutput(
      label: 'A–a gradient',
      value: fmtNum(aa),
      unit: 'mmHg',
      primary: true,
    ),
  ];
  if (age != null && age > 0) {
    final expected = age / 4 + 4;
    final elevated = aa > expected;
    out.add(FormulaOutput(
      label: 'Expected (age-adjusted)',
      value: '≤ ${fmtNum(expected)}',
      unit: 'mmHg',
      severity: elevated ? FormulaSeverity.warn : FormulaSeverity.none,
      interpretation: elevated
          ? 'Elevated for age (age/4 + 4).'
          : 'Within age-expected range (age/4 + 4).',
    ));
  }
  return FormulaResult(out);
}

// ── winters ───────────────────────────────────────────────────────────

FormulaResult _winters(Map<String, dynamic> v) {
  final hco3 = _num(v, 'bicarbonate');
  if (hco3 == null) return const FormulaResult.empty();
  final expected = 1.5 * hco3 + 8;
  final lo = expected - 2;
  final hi = expected + 2;
  final out = <FormulaOutput>[
    FormulaOutput(
      label: 'Expected pCO₂',
      value: '${fmtNum(lo)}–${fmtNum(hi)}',
      unit: 'mmHg',
      primary: true,
      interpretation: 'Adequate respiratory compensation in metabolic acidosis.',
    ),
  ];
  final measured = _num(v, 'measured_pco2');
  if (measured != null) {
    final String interp;
    final FormulaSeverity sev;
    if (measured > hi) {
      interp = 'Measured > expected → concurrent respiratory acidosis.';
      sev = FormulaSeverity.warn;
    } else if (measured < lo) {
      interp = 'Measured < expected → concurrent respiratory alkalosis.';
      sev = FormulaSeverity.warn;
    } else {
      interp = 'Measured within expected → appropriate compensation.';
      sev = FormulaSeverity.none;
    }
    out.add(FormulaOutput(
      label: 'Measured pCO₂',
      value: fmtNum(measured),
      unit: 'mmHg',
      severity: sev,
      interpretation: interp,
    ));
  }
  return FormulaResult(out);
}

// ── ideal_body_weight (Devine) + adjusted body weight ─────────────────

FormulaResult _idealBodyWeight(Map<String, dynamic> v) {
  final height = _num(v, 'height');
  final sex = _sel(v, 'sex');
  if (height == null || height <= 0 || sex == null) {
    return const FormulaResult.empty();
  }
  final heightIn = _sel(v, 'height_unit') == 'in' ? height : height / 2.54;
  final female = sex == 'F';
  final base = female ? 45.5 : 50.0;
  final ibw = base + 2.3 * (heightIn - 60);
  final out = <FormulaOutput>[
    FormulaOutput(
      label: 'Ideal body weight (Devine)',
      value: fmtNum(ibw),
      unit: 'kg',
      primary: true,
    ),
  ];
  final actual = _num(v, 'weight');
  if (actual != null && actual > 0) {
    final adj = ibw + 0.4 * (actual - ibw);
    out.add(FormulaOutput(
      label: 'Adjusted body weight',
      value: fmtNum(adj),
      unit: 'kg',
      interpretation: 'IBW + 0.4 × (actual − IBW); use per drug-specific guidance.',
    ));
  }
  return FormulaResult(out);
}

// ── holliday_segar (4-2-1) ────────────────────────────────────────────

FormulaResult _hollidaySegar(Map<String, dynamic> v) {
  final wt = _num(v, 'weight');
  if (wt == null || wt <= 0) return const FormulaResult.empty();

  double daily;
  if (wt <= 10) {
    daily = wt * 100;
  } else if (wt <= 20) {
    daily = 1000 + (wt - 10) * 50;
  } else {
    daily = 1500 + (wt - 20) * 20;
  }

  double hourly;
  if (wt <= 10) {
    hourly = wt * 4;
  } else if (wt <= 20) {
    hourly = 40 + (wt - 10) * 2;
  } else {
    hourly = 60 + (wt - 20) * 1;
  }

  return FormulaResult([
    FormulaOutput(
      label: 'Maintenance rate',
      value: fmtNum(hourly),
      unit: 'mL/hr',
      primary: true,
      interpretation: 'Use an ISOTONIC fluid (AAP 2018) — not hypotonic.',
    ),
    FormulaOutput(
      label: 'Daily volume',
      value: fmtNum(daily),
      unit: 'mL/day',
    ),
  ]);
}

double _pow(double base, double exp) => math.pow(base, exp).toDouble();
