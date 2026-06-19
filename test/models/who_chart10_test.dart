import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:orbweaver/models/topic.dart';

/// Structural parse check for WHO Chart 10 (IV glucose for hypoglycaemia).
void main() {
  test('WHO Chart 10 parses to the expected blocks', () {
    final yaml = File(
      'assets/books/who_imci/topics/who_chart10_glucose.yaml',
    ).readAsStringSync();
    final topic = Topic.fromYamlString(yaml);

    expect(topic.id, 'who-imci-chart10-glucose');
    expect(topic.category, TopicCategory.medical);
    expect(topic.pageNumber, 16);

    final blocks = topic.blocks;
    // when/what, dose table, after-bolus, 50% dilution, sublingual first aid.
    expect(blocks.length, 5);

    final table = blocks.whereType<TableBlock>().single;
    expect(table.columns.length, 2);
    expect(table.rows.length, 5); // < 4 kg … 14–19 kg

    final last = blocks.last;
    expect(last, isA<ProseBlock>());
    expect((last as ProseBlock).callout, isTrue);
  });
}
