import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:orbweaver/models/book.dart';
import 'package:yaml/yaml.dart';

/// The library is data, not code: each book is a manifest under
/// `assets/books/<id>.yaml`, and `assets/books/index.yaml` lists the
/// book ids in shelf order. Orbweaver is a renderer — it reads what to
/// show from these files; nothing about the shelf is hardcoded.
///
/// A manifest is `{book: {id, title, subtitle, cover, spine_color,
/// topics: [{id, title, subtitle, asset, tags}]}}`. Each topic's `asset`
/// points at a self-contained topic YAML loaded on demand when opened.
Future<List<Book>> loadLibrary() async {
  final indexRaw = await rootBundle.loadString('assets/books/index.yaml');
  final index = loadYaml(indexRaw) as YamlMap;
  final ids = (index['books'] as YamlList).map((e) => e as String);

  final books = <Book>[];
  for (final id in ids) {
    final raw = await rootBundle.loadString('assets/books/$id.yaml');
    books.add(_bookFromYaml(loadYaml(raw) as YamlMap));
  }
  return books;
}

Book _bookFromYaml(YamlMap map) {
  final b = map['book'] as YamlMap;
  final rawTopics = b['topics'] as YamlList?;
  final topics = <BookTopic>[
    for (final t in rawTopics ?? const []) _topicFromYaml(t as YamlMap),
  ];
  return Book(
    id: b['id'] as String,
    title: b['title'] as String,
    subtitle: b['subtitle'] as String,
    coverAsset: b['cover'] as String? ?? '',
    spineColor: _color(b['spine_color'] as String),
    topics: topics,
  );
}

BookTopic _topicFromYaml(YamlMap t) => BookTopic(
      id: t['id'] as String,
      title: t['title'] as String,
      subtitle: t['subtitle'] as String? ?? '',
      asset: t['asset'] as String,
      tags: [for (final tag in t['tags'] as YamlList? ?? const []) tag as String],
    );

/// Parses a `"0xAARRGGBB"` (or `"#RRGGBB"`) spine color string.
Color _color(String s) {
  var hex = s.trim();
  if (hex.startsWith('0x')) hex = hex.substring(2);
  if (hex.startsWith('#')) hex = hex.substring(1);
  if (hex.length == 6) hex = 'FF$hex';
  return Color(int.parse(hex, radix: 16));
}

Book? findBook(List<Book> library, String id) {
  for (final b in library) {
    if (b.id == id) return b;
  }
  return null;
}

BookTopic? findTopic(Book book, String topicId) {
  for (final t in book.topics) {
    if (t.id == topicId) return t;
  }
  return null;
}
