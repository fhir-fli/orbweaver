// Checks one translated YAML against its English source, the same way the
// test suite checks bundled translations (structure + safety content; the
// sha256 stamp is reported but not required, for drafts not yet stamped).
//
//   dart run tool/l10n/check_pair.dart <english.yaml> <translated.yaml> [...]
//
// Takes one or more pairs. For each pair prints `== <translated>`, the
// stamp, one line per problem and `problems: N`; exits 1 if any pair has
// a problem.

import 'dart:io';

import 'package:yaml/yaml.dart';

import 'translation_check.dart';

void main(List<String> args) {
  if (args.isEmpty || args.length.isOdd) {
    stderr.writeln(
      'usage: check_pair.dart <english.yaml> <translated.yaml> [...]',
    );
    exit(2);
  }
  var failed = false;
  for (var i = 0; i < args.length; i += 2) {
    if (args.length > 2) stdout.writeln('== ${args[i + 1]}');
    if (!_checkPair(File(args[i]), File(args[i + 1]))) failed = true;
  }
  exit(failed ? 1 : 0);
}

bool _checkPair(File en, File tr) {
  final problems = <String>[];
  Object? parsed;
  try {
    parsed = loadYaml(tr.readAsStringSync());
  } on YamlException catch (e) {
    stdout
      ..writeln('${tr.path}: not valid YAML: ${e.message}')
      ..writeln('problems: 1');
    return false;
  }
  compareTranslation(
    loadYaml(en.readAsStringSync()),
    parsed,
    tr.path,
    null,
    problems,
  );
  final first = tr.readAsLinesSync().firstOrNull ?? '';
  final m = sourceLine.firstMatch(first);
  stdout.writeln(
    m == null
        ? 'stamp: none'
        : 'stamp: ${m.group(1) == sha256Of(en) ? 'current' : 'STALE'}',
  );
  for (final p in problems) {
    stdout.writeln(p);
  }
  stdout.writeln('problems: ${problems.length}');
  return problems.isEmpty;
}
