import 'package:flutter/material.dart';
import 'package:orbweaver/models/topic.dart';
import 'package:orbweaver/theme/topic_theme.dart';
import 'package:orbweaver/widgets/flowchart/arrow_paint.dart';
import 'package:orbweaver/widgets/flowchart/banded_entry.dart';
import 'package:orbweaver/widgets/flowchart/flow_link.dart';

/// A flowchart node (entry / decision / convergence / action).
///
/// Shape is taken from [NodeShape]. Stadium and diamond nodes render
/// centred at ~55% width — they're visual cues (entry / decision) that
/// sit above the full-width branch row.
class FlowNodeBox extends StatelessWidget {
  const FlowNodeBox({
    required this.text,
    required this.shape,
    required this.theme,
    this.compact = false,
    this.fillWidth = false,
    this.bands = const [],
    this.ccTitle,
    super.key,
  });

  /// A box carrying everything the model [node] declares (text, shape, age
  /// bands and the fused Critical-Care title).
  FlowNodeBox.fromNode(
    FlowNode node, {
    required this.theme,
    this.compact = false,
    this.fillWidth = false,
    super.key,
  }) : text = node.text,
       shape = node.shape,
       bands = node.bands,
       ccTitle = node.ccTitle;

  final String text;
  final NodeShape shape;
  final TopicTheme theme;
  final bool compact;

  /// Age rows, when this node is one of the print's banded entry stadiums.
  /// See [BandedEntryStadium] — it takes over the whole node.
  final List<AgeBand> bands;

  /// Header of the fused Critical-Care column, when [bands] carry CC values.
  final String? ccTitle;

  /// When true, skip the default Center+FractionallySizedBox(0.55) wrap
  /// applied to stadium and diamond shapes. Use when the node is
  /// already inside a sized parent slot (e.g. flanked by warning
  /// callouts) and should fill its slot rather than shrink to 55%.
  final bool fillWidth;

  @override
  Widget build(BuildContext context) {
    if (bands.isNotEmpty) {
      // The banded stadium already is a stadium, striped and (where the page
      // has one) fused to its Critical-Care column. It takes the full width:
      // the 0.95 factor below exists to stop multi-line stadiums wrapping,
      // and this one sizes its own rows.
      return BandedEntryStadium(
        title: text,
        bands: bands,
        ccTitle: ccTitle,
      );
    }

    if (shape == NodeShape.diamond) {
      // Diamond in isolation (no fan-out). DecisionHub handles the
      // diamond-with-arrows case; this branch is here for flowcharts
      // that use a diamond with a single exit arrow.
      final diamond = DiamondNode(text: text, compact: compact);
      if (fillWidth) return diamond;
      return Center(
        child: FractionallySizedBox(widthFactor: 0.55, child: diamond),
      );
    }

    final radius = switch (shape) {
      NodeShape.stadium => 999.0,
      NodeShape.roundedRectangle => 12.0,
      NodeShape.rectangle => 4.0,
      NodeShape.diamond => 0.0,
    };

    final fill = shape == NodeShape.stadium ? theme.flowEntry : theme.nodeFill;

    final padding = compact
        ? const EdgeInsets.symmetric(horizontal: 6, vertical: 2)
        : const EdgeInsets.symmetric(horizontal: 8, vertical: 4);

    final box = Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: fill,
        border: Border.all(color: theme.nodeBorder, width: 1.5),
        borderRadius: BorderRadius.circular(radius),
      ),
      child: FlowLinkText(
        text,
        style: const TextStyle(
          fontSize: 16,
          height: 1.15,
          fontWeight: FontWeight.w700,
          color: Colors.black87,
        ),
      ),
    );

    if (shape == NodeShape.stadium && !fillWidth) {
      // Multi-line entry stadiums (Shock, HTN, etc.) need a wider band
      // so each authored line fits on its own row instead of wrapping
      // further. Single-line stadiums stay at the narrower 0.55 to read
      // as a focused visual cue above the branches.
      final lineCount = text.split('\n').length;
      final widthFactor = lineCount >= 2 ? 0.95 : 0.55;
      return Center(
        child: FractionallySizedBox(widthFactor: widthFactor, child: box),
      );
    }

    return box;
  }
}

/// Pale colours matching the WVEMS protocol PDFs.

/// Horizontal gap between adjacent branch columns in a severity
/// flowchart. Painters that draw arrows landing on column centres must
/// account for this gap, otherwise their X positions are off by half
/// the gap and the arrow ends look like they "step" instead of being
/// straight continuations of the column-internal vertical line.
const double kSeverityBranchGap = 4;

/// Rhombus decision node. Exposed so [DecisionHub] can draw it inside
/// its combined diamond+arrows layout. The inscribed text band spans
/// the middle; horizontal padding keeps text off the sloping edges.
class DiamondNode extends StatelessWidget {
  const DiamondNode({
    required this.text,
    this.compact = false,
    super.key,
  });

  final String text;
  final bool compact;

  static double heightFor({bool compact = false}) => compact ? 64 : 76;

