import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:orbweaver/models/topic.dart';

void main() {
  group('Topic.fromYamlString (WVEMS 2025-008)', () {
    late Topic topic;

    setUpAll(() {
      final yaml = File(
        'assets/books/wvems/topics/wvems_2025_008.yaml',
      ).readAsStringSync();
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
      expect(fc.entryChain.first.shape, NodeShape.stadium);
      expect(fc.entryChain.first.text, contains('Systolic'));
      expect(fc.decision!.shape, NodeShape.diamond);
      expect(fc.decision!.text, 'Severity?');
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
      // Cross-link year-typo fix: 008's Consider links were corrected
      // 2025→2026 when cross-topic navigation went live.
      expect(conv.bullets.first.linkId, 'wvems-2026-014');
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
      // 'Pediatrics' is deliberately absent: it is a BandCalloutBlock now, not
      // a ProseBlock — see the peds-band test below.
      expect(titles, [
        'Poor Perfusion',
        'Shock Imperatives',
        'Medication',
        'Notes',
        'References',
      ]);
    });

    test('highlight flag set for the callout, not for pediatrics', () {
      final byTitle = {
        for (final p in topic.blocks.whereType<ProseBlock>()) p.title: p,
      };
      expect(byTitle['Poor Perfusion']!.highlight, isTrue);
      expect(byTitle['Medication']!.highlight, isFalse);
      // Pediatrics must NOT be a highlighted prose block any more: `highlight`
      // tints with the CHAPTER ACCENT, which rendered the peds section salmon
      // on Trauma and green on Medical. The print uses pink on every one.
      expect(byTitle.containsKey('Pediatrics'), isFalse);
    });

    test('pediatrics is a pink peds band, not a chapter-accent highlight', () {
      final peds = topic.blocks
          .whereType<BandCalloutBlock>()
          .where((b) => b.band == CalloutBand.peds)
          .toList();
      expect(peds, hasLength(1));
      expect(peds.single.title, 'Pediatrics');
      expect(peds.single.markdown, isNotEmpty);
    });

    test('the credentialed-for-CC line is a bare lavender band', () {
      final cc = topic.blocks
          .whereType<BandCalloutBlock>()
          .where((b) => b.band == CalloutBand.criticalCare)
          .toList();
      expect(cc, hasLength(1));
      // A bare band: the print tints this line inside another section, so it
      // carries no heading of its own.
      expect(cc.single.title, '');
      expect(cc.single.markdown, contains('credentialed'));
    });

    test('prose markdown content preserved', () {
      final meds = topic.blocks.whereType<ProseBlock>().firstWhere(
        (p) => p.title == 'Medication',
      );
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
      final yaml = File(
        'test/fixtures/demo_all_blocks.yaml',
      ).readAsStringSync();
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
      final cascade = topic.blocks.whereType<FlowchartBlock>().firstWhere(
        (b) => b.variant == FlowchartVariant.cascade,
      );
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

  group('Topic palette frontmatter (ownPaletteArgb)', () {
    test('parses a palette: map into role→ARGB ints, skipping bad values', () {
      final topic = Topic.fromYamlString('''
topic:
  id: "t"
  title: "T"
  palette:
    accent: "0xFFD81B60"
    alert: "#FFB300"
    bogus: "nope"
  blocks:
    - type: "prose"
      markdown: "x"
''');
      expect(topic.ownPaletteArgb['accent'], 0xFFD81B60);
      expect(topic.ownPaletteArgb['alert'], 0xFFFFB300);
      expect(topic.ownPaletteArgb.containsKey('bogus'), isFalse);
    });

    test('no palette: → empty map', () {
      final topic = Topic.fromYamlString('''
topic:
  id: "t"
  title: "T"
  blocks:
    - type: "prose"
      markdown: "x"
''');
      expect(topic.ownPaletteArgb, isEmpty);
    });
  });

  group('algorithm flowchart variant (ProtocolBook p.30 Hydrocarbon)', () {
    late FlowchartBlock block;
    late AlgorithmFlowchart algo;

    setUpAll(() {
      final yaml = File(
        'assets/books/protocolbook/topics/pb_030_hydrocarbon.yaml',
      ).readAsStringSync();
      final topic = Topic.fromYamlString(yaml);
      block = topic.blocks.whereType<FlowchartBlock>().first;
      algo = block.algorithm!;
    });

    test('block is an algorithm-variant flowchart', () {
      expect(block.variant, FlowchartVariant.algorithm);
      expect(block.algorithm, isNotNull);
      expect(block.severity, isNull);
      expect(block.cascade, isNull);
    });

    test('entry, named boxes and stages parse', () {
      expect(algo.entry!.text, 'Hydrocarbon ingestion');
      expect(algo.entry!.shape, NodeShape.stadium);
      expect(algo.boxes.single.id, 'treat');
      expect(algo.boxes.single.bullets, hasLength(4));
      expect(algo.stages, hasLength(3));
      expect(algo.terminal!.title, 'Discharge');
    });

    test('stage 1 outcomes: goto + continue vs inline box', () {
      final s1 = algo.stages.first;
      expect(s1.decision, 'Any of these present?');
      expect(s1.criteria, hasLength(4));
      final yes = s1.outcomes.first;
      expect(yes.goto, 'treat');
      expect(yes.cont, isTrue);
      // goto resolves to the shared "treat" box.
      expect(algo.boxFor(yes)!.title, 'Treatment');
      final no = s1.outcomes[1];
      expect(no.box!.title, 'Observe');
      expect(no.cont, isFalse); // terminal branch (self-contained observe path)
    });

    test('severity tint on the terminal ICU disposition', () {
      final s2 = algo.stages[1];
      final icu = s2.outcomes.last;
      expect(icu.box!.title, 'Intubate and admit to ICU');
      expect(icu.box!.severity, RowSeverity.emergency);
      expect(icu.cont, isFalse);
    });
  });
}
