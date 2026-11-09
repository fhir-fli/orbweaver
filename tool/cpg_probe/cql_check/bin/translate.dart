import 'dart:convert';
import 'dart:io';
import 'package:cql/cql.dart';
import 'package:cql/src/internal.dart';

void main(List<String> args) {
  final base = args[0];
  final lm = LibraryManager(
    sourceProvider: FileSystemLibrarySourceProvider(basePath: base),
    parseLibrary: (String s, {LibraryManager? libraryManager}) =>
        libraryFromCql(s, libraryManager: libraryManager),
  );
  final src = File('$base/PaediatricConvulsions.cql').readAsStringSync();
  final lib = libraryFromCql(src, libraryManager: lm);
  final ann = lib.annotation ?? [];
  stdout.writeln('annotations: ${ann.length}');
  for (final a in ann) {
    stdout.writeln(jsonEncode(a is CqlToElmError ? a.toJson() : a.toString()));
  }
  final defs = lib.statements?.def ?? [];
  stdout.writeln('defines: ${defs.length}');
  for (final d in defs) {
    stdout.writeln('  ${d.name}');
  }
  File(
    '$base/../elm.json',
  ).writeAsStringSync(const JsonEncoder.withIndent(' ').convert(lib.toJson()));
}
