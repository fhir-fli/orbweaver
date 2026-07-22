import 'package:flutter/material.dart';
import 'package:orbweaver/data/search_normalizer.dart';
import 'package:orbweaver/models/formulary.dart';

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
    this.view,
  });

  final String id;
  final String title;
  final String subtitle;
  final String coverAsset;
  final Color spineColor;

  /// A book-level `view:` marker that replaces the default drill-down table of
  /// contents. `"index"` → a single-page sectioned directory linking every
  /// topic at once (like the WVEMS cover). Null for the ordinary drill-down.
  final String? view;

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
    this.view,
    this.formulary,
  });

  final String title;
  final BookTopic? overview;
  final List<BookNode> children;

  /// A `view:` marker that replaces the generic chapter/accordion rendering
  /// with a bespoke screen. `"collection"` → a faceted [Formulary] index.
  /// Null for an ordinary chapter/section group.
  final String? view;

  /// The loaded collection dataset when [view] is `"collection"`. Its drugs
  /// are also surfaced as synthetic [BookLeaf] children (so they are searched
  /// and counted); this holds the structured records the custom view renders.
  final Formulary? formulary;

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
    this.titleText = '',
    this.keywordsText = '',
    this.breadcrumb = '',
    this.drug,
  });

  final String id;
  final String title;
  final String subtitle;
  final String asset;
  final List<String> tags;

  /// For a synthetic formulary-drug row: the structured [Drug] record this
  /// topic stands in for. When set, opening the row renders the drug detail
  /// page directly instead of loading [asset] (which is a `formulary:` sentinel,
  /// not a real file). Null for ordinary topics.
  final Drug? drug;

  /// Fully-resolved color palette for this topic (book → chapter → topic
  /// cascade, accent-derived roles filled in). Drives the TOC row accent
  /// and is passed to the topic page when opened.
  final Map<String, Color> palette;

  /// Pre-normalised full-text index for this topic: title + subtitle + tags +
  /// aliases + every block's text, run through [SearchNormalizer] once at load
  /// (so British/American spellings and dosing wording already match). Empty
  /// for synthetic test stubs.
  final String searchText;

  /// Normalised title + subtitle, and normalised tags + aliases — kept
  /// separately so [relevance] can weight a title/keyword hit above a buried
  /// body-text mention.
  final String titleText;
  final String keywordsText;

  /// Human-readable ancestry for search results, e.g.
  /// "1. Triage… › 1.5 Diagnostic considerations". Empty for top-level
  /// topics. Populated during library load.
  final String breadcrumb;

  /// Relevance of this topic to [query], or 0 if it doesn't match. Every
  /// query term must appear *somewhere* (token-AND); each term then scores by
  /// where it hit — title ≫ keywords ≫ body — with bonuses for the whole
  /// query appearing as a phrase in, or at the start of, the title.
  double relevance(String query) {
    final q = SearchNormalizer.normalize(query);
    if (q.isEmpty) return 0;
    final terms = q.split(' ');
    for (final term in terms) {
      if (!searchText.contains(term)) return 0; // AND filter
    }
    var score = 0.0;
    for (final term in terms) {
      if (titleText.contains(term)) {
        score += 10;
      } else if (keywordsText.contains(term)) {
        score += 5;
      } else {
        score += 1; // body-only mention
      }
    }
    if (titleText.contains(q)) score += 20; // whole query as a title phrase
    if (titleText.startsWith(q)) score += 10; // title prefix
    return score;
  }

  /// Boolean form of [relevance] (empty query matches everything).
  bool matches(String query) =>
      SearchNormalizer.normalize(query).isEmpty || relevance(query) > 0;
}
