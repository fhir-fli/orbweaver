import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:orbweaver/models/topic.dart';
import 'package:orbweaver/theme/topic_theme.dart';
import 'package:orbweaver/widgets/flowchart/fit_text.dart';

/// Renders a `variant: cycle` flowchart — a genuinely cyclic clinical
/// algorithm (reassessment loop, titration, resuscitation cycle).
///
/// Layout: a centred vertical spine of nodes (boxes + one or more decision
/// diamonds). A decision may spawn [CycleBranch] boxes to its left/right,
/// each optionally carrying a `loopTo` back-edge — a return arrow routed up
/// the margin to an earlier spine node (the re-assessment hub). The decision
/// also flows straight DOWN to the next spine node (the loop's exit), labelled
/// by [CycleNode.downLabel] (e.g. "once stable").
///
/// Because clinical flows are reducible (loops are always back-edges to an
/// ancestor on the main line), a single spine + side-routed back-edges covers
/// the whole loop taxonomy without a 2-D graph engine. See
/// [FlowchartVariant.cycle].
class CycleFlowchartView extends StatelessWidget {
  const CycleFlowchartView({
    required this.flowchart,
    required this.theme,
    super.key,
  });

  final CycleFlowchart flowchart;
  final TopicTheme theme;

  // ── Grid + sizing constants (tuned visually). ─────────────────────────
  static const int _cols = 12;
  static const double _boxColsWide = 6.6; // plain spine box width (cols)
  static const double _boxColsBranched =
      4.2; // spine box that has side branches
  static const double _decisionCols = 3.6; // decision diamond width (cols)
  static const double _branchCols = 2.9; // side branch box width (cols)
  static const double _bandGap = 30; // vertical gap between spine bands
  static const double _labelFont = 11.5;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth;
        final colW = w / _cols;
        final cx = w / 2;
        final layout = _CycleLayout(flowchart, colW: colW, cx: cx, width: w);

        final children = <Widget>[
          // All connectors first (behind the nodes).
          Positioned.fill(
            child: CustomPaint(
              painter: _CyclePainter(layout: layout, fill: theme.flowDecision),
            ),
          ),
        ];

        // Spine nodes.
        for (var i = 0; i < layout.nodes.length; i++) {
          final n = flowchart.nodes[i];
          final r = layout.nodes[i];
          children.add(
            Positioned(
              left: r.left,
              top: r.top,
              width: r.width,
              child: n.shape == CycleNodeShape.decision
                  ? _Diamond(
                      text: n.title,
                      width: r.width,
                      height: r.height,
                      fill: theme.flowDecision,
                      border: theme.nodeBorder,
                    )
                  : _NodeBox(
                      title: n.title,
                      bullets: n.bullets,
                      severity: n.severity,
                      theme: theme,
                      isHub: n.id != null,
                    ),
            ),
          );
        }

        // Branch boxes + their edge labels.
        for (final b in layout.branches) {
          children.add(
            Positioned(
              left: b.rect.left,
              top: b.rect.top,
              width: b.rect.width,
              child: _NodeBox(
                title: b.branch.box.title,
                bullets: b.branch.box.bullets,
                severity: b.branch.box.severity,
                theme: theme,
                isHub: false,
              ),
            ),
          );
        }

        // Edge labels (branch labels, loop labels, down labels) as positioned
        // text so they wrap cleanly.
        for (final lbl in layout.labels) {
          children.add(
            Positioned(
              left: lbl.left,
              top: lbl.top,
              width: lbl.width,
              child: Align(
                alignment: lbl.center ? Alignment.center : Alignment.centerLeft,
                child: Text(
                  lbl.text,
                  textAlign: lbl.center ? TextAlign.center : TextAlign.left,
                  style: const TextStyle(
                    fontSize: _labelFont,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
              ),
            ),
          );
        }

        return SizedBox(
          width: w,
          height: layout.totalHeight,
          child: Stack(clipBehavior: Clip.none, children: children),
        );
      },
    );
  }
}

