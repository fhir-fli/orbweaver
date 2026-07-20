// Golden-value tests for the score engine + each authored score.
//
// Correctness is the product: a wrong point weight or band boundary
// mis-triages a patient. Each score is loaded from its real YAML and checked
// with hand-derived selection → total → band vectors verified against the
// published score. Boundary totals (band edges) are exercised explicitly.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:orbweaver/data/score_engine.dart';
import 'package:orbweaver/models/topic.dart';

const _dir = 'assets/books/calculators/topics';

ScoreBlock _load(String file) => Topic.fromYamlString(
      File('$_dir/$file').readAsStringSync(),
    ).blocks.whereType<ScoreBlock>().single;

/// total for a selection map.
num _total(ScoreBlock b, Map<String, dynamic> sel) =>
    computeScore(b, sel).total;

/// band label for a selection map.
String _band(ScoreBlock b, Map<String, dynamic> sel) =>
    computeScore(b, sel).band!.label;

void main() {
  group('CHA₂DS₂-VASc', () {
    late ScoreBlock b;
    setUpAll(() => b = _load('calc_cha2ds2_vasc.yaml'));

    test('all absent → 0, Low risk', () {
      expect(_total(b, {'age': 'lt65'}), 0);
      expect(_band(b, {'age': 'lt65'}), contains('Low risk'));
    });
    test('age ≥75 alone → 2 (recommended)', () {
      expect(_total(b, {'age': 'ge75'}), 2);
      expect(_band(b, {'age': 'ge75'}), contains('recommended'));
    });
    test('prior stroke alone → 2', () {
      expect(_total(b, {'age': 'lt65', 'stroke': true}), 2);
    });
    test('female alone → 1 (intermediate)', () {
      expect(_total(b, {'age': 'lt65', 'female': true}), 1);
      expect(_band(b, {'age': 'lt65', 'female': true}), contains('men'));
    });
    test('CHF+HTN+DM+age65–74 → 4', () {
      expect(
        _total(b, {'chf': true, 'htn': true, 'dm': true, 'age': '65_74'}),
        4,
      );
    });
    test('maximum = 9', () {
      expect(scoreRange(b).max, 9);
      expect(
        _total(b, {
          'chf': true,
          'htn': true,
          'age': 'ge75',
          'dm': true,
          'stroke': true,
          'vasc': true,
          'female': true,
        }),
        9,
      );
    });
  });

  group('HAS-BLED', () {
    late ScoreBlock b;
    setUpAll(() => b = _load('calc_hasbled.yaml'));

    test('none → 0, low–moderate', () {
      expect(_total(b, const {}), 0);
      expect(_band(b, const {}), contains('Low'));
    });
    test('3 factors → 3, high (boundary)', () {
      final s = {'htn': true, 'renal': true, 'stroke': true};
      expect(_total(b, s), 3);
      expect(_band(b, s), contains('High'));
    });
    test('2 factors → still low–moderate (below threshold)', () {
      expect(_band(b, {'htn': true, 'renal': true}), contains('Low'));
    });
    test('all nine → 9', () => expect(scoreRange(b).max, 9));
  });

  group('Wells DVT (two-level, has a −2 item)', () {
    late ScoreBlock b;
    setUpAll(() => b = _load('calc_wells_dvt.yaml'));

    test('none → 0, DVT unlikely', () {
      expect(_total(b, const {}), 0);
      expect(_band(b, const {}), contains('unlikely'));
    });
    test('alternative diagnosis subtracts 2', () {
      expect(_total(b, {'alt_dx': true}), -2);
      expect(_total(b, {'cancer': true, 'alt_dx': true}), -1);
    });
    test('score 2 → DVT likely (boundary)', () {
      final s = {'cancer': true, 'tender': true};
      expect(_total(b, s), 2);
      expect(_band(b, s), contains('likely'));
    });
    test('score 1 → still unlikely', () {
      expect(_band(b, {'cancer': true}), contains('unlikely'));
    });
    test('range spans −2 … 9', () {
      expect(scoreRange(b).min, -2);
      expect(scoreRange(b).max, 9);
    });
  });

  group('Wells PE (half-point weights, cutoff > 4)', () {
    late ScoreBlock b;
    setUpAll(() => b = _load('calc_wells_pe.yaml'));

    test('none → 0, PE unlikely', () {
      expect(_total(b, const {}), 0);
      expect(_band(b, const {}), contains('unlikely'));
    });
    test('exactly 4 → PE unlikely (≤4)', () {
      final s = {'dvt_signs': true, 'hemoptysis': true}; // 3 + 1
      expect(_total(b, s), 4);
      expect(_band(b, s), contains('unlikely'));
    });
    test('4.5 → PE likely (>4)', () {
      final s = {'dvt_signs': true, 'tachy': true}; // 3 + 1.5
      expect(_total(b, s), 4.5);
      expect(_band(b, s), contains('likely'));
    });
    test('maximum = 12.5', () => expect(scoreRange(b).max, 12.5));
  });

  group('PERC (all-negative rule)', () {
    late ScoreBlock b;
    setUpAll(() => b = _load('calc_perc.yaml'));

    test('all negative → 0, PERC negative', () {
      expect(_total(b, const {}), 0);
      expect(_band(b, const {}), contains('excluded'));
    });
    test('any one positive → PERC positive', () {
      expect(_band(b, {'age50': true}), contains('not excluded'));
    });
    test('maximum = 8', () => expect(scoreRange(b).max, 8));
  });

  group('CURB-65', () {
    late ScoreBlock b;
    setUpAll(() => b = _load('calc_curb65.yaml'));

    test('0–1 low', () {
      expect(_band(b, const {}), contains('Low'));
      expect(_band(b, {'confusion': true}), contains('Low'));
    });
    test('2 → moderate (boundary)', () {
      final s = {'confusion': true, 'age65': true};
      expect(_total(b, s), 2);
      expect(_band(b, s), contains('Moderate'));
    });
    test('3 → high (boundary)', () {
      final s = {'confusion': true, 'age65': true, 'rr': true};
      expect(_total(b, s), 3);
      expect(_band(b, s), contains('High'));
    });
    test('maximum = 5', () => expect(scoreRange(b).max, 5));
  });

  group('GCS (choice-only, sums 3–15)', () {
    late ScoreBlock b;
    setUpAll(() => b = _load('calc_gcs.yaml'));

    Map<String, dynamic> g(String e, String v, String m) =>
        {'eye': e, 'verbal': v, 'motor': m};

    test('normal E4V5M6 → 15, mild', () {
      expect(_total(b, g('e4', 'v5', 'm6')), 15);
      expect(_band(b, g('e4', 'v5', 'm6')), contains('Mild'));
    });
    test('E1V1M1 → 3, severe', () {
      expect(_total(b, g('e1', 'v1', 'm1')), 3);
      expect(_band(b, g('e1', 'v1', 'm1')), contains('Severe'));
    });
    test('8 → severe (boundary), 9 → moderate', () {
      expect(_band(b, g('e2', 'v2', 'm4')), contains('Severe')); // 2+2+4=8
      expect(_band(b, g('e2', 'v3', 'm4')), contains('Moderate')); // 9
    });
    test('12 → moderate (boundary), 13 → mild', () {
      expect(_band(b, g('e3', 'v4', 'm5')), contains('Moderate')); // 12
      expect(_band(b, g('e4', 'v4', 'm5')), contains('Mild')); // 13
    });
    test('reachable totals are exactly 3..15', () {
      expect(reachableTotals(b), {for (var i = 3; i <= 15; i++) i});
    });
  });

  group('Child-Pugh (5 three-option choices → A/B/C)', () {
    late ScoreBlock b;
    setUpAll(() => b = _load('calc_child_pugh.yaml'));

    Map<String, dynamic> cp(String bil, String alb, String inr, String asc,
            String enc) =>
        {'bilirubin': bil, 'albumin': alb, 'inr': inr, 'ascites': asc, 'enceph': enc};

    test('all mildest → 5, Class A', () {
      final s = cp('b1', 'a1', 'i1', 'as1', 'e1');
      expect(_total(b, s), 5);
      expect(_band(b, s), contains('Class A'));
    });
    test('6 → Class A, 7 → Class B (boundary)', () {
      expect(_band(b, cp('b2', 'a1', 'i1', 'as1', 'e1')), contains('Class A')); // 6
      expect(_band(b, cp('b2', 'a2', 'i1', 'as1', 'e1')), contains('Class B')); // 7
    });
    test('9 → B, 10 → C (boundary)', () {
      expect(_band(b, cp('b3', 'a2', 'i2', 'as1', 'e1')), contains('Class B')); // 9
      expect(_band(b, cp('b2', 'a2', 'i2', 'as2', 'e2')), contains('Class C')); // 10
    });
    test('all severe → 15, Class C', () {
      final s = cp('b3', 'a3', 'i3', 'as3', 'e3');
      expect(_total(b, s), 15);
      expect(_band(b, s), contains('Class C'));
    });
    test('reachable totals are exactly 5..15', () {
      expect(reachableTotals(b), {for (var i = 5; i <= 15; i++) i});
    });
  });

  group('HEART', () {
    late ScoreBlock b;
    setUpAll(() => b = _load('calc_heart.yaml'));

    Map<String, dynamic> h(String hi, String ec, String ag, String r,
            String t) =>
        {'history': hi, 'ecg': ec, 'age': ag, 'risk': r, 'troponin': t};

    test('all zero → 0, low', () {
      expect(_total(b, h('h0', 'ec0', 'ag0', 'r0', 't0')), 0);
      expect(_band(b, h('h0', 'ec0', 'ag0', 'r0', 't0')), contains('Low'));
    });
    test('3 → low, 4 → moderate (boundary)', () {
      expect(_band(b, h('h1', 'ec1', 'ag1', 'r0', 't0')), contains('Low')); // 3
      expect(_band(b, h('h1', 'ec1', 'ag1', 'r1', 't0')), contains('Moderate')); // 4
    });
    test('7 → high', () {
      expect(_band(b, h('h2', 'ec2', 'ag2', 'r1', 't0')), contains('High')); // 7
    });
    test('max 10', () => expect(scoreRange(b).max, 10));
  });

  group('4Ts (HIT)', () {
    late ScoreBlock b;
    setUpAll(() => b = _load('calc_4ts.yaml'));

    Map<String, dynamic> t4(String tc, String ti, String tb, String ot) =>
        {'thrombocytopenia': tc, 'timing': ti, 'thrombosis': tb, 'other': ot};

    test('all zero → 0, low (rule-out)', () {
      expect(_total(b, t4('tc0', 'ti0', 'tb0', 'ot0')), 0);
      expect(_band(b, t4('tc0', 'ti0', 'tb0', 'ot0')), contains('excluded'));
    });
    test('3 → low, 4 → intermediate (boundary)', () {
      expect(_band(b, t4('tc1', 'ti1', 'tb1', 'ot0')), contains('excluded')); // 3
      expect(_band(b, t4('tc2', 'ti1', 'tb1', 'ot0')), contains('Intermediate')); // 4
    });
    test('6 → high', () {
      expect(_band(b, t4('tc2', 'ti2', 'tb1', 'ot1')), contains('High')); // 6
    });
    test('max 8', () => expect(scoreRange(b).max, 8));
  });

  group('engine primitives', () {
    late ScoreBlock gcs;
    setUpAll(() => gcs = _load('calc_gcs.yaml'));

    test('bandFor resolves open-ended and interval bands', () {
      expect(bandFor(gcs, 15)!.label, contains('Mild'));
      expect(bandFor(gcs, 3)!.label, contains('Severe'));
    });
    test('unmatched total → null band', () {
      // GCS has no band below 3; total 0 shouldn't resolve.
      expect(bandFor(gcs, 0), isNull);
    });
  });
}
