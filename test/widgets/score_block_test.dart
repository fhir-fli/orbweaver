// Widget tests for the score block: tapping criteria must update the live total
// and band on screen (a correct engine is useless if the UI doesn't reflect it).

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orbweaver/models/topic.dart';
import 'package:orbweaver/widgets/blocks/score_block_view.dart';
import 'package:orbweaver/widgets/topic_view.dart';

const _dir = 'assets/books/calculators/topics';

Topic _load(String file) =>
    Topic.fromYamlString(File('$_dir/$file').readAsStringSync());

Widget _wrap(Widget child) => MaterialApp(
  home: Scaffold(
    body: SizedBox(
      width: 375,
      height: 667,
      child: SingleChildScrollView(child: child),
    ),
  ),
);

void main() {
  testWidgets('CURB-65: toggling criteria moves total 0→2 and band', (t) async {
    await t.pumpWidget(_wrap(TopicView(topic: _load('calc_curb65.yaml'))));
    expect(find.byType(ScoreBlockView), findsOneWidget);
    expect(find.textContaining('Low severity'), findsOneWidget);

    final boxes = find.byType(Checkbox);
    expect(boxes, findsNWidgets(5));
    await t.tap(boxes.at(0));
    await t.tap(boxes.at(1));
    await t.pump();

    expect(find.text('2'), findsOneWidget); // total
    expect(find.textContaining('Moderate'), findsOneWidget); // band
    expect(find.textContaining('Low severity'), findsNothing);
  });

  testWidgets('GCS: default selections render 15 / Mild', (t) async {
    await t.pumpWidget(_wrap(TopicView(topic: _load('calc_gcs.yaml'))));
    expect(find.text('15'), findsOneWidget);
    expect(find.textContaining('Mild'), findsOneWidget);
  });

  testWidgets('CIWA-Ar scale: stepper taps update anchor + total/band', (
    t,
  ) async {
    await t.pumpWidget(_wrap(TopicView(topic: _load('calc_ciwa_ar.yaml'))));
    expect(find.byType(ScoreBlockView), findsOneWidget);
    expect(find.textContaining('Minimal'), findsOneWidget);
    expect(find.text('7'), findsWidgets); // a "7" button per 0–7 scale item

    await t.ensureVisible(find.text('7').first);
    await t.tap(find.text('7').first); // nausea → 7
    await t.pump();
    expect(find.textContaining('Constant nausea'), findsOneWidget); // anchor

    await t.ensureVisible(find.text('7').at(1));
    await t.tap(find.text('7').at(1)); // tremor → 7, total 14
    await t.pump();
    expect(find.textContaining('Moderate'), findsOneWidget);
    expect(find.textContaining('Minimal'), findsNothing);
  });

  testWidgets('GCS: choosing worst responses drops to 3 / Severe', (t) async {
    await t.pumpWidget(_wrap(TopicView(topic: _load('calc_gcs.yaml'))));
    // Tap the first "None" chip of each component (eye/verbal/motor → all 1).
    final none = find.textContaining('None');
    expect(none, findsNWidgets(3));
    await t.tap(none.at(0));
    await t.tap(none.at(1));
    await t.tap(none.at(2));
    await t.pump();

    expect(find.text('3'), findsOneWidget);
    expect(find.textContaining('Severe'), findsOneWidget);
  });
}
