// The JSON Schemas in `schema/` promise: if a bundle validates, the app
// parses and renders it. These tests hold the schemas to that promise from
// both sides.
//
//   1. Every YAML file bundled under assets/books/ validates.
//   2. Every key the parsers read (topic.dart, library.dart, formulary.dart)
//      is a property somewhere in the schemas, and every schema property is a
//      key a parser reads. A field added to one side without the other fails.
//   3. The formula `kind` enum equals the registry's switch.
//   4. Known-bad documents are rejected, and the explanation names the fault.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:json_schema/json_schema.dart';

import '../../tool/schema_validation.dart';

void main() {
  final schemas = SchemaSet.load(Directory('schema'));

  List<File> yamlFiles(String glob) {
    final out = <File>[];
    for (final f in Directory('assets/books').listSync(recursive: true)) {
      if (f is File && f.path.endsWith('.yaml')) out.add(f);
    }
    out.sort((a, b) => a.path.compareTo(b.path));
    return out.where((f) => RegExp(glob).hasMatch(f.path)).toList();
  }

  test('every bundled topic validates against topic.schema.json', () {
    final files = yamlFiles(r'/topics/[^/]+\.yaml$');
    expect(files.length, greaterThan(400), reason: 'topic files found');
    final failures = <String>[];
    for (final f in files) {
      final problems = explain(
        schemas.topic,
        parseYamlPlain(f.readAsStringSync()),
      );
      for (final p in problems) {
        failures.add('${f.path} $p');
      }
    }
    expect(failures, isEmpty, reason: failures.join('\n'));
  });

  test('every book.yaml, formulary.yaml and index.yaml validates', () {
    final failures = <String>[];
    void check(String glob, JsonSchema schema) {
      final files = yamlFiles(glob);
      expect(files, isNotEmpty, reason: glob);
      for (final f in files) {
        for (final p in explain(schema, parseYamlPlain(f.readAsStringSync()))) {
          failures.add('${f.path} $p');
        }
      }
    }

    check(r'/book\.yaml$', schemas.book);
    check(r'/formulary\.yaml$', schemas.formulary);
    check(r'assets/books/index\.yaml$', schemas.index);
    expect(failures, isEmpty, reason: failures.join('\n'));
  });

  test('parser keys and schema properties are the same set', () {
    // Every `x['key']` string index in the parsers. The three files are the
    // only places YAML is read.
    final parserKeys = <String>{};
    for (final path in [
      'lib/models/topic.dart',
      'lib/data/library.dart',
      'lib/models/formulary.dart',
    ]) {
      final src = File(path).readAsStringSync();
      for (final m in RegExp(
        r"\[\s*'([a-z_][a-z0-9_]*)'\s*\]",
      ).allMatches(src)) {
        parserKeys.add(m.group(1)!);
      }
    }
    expect(parserKeys.length, greaterThan(150));

    final schemaKeys = <String>{};
    void collect(Object? node) {
      if (node is Map) {
        final props = node['properties'];
        if (props is Map) schemaKeys.addAll(props.keys.cast<String>());
        node.values.forEach(collect);
      } else if (node is List) {
        node.forEach(collect);
      }
    }

    for (final s in [
      schemas.topic,
      schemas.book,
      schemas.formulary,
      schemas.index,
    ]) {
      collect(s.schemaMap);
    }

    // Keys a schema allows that no parser reads: each needs a reason.
    const metadataOnly = {
      // formulary.yaml: provenance comment kept with the data, not rendered.
      'source',
    };

    final unread = schemaKeys.difference(parserKeys).difference(metadataOnly);
    expect(
      unread,
      isEmpty,
      reason: 'schema allows keys no parser reads (renderer would drop them)',
    );
    final unschemad = parserKeys.difference(schemaKeys);
    expect(
      unschemad,
      isEmpty,
      reason: 'parser reads keys the schema does not allow',
    );
  });

  test('formula kind enum equals the registry switch', () {
    final src = File('lib/data/formula_registry.dart').readAsStringSync();
    final start = src.indexOf('FormulaResult computeFormula(');
    final end = src.indexOf('_ => const FormulaResult.empty()', start);
    expect(start, greaterThan(0));
    expect(end, greaterThan(start));
    final kinds = RegExp(
      r"'([a-z0-9_]+)'\s*=>",
    ).allMatches(src.substring(start, end)).map((m) => m.group(1)!).toSet();
    final formula = schemas.topic.schemaMap![r'$defs']['formula'] as Map;
    final enumKinds =
        ((formula['properties'] as Map)['kind'] as Map)['enum'] as List;
    expect(enumKinds.toSet(), kinds);
    expect(kinds.length, greaterThan(20));
  });

  group('rejects', () {
    Map<String, dynamic> topic({
      Map<String, dynamic>? extra,
      List<Object?>? blocks,
    }) => {
      'topic': {
        'id': 't',
        'title': 'T',
        'blocks':
            blocks ??
            [
              {'type': 'prose', 'markdown': 'hello'},
            ],
        ...?extra,
      },
    };

    test('the minimal topic is valid', () {
      expect(explain(schemas.topic, topic()), isEmpty);
    });

    void rejects(String name, Object? doc, String mentions) {
      test(name, () {
        final problems = explain(schemas.topic, doc);
        expect(problems, isNotEmpty);
        expect(problems.join('\n'), contains(mentions));
      });
    }

    rejects(
      'a misspelt key on a block',
      topic(
        blocks: [
          {'type': 'prose', 'markdown': 'x', 'markdwn': 'y'},
        ],
      ),
      'markdwn',
    );
    rejects(
      'an unknown block type',
      topic(
        blocks: [
          {'type': 'proze', 'markdown': 'x'},
        ],
      ),
      'proze',
    );
    rejects(
      'a block missing its required field',
      topic(
        blocks: [
          {'type': 'image', 'caption': 'no path'},
        ],
      ),
      'path',
    );
    rejects(
      'an enum value the parser would silently default',
      topic(extra: {'category': 'critical'}),
      'critical',
    );
    rejects(
      'a flowchart with an unknown variant',
      topic(
        blocks: [
          {'type': 'flowchart', 'variant': 'sqare', 'branches': []},
        ],
      ),
      'sqare',
    );
    rejects(
      'a severity flowchart key on a cascade flowchart',
      topic(
        blocks: [
          {
            'type': 'flowchart',
            'variant': 'cascade',
            'entry': {'text': 'e'},
            'root': {'decision': 'd?'},
            'branches': [],
          },
        ],
      ),
      'branches',
    );
    rejects(
      'both pages and blocks',
      topic(
        extra: {
          'pages': [
            {
              'blocks': [
                {'type': 'prose', 'markdown': 'x'},
              ],
            },
          ],
        },
      ),
      'pages',
    );
    rejects('an unknown topic key', topic(extra: {'titel': 'x'}), 'titel');
    rejects(
      'a bad colour',
      topic(
        extra: {
          'palette': {'accent': 'red'},
        },
      ),
      'accent',
    );
    rejects(
      'a table cell of the wrong shape',
      topic(
        blocks: [
          {
            'type': 'table',
            'rows': [
              {
                'cells': [
                  {'txt': 'x'},
                ],
              },
            ],
          },
        ],
      ),
      'cells',
    );

    test('book: a leaf with a stray key, a collection without a formulary', () {
      Map<String, dynamic> book(List<Object?> contents) => {
        'book': {
          'id': 'b',
          'title': 'B',
          'spine_color': '#112233',
          'contents': contents,
        },
      };
      expect(
        explain(
          schemas.book,
          book([
            {'topic': 'topics/a.yaml'},
          ]),
        ),
        isEmpty,
      );
      expect(
        explain(
          schemas.book,
          book([
            {'topic': 'topics/a.yaml', 'title': null},
          ]),
        ),
        isNotEmpty,
      );
      expect(
        explain(
          schemas.book,
          book([
            {'topic': 'topics/a.yaml', 'palette': {}},
          ]),
        ),
        isNotEmpty,
      );
      expect(
        explain(
          schemas.book,
          book([
            {'title': 'Drugs', 'view': 'collection'},
          ]),
        ).join(),
        contains('formulary'),
      );
      expect(
        explain(
          schemas.book,
          book([
            {'title': 'Ch 1'},
          ]),
        ).join(),
        contains('children'),
      );
    });

    test('formulary: a drug without a class; index: no books', () {
      expect(
        explain(schemas.formulary, {
          'formulary': {
            'id': 'f',
            'title': 'F',
            'bands': {'label': '', 'columns': <String>[]},
            'bands_art': {'label': '', 'columns': <String>[]},
            'facets': [
              {
                'key': 'alpha',
                'label': 'A–Z',
                'mode': 'alpha',
                'tap': 'detail',
              },
            ],
            'drugs': [
              {'id': 'x', 'name': 'X'},
            ],
          },
        }).join(),
        contains('class'),
      );
      expect(explain(schemas.index, {'books': <String>[]}), isNotEmpty);
      expect(
        explain(schemas.index, {
          'books': ['a'],
        }),
        isEmpty,
      );
    });
  });
}