// ───────────────────────────────────────────────────────────────────────
// Layout computation
// ───────────────────────────────────────────────────────────────────────

class _NodeRect {
  const _NodeRect(this.left, this.top, this.width, this.height);
  final double left;
  final double top;
  final double width;
  final double height;
  double get right => left + width;
  double get bottom => top + height;
  double get cx => left + width / 2;
}

class _BranchLayout {
  const _BranchLayout(this.branch, this.rect, this.parentIndex);
  final CycleBranch branch;
  final _NodeRect rect;
  final int parentIndex;
}

class _EdgeLabel {
  const _EdgeLabel(
    this.text,
    this.left,
    this.top,
    this.width, {
    this.center = false,
  });
  final String text;
  final double left;
  final double top;
  final double width;
  final bool center;
}

/// Computes rects for every spine node, branch box, connector and label.
class _CycleLayout {
  _CycleLayout(
    this.fc, {
    required this.colW,
    required this.cx,
    required this.width,
  }) {
    _compute();
  }

  final CycleFlowchart fc;
  final double colW;
  final double cx;
  final double width;

  final List<_NodeRect> nodes = [];
  final List<_BranchLayout> branches = [];
  final List<_EdgeLabel> labels = [];
  double totalHeight = 0;

  double get _boxW => colW * CycleFlowchartView._boxColsWide;
  double get _boxBranchedW => colW * CycleFlowchartView._boxColsBranched;
  double get _decW => colW * CycleFlowchartView._decisionCols;
  double get _branchW => colW * CycleFlowchartView._branchCols;

  void _compute() {
    var y = 0.0;
    for (var i = 0; i < fc.nodes.length; i++) {
      final n = fc.nodes[i];
      final isDecision = n.shape == CycleNodeShape.decision;
      // A box with side branches is narrowed so the branches (and their
      // Yes/No labels) clear it.
      final nodeW = isDecision
          ? _decW
          : (n.branches.isNotEmpty ? _boxBranchedW : _boxW);
      final nodeH = isDecision
          ? _diamondHeight(n.title)
          : _boxHeight(n.title, n.bullets, nodeW);

      // Branch heights (same band as the node).
      final branchHeights = <double>[
        for (final b in n.branches)
          _boxHeight(b.box.title, b.box.bullets, _branchW),
      ];
      final bandH = [nodeH, ...branchHeights].reduce(math.max);

      final nodeTop = y + (bandH - nodeH) / 2;
      // Centre on the spine — but if a box node's branches are all on ONE side,
      // shift it away from that side (into the otherwise-wasted margin) so the
      // branch and its label get more room.
      var nodeLeft = cx - nodeW / 2;
      if (!isDecision && n.branches.isNotEmpty) {
        final sides = {for (final b in n.branches) b.side};
        if (sides.length == 1) {
          final shift = colW * 1.15;
          nodeLeft += sides.first == CycleSide.right ? -shift : shift;
        }
      }
      nodes.add(_NodeRect(nodeLeft, nodeTop, nodeW, nodeH));

      // Place branches L/R of the node.
      for (var bi = 0; bi < n.branches.length; bi++) {
        final b = n.branches[bi];
        final bh = branchHeights[bi];
        final left = b.side == CycleSide.left
            ? colW * 0.1
            : width - _branchW - colW * 0.1;
        branches.add(
          _BranchLayout(
            b,
            _NodeRect(left, y + (bandH - bh) / 2, _branchW, bh),
            i,
          ),
        );
      }

      y += bandH + CycleFlowchartView._bandGap;
    }
    totalHeight = y - CycleFlowchartView._bandGap + 8;

    _buildLabels();
  }

