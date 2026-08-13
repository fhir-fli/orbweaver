import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:orbweaver/models/topic.dart';

/// Structural parse checks for WHO §1.6 poisoning topics.
void main() {
  Topic load(String file) => Topic.fromYamlString(
    File('assets/books/who_imci/topics/$file').readAsStringSync(),
  );

  test('§1.6 overview parses', () {
    final t = load('who_1_06_poisoning.yaml');
    expect(t.id, 'who-imci-1-6-poisoning');
    expect(t.pageNumber, 26);
  });

  test('§1.6.1 ingested: charcoal Table 5 + red contraindications callout', () {
    final t = load('who_1_06_1_ingested.yaml');
    expect(t.id, 'who-imci-1-6-1-ingested');
    final table = t.blocks.whereType<TableBlock>().single;
    expect(table.rows.length, 3); // ≤1y, 1–12y, adolescents/adults

    final danger = t.blocks.whereType<ProseBlock>().firstWhere(
      (b) => b.title!.contains('Contraindications'),
    );
    expect(danger.callout, isTrue);
    expect(danger.ownPaletteArgb['alert'], 0xFFD32F2F);
  });

  test('§1.6.2 / §1.6.3 short route topics parse', () {
    expect(load('who_1_06_2_skin_eye.yaml').id, 'who-imci-1-6-2-skin-eye');
    expect(load('who_1_06_3_inhaled.yaml').id, 'who-imci-1-6-3-inhaled');
  });

  test('§1.6.4 specific poisons covers the 8 agents', () {
    final t = load('who_1_06_4_specific.yaml');
    expect(t.id, 'who-imci-1-6-4-specific');
    final titles = t.blocks
        .whereType<ProseBlock>()
        .map((b) => b.title)
        .join(' ');
    for (final agent in [
      'Corrosives',
      'Petroleum',
      'Organophosphorus',
      'Paracetamol',
      'Aspirin',
      'Iron',
      'opiates',
      'Carbon monoxide',
    ]) {
      expect(titles.contains(agent), isTrue, reason: 'missing $agent');
    }
  });

  test('§1.6.5 prevention parses', () {
    expect(load('who_1_06_5_prevention.yaml').id, 'who-imci-1-6-5-prevention');
  });
}
