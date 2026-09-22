// GUARD — every table in every book must render at phone width without a
// layout exception.
//
// The companion to flowchart_fit_guard_test.dart. Between them the two cover
// the block types that carry most of the clinical content: 97 flowcharts and
// every table across the three books.
//
// WHY IT IS NEEDED
// A table is the block most likely to overflow, because its width is driven by
// its widest cell rather than by the frame. Until now the only table with any
// layout coverage was the A5.1 growth table, and that coverage was itself
// wrong — see the header of table_features_test.dart.
//
// FONT — loads Roboto and FAILS if it cannot find it. Measuring a table in
// Ahem reports phantom overflows: that is exactly how three cases in
// table_features_test.dart came to be carried as known-failing for months
// while the app was fine.
//
// Writes every table it measures to build/fits/table_fits.tsv for diagnosis.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orbweaver/data/library.dart';
import 'package:orbweaver/data/topic_loader.dart';
import 'package:orbweaver/models/topic.dart';
import 'package:orbweaver/widgets/topic_view.dart';

/// Pixel 3a logical size — the proxy this project targets.
const Size kPhone = Size(393, 852);

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
  testWidgets('every table renders at phone width without a layout exception', (
    tester,
  ) async {
    final font = _findRoboto();
    expect(
      font,
      isNotNull,
      reason:
          'Roboto not found. Measuring tables in Ahem reports phantom '
          'overflows, which is how three cases in table_features_test came '
          'to be carried as known-failing while the app was fine.',
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
    final fh = File('build/fits/table_fits.tsv').openSync(mode: FileMode.write)
      ..writeStringSync('topic\tn_tables\tn_errors\tfirst_error\n')
      ..flushSync();

    final offenders = <String>[];
    var withTables = 0;
    var tableCount = 0;

    for (final rec in loaded) {
      final topic = rec.topic;
      final n = [
        for (final page in topic.pages)
          for (final b in page.blocks)
            if (b is TableBlock) b,
      ].length;
      if (n == 0) continue;
      withTables++;
      tableCount += n;

      final errors = <String>[];
      final prev = FlutterError.onError;
      FlutterError.onError = (d) => errors.add(d.exceptionAsString());
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
      FlutterError.onError = prev;

      fh
        ..writeStringSync(
          '${rec.id}\t$n\t${errors.length}\t'
          '${errors.isEmpty ? "" : errors.first.replaceAll("\n", " ").replaceAll("\t", " ")}\n',
        )
        ..flushSync();

      for (final e in errors) {
        offenders.add('${rec.id} ($n tables) — ${e.split("\n").first}');
      }
    }
    fh.closeSync();

    expect(
      tableCount,
      greaterThan(80),
      reason:
          'expected well over 80 tables across the books; found '
          '$tableCount in $withTables topics — did the block scan break?',
    );
    expect(
      offenders,
      isEmpty,
      reason:
          'These topics raise a layout exception at phone width:\n  '
          '${offenders.join("\n  ")}',
    );
  });
}