  void _buildLabels() {
    // Branch labels sit centred on the horizontal node→branch arrow. The gap
    // is often narrow, so give them a fixed width centred on the gap midpoint
    // (short "Yes"/"No" text may overflow a few px onto the white boxes — fine).
    const branchLabelW = 36.0;
    for (final bl in branches) {
      final node = nodes[bl.parentIndex];
      final left = bl.branch.side == CycleSide.left;
      final midY =
          math.max(node.top, bl.rect.top) +
          math.min(node.height, bl.rect.height) / 2;
      final gapMid = left
          ? (node.left + bl.rect.right) / 2
          : (node.right + bl.rect.left) / 2;
      labels.add(
        _EdgeLabel(
          bl.branch.label,
          gapMid - branchLabelW / 2,
          midY - 17,
          branchLabelW,
          center: true,
        ),
      );
    }

    // Down labels on spine exit arrows (e.g. a decision's "once stable" exit).
    for (var i = 0; i < fc.nodes.length - 1; i++) {
      final dl = fc.nodes[i].downLabel;
      if (dl == null) continue;
      final a = nodes[i];
      final bnode = nodes[i + 1];
      final gapMid = (a.bottom + bnode.top) / 2 - 8;
      labels.add(_EdgeLabel(dl, cx + 8, gapMid, width / 2 - 12));
    }
  }

  // Height estimates (generous, so intrinsic boxes never exceed their band).
  double _boxHeight(String title, List<String> bullets, double boxW) {
    final cplT = math.max(6, (boxW - 18) / 6.7);
    final cplB = math.max(6, (boxW - 26) / 6.1);
    final titleLines = math.max(1, (title.length / cplT).ceil());
    var bulletLines = 0;
    for (final b in bullets) {
      bulletLines += math.max(1, (b.length / cplB).ceil());
    }
    return 12 +
        titleLines * 15.5 +
        bulletLines * 14.0 +
        (bullets.isNotEmpty ? 3 : 0);
  }

  double _diamondHeight(String text) {
    final lines = (text.length / 15).ceil().clamp(2, 4);
    return (34 + lines * 15).toDouble();
  }
}

// ───────────────────────────────────────────────────────────────────────
// Painter — draws every connector
// ───────────────────────────────────────────────────────────────────────

class _CyclePainter extends CustomPainter {
  const _CyclePainter({required this.layout, required this.fill});
  final _CycleLayout layout;
  final Color fill;

  @override
  void paint(Canvas canvas, Size size) {
    final nodes = layout.nodes;

    // 1. Spine down-arrows between consecutive nodes (skip if the current
    //    node is a decision — its down exit is drawn from the bottom point).
    for (var i = 0; i < nodes.length - 1; i++) {
      final a = nodes[i];
      final b = nodes[i + 1];
      _arrow(canvas, [Offset(a.cx, a.bottom), Offset(b.cx, b.top)]);
    }

    // 2. Node → branch arrows, and branch → hub return risers.
    for (final bl in layout.branches) {
      final node = nodes[bl.parentIndex];
      final br = bl.rect;
      final left = bl.branch.side == CycleSide.left;
      final y =
          math.max(node.top, br.top) + math.min(node.height, br.height) / 2;

      // node side → branch inner side
      if (left) {
        _arrow(canvas, [Offset(node.left, y), Offset(br.right, y)]);
      } else {
        _arrow(canvas, [Offset(node.right, y), Offset(br.left, y)]);
      }

      // return riser: up from the branch's TOP-CENTRE, then elbow INWARD into
      // the hub node's side (loopTo).
      final target = bl.branch.loopTo == null
          ? -1
          : layout.fc.indexOfId(bl.branch.loopTo!);
      if (target >= 0) {
        final hub = nodes[target];
        final startX = br.cx;
        final hubSideY = hub.top + hub.height * 0.5;
        final into = left ? hub.left : hub.right;
        _arrow(canvas, [
          Offset(startX, br.top),
          Offset(startX, hubSideY),
          Offset(into, hubSideY),
        ]);
      }
    }
  }

