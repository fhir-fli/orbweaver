import 'package:flutter/material.dart';
import 'package:orbweaver/models/topic.dart';
import 'package:orbweaver/theme/palette.dart';
import 'package:orbweaver/theme/topic_theme.dart';
import 'package:orbweaver/widgets/blocks/drug_card_block_view.dart';
import 'package:orbweaver/widgets/blocks/image_block_view.dart';
import 'package:orbweaver/widgets/blocks/prose_block_view.dart';
import 'package:orbweaver/widgets/blocks/table_block_view.dart';
import 'package:orbweaver/widgets/flowchart/cascade_flowchart_view.dart';
import 'package:orbweaver/widgets/flowchart/flowchart_view.dart';

/// Top-level renderer for a [Topic].
///
/// Renders each [TopicPage] in order, separated by a subtle divider
/// carrying the next page's printed page number. [pageKeys] is attached
/// to each page's container so [TopicFrame] can measure page positions
/// for the sticky page-number badge in the app bar.
class TopicView extends StatelessWidget {
  const TopicView({
    required this.topic,
    this.palette = const {},
    this.pageKeys = const [],
    super.key,
  });

  final Topic topic;

  /// Fully-resolved color palette (book → chapter → topic cascade), passed
  /// in when the topic is opened from a book. Empty for a standalone topic,
  /// in which case it is resolved from the topic's own `palette:` over the
  /// defaults.
  final Map<String, Color> palette;

  /// One key per entry in [Topic.pages]. Pass an empty list to skip
  /// key attachment (e.g., when the caller doesn't track scroll).
  final List<GlobalKey> pageKeys;

  @override
  Widget build(BuildContext context) {
    final resolved = palette.isNotEmpty
        ? palette
        : resolvePalette([
            {
              for (final e in topic.ownPaletteArgb.entries) e.key: Color(e.value),
            },
          ]);
    final theme = TopicTheme(resolved);
    return TopicThemeScope(
      theme: theme,
      child: ColoredBox(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < topic.pages.length; i++)
              KeyedSubtree(
                key: i < pageKeys.length ? pageKeys[i] : null,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Divider is inside page i's keyed subtree (for i > 0)
                    // so the key's top == divider top. The header badge
                    // flips to page i as soon as the divider reaches the
                    // viewport top.
                    if (i > 0)
                      _PageBreak(pageNumber: topic.pages[i].pageNumber),
                    for (var j = 0; j < topic.pages[i].blocks.length; j++) ...[
                      if (j > 0) const SizedBox(height: 16),
                      _BlockRenderer(
                        block: topic.pages[i].blocks[j],
                        theme: theme,
                      ),
                    ],
                  ],
                ),
              ),
          ],
        ),
      ),
      ),
    );
  }
}

/// Visual break between two pages of the same topic. Renders as hairline
/// rules on either side of the next page's number.
class _PageBreak extends StatelessWidget {
  const _PageBreak({required this.pageNumber});

  final int? pageNumber;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Row(
        children: [
          const Expanded(child: Divider(color: Colors.black26, height: 1)),
          if (pageNumber != null) ...[
            const SizedBox(width: 10),
            Text(
              'Page $pageNumber',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.black54,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(width: 10),
          ],
          const Expanded(child: Divider(color: Colors.black26, height: 1)),
        ],
      ),
    );
  }
}

class _BlockRenderer extends StatelessWidget {
  const _BlockRenderer({required this.block, required this.theme});

  final Block block;
  final TopicTheme theme;

  @override
  Widget build(BuildContext context) {
    return switch (block) {
      final ProseBlock b => ProseBlockView(block: b, theme: theme),
      final FlowchartBlock b => _FlowchartBlockRenderer(block: b, theme: theme),
      final TableBlock b => TableBlockView(block: b, theme: theme),
      final DrugCardBlock b => DrugCardBlockView(block: b, theme: theme),
      final ImageBlock b => ImageBlockView(block: b, theme: theme),
      final RowBlock b => _RowBlockRenderer(block: b, theme: theme),
      final ColumnBlock b => _ColumnBlockRenderer(block: b, theme: theme),
      final ArrowsBlock b => _ArrowsBlockRenderer(block: b),
      final MergeArrowsBlock b => _MergeArrowsRenderer(block: b),
    };
  }
}

