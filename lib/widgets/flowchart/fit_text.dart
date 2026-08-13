import 'package:flutter/material.dart';

/// Text widget that word-wraps but never breaks a word into an orphan
/// fragment.  If the widest word at [style] doesn't fit [maxWidth], the
/// font size is scaled down just enough that it does — wrapping then
/// happens at spaces only, matching how the source PDFs render.
///
/// [maxWidth] is supplied by the caller (computed above any surrounding
/// `IntrinsicHeight`/`IntrinsicWidth` so it never has to be read by a
/// nested `LayoutBuilder` — a `LayoutBuilder` can't answer the
/// intrinsic-dimension queries those widgets make).  A non-finite
/// [maxWidth] disables shrinking and the text just wraps.
///
/// The widget uses the ambient `MediaQuery.textScalerOf(context)` for
/// its `TextPainter` measurement so the painter's word-width matches the
/// live `RenderParagraph` — otherwise the two disagree at non-default
/// scale factors and the shrink decision misfires.
class FitText extends StatelessWidget {
  const FitText(
    this.text, {
    required this.style,
    required this.maxWidth,
    this.maxHeight,
    this.textAlign = TextAlign.center,
    this.color,
    super.key,
  });

  final String text;
  final TextStyle style;
  final double maxWidth;

  /// Optional wrapped-height budget. After the width-based shrink, if the
  /// text still wraps taller than this, the font is scaled down further (to
  /// [_minFontSize]) so it fits — used to keep a decision's text inside its
  /// diamond instead of spilling past the points onto the box below.
  final double? maxHeight;
  final TextAlign textAlign;

  /// Optional override on the rendered text's colour — applied on top of
  /// the shrink-adjusted style.  Convenient when the caller's [style]
  /// already encodes everything else and they just want to tint.
  final Color? color;

  /// Legibility floor — never shrink below this even if a pathologically
  /// long word would still overflow.  External readability constraint
  /// (akin to a minimum touch target), not a layout fudge.
  static const double _minFontSize = 9;

  @override
  Widget build(BuildContext context) {
    final baseSize = style.fontSize ?? 14.0;
    var fontSize = baseSize;
    if (maxWidth.isFinite && maxWidth > 0) {
      final scaler = MediaQuery.textScalerOf(context);
      var widest = 0.0;
      for (final word in text.split(RegExp(r'\s+'))) {
        if (word.isEmpty) continue;
        final tp = TextPainter(
          text: TextSpan(text: word, style: style),
          textDirection: TextDirection.ltr,
          textScaler: scaler,
          maxLines: 1,
        )..layout();
        if (tp.width > widest) widest = tp.width;
      }
      if (widest > maxWidth) {
        fontSize = (baseSize * maxWidth / widest).clamp(_minFontSize, baseSize);
      }
      // Height fit: shrink further if the wrapped text is taller than the
      // budget (two proportional passes converge quickly).
      final mh = maxHeight;
      if (mh != null && mh.isFinite && mh > 0) {
        final scaler = MediaQuery.textScalerOf(context);
        double wrappedHeight(double fs) {
          final tp = TextPainter(
            text: TextSpan(
              text: text,
              style: style.copyWith(fontSize: fs),
            ),
            textDirection: TextDirection.ltr,
            textScaler: scaler,
          )..layout(maxWidth: maxWidth);
          return tp.height;
        }

        for (var i = 0; i < 2; i++) {
          final h = wrappedHeight(fontSize);
          if (h <= mh || fontSize <= _minFontSize) break;
          fontSize = (fontSize * mh / h).clamp(_minFontSize, fontSize);
        }
      }
    }
    final resolved = style.copyWith(fontSize: fontSize, color: color);
    return Text(text, textAlign: textAlign, style: resolved);
  }
}
