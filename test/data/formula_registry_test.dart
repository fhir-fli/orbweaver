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

  group('meld3 (OPTN 2023)', () {
    // female, bili 2.0, Na 130, INR 1.5, Cr 1.5, alb 3.0 → 23.82 → 24
    test('worked example → 24', () {
      final r = computeFormula('meld3', {
        'sex': 'F',
        'bilirubin': 2.0,
        'sodium': 130,
        'inr': 1.5,
        'creatinine': 1.5,
        'albumin': 3.0,
      });
      expect(r.outputs.first.value, '24');
    });

    test('lab lower-bounds + creatinine cap → 18', () {
      // male, bili 0.5→1, Na 145→137, INR 0.9→1, Cr 5→3, alb 1.0→1.5
      final r = computeFormula('meld3', {
        'sex': 'M',
        'bilirubin': 0.5,
        'sodium': 145,
        'inr': 0.9,
        'creatinine': 5,
        'albumin': 1.0,
      });
      expect(r.outputs.first.value, '18');
    });

    test('dialysis forces creatinine to 3.0', () {
      final r = computeFormula('meld3', {
        'sex': 'M',
        'bilirubin': 0.5,
        'sodium': 145,
        'inr': 0.9,
        'creatinine': 1.0,
        'albumin': 1.0,
        'dialysis': 'yes',
      });
      expect(r.outputs.first.value, '18'); // same as Cr 5 case
    });

    test('healthy labs clamp to the floor of 6', () {
      final r = computeFormula('meld3', {
        'sex': 'M',
        'bilirubin': 1.0,
        'sodium': 137,
        'inr': 1.0,
        'creatinine': 1.0,
        'albumin': 3.5,
      });
      expect(r.outputs.first.value, '6');
    });

    test('creatinine unit toggle honored', () {
      final mg = computeFormula('meld3', {
        'sex': 'F',
        'bilirubin': 2.0,
        'sodium': 130,
        'inr': 1.5,
        'creatinine': 1.5,
        'albumin': 3.0,
      });
      final umol = computeFormula('meld3', {
        'sex': 'F',
        'bilirubin': 2.0,
        'sodium': 130,
        'inr': 1.5,
        'creatinine': 132.6, // 1.5 mg/dL × 88.4
        'cr_unit': 'µmol/L',
        'albumin': 3.0,
      });
      expect(umol.outputs.first.value, mg.outputs.first.value);
    });

    test('missing input → empty', () {
      expect(computeFormula('meld3', {'sex': 'F'}).isEmpty, isTrue);
    });
  });

  group('qtc', () {
    test('HR 60 → all formulas equal QT (RR = 1)', () {
      final r = computeFormula('qtc', {'qt': 400, 'hr': 60});
      for (final o in r.outputs) {
        expect(o.value, '400');
      }
    });

    test('HR 100, QT 400 → Fridericia 474, Bazett 516', () {
      final r = computeFormula('qtc', {'qt': 400, 'hr': 100});
      expect(r.outputs[0].value, '474'); // Fridericia (primary)
      expect(r.outputs[1].value, '516'); // Bazett
      expect(r.outputs[0].severity, FormulaSeverity.warn); // ≥460 prolonged
    });

    test('Fridericia > 500 → alert', () {
      final r = computeFormula('qtc', {'qt': 500, 'hr': 100});
      expect(r.outputs[0].severity, FormulaSeverity.alert);
    });

    test('missing HR → empty', () {
      expect(computeFormula('qtc', {'qt': 400}).isEmpty, isTrue);
    });
  });

  group('free_water_deficit', () {
    test('male 70kg, Na 160, target 140 → 6 L', () {
      final r = computeFormula('free_water_deficit',
          {'weight': 70, 'sex': 'M', 'sodium': 160, 'target': 140});
      expect(_v(r, 0), closeTo(6.0, 0.05));
    });

    test('female TBW factor 0.5: 60kg Na 154 → 3 L', () {
      final r = computeFormula('free_water_deficit',
          {'weight': 60, 'sex': 'F', 'sodium': 154, 'target': 140});
      expect(_v(r, 0), closeTo(3.0, 0.05));
    });

    test('target defaults to 140 when omitted', () {
      final r = computeFormula(
          'free_water_deficit', {'weight': 70, 'sex': 'M', 'sodium': 160});
      expect(_v(r, 0), closeTo(6.0, 0.05));
    });

    test('missing sodium → empty', () {
      expect(
        computeFormula('free_water_deficit', {'weight': 70, 'sex': 'M'}).isEmpty,
        isTrue,
      );
    });
  });

  group('anthropometrics (BMI + BSA)', () {
    test('180cm 80kg → BMI 24.7 normal, BSA 2.00', () {
      final r = computeFormula('anthropometrics', {'height': 180, 'weight': 80});
      expect(_v(r, 0), closeTo(24.7, 0.05)); // 80/1.8²
      expect(r.outputs[0].interpretation, contains('Normal'));
      expect(_v(r, 1), closeTo(2.0, 0.01)); // Mosteller √(180·80/3600)=2
    });
    test('BMI category + severity thresholds', () {
      expect(
        computeFormula('anthropometrics', {'height': 180, 'weight': 100})
            .outputs[0]
            .interpretation,
        contains('Obese'),
      );
      expect(
        computeFormula('anthropometrics', {'height': 180, 'weight': 55})
            .outputs[0]
            .interpretation,
        contains('Underweight'),
      );
    });
    test('height unit toggle: 70.866 in ≡ 180 cm', () {
      final cm = computeFormula('anthropometrics', {'height': 180, 'weight': 80});
      final inch = computeFormula('anthropometrics',
          {'height': 70.866, 'weight': 80, 'height_unit': 'in'});
      expect(_v(inch, 0), closeTo(_v(cm, 0), 0.05));
    });
    test('missing weight → empty', () {
      expect(computeFormula('anthropometrics', {'height': 180}).isEmpty, isTrue);
    });
  });

  group('osmolal_gap', () {
    test('measured 300, Na 140, glu 90, BUN 14 → gap 10', () {
      final r = computeFormula('osmolal_gap',
          {'measured': 300, 'sodium': 140, 'glucose': 90, 'bun': 14});
      expect(_v(r, 1), closeTo(290, 0.05)); // calc = 280+5+5
      expect(_v(r, 0), closeTo(10, 0.05));
    });
    test('ethanol is added to calculated osmolality', () {
      final r = computeFormula('osmolal_gap', {
        'measured': 300,
        'sodium': 140,
        'glucose': 90,
        'bun': 14,
        'ethanol': 100,
      });
      expect(_v(r, 1), closeTo(290 + 100 / 3.7, 0.05));
    });
    test('gap > 10 flags warn', () {
      final r = computeFormula('osmolal_gap',
          {'measured': 320, 'sodium': 140, 'glucose': 90, 'bun': 14});
      expect(r.outputs[0].severity, FormulaSeverity.warn);
    });
    test('missing BUN → empty', () {
      expect(
        computeFormula('osmolal_gap',
                {'measured': 300, 'sodium': 140, 'glucose': 90})
            .isEmpty,
        isTrue,
      );
    });
  });

  group('parkland (burn fluid)', () {
    test('ABA default 2 mL/kg: 70kg 40% → 5600 mL, 2800/2800', () {
      final r = computeFormula('parkland', {'weight': 70, 'tbsa': 40});
      expect(_v(r, 0), closeTo(5600, 0.5)); // 2×70×40
      expect(r.outputs[1].value, contains('2800')); // first 8h
      expect(r.outputs[1].unit, contains('350')); // 2800/8 mL/h
    });
    test('4 mL/kg legacy coefficient doubles it', () {
      final r =
          computeFormula('parkland', {'weight': 70, 'tbsa': 40, 'coefficient': '4'});
      expect(_v(r, 0), closeTo(11200, 0.5));
    });
    test('missing TBSA → empty', () {
      expect(computeFormula('parkland', {'weight': 70}).isEmpty, isTrue);
    });
  });

  group('urinary_indices (FENa / FEUrea)', () {
    test('prerenal: FENa 0.36%', () {
      final r = computeFormula('urinary_indices', {
        'serum_na': 140,
        'urine_na': 10,
        'serum_cr': 5,
        'urine_cr': 100,
      });
      expect(_v(r, 0), closeTo(0.36, 0.01)); // (10×5)/(140×100)×100
      expect(r.outputs[0].interpretation, contains('prerenal'));
    });
    test('intrinsic: FENa > 2% flagged', () {
      final r = computeFormula('urinary_indices', {
        'serum_na': 140,
        'urine_na': 60,
        'serum_cr': 2,
        'urine_cr': 20,
      });
      expect(_v(r, 0), closeTo(4.29, 0.02)); // (60×2)/(140×20)×100
      expect(r.outputs[0].interpretation, contains('intrinsic'));
    });
    test('FEUrea added only when urea provided', () {
      final base = computeFormula('urinary_indices',
          {'serum_na': 140, 'urine_na': 10, 'serum_cr': 5, 'urine_cr': 100});
      expect(base.outputs, hasLength(1));
      final withUrea = computeFormula('urinary_indices', {
        'serum_na': 140,
        'urine_na': 10,
        'serum_cr': 5,
        'urine_cr': 100,
        'serum_urea': 40,
        'urine_urea': 200,
      });
      expect(withUrea.outputs, hasLength(2));
      expect(_v(withUrea, 1), closeTo(25.0, 0.1)); // (200×5)/(40×100)×100
    });
    test('missing urine creatinine → empty', () {
      expect(
        computeFormula('urinary_indices',
                {'serum_na': 140, 'urine_na': 10, 'serum_cr': 5})
            .isEmpty,
        isTrue,
      );
    });
  });

  group('anc', () {
    test('WBC 7.5, segs 60, bands 3 → 4725 cells/µL', () {
      final r = computeFormula('anc', {'wbc': 7.5, 'segs': 60, 'bands': 3});
      expect(_v(r, 0), closeTo(4725, 0.5));
      expect(r.outputs[0].severity, FormulaSeverity.none);
    });
    test('bands optional (defaults 0)', () {
      final r = computeFormula('anc', {'wbc': 7.5, 'segs': 60});
      expect(_v(r, 0), closeTo(4500, 0.5));
    });
    test('severe neutropenia flag < 500', () {
      final r = computeFormula('anc', {'wbc': 0.5, 'segs': 50});
      expect(_v(r, 0), closeTo(250, 0.5));
      expect(r.outputs[0].severity, FormulaSeverity.alert);
    });
    test('missing segs → empty', () {
      expect(computeFormula('anc', {'wbc': 7.5}).isEmpty, isTrue);
    });
  });

  group('reticulocyte (RPI)', () {
    test('retic 5%, Hct 30 → corrected 3.3%, RPI 2.2', () {
      final r = computeFormula('reticulocyte', {'retic': 5, 'hct': 30});
      expect(_v(r, 0), closeTo(2.2, 0.05)); // RPI (primary): 3.333/1.5
      expect(_v(r, 1), closeTo(3.3, 0.05)); // corrected retic
    });
    test('maturation factor steps with Hct', () {
      // Hct 45 → factor 1.0; retic 1% → corrected 1.0 → RPI 1.0 (inadequate)
      final r = computeFormula('reticulocyte', {'retic': 1, 'hct': 45});
      expect(_v(r, 0), closeTo(1.0, 0.02));
      expect(r.outputs[0].severity, FormulaSeverity.warn);
    });
    test('missing Hct → empty', () {
      expect(computeFormula('reticulocyte', {'retic': 5}).isEmpty, isTrue);
    });
  });

  group("Light's criteria", () {
    test('protein ratio > 0.5 → exudate', () {
      final r = computeFormula('lights', {
        'pleural_protein': 4.0,
        'serum_protein': 6.0,
        'pleural_ldh': 100,
        'serum_ldh': 200,
        'serum_ldh_uln': 250,
      });
      expect(r.outputs[0].label, 'Exudate'); // protein ratio 0.667 > 0.5
      expect(_v(r, 1), closeTo(0.67, 0.01)); // protein ratio row
    });
    test('all ratios below thresholds → transudate (0/3)', () {
      final r = computeFormula('lights', {
        'pleural_protein': 2.0,
        'serum_protein': 7.0,
        'pleural_ldh': 80,
        'serum_ldh': 200,
        'serum_ldh_uln': 250,
      });
      expect(r.outputs[0].label, 'Transudate');
      expect(r.outputs[0].value, '0/3');
    });
    test('missing serum LDH ULN → empty', () {
      expect(
        computeFormula('lights', {
          'pleural_protein': 4.0,
          'serum_protein': 6.0,
          'pleural_ldh': 100,
          'serum_ldh': 200,
        }).isEmpty,
        isTrue,
      );
    });
  });

  group('fib4', () {
    test('age 60, AST 50, plt 150, ALT 40 → 3.16 (high)', () {
      final r = computeFormula(
          'fib4', {'age': 60, 'ast': 50, 'alt': 40, 'platelets': 150});
      expect(_v(r, 0), closeTo(3.16, 0.02)); // (60×50)/(150×√40)
      expect(r.outputs[0].severity, FormulaSeverity.alert);
    });
    test('low result flagged low (< 1.3)', () {
      final r = computeFormula(
          'fib4', {'age': 40, 'ast': 20, 'alt': 25, 'platelets': 250});
      expect(r.outputs[0].severity, FormulaSeverity.none);
      expect(r.outputs[0].interpretation, contains('Low'));
    });
    test('age > 65 raises the low cutoff to 2.0', () {
      // FIB-4 ~1.6 → indeterminate under 1.3 cutoff, but LOW under 2.0 (>65)
      final r = computeFormula(
          'fib4', {'age': 70, 'ast': 30, 'alt': 30, 'platelets': 200});
      expect(_v(r, 0), closeTo(1.92, 0.05)); // (70×30)/(200×√30)
      expect(r.outputs[0].interpretation, contains('Low'));
    });
    test('missing platelets → empty', () {
      expect(
        computeFormula('fib4', {'age': 60, 'ast': 50, 'alt': 40}).isEmpty,
        isTrue,
      );
    });
  });

  group('maddrey', () {
    test('PT 20, control 12, bili 10 → 46.8 (severe)', () {
      final r = computeFormula(
          'maddrey', {'pt': 20, 'control_pt': 12, 'bilirubin': 10});
      expect(_v(r, 0), closeTo(46.8, 0.05)); // 4.6×8 + 10
      expect(r.outputs[0].severity, FormulaSeverity.alert);
    });
    test('below 32 not severe', () {
      final r = computeFormula(
          'maddrey', {'pt': 14, 'control_pt': 12, 'bilirubin': 5});
      expect(_v(r, 0), closeTo(14.2, 0.05)); // 4.6×2 + 5
      expect(r.outputs[0].severity, FormulaSeverity.none);
    });
  });

  group('oxygenation (P/F, S/F)', () {
    test('PaO2 90 on 21% → P/F 429', () {
      final r = computeFormula('oxygenation', {'fio2': 21, 'pao2': 90});
      expect(_v(r, 0), closeTo(429, 1)); // 90/0.21
      expect(r.outputs[0].severity, FormulaSeverity.none);
    });
    test('PaO2 90 on 100% → P/F 90 (severe ARDS range)', () {
      final r = computeFormula('oxygenation', {'fio2': 100, 'pao2': 90});
      expect(_v(r, 0), closeTo(90, 0.5));
      expect(r.outputs[0].severity, FormulaSeverity.alert);
    });
    test('S/F added when SpO2 given', () {
      final r =
          computeFormula('oxygenation', {'fio2': 21, 'pao2': 90, 'spo2': 95});
      expect(r.outputs, hasLength(2));
      expect(_v(r, 1), closeTo(452, 1)); // 95/0.21
    });
    test('no PaO2 and no SpO2 → empty', () {
      expect(computeFormula('oxygenation', {'fio2': 21}).isEmpty, isTrue);
    });
  });

  group('dday_age (age-adjusted D-dimer)', () {
    test('age 80 → cutoff 800', () {
      final r = computeFormula('dday_age', {'age': 80});
      expect(_v(r, 0), closeTo(800, 0.5)); // 80×10
    });
    test('age ≤ 50 → conventional 500', () {
      expect(_v(computeFormula('dday_age', {'age': 45}), 0), closeTo(500, 0.5));
    });
    test('measured value interpreted vs cutoff', () {
      final pos = computeFormula('dday_age', {'age': 80, 'measured': 850});
      expect(pos.outputs[1].severity, FormulaSeverity.warn);
      final neg = computeFormula('dday_age', {'age': 80, 'measured': 600});
      expect(neg.outputs[1].severity, FormulaSeverity.none); // < 800 cutoff
    });
    test('missing age → empty', () {
      expect(computeFormula('dday_age', const {}).isEmpty, isTrue);
    });
  });

  group('lille (steroid response)', () {
    // Coefficients cross-checked vs the original Louvet µmol model; expected
    // values hand-computed from R = exp(-R)/(1+exp(-R)).
    test('falling bilirubin, no renal insuff → 0.31 (responder)', () {
      final r = computeFormula('lille', {
        'age': 50,
        'albumin': 2.5,
        'bilirubin_day0': 15,
        'bilirubin_day7': 12,
        'creatinine': 1.0,
        'pt': 20,
      });
      expect(_v(r, 0), closeTo(0.31, 0.01));
      expect(r.outputs[0].severity, FormulaSeverity.none);
    });
    test('rising bilirubin + renal insuff (Cr>1.3) → 0.75 (non-responder)', () {
      final r = computeFormula('lille', {
        'age': 50,
        'albumin': 2.5,
        'bilirubin_day0': 15,
        'bilirubin_day7': 18,
        'creatinine': 2.0,
        'pt': 20,
      });
      expect(_v(r, 0), closeTo(0.75, 0.01));
      expect(r.outputs[0].severity, FormulaSeverity.alert);
    });
    test('renal term is binary at 1.3 mg/dL threshold', () {
      final below = computeFormula('lille', {
        'age': 50, 'albumin': 2.5, 'bilirubin_day0': 15,
        'bilirubin_day7': 15, 'creatinine': 1.3, 'pt': 20,
      });
      final above = computeFormula('lille', {
        'age': 50, 'albumin': 2.5, 'bilirubin_day0': 15,
        'bilirubin_day7': 15, 'creatinine': 1.4, 'pt': 20,
      });
      // Crossing 1.3 subtracts 0.206 from R → raises the Lille score.
      expect(_v(above, 0), greaterThan(_v(below, 0)));
    });
    test('missing PT → empty', () {
      expect(
        computeFormula('lille', {
          'age': 50, 'albumin': 2.5, 'bilirubin_day0': 15,
          'bilirubin_day7': 12, 'creatinine': 1.0,
        }).isEmpty,
        isTrue,
      );
    });
  });

  group('prevent_ascvd (AHA PREVENT 10-yr)', () {
    // Coefficients from Khan Circulation 2024 via preventr; validated against
    // the preventr worked example (→ 9.2%) and the paper's Table 2 HRs.
    test('preventr worked example → 9.2%', () {
      final r = computeFormula('prevent_ascvd', {
        'sex': 'F',
        'age': 50,
        'total_c': 200,
        'hdl_c': 45,
        'sbp': 160,
        'egfr': 90,
        'bp_tx': 'yes',
        'statin': 'no',
        'diabetes': 'yes',
        'smoking': 'no',
      });
      expect(_v(r, 0), closeTo(9.2, 0.1));
    });
    test('cholesterol unit toggle: mmol/L ≡ mg/dL', () {
      // TC 200 mg/dL = 5.172 mmol/L; HDL 45 = 1.164 mmol/L
      final mg = computeFormula('prevent_ascvd', {
        'sex': 'F', 'age': 50, 'total_c': 200, 'hdl_c': 45, 'sbp': 160,
        'egfr': 90, 'bp_tx': 'yes', 'diabetes': 'yes',
      });
      final mmol = computeFormula('prevent_ascvd', {
        'sex': 'F', 'age': 50, 'total_c': 5.172, 'hdl_c': 1.164,
        'chol_unit': 'mmol/L', 'sbp': 160, 'egfr': 90, 'bp_tx': 'yes',
        'diabetes': 'yes',
      });
      expect(_v(mmol, 0), closeTo(_v(mg, 0), 0.1));
    });
    test('lower-risk male → single-digit or lower, no alert', () {
      final r = computeFormula('prevent_ascvd', {
        'sex': 'M', 'age': 40, 'total_c': 170, 'hdl_c': 55, 'sbp': 120,
        'egfr': 100,
      });
      expect(_v(r, 0), lessThan(5));
      expect(r.outputs[0].severity, FormulaSeverity.none);
    });
    test('missing eGFR → empty', () {
      expect(
        computeFormula('prevent_ascvd', {
          'sex': 'F', 'age': 50, 'total_c': 200, 'hdl_c': 45, 'sbp': 160,
        }).isEmpty,
        isTrue,
      );
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
