import 'package:flutter/material.dart';
import 'package:orbweaver/models/topic.dart';
import 'package:orbweaver/theme/topic_theme.dart';
import 'package:orbweaver/widgets/flowchart/branch_column.dart';
import 'package:orbweaver/widgets/flowchart/dose_table.dart';
import 'package:orbweaver/widgets/flowchart/flow_node.dart';
import 'package:orbweaver/widgets/flowchart/warning_callouts.dart';

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

    final safety = fc.warnings
        .where((w) => w.type == WarningType.safety)
        .cast<WarningCallout?>()
        .firstWhere((_) => true, orElse: () => null);
    final caution = fc.warnings
        .where((w) => w.type == WarningType.caution)
        .cast<WarningCallout?>()
        .firstWhere((_) => true, orElse: () => null);
    final hasWarnings = safety != null || caution != null;

    for (var i = 0; i < fc.entryChain.length; i++) {
      final node = fc.entryChain[i];
      // The first entry node gets the warning callouts as side flanks
      // when any warnings are declared on the flowchart.
      if (i == 0 && hasWarnings) {
        rows.add(_EntryWithWarnings(
          safety: safety,
          caution: caution,
          entry: node,
          theme: theme,
        ));
      } else {
        rows.add(
          FlowNodeBox(text: node.text, shape: node.shape, theme: theme),
        );
      }
      // Skip the arrow after the very last pre-branch node — the fork row
      // below handles that transition (one arrow per branch column).
      final isLastPreBranch =
          i == fc.entryChain.length - 1 && fc.decision == null;
      if (!isLastPreBranch) rows.add(const FlowDownArrow());
    }

    if (fc.decision != null) {
      // A diamond decision with multiple branches renders as a single
      // DecisionHub that draws the diamond + L-shape arrows to each
      // branch in one CustomPaint — arrows then originate at the
      // diamond's actual points rather than a shared bottom tip.
      if (fc.decision!.shape == NodeShape.diamond &&
          fc.branches.length > 1) {
        rows.add(
          DecisionHub(
            text: fc.decision!.text,
            branchCount: fc.branches.length,
          ),
        );
      } else {
        rows.add(
          FlowNodeBox(
            text: fc.decision!.text,
            shape: fc.decision!.shape,
            theme: theme,
          ),
        );
        if (fc.branches.length > 1) {
          rows.add(_ForkArrows(count: fc.branches.length));
        } else {
          rows.add(const FlowDownArrow());
        }
      }
    } else {
      if (fc.branches.length > 1) {
        rows.add(_ForkArrows(count: fc.branches.length));
      } else {
        rows.add(const FlowDownArrow());
      }
    }

    // Branch columns extend their last action down to the bottom of the
    // (intrinsic-height-stretched) row when the next row is a convergence
    // hub — keeps the L-arrow visibly continuous from the action tile.
    final branchesExtendDown = fc.convergence != null &&
        !useLoopbackLayout &&
        (fc.branches.length == 2 || fc.branches.length == 3);
    rows.add(_BranchesRow(
      branches: fc.branches,
      theme: theme,
      extendDown: branchesExtendDown,
    ));

    // Asymmetric branch continuations: render continuation nodes below
    // the branches row, anchored in the source branch's column.
    final anyContinuation =
        fc.branches.any((b) => b.continuation != null);
    if (anyContinuation && fc.branches.length == 2) {
      _appendBranchContinuations(rows, fc.branches);
    }

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
        if (fc.branches.length == 2 || fc.branches.length == 3) {
          rows.add(
            _ConvergenceHub(
              node: fc.convergence!,
              theme: theme,
              branchCount: fc.branches.length,
            ),
          );
        } else {
          rows.add(_ParallelDownArrows(count: fc.branches.length));
          rows.add(_ConvergenceBox(node: fc.convergence!, theme: theme));
        }
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
      rows.add(const SizedBox(height: 18));
      rows.add(DoseTable(rows: fc.doseTable, theme: theme));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: rows,
    );
  }

  void _appendBranchContinuations(
    List<Widget> rows,
    List<TopicBranch> branches,
  ) {
    final leftCont = branches[0].continuation;
    final rightCont = branches[1].continuation;

    if (leftCont != null && rightCont != null) {
      _appendDualContinuations(rows, leftCont, rightCont);
    } else if (leftCont != null) {
      _appendSingleContinuation(rows, leftCont);
    } else if (rightCont != null) {
      _appendSingleContinuation(rows, rightCont);
    }
  }

  /// The single-branch case: render continuation nodes full-width below
  /// the branches row, since there's only one flow line to follow.
  void _appendSingleContinuation(
    List<Widget> rows,
    BranchContinuation cont,
  ) {
    rows.add(FlowDownArrow(label: cont.entryArrowLabel));
    for (var i = 0; i < cont.nodes.length; i++) {
      final node = cont.nodes[i];
      rows.add(
        FlowNodeBox(text: node.text, shape: node.shape, theme: theme),
      );
      if (i < cont.nodes.length - 1) rows.add(const FlowDownArrow());
    }
  }

  /// The rare case where both branches have continuations — keep the
  /// two-column layout so each branch's continuation stays in its column.
  void _appendDualContinuations(
    List<Widget> rows,
    BranchContinuation leftCont,
    BranchContinuation rightCont,
  ) {
    final leftNodes = leftCont.nodes;
    final rightNodes = rightCont.nodes;

    rows.add(
      _TwoColumn(
        left: Center(child: FlowDownArrow(label: leftCont.entryArrowLabel)),
        right: Center(child: FlowDownArrow(label: rightCont.entryArrowLabel)),
      ),
    );

    final maxNodes = leftNodes.length > rightNodes.length
        ? leftNodes.length
        : rightNodes.length;
    for (var i = 0; i < maxNodes; i++) {
      rows.add(
        _TwoColumn(
          left: i < leftNodes.length
              ? FlowNodeBox(
                  text: leftNodes[i].text,
                  shape: leftNodes[i].shape,
                  theme: theme,
                )
              : const SizedBox.shrink(),
          right: i < rightNodes.length
              ? FlowNodeBox(
                  text: rightNodes[i].text,
                  shape: rightNodes[i].shape,
                  theme: theme,
                )
              : const SizedBox.shrink(),
        ),
      );
      if (i < maxNodes - 1) {
        rows.add(
          _TwoColumn(
            left: i + 1 < leftNodes.length
                ? const Center(child: FlowDownArrow())
                : const SizedBox.shrink(),
            right: i + 1 < rightNodes.length
                ? const Center(child: FlowDownArrow())
                : const SizedBox.shrink(),
          ),
        );
      }
    }
  }
}

