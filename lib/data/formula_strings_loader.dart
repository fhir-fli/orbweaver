import 'package:flutter/services.dart' show rootBundle;
import 'package:orbweaver/data/formula_strings.dart';
import 'package:orbweaver/data/localized_asset.dart';

const _kEnglish = 'assets/l10n/formulas.yaml';

/// Loads the calculator wording for [language] into [FormulaStrings.current]:
/// English first, the translation (when the bundle has one) on top.
Future<void> loadFormulaStrings(String language) async {
  final english = await rootBundle.loadString(_kEnglish);
  final loc = await AssetLocalizer.load(language);
  final path = loc.path(_kEnglish);
  final translation = path == _kEnglish
      ? null
      : await rootBundle.loadString(path);
  FormulaStrings.current = FormulaStrings.fromYaml(english, translation);
}
