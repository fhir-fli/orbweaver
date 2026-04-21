import 'package:flutter/material.dart';
import 'package:orbweaver/models/book.dart';
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

  @override
  void initState() {
    super.initState();
    LastState.recordBook(widget.book.id);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = widget.book.topics
        .where((t) => t.matches(_query))
        .toList(growable: false);

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
                  itemCount: filtered.length,
                  separatorBuilder: (_, _) => const Divider(
                    height: 1,
                    thickness: 0.5,
                    indent: 12,
                    endIndent: 12,
                  ),
                  itemBuilder: (context, i) => _TopicRow(
                    topic: filtered[i],
                    onTap: () => _openTopic(filtered[i]),
                  ),
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

class _TopicRow extends StatelessWidget {
  const _TopicRow({
    required this.topic,
    required this.onTap,
  });

  final BookTopic topic;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = TopicTheme.of(topic.category).header;
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
