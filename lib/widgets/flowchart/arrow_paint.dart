import 'package:flutter/material.dart';

/// The ink every flowchart connector and arrowhead is drawn in.
const Color kFlowInk = Colors.black87;

/// A stroke for connector shafts: [kFlowInk], [width] wide, joined by [join].
Paint flowStroke({double width = 1.5, StrokeJoin join = StrokeJoin.miter}) =>
    Paint()
      ..color = kFlowInk
      ..strokeWidth = width
      ..style = PaintingStyle.stroke
      ..strokeJoin = join;

/// A solid fill for arrowheads.
Paint flowFill() => Paint()
  ..color = kFlowInk
  ..style = PaintingStyle.fill;

/// The triangular head of a connector: apex at [tip], pointing along the
/// unit vector [unit], [length] back along the shaft and [halfWidth] out to
/// each side. Every renderer draws its heads through here so the shape is
/// one shape; the sizes stay the renderer's own.
void drawArrowHead(
  Canvas canvas,
  Offset tip,
  Offset unit, {
  double length = 6,
  double halfWidth = 4,
  Paint? fill,
}) {
  final perp = Offset(-unit.dy, unit.dx) * halfWidth;
  final base = tip - unit * length;
  final head = Path()
    ..moveTo(tip.dx, tip.dy)
    ..lineTo(base.dx + perp.dx, base.dy + perp.dy)
    ..lineTo(base.dx - perp.dx, base.dy - perp.dy)
    ..close();
  canvas.drawPath(head, fill ?? flowFill());
}
