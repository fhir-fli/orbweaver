import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:orbweaver/data/topic_loader.dart';
import 'package:orbweaver/models/topic.dart';
import 'package:orbweaver/theme/palette.dart';
import 'package:orbweaver/theme/topic_theme.dart';
import 'package:orbweaver/widgets/topic_view.dart';

/// Chrome around a [TopicView]: app bar with a page-number badge that
/// updates as the user scrolls past each page's [TopicPage], plus the
/// scroll view itself.
///
/// Scroll-tracking uses [RenderAbstractViewport.getOffsetToReveal] to
/// compute each page's top offset on demand — no manual height math.
class TopicFrame extends StatefulWidget {
  const TopicFrame({required this.assetPath, this.palette = const {}, super.key});

  final String assetPath;

  /// Fully-resolved color palette from the book → chapter → topic cascade,
  /// passed when opened from a book. Empty for a standalone/pasted topic,
  /// in which case the palette is resolved from the topic's own `palette:`.
  final Map<String, Color> palette;

  @override
  State<TopicFrame> createState() => _TopicFrameState();
}

class _TopicFrameState extends State<TopicFrame> {
  final _scrollCtrl = ScrollController();
  final _currentPage = ValueNotifier<int>(0);
  Topic? _topic;
  Object? _error;
  List<GlobalKey> _pageKeys = const [];

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
    loadTopicAsset(widget.assetPath).then((t) {
      if (!mounted) return;
      setState(() {
        _topic = t;
        _pageKeys =
            List.generate(t.pages.length, (_) => GlobalKey(), growable: false);
      });
    }).catchError((Object e) {
      if (!mounted) return;
      setState(() => _error = e);
    });
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    _currentPage.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_pageKeys.length < 2 || !_scrollCtrl.hasClients) return;
    final position = _scrollCtrl.position;
    final viewportCenter = position.pixels + position.viewportDimension / 2;
    var newIdx = 0;
    for (var i = 0; i < _pageKeys.length; i++) {
      final ctx = _pageKeys[i].currentContext;
      if (ctx == null) continue;
      final box = ctx.findRenderObject();
      if (box is! RenderBox) continue;
      final viewport = RenderAbstractViewport.maybeOf(box);
      if (viewport == null) continue;
      final reveal = viewport.getOffsetToReveal(box, 0).offset;
      // Current page = last page whose top is above the viewport's
      // vertical centre. That matches the reader's expectation: when
      // more than half the screen is a given page, that page's number
      // shows in the header.
      if (reveal <= viewportCenter) newIdx = i;
    }
    if (_currentPage.value != newIdx) _currentPage.value = newIdx;
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Topic')),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Text('Error: $_error'),
        ),
      );
    }
    final topic = _topic;
    if (topic == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Loading…')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    // Resolve the palette (cascade from the book if opened there, else the
    // topic's own over the defaults). The accent drives the app bar + badge
    // so the header matches the content.
    final resolved = widget.palette.isNotEmpty
        ? widget.palette
        : resolvePalette([
            {
              for (final e in topic.ownPaletteArgb.entries) e.key: Color(e.value),
            },
          ]);
    final theme = TopicTheme(resolved);
    final accent = theme.header;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: accent,
        foregroundColor: Colors.white,
        titleSpacing: 8,
        title: ValueListenableBuilder<int>(
          valueListenable: _currentPage,
          builder: (_, idx, _) {
            final safeIdx = idx.clamp(0, topic.pages.length - 1);
            final page = topic.pages[safeIdx];
            return Row(
              children: [
                if (page.pageNumber != null) ...[
                  _PageBadge(
                    pageNumber: page.pageNumber!,
                    headerColor: accent,
                  ),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: Text(
                    topic.title,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          controller: _scrollCtrl,
          child: TopicView(
            topic: topic,
            palette: resolved,
            pageKeys: _pageKeys,
          ),
        ),
      ),
    );
  }
}

class _PageBadge extends StatelessWidget {
  const _PageBadge({required this.pageNumber, required this.headerColor});

  final int pageNumber;
  final Color headerColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 24,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(
        '$pageNumber',
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w800,
          color: headerColor,
        ),
      ),
    );
  }
}
