import 'package:flutter/material.dart';
import 'package:orbweaver/data/search_normalizer.dart';

/// One source reference book on the shelf.
///
/// A [Book] owns a tree of [BookNode]s ([contents]) — the topic+map model
/// (DITA topic/map; MkDocs `nav:`; Antora/Sphinx toctree), expressed in YAML.
/// The book is a *map*: it references self-contained topic files and arranges
/// them into a chapter → section → subsection hierarchy. A topic is just the
/// user-facing row metadata plus the YAML asset path that `TopicFrame` loads
/// when the topic is opened.
class Book {
  const Book({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.coverAsset,
    required this.spineColor,
    required this.contents,
    this.paletteOverrides = const {},
  });

  final String id;
  final String title;
  final String subtitle;
  final String coverAsset;
  final Color spineColor;

  /// Book-level `palette:` overrides (role → color), the root of the
  /// cascade. Chapters and topics inherit and may override per-role.
  final Map<String, Color> paletteOverrides;

  /// Ordered top-level nodes (chapters or bare topics).
  final List<BookNode> contents;

  /// Every topic in the book, flattened depth-first (a group's own
  /// `overview` page first, then its children). This is what search,
  /// counts, `LibraryIndex`, last-state resolution, and cross-links use —
  /// all of which key on a topic's logical id, so they are unaffected by
  /// where the topic sits in the tree.
  Iterable<BookTopic> get allTopics sync* {
    yield* _walk(contents);
  }

  static Iterable<BookTopic> _walk(List<BookNode> nodes) sync* {
    for (final node in nodes) {
      switch (node) {
        case BookLeaf(:final topic):
          yield topic;
        case BookGroup(:final overview, :final children):
          if (overview != null) yield overview;
          yield* _walk(children);
      }
    }
  }
}

/// A node in a book's contents tree: either a [BookGroup] (a chapter or
/// section that organizes children, optionally with its own overview page)
/// or a [BookLeaf] (a reference to a single topic).
sealed class BookNode {
  const BookNode();
}

/// A chapter or section. Has a [title] (the outline number is folded in,
/// e.g. `"6.2 Malaria"`), an optional [overview] page of its own, and a
/// list of [children]. A group with an [overview] is both an openable page
/// and a parent (the DITA rule: a topicref can carry content and nest
/// children).
class BookGroup extends BookNode {
  const BookGroup({
    required this.title,
    required this.children,
    this.overview,
    this.paletteOverrides = const {},
  });

  final String title;
  final BookTopic? overview;
  final List<BookNode> children;

  /// Chapter-level `palette:` overrides, applied over the book's and
  /// inherited by this group's topics. Retained for reference; topic rows
  /// already carry their fully-resolved [BookTopic.palette].
  final Map<String, Color> paletteOverrides;
}

/// A leaf reference to a single topic.
class BookLeaf extends BookNode {
  const BookLeaf(this.topic);

  final BookTopic topic;
}

class BookTopic {
  const BookTopic({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.asset,
    this.tags = const [],
    this.palette = const {},
    this.searchText = '',
  });

  final String id;
  final String title;
  final String subtitle;
  final String asset;
  final List<String> tags;

  /// Fully-resolved color palette for this topic (book → chapter → topic
  /// cascade, accent-derived roles filled in). Drives the TOC row accent
  /// and is passed to the topic page when opened.
  final Map<String, Color> palette;

  /// Pre-normalised full-text index for this topic: title + subtitle + tags +
  /// aliases + every block's text, run through [SearchNormalizer] once at load
  /// (so British/American spellings and dosing wording already match). Empty
  /// for synthetic test stubs. See [matches].
  final String searchText;

  /// True if every whitespace term in [query] (after the same normalisation
  /// applied to [searchText]) is found as a substring — token-AND full-text
  /// search. So "diarrhea" hits British "diarrhoea" content and "diazepam
  /// rectal" requires both words somewhere in the topic.
  bool matches(String query) {
    final q = SearchNormalizer.normalize(query);
    if (q.isEmpty) return true;
    for (final term in q.split(' ')) {
      if (!searchText.contains(term)) return false;
    }
    return true;
  }
}
