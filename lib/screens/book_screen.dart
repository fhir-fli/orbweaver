import 'package:flutter/material.dart';
import 'package:orbweaver/data/topic_loader.dart';
import 'package:orbweaver/models/book.dart';
import 'package:orbweaver/models/topic.dart';
import 'package:orbweaver/screens/topic_frame.dart';
import 'package:orbweaver/services/last_state.dart';
import 'package:orbweaver/theme/topic_theme.dart';

/// One book's table of contents. Topics are filtered live by the
/// search bar (title / subtitle / tags).
class BookScreen extends StatefulWidget {
  const BookScreen({required this.book, super.key});

  final Book book;

  @override
  State<BookScreen> createState() => _BookScreenState();
}

class _BookScreenState extends State<BookScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';
  bool _searchOpen = false;

  /// Topic.category per topic id, loaded from each YAML on open.
  /// Rows without an entry yet render a neutral placeholder bar.
  Map<String, TopicCategory> _categories = {};

  @override
  void initState() {
    super.initState();
    LastState.recordBook(widget.book.id);
    _loadCategories();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    final entries = await Future.wait(
      widget.book.topics.map((t) async {
        try {
          final topic = await loadTopicAsset(t.asset);
          return MapEntry(t.id, topic.category);
        } catch (_) {
          return MapEntry(t.id, TopicCategory.medical);
        }
      }),
    );
    if (!mounted) return;
    setState(() => _categories = Map.fromEntries(entries));
  }

  /// List rows: a section header wherever the category changes between
  /// consecutive topics (the WVEMS PDF index's Universal / Medical /
  /// Trauma / Critical Care sections), then the topic rows. Headers are
  /// derived purely from each topic's own `category` — nothing
  /// book-specific is hardcoded. A book whose topics all share one
  /// category renders flat, and no headers show until categories have
  /// loaded.
  List<_ListItem> _buildItems(List<BookTopic> topics) {
    final distinct = topics
        .map((t) => _categories[t.id])
        .whereType<TopicCategory>()
        .toSet();
    if (distinct.length < 2) return [for (final t in topics) _TopicItem(t)];

    final items = <_ListItem>[];
    TopicCategory? prev;
    for (final t in topics) {
      final cat = _categories[t.id];
      if (cat != null && cat != prev) {
        items.add(_SectionHeaderItem(cat));
        prev = cat;
      }
      items.add(_TopicItem(t));
    }
    return items;
  }

  @override
  Widget build(BuildContext context) {
    final filtered = widget.book.topics
        .where((t) => t.matches(_query))
        .toList(growable: false);
    final items = _buildItems(filtered);

    return Scaffold(
      backgroundColor: const Color(0xFFEFEFEF),
      appBar: AppBar(
        backgroundColor: widget.book.spineColor,
        foregroundColor: Colors.white,
        title: _searchOpen
            ? TextField(
                controller: _searchCtrl,
                autofocus: true,
                style: const TextStyle(color: Colors.white, fontSize: 16),
                cursorColor: Colors.white,
                decoration: const InputDecoration(
                  hintText: 'Search…',
                  hintStyle: TextStyle(color: Colors.white70),
                  border: InputBorder.none,
                ),
                onChanged: (v) => setState(() => _query = v),
              )
            : Text(widget.book.title),
        actions: [
          IconButton(
            icon: Icon(_searchOpen ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                if (_searchOpen) {
                  _searchCtrl.clear();
                  _query = '';
                }
                _searchOpen = !_searchOpen;
              });
            },
          ),
        ],
      ),
      body: widget.book.topics.isEmpty
          ? const _EmptyState()
          : filtered.isEmpty
              ? _NoMatches(query: _query)
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  itemCount: items.length,
                  // Divider only between two adjacent topic rows — not
                  // around section headers, which separate visually on
                  // their own.
                  separatorBuilder: (_, i) =>
                      items[i] is _TopicItem && items[i + 1] is _TopicItem
                          ? const Divider(
                              height: 1,
                              thickness: 0.5,
                              indent: 12,
                              endIndent: 12,
                            )
                          : const SizedBox.shrink(),
                  itemBuilder: (context, i) => switch (items[i]) {
                    _SectionHeaderItem(:final category) =>
                      _SectionHeader(category: category),
                    _TopicItem(:final topic) => _TopicRow(
                        topic: topic,
                        category: _categories[topic.id],
                        onTap: () => _openTopic(topic),
                      ),
                  },
                ),
    );
  }

  Future<void> _openTopic(BookTopic topic) async {
    await LastState.recordTopic(widget.book.id, topic.id);
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => TopicFrame(assetPath: topic.asset),
      ),
    );
  }
}

/// A TOC list row — either a category section header or a topic.
sealed class _ListItem {
  const _ListItem();
}

class _SectionHeaderItem extends _ListItem {
  const _SectionHeaderItem(this.category);
  final TopicCategory category;
}

class _TopicItem extends _ListItem {
  const _TopicItem(this.topic);
  final BookTopic topic;
}

/// Colored section band matching the WVEMS PDF index's visual language —
/// the category's theme color with a white label.
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.category});

  final TopicCategory category;

  static String _label(TopicCategory c) => switch (c) {
        TopicCategory.universal => 'Universal',
        TopicCategory.medical => 'Medical',
        TopicCategory.trauma => 'Trauma',
        TopicCategory.criticalCare => 'Critical Care',
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: TopicTheme.of(category).header,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Text(
        _label(category),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}

class _TopicRow extends StatelessWidget {
  const _TopicRow({
    required this.topic,
    required this.category,
    required this.onTap,
  });

  final BookTopic topic;
  final TopicCategory? category;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = category == null
        ? const Color(0xFFBDBDBD)
        : TopicTheme.of(category!).header;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Container(
              width: 3,
              height: 32,
              decoration: BoxDecoration(
                color: accent,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    topic.title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    topic.subtitle,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              size: 20,
              color: Colors.black38,
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) => const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text(
            'No topics yet.\n\nContent for this book is still being authored.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.black54),
          ),
        ),
      );
}

class _NoMatches extends StatelessWidget {
  const _NoMatches({required this.query});

  final String query;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            'No topics match "$query".',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.black54),
          ),
        ),
      );
}