class _ColumnBlockRenderer extends StatelessWidget {
  const _ColumnBlockRenderer({required this.block, required this.theme});

  final ColumnBlock block;
  final TopicTheme theme;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < block.blocks.length; i++) ...[
          if (i > 0) const SizedBox(height: 6),
          _BlockRenderer(block: block.blocks[i], theme: theme),
        ],
      ],
    );
  }
}

class _ArrowsBlockRenderer extends StatelessWidget {
  const _ArrowsBlockRenderer({required this.block});

  final ArrowsBlock block;

  @override
  Widget build(BuildContext context) {
    if (block.direction == ArrowDirection.right) {
      return Center(
        child: FlowRightArrow(length: block.length, label: block.label),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          for (var i = 0; i < block.count; i++)
            Expanded(
              child: Center(
                child: FlowDownArrow(
                  label: block.label,
                  length: block.length,
                  inline: block.inline,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MergeArrowsRenderer extends StatelessWidget {
  const _MergeArrowsRenderer({required this.block});

  final MergeArrowsBlock block;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final cellW = width / block.columns;
          // Center-of-column x coordinates for each source.
          final sourceXs = block.sources
              .map((c) => (c + 0.5) * cellW)
              .toList()
            ..sort();
          final lineStart = sourceXs.first;
          final lineEnd = sourceXs.last;
          // targetCenter is a fractional column index; +0.5 lands the
          // arrow at the center of that column (or halfway between two
          // columns for a fractional value like 2.5).
          final targetX = (block.targetCenter + 0.5) * cellW;

          const topArrowLen = 10.0;
          const bottomArrowLen = 14.0;
          const lineGap = 2.0;
          const stubLen = 6.0;
          const totalHeight =
              topArrowLen + lineGap + stubLen + bottomArrowLen + 4;

          return SizedBox(
            height: totalHeight,
            child: Stack(
              children: [
                for (final x in sourceXs)
                  Positioned(
                    top: 0,
                    left: x - 6,
                    child: const FlowDownArrow(length: topArrowLen),
                  ),
                Positioned(
                  top: topArrowLen + lineGap,
                  left: lineStart,
                  width: lineEnd - lineStart,
                  height: 1,
                  child: Container(color: Colors.black54),
                ),
                Positioned(
                  top: topArrowLen + lineGap,
                  left: targetX - 0.5,
                  height: stubLen,
                  width: 1,
                  child: Container(color: Colors.black54),
                ),
                Positioned(
                  top: topArrowLen + lineGap + stubLen,
                  left: targetX - 6,
                  child: const FlowDownArrow(),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _RowBlockRenderer extends StatelessWidget {
  const _RowBlockRenderer({required this.block, required this.theme});

  final RowBlock block;
  final TopicTheme theme;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < block.blocks.length; i++) ...[
            if (i > 0) const SizedBox(width: 6),
            Expanded(
              flex: block.blocks[i].flex,
              child: _BlockRenderer(block: block.blocks[i], theme: theme),
            ),
          ],
        ],
      ),
    );
  }
}

class _FlowchartBlockRenderer extends StatelessWidget {
  const _FlowchartBlockRenderer({required this.block, required this.theme});

  final FlowchartBlock block;
  final TopicTheme theme;

  @override
  Widget build(BuildContext context) {
    return switch (block.variant) {
      FlowchartVariant.severity => SeverityFlowchartView(
          flowchart: block.severity!,
          theme: theme,
        ),
      FlowchartVariant.cascade => CascadeFlowchartView(
          flowchart: block.cascade!,
          theme: theme,
        ),
      FlowchartVariant.linear => LinearFlowchartView(
          flowchart: block.linear!,
          theme: theme,
        ),
      FlowchartVariant.differential => DifferentialFlowchartView(
          flowchart: block.differential!,
          theme: theme,
        ),
    };
  }
}
