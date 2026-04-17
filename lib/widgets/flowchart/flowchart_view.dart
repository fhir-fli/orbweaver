import 'package:flutter/material.dart';
import 'package:orbweaver/models/topic.dart';
import 'package:orbweaver/theme/topic_theme.dart';
import 'package:orbweaver/widgets/flowchart/branch_column.dart';
import 'package:orbweaver/widgets/flowchart/dose_table.dart';
import 'package:orbweaver/widgets/flowchart/flow_node.dart';

/// Severity-variant flowchart renderer — grid-of-widgets layout.
///
/// Each transition in the flow is its own widget (arrow glyphs are small
/// `CustomPaint`s for crisp lines + triangles). Rows arrange those arrow
/// widgets into columns that line up with the branches they attach to.
/// No GlobalKeys, no post-frame callbacks, no coordinate measurement —
/// Flutter's normal Row/Column layout does the positioning.
///
/// Row sequence (when a convergence loopback is declared):
///   entry-chain nodes + ▼ between each
///   decision node (optional) + ▼
///   branches row              [Red    | Yellow ]
///   branch-exit row           [ ▼     |   ▲    ]   ← target column gets ▲
///   convergence + waypoint    [Reassess |  →  Improvement]
///   post-convergence exit row [ No change ▼ |  ▲ ]
///   post-convergence box
///
/// Without a loopback, the renderer falls back to a single-column stack.
class SeverityFlowchartView extends StatelessWidget {
  const SeverityFlowchartView({
    required this.flowchart,
    required this.theme,
    super.key,
  });

  final SeverityFlowchart flowchart;
  final TopicTheme theme;

  @override
  Widget build(BuildContext context) {
    final fc = flowchart;
    final exits = fc.convergence?.exits ?? const <ConvergenceExit>[];
    final loopback = exits
        .where((e) => e.loopbackBranchId != null)
        .cast<ConvergenceExit?>()
        .firstWhere((_) => true, orElse: () => null);
    final forwardExits =
        exits.where((e) => e.loopbackBranchId == null).toList();

    final loopbackTargetIdx = loopback == null
        ? -1
        : fc.branches.indexWhere((b) => b.id == loopback.loopbackBranchId);

    final useLoopbackLayout = loopback != null &&
        loopbackTargetIdx >= 0 &&
        fc.branches.length == 2;

    final rows = <Widget>[];

    for (var i = 0; i < fc.entryChain.length; i++) {
      final node = fc.entryChain[i];
      rows.add(FlowNodeBox(text: node.text, shape: node.shape, theme: theme));
      // Skip the arrow after the very last pre-branch node — the fork row
      // below handles that transition (one arrow per branch column).
      final isLastPreBranch =
          i == fc.entryChain.length - 1 && fc.decision == null;
      if (!isLastPreBranch) rows.add(const FlowDownArrow());
    }

    if (fc.decision != null) {
      rows.add(
        FlowNodeBox(
          text: fc.decision!.text,
          shape: fc.decision!.shape,
          theme: theme,
        ),
      );
      // No arrow here — fork row handles the split.
    }

    if (fc.branches.length > 1) {
      rows.add(_ForkArrows(count: fc.branches.length));
    } else {
      rows.add(const FlowDownArrow());
    }

    rows.add(_BranchesRow(branches: fc.branches, theme: theme));

    if (fc.convergence != null) {
      if (useLoopbackLayout) {
        rows.add(
          _TwoColumn(
            left: loopbackTargetIdx == 0
                ? const Center(child: FlowUpArrow())
                : const Center(child: FlowDownArrow()),
            right: loopbackTargetIdx == 1
                ? const Center(child: FlowUpArrow())
                : const Center(child: FlowDownArrow()),
          ),
        );
        rows.add(
          _ConvergenceWithWaypointRow(
            convergence: fc.convergence!,
            waypointLabel: loopback.label,
            theme: theme,
          ),
        );
        if (fc.postConvergence != null) {
          final noChange = forwardExits.isNotEmpty
              ? forwardExits.first.label
              : 'No change';
          final parts = noChange.split(RegExp(r'\s+'));
          final before = parts.isNotEmpty ? parts.first : noChange;
          final after = parts.length >= 2 ? parts.sublist(1).join(' ') : null;
          rows.add(
            _TwoColumn(
              left: Center(
                child: FlowDownArrow(label: before, labelAfter: after),
              ),
              right: const Center(child: FlowUpArrow()),
            ),
          );
          rows.add(
            FlowNodeBox(
              text: fc.postConvergence!.text,
              shape: fc.postConvergence!.shape,
              theme: theme,
            ),
          );
        }
      } else {
        rows.add(const FlowDownArrow());
        rows.add(_ConvergenceBox(node: fc.convergence!, theme: theme));
        for (final exit in forwardExits) {
          rows.add(FlowDownArrow(label: exit.label));
        }
        if (fc.postConvergence != null) {
          rows.add(
            FlowNodeBox(
              text: fc.postConvergence!.text,
              shape: fc.postConvergence!.shape,
              theme: theme,
            ),
          );
        }
      }
    }

    if (fc.doseTable.isNotEmpty) {
      rows.add(DoseTable(rows: fc.doseTable, theme: theme));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: rows,
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Row helpers
// ─────────────────────────────────────────────────────────────

/// One centered down-arrow per branch column, so the fork looks like
/// parallel arrows splitting into each branch rather than a single
/// centered arrow.
class _ForkArrows extends StatelessWidget {
  const _ForkArrows({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        for (var i = 0; i < count; i++) ...[
          if (i > 0) const SizedBox(width: 4),
          const Expanded(child: Center(child: FlowDownArrow())),
        ],
      ],
    );
  }
}

/// Two equal-width children in a Row — so the column divisions line up
/// across the branch, exit-arrow, and post-convergence rows.
class _TwoColumn extends StatelessWidget {
  const _TwoColumn({required this.left, required this.right});

  final Widget left;
  final Widget right;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(child: left),
        const SizedBox(width: 4),
        Expanded(child: right),
      ],
    );
  }
}

