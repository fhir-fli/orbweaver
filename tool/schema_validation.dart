// File loading for the JSON Schemas, shared by `tool/validate_book.dart` (the
// author-facing validator) and `test/schema/schema_test.dart` (the guard that
// every bundled file validates). The validation itself is in
// `lib/data/schema_explain.dart`, which has no dart:io so the web playground
// can use it too.
import 'dart:io';

import 'package:json_schema/json_schema.dart';
import 'package:orbweaver/data/schema_explain.dart';

export 'package:orbweaver/data/schema_explain.dart';

/// The four schemas, loaded from `dir` (the repo's `schema/` folder).
class SchemaSet {
  SchemaSet._(this.topic, this.book, this.formulary, this.index);

  factory SchemaSet.load(Directory dir) {
    JsonSchema read(String name) =>
        schemaFromJson(File('${dir.path}/$name').readAsStringSync());
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