  @override
  Widget build(BuildContext context) {
    final height = heightFor(compact: compact);
    return SizedBox(
      width: double.infinity,
      height: height,
      child: CustomPaint(
        painter: DiamondPainter(
          fill: TopicThemeScope.of(context).flowDecision,
          stroke: Colors.black87,
        ),
        child: Center(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 24 : 44,
              vertical: compact ? 6 : 8,
            ),
            child: FlowLinkText(
              text,
              style: TextStyle(
                fontSize: compact ? 15 : 16,
                height: 1.15,
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

/// Centred diamond + three arrows radiating from its left point, bottom
/// point, and right point down to the top of each branch column. The
/// left/right arrows are L-shaped (horizontal then down) — that's the
/// WVEMS convention and reads more clearly than splaying diagonals on a
/// narrow screen.
///
/// Branch count must be 3 for the L-arrow layout; other counts fall back
/// to a simple fan (one line per column from the bottom tip).
class DecisionHub extends StatelessWidget {
  const DecisionHub({
    required this.text,
    required this.branchCount,
    super.key,
  });

  final String text;
  final int branchCount;

  static const double _arrowExtension = 12;

  /// Narrower diamond for 2-branch flows leaves room for visible L-shape
  /// arrow segments between the diamond's side points and the branch
  /// column centres. 3-branch flows use a wider diamond so the centre
  /// arrow has somewhere to exit from.
  static double diamondWidthFactorFor(int branchCount) =>
      branchCount == 2 ? 0.4 : 0.55;

  @override
  Widget build(BuildContext context) {
    // Narrower diamonds (2-branch) have less horizontal room for the
    // inscribed text band — use the tighter compact padding so short
    // decision prompts like "Severity?" don't wrap.
    final compact = branchCount == 2;
    final diamondHeight = DiamondNode.heightFor(compact: compact);
    final totalHeight = diamondHeight + _arrowExtension;
    final widthFactor = diamondWidthFactorFor(branchCount);
    return SizedBox(
      width: double.infinity,
      height: totalHeight,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _DecisionArrowsPainter(
                branchCount: branchCount,
                diamondHeight: diamondHeight,
                diamondWidthFactor: widthFactor,
                columnGap: kSeverityBranchGap,
              ),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: diamondHeight,
            child: Center(
              child: FractionallySizedBox(
                widthFactor: widthFactor,
                child: DiamondNode(text: text, compact: compact),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DecisionArrowsPainter extends CustomPainter {
  const _DecisionArrowsPainter({
    required this.branchCount,
    required this.diamondHeight,
    required this.diamondWidthFactor,
    this.columnGap = 0,
  });

  final int branchCount;
  final double diamondHeight;
  final double diamondWidthFactor;
  final double columnGap;

  @override
  void paint(Canvas canvas, Size size) {
    final line = flowStroke();
    final fill = flowFill();

    final w = size.width;
    final midX = w / 2;
    final diamondMidY = diamondHeight / 2;
    final diamondHalfWidth = (w * diamondWidthFactor) / 2;
    final leftPointX = midX - diamondHalfWidth;
    final rightPointX = midX + diamondHalfWidth;

    void drawArrow(Path path, Offset tip, Offset shaftDir) {
      canvas.drawPath(path, line);
      drawArrowHead(canvas, tip, shaftDir / shaftDir.distance, fill: fill);
    }

    if (branchCount == 2 || branchCount == 3) {
      // Column centres in the row below: each column slot has width
      // (W − (n−1)·gap) / n, and column i sits at offset i·(slotW + gap).
      // Centring on slotW/2 within each slot gives the painter the same
      // X positions the column widgets actually occupy.
      final slotW = (w - (branchCount - 1) * columnGap) / branchCount;
      final centers = [
        for (var i = 0; i < branchCount; i++)
          i * (slotW + columnGap) + slotW / 2,
      ];
      // Centre arrow only exists for an odd branch count (the bottom
      // tip of the diamond has a column directly below it).
      if (branchCount == 3) {
        final centerPath = Path()
          ..moveTo(midX, diamondHeight)
          ..lineTo(centers[1], size.height);
        drawArrow(
          centerPath,
          Offset(centers[1], size.height),
          const Offset(0, 1),
        );
      }
      // Left — from left point, horizontal to left-most branch column
      // centre, then straight down.
      final leftCornerX = centers.first;
      final leftPath = Path()
        ..moveTo(leftPointX, diamondMidY)
        ..lineTo(leftCornerX, diamondMidY)
        ..lineTo(leftCornerX, size.height);
      drawArrow(leftPath, Offset(leftCornerX, size.height), const Offset(0, 1));
      // Right — mirror of left.
      final rightCornerX = centers.last;
      final rightPath = Path()
        ..moveTo(rightPointX, diamondMidY)
        ..lineTo(rightCornerX, diamondMidY)
        ..lineTo(rightCornerX, size.height);
      drawArrow(
        rightPath,
        Offset(rightCornerX, size.height),
        const Offset(0, 1),
      );
    } else {
      for (var i = 0; i < branchCount; i++) {
        final frac = (2 * i + 1) / (2 * branchCount);
        final tip = Offset(w * frac, size.height);
        final path = Path()
          ..moveTo(midX, diamondHeight)
          ..lineTo(tip.dx, tip.dy);
        drawArrow(path, tip, tip - Offset(midX, diamondHeight));
      }
    }
  }

  @override
  bool shouldRepaint(_DecisionArrowsPainter old) =>
      old.branchCount != branchCount ||
      old.diamondHeight != diamondHeight ||
      old.diamondWidthFactor != diamondWidthFactor ||
      old.columnGap != columnGap;
}

/// A filled, outlined diamond filling its whole canvas: the decision node
/// of the severity family (2 px, round joins) and of the cycle renderer
/// (1.5 px, mitred), which pass their own outline.
class DiamondPainter extends CustomPainter {
  const DiamondPainter({
    required this.fill,
    required this.stroke,
    this.strokeWidth = 2,
    this.strokeJoin = StrokeJoin.round,
  });

  final Color fill;
  final Color stroke;
  final double strokeWidth;
  final StrokeJoin strokeJoin;

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
          ..color = stroke
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeJoin = strokeJoin,
      );
  }

  @override
  bool shouldRepaint(DiamondPainter old) =>
      old.fill != fill ||
      old.stroke != stroke ||
      old.strokeWidth != strokeWidth ||
      old.strokeJoin != strokeJoin;
}