class _BranchesRow extends StatelessWidget {
  const _BranchesRow({required this.branches, required this.theme});

  final List<TopicBranch> branches;
  final TopicTheme theme;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < branches.length; i++) ...[
            if (i > 0) const SizedBox(width: 4),
            Expanded(child: BranchColumn(branch: branches[i], theme: theme)),
          ],
        ],
      ),
    );
  }
}

/// Convergence box on the left half + waypoint pill on the right half,
/// connected by a short right-pointing arrow sitting in the gutter
/// between them.
class _ConvergenceWithWaypointRow extends StatelessWidget {
  const _ConvergenceWithWaypointRow({
    required this.convergence,
    required this.waypointLabel,
    required this.theme,
  });

  final ConvergenceNode convergence;
  final String waypointLabel;
  final TopicTheme theme;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _ConvergenceBox(node: convergence, theme: theme),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Row(
              children: [
                const SizedBox(
                  width: 18,
                  child: Center(child: FlowRightArrow(length: 16)),
                ),
                Expanded(child: _ImprovementWaypoint(label: waypointLabel)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Content boxes
// ─────────────────────────────────────────────────────────────

class _ConvergenceBox extends StatelessWidget {
  const _ConvergenceBox({required this.node, required this.theme});

  final ConvergenceNode node;
  final TopicTheme theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: theme.nodeFill,
        border: Border.all(color: theme.nodeBorder, width: 1.5),
      ),
      alignment: Alignment.center,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            node.text,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (node.bullets.isNotEmpty) ...[
            const SizedBox(height: 2),
            for (final b in node.bullets)
              Text(
                '• ${b.text}',
                style: const TextStyle(fontSize: 12, height: 1.2),
              ),
          ],
        ],
      ),
    );
  }
}

