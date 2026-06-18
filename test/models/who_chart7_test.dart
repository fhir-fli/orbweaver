import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:orbweaver/models/topic.dart';

/// Structural parse check for WHO Chart 7 (post-FEAST revision) — verifies
/// the YAML loads into a valid Topic with the resource-stratified layout:
/// FEAST warning callout, first-steps prose, the approach table, the
/// by-weight volume table, reassess/refractory prose, and the malaria
/// caution callout — plus the red harm-warning palette override.
void main() {
  test('WHO Chart 7 parses to the post-FEAST block structure', () {
    final yaml = File(
      'assets/books/who_imci/topics/who_chart7_iv_fluids_shock.yaml',
    ).readAsStringSync();
    final topic = Topic.fromYamlString(yaml);

    expect(topic.id, 'who-imci-chart7-iv-fluids-shock');
    expect(topic.category, TopicCategory.medical);
    expect(topic.pageNumber, 13);

    // Topic-level palette override makes harm-warning callouts red.
    expect(topic.ownPaletteArgb['alert'], 0xFFD32F2F);

    final blocks = topic.blocks;
    // FEAST callout, first steps, hypotension-definition, approach table,
    // volume table, reassess, fluid-refractory, malaria/anaemia callout.
    expect(blocks.length, 8);

    // Leads with the FEAST attention callout.
    final first = blocks.first;
    expect(first, isA<ProseBlock>());
    expect((first as ProseBlock).callout, isTrue);

    // Two tables: the stratified approach (2 cols) and volume-by-weight
    // (3 cols: age, 10 ml/kg, 20 ml/kg).
    final tables = blocks.whereType<TableBlock>().toList();
    expect(tables.length, 2);
    expect(tables[0].columns.length, 2);
    expect(tables[0].rows.length, 5);
    expect(tables[1].columns.length, 3);
    expect(tables[1].rows.length, 5);

    // Ends with the malaria / severe-anaemia caution callout.
    final last = blocks.last;
    expect(last, isA<ProseBlock>());
    expect((last as ProseBlock).callout, isTrue);
  });
}