// ─────────────────────────────────────────────────────────────
// Row helpers
// ─────────────────────────────────────────────────────────────

/// N parallel vertical arrows — one centred in each branch column.
/// Used between the branch row and the convergence "Consider" oval.
class _ParallelDownArrows extends StatelessWidget {
  const _ParallelDownArrows({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        for (var i = 0; i < count; i++) ...[
          if (i > 0) const SizedBox(width: kSeverityBranchGap),
          const Expanded(child: Center(child: FlowDownArrow(length: 18))),
        ],
      ],
    );
  }
}

/// Fan-out arrows radiating from a single point at top-center (the
/// bottom tip of the centered decision diamond) to the column centre
/// of each branch below. Drawn as a single [CustomPaint] so the lines
/// are true diagonals — not stepped pixel-aligned paths.
class _ForkArrows extends StatelessWidget {
  const _ForkArrows({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 22,
      child: CustomPaint(
        size: Size.infinite,
        painter: _FanArrowsPainter(count: count),
      ),
    );
  }
}

class _FanArrowsPainter extends CustomPainter {
  const _FanArrowsPainter({required this.count});

  final int count;

  @override
  void paint(Canvas canvas, Size size) {
    final line = Paint()
      ..color = Colors.black87
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    final fill = Paint()
      ..color = Colors.black87
      ..style = PaintingStyle.fill;

    final origin = Offset(size.width / 2, 0);
    for (var i = 0; i < count; i++) {
      // Branch column centres: 1/(2n), 3/(2n), …, (2n-1)/(2n) of width.
      final frac = (2 * i + 1) / (2 * count);
      final tip = Offset(size.width * frac, size.height);
      // Shorten slightly so the triangular head sits at the tip.
      final direction = tip - origin;
      final length = direction.distance;
      final unit = direction / length;
      final shaftEnd = tip - unit * 6;
      canvas.drawLine(origin, shaftEnd, line);
      // Triangle head oriented along the line.
      final perp = Offset(-unit.dy, unit.dx) * 4;
      final head = Path()
        ..moveTo(tip.dx, tip.dy)
        ..lineTo(shaftEnd.dx + perp.dx, shaftEnd.dy + perp.dy)
        ..lineTo(shaftEnd.dx - perp.dx, shaftEnd.dy - perp.dy)
        ..close();
      canvas.drawPath(head, fill);
    }
  }

