import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:orbweaver/models/topic.dart';

/// Structural parse checks for WHO §1.5 diagnostic-considerations topics.
void main() {
  Topic load(String file) => Topic.fromYamlString(
        File('assets/books/who_imci/topics/$file').readAsStringSync(),
      );

  test('§1.5 overview parses', () {
    final t = load('who_1_05_diagnostic.yaml');
    expect(t.id, 'who-imci-1-5-diagnostic');
    expect(t.pageNumber, 20);
  });

  test('§1.5.1 airway has a differential table', () {
    final t = load('who_1_05_1_airway_dx.yaml');
    expect(t.id, 'who-imci-1-5-1-airway-dx');
    final table = t.blocks.whereType<TableBlock>().single;
    expect(table.columns, ['Diagnosis / cause', 'In favour']);
    expect(table.rows.length, 6); // pneumonia … diphtheria
    // The "In favour" cell is a bulleted list.
    expect(table.rows.first.cells[1], isA<BulletCell>());
  });

  test('§1.5.2 shock differential lists 5 causes', () {
    final t = load('who_1_05_2_shock_dx.yaml');
    expect(t.id, 'who-imci-1-5-2-shock-dx');
    final table = t.blocks.whereType<TableBlock>().single;
    expect(table.rows.length, 5);
  });

  test('§1.5.3 coma has two tables (Table 3 + young-infant Table 4)', () {
    final t = load('who_1_05_3_coma_dx.yaml');
    expect(t.id, 'who-imci-1-5-3-coma-dx');
    expect(t.pageNumber, 23);
    final tables = t.blocks.whereType<TableBlock>().toList();
    expect(tables.length, 2);
    expect(tables[0].rows.length, 9); // meningitis … DKA
    expect(tables[1].rows.length, 4); // young-infant causes
  });
}