class _ImprovementWaypoint extends StatelessWidget {
  const _ImprovementWaypoint({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFDE7),
        border: Border.all(color: const Color(0xFFF9A825), width: 1.5),
        borderRadius: BorderRadius.circular(999),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: Color(0xFF5D4037),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Arrow widgets — self-contained, line + triangle via CustomPaint.
// Size is intrinsic; no positioning math anywhere in this file.
// ─────────────────────────────────────────────────────────────

class FlowDownArrow extends StatelessWidget {
  const FlowDownArrow({
    this.label,
    this.labelAfter,
    this.length = 22,
    super.key,
  });

  /// Text rendered to the LEFT of the arrow.
  final String? label;

  /// Text rendered to the RIGHT of the arrow. When both [label] and
  /// [labelAfter] are set, the arrow becomes a glyph in the middle of the
  /// phrase — e.g. `No  ▼  change`.
  final String? labelAfter;

  final double length;

  @override
  Widget build(BuildContext context) {
    final arrow = CustomPaint(
      size: Size(12, length),
      painter: const _VerticalArrowPainter(pointing: _Dir.down),
    );
    final hasBefore = label != null;
    final hasAfter = labelAfter != null;

    final Widget content;
    if (!hasBefore && !hasAfter) {
      content = arrow;
    } else {
      content = Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (hasBefore) ...[
            Text(label!, style: _arrowLabelStyle),
            const SizedBox(width: 6),
          ],
          arrow,
          if (hasAfter) ...[
            const SizedBox(width: 6),
            Text(labelAfter!, style: _arrowLabelStyle),
          ],
        ],
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Center(child: content),
    );
  }
}

const _arrowLabelStyle = TextStyle(
  fontSize: 12,
  fontWeight: FontWeight.w700,
  color: Colors.black87,
);

class FlowUpArrow extends StatelessWidget {
  const FlowUpArrow({this.label, this.length = 22, super.key});

  final String? label;
  final double length;

  @override
  Widget build(BuildContext context) {
    final arrow = CustomPaint(
      size: Size(12, length),
      painter: const _VerticalArrowPainter(pointing: _Dir.up),
    );
    final content = label == null
        ? arrow
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              arrow,
              const SizedBox(width: 6),
              Text(
                label!,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
            ],
          );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Center(child: content),
    );
  }
}

class FlowRightArrow extends StatelessWidget {
  const FlowRightArrow({this.length = 18, super.key});

  final double length;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(length, 12),
      painter: const _HorizontalArrowPainter(pointing: _Dir.right),
    );
  }
}

enum _Dir { up, down, left, right }

class _VerticalArrowPainter extends CustomPainter {
  const _VerticalArrowPainter({required this.pointing});

  final _Dir pointing;

  @override
  void paint(Canvas canvas, Size size) {
    final line = Paint()
      ..color = Colors.black87
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    final fill = Paint()
      ..color = Colors.black87
      ..style = PaintingStyle.fill;

    final cx = size.width / 2;

    if (pointing == _Dir.down) {
      canvas.drawLine(Offset(cx, 0), Offset(cx, size.height - 5), line);
      final head = Path()
        ..moveTo(cx, size.height)
        ..lineTo(cx - 4, size.height - 6)
        ..lineTo(cx + 4, size.height - 6)
        ..close();
      canvas.drawPath(head, fill);
    } else {
      canvas.drawLine(Offset(cx, size.height), Offset(cx, 5), line);
      final head = Path()
        ..moveTo(cx, 0)
        ..lineTo(cx - 4, 6)
        ..lineTo(cx + 4, 6)
        ..close();
      canvas.drawPath(head, fill);
    }
  }

  @override
  bool shouldRepaint(_VerticalArrowPainter old) => old.pointing != pointing;
}

class _HorizontalArrowPainter extends CustomPainter {
  const _HorizontalArrowPainter({required this.pointing});

  final _Dir pointing;

  @override
  void paint(Canvas canvas, Size size) {
    final line = Paint()
      ..color = Colors.black87
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    final fill = Paint()
      ..color = Colors.black87
      ..style = PaintingStyle.fill;

    final cy = size.height / 2;

    if (pointing == _Dir.right) {
      canvas.drawLine(Offset(0, cy), Offset(size.width - 5, cy), line);
      final head = Path()
        ..moveTo(size.width, cy)
        ..lineTo(size.width - 6, cy - 4)
        ..lineTo(size.width - 6, cy + 4)
        ..close();
      canvas.drawPath(head, fill);
    } else {
      canvas.drawLine(Offset(size.width, cy), Offset(5, cy), line);
      final head = Path()
        ..moveTo(0, cy)
        ..lineTo(6, cy - 4)
        ..lineTo(6, cy + 4)
        ..close();
      canvas.drawPath(head, fill);
    }
  }

  @override
  bool shouldRepaint(_HorizontalArrowPainter old) =>
      old.pointing != pointing;
}
