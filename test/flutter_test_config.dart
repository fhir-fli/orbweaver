import 'dart:async';
import 'dart:io';

import 'package:orbweaver/data/formula_strings.dart';

/// Runs before every test file: the calculator registry reads its wording
/// from the English strings file, as the app does at startup.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  FormulaStrings.current = FormulaStrings.fromYaml(
    File('assets/l10n/formulas.yaml').readAsStringSync(),
  );
  await testMain();
}
