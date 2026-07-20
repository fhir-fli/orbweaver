// Structural tests: every calculator topic's YAML must parse into a valid
// FormulaBlock whose `kind` is actually wired into the registry, with
// well-formed inputs. This catches author typos (kind/key mismatches, a
// select with no options, an undeclared kind) before they ship.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:orbweaver/data/formula_registry.dart';
import 'package:orbweaver/models/topic.dart';

const _dir = 'assets/books/calculators/topics';

/// Each calculator file + a minimal valid input vector proving its `kind`
/// resolves in the registry and produces output.
const _files = <String, Map<String, dynamic>>{
  'calc_creatinine_clearance.yaml': {
    'age': 60,
    'sex': 'M',
    'weight': 80,
    'creatinine': 1.0,
  },
  'calc_holliday_segar.yaml': {'weight': 15},
  'calc_corrected_sodium.yaml': {'sodium': 130, 'glucose': 600},
  'calc_anion_gap.yaml': {'sodium': 140, 'chloride': 100, 'bicarbonate': 24},
  'calc_winters.yaml': {'bicarbonate': 12},
  'calc_aa_gradient.yaml': {'fio2': 21, 'paco2': 40, 'pao2': 90},
  'calc_map.yaml': {'sbp': 120, 'dbp': 80},
  'calc_ideal_body_weight.yaml': {'height': 180, 'sex': 'M'},
  'calc_meld.yaml': {
    'sex': 'F',
    'bilirubin': 2.0,
    'sodium': 130,
    'inr': 1.5,
    'creatinine': 1.5,
    'albumin': 3.0,
  },
  'calc_qtc.yaml': {'qt': 400, 'hr': 60},
  'calc_free_water_deficit.yaml': {'weight': 70, 'sex': 'M', 'sodium': 160},
  'calc_anthropometrics.yaml': {'height': 180, 'weight': 80},
  'calc_osmolal_gap.yaml': {
    'measured': 300,
    'sodium': 140,
    'glucose': 90,
    'bun': 14,
  },
  'calc_parkland.yaml': {'weight': 70, 'tbsa': 40},
  'calc_urinary_indices.yaml': {
    'serum_na': 140,
    'urine_na': 10,
    'serum_cr': 5,
    'urine_cr': 100,
  },
  'calc_anc.yaml': {'wbc': 7.5, 'segs': 60},
  'calc_fib4.yaml': {'age': 60, 'ast': 50, 'alt': 40, 'platelets': 150},
  'calc_maddrey.yaml': {'pt': 20, 'control_pt': 12, 'bilirubin': 10},
  'calc_oxygenation.yaml': {'fio2': 21, 'pao2': 90},
  'calc_dday_age.yaml': {'age': 80},
  'calc_lille.yaml': {
    'age': 50,
    'albumin': 2.5,
    'bilirubin_day0': 15,
    'bilirubin_day7': 12,
    'creatinine': 1.0,
    'pt': 20,
  },
  'calc_reticulocyte.yaml': {'retic': 5, 'hct': 30},
  'calc_lights.yaml': {
    'pleural_protein': 4.0,
    'serum_protein': 6.0,
    'pleural_ldh': 100,
    'serum_ldh': 200,
    'serum_ldh_uln': 250,
  },
  'calc_prevent_ascvd.yaml': {
    'sex': 'F',
    'age': 50,
    'total_c': 200,
    'hdl_c': 45,
    'sbp': 160,
    'egfr': 90,
    'bp_tx': 'yes',
    'diabetes': 'yes',
  },
  'calc_glasgow_blatchford.yaml': {
    'bun': 25,
    'hgb': 11,
    'sex': 'M',
    'sbp': 95,
  },
};

FormulaBlock _load(String file) {
  final yaml = File('$_dir/$file').readAsStringSync();
  return Topic.fromYamlString(yaml).blocks.whereType<FormulaBlock>().single;
}

void main() {
  group('calculator topics parse to valid FormulaBlocks', () {
    _files.forEach((file, sample) {
      group(file, () {
        late FormulaBlock b;
        setUpAll(() => b = _load(file));

        test('has a kind and a source', () {
          expect(b.kind, isNotEmpty);
          expect(b.source, isNotNull,
              reason: 'clinical formulas must cite provenance');
        });

        test('kind is wired into the registry and computes with a valid vector',
            () {
          final r = computeFormula(b.kind, sample);
          expect(r.isEmpty, isFalse,
              reason: 'kind "${b.kind}" produced no output — '
                  'unwired kind or wrong sample keys');
          expect(r.outputs.first.value, isNotEmpty);
        });

        test('inputs are well-formed (keys unique; selects have options)', () {
          expect(b.inputs, isNotEmpty);
          final keys = <String>{};
          for (final input in b.inputs) {
            expect(input.key, isNotEmpty);
            expect(keys.add(input.key), isTrue,
                reason: 'duplicate input key "${input.key}"');
            if (input.type == FormulaInputType.select) {
              expect(input.options, isNotEmpty,
                  reason: 'select "${input.key}" needs options');
              // a declared default must be one of the options
              if (input.defaultValue != null) {
                expect(
                  input.options.map((o) => o.value),
                  contains(input.defaultValue),
                  reason: 'default "${input.defaultValue}" not among options',
                );
              }
            }
          }
        });

        test('every sample key exists as a declared input', () {
          final declared = b.inputs.map((i) => i.key).toSet();
          for (final k in sample.keys) {
            expect(declared, contains(k),
                reason: 'sample key "$k" is not a declared input');
          }
        });
      });
    });

    test('all formula calculators are present', () {
      expect(_files, hasLength(25));
      for (final f in _files.keys) {
        expect(File('$_dir/$f').existsSync(), isTrue, reason: 'missing $f');
      }
    });
  });
}
