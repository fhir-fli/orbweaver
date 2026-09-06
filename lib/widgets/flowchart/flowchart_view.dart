import 'package:flutter/material.dart';
import 'package:orbweaver/data/library_scope.dart';
import 'package:orbweaver/models/topic.dart';
import 'package:orbweaver/theme/topic_theme.dart';
import 'package:orbweaver/widgets/flowchart/branch_column.dart';
import 'package:orbweaver/widgets/flowchart/cc_link_pill.dart';
import 'package:orbweaver/widgets/flowchart/dose_table.dart';
import 'package:orbweaver/widgets/flowchart/flow_link.dart';
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
    final forwardExits = exits
        .where((e) => e.loopbackBranchId == null)
        .toList();

    final loopbackTargetIdx = loopback == null
        ? -1
        : fc.branches.indexWhere((b) => b.id == loopback.loopbackBranchId);

    final useLoopbackLayout =
        loopback != null && loopbackTargetIdx >= 0 && fc.branches.length == 2;

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

    // Breathing room above the first flowchart object. _EntryWithWarnings
    // adds its own top padding, so only insert this leading gap when the
    // flowchart starts with a plain entry node.
    if (!hasWarnings) rows.add(const SizedBox(height: 6));

    for (var i = 0; i < fc.entryChain.length; i++) {
      final node = fc.entryChain[i];
      // The first entry node gets the warning callouts as side flanks
      // when any warnings are declared on the flowchart.
      if (i == 0 && hasWarnings) {
        rows.add(
          _EntryWithWarnings(
            safety: safety,
            caution: caution,
            entry: node,
            theme: theme,
          ),
        );
      } else {
        rows.add(
          FlowNodeBox(
            text: node.text,
            shape: node.shape,
            theme: theme,
            bands: node.bands,
            ccTitle: node.ccTitle,
          ),
        );
      }
      // Skip the arrow after the very last pre-branch node — the fork row
      // below handles that transition (one arrow per branch column).
      // When pre-decision actions or a decision follow, the loop's
      // trailing arrow flows into them instead.
      final isLastPreBranch =
          i == fc.entryChain.length - 1 &&
          fc.decision == null &&
          fc.preDecisionActions.isEmpty;
      if (!isLastPreBranch) rows.add(const FlowDownArrow());
    }

    if (fc.preDecisionActions.isNotEmpty) {
      rows.add(
        _PreDecisionActions(actions: fc.preDecisionActions, theme: theme),
      );
      rows.add(const FlowDownArrow());
    }

    if (fc.decision != null) {
      // A diamond decision with multiple branches renders as a single
      // DecisionHub that draws the diamond + L-shape arrows to each
      // branch in one CustomPaint — arrows then originate at the
      // diamond's actual points rather than a shared bottom tip.
      if (fc.decision!.shape == NodeShape.diamond && fc.branches.length > 1) {
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
    // Convergence side-warnings replace the hub with a callout-flanked
    // stadium (no L-arrows), so the fill line isn't needed there.
    final convHasWarnings = fc.convergence?.warnings.isNotEmpty ?? false;
    final branchesExtendDown =
        fc.convergence != null &&
        !useLoopbackLayout &&
        !convHasWarnings &&
        (fc.branches.length == 2 || fc.branches.length == 3);
    rows.add(
      _BranchesRow(
        branches: fc.branches,
        theme: theme,
        extendDown: branchesExtendDown,
      ),
    );

    // Asymmetric branch continuations: render continuation nodes below
    // the branches row, anchored in the source branch's column.
    final anyContinuation = fc.branches.any((b) => b.continuation != null);
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
            _PostConvergence(node: fc.postConvergence!, theme: theme),
          );
        }
      } else {
        final conv = fc.convergence!;
        final convSafety = conv.warnings
            .where((w) => w.type == WarningType.safety)
            .cast<WarningCallout?>()
            .firstWhere((_) => true, orElse: () => null);
        final convCaution = conv.warnings
            .where((w) => w.type == WarningType.caution)
            .cast<WarningCallout?>()
            .firstWhere((_) => true, orElse: () => null);
        final hasConvWarnings = convSafety != null || convCaution != null;
        if (hasConvWarnings) {
          // Side callouts replace the L-arrow hub: this preserves the
          // clinical content (e.g. "Ensure Patient DECON",
          // "Consider Destination Triage") at the cost of the L-arrows
          // from the branch columns.
          rows.add(_ParallelDownArrows(count: fc.branches.length));
          rows.add(
            _ConvergenceWithWarnings(
              safety: convSafety,
              caution: convCaution,
              node: conv,
              theme: theme,
            ),
          );
        } else if (fc.branches.length == 2 || fc.branches.length == 3) {
          rows.add(
            _ConvergenceHub(
              node: conv,
              theme: theme,
              branchCount: fc.branches.length,
            ),
          );
        } else {
          rows.add(_ParallelDownArrows(count: fc.branches.length));
          rows.add(_ConvergenceBox(node: conv, theme: theme));
        }
        for (final exit in forwardExits) {
          rows.add(FlowDownArrow(label: exit.label));
        }
        if (fc.postConvergence != null) {
          rows.add(
            _PostConvergence(node: fc.postConvergence!, theme: theme),
          );
        }
      }

      if (fc.criticalCareLink != null) {
        rows.add(CriticalCareLinkPill(link: fc.criticalCareLink!));
      }
    }

    if (fc.doseTable.isNotEmpty) {
      rows.add(const SizedBox(height: 8));
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
        FlowNodeBox(
          text: node.text,
          shape: node.shape,
          theme: theme,
          bands: node.bands,
          ccTitle: node.ccTitle,
        ),
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
/// on the left, the entry stadium centred, and a caution trapezoid
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
              // Stack the entry stadium on top of an extension line that
              // fills the row's leftover height (when the warning
              // callouts make the row taller than the stadium). The
              // FlowDownArrow that follows _EntryWithWarnings provides
              // the arrowhead — together they read as one continuous
              // arrow originating at the stadium's bottom.
              child: Column(
                mainAxisSize: MainAxisSize.max,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  FlowNodeBox(
                    text: entry.text,
                    shape: entry.shape,
                    theme: theme,
                    fillWidth: true,
                    bands: entry.bands,
                    ccTitle: entry.ccTitle,
                  ),
                  Expanded(
                    child: Center(
                      child: Container(width: 1.5, color: Colors.black87),
                    ),
                  ),
                ],
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

/// Mirror of [_EntryWithWarnings] for the convergence stadium: the
/// `_ConvergenceBox` is centered between an optional safety octagon on
/// the left and an optional caution trapezoid on the right.
///
/// Used by both the linear and severity renderers whenever a
/// [ConvergenceNode] carries `warnings`.  When the severity convergence
/// has warnings we use this layout instead of [_ConvergenceHub] — the
/// L-arrow visualization is traded for the side callouts, which carry
/// real clinical content (e.g. "Ensure Patient DECON") and shouldn't be
/// folded into a Consider bullet.
class _ConvergenceWithWarnings extends StatelessWidget {
  const _ConvergenceWithWarnings({
    required this.safety,
    required this.caution,
    required this.node,
    required this.theme,
  });

  final WarningCallout? safety;
  final WarningCallout? caution;
  final ConvergenceNode node;
  final TopicTheme theme;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
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
            child: _ConvergenceBox(node: node, theme: theme),
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
    // If any branch is a `continues: true` arrow-only stub, fall back to
    // the legacy single-Column-per-branch layout — those branches don't
    // have criteria/action structure to align across.
    if (branches.any((b) => b.continues)) {
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

    // Split layout: one IntrinsicHeight Row of criteria boxes (equalises
    // header heights across columns), then a row of small connector
    // arrows, then an IntrinsicHeight Row of action stacks. This makes
    // the first action tile in each branch land at the same Y, even
    // when criteria text wraps differently between columns.
    final paletteFor = _resolvePalettes(theme, branches);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < branches.length; i++) ...[
                if (i > 0) const SizedBox(width: kSeverityBranchGap),
                Expanded(
                  child: BranchHeaderBox(
                    label: branches[i].label,
                    criteria: branches[i].criteria,
                    headerBg: paletteFor[i]?.headerBg,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (branches.any((b) => b.actions.isNotEmpty))
          Row(
            children: [
              for (var i = 0; i < branches.length; i++) ...[
                if (i > 0) const SizedBox(width: kSeverityBranchGap),
                Expanded(
                  child: branches[i].actions.isNotEmpty
                      ? const Padding(
                          padding: EdgeInsets.symmetric(vertical: 2),
                          child: Center(child: FlowDownArrow(length: 10)),
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ],
          ),
        // LayoutBuilder sits *above* the IntrinsicHeight so it is never
        // asked for intrinsic dimensions (which it can't answer). It
        // measures each branch column's width once and hands it to
        // ActionTile, which derives its own label budget — so the label
        // can shrink-to-fit without a LayoutBuilder nested inside the
        // tile's own IntrinsicHeight.
        LayoutBuilder(
          builder: (context, constraints) {
            final n = branches.length;
            final colW =
                (constraints.maxWidth - (n - 1) * kSeverityBranchGap) / n;
            return IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var i = 0; i < branches.length; i++) ...[
                    if (i > 0) const SizedBox(width: kSeverityBranchGap),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          for (final action in branches[i].actions)
                            ActionTile(
                              action: action,
                              theme: theme,
                              tileBg: paletteFor[i]?.tileBg,
                              columnWidth: colW,
                            ),
                          if (extendDown && branches[i].continuation == null)
                            const Expanded(child: TrailingFillLine()),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

/// Resolve each branch's optional severity palette into the (headerBg,
/// tileBg) pair used by the renderer. Mirrors the logic inside
/// [BranchColumn] so the split-row layout produces the same colours.
List<({Color? headerBg, Color? tileBg})?> _resolvePalettes(
  TopicTheme theme,
  List<TopicBranch> branches,
) {
  return branches.map<({Color? headerBg, Color? tileBg})?>((b) {
    return switch (b.severity) {
      RowSeverity.none => null,
      RowSeverity.emergency => (
        headerBg: theme.severitySevereHeader,
        tileBg: theme.severitySevereTile,
      ),
      RowSeverity.priority => (
        headerBg: theme.severityModerateHeader,
        tileBg: theme.severityModerateTile,
      ),
      RowSeverity.nonUrgent => (
        headerBg: theme.severityMildHeader,
        tileBg: theme.severityMildTile,
      ),
    };
  }).toList();
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

  static const double _arrowExtension = 8;

  /// Width factor of the centre stadium relative to the row.  Narrow
  /// (0.4 for 2-branch, 0.55 for 3-branch) so the L-arrows from each
  /// branch column have a visible horizontal jog to the pill edge.
  /// Wider stadiums squash the arrows into near-vertical stubs.
  /// Bullets that don't fit on one line are allowed to wrap; the pill
  /// auto-grows vertically because `_ConvergenceBox` is a shrink-wrap
  /// Container around a `MainAxisSize.min` Column.
  static double _stadiumWidthFactorFor(int branchCount) =>
      branchCount >= 3 ? 0.55 : 0.4;

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
      for (var i = 0; i < branchCount; i++) i * (slotW + columnGap) + slotW / 2,
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

  @override
  Widget build(BuildContext context) {
    // Border radius 28 (not 999 / true stadium): a true semicircular
    // end clips text whose width approaches the box width — and our
    // narrow convergence stadium (0.4 / 0.55 of row width) regularly
    // takes 2-3 lines of bullets that brush the curve. The 28 px
    // radius reads as a soft pill while keeping a rectangular text
    // safe-zone the full inner width.
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 5),
      decoration: BoxDecoration(
        color: theme.flowConvergence,
        border: Border.all(color: Colors.black87, width: 1.5),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          FlowLinkText(
            node.text,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (node.bullets.isNotEmpty) ...[
            const SizedBox(height: 8),
            for (final b in node.bullets) _bullet(context, b),
          ],
        ],
      ),
    );
  }

  /// One convergence bullet.
  ///
  /// Two ways to carry a cross-reference, because the print uses both. A
  /// bullet whose whole text is one reference takes `link_id`; a bullet that
  /// packs several — p.34's "Fever, Pain, Nausea" is three links, to pp.16, 20
  /// and 22 — writes them inline (see [flowLinkPattern]). Either way the
  /// reference is underlined, and tapping degrades to a no-op when it doesn't
  /// resolve.
  Widget _bullet(BuildContext context, ConvergenceBullet b) {
    const style = TextStyle(fontSize: 14, height: 1.2);
    if (hasFlowLink(b.text)) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: style),
          Flexible(
            child: FlowLinkText(b.text, style: style),
          ),
        ],
      );
    }
    final text = Text.rich(
      TextSpan(
        children: [
          const TextSpan(text: '• '),
          TextSpan(
            text: b.text,
            style: TextStyle(
              decoration: b.linkId != null ? TextDecoration.underline : null,
            ),
          ),
        ],
      ),
      textAlign: TextAlign.center,
      style: style,
    );
    if (b.linkId == null) return text;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => openLinkedTopic(context, b.linkId!),
      child: text,
    );
  }
}

/// A centred vertical stack of action tiles rendered between the entry
/// chain and the decision diamond (WVEMS "pre-decision" interventions,
/// e.g. Altered LOC's Glucometer / 12-Lead / Saline Lock). Tiles keep
/// their provider badges (gray placeholder for `any`) so the E/A/I
/// column lines up, matching the single bordered box in the PDF.
class _PreDecisionActions extends StatelessWidget {
  const _PreDecisionActions({required this.actions, required this.theme});

  final List<TopicAction> actions;
  final TopicTheme theme;

  static const double _widthFactor = 0.55;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: FractionallySizedBox(
        widthFactor: _widthFactor,
        // LayoutBuilder sits above the tiles' own IntrinsicHeight, so it
        // can measure the stack width and feed each tile's label-fit.
        child: LayoutBuilder(
          builder: (context, constraints) {
            final colW = constraints.maxWidth;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final action in actions)
                  ActionTile(
                    action: action,
                    theme: theme,
                    columnWidth: colW,
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Lavender pill for a Critical Care protocol cross-reference, matching
/// the WVEMS PDF (e.g. Abdominal Pain → "Sepsis"). Sits below the green
/// "Consider" terminator. Shrink-wraps its text and underlines it to
/// echo the convergence-bullet cross-link cue. Colours come from the
/// shared Critical Care palette (lavender fill, purple border).
/// Renders a flowchart's `post_convergence` node. With bullets it reads
/// as a second green "Consider"-style terminator (e.g. Sedation / Vent:
/// branches → Ventilator → Consider · Airway / Vasopressors); without
/// bullets it's a plain themed node box (e.g. Airway → Intubation).
class _PostConvergence extends StatelessWidget {
  const _PostConvergence({required this.node, required this.theme});

  final ConvergenceNode node;
  final TopicTheme theme;

  static const double _widthFactor = 0.55;

  @override
  Widget build(BuildContext context) {
    if (node.bullets.isNotEmpty) {
      return Center(
        child: FractionallySizedBox(
          widthFactor: _widthFactor,
          child: _ConvergenceBox(node: node, theme: theme),
        ),
      );
    }
    return FlowNodeBox(text: node.text, shape: node.shape, theme: theme);
  }
}

class _ImprovementWaypoint extends StatelessWidget {
  const _ImprovementWaypoint({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = TopicThemeScope.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      decoration: BoxDecoration(
        color: theme.noteFill,
        border: Border.all(color: theme.noteBorder, width: 1.5),
        borderRadius: BorderRadius.circular(999),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: theme.noteText,
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
    return Center(child: content);
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
    return Center(child: content);
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
  bool shouldRepaint(_HorizontalArrowPainter old) => old.pointing != pointing;
}

/// Renderer for [FlowchartVariant.linear] — a single-column flow
/// `entry → step → step → … → Consider`.  Steps are either content
/// boxes (titled white box with bullets — same visual primitive as a
/// branch criteria box, reused via [BranchHeaderBox]) or action tiles
/// (reused via [ActionTile]).  Warnings flank the first entry node
/// just like in the severity variant; convergence + post-convergence
/// + dose-table follow.
///
/// Linear nodes are centered at a 0.55 width factor — matching the
/// entry stadium width factor used by [FlowNodeBox] — so the column
/// of nodes reads as a coherent vertical track.
class LinearFlowchartView extends StatelessWidget {
  const LinearFlowchartView({
    required this.flowchart,
    required this.theme,
    super.key,
  });

  final LinearFlowchart flowchart;
  final TopicTheme theme;

  /// Same as the entry-stadium width factor in [FlowNodeBox]; keeps all
  /// linear nodes (action tiles, content boxes, entry boxes, convergence)
  /// aligned in one centered column.
  static const double _nodeWidthFactor = 0.55;

  @override
  Widget build(BuildContext context) {
    final fc = flowchart;
    final safety = fc.warnings
        .where((w) => w.type == WarningType.safety)
        .cast<WarningCallout?>()
        .firstWhere((_) => true, orElse: () => null);
    final caution = fc.warnings
        .where((w) => w.type == WarningType.caution)
        .cast<WarningCallout?>()
        .firstWhere((_) => true, orElse: () => null);
    final hasWarnings = safety != null || caution != null;

    final rows = <Widget>[];

    if (!hasWarnings) rows.add(const SizedBox(height: 6));

    // Entry chain — first node flanked by warnings (if any), rest stack
    // with a FlowDownArrow between each.  Matches the severity layout.
    for (var i = 0; i < fc.entryChain.length; i++) {
      final node = fc.entryChain[i];
      if (i == 0 && hasWarnings) {
        rows.add(
          _EntryWithWarnings(
            safety: safety,
            caution: caution,
            entry: node,
            theme: theme,
          ),
        );
      } else {
        rows.add(
          FlowNodeBox(
            text: node.text,
            shape: node.shape,
            theme: theme,
            bands: node.bands,
            ccTitle: node.ccTitle,
          ),
        );
      }
      rows.add(const FlowDownArrow());
    }

    // Steps — alternating mix of content boxes and action tiles.  We
    // measure the content width once via a LayoutBuilder placed above
    // the steps (not inside any IntrinsicHeight — see [_FitText] note)
    // so each ActionTile can derive its label budget.
    if (fc.steps.isNotEmpty) {
      rows.add(
        LayoutBuilder(
          builder: (context, constraints) {
            final colW = constraints.maxWidth * _nodeWidthFactor;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < fc.steps.length; i++) ...[
                  _LinearStepRow(
                    step: fc.steps[i],
                    theme: theme,
                    widthFactor: _nodeWidthFactor,
                    columnWidth: colW,
                  ),
                  if (i < fc.steps.length - 1) const FlowDownArrow(),
                ],
              ],
            );
          },
        ),
      );
    }

    if (fc.convergence != null) {
      rows.add(const FlowDownArrow());
      final conv = fc.convergence!;
      final convSafety = conv.warnings
          .where((w) => w.type == WarningType.safety)
          .cast<WarningCallout?>()
          .firstWhere((_) => true, orElse: () => null);
      final convCaution = conv.warnings
          .where((w) => w.type == WarningType.caution)
          .cast<WarningCallout?>()
          .firstWhere((_) => true, orElse: () => null);
      if (convSafety != null || convCaution != null) {
        rows.add(
          _ConvergenceWithWarnings(
            safety: convSafety,
            caution: convCaution,
            node: conv,
            theme: theme,
          ),
        );
      } else {
        rows.add(
          Center(
            child: FractionallySizedBox(
              widthFactor: _nodeWidthFactor,
              child: _ConvergenceBox(node: conv, theme: theme),
            ),
          ),
        );
      }
    }

    if (fc.postConvergence != null) {
      rows.add(const FlowDownArrow());
      rows.add(
        _PostConvergence(node: fc.postConvergence!, theme: theme),
      );
    }

    if (fc.criticalCareLink != null) {
      rows.add(CriticalCareLinkPill(link: fc.criticalCareLink!));
    }

    if (fc.doseTable.isNotEmpty) {
      rows.add(const SizedBox(height: 8));
      rows.add(DoseTable(rows: fc.doseTable, theme: theme));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: rows,
    );
  }
}

/// One linear step — dispatches on [LinearStep] subtype to render either
/// a content box (via [BranchHeaderBox]) or an action tile (via
/// [ActionTile]).  Centered at [widthFactor] of the available width to
/// match the rest of the linear column.
class _LinearStepRow extends StatelessWidget {
  const _LinearStepRow({
    required this.step,
    required this.theme,
    required this.widthFactor,
    required this.columnWidth,
  });

  final LinearStep step;
  final TopicTheme theme;
  final double widthFactor;
  final double columnWidth;

  @override
  Widget build(BuildContext context) {
    final Widget body = switch (step) {
      LinearContentStep(:final title, :final bullets) => BranchHeaderBox(
        label: title,
        criteria: bullets,
      ),
      LinearActionStep(:final action) => ActionTile(
        action: action,
        theme: theme,
        columnWidth: columnWidth,
        omitAnyBadge: true,
      ),
    };
    return Center(
      child: FractionallySizedBox(widthFactor: widthFactor, child: body),
    );
  }
}

/// Renderer for [FlowchartVariant.differential] — entry → decision →
/// N-column grid of referential cards → optional convergence.  Each
/// card is a titled box with bullets (same primitive as a branch
/// criteria box, reused via `BranchHeaderBox`).  The user reads the
/// card matching their patient's situation; cards don't carry action
/// tiles, so downstream actions live in the convergence's bullets or
/// the dose_table.
class DifferentialFlowchartView extends StatelessWidget {
  const DifferentialFlowchartView({
    required this.flowchart,
    required this.theme,
    super.key,
  });

  final DifferentialFlowchart flowchart;
  final TopicTheme theme;

  @override
  Widget build(BuildContext context) {
    final fc = flowchart;
    final safety = fc.warnings
        .where((w) => w.type == WarningType.safety)
        .cast<WarningCallout?>()
        .firstWhere((_) => true, orElse: () => null);
    final caution = fc.warnings
        .where((w) => w.type == WarningType.caution)
        .cast<WarningCallout?>()
        .firstWhere((_) => true, orElse: () => null);
    final hasWarnings = safety != null || caution != null;

    final rows = <Widget>[];

    if (!hasWarnings) rows.add(const SizedBox(height: 6));

    // Entry chain — same flow as the other variants.
    for (var i = 0; i < fc.entryChain.length; i++) {
      final node = fc.entryChain[i];
      if (i == 0 && hasWarnings) {
        rows.add(
          _EntryWithWarnings(
            safety: safety,
            caution: caution,
            entry: node,
            theme: theme,
          ),
        );
      } else {
        rows.add(
          FlowNodeBox(
            text: node.text,
            shape: node.shape,
            theme: theme,
            bands: node.bands,
            ccTitle: node.ccTitle,
          ),
        );
      }
      // Skip the arrow after the very last entry node only when the
      // diamond follows immediately — its own incoming arrow handles
      // that. When pre-decision actions sit between, keep the arrow so
      // it flows entry → actions.
      final isLastBeforeDiamond =
          i == fc.entryChain.length - 1 &&
          fc.decision != null &&
          fc.preDecisionActions.isEmpty;
      if (!isLastBeforeDiamond) rows.add(const FlowDownArrow());
    }

    if (fc.preDecisionActions.isNotEmpty) {
      rows.add(
        _PreDecisionActions(actions: fc.preDecisionActions, theme: theme),
      );
    }

    if (fc.decision != null) {
      rows.add(const FlowDownArrow());
      rows.add(
        FlowNodeBox(
          text: fc.decision!.text,
          shape: fc.decision!.shape,
          theme: theme,
        ),
      );
      rows.add(const FlowDownArrow());
    }

    // Card grid — cards chunked into rows of [columns] each.
    if (fc.cards.isNotEmpty) {
      final cols = fc.columns < 1 ? 1 : fc.columns;
      for (var i = 0; i < fc.cards.length; i += cols) {
        final rowCards = fc.cards.sublist(
          i,
          (i + cols).clamp(0, fc.cards.length),
        );
        rows.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var c = 0; c < rowCards.length; c++) ...[
                    if (c > 0) const SizedBox(width: 6),
                    Expanded(
                      child: BranchHeaderBox(
                        label: rowCards[c].title,
                        criteria: rowCards[c].bullets,
                      ),
                    ),
                  ],
                  // Pad short final row with blank slots so cards keep
                  // their column width when the card count isn't a
                  // multiple of [columns].
                  for (var pad = rowCards.length; pad < cols; pad++) ...[
                    const SizedBox(width: 6),
                    const Expanded(child: SizedBox.shrink()),
                  ],
                ],
              ),
            ),
          ),
        );
      }
    }

    if (fc.convergence != null) {
      rows.add(const FlowDownArrow());
      final conv = fc.convergence!;
      final convSafety = conv.warnings
          .where((w) => w.type == WarningType.safety)
          .cast<WarningCallout?>()
          .firstWhere((_) => true, orElse: () => null);
      final convCaution = conv.warnings
          .where((w) => w.type == WarningType.caution)
          .cast<WarningCallout?>()
          .firstWhere((_) => true, orElse: () => null);
      if (convSafety != null || convCaution != null) {
        rows.add(
          _ConvergenceWithWarnings(
            safety: convSafety,
            caution: convCaution,
            node: conv,
            theme: theme,
          ),
        );
      } else {
        rows.add(
          Center(
            child: FractionallySizedBox(
              widthFactor: 0.55,
              child: _ConvergenceBox(node: conv, theme: theme),
            ),
          ),
        );
      }
    }

    if (fc.postConvergence != null) {
      rows.add(const FlowDownArrow());
      rows.add(_PostConvergence(node: fc.postConvergence!, theme: theme));
    }

    if (fc.criticalCareLink != null) {
      rows.add(CriticalCareLinkPill(link: fc.criticalCareLink!));
    }

    if (fc.doseTable.isNotEmpty) {
      rows.add(const SizedBox(height: 8));
      rows.add(DoseTable(rows: fc.doseTable, theme: theme));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: rows,
    );
  }
}
