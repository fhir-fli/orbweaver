import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:orbweaver/models/topic.dart';

/// Structural parse check for WHO Chart 10 (IV glucose for hypoglycaemia).
void main() {
  test('WHO Chart 10 parses to the expected blocks', () {
    final yaml = File(
      'assets/books/who_imci/topics/who_1_chart10_glucose.yaml',
    ).readAsStringSync();
    final topic = Topic.fromYamlString(yaml);

    expect(topic.id, 'who-imci-chart10-glucose');
    expect(topic.category, TopicCategory.medical);
    expect(topic.pageNumber, 16);

    final blocks = topic.blocks;
    // when/what, dose table, dose+threshold context, neonatal thresholds,
    // after-bolus, 50% dilution, D50 danger callout, sublingual first-aid
    // callout.
    expect(blocks.length, 8);

    final table = blocks.whereType<TableBlock>().single;
    expect(table.columns.length, 2);
    expect(table.rows.length, 5); // < 4 kg … 14–19 kg

    // Two callouts: the D50 danger warning overrides its palette to red;
    // the sublingual first-aid tip keeps the inherited (amber) default.
    final callouts = blocks
        .whereType<ProseBlock>()
        .where((b) => b.callout)
        .toList();
    expect(callouts.length, 2);

    final danger = callouts.firstWhere(
      (b) => b.title!.contains('50% dextrose'),
    );
    expect(danger.ownPaletteArgb['alert'], 0xFFD32F2F);

    final tip = blocks.last as ProseBlock;
    expect(tip.callout, isTrue);
    expect(tip.ownPaletteArgb, isEmpty); // inherits the topic palette
  });
}
