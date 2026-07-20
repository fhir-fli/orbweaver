// Golden-value tests for every clinical formula in the calculator registry.
//
// Correctness is the product here: a wrong output can mis-dose or mis-triage a
// patient. Each formula is checked with MULTIPLE hand-derived vectors
// (cross-checked against the published equation), plus unit-toggle equivalence,
// guard/edge cases, and interpretation-band boundaries.
//
// All expected numbers below were hand-computed from the cited formula, NOT
// read back from the implementation — so a divergence flags a real bug.

import 'package:flutter_test/flutter_test.dart';
import 'package:orbweaver/data/formula_registry.dart';

/// Parses the numeric part of an output value (handles a leading "≤ ").
double _v(FormulaResult r, int i) =>
    double.parse(r.outputs[i].value.replaceAll(RegExp(r'[^0-9.\-]'), ''));

FormulaOutput _byLabel(FormulaResult r, String needle) =>
    r.outputs.firstWhere((o) => o.label.toLowerCase().contains(needle));

void main() {
  group('renal_function — Cockcroft-Gault CrCl', () {
    // CrCl = (140 − age) × wt × (0.85 if F) / (72 × Scr[mg/dL])
    test('male 60y, 80kg, Scr 1.0 → 88.9 mL/min', () {
      final r = computeFormula('renal_function',
          {'age': 60, 'sex': 'M', 'weight': 80, 'creatinine': 1.0});
      expect(_byLabel(r, 'cockcroft').unit, 'mL/min');
      expect(_v(r, 0), closeTo(88.9, 0.1)); // 80×80/72
    });

    test('female applies 0.85 factor → 75.6 mL/min', () {
      final r = computeFormula('renal_function',
          {'age': 60, 'sex': 'F', 'weight': 80, 'creatinine': 1.0});
      expect(_v(r, 0), closeTo(75.6, 0.1)); // 88.888 × 0.85
    });

    test('elderly higher creatinine: 70y male 70kg Scr 1.2 → 56.7', () {
      final r = computeFormula('renal_function',
          {'age': 70, 'sex': 'M', 'weight': 70, 'creatinine': 1.2});
      expect(_v(r, 0), closeTo(56.7, 0.1)); // 70×70/86.4
    });

    test('creatinine unit toggle: 88.4 µmol/L ≡ 1.0 mg/dL', () {
      final mg = computeFormula('renal_function',
          {'age': 60, 'sex': 'M', 'weight': 80, 'creatinine': 1.0});
      final umol = computeFormula('renal_function', {
        'age': 60,
        'sex': 'M',
        'weight': 80,
        'creatinine': 88.4,
        'cr_unit': 'µmol/L',
      });
      expect(_v(umol, 0), closeTo(_v(mg, 0), 0.05));
    });

    test('no weight → CrCl omitted, only eGFR remains', () {
      final r = computeFormula(
          'renal_function', {'age': 60, 'sex': 'M', 'creatinine': 1.0});
      expect(r.outputs.any((o) => o.label.contains('Cockcroft')), isFalse);
      expect(r.outputs.any((o) => o.label.contains('eGFR')), isTrue);
    });
  });

  group('renal_function — CKD-EPI 2021 eGFR (race-free)', () {
    // 142 × min(Scr/κ,1)^α × max(Scr/κ,1)^−1.2 × 0.9938^age × (1.012 if F)
    test('male 60y Scr 1.0 → 86.2 (max-branch)', () {
      final r = computeFormula(
          'renal_function', {'age': 60, 'sex': 'M', 'creatinine': 1.0});
      expect(_byLabel(r, 'egfr').unit, 'mL/min/1.73m²');
      expect(_v(_single(r, 'egfr'), 0), closeTo(86.2, 0.4));
    });

    test('female 60y Scr 0.8 → 84.3 (female coefficients)', () {
      final r = computeFormula(
          'renal_function', {'age': 60, 'sex': 'F', 'creatinine': 0.8});
      expect(_egfr(r), closeTo(84.3, 0.4));
    });

    test('female 40y Scr 0.5 → 121.6 (min/α branch, Scr<κ)', () {
      final r = computeFormula(
          'renal_function', {'age': 40, 'sex': 'F', 'creatinine': 0.5});
      expect(_egfr(r), closeTo(121.6, 0.5));
    });

    test('missing age → empty (no wrong number)', () {
      expect(
        computeFormula('renal_function', {'sex': 'M', 'creatinine': 1.0}).isEmpty,
        isTrue,
      );
    });
  });

  group('map', () {
    test('120/80 → 93.3 mmHg', () {
      final r = computeFormula('map', {'sbp': 120, 'dbp': 80});
      expect(_v(r, 0), closeTo(93.3, 0.1));
      expect(r.outputs[0].severity, FormulaSeverity.none);
    });

    test('90/60 → 70, no alert', () {
      final r = computeFormula('map', {'sbp': 90, 'dbp': 60});
      expect(_v(r, 0), closeTo(70, 0.05));
      expect(r.outputs[0].severity, FormulaSeverity.none);
    });

    test('85/50 → 61.7, MAP<65 alert', () {
      final r = computeFormula('map', {'sbp': 85, 'dbp': 50});
      expect(_v(r, 0), closeTo(61.7, 0.1));
      expect(r.outputs[0].severity, FormulaSeverity.alert);
    });

    test('SBP < DBP is rejected → empty', () {
      expect(computeFormula('map', {'sbp': 80, 'dbp': 90}).isEmpty, isTrue);
    });

    test('missing dbp → empty', () {
      expect(computeFormula('map', {'sbp': 120}).isEmpty, isTrue);
    });
  });

  group('corrected_sodium', () {
    test('Na 130, glu 600 → Hillier 142, Katz 138', () {
      final r =
          computeFormula('corrected_sodium', {'sodium': 130, 'glucose': 600});
      expect(_v(r, 0), closeTo(142, 0.05)); // 130 + 2.4×5
      expect(_v(r, 1), closeTo(138, 0.05)); // 130 + 1.6×5
    });

    test('Na 125, glu 200 → Hillier 127.4', () {
      final r =
          computeFormula('corrected_sodium', {'sodium': 125, 'glucose': 200});
      expect(_v(r, 0), closeTo(127.4, 0.05));
    });

    test('glucose unit toggle: 33.333 mmol/L ≡ 600 mg/dL', () {
      final mgdl =
          computeFormula('corrected_sodium', {'sodium': 130, 'glucose': 600});
      final mmol = computeFormula('corrected_sodium',
          {'sodium': 130, 'glucose': 33.333, 'glu_unit': 'mmol/L'});
      expect(_v(mmol, 0), closeTo(_v(mgdl, 0), 0.05));
    });

    test('missing glucose → empty', () {
      expect(computeFormula('corrected_sodium', {'sodium': 130}).isEmpty, isTrue);
    });
  });

  group('anion_gap', () {
    test('140/100/24 → AG 16, high', () {
      final r = computeFormula(
          'anion_gap', {'sodium': 140, 'chloride': 100, 'bicarbonate': 24});
      expect(_v(r, 0), closeTo(16, 0.05));
      expect(r.outputs[0].severity, FormulaSeverity.warn);
      expect(r.outputs, hasLength(1)); // no albumin → no correction row
    });

    test('140/105/25 → AG 10, normal', () {
      final r = computeFormula(
          'anion_gap', {'sodium': 140, 'chloride': 105, 'bicarbonate': 25});
      expect(_v(r, 0), closeTo(10, 0.05));
      expect(r.outputs[0].severity, FormulaSeverity.none);
    });

    test('albumin 2.0 adds corrected AG 21', () {
      final r = computeFormula('anion_gap',
          {'sodium': 140, 'chloride': 100, 'bicarbonate': 24, 'albumin': 2.0});
      expect(r.outputs, hasLength(2));
      expect(_v(r, 1), closeTo(21, 0.05)); // 16 + 2.5×(4−2)
    });

    test('albumin 4.0 (normal) leaves corrected == raw', () {
      final r = computeFormula('anion_gap',
          {'sodium': 140, 'chloride': 100, 'bicarbonate': 24, 'albumin': 4.0});
      expect(_v(r, 1), closeTo(16, 0.05));
    });

    test('missing bicarbonate → empty', () {
      expect(
        computeFormula('anion_gap', {'sodium': 140, 'chloride': 100}).isEmpty,
        isTrue,
      );
    });
  });

  group('aa_gradient', () {
    // PAO2 = FiO2×(760−47) − PaCO2/0.8 ; A-a = PAO2 − PaO2
    test('room air 40/90, age 40 → A-a 9.7, within expected 14', () {
      final r = computeFormula(
          'aa_gradient', {'fio2': 21, 'paco2': 40, 'pao2': 90, 'age': 40});
      expect(_v(r, 0), closeTo(9.7, 0.1));
      expect(_byLabel(r, 'expected').severity, FormulaSeverity.none);
    });

    test('room air 40/60, age 40 → A-a 39.7, elevated for age', () {
      final r = computeFormula(
          'aa_gradient', {'fio2': 21, 'paco2': 40, 'pao2': 60, 'age': 40});
      expect(_v(r, 0), closeTo(39.7, 0.1));
      expect(_byLabel(r, 'expected').severity, FormulaSeverity.warn);
    });

    test('atmospheric-pressure override changes PAO2 (altitude)', () {
      final sea = computeFormula(
          'aa_gradient', {'fio2': 21, 'paco2': 40, 'pao2': 60});
      final alt = computeFormula('aa_gradient',
          {'fio2': 21, 'paco2': 40, 'pao2': 60, 'patm': 700});
      expect(_v(sea, 0), closeTo(39.7, 0.1)); // 99.73 − 60
      expect(_v(alt, 0), closeTo(27.1, 0.2)); // 0.21×653 − 50 − 60
      expect(_v(alt, 0), lessThan(_v(sea, 0)));
    });

    test('no age → only the gradient, no expected row', () {
      final r =
          computeFormula('aa_gradient', {'fio2': 21, 'paco2': 40, 'pao2': 90});
      expect(r.outputs, hasLength(1));
    });

    test('missing pao2 → empty', () {
      expect(
        computeFormula('aa_gradient', {'fio2': 21, 'paco2': 40}).isEmpty,
        isTrue,
      );
    });
  });

  group('winters', () {
    // expected pCO2 = 1.5×HCO3 + 8 (±2)
    test('HCO3 12 → expected 24–28', () {
      final r = computeFormula('winters', {'bicarbonate': 12});
      expect(r.outputs[0].value, '24–28');
    });

    test('measured 30 > 28 → concurrent respiratory acidosis', () {
      final r =
          computeFormula('winters', {'bicarbonate': 12, 'measured_pco2': 30});
      expect(r.outputs[1].severity, FormulaSeverity.warn);
      expect(r.outputs[1].interpretation, contains('acidosis'));
    });

    test('measured 26 within range → appropriate compensation', () {
      final r =
          computeFormula('winters', {'bicarbonate': 12, 'measured_pco2': 26});
      expect(r.outputs[1].severity, FormulaSeverity.none);
    });

    test('measured 20 < 24 → concurrent respiratory alkalosis', () {
      final r =
          computeFormula('winters', {'bicarbonate': 12, 'measured_pco2': 20});
      expect(r.outputs[1].severity, FormulaSeverity.warn);
      expect(r.outputs[1].interpretation, contains('alkalosis'));
    });

    test('no HCO3 → empty', () {
      expect(computeFormula('winters', const {}).isEmpty, isTrue);
    });
  });

  group('ideal_body_weight (Devine)', () {
    // male 50 + 2.3×(in−60); female 45.5 + 2.3×(in−60)
    test('male 180cm → 75.0 kg', () {
      final r = computeFormula(
          'ideal_body_weight', {'height': 180, 'sex': 'M'});
      expect(_v(r, 0), closeTo(75.0, 0.1)); // in=70.87
    });

    test('female 165cm → 56.9 kg', () {
      final r = computeFormula(
          'ideal_body_weight', {'height': 165, 'sex': 'F'});
      expect(_v(r, 0), closeTo(56.9, 0.1));
    });

    test('height unit toggle: 70.866 in ≡ 180 cm', () {
      final cm = computeFormula(
          'ideal_body_weight', {'height': 180, 'sex': 'M'});
      final inch = computeFormula('ideal_body_weight',
          {'height': 70.866, 'sex': 'M', 'height_unit': 'in'});
      expect(_v(inch, 0), closeTo(_v(cm, 0), 0.05));
    });

    test('actual weight adds adjusted BW: 180cm male, 120kg → 93', () {
      final r = computeFormula('ideal_body_weight',
          {'height': 180, 'sex': 'M', 'weight': 120});
      expect(r.outputs, hasLength(2));
      expect(_v(r, 1), closeTo(93.0, 0.2)); // 75 + 0.4×45
    });

    test('missing sex → empty', () {
      expect(computeFormula('ideal_body_weight', {'height': 180}).isEmpty, isTrue);
    });
  });

  group('holliday_segar (4-2-1)', () {
    void check(num kg, double hourly, double daily) {
      final r = computeFormula('holliday_segar', {'weight': kg});
      expect(_byLabel(r, 'rate').value, closeToStr(hourly));
      expect(_byLabel(r, 'daily').value, closeToStr(daily));
    }

    test('5 kg → 20 mL/hr, 500 mL/day', () => check(5, 20, 500));
    test('15 kg → 50 mL/hr, 1250 mL/day', () => check(15, 50, 1250));
    test('30 kg → 70 mL/hr, 1700 mL/day', () => check(30, 70, 1700));
    test('70 kg → 110 mL/hr, 2500 mL/day', () => check(70, 110, 2500));

    test('zero/negative weight → empty', () {
      expect(computeFormula('holliday_segar', {'weight': 0}).isEmpty, isTrue);
    });
  });

  group('registry guards', () {
    test('unknown kind → empty (author typo fails safe)', () {
      expect(computeFormula('does_not_exist', {'x': 1}).isEmpty, isTrue);
    });

    test('fmtNum trims trailing zeros, no false precision', () {
      expect(fmtNum(70), '70');
      expect(fmtNum(93.333), '93.3');
      expect(fmtNum(75), '75');
      expect(fmtNum(56.90), '56.9');
    });
  });
}

// helpers ────────────────────────────────────────────────────────────

FormulaResult _single(FormulaResult r, String label) => FormulaResult(
    [r.outputs.firstWhere((o) => o.label.toLowerCase().contains(label))]);

double _egfr(FormulaResult r) => double.parse(
    r.outputs.firstWhere((o) => o.label.contains('eGFR')).value);

/// Matcher-ish helper: format an expected integer-valued mL the way fmtNum does.
String closeToStr(double v) => fmtNum(v);
