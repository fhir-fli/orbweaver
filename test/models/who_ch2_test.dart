import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:orbweaver/models/topic.dart';

/// Structural parse checks for WHO Chapter 2 (diagnostic approaches).
void main() {
  Topic load(String file) => Topic.fromYamlString(
        File('assets/books/who_imci/topics/$file').readAsStringSync(),
      );

  test('Chapter 2 sections parse with the expected ids and pages', () {
    final cases = {
      'who_2_01_imci_stages.yaml': ('who-imci-2-1-imci-stages', 41),
      'who_2_02_history.yaml': ('who-imci-2-2-history', 42),
      'who_2_03_examination.yaml': ('who-imci-2-3-examination', 42),
      'who_2_04_labs.yaml': ('who-imci-2-4-labs', 43),
      'who_2_05_differential.yaml': ('who-imci-2-5-differential', 44),
    };
    cases.forEach((file, expected) {
      final t = load(file);
      expect(t.id, expected.$1);
      expect(t.pageNumber, expected.$2);
      expect(t.category, TopicCategory.medical);
      expect(t.blocks, isNotEmpty);
    });
  });

  test('§2.5 links to the §1.5 differential tables', () {
    final t = load('who_2_05_differential.yaml');
    final body = t.blocks.whereType<ProseBlock>().map((b) => b.markdown).join();
    expect(body, contains('topic:who-imci-1-5-diagnostic'));
  });
}
