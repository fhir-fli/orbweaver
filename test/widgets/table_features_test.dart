import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orbweaver/models/topic.dart';
import 'package:orbweaver/widgets/topic_view.dart';

/// Covers the TableBlock display-aid features added for the Annex 5 growth
/// tables: zebra striping, sticky header, frozen first column, per-column
/// alignment + colour tint — parsed from YAML and rendered without overflow.
Topic _loadA51() {
  final yaml = File(
    'assets/books/who_imci/topics/who_a5_1_weight_for_age.yaml',
  ).readAsStringSync();
  return Topic.fromYamlString(yaml);
}

const double _frameWidth = 375;
const double _frameHeight = 667;

Widget _wrap(Widget child) => MaterialApp(
  home: Scaffold(
    body: SizedBox(
      width: _frameWidth,
      height: _frameHeight,
      child: SingleChildScrollView(child: child),
    ),
  ),
);

void main() {
  late Topic topic;
  setUpAll(() => topic = _loadA51());

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