  @override
  bool shouldRepaint(_FanArrowsPainter old) => old.count != count;
}

/// Top row of a flowchart that has warning callouts: a safety octagon
/// on the left, the entry stadium centred, and a caution parallelogram
/// on the right. Either flank may be null — the slot stays empty so
/// the entry stays centred relative to the row.
class _EntryWithWarnings extends StatelessWidget {
  const _EntryWithWarnings({
    required this.safety,
    required this.caution,
    required this.entry,
    required this.theme,
  });

  final WarningCallout? safety;
  final WarningCallout? caution;
  final FlowNode entry;
  final TopicTheme theme;

  @override
  Widget build(BuildContext context) {
    return Padding(
      // Breathing room between the AppBar (or whatever sits above) and
      // the warning row — the rectangular callouts otherwise read as
      // stuck to the header.
      padding: const EdgeInsets.only(top: 10),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              flex: 22,
              child: safety != null
                  ? SafetyOctagon(text: safety!.text)
                  : const SizedBox.shrink(),
            ),
            const SizedBox(width: 4),
            Expanded(
              flex: 56,
              child: FlowNodeBox(
                text: entry.text,
                shape: entry.shape,
                theme: theme,
                fillWidth: true,
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              flex: 22,
              child: caution != null
                  ? CautionCallout(text: caution!.text)
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
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
        const SizedBox(width: kSeverityBranchGap),
        Expanded(child: right),
      ],
    );
  }
}

class _BranchesRow extends StatelessWidget {
  const _BranchesRow({
    required this.branches,
    required this.theme,
    this.extendDown = false,
  });

