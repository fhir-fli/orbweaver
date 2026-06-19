import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:orbweaver/models/topic.dart';

/// Structural parse check for WHO Chart 11 (severe dehydration emergency).
void main() {
  test('WHO Chart 11 parses to the expected blocks', () {
    final yaml = File(
      'assets/books/who_imci/topics/who_chart11_dehydration.yaml',
    ).readAsStringSync();
    final topic = Topic.fromYamlString(yaml);

    expect(topic.id, 'who-imci-chart11-dehydration');
    expect(topic.category, TopicCategory.medical);
    expect(topic.pageNumber, 17);

    final blocks = topic.blocks;
    // when-to-use, IV rehydration, IV table, reassess, add-ORS,
    // ORS table, reclassify.
    expect(blocks.length, 7);

    // Two tables: the 3-column IV fluid table and the 2-column ORS table,
    // each with one row per weight band.
    final tables = blocks.whereType<TableBlock>().toList();
    expect(tables.length, 2);

    final ivTable = tables.first;
    expect(ivTable.columns.length, 3);
    expect(ivTable.rows.length, 5);

    final orsTable = tables.last;
    expect(orsTable.columns.length, 2);
    expect(orsTable.rows.length, 5);
  });
}
