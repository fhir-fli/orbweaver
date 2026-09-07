// The Canadian C-Spine Rule is a three-step algorithm (Stiell 2001/2003), so
// it is a flowchart, not a score. These tests hold the encoded chart to the
// published rule: three stages in order, every "image" arrow resolves to the
// shared imaging box, the only non-imaging leaf is the rotation step, and
// the nine published exclusions are on the page.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orbweaver/models/topic.dart';
import 'package:orbweaver/widgets/topic_view.dart';

const _file = 'assets/books/calculators/topics/calc_canadian_cspine.yaml';

Topic _load() => Topic.fromYamlString(File(_file).readAsStringSync());

void main() {
  group('Canadian C-Spine Rule flowchart', () {
    late AlgorithmFlowchart algo;
    late Topic topic;
    setUpAll(() {
      topic = _load();
      algo = topic.blocks.whereType<FlowchartBlock>().single.algorithm!;
    });

    test('three stages: high-risk, low-risk, rotation', () {
      expect(algo.stages, hasLength(3));
      expect(algo.stages[0].decision, contains('high-risk'));
      expect(algo.stages[1].decision, contains('low-risk'));
      expect(algo.stages[2].decision, contains('45°'));
    });

    test('high-risk factors are the three published ones', () {
      final c = algo.stages[0].criteria.join(' ');
      expect(c, contains('Age ≥ 65'));
      expect(c, contains('Dangerous mechanism'));
      expect(c, contains('Paraesthesias'));
      expect(c, contains('100 km/h'));
      expect(c, contains('5 stairs'));
    });

    test('low-risk factors are the five published ones', () {
      expect(algo.stages[1].criteria, hasLength(5));
      final c = algo.stages[1].criteria.join(' ');
      expect(c, contains('rear-end'));
      expect(c, contains('Sitting'));
      expect(c, contains('Ambulatory'));
      expect(c, contains('Delayed'));
      expect(c, contains('Absence of midline'));
    });

    test('every goto resolves to the shared imaging box', () {
      final ids = algo.boxes.map((b) => b.id).whereType<String>().toSet();
      expect(ids, contains('image'));
      for (final s in algo.stages) {
        for (final o in s.outcomes) {
          if (o.goto != null) expect(ids, contains(o.goto));
        }
      }
    });

    test('steps 1 and 2 image or continue; step 3 is the only clearance', () {
      for (final s in algo.stages.take(2)) {
        expect(s.outcomes.where((o) => o.goto == 'image'), hasLength(1));
        expect(s.outcomes.where((o) => o.cont), hasLength(1));
      }
      final last = algo.stages[2];
      expect(last.outcomes.where((o) => o.goto == 'image'), hasLength(1));
      final clear = last.outcomes.where((o) => o.box != null).single;
      expect(clear.box!.title, contains('No imaging'));
      expect(clear.box!.severity, RowSeverity.nonUrgent);
      // "not assessed" must route to imaging, never to a silent default.
      expect(
        last.outcomes.firstWhere((o) => o.goto == 'image').label,
        contains('not assessed'),
      );
    });

    test('the nine published exclusions are on the page', () {
      final prose = topic.blocks.whereType<ProseBlock>().firstWhere(
        (b) => (b.title ?? '').startsWith('Do not apply'),
      );
      final lines = prose.markdown
          .split('\n')
          .where((l) => l.trimLeft().startsWith('- '))
          .toList();
      expect(lines, hasLength(9));
      final text = lines.join(' ');
      for (final needle in [
        'under 16',
        'GCS below 15',
        '48 h',
        'Penetrating',
        'paralysis',
        'ankylosing spondylitis',
        'reassessment',
        'systolic BP < 90',
        'above the clavicles',
      ]) {
        expect(text, contains(needle));
      }
    });

    testWidgets('renders the chart and both leaves', (t) async {
      await t.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 375,
              height: 2000,
              child: SingleChildScrollView(child: TopicView(topic: topic)),
            ),
          ),
        ),
      );
      expect(find.textContaining('Image the cervical spine'), findsWidgets);
      expect(find.textContaining('No imaging'), findsWidgets);
    });
  });
}
