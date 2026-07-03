import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:orbweaver/models/topic.dart';

/// Structural parse check for WHO Chart 8 (IV fluids for shock WITH severe
/// acute malnutrition).
void main() {
  test('WHO Chart 8 parses to the expected blocks', () {
    final yaml = File(
      'assets/books/who_imci/topics/who_1_chart08_iv_fluids_sam.yaml',
    ).readAsStringSync();
    final topic = Topic.fromYamlString(yaml);

    expect(topic.id, 'who-imci-chart8-iv-fluids-sam');
    expect(topic.category, TopicCategory.medical);
    expect(topic.pageNumber, 14);
    // STOP/harm callout renders red.
    expect(topic.ownPaletteArgb['alert'], 0xFFD32F2F);

    final blocks = topic.blocks;
    // gate, first steps, volume table, monitor, improving, no-improvement,
    // deteriorate callout.
    expect(blocks.length, 7);

    final table = blocks.whereType<TableBlock>().single;
    expect(table.columns.length, 2);
    expect(table.rows.length, 8); // 4–18 kg in 2 kg steps

    // Ends with the "deteriorate — STOP" caution callout.
    final last = blocks.last;
    expect(last, isA<ProseBlock>());
    expect((last as ProseBlock).callout, isTrue);
  });
}
