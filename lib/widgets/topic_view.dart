import 'package:flutter/material.dart';
import 'package:orbweaver/models/topic.dart';
import 'package:orbweaver/theme/topic_theme.dart';
import 'package:orbweaver/widgets/blocks/drug_card_block_view.dart';
import 'package:orbweaver/widgets/blocks/image_block_view.dart';
import 'package:orbweaver/widgets/blocks/prose_block_view.dart';
import 'package:orbweaver/widgets/blocks/table_block_view.dart';
import 'package:orbweaver/widgets/flowchart/cascade_flowchart_view.dart';
import 'package:orbweaver/widgets/flowchart/flowchart_view.dart';

/// Top-level renderer for a [Topic].
///
/// Renders a category-coloured header followed by a vertical stack of
/// block renderers (one per [Block] in [Topic.blocks]). Every block type
/// has a concrete case — the sealed [Block] hierarchy guarantees this
/// switch stays exhaustive.
class TopicView extends StatelessWidget {
  const TopicView({required this.topic, super.key});

  final Topic topic;

  @override
  Widget build(BuildContext context) {
    final theme = TopicTheme.of(topic.category);
    return ColoredBox(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _TopicHeader(topic: topic, theme: theme),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final block in topic.blocks)
                  _BlockRenderer(block: block, theme: theme),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TopicHeader extends StatelessWidget {
  const _TopicHeader({required this.topic, required this.theme});

  final Topic topic;
  final TopicTheme theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      color: theme.header,
      alignment: Alignment.centerLeft,
      child: Row(
        children: [
          if (topic.pageNumber != null) ...[
            Container(
              width: 24,
              height: 22,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(3),
              ),
              child: Text(
                '${topic.pageNumber}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: theme.header,
                ),
              ),
            ),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Text(
              topic.title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
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
    };
  }
}
