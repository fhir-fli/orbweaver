// GUARD — every paged prose page must fit one phone screen without being
// shrunk past [kMinScale].
//
// WHY THIS IS A GUARD AND NOT A PROBE
// `_FitToScreen` (lib/screens/topic_frame.dart) renders a paged prose page,
// measures it, and shrinks the text until it fits, stopping at a floor of 0.48.
// Below that floor the overflow is CLIPPED inside a NeverScrollableScrollPhysics
// viewport — unreachable, no scrollbar, invisible to the author. On a clinical
// reference that is the worst possible failure mode.
//
// The invariant that keeps us away from that cliff is "a page should not need
// heavy shrinking to fit". This test enforces it. It replaces two earlier files
// that only MEASURED and could never fail:
//   - fit_overload_probe_test.dart      (measured in Ahem; see below)
//   - fit_real_font_probe_test.dart     (right font, but asserted nothing)
//
// WHY THE FONT MATTERS — this is the trap that produced a wrong answer once.
// `flutter_test` renders every glyph in Ahem, a square em-width test face that
// advances ~1.0 em per character where Roboto (what the app gets on device)
// advances ~0.5. Prose therefore wraps to roughly TWICE as many lines under
// test. Measured in Ahem, all 45 WVEMS prose pages appeared to need 0.48 and to
// be clipping. Measured in Roboto, none of them ever reached the floor and the
// real range was 0.80-0.85. Any height assertion made in Ahem is meaningless,
// so this test loads Roboto and FAILS LOUDLY if it cannot — a guard that
// silently skips is not a guard.
//
// Writes per-page numbers to build/fits/page_fits.tsv for diagnosis when it fails.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orbweaver/data/library.dart';
import 'package:orbweaver/data/topic_loader.dart';
import 'package:orbweaver/models/topic.dart';
import 'package:orbweaver/theme/palette.dart';
import 'package:orbweaver/theme/topic_theme.dart';
import 'package:orbweaver/widgets/topic_view.dart';

/// Pixel 3a logical size — the proxy this project targets.
const Size kPhone = Size(393, 852);

/// The smallest shrink we accept. Below this a page is not "a bit tight", it is
/// mis-authored — and it is heading for the 0.48 clipping floor.
///
/// Currently every WVEMS prose page fits at 0.85 or better. Before the print
/// leading was adopted, 21 of them did not, so this threshold is meaningful
/// rather than vacuous.
const double kMinScale = 0.85;

/// Candidate scales, largest first; the first that fits is recorded. Fixed
/// candidates rather than a 3%-step walk: the walk needs ~46 pumpAndSettle
/// passes per page and pushed the whole suite past 15 minutes.
const List<double> kCandidates = [1.0, 0.95, 0.9, 0.85, 0.8, 0.7, 0.6, 0.48];

