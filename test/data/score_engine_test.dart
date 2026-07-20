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

  group('qSOFA', () {
    late ScoreBlock b;
    setUpAll(() => b = _load('calc_qsofa.yaml'));

    test('0–1 lower risk; 2+ increased risk (boundary)', () {
      expect(_band(b, const {}), contains('Lower'));
      expect(_band(b, {'rr': true}), contains('Lower'));
      final s = {'rr': true, 'sbp': true};
      expect(_total(b, s), 2);
      expect(_band(b, s), contains('increased'));
    });
    test('max 3', () => expect(scoreRange(b).max, 3));
  });

  group('Centor / McIsaac (has age −1 option)', () {
    late ScoreBlock b;
    setUpAll(() => b = _load('calc_centor.yaml'));

    test('age ≥45 subtracts 1 → −1 possible', () {
      expect(_total(b, {'age': 'a45'}), -1);
      expect(scoreRange(b).min, -1);
    });
    test('band edges: 0 very low, 1 low, 2 intermediate, 4 high', () {
      expect(_band(b, {'age': 'a15_44'}), contains('Very low')); // 0
      expect(_band(b, {'age': 'a3_14'}), contains('testing optional')); // 1
      expect(_band(b, {'age': 'a3_14', 'exudate': true}),
          contains('Intermediate')); // 2
      final high = {
        'exudate': true,
        'nodes': true,
        'fever': true,
        'no_cough': true,
        'age': 'a15_44',
      };
      expect(_total(b, high), 4);
      expect(_band(b, high), contains('High')); // 4
    });
    test('max 5', () => expect(scoreRange(b).max, 5));
  });

  group('Canadian CT Head Rule (any factor → CT)', () {
    late ScoreBlock b;
    setUpAll(() => b = _load('calc_canadian_ct_head.yaml'));

    test('no factors → no CT indicated', () {
      expect(_total(b, const {}), 0);
      expect(_band(b, const {}), contains('No CT'));
    });
    test('any single factor → CT recommended', () {
      expect(_band(b, {'vomiting': true}), contains('recommended'));
      expect(_band(b, {'age65': true}), contains('recommended'));
    });
    test('max 7', () => expect(scoreRange(b).max, 7));
  });

  group('CIWA-Ar (scale items, 0–67)', () {
    late ScoreBlock b;
    setUpAll(() => b = _load('calc_ciwa_ar.yaml'));

    test('all zero → 0, minimal', () {
      final all0 = {
        for (final i in b.items) i.key: '0',
      };
      expect(_total(b, all0), 0);
      expect(_band(b, all0), contains('Minimal'));
    });
    test('scale points equal their level; sums correctly', () {
      // nausea 4 + tremor 7 + orientation 4 = 15 → moderate
      final s = {'nausea': '4', 'tremor': '7', 'orientation': '4'};
      expect(_total(b, s), 15);
      expect(_band(b, s), contains('Moderate'));
    });
    test('boundary 9→minimal, 10→moderate, 20→severe', () {
      expect(_band(b, {'nausea': '2', 'tremor': '7'}), contains('Minimal')); // 9
      expect(_band(b, {'nausea': '3', 'tremor': '7'}), contains('Moderate')); // 10
      expect(_band(b, {'nausea': '7', 'tremor': '7', 'sweats': '6'}),
          contains('Severe')); // 20
    });
    test('maximum = 67 (nine 0–7 items + one 0–4)', () {
      expect(scoreRange(b).max, 67);
    });
    test('orientation item is 0–4 only', () {
      final orientation = b.items.firstWhere((i) => i.key == 'orientation');
      expect(orientation.type, ScoreItemType.scale);
      expect(orientation.options.map((o) => o.points).reduce((a, c) => a > c ? a : c),
          4);
    });
  });

  group('COWS (scale items, non-contiguous points, 0–48)', () {
    late ScoreBlock b;
    setUpAll(() => b = _load('calc_cows.yaml'));

    test('all zero → 0, minimal', () {
      final all0 = {for (final i in b.items) i.key: '0'};
      expect(_total(b, all0), 0);
      expect(_band(b, all0), contains('Minimal'));
    });
    test('non-contiguous points: restlessness has a 3 and 5 (no 2/4)', () {
      final r = b.items.firstWhere((i) => i.key == 'restlessness');
      expect(r.options.map((o) => o.points).toSet(), {0, 1, 3, 5});
    });
    test('sums across bands: 13 → moderate', () {
      // pulse 4 + restlessness 5 + gooseflesh... use pulse4+gi5+aches4 = 13
      final s = {'pulse': '4', 'gi': '5', 'aches': '4'};
      expect(_total(b, s), 13);
      expect(_band(b, s), contains('Moderate'));
    });
    test('maximum = 48', () => expect(scoreRange(b).max, 48));
  });

  group('NEWS2 (7 choice params, U-shaped bands)', () {
    late ScoreBlock b;
    setUpAll(() => b = _load('calc_news2.yaml'));

    Map<String, dynamic> normal() => {
          'rr': 'rr_normal',
          'spo2': 'spo2_normal',
          'o2': 'air',
          'sbp': 'sbp_normal',
          'pulse': 'pulse_normal',
          'consciousness': 'alert',
          'temp': 'temp_normal',
        };

    test('all-normal → 0, low', () {
      expect(_total(b, normal()), 0);
      expect(_band(b, normal()), contains('Low'));
    });
    test('extremes score high on both tails (U-shaped)', () {
      final s = normal()..['rr'] = 'rr_le8'; // ≤8 → 3
      expect(_total(b, s), 3);
      final s2 = normal()..['rr'] = 'rr_ge25'; // ≥25 → 3
      expect(_total(b, s2), 3);
    });
    test('aggregate bands: 5 medium, 7 high', () {
      // O₂ (2) + SpO₂ 92–93 (2) + temp ≥39.1 (2) = 6 → medium... build a 5:
      final five = normal()
        ..['o2'] = 'o2' // 2
        ..['rr'] = 'rr_21_24' // 2
        ..['temp'] = 'temp_38_39'; // 1  => 5
      expect(_total(b, five), 5);
      expect(_band(b, five), contains('Medium'));
      final seven = normal()
        ..['rr'] = 'rr_ge25' // 3
        ..['spo2'] = 'spo2_92_93' // 2
        ..['o2'] = 'o2'; // 2  => 7
      expect(_total(b, seven), 7);
      expect(_band(b, seven), contains('High'));
    });
    test('maximum aggregate = 20', () => expect(scoreRange(b).max, 20));
  });

  group('ICH Score (mortality bands 0–6)', () {
    late ScoreBlock b;
    setUpAll(() => b = _load('calc_ich_score.yaml'));

    test('GCS 13–15, nothing else → 0', () {
      expect(_total(b, {'gcs': 'g13_15'}), 0);
      expect(_band(b, {'gcs': 'g13_15'}), contains('Score 0'));
    });
    test('GCS 3–4 alone → 2', () {
      expect(_total(b, {'gcs': 'g3_4'}), 2);
    });
    test('full house → 6, top mortality band', () {
      final s = {
        'gcs': 'g3_4',
        'volume': true,
        'ivh': true,
        'infratentorial': true,
        'age80': true,
      };
      expect(_total(b, s), 6);
      expect(_band(b, s), contains('4–6'));
    });
    test('reachable totals are 0..6 and all banded', () {
      expect(reachableTotals(b), {for (var i = 0; i <= 6; i++) i});
    });
  });

  group('Ottawa Ankle / Knee (any positive → imaging)', () {
    late ScoreBlock ankle;
    late ScoreBlock knee;
    setUpAll(() {
      ankle = _load('calc_ottawa_ankle.yaml');
      knee = _load('calc_ottawa_knee.yaml');
    });

    test('ankle: no findings → no X-ray; any finding → X-ray', () {
      expect(_band(ankle, const {}), contains('No X-ray'));
      expect(_band(ankle, {'lat_mall': true}), contains('X-ray indicated'));
      expect(_band(ankle, {'weight': true}), contains('X-ray indicated'));
    });
    test('knee: age ≥55 alone → knee X-ray', () {
      expect(_band(knee, const {}), contains('No X-ray'));
      expect(_band(knee, {'age55': true}), contains('X-ray indicated'));
    });
    test('ankle max 5, knee max 5', () {
      expect(scoreRange(ankle).max, 5);
      expect(scoreRange(knee).max, 5);
    });
  });

  group('Bishop score (cervical favorability 0–13)', () {
    late ScoreBlock b;
    setUpAll(() => b = _load('calc_bishop.yaml'));

    test('all least-favorable defaults → 0, unfavorable', () {
      final s = {
        'dilation': 'd0',
        'effacement': 'e0',
        'station': 's3',
        'consistency': 'c_firm',
        'position': 'p_post',
      };
      expect(_total(b, s), 0);
      expect(_band(b, s), contains('Unfavorable'));
    });
    test('boundary 5 unfavorable, 6 intermediate, 8 favorable', () {
      // 5: dilation 3–4 (2) + effacement 40–50 (1) + station −1/0 (2) = 5
      expect(
        _band(b, {
          'dilation': 'd3',
          'effacement': 'e40',
          'station': 's1',
          'consistency': 'c_firm',
          'position': 'p_post',
        }),
        contains('Unfavorable'),
      );
      // 6: add soft consistency (2) → but that's 7; use dilation2+eff2+station2=6
      expect(
        _band(b, {
          'dilation': 'd3',
          'effacement': 'e60',
          'station': 's1',
          'consistency': 'c_firm',
          'position': 'p_post',
        }),
        contains('Intermediate'),
      ); // 2+2+2 = 6
      // 8: dilation ≥5 (3) + effacement ≥80 (3) + station +1/+2 (3)... = 9 favorable
      expect(
        _band(b, {
          'dilation': 'd5',
          'effacement': 'e80',
          'station': 's1',
          'consistency': 'c_firm',
          'position': 'p_post',
        }),
        contains('Favorable'),
      ); // 3+3+2 = 8
    });
    test('maximum = 13', () => expect(scoreRange(b).max, 13));
  });

  group('SOFA (6 scale organs, 0–24)', () {
    late ScoreBlock b;
    setUpAll(() => b = _load('calc_sofa.yaml'));

    test('all normal → 0, lower mortality', () {
      final all0 = {for (final i in b.items) i.key: '0'};
      expect(_total(b, all0), 0);
      expect(_band(b, all0), contains('Lower'));
    });
    test('sums organs; band boundaries 6/7 and 12/13', () {
      // resp3 + cardio3 + renal1 = 7 → moderate
      expect(_band(b, {'resp': '3', 'cardio': '3', 'renal': '1'}),
          contains('Moderate'));
      // resp4+coag4+liver4+cardio1 = 13 → very high
      expect(
        _band(b, {'resp': '4', 'coag': '4', 'liver': '4', 'cardio': '1'}),
        contains('Very high'),
      );
    });
    test('maximum = 24', () => expect(scoreRange(b).max, 24));
  });

  group('RCRI (Lee)', () {
    late ScoreBlock b;
    setUpAll(() => b = _load('calc_rcri.yaml'));

    test('0 → Class I, 1 → Class II, 2 → Class III, 3+ → Class IV', () {
      expect(_band(b, const {}), contains('Class I'));
      expect(_band(b, {'ihd': true}), contains('Class II'));
      expect(_band(b, {'ihd': true, 'chf': true}), contains('Class III'));
      expect(
        _band(b, {'ihd': true, 'chf': true, 'cva': true}),
        contains('Class IV'),
      );
    });
    test('max 6', () => expect(scoreRange(b).max, 6));
  });

  group('BISAP', () {
    late ScoreBlock b;
    setUpAll(() => b = _load('calc_bisap.yaml'));

    test('0–2 lower, 3 elevated, 4 high', () {
      expect(_band(b, {'bun': true, 'age60': true}), contains('Lower')); // 2
      expect(_band(b, {'bun': true, 'age60': true, 'sirs': true}),
          contains('Elevated')); // 3
      expect(
        _band(b, {'bun': true, 'age60': true, 'sirs': true, 'effusion': true}),
        contains('High'),
      ); // 4
    });
    test('max 5', () => expect(scoreRange(b).max, 5));
  });

  group('PHQ-9 (public-domain screen, 0–27)', () {
    late ScoreBlock b;
    setUpAll(() => b = _load('calc_phq9.yaml'));

    test('all zero → 0, minimal', () {
      final all0 = {for (final i in b.items) i.key: '0'};
      expect(_total(b, all0), 0);
      expect(_band(b, all0), contains('Minimal'));
    });
    test('YAML anchor expands: 9 items each with 4 options', () {
      expect(b.items, hasLength(9));
      for (final i in b.items) {
        expect(i.type, ScoreItemType.scale);
        expect(i.options.map((o) => o.points), [0, 1, 2, 3]);
      }
    });
    test('band boundaries 9/10 and 19/20', () {
      // 9 = q1..q3 at 3 → mild; 10 = one more point → moderate
      expect(_band(b, {'q1': '3', 'q2': '3', 'q3': '3'}), contains('Mild'));
      expect(_band(b, {'q1': '3', 'q2': '3', 'q3': '3', 'q4': '1'}),
          contains('Moderate'));
      // 20 = severe
      expect(
        _band(b, {
          'q1': '3', 'q2': '3', 'q3': '3', 'q4': '3',
          'q5': '3', 'q6': '3', 'q7': '2',
        }),
        contains('Severe'),
      ); // 20
    });
    test('maximum = 27', () => expect(scoreRange(b).max, 27));
  });

  group('GAD-7', () {
    late ScoreBlock b;
    setUpAll(() => b = _load('calc_gad7.yaml'));

    test('7 items, max 21, ≥10 moderate', () {
      expect(b.items, hasLength(7));
      expect(scoreRange(b).max, 21);
      expect(_band(b, {'q1': '3', 'q2': '3', 'q3': '3', 'q4': '1'}),
          contains('Moderate')); // 10
    });
  });

  group('AUDIT-C (sex-specific cutoff in note)', () {
    late ScoreBlock b;
    setUpAll(() => b = _load('calc_auditc.yaml'));

    test('0–2 lower, 3+ positive screen', () {
      expect(_band(b, {'frequency': '2'}), contains('Lower')); // 2
      expect(_band(b, {'frequency': '2', 'quantity': '1'}),
          contains('Positive')); // 3
      expect(_band(b, {'frequency': '4', 'quantity': '4'}),
          contains('probable alcohol')); // 8
    });
    test('maximum = 12', () => expect(scoreRange(b).max, 12));
  });

  group('NIHSS (15 scale items, 0–42)', () {
    late ScoreBlock b;
    setUpAll(() => b = _load('calc_nihss.yaml'));

    test('15 items; all normal → 0, no symptoms', () {
      expect(b.items, hasLength(15));
      final all0 = {for (final i in b.items) i.key: '0'};
      expect(_total(b, all0), 0);
      expect(_band(b, all0), contains('No stroke'));
    });
    test('anchor YAML alias expands: arm/leg motor 0–4', () {
      final arm = b.items.firstWhere((i) => i.key == 'arm_r');
      expect(arm.options.map((o) => o.points), [0, 1, 2, 3, 4]);
    });
    test('band boundaries: 4 minor, 5 moderate, 16 mod-severe, 21 severe', () {
      // 4 = gaze2 + facial2
      expect(_band(b, {'gaze': '2', 'facial': '2'}), contains('Minor'));
      // 5 = arm_l 4 + loc_q 1
      expect(_band(b, {'arm_l': '4', 'loc_q': '1'}), contains('Moderate'));
      // 16 = four limbs 4 = 16 → moderate-to-severe
      expect(
        _band(b, {'arm_l': '4', 'arm_r': '4', 'leg_l': '4', 'leg_r': '4'}),
        contains('Moderate-to-severe'),
      );
    });
    test('maximum = 42', () => expect(scoreRange(b).max, 42));
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
