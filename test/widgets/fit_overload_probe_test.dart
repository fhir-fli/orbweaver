// DIAGNOSTIC PROBE — answers "which pages are overloaded?"
//
// `_FitToScreen` (lib/screens/topic_frame.dart) renders a paged PROSE page at
// textScaler 1.0, measures it, and shrinks by 3% a step until it fits or hits a
// floor of 0.48. Below that floor the excess is CLIPPED, inside a
// NeverScrollableScrollPhysics viewport — unreachable, with no scrollbar.
//
// This probe replicates that loop per page and reports the scale at which each
// page actually fits, pushing well past 0.48 so we can see how bad the worst
// pages really are. It is a measurement, not an assertion: it never fails.
//
// Scope note: only paged PROSE pages are at risk. Flowchart pages go through
// FittedBox(scaleDown) which shrinks uniformly without clipping, and the seven
// topics with no top-level `layout:` fall through to a real scrolling view.
//
// Writes results incrementally to fit_overload.tsv.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orbweaver/data/library.dart';
import 'package:orbweaver/data/topic_loader.dart';
import 'package:orbweaver/models/topic.dart';
import 'package:orbweaver/theme/palette.dart';
import 'package:orbweaver/theme/topic_theme.dart';
import 'package:orbweaver/widgets/topic_view.dart';

/// Pixel 3a logical size — the proxy this project targets.
const Size kPhone = Size(393, 852);

/// The floor the app currently enforces.
const double kAppFloor = 0.48;

/// How far past the floor we probe, to size the problem.
const double kProbeFloor = 0.25;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'PROBE: which paged prose pages overflow, and at what scale',
    (tester) async {
      tester.view.physicalSize = kPhone * 3.0;
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.reset);

      final fh = File('fit_overload.tsv').openSync(mode: FileMode.write)
        ..writeStringSync(
          'book\ttopic\tpage_index\tpage_number\t'
          'fits_at_scale\tclipped_by_app\tnatural_h_at_1.0\tavail_h\n',
        )
        ..flushSync();

      final books = await loadLibrary();
      var probed = 0;
      var belowFloor = 0;
      var below085 = 0;

      for (final book in books) {
        for (final entry in book.allTopics) {
          if (entry.drug != null || entry.asset.isEmpty) continue;
          late final Topic topic;
          try {
            topic = await loadTopicAsset(entry.asset);
          } on Object catch (_) {
            // A topic that will not load is a separate defect; skip it here so
            // the probe still measures every page that does load.
            continue;
          }
          if (topic.layout != TopicLayout.paged || topic.pages.length < 2) {
            continue;
          }
          final resolved = resolvePalette([
            {
              for (final e in topic.ownPaletteArgb.entries)
                e.key: Color(e.value),
            },
          ]);
          final theme = TopicTheme(resolved);

          for (var i = 0; i < topic.pages.length; i++) {
            final page = topic.pages[i];
            // Flowchart pages take the FittedBox path — not at risk of clipping.
            if (page.blocks.any((b) => b is FlowchartBlock)) continue;

            double? naturalAt1;
            var fits = -1.0;
            var availH = 0.0;

            for (var scale = 1.0; scale >= kProbeFloor; scale *= 0.97) {
              final key = GlobalKey();
              await tester.pumpWidget(
                MaterialApp(
                  home: Scaffold(
                    body: Builder(
                      builder: (context) {
                        return MediaQuery(
                          data: MediaQuery.of(
                            context,
                          ).copyWith(textScaler: TextScaler.linear(scale)),
                          child: LayoutBuilder(
                            builder: (context, c) {
                              availH = c.maxHeight;
                              return SingleChildScrollView(
                                physics: const NeverScrollableScrollPhysics(),
                                child: KeyedSubtree(
                                  key: key,
                                  child: TopicPageBody(
                                    page: page,
                                    theme: theme,
                                    gapScale: scale,
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ),
              );
              await tester.pumpAndSettle(const Duration(milliseconds: 50));

              final box = key.currentContext?.findRenderObject();
              if (box is! RenderBox || !box.hasSize) break;
              final h = box.size.height;
              naturalAt1 ??= h;

              if (h <= availH - 2) {
                fits = scale;
                break;
              }
            }

            probed++;
            final clipped = fits < 0 || fits < kAppFloor;
            if (clipped) belowFloor++;
            if (fits >= 0 && fits < 0.85) below085++;

            fh
              ..writeStringSync(
                '${book.id}\t${entry.id}\t$i\t'
                '${page.pageNumber ?? ""}\t'
                '${fits < 0 ? "NEVER" : fits.toStringAsFixed(3)}\t'
                '${clipped ? "YES" : "no"}\t'
                '${naturalAt1?.toStringAsFixed(1) ?? "?"}\t'
                '${availH.toStringAsFixed(1)}\n',
              )
              ..flushSync();
            // A probe is only useful if you can watch it. Progress goes to stdout
            // per page as well as to disk, so a run that dies part-way still
            // shows how far it got.
            // ignore: avoid_print
            print(
              '${entry.id} p$i: fits_at='
              '${fits < 0 ? "NEVER" : fits.toStringAsFixed(3)}'
              '${clipped ? "  <-- CLIPPED BY APP" : ""}',
            );
          }
        }
      }

      final summary =
          'PROBED $probed paged prose pages · '
          '$belowFloor clipped by the app (need < $kAppFloor) · '
          '$below085 fit only below 0.85';
      fh
        ..writeStringSync('# $summary\n')
        ..flushSync()
        ..closeSync();
      // Same reason as above: the headline number belongs on the terminal, not
      // only at the bottom of a file nobody opens.
      // ignore: avoid_print
      print(summary);
    },
    timeout: const Timeout(Duration(minutes: 15)),
  );
}
