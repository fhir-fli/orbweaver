// MEASUREMENT (not an assertion) for the WVEMS side-by-side pass.
//
// `test/widgets/fit_overload_probe_test.dart` reports the largest of a COARSE
// candidate ladder (1.0 / .95 / .9 / .85 / .8 / .7 / .6 / .48) that fits one
// 393x852 screen. That ladder cannot tell "needs 0.59" from "needs 0.49", which
// is exactly the resolution needed to decide whether converting a stacked pair
// into a `row` helped or hurt.
//
// This walks a FINE ladder (1.00 -> 0.44 in 0.02 steps) and reports the largest
// scale at which the page still fits. Bare `pump()` per step, results written
// and flushed per page.
//
// Run:  flutter test tool/wvems_fit_measure_test.dart
// Out:  tool/wvems_fit_fine.tsv   (override with FIT_OUT=<path>)

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orbweaver/data/library.dart';
import 'package:orbweaver/data/topic_loader.dart';
import 'package:orbweaver/models/topic.dart';
import 'package:orbweaver/theme/palette.dart';
import 'package:orbweaver/theme/topic_theme.dart';
import 'package:orbweaver/widgets/topic_view.dart';

const Size kPhone = Size(393, 852);

/// Only the topics this pass touches, plus the already-rowed ones as controls.
const Set<String> kOfInterest = {
  'wvems-2026-016',
  'wvems-2026-018',
  'wvems-2026-024',
  'wvems-2026-036',
  'wvems-2026-052',
  'wvems-2026-070',
  'wvems-2026-076',
  'wvems-2026-094',
  'wvems-2026-050',
  'wvems-2026-054',
  // controls: already rowed before this pass
  'wvems-2026-044',
  'wvems-2026-086',
};

List<double> fineLadder() {
  final out = <double>[];
  for (var s = 100; s >= 44; s -= 2) {
    out.add(s / 100);
  }
  return out;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('MEASURE: finest fitting textScaler per paged prose page',
      (tester) async {
    tester.view.physicalSize = kPhone * 3.0;
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    final outPath =
        Platform.environment['FIT_OUT'] ?? 'tool/wvems_fit_fine.tsv';
    final fh = File(outPath).openSync(mode: FileMode.write);
    fh.writeStringSync('topic\tpage_number\tfits_at\tnat_h_1.0\tavail_h\n');
    fh.flushSync();

    final loaded = <({String id, Topic topic})>[];
    await tester.runAsync(() async {
      final books = await loadLibrary();
      for (final book in books) {
        if (book.id != 'wvems') continue;
        for (final entry in book.allTopics) {
          if (entry.drug != null || entry.asset.isEmpty) continue;
          if (!kOfInterest.contains(entry.id)) continue;
          loaded.add((id: entry.id, topic: await loadTopicAsset(entry.asset)));
        }
      }
    });
    stdout.writeln('measuring ${loaded.length} topics');
    stdout.flush();

    for (final rec in loaded) {
      final topic = rec.topic;
      if (topic.layout != TopicLayout.paged || topic.pages.length < 2) continue;
      final theme = TopicTheme(resolvePalette([
        {for (final e in topic.ownPaletteArgb.entries) e.key: Color(e.value)},
      ]));

      for (final page in topic.pages) {
        if (page.blocks.any((b) => b is FlowchartBlock)) continue;

        double? natural;
        double avail = 0;
        double fits = -1;

        for (final scale in fineLadder()) {
          final key = GlobalKey();
          await tester.pumpWidget(MaterialApp(
            home: Scaffold(
              body: Builder(builder: (context) {
                return MediaQuery(
                  data: MediaQuery.of(context)
                      .copyWith(textScaler: TextScaler.linear(scale)),
                  child: LayoutBuilder(builder: (context, c) {
                    avail = c.maxHeight;
                    return SingleChildScrollView(
                      physics: const NeverScrollableScrollPhysics(),
                      child: KeyedSubtree(
                        key: key,
                        child: TopicPageBody(
                            page: page, theme: theme, gapScale: scale),
                      ),
                    );
                  }),
                );
              }),
            ),
          ));
          await tester.pump();

          final box = key.currentContext?.findRenderObject();
          if (box is! RenderBox || !box.hasSize) break;
          natural ??= box.size.height;
          if (box.size.height <= avail - 2) {
            fits = scale;
            break;
          }
        }

        final line = '${rec.id}\t${page.pageNumber ?? ""}\t'
            '${fits < 0 ? "NEVER" : fits.toStringAsFixed(2)}\t'
            '${natural?.toStringAsFixed(0) ?? "?"}\t'
            '${avail.toStringAsFixed(0)}\n';
        fh.writeStringSync(line);
        fh.flushSync();
        stdout.writeln(line.trim());
        stdout.flush();
      }
    }

    fh.closeSync();
  }, timeout: const Timeout(Duration(minutes: 15)));
}
