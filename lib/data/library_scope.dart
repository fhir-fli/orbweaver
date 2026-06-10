import 'package:flutter/material.dart';
import 'package:orbweaver/data/library.dart';
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

/// Opens the topic a `link_id` points at, pushing it onto the stack so
/// back returns to the source topic. No-ops if the id doesn't resolve
/// (unknown link, or no library in scope) — links degrade gracefully.
Future<void> openLinkedTopic(BuildContext context, String topicId) async {
  final ref = LibraryScope.of(context)?.lookup(topicId);
  if (ref == null) return;
  await LastState.recordTopic(ref.bookId, topicId);
  if (!context.mounted) return;
  await Navigator.push(
    context,
    MaterialPageRoute<void>(
      builder: (_) => TopicFrame(assetPath: ref.asset, palette: ref.palette),
    ),
  );
}
