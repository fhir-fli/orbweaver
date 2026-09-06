// Validates an orbweaver book bundle (or the whole `assets/books` library)
// before it is rendered.
//
//   dart run tool/validate_book.dart assets/books            # every book
//   dart run tool/validate_book.dart assets/books/who_imci   # one bundle
//   dart run tool/validate_book.dart path/to/my_book         # a bundle anywhere
//
// Checks, in order, printing each finding as it is found:
//   1. book.yaml, every referenced topic file, formulary.yaml and index.yaml
//      validate against the JSON Schemas in `schema/` (`--schema-dir` to point
//      elsewhere). Unknown keys are errors: the renderer ignores them silently.
//   2. Every `topic:` path in book.yaml exists.
//   3. Topic ids are unique within the bundle.
//   4. Image paths (`image` block `path`, `drug_card`/`procedure_card` `image`)
//      exist; a missing one is a warning (the app draws a placeholder). A path
//      `assets/books/<id>/…` resolves inside the bundle folder.
//   5. Ids referenced inside a flowchart resolve: a convergence `loopback` to a
//      branch `id`, an algorithm `goto` to a box `id`, a cycle `loop_to` to a
//      node `id`.
//   6. `[text](topic:<id>)` links and `link_id`s that do not resolve to a topic
//      in this bundle are reported as warnings (they may target another book;
//      the app renders them inert).
//
// Exit code 1 if any error, 0 otherwise (warnings do not fail).
import 'dart:io';

import 'package:yaml/yaml.dart';

import 'schema_validation.dart';

int _errors = 0;
int _warnings = 0;

void _error(String file, String msg) {
  _errors++;
  stdout.writeln('ERROR  $file: $msg');
}

void _warn(String file, String msg) {
  _warnings++;
  stdout.writeln('WARN   $file: $msg');
}

void main(List<String> args) {
  var schemaDir = Directory('schema');
  final targets = <String>[];
  for (var i = 0; i < args.length; i++) {
    if (args[i] == '--schema-dir') {
      schemaDir = Directory(args[++i]);
    } else {
      targets.add(args[i]);
    }
  }
  if (targets.isEmpty) {
    stderr.writeln(
      'usage: dart run tool/validate_book.dart <bundle-dir | library-dir>',
    );
    exit(2);
  }
  if (!File('${schemaDir.path}/topic.schema.json').existsSync()) {
    stderr.writeln('no schemas in ${schemaDir.path} (use --schema-dir)');
    exit(2);
  }
  final schemas = SchemaSet.load(schemaDir);

  for (final t in targets) {
    final dir = Directory(t);
    if (!dir.existsSync()) {
      _error(t, 'not a directory');
      continue;
    }
    if (File('${dir.path}/book.yaml').existsSync()) {
      _validateBundle(schemas, dir);
    } else if (File('${dir.path}/index.yaml').existsSync()) {
      _validateLibrary(schemas, dir);
    } else {
      _error(t, 'neither a bundle (book.yaml) nor a library (index.yaml)');
    }
  }
  stdout.writeln(
    '${_errors == 0 ? 'OK' : 'FAILED'}: $_errors error(s), $_warnings warning(s)',
  );
  exit(_errors == 0 ? 0 : 1);
}

void _validateLibrary(SchemaSet schemas, Directory dir) {
  final indexFile = File('${dir.path}/index.yaml');
  final index = _loadYaml(indexFile);
  if (index == null) return;
  _report(indexFile.path, explain(schemas.index, index));
  final ids = (index as Map)['books'];
  if (ids is! List) return;
  for (final id in ids) {
    final bundle = Directory('${dir.path}/$id');
    if (!File('${bundle.path}/book.yaml').existsSync()) {
      _error(indexFile.path, 'book "$id" has no ${bundle.path}/book.yaml');
      continue;
    }
    _validateBundle(schemas, bundle);
  }
}

