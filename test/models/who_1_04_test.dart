import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:orbweaver/models/topic.dart';

/// Structural parse check for WHO §1.4 (emergency treatment for SAM).
void main() {
  test('WHO §1.4 SAM parses to the expected blocks', () {
    final yaml = File(
      'assets/books/who_imci/topics/who_1_04_sam_emergency.yaml',
    ).readAsStringSync();
    final topic = Topic.fromYamlString(yaml);

    expect(topic.id, 'who-imci-1-4-sam-emergency');
    expect(topic.category, TopicCategory.medical);
    expect(topic.pageNumber, 19);

    final blocks = topic.blocks;
    // priority, dehydration-without-shock, evidence-update, ReSoMal danger,
    // shock, why-differs, also-screen.
    expect(blocks.length, 7);

    // GASTROSAM update: the red danger is now the ReSoMal hyponatraemia
    // callout (not "no IV fluids", which the trial refuted).
    final danger = blocks.whereType<ProseBlock>().firstWhere(
      (b) => b.title!.contains('ReSoMal'),
    );
    expect(danger.callout, isTrue);
    expect(danger.ownPaletteArgb['alert'], 0xFFD32F2F);

    // The evidence-update block is a blue-accented highlight.
    final evidence = blocks.whereType<ProseBlock>().firstWhere(
      (b) => b.title!.contains('Evidence update'),
    );
    expect(evidence.highlight, isTrue);
    expect(evidence.ownPaletteArgb['accent'], 0xFF1565C0);
  });
}
