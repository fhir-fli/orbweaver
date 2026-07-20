// Widget tests for the formula block: the computed value must actually reach
// the screen (the registry can be perfect, but a rendering bug would still ship
// a blank or wrong calculator). Pumps the real TopicView so theme resolution,
// input wiring, and live recompute are all exercised end-to-end.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orbweaver/models/topic.dart';
import 'package:orbweaver/widgets/blocks/formula_block_view.dart';
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
  testWidgets('MAP: placeholder until inputs, then computes 93.3', (t) async {
    await t.pumpWidget(_wrap(TopicView(topic: _load('calc_map.yaml'))));

    expect(find.byType(FormulaBlockView), findsOneWidget);
    expect(find.text('Enter values to calculate'), findsOneWidget);

    final fields = find.byType(TextField);
    expect(fields, findsNWidgets(2)); // SBP, DBP
    await t.enterText(fields.at(0), '120');
    await t.enterText(fields.at(1), '80');
    await t.pump();

    expect(find.text('Enter values to calculate'), findsNothing);
    expect(find.text('93.3'), findsOneWidget);
    expect(find.text('mmHg'), findsWidgets);
  });

  testWidgets('MAP: low value surfaces the perfusion caveat text', (t) async {
    await t.pumpWidget(_wrap(TopicView(topic: _load('calc_map.yaml'))));
    final fields = find.byType(TextField);
    await t.enterText(fields.at(0), '85');
    await t.enterText(fields.at(1), '50');
    await t.pump();

    expect(find.text('61.7'), findsOneWidget);
    expect(find.textContaining('perfusion'), findsOneWidget);
  });

  testWidgets('Holliday-Segar: renders both rate and daily rows', (t) async {
    await t.pumpWidget(
        _wrap(TopicView(topic: _load('calc_holliday_segar.yaml'))));
    await t.enterText(find.byType(TextField).first, '15');
    await t.pump();

    expect(find.text('50'), findsOneWidget); // hourly mL/hr
    expect(find.text('1250'), findsOneWidget); // daily mL/day
    expect(find.text('mL/hr'), findsOneWidget);
    expect(find.text('mL/day'), findsOneWidget);
  });

  testWidgets('corrected sodium renders with default unit select', (t) async {
    await t.pumpWidget(
        _wrap(TopicView(topic: _load('calc_corrected_sodium.yaml'))));
    // two number fields (Na, glucose); one select (glucose unit) defaulting mg/dL
    final fields = find.byType(TextField);
    expect(fields, findsNWidgets(2));
    await t.enterText(fields.at(0), '130');
    await t.enterText(fields.at(1), '600');
    await t.pump();

    expect(find.text('142'), findsOneWidget); // Hillier
    expect(find.text('138'), findsOneWidget); // Katz
  });
}
