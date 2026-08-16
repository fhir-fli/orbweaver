import 'package:flutter/material.dart';
import 'package:orbweaver/data/library.dart';
import 'package:orbweaver/models/book.dart';
import 'package:orbweaver/screens/topic_frame.dart';
import 'package:orbweaver/services/last_state.dart';

/// Makes the [LibraryIndex] available to the whole widget tree (provided
/// above the Navigator in `main`), so any rendered topic's cross-links
/// can resolve and navigate. Deep flowchart link spans reach it via
/// `LibraryScope.of(context)` rather than threading a callback down.
class LibraryScope extends InheritedWidget {
  const LibraryScope({
    required this.index,
    required super.child,
    super.key,
  });

  final LibraryIndex index;

  static LibraryIndex? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<LibraryScope>()?.index;

  @override
  bool updateShouldNotify(LibraryScope oldWidget) => oldWidget.index != index;
}

/// True when [topicId] resolves to a topic in the loaded library — i.e.
/// a tap on it would navigate. Used to decide whether to render a link
/// as interactive vs. an inert cross-reference cue.
bool isTopicLinkLive(BuildContext context, String topicId) =>
    LibraryScope.of(context)?.contains(topicId) ?? false;

/// Opens [topicId] as a protocol page, pushing it onto the stack so back
/// returns to the source. Uses a [TopicPager] (sibling swipe + in-protocol
/// search + home) when the owning book is known; falls back to a single
/// [TopicFrame] otherwise. No-ops if the id doesn't resolve — links degrade
/// gracefully.
///
/// [anchor] is the `#slug` half of a `topic:<id>#<anchor>` link: the topic
/// opens scrolled to the block carrying that `anchor:`. This is what lets a
/// cross-reference reach one drug card out of fifty rather than the top of the
/// drug reference.
Future<void> openLinkedTopic(
  BuildContext context,
  String topicId, {
  String? anchor,
}) async {
  final lib = LibraryScope.of(context);
  final book = lib?.bookContaining(topicId);
  if (book != null) {
    await openProtocol(context, book, topicId, anchor: anchor);
    return;
  }
  final ref = lib?.lookup(topicId);
  if (ref == null) return;
  await LastState.recordTopic(ref.bookId, topicId);
  if (!context.mounted) return;
  await Navigator.push(
    context,
    MaterialPageRoute<void>(
      builder: (_) => TopicFrame(
        assetPath: ref.asset,
        palette: ref.palette,
        fontFamily: ref.fontFamily,
        initialAnchor: anchor,
      ),
    ),
  );
}

/// Builds the swipe-siblings for a book — every real (non-drug) topic, in book
/// order.
List<BookTopic> protocolSiblings(Book book) =>
    book.allTopics.where((t) => t.drug == null).toList(growable: false);

/// Opens [topicId] (owned by [book]) in a [TopicPager] so the reader can swipe
/// between siblings, search within the protocols, and jump home. Falls back to
/// a single [TopicFrame] if the topic isn't a swipeable protocol.
Future<void> openProtocol(
  BuildContext context,
  Book book,
  String topicId, {
  String? anchor,
}) async {
  await LastState.recordTopic(book.id, topicId);
  if (!context.mounted) return;
  final siblings = protocolSiblings(book);
  final index = siblings.indexWhere((t) => t.id == topicId);
  if (index < 0) {
    final t = book.allTopics.firstWhere(
      (t) => t.id == topicId,
      orElse: () => siblings.isNotEmpty ? siblings.first : book.allTopics.first,
    );
    await Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => TopicFrame(
          assetPath: t.asset,
          palette: t.palette,
          fontFamily: t.fontFamily,
          initialAnchor: anchor,
        ),
      ),
    );
    return;
  }
  await Navigator.push(
    context,
    MaterialPageRoute<void>(
      builder: (_) => TopicPager(
        siblings: siblings,
        initialIndex: index,
        bookId: book.id,
        initialAnchor: anchor,
      ),
    ),
  );
}
