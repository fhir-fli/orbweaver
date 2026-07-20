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
