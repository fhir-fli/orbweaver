import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:orbweaver/data/search_normalizer.dart';
import 'package:orbweaver/models/book.dart';
import 'package:orbweaver/models/formulary.dart';
import 'package:orbweaver/screens/topic_frame.dart' show TopicPager;
import 'package:orbweaver/theme/palette.dart';
import 'package:yaml/yaml.dart';

/// The library is data, not code. Each book is a self-contained **bundle
/// folder** under `assets/books/<id>/`:
///
/// ```text
/// assets/books/<id>/book.yaml   metadata + contents tree (topic+map)
/// assets/books/<id>/cover.*     shelf cover
/// assets/books/<id>/topics/     one self-contained topic YAML each
/// assets/books/<id>/images/     bitmaps the topics reference
/// ```
///
/// `assets/books/index.yaml` lists the book ids in shelf order. Paths in
/// `book.yaml` (cover, topic files) are relative to the bundle folder, so
/// a bundle is portable — zip it to share. Orbweaver is a renderer: it
/// reads what to show from these files and hardcodes nothing.
///
/// `book.yaml` carries a `contents:` tree (the *map*) that references topic
/// files and arranges them into chapters/sections — the topic+map model
/// (DITA; MkDocs `nav:`; Antora/Sphinx toctree). Each entry is either:
///   - a leaf:  `{ topic: "topics/foo.yaml" }`
///   - a group: `{ title: "1. Triage", children: [ ... ], topic: <opt overview> }`
/// Groups nest arbitrarily; a group may carry its own `topic:` overview page.
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

/// Loads a single book by id — for a single-book build (e.g. the WHO-only web
/// app) that opens straight into one book with no shelf.
Future<Book> loadBook(String id) => _loadBook(id);

Future<Book> _loadBook(String id) async {
  final dir = 'assets/books/$id';
  final raw = await rootBundle.loadString('$dir/book.yaml');
  final b = (loadYaml(raw) as YamlMap)['book'] as YamlMap;

  final cover = (b['cover'] as String?) ?? '';
  final bookOverrides = parsePaletteOverrides(b['palette']);
  final bookFont = b['font_family'] as String?;
  final contents = await _parseNodes(
    b['contents'] as YamlList? ?? YamlList(),
    dir,
    [bookOverrides],
    const [],
    bookFont,
  );

  return Book(
    id: b['id'] as String,
    title: b['title'] as String,
    subtitle: (b['subtitle'] as String?) ?? '',
    coverAsset: cover.isEmpty ? '' : '$dir/$cover',
    spineColor: _color(b['spine_color'] as String),
    contents: contents,
    paletteOverrides: bookOverrides,
    fontFamily: bookFont,
    view: b['view'] as String?,
  );
}

/// Recursively parses a `contents:` list into a [BookNode] tree. An entry
/// with a `topic:` path is a [BookLeaf]; an entry with a `title:` is a
/// [BookGroup] (which may carry its own `topic:` overview and nested
/// `children:`). Topic rows are read from each file's own frontmatter.
Future<List<BookNode>> _parseNodes(
  YamlList raw,
  String dir,
  List<Map<String, Color>> layers,
  List<String> ancestors,
  String? fontFamily,
) async {
  final nodes = <BookNode>[];
  for (final entry in raw) {
    final map = entry as YamlMap;
    final title = map['title'] as String?;
    if (title == null) {
      // Leaf: a bare topic reference.
      final topic = await _loadTopicRow(
        '$dir/${map['topic'] as String}',
        layers,
        ancestors,
        fontFamily,
      );
      nodes.add(BookLeaf(topic));
    } else {
      // Group: a chapter/section, optionally with its own overview page.
      // Its `palette:` overrides extend the cascade for its subtree.
      final groupOverrides = parsePaletteOverrides(map['palette']);
      final groupFont = (map['font_family'] as String?) ?? fontFamily;
      final childLayers = [...layers, groupOverrides];
      final childAncestors = [...ancestors, title];
      final overviewPath = map['topic'] as String?;
      final overview = overviewPath == null
          ? null
          : await _loadTopicRow(
              '$dir/$overviewPath',
              childLayers,
              ancestors,
              groupFont,
            );

      // A `view: "collection"` group is a bespoke faceted screen (a
      // formulary) rather than a chapter. Its drugs are loaded from the
      // referenced dataset and surfaced as synthetic searchable leaves.
      final view = map['view'] as String?;
      Formulary? formulary;
      List<BookNode> children;
      if (view == 'collection') {
        final formPath = map['formulary'] as String;
        final raw = await rootBundle.loadString('$dir/$formPath');
        formulary = Formulary.fromYaml(loadYaml(raw) as YamlMap);
        children = _formularyLeaves(
          formulary,
          childLayers,
          childAncestors,
          groupFont,
        );
      } else {
        children = await _parseNodes(
          map['children'] as YamlList? ?? YamlList(),
          dir,
          childLayers,
          childAncestors,
          groupFont,
        );
      }
      nodes.add(
        BookGroup(
          title: title,
          overview: overview,
          children: children,
          paletteOverrides: groupOverrides,
          fontFamily: groupFont,
          view: view,
          formulary: formulary,
          appendix: map['appendix'] as bool? ?? false,
        ),
      );
    }
  }
  return nodes;
}

