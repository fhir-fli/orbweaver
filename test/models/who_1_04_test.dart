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
    // priority, no-IV-dehydration, shock, why-differs, also-screen.
    expect(blocks.length, 5);

    // The "do NOT give IV fluids" danger block overrides its accent to red.
    final danger = blocks
        .whereType<ProseBlock>()
        .firstWhere((b) => b.title!.contains('do NOT give IV fluids'));
    expect(danger.highlight, isTrue);
    expect(danger.ownPaletteArgb['accent'], 0xFFD32F2F);
  });
}
