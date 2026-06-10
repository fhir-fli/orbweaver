import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:orbweaver/models/book.dart';
import 'package:yaml/yaml.dart';

/// The library is data, not code. Each book is a self-contained **bundle
/// folder** under `assets/books/<id>/`:
///
///   assets/books/<id>/book.yaml   metadata + ordered topic paths
///   assets/books/<id>/cover.*     shelf cover
///   assets/books/<id>/topics/     one self-contained topic YAML each
///   assets/books/<id>/images/     bitmaps the topics reference
///
/// `assets/books/index.yaml` lists the book ids in shelf order. Paths in
/// `book.yaml` (cover, topic files) are relative to the bundle folder, so
/// a bundle is portable — zip it to share. Orbweaver is a renderer: it
/// reads what to show from these files and hardcodes nothing.
///
/// The **topic** is the source of truth for its own row: the loader reads
/// each topic's `title` / `list_subtitle` / `tags` frontmatter — the book
/// manifest only orders and references them.
Future<List<Book>> loadLibrary() async {
  final indexRaw = await rootBundle.loadString('assets/books/index.yaml');
  final index = loadYaml(indexRaw) as YamlMap;
  final ids = (index['books'] as YamlList).map((e) => e as String);

  final books = <Book>[];
  for (final id in ids) {
    books.add(await _loadBook(id));
  }
  return books;
}

Future<Book> _loadBook(String id) async {
  final dir = 'assets/books/$id';
  final raw = await rootBundle.loadString('$dir/book.yaml');
  final b = (loadYaml(raw) as YamlMap)['book'] as YamlMap;

  final cover = (b['cover'] as String?) ?? '';
  final topicPaths = [
    for (final p in b['topics'] as YamlList? ?? const []) p as String,
  ];

  // Read each topic's frontmatter in parallel for its row metadata.
  final topics = await Future.wait(
    topicPaths.map((rel) => _loadTopicRow('$dir/$rel')),
  );

  return Book(
    id: b['id'] as String,
    title: b['title'] as String,
    subtitle: (b['subtitle'] as String?) ?? '',
    coverAsset: cover.isEmpty ? '' : '$dir/$cover',
    spineColor: _color(b['spine_color'] as String),
    topics: topics,
  );
}

/// Builds a [BookTopic] row from a topic file's own frontmatter — the
/// topic is the single source of truth for its title/subtitle/tags.
Future<BookTopic> _loadTopicRow(String assetPath) async {
  final raw = await rootBundle.loadString(assetPath);
  final t = (loadYaml(raw) as YamlMap)['topic'] as YamlMap;
  final stem = assetPath.split('/').last.replaceAll('.yaml', '');
  return BookTopic(
    id: stem,
    title: t['title'] as String,
    subtitle: (t['list_subtitle'] as String?) ?? '',
    asset: assetPath,
    tags: [for (final tag in t['tags'] as YamlList? ?? const []) tag as String],
  );
}

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
