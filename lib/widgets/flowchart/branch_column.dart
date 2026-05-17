import 'package:flutter/material.dart';
import 'package:orbweaver/models/topic.dart';
import 'package:orbweaver/theme/topic_theme.dart';
import 'package:orbweaver/widgets/flowchart/flowchart_view.dart';

/// Severity palette for branches. Matches the WHO-IMCI colours used on
/// table rows. Tile/header backgrounds are pale so bold text stays
/// black-on-white-ish for legibility.
///
/// Severity tinting is opt-in: a branch only takes a palette when its
/// YAML sets `severity:` explicitly. WVEMS protocols leave Mild /
/// Moderate / Severe label bands uncoloured (just bold headers inside
/// the criteria box) — see [BranchColumn.build].
class _SeverityColors {
  const _SeverityColors({
    required this.headerBg,
    required this.tileBg,
  });
  final Color headerBg;
  final Color tileBg;
}

_SeverityColors? _paletteFor(RowSeverity s) => switch (s) {
      RowSeverity.none => null,
      RowSeverity.emergency => const _SeverityColors(
          headerBg: Color(0xFFFFCDD2),
          tileBg: Color(0xFFFFEBEE),
        ),
      RowSeverity.priority => const _SeverityColors(
          headerBg: Color(0xFFFFE082),
          tileBg: Color(0xFFFFF8E1),
        ),
      RowSeverity.nonUrgent => const _SeverityColors(
          headerBg: Color(0xFFC8E6C9),
          tileBg: Color(0xFFE8F5E9),
        ),
    };

/// One branch from the decision diamond — rendered as a vertical column:
///   label header → criteria bullets → stacked action items.
///
/// Each action displays its provider-level badge (A/E/I) on the left if set.
/// If [TopicBranch.severity] is set, the label band and action tiles are
/// tinted with the WHO-IMCI palette (pink/yellow/green) so branches are
/// distinguishable without reading labels.
class BranchColumn extends StatelessWidget {
  const BranchColumn({
    required this.branch,
    required this.theme,
    this.extendDown = false,
    super.key,
  });

  final TopicBranch branch;
  final TopicTheme theme;

  /// When true, append a trailing vertical line that fills any remaining
  /// height in the column. Used when the row below is a convergence hub:
  /// the IntrinsicHeight of `_BranchesRow` stretches every column to the
  /// tallest sibling's height, so a column with fewer actions has empty
  /// space above the hub. This fill line bridges that gap so the
  /// convergence arrow visibly originates from the column's last action.
  final bool extendDown;

  @override
  Widget build(BuildContext context) {
    final palette = _paletteFor(branch.severity);

    // Arrow-only branch: render label + a long down-arrow.  Used when
    // the branch flows directly into the block that comes next in the
    // topic, with no intermediate action tile in the branch column.
    if (branch.continues) {
      return Column(
        children: [
          _BranchHeader(label: branch.label, headerBg: palette?.headerBg),
          const SizedBox(height: 6),
          const Expanded(child: Center(child: FlowDownArrow(length: 36))),
          const SizedBox(height: 2),
        ],
      );
    }

    final hasActions = branch.actions.isNotEmpty;
    final hasCriteria = branch.criteria.isNotEmpty;
    final addTrailingFill = extendDown && branch.continuation == null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        BranchHeaderBox(
          label: branch.label,
          criteria: branch.criteria,
          headerBg: palette?.headerBg,
        ),
        if (hasCriteria && hasActions)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 2),
            child: Center(child: FlowDownArrow(length: 10)),
          ),
        for (final action in branch.actions)
          ActionTile(action: action, theme: theme, tileBg: palette?.tileBg),
        if (addTrailingFill) const Expanded(child: TrailingFillLine()),
      ],
    );
  }
}

