// Shared by `tool/validate_book.dart` (the author-facing validator) and
// `test/schema/schema_test.dart` (the guard that every bundled file validates).
//
// Validates parsed YAML against the JSON Schemas in `schema/`. json_schema's
// own report for a block that fails is only "allOf violated", because a block
// is dispatched to its type's sub-schema through `if`/`then`; `explain` drills
// into the sub-schema the block actually belongs to so the message names the
// key, the enum value or the missing field.
import 'dart:convert';
import 'dart:io';

import 'package:json_schema/json_schema.dart';
import 'package:yaml/yaml.dart';

/// The four schemas, loaded from [dir] (the repo's `schema/` folder).
class SchemaSet {
  SchemaSet._(this.topic, this.book, this.formulary, this.index);

  factory SchemaSet.load(Directory dir) {
    JsonSchema read(String name) => JsonSchema.create(
      jsonDecode(File('${dir.path}/$name').readAsStringSync())
          as Map<String, dynamic>,
      schemaVersion: SchemaVersion.draft2020_12,
    );
    return SchemaSet._(
      read('topic.schema.json'),
      read('book.schema.json'),
      read('formulary.schema.json'),
      read('index.schema.json'),
    );
  }

  final JsonSchema topic;
  final JsonSchema book;
  final JsonSchema formulary;
  final JsonSchema index;
}

/// Parses YAML text into plain `Map`/`List`/scalars (json_schema validates
/// native Dart collections, not `YamlMap`).
Object? parseYamlPlain(String text) => jsonDecode(jsonEncode(loadYaml(text)));

/// Resolves a JSON pointer such as `/topic/blocks/3/markdown` in [doc].
Object? _at(Object? doc, String pointer) {
  var node = doc;
  for (final raw in pointer.split('/').skip(1)) {
    final seg = raw.replaceAll('~1', '/').replaceAll('~0', '~');
    if (node is Map) {
      node = node[seg];
    } else if (node is List) {
      final i = int.tryParse(seg);
      if (i == null || i < 0 || i >= node.length) return null;
      node = node[i];
    } else {
      return null;
    }
  }
  return node;
}

const _blockTypes = {
  'prose',
  'band_callout',
  'flowchart',
  'table',
  'drug_card',
  'procedure_card',
  'image',
  'row',
  'column',
  'arrows',
  'merge_arrows',
  'conversion',
  'formula',
  'score',
};
const _variants = {
  'severity',
  'cascade',
  'linear',
  'differential',
  'algorithm',
  'cycle',
};

/// Validates [doc] against [schema] and returns one line per problem, each
/// `"<json pointer>: <message>"`. Empty means valid.
List<String> explain(JsonSchema schema, Object? doc) {
  final out = <String>[];
  _explainInto(schema, schema, doc, '', out, 0);
  return out;
}

void _explainInto(
  JsonSchema root,
  JsonSchema schema,
  Object? doc,
  String prefix,
  List<String> out,
  int depth,
) {
  final result = schema.validate(doc);
  if (result.isValid) return;
  final seen = <String>{};
  for (final e in result.errors) {
    final path = e.instancePath;
    final msg = e.message;
    final combinator = _combinator.hasMatch(msg);
    if (combinator && depth < 40) {
      final node = _at(doc, path);
      final sub = _dispatch(root, node);
      if (sub != null) {
        final before = out.length;
        _explainInto(root, sub, node, '$prefix$path', out, depth + 1);
        if (out.length > before) continue;
      }
      if (node is Map &&
          node.containsKey('pages') &&
          node.containsKey('blocks')) {
        out.add(
          '$prefix$path: a topic has either `pages` or `blocks`, not both',
        );
        continue;
      }
      if (node is Map &&
          node.containsKey('pages') &&
          node.containsKey('page_number')) {
        out.add(
          '$prefix$path: `page_number` belongs on each page when `pages` is used',
        );
        continue;
      }
    }
    final line = '$prefix$path: $msg';
    if (seen.add(line)) out.add(line);
  }
}

/// json_schema reports a failed `allOf`/`oneOf`/`anyOf` as e.g.
/// `#/$defs/block: allOf violated {…}`, `#/properties/topic/oneOf: violated
/// No element` or `#/$defs/node/then: then violated (…)`; either way the
/// useful error is one level down.
final _combinator = RegExp(r'\b(allOf|oneOf|anyOf|then|else)\b.*violated');

/// The sub-schema a block, flowchart, or book node is dispatched to, or null.
JsonSchema? _dispatch(JsonSchema root, Object? node) {
  if (node is! Map) return null;
  final defs = root.schemaMap?[r'$defs'];
  if (defs is Map && defs.containsKey('group_chapter')) {
    // book.yaml contents node: a leaf has no title; a titled node is a
    // collection when `view: collection`, otherwise a chapter.
    final name = !node.containsKey('title')
        ? 'leaf'
        : node['view'] == 'collection'
        ? 'group_collection'
        : 'group_chapter';
    return root.resolvePath(Uri.parse('#/\$defs/$name'));
  }
  final type = node['type'];
  if (type is! String || !_blockTypes.contains(type)) return null;
  if (type == 'flowchart') {
    final variant = node['variant'] ?? 'severity';
    if (variant is! String || !_variants.contains(variant)) return null;
    return root.resolvePath(Uri.parse('#/\$defs/flowchart_$variant'));
  }
  return root.resolvePath(Uri.parse('#/\$defs/$type'));
}
