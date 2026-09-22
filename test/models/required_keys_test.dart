import 'package:flutter_test/flutter_test.dart';
import 'package:orbweaver/models/formulary.dart';
import 'package:orbweaver/models/topic.dart';
import 'package:yaml/yaml.dart';

/// A key the schema requires must not be quietly replaced by a default when
/// the parser meets a file that lacks it. The schema test catches such a
/// file in this repo; these guard the parser itself, which also reads
/// pasted playground topics that never passed the schema.
void main() {
  YamlMap yaml(String s) => loadYaml(s) as YamlMap;

  test('merge_arrows without columns or target_center throws', () {
    expect(
      () => MergeArrowsBlock.fromYaml(yaml('type: merge_arrows\nsources: [0]')),
      throwsA(isA<TypeError>()),
    );
  });

  test('an algorithm stage without outcomes throws', () {
    expect(
      () => AlgoStage.fromYaml(yaml('decision: Shocked?')),
      throwsA(isA<TypeError>()),
    );
  });

  test('an algorithm flowchart without stages throws', () {
    expect(
      () => AlgorithmFlowchart.fromYaml(yaml('variant: algorithm')),
      throwsA(isA<TypeError>()),
    );
  });

  test('a cycle flowchart without nodes throws', () {
    expect(
      () => CycleFlowchart.fromYaml(yaml('variant: cycle')),
      throwsA(isA<TypeError>()),
    );
  });

  test('a formulary without facets or drugs throws', () {
    // Formulary.fromYaml casts `f['bands'] as YamlMap` on its second line,
    // before it reads facets or drugs (read in lib/models/formulary.dart),
    // so a fixture with `bands: []` throws there and proves nothing about
    // the two lists. Both axes here are valid maps.
    const head =
        'formulary:\n'
        '  id: f\n'
        '  title: T\n'
        '  bands: {label: Age, columns: [Adult]}\n'
        '  bands_art: {label: ART, columns: [Adult]}\n';
    expect(
      () => Formulary.fromYaml(yaml('$head  drugs: []')),
      throwsA(isA<TypeError>()),
      reason: 'no facets',
    );
    expect(
      () => Formulary.fromYaml(yaml('$head  facets: []')),
      throwsA(isA<TypeError>()),
      reason: 'no drugs',
    );
  });
}