/// Roboto, located relative to the SDK actually running the test rather than a
/// hardcoded home directory.
File? _findRoboto() {
  final tried = <String>[];
  final root = Platform.environment['FLUTTER_ROOT'];
  if (root != null && root.isNotEmpty) {
    tried.add(root);
    final f = File(
      '$root/bin/cache/artifacts/material_fonts/Roboto-Regular.ttf',
    );
    if (f.existsSync()) return f;
  }
  // `flutter test` runs a Dart from <sdk>/bin/cache/dart-sdk/bin/dart.
  var dir = File(Platform.resolvedExecutable).parent;
  for (var i = 0; i < 6 && dir.path != dir.parent.path; i++) {
    final f = File(
      '${dir.path}/cache/artifacts/material_fonts/Roboto-Regular.ttf',
    );
    tried.add(f.path);
    if (f.existsSync()) return f;
    dir = dir.parent;
  }
  return null;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'every paged prose page fits one screen at >= $kMinScale',
    (tester) async {
      final font = _findRoboto();
      expect(
        font,
        isNotNull,
        reason:
            'Could not find Roboto-Regular.ttf in the Flutter SDK. This test '
            'measures text layout, and flutter_test defaults to the Ahem face, '
            'which advances about twice Roboto and makes every height wrong. '
            'Failing rather than skipping so the guard cannot quietly stop '
            'guarding.',
      );

      await tester.runAsync(() async {
        await (FontLoader('Roboto')..addFont(
              Future.value(font!.readAsBytesSync().buffer.asByteData()),
            ))
            .load();
      });

      tester.view.physicalSize = kPhone * 3.0;
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.reset);

      Directory('build/fits').createSync(recursive: true);
    final fh = File('build/fits/page_fits.tsv').openSync(mode: FileMode.write);
      fh.writeStringSync('topic\tpage\tfits_at\tnat_h\tavail_h\n');
      fh.flushSync();

      // Asset I/O must run outside the fake-async zone testWidgets installs, or
      // the future never completes and the test times out with no output.
      final loaded = <({String id, Topic topic})>[];
      await tester.runAsync(() async {
        for (final book in await loadLibrary()) {
          for (final entry in book.allTopics) {
            if (entry.drug != null || entry.asset.isEmpty) continue;
            loaded.add((
              id: entry.id,
              topic: await loadTopicAsset(entry.asset),
            ));
          }
        }
      });
      expect(
        loaded,
        isNotEmpty,
        reason: 'no topics loaded — asset path broken?',
      );

      final offenders = <String>[];
      var checked = 0;

      for (final rec in loaded) {
        final topic = rec.topic;
        if (topic.layout != TopicLayout.paged || topic.pages.length < 2)
          continue;
        final theme = TopicTheme(
          resolvePalette([
            {
              for (final e in topic.ownPaletteArgb.entries)
                e.key: Color(e.value),
            },
          ]),
        );

        for (var i = 0; i < topic.pages.length; i++) {
          final page = topic.pages[i];
          // Flowchart pages take the FittedBox(scaleDown) path, which shrinks
          // uniformly and never clips, so they are not at risk.
          if (page.blocks.any((b) => b is FlowchartBlock)) continue;

          double? natural;
          var avail = 0.0;
          var fits = -1.0;

          for (final scale in kCandidates) {
            final key = GlobalKey();
            await tester.pumpWidget(
              MaterialApp(
                theme: ThemeData(fontFamily: 'Roboto'),
                home: Scaffold(
                  body: Builder(
                    builder: (context) => MediaQuery(
                      data: MediaQuery.of(
                        context,
                      ).copyWith(textScaler: TextScaler.linear(scale)),
                      child: LayoutBuilder(
                        builder: (context, c) {
                          avail = c.maxHeight;
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
                    ),
                  ),
                ),
              ),
            );
            await tester.pump();

            final box = key.currentContext?.findRenderObject();
            if (box is! RenderBox || !box.hasSize) break;
            natural ??= box.size.height;
            if (box.size.height <= avail - 2) {
              fits = scale;
              break;
            }
          }

          checked++;
          final label = '${rec.id} p${page.pageNumber ?? i}';
          fh.writeStringSync(
            '${rec.id}\t${page.pageNumber ?? i}\t'
            '${fits < 0 ? "NEVER" : fits.toStringAsFixed(2)}\t'
            '${natural?.toStringAsFixed(0) ?? "?"}\t'
            '${avail.toStringAsFixed(0)}\n',
          );
          fh.flushSync();

          if (fits < kMinScale) {
            offenders.add(
              '$label — fits at '
              '${fits < 0 ? "NO scale tried" : fits.toStringAsFixed(2)}, '
              'natural ${natural?.toStringAsFixed(0)}px vs '
              '${avail.toStringAsFixed(0)}px available',
            );
          }
        }
      }
      fh.closeSync();

      expect(
        checked,
        greaterThan(0),
        reason: 'no paged prose pages were checked',
      );
      expect(
        offenders,
        isEmpty,
        reason:
            'These pages need shrinking below $kMinScale to fit a '
            '${kPhone.width.toInt()}x${kPhone.height.toInt()} screen, which puts '
            'them on course for the 0.48 clipping floor where content is silently '
            'cut. Shorten the page, or move content into a side-by-side row.\n'
            '  ${offenders.join("\n  ")}\n'
            'Per-page numbers in build/fits/page_fits.tsv.',
      );
    },
    timeout: const Timeout(Duration(minutes: 5)),
  );
}