void _validateBundle(SchemaSet schemas, Directory bundle) {
  stdout.writeln('== ${bundle.path}');
  final bookFile = File('${bundle.path}/book.yaml');
  final bookDoc = _loadYaml(bookFile);
  if (bookDoc == null) return;
  final bookProblems = explain(schemas.book, bookDoc);
  _report(bookFile.path, bookProblems);
  if (bookProblems.isNotEmpty) return;
  final book = (bookDoc as Map)['book'] as Map;
  final bookId = book['id'] as String;
  if (bookId != _basename(bundle.path)) {
    _warn(
      bookFile.path,
      'book id "$bookId" differs from folder name "${_basename(bundle.path)}"',
    );
  }
  final cover = book['cover'];
  if (cover is String && !File('${bundle.path}/$cover').existsSync()) {
    _error(bookFile.path, 'cover "$cover" not found');
  }

  final topicPaths = <String>[];
  final formularyPaths = <String>[];
  void walk(List<dynamic> nodes) {
    for (final n in nodes) {
      if (n is! Map) continue;
      if (n['topic'] is String) topicPaths.add(n['topic'] as String);
      if (n['formulary'] is String)
        formularyPaths.add(n['formulary'] as String);
      if (n['children'] is List) walk(n['children'] as List);
    }
  }

  walk(book['contents'] as List);

  final ids = <String, String>{}; // id → file
  final linkTargets = <String, List<String>>{}; // file → ids linked
  for (final rel in topicPaths) {
    final f = File('${bundle.path}/$rel');
    if (!f.existsSync()) {
      _error(bookFile.path, 'topic "$rel" not found');
      continue;
    }
    final doc = _loadYaml(f);
    if (doc == null) continue;
    final problems = explain(schemas.topic, doc);
    _report(f.path, problems);
    if (problems.isNotEmpty) continue;
    final topic = (doc as Map)['topic'] as Map;
    final id = topic['id'] as String;
    if (ids.containsKey(id)) {
      _error(f.path, 'duplicate topic id "$id" (also ${ids[id]})');
    }
    ids[id] = f.path;
    _checkTopicRefs(bundle, f.path, topic, linkTargets);
  }

  for (final rel in formularyPaths) {
    final f = File('${bundle.path}/$rel');
    if (!f.existsSync()) {
      _error(bookFile.path, 'formulary "$rel" not found');
      continue;
    }
    final doc = _loadYaml(f);
    if (doc == null) continue;
    final problems = explain(schemas.formulary, doc);
    _report(f.path, problems);
    if (problems.isNotEmpty) continue;
    final formulary = (doc as Map)['formulary'] as Map;
    final classes = {
      for (final c in (formulary['classes'] as List? ?? const []))
        (c as Map)['key'],
    };
    final indications = {
      for (final c in (formulary['indications'] as List? ?? const []))
        (c as Map)['key'],
    };
    for (final d in formulary['drugs'] as List) {
      final drug = d as Map;
      final id = drug['id'] as String;
      if (ids.containsKey(id)) {
        _error(f.path, 'drug id "$id" duplicates a topic id (${ids[id]})');
      }
      ids[id] = f.path;
      if (classes.isNotEmpty && !classes.contains(drug['class'])) {
        _error(
          f.path,
          'drug "$id": class "${drug['class']}" is not in `classes`',
        );
      }
      for (final ind in (drug['indications'] as List? ?? const [])) {
        if (indications.isNotEmpty && !indications.contains(ind)) {
          _error(
            f.path,
            'drug "$id": indication "$ind" is not in `indications`',
          );
        }
      }
    }
  }

  // Cross-topic links: unresolved within this bundle is a warning, because
  // the app allows links across books and renders unresolved ones inert.
  linkTargets.forEach((file, targets) {
    for (final t in targets) {
      if (!ids.containsKey(t))
        _warn(file, 'link target "topic:$t" is not in this bundle');
    }
  });
  stdout.writeln('   ${topicPaths.length} topics, ${ids.length} ids');
}

final _topicLink = RegExp(r'\(topic:([^)#\s]+)(?:#[^)]*)?\)');

