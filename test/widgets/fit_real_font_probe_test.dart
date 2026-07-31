// DIAGNOSTIC PROBE — the same question as fit_overload_probe_test.dart, but
// measured with a REAL font.
//
// Why this exists: `flutter_test` renders every glyph in Ahem, a square
// em-width test face. Ahem advances ~1.0 em per character where Roboto (what
// the app actually gets on device) advances ~0.5 em, so prose wraps to roughly
// twice as many lines under test as on a phone. Every absolute height and
// "fits at" figure from the Ahem probe is therefore pessimistic — useful for
// before/after comparison, useless as an answer to "does this page fit?".
//
// This probe loads Roboto-Regular from the Flutter SDK's material_fonts
// artifact and re-measures, so the numbers can be read literally. It skips
// (rather than fails) when that font is not on disk, since the path is
// machine-specific.
//
// Writes results incrementally to fit_real_font.tsv.

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

/// Candidate scales, largest first. The first that fits is reported.
const List<double> kCandidates = [
  1.0, 0.95, 0.9, 0.85, 0.8, 0.7, 0.6, 0.48, 0.4, 0.3,
];

/// Where the Flutter SDK keeps the fonts it ships to Android.
const List<String> kRobotoCandidates = [
  '/home/grey/flutter/bin/cache/artifacts/material_fonts/Roboto-Regular.ttf',
];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('PROBE: paged prose pages measured in Roboto, not Ahem',
      (tester) async {
    final font =
        kRobotoCandidates.map(File.new).where((f) => f.existsSync()).firstOrNull;
    if (font == null) {
      // ignore: avoid_print
      print('SKIP: no Roboto on disk (looked in $kRobotoCandidates)');
      return;
    }

    await tester.runAsync(() async {
      final loader = FontLoader('Roboto')
        ..addFont(
          Future.value(font.readAsBytesSync().buffer.asByteData()),
        );
      await loader.load();
    });

    tester.view.physicalSize = kPhone * 3.0;
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    final fh = File('fit_real_font.tsv').openSync(mode: FileMode.write);
    fh.writeStringSync('topic\tpage_index\tpage_number\tfits_at\tnat_h_1.0\t'
        'avail_h\n');
    fh.flushSync();

    final loaded = <({String id, Topic topic})>[];
    await tester.runAsync(() async {
      for (final book in await loadLibrary()) {
        if (book.id != 'wvems') continue;
        for (final entry in book.allTopics) {
          if (entry.drug != null || entry.asset.isEmpty) continue;
          loaded.add((id: entry.id, topic: await loadTopicAsset(entry.asset)));
        }
      }
    });

    for (final rec in loaded) {
      final topic = rec.topic;
      if (topic.layout != TopicLayout.paged || topic.pages.length < 2) continue;
      final theme = TopicTheme(resolvePalette([
        {for (final e in topic.ownPaletteArgb.entries) e.key: Color(e.value)},
      ]));

      for (var i = 0; i < topic.pages.length; i++) {
        final page = topic.pages[i];
        if (page.blocks.any((b) => b is FlowchartBlock)) continue;

        double? natural;
        var avail = 0.0;
        var fits = -1.0;

        for (final scale in kCandidates) {
          final key = GlobalKey();
          await tester.pumpWidget(MaterialApp(
            theme: ThemeData(fontFamily: 'Roboto'),
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
                          page: page,
                          theme: theme,
                          gapScale: scale,
                        ),
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

        fh.writeStringSync('${rec.id}\t$i\t${page.pageNumber ?? ""}\t'
            '${fits < 0 ? "NEVER" : fits.toStringAsFixed(2)}\t'
            '${natural?.toStringAsFixed(0) ?? "?"}\t'
            '${avail.toStringAsFixed(0)}\n');
        fh.flushSync();
        // ignore: avoid_print
        print('${rec.id} p$i fits_at='
            '${fits < 0 ? "NEVER" : fits.toStringAsFixed(2)} '
            'nat=${natural?.toStringAsFixed(0)}');
      }
    }
    fh.closeSync();
  }, timeout: const Timeout(Duration(minutes: 10)));
}
