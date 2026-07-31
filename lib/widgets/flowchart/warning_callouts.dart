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

/// Purple trapezoid for `WarningType.caution` callouts.
///
/// Matches the WVEMS convention — the print's "Important Note" shape
/// (PDF p.2 legend) and its in-flow uses, e.g. p.70's "Consider
/// Destination Triage".  Both sides slope inward going down (an
/// isosceles trapezoid, wide edge on top), which is what distinguishes
/// it from the plain boxes around it.  Used for clinician-facing caveats
/// and cross-references that change how to engage the patient.
class CautionCallout extends StatelessWidget {
  const CautionCallout({required this.text, super.key});

  final String text;

  static const Color _stroke = Colors.black87;

  /// Fraction of the callout's width each sloped side eats by the bottom
  /// edge.  Measured off the source PDF: the legend trapezoid on p.2 is
  /// 511 x 315 px at 300 dpi with a 355 px bottom edge, and p.70's is
  /// 255 x 157 px at 150 dpi with a 177 px bottom edge — both 0.248 of
  /// the height per side, bottom edge 0.70 of the top.  Expressed against
  /// width (not height) because the app's flank slot is narrower and
  /// taller than the printed box: holding the printed width ratio keeps
  /// the printed silhouette, where holding its 14 degree slope would
  /// pinch the bottom edge to under half the top.
  static const double _taperFraction = 0.15;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 84,
      child: CustomPaint(
        painter: _TrapezoidPainter(
          fill: TopicThemeScope.of(context).warningCaution,
          stroke: _stroke,
          taperFraction: _taperFraction,
        ),
        child: LayoutBuilder(
          builder: (context, slot) {
            // Inset by half the taper on each side — the trapezoid's width
            // at mid-height, which is where the text band sits. The print
            // does the same: on p.70 the widest line spans nearly the full
            // top edge and only the short last line sits inside the narrow
            // bottom.
            final inset = 6 + slot.maxWidth * _taperFraction / 2;
            return Padding(
              padding: EdgeInsets.symmetric(horizontal: inset, vertical: 4),
              child: Center(
                // Subtract a small margin so the shrunk text leaves
                // breathing room from the slant edges; matches the
                // measurement-tolerance pattern used by action tiles.
                child: FitText(
                  text,
                  maxWidth: slot.maxWidth - 2 * inset - 4,
                  color: Colors.white,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.1,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _TrapezoidPainter extends CustomPainter {
  const _TrapezoidPainter({
    required this.fill,
    required this.stroke,
    required this.taperFraction,
  });

  final Color fill;
  final Color stroke;

  /// See [CautionCallout._taperFraction] — how much of the width each
  /// sloped side has eaten by the bottom edge.
  final double taperFraction;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final taper = w * taperFraction;
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(w, 0)
      ..lineTo(w - taper, h)
      ..lineTo(taper, h)
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
  bool shouldRepaint(_TrapezoidPainter old) =>
      old.fill != fill ||
      old.stroke != stroke ||
      old.taperFraction != taperFraction;
}
