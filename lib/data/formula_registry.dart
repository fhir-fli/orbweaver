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
    _ => const FormulaResult.empty(),
  };
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
