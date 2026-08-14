import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:orbweaver/data/topic_loader.dart';
import 'package:orbweaver/models/book.dart';
import 'package:orbweaver/screens/book_screen.dart' show kBookRouteName;
import 'package:orbweaver/models/topic.dart';
import 'package:orbweaver/services/last_state.dart';
import 'package:orbweaver/theme/palette.dart';
import 'package:orbweaver/theme/topic_theme.dart';
import 'package:orbweaver/widgets/topic_view.dart';

/// Loads a topic asset and renders just its body — either a continuous
/// [SingleChildScrollView] (`layout: scroll`) or a sticky vertical [PageView]
/// that snaps one screen per [TopicPage] (`layout: paged`). Carries no app-bar
/// chrome; the parent ([TopicFrame] or [TopicPager]) owns that and is fed the
/// loaded topic ([onLoaded]) and the currently-visible page number ([onPage]).
class TopicBody extends StatefulWidget {
  const TopicBody({
    required this.assetPath,
    this.palette = const {},
    this.onLoaded,
    this.onPage,
    this.initialAnchor,
    super.key,
  });

  final String assetPath;

  /// Anchor slug to open at, from a `topic:<id>#<anchor>` cross-reference.
  /// Only meaningful for a scrolling topic; a paged topic has no scroll to
  /// place.
  final String? initialAnchor;

  /// Fully-resolved palette from the book→chapter→topic cascade (empty for a
  /// standalone topic, whose palette is resolved from its own `palette:`).
  final Map<String, Color> palette;

  final void Function(Topic topic)? onLoaded;
  final void Function(int? pageNumber)? onPage;

  @override
  State<TopicBody> createState() => _TopicBodyState();
}

class _TopicBodyState extends State<TopicBody> {
  final _scrollCtrl = ScrollController();
  final _pageCtrl = PageController();
  Topic? _topic;
  Object? _error;
  List<GlobalKey> _pageKeys = const [];
  int _subPage = 0;

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
    loadTopicAsset(widget.assetPath)
        .then((t) {
          if (!mounted) return;
          setState(() {
            _topic = t;
            _pageKeys = List.generate(
              t.pages.length,
              (_) => GlobalKey(),
              growable: false,
            );
          });
          widget.onLoaded?.call(t);
          _report();
        })
        .catchError((Object e) {
          if (!mounted) return;
          setState(() => _error = e);
        });
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    _pageCtrl.dispose();
    super.dispose();
  }

  void _report() {
    final t = _topic;
    if (t == null || t.pages.isEmpty) return;
    final idx = _subPage.clamp(0, t.pages.length - 1);
    widget.onPage?.call(t.pages[idx].pageNumber);
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
      if (reveal <= viewportCenter) newIdx = i;
    }
    if (newIdx != _subPage) {
      _subPage = newIdx;
      _report();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Text('Error: $_error'),
      );
    }
    final topic = _topic;
    if (topic == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final resolved = widget.palette.isNotEmpty
        ? widget.palette
        : resolvePalette([
            {
              for (final e in topic.ownPaletteArgb.entries)
                e.key: Color(e.value),
            },
          ]);
    final theme = TopicTheme(resolved);

    if (topic.layout == TopicLayout.paged && topic.pages.length > 1) {
      // Sticky: each page snaps to a full screen. A flowchart page renders at
      // its exact size; a prose page is auto-fit (text + gaps scaled down just
      // enough) so it fills one screen full-width, like the printed page.
      return PageView(
        controller: _pageCtrl,
        scrollDirection: Axis.vertical,
        onPageChanged: (i) {
          _subPage = i;
          _report();
        },
        children: [
          for (final page in topic.pages)
            page.blocks.any((b) => b is FlowchartBlock)
                // A flowchart page scales down UNIFORMLY (boxes + text together)
                // to fit one screen — its hand-drawn boxes can't reflow like
                // text, so uniform scaling is the safe fit. No-op when it
                // already fits (renders full size, top-aligned).
                ? LayoutBuilder(
                    builder: (context, c) => FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.topCenter,
                      child: SizedBox(
                        width: c.maxWidth,
                        child: TopicPageBody(page: page, theme: theme),
                      ),
                    ),
                  )
                : _FitToScreen(
                    builder: (scale) => TopicPageBody(
                      page: page,
                      theme: theme,
                      gapScale: scale,
                    ),
                  ),
        ],
      );
    }

    return SingleChildScrollView(
      controller: _scrollCtrl,
      child: TopicView(
        topic: topic,
        palette: resolved,
        pageKeys: _pageKeys,
        initialAnchor: widget.initialAnchor,
      ),
    );
  }
}

