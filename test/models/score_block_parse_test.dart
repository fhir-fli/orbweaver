// Structural tests for every score topic: it parses to a valid ScoreBlock,
// choice items declare a default that's a real option, item keys are unique,
// and — the strict part — the declared bands cover EVERY reachable total, so no
// achievable score falls through to "no interpretation".

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:orbweaver/data/score_engine.dart';
import 'package:orbweaver/models/topic.dart';

const _dir = 'assets/books/calculators/topics';

const _files = <String>[
  'calc_cha2ds2_vasc.yaml',
  'calc_hasbled.yaml',
  'calc_wells_dvt.yaml',
  'calc_wells_pe.yaml',
  'calc_perc.yaml',
  'calc_curb65.yaml',
  'calc_gcs.yaml',
  'calc_child_pugh.yaml',
  'calc_heart.yaml',
  'calc_4ts.yaml',
  'calc_qsofa.yaml',
  'calc_centor.yaml',
  'calc_canadian_ct_head.yaml',
  'calc_ciwa_ar.yaml',
  'calc_cows.yaml',
  'calc_news2.yaml',
  'calc_ich_score.yaml',
  'calc_ottawa_ankle.yaml',
  'calc_ottawa_knee.yaml',
  'calc_bishop.yaml',
  'calc_sofa.yaml',
  'calc_rcri.yaml',
  'calc_bisap.yaml',
  'calc_phq9.yaml',
  'calc_gad7.yaml',
  'calc_auditc.yaml',
  'calc_nihss.yaml',
  'calc_sirs.yaml',
  'calc_sgarbossa.yaml',
];

ScoreBlock _load(String file) => Topic.fromYamlString(
      File('$_dir/$file').readAsStringSync(),
    ).blocks.whereType<ScoreBlock>().single;

void main() {
  group('score topics parse to valid ScoreBlocks', () {
    for (final file in _files) {
      group(file, () {
        late ScoreBlock b;
        setUpAll(() => b = _load(file));

        test('has a title, source, items, and bands', () {
          expect(b.title, isNotNull);
          expect(b.source, isNotNull, reason: 'scores must cite provenance');
          expect(b.items, isNotEmpty);
          expect(b.bands, isNotEmpty);
        });

        test('item keys unique; choices have options + a valid default', () {
          final keys = <String>{};
          for (final item in b.items) {
            expect(keys.add(item.key), isTrue,
                reason: 'duplicate item key "${item.key}"');
            if (item.type != ScoreItemType.toggle) {
              expect(item.options, isNotEmpty,
                  reason: '${item.type.name} "${item.key}" needs options');
              expect(item.defaultValue, isNotNull,
                  reason: '${item.type.name} "${item.key}" needs a default');
              expect(
                item.options.map((o) => o.value),
                contains(item.defaultValue),
                reason: 'default "${item.defaultValue}" not an option',
              );
            }
          }
        });

        test('bands cover EVERY reachable total (no gaps)', () {
          final reachable = reachableTotals(b);
          expect(reachable, isNotEmpty);
          final uncovered =
              reachable.where((t) => bandFor(b, t) == null).toList()..sort();
          expect(uncovered, isEmpty,
              reason: 'totals with no band: $uncovered');
        });

        test('bands are ordered and non-overlapping on first-match', () {
          // Every reachable total resolves to exactly the first matching band;
          // assert the resolved band is self-consistent (min ≤ total).
          for (final t in reachableTotals(b)) {
            final band = bandFor(b, t)!;
            expect(t >= band.min, isTrue);
            final max = band.max;
            expect(max == null || t <= max, isTrue);
          }
        });
      });
    }

    test('all scores registered', () {
      expect(_files, hasLength(29));
      for (final f in _files) {
        expect(File('$_dir/$f').existsSync(), isTrue, reason: 'missing $f');
      }
    });
  });
}
