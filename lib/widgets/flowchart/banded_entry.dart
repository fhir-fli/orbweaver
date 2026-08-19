import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:orbweaver/models/topic.dart';
import 'package:orbweaver/theme/topic_theme.dart';
import 'package:orbweaver/widgets/unit_text.dart';

/// The print's age-banded entry stadium: a title over one row per age band,
/// zebra-striped a stripe to a row, with an optional Critical-Care stadium
/// fused behind its right end (pp.8, 10, 12, 14, 82, 92).
///
/// Reproduced from the page rather than from the vector layer, because the
/// vector layer does not have it: `get_drawings()` reports both stadiums as
/// stroke-only, and the banding is painted underneath by a shading the walker
/// does not report. The stripe colours here were sampled off a 400 dpi render
/// down a column no glyph crosses (`tool/wvems_entry_stripe_sample.py`):
/// #CFE2F3 / #E5EFF7 on the blue side, #D9D2E9 / #ECE4FF on the lavender,
/// with the stripe boundaries shared across both so the bands run
/// continuously from one stadium into the other.
///
/// The striping is the whole point of the widget. These stadiums are a lookup
/// table — the reader wants one row, their patient's — and four lines of
/// centred text with no banding makes them read the whole block to find it.
///
/// The Critical-Care column is a *second stadium behind the first*, offset
/// right so only its right cap shows, with no black outline of its own. That
/// layering is what marks MAP as a credentialed alternative to the systolic
/// threshold rather than an extra column of the same table — and its dark
/// stripe is `cc_band_fill` exactly, the same lavender as every other CC
/// element in the book.
class BandedEntryStadium extends StatelessWidget {
  const BandedEntryStadium({
    required this.title,
    required this.bands,
    this.ccTitle,
    super.key,
  });

  final String title;
  final List<AgeBand> bands;
  final String? ccTitle;

  /// Share of the width taken by the blue stadium. Measured: the blue runs
  /// 186→438 pt and the lavender shows through to 528, so the blue is
  /// 252/342 of the pair.
  static const double _blueFraction = 252 / 342;

  bool get _hasCc =>
      ccTitle != null && bands.any((b) => b.criticalCare != null);