/// Scales a paged prose page's content down (text via a smaller `textScaler`,
/// gaps via [TopicPageBody.gapScale]) just enough that it fits one screen —
/// dense and full-width like the printed protocol page, with nothing cut.
/// Measures the laid-out content and re-scales until it fits (converges in a
/// frame or two); never scales below [_min].
class _FitToScreen extends StatefulWidget {
  const _FitToScreen({required this.builder});

  final Widget Function(double scale) builder;

  @override
  State<_FitToScreen> createState() => _FitToScreenState();
}

class _FitToScreenState extends State<_FitToScreen> {
  static const double _min = 0.48;
  double _scale = 1.0;
  final _key = GlobalKey();

  void _fit(double availH) {
    final ctx = _key.currentContext;
    final box = ctx?.findRenderObject();
    if (box is! RenderBox || !box.hasSize || availH <= 0) return;
    final h = box.size.height;
    // Shrink-only, in small steps, until the content fits — converges from
    // full size DOWN to the largest scale that fits one screen (a few frames).
    // No growth, so it never oscillates back into an overflow that clips
    // clinical content.
    if (h > availH - 2 && _scale > _min) {
      final ns = (_scale * 0.97).clamp(_min, 1.0);
      if (ns != _scale) setState(() => _scale = ns);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _fit(c.maxHeight));
        return MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(_scale)),
          // A non-scrollable scroll view gives the content unbounded height, so
          // we can measure its NATURAL height (rather than clamp it to the
          // screen and overflow) and scale down until it fits.
          child: SingleChildScrollView(
            physics: const NeverScrollableScrollPhysics(),
            child: KeyedSubtree(key: _key, child: widget.builder(_scale)),
          ),
        );
      },
    );
  }
}

/// A single topic with app-bar chrome (page badge + title), for standalone /
/// last-state-restore opens where there are no sibling protocols to swipe.
class TopicFrame extends StatefulWidget {
  const TopicFrame({
    required this.assetPath,
    this.palette = const {},
    this.initialAnchor,
    super.key,
  });

  final String assetPath;
  final Map<String, Color> palette;

  /// Anchor slug to open at, from a `topic:<id>#<anchor>` cross-reference.
  final String? initialAnchor;

  @override
  State<TopicFrame> createState() => _TopicFrameState();
}

class _TopicFrameState extends State<TopicFrame> {
  final _pageNumber = ValueNotifier<int?>(null);
  String _title = '';

  @override
  void dispose() {
    _pageNumber.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final resolved = widget.palette.isNotEmpty ? widget.palette : null;
    final theme = resolved != null ? TopicTheme(resolved) : null;
    final accent = theme?.header ?? Colors.grey;
    return Scaffold(
      backgroundColor: theme?.pageWash ?? Colors.white,
      appBar: AppBar(
        backgroundColor: accent,
        foregroundColor: Colors.white,
        titleSpacing: 8,
        title: _AppBarTitle(
          pageNumber: _pageNumber,
          title: _title,
          headerColor: accent,
        ),
      ),
      body: SafeArea(
        child: TopicBody(
          assetPath: widget.assetPath,
          palette: widget.palette,
          onLoaded: (t) => setState(() => _title = t.title),
          onPage: (pn) => _pageNumber.value = pn,
          initialAnchor: widget.initialAnchor,
        ),
      ),
    );
  }
}

/// A horizontally-swipeable run of sibling protocols: swipe left/right for the
/// next/previous topic (in book order). Each page is a [TopicBody] (which may
/// itself be sticky-paged or free-scroll). The app bar reflects the active
/// protocol and its currently-visible page.
class TopicPager extends StatefulWidget {
  const TopicPager({
    required this.siblings,
    required this.initialIndex,
    required this.bookId,
    this.initialAnchor,
    super.key,
  });

  /// Ordered real topics (no formulary drugs) the user can swipe between.
  final List<BookTopic> siblings;
  final int initialIndex;
  final String bookId;

  /// Anchor slug for the topic at [initialIndex] only — a cross-reference
  /// aimed at one card. Swiping to a sibling opens it at the top, as before.
  final String? initialAnchor;

  @override
  State<TopicPager> createState() => _TopicPagerState();
}

class _TopicPagerState extends State<TopicPager> {
  late final PageController _hCtrl = PageController(
    initialPage: widget.initialIndex,
  );
  late int _activeIndex = widget.initialIndex;
  final _badge = ValueNotifier<int?>(null);
  final Map<int, int?> _badgeByIndex = {};
  final _searchCtrl = TextEditingController();
  bool _searchOpen = false;
  String _query = '';

