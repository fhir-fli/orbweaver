import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:orbweaver/models/topic.dart';

void main() {
  group('Topic.fromYamlString (WVEMS 2025-008)', () {
    late Topic topic;

    setUpAll(() {
      final yaml =
          File('assets/topics/wvems_2025_008.yaml').readAsStringSync();
      topic = Topic.fromYamlString(yaml);
    });

    test('parses top-level metadata', () {
      expect(topic.id, 'wvems-2025-008');
      expect(topic.title, 'Circulation / Shock');
      expect(topic.version, 'v250218');
      expect(topic.lastReviewed, '2024-10');
      expect(topic.category, TopicCategory.universal);
      expect(topic.pageNumber, 8);
      expect(topic.aliases, contains('Hypotension'));
      expect(topic.tags, contains('shock'));
    });

    test('first block is a severity flowchart', () {
      final block = topic.blocks.first;
      expect(block, isA<FlowchartBlock>());
      final fc = block as FlowchartBlock;
      expect(fc.variant, FlowchartVariant.severity);
      expect(fc.severity, isNotNull);
      expect(fc.cascade, isNull);
    });

    test('severity flowchart entry and decision', () {
      final fc = (topic.blocks.first as FlowchartBlock).severity!;
      expect(fc.entry.shape, NodeShape.stadium);
      expect(fc.entry.text, contains('Systolic'));
      expect(fc.decision.shape, NodeShape.diamond);
      expect(fc.decision.text, 'Severity?');
    });

    test('severity flowchart has three branches with actions', () {
      final fc = (topic.blocks.first as FlowchartBlock).severity!;
      expect(fc.branches.map((b) => b.id), ['mild', 'moderate', 'severe']);

      final severe = fc.branches.last;
      expect(severe.criteria, ['Poor Perfusion', 'Altered LOC']);
      expect(severe.actions.length, 4);
      expect(severe.actions.first.text, 'NS Bolus');
      expect(severe.actions.first.providerLevel, ProviderLevel.als);
      expect(severe.actions.first.kind, ActionKind.medicationAdministration);
    });

    test('severity flowchart convergence bullets with link ids', () {
      final conv =
          (topic.blocks.first as FlowchartBlock).severity!.convergence!;
      expect(conv.text, 'Consider');
      expect(conv.bullets.length, 6);
      expect(conv.bullets.first.text, 'Tachycardia');
      expect(conv.bullets.first.linkId, 'wvems-2025-014');
    });

    test('severity flowchart dose table rows', () {
      final doses = (topic.blocks.first as FlowchartBlock).severity!.doseTable;
      expect(doses.length, 3);
      expect(doses.first.drug, 'NS Bolus');
      expect(doses.first.dose, '500 mL');
      expect(doses.first.population, DosePopulation.adult);
    });

    test('prose blocks follow the flowchart', () {
      final prose = topic.blocks.whereType<ProseBlock>().toList();
      final titles = prose.map((p) => p.title).toList();
      expect(titles, [
        'Poor Perfusion',
        'Shock Imperatives',
        'Medication',
        'Notes',
        'Pediatrics',
        'References',
      ]);
    });

    test('highlight flag set for callout and pediatrics', () {
      final byTitle = {
        for (final p in topic.blocks.whereType<ProseBlock>()) p.title: p,
      };
      expect(byTitle['Poor Perfusion']!.highlight, isTrue);
      expect(byTitle['Pediatrics']!.highlight, isTrue);
      expect(byTitle['Medication']!.highlight, isFalse);
    });

    test('prose markdown content preserved', () {
      final meds = topic.blocks
          .whereType<ProseBlock>()
          .firstWhere((p) => p.title == 'Medication');
      expect(meds.markdown, contains('**NS Bolus**'));
      expect(meds.markdown, contains('Dopamine'));
    });

    test('TopicAction supports timing/condition annotations', () {
      const action = TopicAction(
        text: 'Epinephrine',
        timing: 'Q 5 min',
        condition: 'If asystole',
      );
      expect(action.timing, 'Q 5 min');
      expect(action.condition, 'If asystole');
    });
  });

  group('Topic.fromYamlString (demo_all_blocks)', () {
    late Topic topic;

    setUpAll(() {
      final yaml =
          File('assets/topics/demo_all_blocks.yaml').readAsStringSync();
      topic = Topic.fromYamlString(yaml);
    });

    test('parses every block type', () {
      final types = topic.blocks.map((b) => b.runtimeType.toString()).toList();
      expect(types, contains('ProseBlock'));
      expect(types, contains('TableBlock'));
      expect(types, contains('FlowchartBlock'));
      expect(types, contains('DrugCardBlock'));
      expect(types, contains('ImageBlock'));
    });

    test('table block parses columns, rows, severity, cell variants', () {
      final tables = topic.blocks.whereType<TableBlock>().toList();
      expect(tables.length, 2);

      final triage = tables.first;
      expect(triage.title, contains('IMCI'));
      expect(triage.columns, ['Sign', 'Action']);
      expect(triage.rows.length, 4);
      expect(triage.rows.first.severity, RowSeverity.emergency);
      expect(triage.rows[2].severity, RowSeverity.priority);
      expect(triage.rows.last.severity, RowSeverity.nonUrgent);

      // First row: TextCell + BulletCell.
      final firstRow = triage.rows.first;
      expect(firstRow.cells.first, isA<TextCell>());
      expect(firstRow.cells[1], isA<BulletCell>());
      expect((firstRow.cells[1] as BulletCell).items, hasLength(3));
    });

    test('table block parses grouped row headers', () {
      final cprTable = topic.blocks.whereType<TableBlock>().last;
      expect(cprTable.title, contains('CPR'));
      expect(cprTable.rows.first.group, 'Compress');
      expect(cprTable.rows.first.header, 'Rate');
      expect(cprTable.rows.last.group, 'Airway');
    });

    test('cascade flowchart block parses linked chain', () {
      final cascade = topic.blocks
          .whereType<FlowchartBlock>()
          .firstWhere((b) => b.variant == FlowchartVariant.cascade);
      expect(cascade.cascade, isNotNull);
      var step = cascade.cascade!.root;
      var depth = 1;
      while (step.continuation != null) {
        step = step.continuation!;
        depth++;
      }
      expect(depth, 4);
      expect(cascade.cascade!.root.actionAnswer, YesNo.yes);
      expect(cascade.cascade!.root.continuationAnswer, YesNo.no);
    });

    test('drug card parses all sections', () {
      final card = topic.blocks.whereType<DrugCardBlock>().single;
      expect(card.name, 'Epinephrine');
      expect(card.drugClass, contains('Sympathomimetic'));
      expect(card.indications, hasLength(3));
      expect(card.contraindications, hasLength(1));
      expect(card.doses, hasLength(2));
      expect(card.doses.first.population, DosePopulation.adult);
      expect(card.doses.last.population, DosePopulation.peds);
      expect(card.warnings, hasLength(2));
      expect(card.pearls, hasLength(2));
    });

    test('image block parses path, caption, size', () {
      final image = topic.blocks.whereType<ImageBlock>().single;
      expect(image.path, contains('missing_demo.png'));
      expect(image.caption, isNotNull);
      expect(image.size, ImageSize.medium);
    });
  });
}
