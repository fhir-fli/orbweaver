import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:orbweaver/models/topic.dart';

/// Structural parse checks for WHO §1.7–§1.10 (drowning, electrocution,
/// envenoming, trauma).
void main() {
  Topic load(String file) => Topic.fromYamlString(
    File('assets/books/who_imci/topics/$file').readAsStringSync(),
  );

  test('§1.7 drowning & §1.8 electrocution parse', () {
    expect(load('who_1_07_drowning.yaml').id, 'who-imci-1-7-drowning');
    expect(load('who_1_07_drowning.yaml').pageNumber, 33);
    expect(
      load('who_1_08_electrocution.yaml').id,
      'who-imci-1-8-electrocution',
    );
  });

  test('§1.9 envenoming group: overview + snake/scorpion/other', () {
    expect(load('who_1_09_envenoming.yaml').id, 'who-imci-1-9-envenoming');

    final snake = load('who_1_09_1_snake_bite.yaml');
    expect(snake.id, 'who-imci-1-9-1-snake-bite');
    // The antivenom-reaction danger callout is red.
    final reaction = snake.blocks.whereType<ProseBlock>().firstWhere(
      (b) => b.title!.contains('Antivenom reaction'),
    );
    expect(reaction.callout, isTrue);
    expect(reaction.ownPaletteArgb['alert'], 0xFFD32F2F);

    expect(load('who_1_09_2_scorpion.yaml').id, 'who-imci-1-9-2-scorpion');

    final other = load('who_1_09_3_other.yaml');
    expect(other.id, 'who-imci-1-9-3-other');
    // Box jellyfish is a red callout.
    final jelly = other.blocks.whereType<ProseBlock>().firstWhere(
      (b) => b.title!.contains('Box jellyfish'),
    );
    expect(jelly.ownPaletteArgb['alert'], 0xFFD32F2F);
  });

  test('§1.10 trauma group: overview + primary/secondary survey', () {
    expect(load('who_1_10_trauma.yaml').id, 'who-imci-1-10-trauma');
    expect(
      load('who_1_10_1_primary_survey.yaml').id,
      'who-imci-1-10-1-primary-survey',
    );
    expect(
      load('who_1_10_2_secondary_survey.yaml').id,
      'who-imci-1-10-2-secondary-survey',
    );
  });
}