/// Vertical line that fills its slot — no arrow head. Used as the
/// bottom of a [BranchColumn] to bridge the empty space between the
/// last action tile and the convergence hub below, so the arrow looks
/// continuous from the action down into the hub.
class TrailingFillLine extends StatelessWidget {
  const TrailingFillLine({super.key});

  @override
  Widget build(BuildContext context) {
    return const CustomPaint(
      size: Size.infinite,
      painter: _TrailingFillLinePainter(),
    );
  }
}

class _TrailingFillLinePainter extends CustomPainter {
  const _TrailingFillLinePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final paint = Paint()
      ..color = Colors.black87
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(cx, 0), Offset(cx, size.height), paint);
  }

  @override
  bool shouldRepaint(_TrailingFillLinePainter old) => false;
}

/// One bordered rounded box containing a centred bold header and the
/// criteria bullets — matches the WVEMS PDF where Mild / Moderate /
/// Severe sit *inside* the same box as the criteria, not in a separate
/// coloured band above it. The header gets a [headerBg] tint only when
/// the branch's `severity:` field is set in YAML.
class BranchHeaderBox extends StatelessWidget {
  const BranchHeaderBox({
    required this.label,
    required this.criteria,
    this.headerBg,
    super.key,
  });

  final String label;
  final List<String> criteria;
  final Color? headerBg;

  @override
  Widget build(BuildContext context) {
    final hasCriteria = criteria.isNotEmpty;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.black87, width: 1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            decoration: BoxDecoration(
              color: headerBg,
              borderRadius: hasCriteria
                  ? const BorderRadius.vertical(top: Radius.circular(5))
                  : BorderRadius.circular(5),
              border: hasCriteria
                  ? const Border(
                      bottom: BorderSide(color: Colors.black87, width: 1),
                    )
                  : null,
            ),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: Colors.black87,
                height: 1.1,
              ),
            ),
          ),
          if (hasCriteria)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final c in criteria)
                    Text(
                      '• $c',
                      style: const TextStyle(fontSize: 12.5, height: 1.25),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Standalone label used only by the `continues: true` branch shape
/// (label + long down-arrow only, no criteria box).
class _BranchHeader extends StatelessWidget {
  const _BranchHeader({required this.label, this.headerBg});

  final String label;
  final Color? headerBg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 3),
      decoration: BoxDecoration(
        color: headerBg ?? Colors.white,
        border: Border.all(color: Colors.black87, width: 1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w800,
          color: Colors.black87,
        ),
      ),
    );
  }
}

/// Medication tile matching WVEMS format: full-height coloured provider
/// band on the left (E/A/I), bold underlined drug name on the right.

/// Provider-badge strip width. Shared so the label-width budget in
/// [ActionTile] stays in sync with the actual badge.
const double _badgeWidth = 26;

/// Horizontal padding on each side of the label inside the tile.
const double _labelHPad = 6;

/// Slack subtracted from the computed label width before deciding
/// whether to shrink: covers sub-pixel rounding between the measuring
/// `TextPainter` and the live `RenderParagraph`, plus the tile's 1px
/// border. A measurement tolerance, not a layout fudge.
const double _labelMeasureSlack = 6;

class ActionTile extends StatelessWidget {
  const ActionTile({
    required this.action,
    required this.theme,
    this.tileBg,
    this.columnWidth = double.infinity,
    super.key,
  });

  final TopicAction action;
  final TopicTheme theme;
  final Color? tileBg;

  /// Width of the branch column this tile sits in, measured by the
  /// caller *above* the branch row's `IntrinsicHeight` (a `LayoutBuilder`
  /// can't answer the intrinsic queries `IntrinsicHeight` makes).  The
  /// tile derives its own label budget from this minus its known chrome
  /// (badge + padding).  Infinity (the default, for callers that can't
  /// measure) disables label shrinking — the label just wraps.
  final double columnWidth;

