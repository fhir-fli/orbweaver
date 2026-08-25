import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orbweaver/models/topic.dart';
import 'package:orbweaver/widgets/topic_view.dart';

/// Covers the TableBlock display-aid features added for the Annex 5 growth
/// tables: zebra striping, sticky header, frozen first column, per-column
/// alignment + colour tint — parsed from YAML and rendered without overflow.
///
/// FONT — this file used to render in Ahem and three of its four cases failed
/// with "A RenderFlex overflowed by 15 pixels on the bottom". They were carried
/// as known-failing for months. The overflow was never real: Ahem advances
/// ~1.0 em per character where Roboto (what the device gets) advances ~0.5, so
/// every cell wrapped to about twice as many lines and the table came out
/// taller than the frame. Loading Roboto, the same widget tree renders with
/// ZERO exceptions. This is the same trap page_fits_screen_test.dart documents
/// at length; a table test is no more exempt from it than a prose one.
/// Fails loudly if Roboto cannot be found — a guard that silently skips is not
/// a guard.
Topic _loadA51() {
  final yaml = File(
    'assets/books/who_imci/topics/who_a5_1_weight_for_age.yaml',
  ).readAsStringSync();
  return Topic.fromYamlString(yaml);
}

const double _frameWidth = 375;
const double _frameHeight = 667;

Widget _wrap(Widget child) => MaterialApp(
  theme: ThemeData(fontFamily: 'Roboto'),
  home: Scaffold(
    body: SizedBox(
      width: _frameWidth,
      height: _frameHeight,
      child: SingleChildScrollView(child: child),
    ),
  ),
);

/// Roboto, located relative to the SDK actually running the test.
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
  late Topic topic;

  setUpAll(() async {
    topic = _loadA51();
    final font = _findRoboto();
    if (font == null) {
      fail(
        'Roboto not found. Measuring this table in Ahem reports a phantom '
        '15px overflow — see the note at the top of this file.',
      );
    }
    await (FontLoader('Roboto')
          ..addFont(Future.value(font.readAsBytesSync().buffer.asByteData())))
        .load();
  });

  group('A5.1 weight-for-age table features', () {
    test('parses the new TableBlock display-aid fields', () {
      final tables = topic.blocks.whereType<TableBlock>().toList();
      expect(tables, hasLength(2)); // Boys + Girls
      final boys = tables.first;
      expect(boys.layout, TableLayout.scroll);
      expect(boys.zebra, isTrue);
      expect(boys.stickyHeader, isTrue);
      expect(boys.stickyFirstColumn, isTrue);
      expect(boys.rows, hasLength(61)); // 0..60 months
      // right-aligned value columns, left label column
      expect(boys.columnAlign.first, CellAlign.left);
      expect(boys.columnAlign[1], CellAlign.right);
      // −3 SD and −2 SD columns carry a tint; others do not
      expect(boys.columnTintArgb[1], isNotNull);
      expect(boys.columnTintArgb[2], isNotNull);
      expect(boys.columnTintArgb[3], isNull);
      // lookup finder enabled
      expect(boys.lookup, isTrue);
      expect(boys.lookupLabel, 'Go to age (months)');
    });

    testWidgets('lookup finder accepts a query without error', (tester) async {
      await tester.pumpWidget(_wrap(TopicView(topic: topic)));
      final field = find.byType(TextField);
      expect(field, findsWidgets); // one finder per lookup table
      await tester.enterText(field.first, '24');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300)); // scroll anim
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders the frozen-pane table without overflow', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(TopicView(topic: topic)));
      expect(tester.takeException(), isNull);
      // header (pinned) + a first-row value are in the tree
      expect(find.text('Months'), findsWidgets);
      expect(find.text('Median'), findsWidgets);
      // body values render via MiniMarkdown (RichText), so match rich text
      expect(find.text('2.1', findRichText: true), findsWidgets);
    });

    testWidgets('renders zebra + tint without exception on a phone frame', (
      tester,
    ) async {
      // A wider check that the bounded frozen panel lays out cleanly.
      await tester.pumpWidget(_wrap(TopicView(topic: topic)));
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  });
}
