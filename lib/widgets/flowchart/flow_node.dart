import 'package:flutter/material.dart';
import 'package:orbweaver/models/topic.dart';
import 'package:orbweaver/theme/topic_theme.dart';

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
    super.key,
  });

  final String text;
  final NodeShape shape;
  final TopicTheme theme;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (shape == NodeShape.diamond) {
      // Diamond in isolation (no fan-out). DecisionHub handles the
      // diamond-with-arrows case; this branch is here for flowcharts
      // that use a diamond with a single exit arrow.
      return Center(
        child: FractionallySizedBox(
          widthFactor: 0.55,
          child: DiamondNode(text: text, compact: compact),
        ),
      );
    }

    final radius = switch (shape) {
      NodeShape.stadium => 999.0,
      NodeShape.roundedRectangle => 12.0,
      NodeShape.rectangle => 4.0,
      NodeShape.diamond => 0.0,
    };

    final fill = shape == NodeShape.stadium
        ? _wvemsEntryStadium
        : theme.nodeFill;

    final padding = compact
        ? const EdgeInsets.symmetric(horizontal: 6, vertical: 2)
        : const EdgeInsets.symmetric(horizontal: 8, vertical: 6);

    final box = Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: fill,
        border: Border.all(color: theme.nodeBorder, width: 1.5),
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 14,
          height: 1.15,
          fontWeight: FontWeight.w700,
          color: Colors.black87,
        ),
      ),
    );

    if (shape == NodeShape.stadium) {
      return Center(
        child: FractionallySizedBox(widthFactor: 0.55, child: box),
      );
    }

    return box;
  }
}

/// Pale colours matching the WVEMS protocol PDFs.
const Color _wvemsDiamondFill = Color(0xFFF6BDAE); // salmon pink
const Color _wvemsEntryStadium = Color(0xFFCDE0F1); // pale blue

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

  static double heightFor({bool compact = false}) => compact ? 60 : 72;

  @override
  Widget build(BuildContext context) {
    final height = heightFor(compact: compact);
    return SizedBox(
      width: double.infinity,
      height: height,
      child: CustomPaint(
        painter: const _DiamondPainter(
          fill: _wvemsDiamondFill,
          stroke: Colors.black87,
        ),
        child: Center(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 44 : 56,
              vertical: 10,
            ),
            child: Text(
              text,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: compact ? 13 : 14,
                height: 1.15,
                fontWeight: FontWeight.w700,
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

  static const double _diamondWidthFactor = 0.55;
  static const double _arrowExtension = 28;

  @override
  Widget build(BuildContext context) {
    final diamondHeight = DiamondNode.heightFor();
    final totalHeight = diamondHeight + _arrowExtension;
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
                diamondWidthFactor: _diamondWidthFactor,
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
                widthFactor: _diamondWidthFactor,
                child: DiamondNode(text: text),
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
  });

  final int branchCount;
  final double diamondHeight;
  final double diamondWidthFactor;

  @override
  void paint(Canvas canvas, Size size) {
    final line = Paint()
      ..color = Colors.black87
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    final fill = Paint()
      ..color = Colors.black87
      ..style = PaintingStyle.fill;

    final w = size.width;
    final midX = w / 2;
    final diamondMidY = diamondHeight / 2;
    final diamondHalfWidth = (w * diamondWidthFactor) / 2;
    final leftPointX = midX - diamondHalfWidth;
    final rightPointX = midX + diamondHalfWidth;

    void drawArrow(Path path, Offset tip, Offset shaftDir) {
      canvas.drawPath(path, line);
      // Arrow head is a small triangle at the tip, oriented by [shaftDir].
      final unit = shaftDir / shaftDir.distance;
      final perp = Offset(-unit.dy, unit.dx) * 4;
      final base = tip - unit * 6;
      final head = Path()
        ..moveTo(tip.dx, tip.dy)
        ..lineTo(base.dx + perp.dx, base.dy + perp.dy)
        ..lineTo(base.dx - perp.dx, base.dy - perp.dy)
        ..close();
      canvas.drawPath(head, fill);
    }

    if (branchCount == 3) {
      final centers = [w / 6, w / 2, 5 * w / 6];
      // Centre — straight down from bottom tip.
      final centerPath = Path()
        ..moveTo(midX, diamondHeight)
        ..lineTo(centers[1], size.height);
      drawArrow(centerPath, Offset(centers[1], size.height),
          const Offset(0, 1));
      // Left — from left point, horizontal to branch 1 column centre,
      // then straight down.
      final leftCornerX = centers[0];
      final leftPath = Path()
        ..moveTo(leftPointX, diamondMidY)
        ..lineTo(leftCornerX, diamondMidY)
        ..lineTo(leftCornerX, size.height);
      drawArrow(leftPath, Offset(leftCornerX, size.height),
          const Offset(0, 1));
      // Right — mirror of left.
      final rightCornerX = centers[2];
      final rightPath = Path()
        ..moveTo(rightPointX, diamondMidY)
        ..lineTo(rightCornerX, diamondMidY)
        ..lineTo(rightCornerX, size.height);
      drawArrow(rightPath, Offset(rightCornerX, size.height),
          const Offset(0, 1));
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
      old.diamondWidthFactor != diamondWidthFactor;
}

class _DiamondPainter extends CustomPainter {
  const _DiamondPainter({required this.fill, required this.stroke});

  final Color fill;
  final Color stroke;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width / 2, 0)
      ..lineTo(size.width, size.height / 2)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(0, size.height / 2)
      ..close();
    canvas.drawPath(path, Paint()..color = fill);
    canvas.drawPath(
      path,
      Paint()
        ..color = stroke
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_DiamondPainter old) =>
      old.fill != fill || old.stroke != stroke;
}
