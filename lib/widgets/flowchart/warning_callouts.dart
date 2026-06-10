import 'package:flutter/material.dart';
import 'package:orbweaver/theme/topic_theme.dart';
import 'package:orbweaver/widgets/flowchart/fit_text.dart';

/// Red octagon (stop sign) for `WarningType.safety` callouts.
///
/// Matches the WVEMS protocol convention — used to flag scene-safety,
/// PPE, or other "before you touch the patient" reminders.  Width is
/// driven by the parent slot; height is set so the inscribed text band
/// fits comfortably without clipping at the slanted corners.
class SafetyOctagon extends StatelessWidget {
  const SafetyOctagon({required this.text, super.key});

  final String text;

  static const Color _stroke = Colors.black87;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 84,
      child: CustomPaint(
        painter: _OctagonPainter(
          fill: TopicThemeScope.of(context).warningSafety,
          stroke: _stroke,
        ),
        child: Padding(
          // Octagon corners eat ~22% of the width on each side at the
          // top/bottom — shrink the text box so words don't clip the
          // slanted edges.
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Center(
            child: LayoutBuilder(
              // Subtract a small margin so the shrunk text leaves
              // breathing room from the slant edges; matches the
              // measurement-tolerance pattern used by action tiles.
              builder: (context, constraints) => FitText(
                text,
                maxWidth: constraints.maxWidth - 4,
                color: Colors.white,
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.1,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OctagonPainter extends CustomPainter {
  const _OctagonPainter({required this.fill, required this.stroke});

  final Color fill;
  final Color stroke;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    // Inscribed regular octagon — corner cut equals 1/(2 + √2) of the
    // shorter side, but we don't need geometric perfection here. Using
    // ~30% of the shorter side gives the right "stop sign" silhouette.
    final cut = (w < h ? w : h) * 0.3;
    final path = Path()
      ..moveTo(cut, 0)
      ..lineTo(w - cut, 0)
      ..lineTo(w, cut)
      ..lineTo(w, h - cut)
      ..lineTo(w - cut, h)
      ..lineTo(cut, h)
      ..lineTo(0, h - cut)
      ..lineTo(0, cut)
      ..close();
    canvas.drawPath(path, Paint()..color = fill);
    canvas.drawPath(
      path,
      Paint()
        ..color = stroke
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_OctagonPainter old) =>
      old.fill != fill || old.stroke != stroke;
}

/// Purple parallelogram for `WarningType.caution` callouts.
///
/// Matches the WVEMS convention — clinician-facing caveats that change
/// how to engage the patient (e.g. respect refusal, capacity check).
/// The slant points right, top-aligned with the sister callout.
class CautionCallout extends StatelessWidget {
  const CautionCallout({required this.text, super.key});

  final String text;

  static const Color _stroke = Colors.black87;

  /// Pixels each long edge slants relative to the short edges. A small
  /// amount reads as a parallelogram without the box looking unstable.
  static const double _skew = 8;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 84,
      child: CustomPaint(
        painter: _ParallelogramPainter(
          fill: TopicThemeScope.of(context).warningCaution,
          stroke: _stroke,
          skew: _skew,
        ),
        child: Padding(
          // Inset from the slanted edges so text doesn't clip. The
          // right edge needs the larger inset because the slant cuts
          // into that corner.
          padding: const EdgeInsets.fromLTRB(6, 4, 6 + _skew, 4),
          child: Center(
            child: LayoutBuilder(
              // Subtract a small margin so the shrunk text leaves
              // breathing room from the slant edges; matches the
              // measurement-tolerance pattern used by action tiles.
              builder: (context, constraints) => FitText(
                text,
                maxWidth: constraints.maxWidth - 4,
                color: Colors.white,
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.1,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ParallelogramPainter extends CustomPainter {
  const _ParallelogramPainter({
    required this.fill,
    required this.stroke,
    required this.skew,
  });

  final Color fill;
  final Color stroke;
  final double skew;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final path = Path()
      ..moveTo(skew, 0)
      ..lineTo(w, 0)
      ..lineTo(w - skew, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(path, Paint()..color = fill);
    canvas.drawPath(
      path,
      Paint()
        ..color = stroke
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_ParallelogramPainter old) =>
      old.fill != fill || old.stroke != stroke || old.skew != skew;
}
