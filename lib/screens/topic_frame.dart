import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:orbweaver/data/topic_loader.dart';
import 'package:orbweaver/models/book.dart';
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
    super.key,
  });

  final String assetPath;

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
    loadTopicAsset(widget.assetPath).then((t) {
      if (!mounted) return;
      setState(() {
        _topic = t;
        _pageKeys =
            List.generate(t.pages.length, (_) => GlobalKey(), growable: false);
      });
      widget.onLoaded?.call(t);
      _report();
    }).catchError((Object e) {
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
              for (final e in topic.ownPaletteArgb.entries) e.key: Color(e.value),
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
                ? SingleChildScrollView(
                    physics: const NeverScrollableScrollPhysics(),
                    child: TopicPageBody(page: page, theme: theme),
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
      child: TopicView(topic: topic, palette: resolved, pageKeys: _pageKeys),
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
    return LayoutBuilder(builder: (context, c) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _fit(c.maxHeight));
      return MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(_scale)),
        // A non-scrollable scroll view gives the content unbounded height, so
        // we can measure its NATURAL height (rather than clamp it to the
        // screen and overflow) and scale down until it fits.
        child: SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          child: KeyedSubtree(key: _key, child: widget.builder(_scale)),
        ),
      );
    });
  }
}

/// A single topic with app-bar chrome (page badge + title), for standalone /
/// last-state-restore opens where there are no sibling protocols to swipe.
class TopicFrame extends StatefulWidget {
  const TopicFrame({required this.assetPath, this.palette = const {}, super.key});

  final String assetPath;
  final Map<String, Color> palette;

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
    final accent = resolved != null ? TopicTheme(resolved).header : Colors.grey;
    return Scaffold(
      backgroundColor: Colors.white,
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
    super.key,
  });

  /// Ordered real topics (no formulary drugs) the user can swipe between.
  final List<BookTopic> siblings;
  final int initialIndex;
  final String bookId;

  @override
  State<TopicPager> createState() => _TopicPagerState();
}

class _TopicPagerState extends State<TopicPager> {
  late final PageController _hCtrl =
      PageController(initialPage: widget.initialIndex);
  late int _activeIndex = widget.initialIndex;
  final _badge = ValueNotifier<int?>(null);
  final Map<int, int?> _badgeByIndex = {};

  @override
  void dispose() {
    _hCtrl.dispose();
    _badge.dispose();
    super.dispose();
  }

  void _report(int index, int? pageNumber) {
    _badgeByIndex[index] = pageNumber;
    if (index == _activeIndex) _badge.value = pageNumber;
  }

  @override
  Widget build(BuildContext context) {
    final active = widget.siblings[_activeIndex];
    final accent = TopicTheme(active.palette).header;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: accent,
        foregroundColor: Colors.white,
        titleSpacing: 8,
        title: _AppBarTitle(
          pageNumber: _badge,
          title: active.title,
          headerColor: accent,
        ),
      ),
      body: SafeArea(
        child: PageView.builder(
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
            );
          },
        ),
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
