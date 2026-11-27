// GUARD — a translated file must say the same clinical thing as its English
// source, and must have been made from the CURRENT English.
//
// Every translated book file sits in a `<lang>/` folder beside its English
// file (lib/data/localized_asset.dart). For each one this test checks:
//
//   1. Fresh: line 1 is `# translated-from-sha256: <hash>` and the hash is
//      the English file's. A later edit to the English (a dose correction,
//      say) fails this test until the translation is updated and re-stamped
//      with `python3 tool/l10n/source_hash.py <english file>`.
//   2. Same shape: the same keys, the same list lengths, the same non-text
//      values. Ids, links, colours, kinds and every other non-prose string
//      must be IDENTICAL; only the keys in [kTranslatableKeys] may differ.
//   3. Same safety content, in every translatable string: the same numbers
//      (decimal point kept), the same comparison signs (< > ≤ ≥), the same
//      dose units, the same link targets, the same bold runs and the same
//      line count.
//
// The calculator wording (assets/l10n/<lang>/formulas.yaml) gets checks 1
// and 3 key by key, and every key must exist in the English file.

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:orbweaver/data/localized_asset.dart';
import 'package:orbweaver/l10n/l10n.dart' show kSupportedLanguages;
import 'package:yaml/yaml.dart';

import '../../tool/l10n/translation_check.dart';

/// Every translated YAML under assets/, with its English source.
List<(File translated, File english, String language)> _translatedFiles() {
  final out = <(File, File, String)>[];
  for (final e in Directory('assets').listSync(recursive: true)) {
    if (e is! File || !e.path.endsWith('.yaml')) continue;
    final parts = e.path.split('/');
    final folder = parts[parts.length - 2];
    if (folder == 'en' || !kSupportedLanguages.contains(folder)) continue;
    final english = [
      ...parts.sublist(0, parts.length - 2),
      parts.last,
    ].join('/');
    out.add((e, File(english), folder));
  }
  return out;
}