  @override
  Widget build(BuildContext context) {
    final labelMaxWidth = columnWidth.isFinite
        ? columnWidth - _badgeWidth - 2 * _labelHPad - _labelMeasureSlack
        : double.infinity;
    return Container(
      decoration: BoxDecoration(
        color: tileBg ?? Colors.white,
        border: Border.all(color: Colors.black87, width: 1),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Always show the badge column (gray placeholder for
            // actions with no provider level) so columns line up.
            _ProviderBadge(level: action.providerLevel),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: _labelHPad,
                  vertical: 4,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _FitText(
                      action.text,
                      maxWidth: labelMaxWidth,
                      style: const TextStyle(
                        fontSize: 13,
                        height: 1.1,
                        fontWeight: FontWeight.w800,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                    if (action.timing != null || action.condition != null)
                      Text(
                        [
                          if (action.timing != null) action.timing!,
                          if (action.condition != null) action.condition!,
                        ].join(' · '),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 12,
                          height: 1.15,
                          fontStyle: FontStyle.italic,
                          color: Colors.black54,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Action-tile label that word-wraps like the source PDF but never
/// breaks a word into an orphan character.
///
/// The PDF renders multi-word actions (e.g. "Encourage Breastfeeding")
/// on as many lines as needed, one word per line when narrow — it never
/// splits a word.  Flutter's default `Text` breaks a single word
/// mid-glyph when that word alone is wider than the column (producing
/// "Breastfeedin" + an orphan "g").  This widget measures the widest
/// word at [style] and, only if it overflows [maxWidth], scales the
/// font down just enough that the widest word fits — wrapping then
/// happens at spaces only, matching the PDF.  Short labels keep the
/// full [style] size unchanged.
///
/// [maxWidth] is computed by the caller *above* the surrounding
/// `IntrinsicHeight` and passed in, rather than read from a
/// `LayoutBuilder` here: a `LayoutBuilder` cannot answer the
/// intrinsic-dimension queries `IntrinsicHeight` makes, so nesting one
/// inside the tile throws.  A non-finite [maxWidth] disables shrinking.
class _FitText extends StatelessWidget {
  const _FitText(this.text, {required this.style, required this.maxWidth});

  final String text;
  final TextStyle style;
  final double maxWidth;

  /// Legibility floor — never shrink an action label below this even if
  /// a pathologically long word would still overflow.  An external
  /// readability constraint (like a minimum touch target), not a layout
  /// fudge factor.
  static const double _minFontSize = 9;

  @override
  Widget build(BuildContext context) {
    final baseSize = style.fontSize ?? 14.0;
    var fontSize = baseSize;
    if (maxWidth.isFinite && maxWidth > 0) {
      // Measure with the same text scaler the rendered Text will use,
      // otherwise the painter under-measures (scale 1.0) and we decide
      // not to shrink even though the live text overflows.
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
        fontSize =
            (baseSize * maxWidth / widest).clamp(_minFontSize, baseSize);
      }
    }
    return Text(
      text,
      textAlign: TextAlign.center,
      style: style.copyWith(fontSize: fontSize),
    );
  }
}

/// Full-height provider-level band. WVEMS convention:
///   E = gold, A = green, I = blue.
class _ProviderBadge extends StatelessWidget {
  const _ProviderBadge({required this.level});

  final ProviderLevel level;

  @override
  Widget build(BuildContext context) {
    final (letter, color) = switch (level) {
      ProviderLevel.emt => ('E', const Color(0xFFF2C24A)),
      ProviderLevel.intermediate => ('I', const Color(0xFF6FAADB)),
      ProviderLevel.als => ('A', const Color(0xFF7BBF86)),
      ProviderLevel.any => ('', const Color(0xFFE0E0E0)),
    };

    return Container(
      width: _badgeWidth,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color,
        border: const Border(
          right: BorderSide(color: Colors.black87, width: 1),
        ),
      ),
      child: Text(
        letter,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w800,
          color: Colors.black87,
        ),
      ),
    );
  }
}