  @override
  void dispose() {
    _hCtrl.dispose();
    _badge.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _report(int index, int? pageNumber) {
    _badgeByIndex[index] = pageNumber;
    if (index == _activeIndex) _badge.value = pageNumber;
  }

  void _closeSearch() {
    setState(() {
      _searchOpen = false;
      _query = '';
      _searchCtrl.clear();
    });
  }

  void _goToSibling(int index) {
    _closeSearch();
    _hCtrl.jumpToPage(index);
  }

  void _goHome() {
    Navigator.of(
      context,
    ).popUntil((r) => r.settings.name == kBookRouteName || r.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final active = widget.siblings[_activeIndex];
    final theme = TopicTheme(active.palette);
    final accent = theme.header;
    return Scaffold(
      backgroundColor: theme.pageWash,
      appBar: AppBar(
        backgroundColor: accent,
        foregroundColor: Colors.white,
        titleSpacing: 8,
        title: _searchOpen
            ? TextField(
                controller: _searchCtrl,
                autofocus: true,
                style: const TextStyle(color: Colors.white, fontSize: 16),
                cursorColor: Colors.white,
                decoration: const InputDecoration(
                  hintText: 'Search protocols…',
                  hintStyle: TextStyle(color: Colors.white70),
                  border: InputBorder.none,
                ),
                onChanged: (v) => setState(() => _query = v),
              )
            : _AppBarTitle(
                pageNumber: _badge,
                title: active.title,
                headerColor: accent,
              ),
        actions: [
          IconButton(
            tooltip: _searchOpen ? 'Close search' : 'Search protocols',
            icon: Icon(_searchOpen ? Icons.close : Icons.search),
            onPressed: () {
              if (_searchOpen) {
                _closeSearch();
              } else {
                setState(() => _searchOpen = true);
              }
            },
          ),
          IconButton(
            tooltip: 'All protocols',
            icon: const Icon(Icons.home_outlined),
            onPressed: _goHome,
          ),
        ],
      ),
      // The PageView stays in the tree even while searching (search results
      // overlay it), so its controller stays attached and jumpToPage works.
      body: SafeArea(
        child: Stack(
          children: [
            PageView.builder(
              controller: _hCtrl,
              itemCount: widget.siblings.length,
              onPageChanged: (i) {
                setState(() => _activeIndex = i);
                _badge.value = _badgeByIndex[i];
                LastState.recordTopic(widget.bookId, widget.siblings[i].id);
              },
              itemBuilder: (context, i) {
                final t = widget.siblings[i];
                return TopicBody(
                  assetPath: t.asset,
                  palette: t.palette,
                  onPage: (pn) => _report(i, pn),
                  initialAnchor: i == widget.initialIndex
                      ? widget.initialAnchor
                      : null,
                );
              },
            ),
            if (_searchOpen && _query.isNotEmpty)
              Positioned.fill(
                child: _SearchResults(
                  siblings: widget.siblings,
                  query: _query,
                  onTap: _goToSibling,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// In-protocol search: a relevance-ranked list of the book's protocols matching
/// the query; tapping one jumps the pager to it.
class _SearchResults extends StatelessWidget {
  const _SearchResults({
    required this.siblings,
    required this.query,
    required this.onTap,
  });

  final List<BookTopic> siblings;
  final String query;
  final void Function(int index) onTap;

  @override
  Widget build(BuildContext context) {
    final scored = <(int, double)>[];
    for (var i = 0; i < siblings.length; i++) {
      final s = siblings[i].relevance(query);
      if (s > 0) scored.add((i, s));
    }
    scored.sort((a, b) {
      final byScore = b.$2.compareTo(a.$2);
      return byScore != 0 ? byScore : a.$1.compareTo(b.$1);
    });
    if (scored.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            'No protocols match "$query".',
            style: const TextStyle(color: Colors.black54),
          ),
        ),
      );
    }
    return ColoredBox(
      color: const Color(0xFFEFEFEF),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 4),
        itemCount: scored.length,
        separatorBuilder: (_, __) =>
            const Divider(height: 1, thickness: 0.5, indent: 12, endIndent: 12),
        itemBuilder: (context, k) {
          final i = scored[k].$1;
          final t = siblings[i];
          final accent = t.palette['accent'] ?? const Color(0xFFBDBDBD);
          return InkWell(
            onTap: () => onTap(i),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              child: Row(
                children: [
                  Container(
                    width: 3,
                    height: 34,
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
                          t.title,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (t.subtitle.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            t.subtitle,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// App-bar title row: an optional page-number badge + the topic title.
class _AppBarTitle extends StatelessWidget {
  const _AppBarTitle({
    required this.pageNumber,
    required this.title,
    required this.headerColor,
  });

  final ValueListenable<int?> pageNumber;
  final String title;
  final Color headerColor;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int?>(
      valueListenable: pageNumber,
      builder: (_, pn, _) => Row(
        children: [
          if (pn != null) ...[
            _PageBadge(pageNumber: pn, headerColor: headerColor),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Text(
              title,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ),
        ],
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