void main() {
  test('translatedPath puts the copy in a language folder beside the file', () {
    expect(
      translatedPath('assets/books/who_imci/topics/who_1_1.yaml', 'es'),
      'assets/books/who_imci/topics/es/who_1_1.yaml',
    );
    expect(
      translatedPath('assets/books/who_imci/book.yaml', 'es'),
      'assets/books/who_imci/es/book.yaml',
    );
  });

  test('the file finder sees a translation placed where the app looks', () {
    // Proves the instrument: a file at translatedPath() is found, paired with
    // the right English file, and an English file is never taken for one.
    final dir = Directory('assets/books/calculators/topics/es')
      ..createSync(recursive: true);
    final probe = File('${dir.path}/zz_probe.yaml')
      ..writeAsStringSync('x: 1\n');
    try {
      final found = _translatedFiles().where((t) => t.$1.path == probe.path);
      expect(found, hasLength(1));
      expect(
        found.single.$2.path,
        'assets/books/calculators/topics/zz_probe.yaml',
      );
      expect(found.single.$3, 'es');
      expect(
        _translatedFiles().where((t) => !t.$1.path.contains('/es/')),
        isEmpty,
      );
    } finally {
      probe.deleteSync();
      if (dir.listSync().isEmpty) dir.deleteSync();
    }
  });

  test('every translated file is bundled with the app', () {
    // Flutter asset folders are not recursive: a <lang>/ folder missing from
    // pubspec.yaml ships nothing, and the app silently shows English. Seen
    // once on the desktop build (the Spanish calculator wording was absent).
    final pubspec =
        loadYaml(File('pubspec.yaml').readAsStringSync()) as YamlMap;
    final declared = {
      for (final a in (pubspec['flutter'] as YamlMap)['assets'] as YamlList)
        a as String,
    };
    final missing = [
      for (final (tr, _, _) in _translatedFiles())
        if (!declared.contains('${tr.parent.path}/')) tr.parent.path,
    ];
    expect(
      missing.toSet(),
      isEmpty,
      reason: 'add these folders to pubspec.yaml',
    );
  });

  test('the comparison catches a changed dose, sign, link and id', () {
    // Seen failing on purpose, so a pass below means something.
    List<String> diff(String en, String tr) {
      final p = <String>[];
      compareTranslation(loadYaml(en), loadYaml(tr), r'$', null, p);
      return p;
    }

    const en = '''
topic:
  id: "pb-x"
  blocks:
    - type: "prose"
      markdown: "Give **0.1 mg/kg** IV if SBP < 90. See [here](topic:pb-y)."
''';
    expect(
      diff(en, en.replaceFirst('Give', 'Administre').replaceFirst('if', 'si')),
      isEmpty,
    );
    expect(diff(en, en.replaceFirst('0.1', '0,1')), isNotEmpty);
    expect(diff(en, en.replaceFirst('0.1', '1')), isNotEmpty);
    expect(diff(en, en.replaceFirst('< 90', '> 90')), isNotEmpty);
    expect(diff(en, en.replaceFirst('mg/kg', 'mcg/kg')), isNotEmpty);
    expect(diff(en, en.replaceFirst('topic:pb-y', 'topic:pb-z')), isNotEmpty);
    expect(diff(en, en.replaceFirst('"pb-x"', '"pb-x-es"')), isNotEmpty);
    expect(diff(en, en.replaceFirst('"prose"', '"texto"')), isNotEmpty);
  });

  test('wrapping and prose letters are not differences; layout is', () {
    final p = <String>[];
    void cmp(String en, String tr) {
      p.clear();
      compareTranslation({'markdown': en}, {'markdown': tr}, r'$', null, p);
    }

    // A longer translation that wraps onto more lines: same layout.
    cmp('- Give 5 mg\n  slowly', '- Administre 5 mg\n  lentamente\n  durante');
    expect(p, isEmpty);
    // "e.g." and "GCS" hold no unit.
    cmp(
      'Toxins (e.g. amitraz), GCS < 12',
      'Toxinas (p. ej., amitraz), ECG < 12',
    );
    expect(p, isEmpty);
    // "1-ml" and "1 ml" are the same unit.
    cmp('a 1-ml syringe', 'una jeringa de 1 ml');
    expect(p, isEmpty);
    // A dropped bullet is a difference.
    cmp('- one\n- two', '- uno\n  dos');
    expect(p, isNotEmpty);
  });

  test('every translated book file matches its current English source', () {
    final problems = <String>[];
    for (final (tr, en, lang) in _translatedFiles()) {
      if (tr.path.endsWith('/formulas.yaml')) continue;
      if (!en.existsSync()) {
        problems.add('${tr.path}: no English file at ${en.path}');
        continue;
      }
      final first = const LineSplitter().convert(tr.readAsStringSync()).first;
      final m = sourceLine.firstMatch(first);
      if (m == null) {
        problems.add(
          '${tr.path}: line 1 must be "# translated-from-sha256: <hash>"',
        );
      } else if (m.group(1) != sha256Of(en)) {
        problems.add(
          '${tr.path} ($lang): the English changed since it was translated; '
          'update the translation, then re-stamp it',
        );
      }
      compareTranslation(
        loadYaml(en.readAsStringSync()),
        loadYaml(tr.readAsStringSync()),
        tr.path,
        null,
        problems,
      );
    }
    expect(problems, isEmpty, reason: problems.join('\n'));
  });

  test('the registry uses exactly the keys in assets/l10n/formulas.yaml', () {
    final source = File('lib/data/formula_registry.dart').readAsStringSync();
    final used = {
      for (final m in RegExp(r"_t\(\s*'([^']+)'").allMatches(source))
        m.group(1)!,
    };
    final english = (loadYaml(
      File('assets/l10n/formulas.yaml').readAsStringSync(),
    ) as YamlMap).keys.cast<String>().toSet();
    expect(used, isNotEmpty);
    expect(used.difference(english), isEmpty, reason: 'used but not defined');
    expect(english.difference(used), isEmpty, reason: 'defined but never used');
  });

  test('every calculator translation matches the English, key by key', () {
    final english = loadYaml(
      File('assets/l10n/formulas.yaml').readAsStringSync(),
    ) as YamlMap;
    final problems = <String>[];
    for (final (tr, en, _) in _translatedFiles()) {
      if (!tr.path.endsWith('/formulas.yaml')) continue;
      final text = tr.readAsStringSync();
      final m = sourceLine.firstMatch(
        const LineSplitter().convert(text).first,
      );
      if (m == null || m.group(1) != sha256Of(en)) {
        problems.add('${tr.path}: missing or stale translated-from-sha256');
      }
      final doc = loadYaml(text) as YamlMap;
      for (final k in doc.keys) {
        if (!english.containsKey(k)) {
          problems.add('${tr.path}: "$k" is not an English key');
          continue;
        }
        final en = english[k] as String;
        final t = doc[k] as String;
        final slots = RegExp(r'\{[A-Za-z]+\}');
        if (allMatches(slots, en).join() != allMatches(slots, t).join()) {
          problems.add('${tr.path}: "$k" slots differ');
        }
        final a = safetyOf(en);
        final b = safetyOf(t);
        for (final part in a.keys) {
          if ('${a[part]}' != '${b[part]}') {
            problems.add('${tr.path}: "$k" $part differ «$en» vs «$t»');
          }
        }
      }
      for (final k in english.keys) {
        if (!doc.containsKey(k)) {
          problems.add('${tr.path}: "$k" not translated');
        }
      }
    }
    expect(problems, isEmpty, reason: problems.join('\n'));
  });

  test('every interface string is translated, with the same placeholders', () {
    Map<String, dynamic> arb(String lang) =>
        jsonDecode(File('lib/l10n/app_$lang.arb').readAsStringSync())
            as Map<String, dynamic>;
    final en = arb('en');
    final keys = en.keys.where((k) => !k.startsWith('@')).toSet();
    final slots = RegExp(r'\{([A-Za-z]+)[,}]');
    for (final lang in kSupportedLanguages.where((l) => l != 'en')) {
      final tr = arb(lang);
      final trKeys = tr.keys.where((k) => !k.startsWith('@')).toSet();
      expect(trKeys, keys, reason: 'app_$lang.arb keys');
      for (final k in keys) {
        expect(
          allMatches(slots, tr[k] as String, 1).toSet(),
          allMatches(slots, en[k] as String, 1).toSet(),
          reason: 'app_$lang.arb "$k" placeholders',
        );
      }
    }
  });
}