/// One synthetic [BookLeaf] per drug in a [Formulary], so every drug is
/// searched and counted like an ordinary topic. The leaf carries the [Drug]
/// as its payload; its `asset` is a `formulary:` sentinel (there is no file),
/// and opening it renders the drug detail directly. [ancestors] here already
/// includes the collection group's title (the breadcrumb).
List<BookNode> _formularyLeaves(
  Formulary formulary,
  List<Map<String, Color>> layers,
  List<String> ancestors,
  String? fontFamily,
) {
  final palette = resolvePalette(layers);
  final crumb = ancestors.join(' › ');
  return [
    for (final drug in formulary.drugs)
      BookLeaf(
        BookTopic(
          id: drug.id,
          title: drug.name,
          subtitle: drug.subtitle.isNotEmpty
              ? drug.subtitle
              : formulary.classLabel(drug.className),
          asset: 'formulary:${drug.id}',
          tags: drug.indications,
          palette: palette,
          fontFamily: fontFamily,
          searchText: SearchNormalizer.normalize(drug.searchBlob),
          titleText: SearchNormalizer.normalize(
            '${drug.name} ${drug.subtitle}',
          ),
          keywordsText: SearchNormalizer.normalize(
            [
              ...drug.indications.map(formulary.indicationLabel),
              formulary.classLabel(drug.className),
            ].join(' '),
          ),
          breadcrumb: crumb,
          drug: drug,
        ),
      ),
  ];
}

/// Builds a [BookTopic] row from a topic file's own frontmatter — the
/// topic is the single source of truth for its title/subtitle/tags.
///
/// [BookTopic.id] is the topic's own `id` (the logical id used by
/// cross-topic `link_id`s and by last-state routing) — NOT the filename.
/// Filenames are just storage; the logical id is what's stable.
Future<BookTopic> _loadTopicRow(
  String assetPath,
  List<Map<String, Color>> layers,
  List<String> ancestors,
  String? fontFamily,
) async {
  final raw = await rootBundle.loadString(assetPath);
  final t = (loadYaml(raw) as YamlMap)['topic'] as YamlMap;
  // The topic's own `palette:` is the last (innermost) layer of the cascade.
  final topicOwn = parsePaletteOverrides(t['palette']);
  final title = t['title'] as String;
  final subtitle = (t['list_subtitle'] as String?) ?? '';
  final tags = [
    for (final tag in t['tags'] as YamlList? ?? const []) tag as String,
  ];
  final aliases = [
    for (final a in t['aliases'] as YamlList? ?? const []) a as String,
  ];
  // Full-text index: collect EVERY string in the topic (title, subtitle, tags,
  // aliases, and every block's text — markdown, table cells, drug doses, …),
  // then normalise once so spellings/units already match at search time. We
  // already parse the whole YAML here, so this is near-free.
  final buf = StringBuffer();
  _collectStrings(t, buf);
  return BookTopic(
    id: t['id'] as String,
    title: title,
    subtitle: subtitle,
    asset: assetPath,
    tags: tags,
    palette: resolvePalette([...layers, topicOwn]),
    fontFamily: (t['font_family'] as String?) ?? fontFamily,
    searchText: SearchNormalizer.normalize(buf.toString()),
    titleText: SearchNormalizer.normalize('$title $subtitle'),
    keywordsText: SearchNormalizer.normalize([...tags, ...aliases].join(' ')),
    breadcrumb: ancestors.join(' › '),
  );
}

/// Recursively appends every String leaf in a parsed-YAML node to [buf]
/// (map values and list items; map keys are structural, so skipped). This is
/// what makes search full-text and block-type-agnostic — new block types are
/// indexed automatically.
void _collectStrings(dynamic node, StringBuffer buf) {
  if (node is String) {
    buf
      ..write(node)
      ..write(' ');
  } else if (node is Map) {
    for (final v in node.values) {
      _collectStrings(v, buf);
    }
  } else if (node is List) {
    for (final v in node) {
      _collectStrings(v, buf);
    }
  }
}

/// Resolves a topic `link_id` to where its topic lives, so a tapped
/// cross-link can navigate. Built once from the loaded library; spans
/// the WHOLE library, so links may target any book. A `link_id` that
/// isn't present resolves to null — the link renders but is inert (the
/// graceful case for a standalone/pasted topic with no library, or a
/// book that isn't installed).
class LibraryIndex {
  LibraryIndex(List<Book> books)
    : _byId = {
        for (final b in books)
          for (final t in b.allTopics)
            t.id: TopicRef(b.id, t.asset, t.palette, t.fontFamily),
      },
      _bookByTopic = {
        for (final b in books)
          for (final t in b.allTopics) t.id: b,
      };

  final Map<String, TopicRef> _byId;
  final Map<String, Book> _bookByTopic;

  TopicRef? lookup(String topicId) => _byId[topicId];
  bool contains(String topicId) => _byId.containsKey(topicId);

  /// The [Book] that owns [topicId] — so a cross-link can open the topic in a
  /// full [TopicPager] (with sibling swipe + in-protocol search) rather than a
  /// bare single-topic frame.
  Book? bookContaining(String topicId) => _bookByTopic[topicId];
}

/// Where a topic lives: its book id (for last-state) + asset path + the
/// topic's fully-resolved palette (so a cross-link opens it with the right
/// chapter colors).
class TopicRef {
  const TopicRef(this.bookId, this.asset, this.palette, this.fontFamily);
  final String bookId;
  final String asset;
  final Map<String, Color> palette;

  /// The owning book's body typeface, so a cross-link opens the topic set
  /// the way its own book sets it.
  final String? fontFamily;
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
  for (final t in book.allTopics) {
    if (t.id == topicId) return t;
  }
  return null;
}