  void _arrow(Canvas canvas, List<Offset> pts) {
    final stroke = Paint()
      ..color = Colors.black87
      ..strokeWidth = 1.7
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round;
    final path = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (final p in pts.skip(1)) {
      path.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(path, stroke);
    // Arrowhead at the last point, oriented along the last segment.
    final tip = pts.last;
    final prev = pts[pts.length - 2];
    final dir = tip - prev;
    final len = dir.distance == 0 ? 1 : dir.distance;
    final ux = dir.dx / len;
    final uy = dir.dy / len;
    // perpendicular
    final px = -uy;
    final py = ux;
    const s = 6.0;
    const back = 8.0;
    final base = Offset(tip.dx - ux * back, tip.dy - uy * back);
    canvas.drawPath(
      Path()
        ..moveTo(tip.dx, tip.dy)
        ..lineTo(base.dx + px * s, base.dy + py * s)
        ..lineTo(base.dx - px * s, base.dy - py * s)
        ..close(),
      Paint()..color = Colors.black87,
    );
  }

  @override
  bool shouldRepaint(_CyclePainter old) => old.layout != layout;
}

// ───────────────────────────────────────────────────────────────────────
// Node widgets
// ───────────────────────────────────────────────────────────────────────

class _NodeBox extends StatelessWidget {
  const _NodeBox({
    required this.title,
    required this.bullets,
    required this.severity,
    required this.theme,
    required this.isHub,
  });
  final String title;
  final List<String> bullets;
  final RowSeverity severity;
  final TopicTheme theme;
  final bool isHub;

  @override
  Widget build(BuildContext context) {
    final fill = _sevFill(theme, severity);
    final border = _sevBorder(theme, severity) ?? theme.nodeBorder;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: fill ?? (isHub ? theme.flowEntry : Colors.white),
        border: Border.all(color: border, width: isHub ? 1.5 : 1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              height: 1.15,
            ),
          ),
          for (final b in bullets)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                '•  $b',
                style: const TextStyle(fontSize: 11, height: 1.2),
              ),
            ),
        ],
      ),
    );
  }
}

class _Diamond extends StatelessWidget {
  const _Diamond({
    required this.text,
    required this.width,
    required this.height,
    required this.fill,
    required this.border,
  });
  final String text;
  final double width;
  final double height;
  final Color fill;
  final Color border;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: CustomPaint(
        painter: _DiamondPainter(fill: fill, border: border),
        child: Center(
          child: SizedBox(
            width: width * 0.62,
            child: FitText(
              text,
              maxWidth: width * 0.62,
              style: const TextStyle(
                fontSize: 11.5,
                height: 1.05,
                fontWeight: FontWeight.w800,
                color: Colors.black87,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DiamondPainter extends CustomPainter {
  const _DiamondPainter({required this.fill, required this.border});
  final Color fill;
  final Color border;
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width / 2, 0)
      ..lineTo(size.width, size.height / 2)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(0, size.height / 2)
      ..close();
    canvas
      ..drawPath(path, Paint()..color = fill)
      ..drawPath(
        path,
        Paint()
          ..color = border
          ..strokeWidth = 1.5
          ..style = PaintingStyle.stroke,
      );
  }

  @override
  bool shouldRepaint(_DiamondPainter old) =>
      old.fill != fill || old.border != border;
}

Color? _sevFill(TopicTheme t, RowSeverity s) => switch (s) {
  RowSeverity.emergency => t.severitySevereTile,
  RowSeverity.priority => t.severityModerateTile,
  RowSeverity.nonUrgent => t.severityMildTile,
  RowSeverity.none => null,
};

Color? _sevBorder(TopicTheme t, RowSeverity s) => switch (s) {
  RowSeverity.emergency => t.severitySevereHeader,
  RowSeverity.priority => t.severityModerateHeader,
  RowSeverity.nonUrgent => t.severityMildHeader,
  RowSeverity.none => null,
};