  @override
  Widget build(BuildContext context) {
    final theme = TopicThemeScope.of(context);
    final rowCount = bands.length + 1;
    // A stadium's ends are caps, so its top and bottom rows lose width to the
    // curve. Inset text by how far the curve bites at the outermost row's
    // midline: r - sqrt(r^2 - (r - y)^2). Both stadiums need it — on a page
    // where a warning callout squeezes the blue one (p.92) its own curve
    // clips the bottom row.
    final radius = _rowHeight * rowCount / 2;
    final capInset =
        radius -
        math.sqrt(
          math.max(0, radius * radius - math.pow(radius - _rowHeight / 2, 2)),
        );
    // The lavender stadium reaches this far left underneath the blue one — its
    // own left cap, hidden. Its text has to clear that or it reads as "5 mmHg".
    final ccOverlap = radius;
    final height = _rowHeight * rowCount;

    final blueRows = [
      for (final band in bands) '• ${band.label}: ${band.value}',
    ];
    final ccRows = [for (final band in bands) band.criticalCare ?? ''];

    // The outer SizedBox is load-bearing, not cosmetic: `_EntryWithWarnings`
    // wraps the entry row in an IntrinsicHeight, and a LayoutBuilder cannot
    // answer an intrinsic query — it throws and the whole page renders blank
    // (p.92). A tight height constraint lets RenderConstrainedBox answer from
    // the constraint without descending into the builder.
    return SizedBox(
      height: height,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final total = constraints.maxWidth;
          final blueWidth = _hasCc ? total * _blueFraction : total;

          final blue = _stadium(
            width: blueWidth,
            height: height,
            rowCount: rowCount,
            dark: theme.flowEntry,
            light: theme.flowEntryAlt,
            border: theme.nodeBorder,
            padding: EdgeInsets.symmetric(horizontal: capInset),
            title: title,
            titleStyle: _titleStyle,
            rows: blueRows,
          );

          if (!_hasCc) return blue;

          return SizedBox(
            height: height,
            child: Stack(
              children: [
                // The lavender sits *behind*, its left cap tucked under the
                // blue, so only its right end shows — the print's layered-card
                // look. Painting it as a sibling column instead would read as
                // one four-column table and lose the "or" the layering carries.
                Positioned(
                  left: blueWidth - ccOverlap,
                  right: 0,
                  top: 0,
                  bottom: 0,
                  child: _stadium(
                    width: total - blueWidth + ccOverlap,
                    height: height,
                    rowCount: rowCount,
                    dark: theme.ccBandFill,
                    light: theme.flowEntryCcAlt,
                    padding: EdgeInsets.only(
                      left: ccOverlap,
                      right: capInset,
                    ),
                    title: ccTitle!,
                    titleStyle: _ccTitleStyle,
                    rows: ccRows,
                  ),
                ),
                blue,
              ],
            ),
          );
        },
      ),
    );
  }

  /// One striped stadium. [rows] are shrunk by a *single* shared factor when
  /// the widest of them would overrun — the print keeps every row at one size,
  /// and shrinking each independently would ladder them. Nothing is ever
  /// clipped: dropping a silent "mmHg" off the end of a threshold is the one
  /// failure this widget must not have.
  Widget _stadium({
    required double width,
    required double height,
    required int rowCount,
    required Color dark,
    required Color light,
    required EdgeInsets padding,
    required String title,
    required TextStyle titleStyle,
    required List<String> rows,
    Color? border,
  }) {
    final content = width - padding.horizontal;
    final rowScale = _fitScale(rows, _rowStyle, content);
    final titleScale = _fitScale([title], titleStyle, content);
    final rowStyle = _scaled(_rowStyle, rowScale);
    final scaledTitle = _scaled(titleStyle, titleScale);

    return SizedBox(
      width: width,
      height: height,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(999),
        child: CustomPaint(
          painter: _ZebraPainter(rowCount: rowCount, dark: dark, light: light),
          child: Container(
            // A `decoration` border insets the child by its own width; the
            // foreground one paints the same stroke without eating height.
            foregroundDecoration: border == null
                ? null
                : BoxDecoration(
                    border: Border.all(color: border, width: 2.5),
                    borderRadius: BorderRadius.circular(999),
                  ),
            padding: padding,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: _rowHeight,
                  child: Center(
                    child: Text(
                      title,
                      textAlign: TextAlign.center,
                      style: scaledTitle,
                    ),
                  ),
                ),
                for (final row in rows)
                  SizedBox(
                    height: _rowHeight,
                    child: Center(
                      child: Text.rich(
                        TextSpan(
                          children: unitAwareSpans(
                            row,
                            rowStyle,
                            rowStyle.fontSize!,
                          ),
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Largest factor <= 1 at which every one of [texts] fits [maxWidth] on one
  /// line, floored so a pathological string cannot shrink the row to nothing.
  static double _fitScale(List<String> texts, TextStyle base, double maxWidth) {
    if (maxWidth <= 0) return 1;
    var scale = 1.0;
    for (final text in texts) {
      if (text.isEmpty) continue;
      final painter = TextPainter(
        text: TextSpan(children: unitAwareSpans(text, base, base.fontSize!)),
        textDirection: TextDirection.ltr,
      )..layout();
      if (painter.width > maxWidth) {
        scale = math.min(scale, maxWidth / painter.width);
      }
    }
    return math.max(scale, _minScale);
  }

  static TextStyle _scaled(TextStyle style, double scale) =>
      style.copyWith(fontSize: style.fontSize! * scale);

  /// Legibility floor, the same constraint `FitText` applies: below this the
  /// row stops being readable at arm's length and the page needs re-authoring.
  static const double _minScale = 9 / 16;

  static const double _rowHeight = 26;

  static const TextStyle _titleStyle = TextStyle(
    fontSize: 18,
    height: 1,
    fontWeight: FontWeight.w800,
    color: Colors.black87,
  );

  static const TextStyle _ccTitleStyle = TextStyle(
    fontSize: 16,
    height: 1,
    fontWeight: FontWeight.w800,
    color: Colors.black87,
  );

  static const TextStyle _rowStyle = TextStyle(
    fontSize: 16,
    height: 1,
    fontWeight: FontWeight.w700,
    color: Colors.black87,
  );
}

/// Equal horizontal stripes, [dark] first, alternating down the box.
class _ZebraPainter extends CustomPainter {
  const _ZebraPainter({
    required this.rowCount,
    required this.dark,
    required this.light,
  });

  final int rowCount;
  final Color dark;
  final Color light;

  @override
  void paint(Canvas canvas, Size size) {
    final rowHeight = size.height / rowCount;
    for (var i = 0; i < rowCount; i++) {
      canvas.drawRect(
        Rect.fromLTWH(0, i * rowHeight, size.width, rowHeight + 0.5),
        Paint()..color = i.isEven ? dark : light,
      );
    }
  }

  @override
  bool shouldRepaint(_ZebraPainter old) =>
      old.rowCount != rowCount || old.dark != dark || old.light != light;
}
