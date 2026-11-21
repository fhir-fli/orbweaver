// Checks one translated YAML against its English source, the same way the
// test suite checks bundled translations (structure + safety content; the
// sha256 stamp is reported but not required, for drafts not yet stamped).
//
//   dart run tool/l10n/check_pair.dart <english.yaml> <translated.yaml>
//
// Prints one line per problem and exits 1 if there are any.

import 'dart:io';

import 'package:yaml/yaml.dart';

import 'translation_check.dart';

void main(List<String> args) {
  if (args.length != 2) {
    stderr.writeln('usage: check_pair.dart <english.yaml> <translated.yaml>');
    exit(2);
  }
  final en = File(args[0]);
  final tr = File(args[1]);
  final problems = <String>[];
  Object? parsed;
  try {
    parsed = loadYaml(tr.readAsStringSync());
  } on YamlException catch (e) {
    stdout.writeln('${tr.path}: not valid YAML: ${e.message}');
    exit(1);
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
  exit(problems.isEmpty ? 0 : 1);
}
