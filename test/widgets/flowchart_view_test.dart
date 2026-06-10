import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orbweaver/models/topic.dart';
import 'package:orbweaver/screens/topic_frame.dart';
import 'package:orbweaver/widgets/topic_view.dart';

Topic _loadWvems() {
  final yaml = File('assets/books/wvems/topics/wvems_2025_008.yaml').readAsStringSync();
  return Topic.fromYamlString(yaml);
}

Widget _wrap(Widget child) {
  return MaterialApp(
    home: Scaffold(
      body: SizedBox(
        width: TopicFrame.frameWidth,
        height: TopicFrame.frameHeight,
        child: SingleChildScrollView(child: child),
      ),
    ),
  );
}

void main() {
  late Topic topic;
  setUpAll(() => topic = _loadWvems());

  group('TopicView (WVEMS 2025-008, 375x667 frame)', () {
    testWidgets('renders the title and page number', (tester) async {
      await tester.pumpWidget(_wrap(TopicView(topic: topic)));
      expect(find.text('Circulation / Shock'), findsOneWidget);
      expect(find.text('8'), findsOneWidget);
    });

    testWidgets('renders the decision text', (tester) async {
      await tester.pumpWidget(_wrap(TopicView(topic: topic)));
      expect(find.text('Severity?'), findsOneWidget);
    });

    testWidgets('renders all three branch labels', (tester) async {
      await tester.pumpWidget(_wrap(TopicView(topic: topic)));
      expect(find.text('Mild'), findsOneWidget);
      expect(find.text('Moderate'), findsOneWidget);
      expect(find.text('Severe'), findsOneWidget);
    });

    testWidgets('renders branch actions with provider badges', (tester) async {
      await tester.pumpWidget(_wrap(TopicView(topic: topic)));
      expect(find.text('Saline Lock'), findsOneWidget);
      expect(find.text('NS Bolus'), findsAtLeastNWidgets(2));
      expect(find.text('Epi Drip'), findsAtLeastNWidgets(1));
      expect(find.text('A'), findsWidgets);
      expect(find.text('E'), findsWidgets);
      expect(find.text('I'), findsWidgets);
    });

    testWidgets('renders convergence bullets', (tester) async {
      await tester.pumpWidget(_wrap(TopicView(topic: topic)));
      expect(find.text('Consider'), findsOneWidget);
      expect(find.text('• Tachycardia'), findsOneWidget);
      expect(find.text('• Bradycardia'), findsOneWidget);
    });

    testWidgets('renders dose table rows', (tester) async {
      await tester.pumpWidget(_wrap(TopicView(topic: topic)));
      expect(find.text('500 mL'), findsOneWidget);
      expect(find.text('5 mcg/kg/min'), findsOneWidget);
    });

    testWidgets('renders prose block titles', (tester) async {
      await tester.pumpWidget(_wrap(TopicView(topic: topic)));
      expect(find.text('Poor Perfusion'), findsOneWidget);
      expect(find.text('Shock Imperatives'), findsOneWidget);
      expect(find.text('Medication'), findsOneWidget);
      expect(find.text('Pediatrics'), findsOneWidget);
      expect(find.text('References'), findsOneWidget);
    });

    testWidgets('no overflow at 375 width', (tester) async {
      await tester.pumpWidget(_wrap(TopicView(topic: topic)));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });
}