  final List<TopicBranch> branches;
  final TopicTheme theme;
  final bool extendDown;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < branches.length; i++) ...[
            if (i > 0) const SizedBox(width: kSeverityBranchGap),
            Expanded(
              child: BranchColumn(
                branch: branches[i],
                theme: theme,
                extendDown: extendDown,
              ),
            ),
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
          const SizedBox(width: kSeverityBranchGap),
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

/// Three-branch convergence: centred stadium + L-arrows coming in from
/// each branch column. Left arrow turns right into the stadium's left
/// edge, right arrow mirrors, middle arrow drops straight into the top.
///
/// Arrows are drawn in a [CustomPaint] behind the stadium so any part of
/// an arrow that would pass through the stadium is covered by its fill.
class _ConvergenceHub extends StatelessWidget {
  const _ConvergenceHub({
    required this.node,
    required this.theme,
    required this.branchCount,
  });

  final ConvergenceNode node;
  final TopicTheme theme;
  final int branchCount;

  static const double _arrowExtension = 22;

  /// Width factor of the centre stadium relative to the row.  We use
  /// the same 0.55 for both 2- and 3-branch so the convergence has
  /// enough horizontal room for typical bullet content (HTN, Seizure,
  /// Overdose all overflow at narrower factors).  The L-arrows still
  /// land cleanly because the painter computes stadium edges from
  /// this factor.
  static double _stadiumWidthFactorFor(int branchCount) => 0.55;

  @override
  Widget build(BuildContext context) {
    final widthFactor = _stadiumWidthFactorFor(branchCount);
    return Stack(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: _arrowExtension),
            Center(
              child: FractionallySizedBox(
                widthFactor: widthFactor,
                child: _ConvergenceBox(node: node, theme: theme),
              ),
            ),
          ],
        ),
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(
              painter: _ConvergenceArrowsPainter(
                branchCount: branchCount,
                arrowExtension: _arrowExtension,
                stadiumWidthFactor: widthFactor,
                columnGap: kSeverityBranchGap,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ConvergenceArrowsPainter extends CustomPainter {
  const _ConvergenceArrowsPainter({
    required this.branchCount,
    required this.arrowExtension,
    required this.stadiumWidthFactor,
    this.columnGap = 0,
  });

  final int branchCount;
  final double arrowExtension;
  final double stadiumWidthFactor;
  final double columnGap;

  @override
  void paint(Canvas canvas, Size size) {
    final line = Paint()
      ..color = Colors.black87
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    final fillPaint = Paint()
      ..color = Colors.black87
      ..style = PaintingStyle.fill;

    final w = size.width;
    final stadiumTop = arrowExtension;
    final stadiumMidY = (stadiumTop + size.height) / 2;
    final stadiumLeftEdge = w * (1 - stadiumWidthFactor) / 2;
    final stadiumRightEdge = w - stadiumLeftEdge;

    void arrowHead(Offset tip, Offset unit) {
      final perp = Offset(-unit.dy, unit.dx) * 4;
      final base = tip - unit * 6;
      final head = Path()
        ..moveTo(tip.dx, tip.dy)
        ..lineTo(base.dx + perp.dx, base.dy + perp.dy)
        ..lineTo(base.dx - perp.dx, base.dy - perp.dy)
        ..close();
      canvas.drawPath(head, fillPaint);
    }

    // Column centres must match `_BranchesRow`: each column slot is
    // (W − (n−1)·gap)/n wide, with the gap between adjacent slots.
    final slotW = (w - (branchCount - 1) * columnGap) / branchCount;
    final centers = [
      for (var i = 0; i < branchCount; i++)
        i * (slotW + columnGap) + slotW / 2,
    ];

    // Centre arrow only when a column sits directly above the stadium
    // (odd branch count).
    if (branchCount == 3) {
      final midPath = Path()
        ..moveTo(centers[1], 0)
        ..lineTo(centers[1], stadiumTop);
      canvas.drawPath(midPath, line);
      arrowHead(Offset(centers[1], stadiumTop), const Offset(0, 1));
    }

    // Left — down to stadium mid-height, then right into the left edge.
    final leftPath = Path()
      ..moveTo(centers.first, 0)
      ..lineTo(centers.first, stadiumMidY)
      ..lineTo(stadiumLeftEdge, stadiumMidY);
    canvas.drawPath(leftPath, line);
    arrowHead(Offset(stadiumLeftEdge, stadiumMidY), const Offset(1, 0));

    // Right — mirror.
    final rightPath = Path()
      ..moveTo(centers.last, 0)
      ..lineTo(centers.last, stadiumMidY)
      ..lineTo(stadiumRightEdge, stadiumMidY);
    canvas.drawPath(rightPath, line);
    arrowHead(Offset(stadiumRightEdge, stadiumMidY), const Offset(-1, 0));
  }

  @override
  bool shouldRepaint(_ConvergenceArrowsPainter old) =>
      old.branchCount != branchCount ||
      old.arrowExtension != arrowExtension ||
      old.stadiumWidthFactor != stadiumWidthFactor ||
      old.columnGap != columnGap;
}

/// Pale green stadium matching the WVEMS "Consider" terminator. Bullets
/// with a `link_id` render underlined to signal they're cross-links.
class _ConvergenceBox extends StatelessWidget {
  const _ConvergenceBox({required this.node, required this.theme});

  final ConvergenceNode node;
  final TopicTheme theme;

  static const Color _fill = Color(0xFFD5ECD6);

  @override
  Widget build(BuildContext context) {
    // Border radius 28 (not 999 / true stadium): a true semicircular
    // end clips text whose width approaches the box width — and our
    // narrow convergence stadium (0.4 / 0.55 of row width) regularly
    // takes 2-3 lines of bullets that brush the curve. The 28 px
    // radius reads as a soft pill while keeping a rectangular text
    // safe-zone the full inner width.
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      decoration: BoxDecoration(
        color: _fill,
        border: Border.all(color: Colors.black87, width: 1.5),
        borderRadius: BorderRadius.circular(28),
      ),
      alignment: Alignment.center,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            node.text,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (node.bullets.isNotEmpty) ...[
            const SizedBox(height: 2),
            for (final b in node.bullets)
              Text.rich(
                TextSpan(
                  children: [
                    const TextSpan(text: '• '),
                    TextSpan(
                      text: b.text,
                      style: TextStyle(
                        decoration: b.linkId != null
                            ? TextDecoration.underline
                            : null,
                      ),
                    ),
                  ],
                ),
                style: const TextStyle(fontSize: 14, height: 1.2),
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
    this.length = 14,
    this.inline = false,
    super.key,
  });

  /// Text rendered to the LEFT of the arrow.
  final String? label;

  /// Text rendered to the RIGHT of the arrow. When both [label] and
  /// [labelAfter] are set, the arrow becomes a glyph in the middle of the
  /// phrase — e.g. `No  ▼  change`.
  final String? labelAfter;

  final double length;

  /// When true with a single [label], the label renders horizontally
  /// beside the arrow (label on the left, arrow on the right) instead
  /// of stacked above it.  Saves a line of vertical space when the
  /// arrow is floating in a layout with no other content on its line.
  final bool inline;

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
    } else if (hasBefore && hasAfter) {
      // Both labels — inline, arrow in the middle ("No ▼ change").
      content = Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(label!, style: _arrowLabelStyle),
          const SizedBox(width: 6),
          arrow,
          const SizedBox(width: 6),
          Text(labelAfter!, style: _arrowLabelStyle),
        ],
      );
    } else if (hasBefore) {
      if (inline) {
        // Label beside the arrow — label on left, glyph on right.
        content = Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(label!, style: _arrowLabelStyle),
            const SizedBox(width: 4),
            arrow,
          ],
        );
      } else {
        // Single leading label — stack label above the arrow.
        content = Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(label!, style: _arrowLabelStyle),
            const SizedBox(height: 1),
            arrow,
          ],
        );
      }
    } else {
      // Single trailing label — stack label below the arrow.
      content = Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          arrow,
          const SizedBox(height: 1),
          Text(labelAfter!, style: _arrowLabelStyle),
        ],
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
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
  const FlowUpArrow({this.label, this.length = 14, super.key});

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
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Center(child: content),
    );
  }
}

class FlowRightArrow extends StatelessWidget {
  const FlowRightArrow({this.length = 18, this.label, super.key});

  final double length;

  /// Optional label rendered centered above the arrow glyph.
  final String? label;

  @override
  Widget build(BuildContext context) {
    final arrow = CustomPaint(
      size: Size(length, 12),
      painter: const _HorizontalArrowPainter(pointing: _Dir.right),
    );
    if (label == null) return arrow;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label!, style: _arrowLabelStyle),
        const SizedBox(height: 1),
        arrow,
      ],
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
