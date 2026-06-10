import 'package:flutter/material.dart';
import 'package:orbweaver/data/topic_loader.dart';
import 'package:orbweaver/models/book.dart';
import 'package:orbweaver/models/topic.dart';
import 'package:orbweaver/screens/topic_frame.dart';
import 'package:orbweaver/services/last_state.dart';
import 'package:orbweaver/theme/topic_theme.dart';

/// One book's table of contents.
///
/// The book is a *map* (topic+map model): its [Book.contents] is a tree of
/// chapters/sections referencing self-contained topic files. Rendering is a
/// hybrid — top-level groups (chapters) drill down into a [_ChapterScreen]
/// whose sections/subsections are a collapsible accordion; bare top-level
/// topics render as rows directly. The search bar flattens the whole tree
/// ([Book.allTopics]) and shows matching topics as a flat list.
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

  /// Topic.category per topic id, loaded from each YAML on open — drives the
  /// per-row accent color. Rows without an entry yet render a neutral bar.
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
      widget.book.allTopics.map((t) async {
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

  @override
  Widget build(BuildContext context) {
    final allTopics = widget.book.allTopics.toList(growable: false);

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
      body: allTopics.isEmpty
          ? const _EmptyState()
          : _query.isNotEmpty
              ? _buildSearchResults(allTopics)
              : _buildContents(),
    );
  }

  /// Flat list of topics matching the search query (ignores hierarchy).
  Widget _buildSearchResults(List<BookTopic> allTopics) {
    final matches =
        allTopics.where((t) => t.matches(_query)).toList(growable: false);
    if (matches.isEmpty) return _NoMatches(query: _query);
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 4),
      itemCount: matches.length,
      separatorBuilder: (_, __) => const Divider(
        height: 1,
        thickness: 0.5,
        indent: 12,
        endIndent: 12,
      ),
      itemBuilder: (context, i) => _TopicRow(
        topic: matches[i],
        category: _categories[matches[i].id],
        onTap: () => openTopicFromBook(context, widget.book.id, matches[i]),
      ),
    );
  }

  /// Top-level contents: groups drill down, bare topics open directly.
  Widget _buildContents() {
    final nodes = widget.book.contents;
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 4),
      itemCount: nodes.length,
      separatorBuilder: (_, i) =>
          nodes[i] is BookLeaf && nodes[i + 1] is BookLeaf
              ? const Divider(
                  height: 1,
                  thickness: 0.5,
                  indent: 12,
                  endIndent: 12,
                )
              : const SizedBox.shrink(),
      itemBuilder: (context, i) => switch (nodes[i]) {
        BookLeaf(:final topic) => _TopicRow(
            topic: topic,
            category: _categories[topic.id],
            onTap: () => openTopicFromBook(context, widget.book.id, topic),
          ),
        BookGroup group => _GroupRow(
            group: group,
            spineColor: widget.book.spineColor,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => _ChapterScreen(
                  bookId: widget.book.id,
                  group: group,
                  spineColor: widget.book.spineColor,
                  categories: _categories,
                ),
              ),
            ),
          ),
      },
    );
  }
}

/// Records last-state and opens a topic page.
Future<void> openTopicFromBook(
  BuildContext context,
  String bookId,
  BookTopic topic,
) async {
  await LastState.recordTopic(bookId, topic.id);
  if (!context.mounted) return;
  await Navigator.push(
    context,
    MaterialPageRoute<void>(
      builder: (_) => TopicFrame(assetPath: topic.asset),
    ),
  );
}

/// A chapter (top-level group) opened as its own screen, with its sections
/// and subsections shown as a collapsible accordion of [_NodeTile]s.
class _ChapterScreen extends StatelessWidget {
  const _ChapterScreen({
    required this.bookId,
    required this.group,
    required this.spineColor,
    required this.categories,
  });

  final String bookId;
  final BookGroup group;
  final Color spineColor;
  final Map<String, TopicCategory> categories;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEFEFEF),
      appBar: AppBar(
        backgroundColor: spineColor,
        foregroundColor: Colors.white,
        title: Text(group.title),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 4),
        children: [
          if (group.overview != null)
            _TopicRow(
              topic: group.overview!,
              category: categories[group.overview!.id],
              onTap: () =>
                  openTopicFromBook(context, bookId, group.overview!),
            ),
          for (final node in group.children)
            _NodeTile(
              node: node,
              bookId: bookId,
              categories: categories,
              depth: 0,
            ),
        ],
      ),
    );
  }
}

/// Recursively renders a node inside a chapter: a leaf is a tappable row; a
/// group is a collapsible [ExpansionTile] whose `overview` (if any) is the
/// first row inside, followed by its children.
class _NodeTile extends StatelessWidget {
  const _NodeTile({
    required this.node,
    required this.bookId,
    required this.categories,
    required this.depth,
  });

  final BookNode node;
  final String bookId;
  final Map<String, TopicCategory> categories;
  final int depth;

  @override
  Widget build(BuildContext context) {
    switch (node) {
      case BookLeaf(:final topic):
        return _TopicRow(
          topic: topic,
          category: categories[topic.id],
          indent: depth * 12.0,
          onTap: () => openTopicFromBook(context, bookId, topic),
        );
      case BookGroup group:
        return ExpansionTile(
          tilePadding: EdgeInsets.only(left: 12 + depth * 12.0, right: 12),
          childrenPadding: EdgeInsets.zero,
          shape: const Border(),
          collapsedShape: const Border(),
          title: Text(
            group.title,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
          ),
          children: [
            if (group.overview != null)
              _TopicRow(
                topic: group.overview!,
                category: categories[group.overview!.id],
                indent: (depth + 1) * 12.0,
                onTap: () =>
                    openTopicFromBook(context, bookId, group.overview!),
              ),
            for (final child in group.children)
              _NodeTile(
                node: child,
                bookId: bookId,
                categories: categories,
                depth: depth + 1,
              ),
          ],
        );
    }
  }
}

/// A drill-down row for a top-level chapter group.
class _GroupRow extends StatelessWidget {
  const _GroupRow({
    required this.group,
    required this.spineColor,
    required this.onTap,
  });

  final BookGroup group;
  final Color spineColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final count = _leafCount(group);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 3,
              height: 32,
              decoration: BoxDecoration(
                color: spineColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    group.title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$count ${count == 1 ? 'topic' : 'topics'}',
                    style: const TextStyle(fontSize: 11, color: Colors.black54),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, size: 22, color: Colors.black38),
          ],
        ),
      ),
    );
  }

  static int _leafCount(BookGroup group) {
    var n = group.overview != null ? 1 : 0;
    for (final child in group.children) {
      switch (child) {
        case BookLeaf():
          n++;
        case BookGroup g:
          n += _leafCount(g);
      }
    }
    return n;
  }
}

class _TopicRow extends StatelessWidget {
  const _TopicRow({
    required this.topic,
    required this.category,
    required this.onTap,
    this.indent = 0,
  });

  final BookTopic topic;
  final TopicCategory? category;
  final VoidCallback onTap;
  final double indent;

  @override
  Widget build(BuildContext context) {
    final accent = category == null
        ? const Color(0xFFBDBDBD)
        : TopicTheme.of(category!).header;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.only(left: 12 + indent, right: 12, top: 8, bottom: 8),
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
                    style: const TextStyle(fontSize: 11, color: Colors.black54),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, size: 20, color: Colors.black38),
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