void _checkTopicRefs(
  Directory bundle,
  String file,
  Map<dynamic, dynamic> topic,
  Map<String, List<String>> linkTargets,
) {
  final links = linkTargets.putIfAbsent(file, () => []);

  void image(String? path, String what) {
    if (path == null) return;
    final prefix = 'assets/books/${_basename(bundle.path)}/';
    final resolved = path.startsWith(prefix)
        ? '${bundle.path}/${path.substring(prefix.length)}'
        : path;
    if (!File(resolved).existsSync()) {
      // The app draws a grey placeholder for a missing asset, so the page
      // still renders; WVEMS carries five such slots on purpose (952b439).
      _warn(file, '$what "$path" not found (renders as a placeholder)');
    }
  }

  void strings(Object? node) {
    if (node is String) {
      for (final m in _topicLink.allMatches(node)) {
        links.add(m.group(1)!);
      }
    } else if (node is Map) {
      if (node['link_id'] is String) {
        links.add(node['link_id'] as String);
      }
      node.values.forEach(strings);
    } else if (node is List) {
      node.forEach(strings);
    }
  }

  void blocks(List<dynamic> list) {
    for (final b in list) {
      if (b is! Map) continue;
      switch (b['type']) {
        case 'image':
          image(b['path'] as String?, 'image');
        case 'drug_card' || 'procedure_card':
          image(b['image'] as String?, 'image');
        case 'row' || 'column':
          blocks(b['blocks'] as List? ?? const []);
        case 'flowchart':
          _checkFlowchartIds(file, b);
      }
    }
  }

  if (topic['pages'] is List) {
    for (final p in topic['pages'] as List) {
      blocks((p as Map)['blocks'] as List? ?? const []);
    }
  } else {
    blocks(topic['blocks'] as List? ?? const []);
  }
  strings(topic);
}

void _checkFlowchartIds(String file, Map<dynamic, dynamic> fc) {
  final variant = fc['variant'] ?? 'severity';
  switch (variant) {
    case 'severity':
      final branchIds = {
        for (final b in fc['branches'] as List? ?? const []) (b as Map)['id'],
      };
      for (final key in ['convergence', 'post_convergence']) {
        final c = fc[key];
        if (c is! Map) continue;
        for (final e in c['exits'] as List? ?? const []) {
          final lb = (e as Map)['loopback'];
          if (lb != null && !branchIds.contains(lb)) {
            _error(
              file,
              'flowchart $key exit loopback "$lb" names no branch id',
            );
          }
        }
      }
    case 'algorithm':
      final boxIds = {
        for (final b in fc['boxes'] as List? ?? const []) (b as Map)['id'],
      };
      for (final s in fc['stages'] as List? ?? const []) {
        for (final o in (s as Map)['outcomes'] as List? ?? const []) {
          final g = (o as Map)['goto'];
          if (g != null && !boxIds.contains(g)) {
            _error(file, 'algorithm goto "$g" names no box id');
          }
        }
      }
    case 'cycle':
      final nodeIds = {
        for (final n in fc['nodes'] as List? ?? const []) (n as Map)['id'],
      };
      for (final n in fc['nodes'] as List? ?? const []) {
        for (final b in (n as Map)['branches'] as List? ?? const []) {
          final lt = (b as Map)['loop_to'];
          if (lt != null && !nodeIds.contains(lt)) {
            _error(file, 'cycle loop_to "$lt" names no node id');
          }
        }
      }
  }
}

Object? _loadYaml(File f) {
  try {
    return parseYamlPlain(f.readAsStringSync());
  } on YamlException catch (e) {
    _error(f.path, 'YAML parse error: ${e.message}');
    return null;
  }
}

void _report(String file, List<String> problems) {
  for (final p in problems) {
    _error(file, p);
  }
}

String _basename(String path) {
  final parts = path.replaceAll(RegExp(r'/+$'), '').split('/');
  return parts.last;
}
