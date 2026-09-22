// GUARD — no flowchart text may be squeezed onto FitText's legibility floor.
//
// WHY THIS IS A GUARD AND NOT A PROBE
// `FitText` (lib/widgets/flowchart/fit_text.dart) shrinks a node's text until
// it fits the space the node gives it, stopping at `_minFontSize` = 9. At that
// floor it stops shrinking but does NOT stop rendering: the text simply spills
// past the node's boundary. Inside a rectangle that reads as untidy; inside a
// DIAMOND it crosses the sloped edges and lands on the arrows, which is what
// Paediatric Convulsions (p.42) was doing before 2026-08-24 — see
// `04bfaca`. Nothing failed, because a FittedBox(scaleDown) flowchart never
// raises a RenderFlex overflow. It just looks wrong on the device, and only if
// someone opens that page.
//
// `page_fits_screen_test.dart` explicitly skips flowchart pages on the grounds
// that they "shrink uniformly and never clip". That is true of the page-level
// FittedBox and false of the text inside the nodes. This covers the gap.
//
// The invariant: a node's text should fit at a readable size, so reaching the
// floor means the node is mis-sized, not that the text is long.
//
// FONT: `flutter_test` renders in Ahem, which advances ~1.0 em per character
// where Roboto advances ~0.5 — text wraps to about twice as many lines and
// every shrink decision comes out wrong. This loads Roboto and FAILS LOUDLY if
// it cannot, for the same reason page_fits_screen_test does.
//
// Writes every node it measures to build/fits/flowchart_fits.tsv for diagnosis.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orbweaver/data/library.dart';
import 'package:orbweaver/data/topic_loader.dart';
import 'package:orbweaver/models/topic.dart';
import 'package:orbweaver/widgets/flowchart/fit_text.dart';
import 'package:orbweaver/widgets/topic_view.dart';

/// Pixel 3a logical size — the proxy this project targets.
const Size kPhone = Size(393, 852);

/// FitText's legibility floor. Kept in step with `FitText._minFontSize`.
const double kFloor = 9;

/// How far past its budget a node's text may run before it counts as spilling.
/// A pixel or two is invisible; the threshold is set from measurement, not
/// taste — see the header note.
const double kTolerancePx = 4;

File? _findRoboto() {
  final root = Platform.environment['FLUTTER_ROOT'];
  if (root != null && root.isNotEmpty) {
    final f = File(
      '$root/bin/cache/artifacts/material_fonts/Roboto-Regular.ttf',
    );
    if (f.existsSync()) return f;
  }
  var dir = File(Platform.resolvedExecutable).parent;
  for (var i = 0; i < 8; i++) {
    final f = File(
      '${dir.path}/cache/artifacts/material_fonts/Roboto-Regular.ttf',
    );
    if (f.existsSync()) return f;
    dir = dir.parent;
  }
  return null;
}

void main() {
  testWidgets('no flowchart node text is squeezed onto the legibility floor', (
    tester,
  ) async {
    final font = _findRoboto();
    expect(
      font,
      isNotNull,
      reason:
          'Roboto not found. Measuring in Ahem would make every shrink '
          'decision wrong, so this fails rather than quietly stopping '
          'guarding.',
    );
    await tester.runAsync(() async {
      await (FontLoader(
            'Roboto',
          )..addFont(Future.value(font!.readAsBytesSync().buffer.asByteData())))
          .load();
    });

    tester.view.physicalSize = kPhone * 3.0;
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    // Asset I/O must run outside the fake-async zone testWidgets installs.
    final loaded = <({String id, Topic topic})>[];
    await tester.runAsync(() async {
      for (final book in await loadLibrary()) {
        for (final entry in book.allTopics) {
          if (entry.drug != null || entry.asset.isEmpty) continue;
          loaded.add((id: entry.id, topic: await loadTopicAsset(entry.asset)));
        }
      }
    });
    expect(loaded, isNotEmpty, reason: 'no topics loaded — asset path broken?');

    Directory('build/fits').createSync(recursive: true);
    final fh =
        File(
            'build/fits/flowchart_fits.tsv',
          ).openSync(mode: FileMode.write)
          ..writeStringSync('topic\tvariant\tn_spilled\tfirst_spilled\n')
          ..flushSync();

    final offenders = <String>[];
    var charts = 0;

    for (final rec in loaded) {
      final topic = rec.topic;
      final variants = <String>{
        for (final page in topic.pages)
          for (final b in page.blocks)
            if (b is FlowchartBlock) b.variant.name,
      };
      if (variants.isEmpty) continue;
      charts++;

      FitText.debugOverflowed.clear();
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(fontFamily: 'Roboto'),
          home: Scaffold(
            body: SingleChildScrollView(
              child: TopicView(
                topic: topic,
                palette: {
                  for (final e in topic.ownPaletteArgb.entries)
                    e.key: Color(e.value),
                },
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      final spilled = List<String>.from(FitText.debugOverflowed);
      FitText.debugOverflowed.clear();

      fh
        ..writeStringSync(
          '${rec.id}\t${variants.join(",")}\t${spilled.length}\t'
          '${spilled.isEmpty ? "" : spilled.first.replaceAll("\n", " ").replaceAll("\t", " ")}\n',
        )
        ..flushSync();

      for (final s in spilled) {
        final bar = s.indexOf('|');
        final excess = double.parse(s.substring(0, bar));
        final text = s.substring(bar + 1);
        if (excess < kTolerancePx) continue;
        offenders.add(
          '${rec.id} [${variants.join(",")}] +${excess.toStringAsFixed(0)}px — '
          '"${text.length > 60 ? "${text.substring(0, 60)}…" : text}"',
        );
      }
    }
    fh.closeSync();

    expect(
      charts,
      greaterThan(40),
      reason:
          'expected the books to hold well over 40 flowcharts; '
          'found $charts — did the block scan break?',
    );
    expect(
      offenders,
      isEmpty,
      reason:
          'These flowchart nodes still do not fit after shrinking all the '
          'way to the ${kFloor}pt legibility floor, so their text is '
          'spilling past the node edges:\n  ${offenders.join("\n  ")}',
    );
  });
}
