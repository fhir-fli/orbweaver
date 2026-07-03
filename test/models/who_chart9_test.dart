import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:orbweaver/models/topic.dart';

/// Structural parse check for WHO Chart 9 (rectal diazepam for convulsions).
void main() {
  test('WHO Chart 9 parses to the expected blocks', () {
    final yaml = File(
      'assets/books/who_imci/topics/who_1_chart09_diazepam.yaml',
    ).readAsStringSync();
    final topic = Topic.fromYamlString(yaml);

    expect(topic.id, 'who-imci-chart9-diazepam');
    expect(topic.category, TopicCategory.medical);
    expect(topic.pageNumber, 15);
    expect(topic.ownPaletteArgb['alert'], 0xFFD32F2F);

    final blocks = topic.blocks;
    // first-line, rectal technique, dose table, neonate, escalation,
    // fever, airway callout.
    expect(blocks.length, 7);

    final table = blocks.whereType<TableBlock>().single;
    expect(table.columns.length, 2);
    expect(table.rows.length, 5); // < 4 kg … 14–19 kg

    final last = blocks.last;
    expect(last, isA<ProseBlock>());
    expect((last as ProseBlock).callout, isTrue);
  });
}
