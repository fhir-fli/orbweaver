import 'package:flutter/material.dart';
import 'package:orbweaver/models/topic.dart';

/// One source reference book on the shelf.
///
/// Each [Book] owns a list of [BookTopic] entries. A topic is just the
/// user-facing row metadata plus the YAML asset path that gets loaded by
/// `TopicFrame` when the topic is opened.
class Book {
  const Book({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.coverAsset,
    required this.spineColor,
    required this.topics,
  });

  final String id;
  final String title;
  final String subtitle;
  final String coverAsset;
  final Color spineColor;
  final List<BookTopic> topics;
}

class BookTopic {
  const BookTopic({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.asset,
    this.tags = const [],
    this.category = TopicCategory.medical,
  });

  final String id;
  final String title;
  final String subtitle;
  final String asset;
  final List<String> tags;

  /// Category accent used on the TOC row.  Must match the `category:`
  /// field in the topic's YAML so the row's leading bar matches the
  /// topic banner once opened.
  final TopicCategory category;

  bool matches(String query) {
    if (query.isEmpty) return true;
    final q = query.toLowerCase();
    if (title.toLowerCase().contains(q)) return true;
    if (subtitle.toLowerCase().contains(q)) return true;
    return tags.any((t) => t.toLowerCase().contains(q));
  }
}
