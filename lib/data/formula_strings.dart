// The calculator wording, kept out of the math so it can be translated.
// Pure Dart (no Flutter imports), like formula_registry.dart.

import 'package:yaml/yaml.dart';

/// Keyed calculator text: `<kind>.<slug>` → template with `{name}` slots.
///
/// English (`assets/l10n/formulas.yaml`) is always loaded; a translation
/// (`assets/l10n/<lang>/formulas.yaml`) is laid over it, so a key the
/// translation lacks still shows in English rather than as a raw key.
class FormulaStrings {
  FormulaStrings(this._text);

  /// Builds from the English YAML and, optionally, one translation's YAML.
  factory FormulaStrings.fromYaml(String english, [String? translation]) {
    final text = <String, String>{..._parse(english)};
    if (translation != null) text.addAll(_parse(translation));
    return FormulaStrings(text);
  }

  static Map<String, String> _parse(String yaml) {
    final doc = loadYaml(yaml);
    if (doc is! YamlMap) return const {};
    return {for (final e in doc.entries) e.key as String: e.value as String};
  }

  final Map<String, String> _text;

  /// The strings the running app uses. Set at startup (and on a language
  /// change) by the app; set from the English file by
  /// `test/flutter_test_config.dart` for every test.
  static FormulaStrings? current;

  Iterable<String> get keys => _text.keys;

  /// The text for [key] with each `{name}` replaced from [args]. An unknown
  /// key is an authoring error in the registry, so it throws: the tests
  /// exercise every branch and catch it before release.
  String call(String key, [Map<String, String> args = const {}]) {
    final template = _text[key];
    if (template == null) {
      throw StateError(
        'formula text "$key" is not in assets/l10n/formulas.yaml',
      );
    }
    var s = template;
    args.forEach((name, value) => s = s.replaceAll('{$name}', value));
    return s;
  }
}

/// Lookup used throughout the registry.
String formulaText(String key, [Map<String, String> args = const {}]) {
  final strings = FormulaStrings.current;
  if (strings == null) {
    throw StateError('FormulaStrings.current was not loaded');
  }
  return strings(key, args);
}
