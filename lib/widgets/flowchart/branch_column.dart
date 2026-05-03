import 'package:flutter/material.dart';
import 'package:orbweaver/models/topic.dart';
import 'package:orbweaver/theme/topic_theme.dart';
import 'package:orbweaver/widgets/flowchart/flowchart_view.dart';

/// Severity palette for branches. Matches the WHO-IMCI colours used on
/// table rows, but with a stronger label band for readability.
class _SeverityColors {
  const _SeverityColors({
    required this.labelBg,
    required this.tileBg,
  });
  final Color labelBg;
  final Color tileBg;
}

_SeverityColors? _paletteFor(RowSeverity s) => switch (s) {
      RowSeverity.none => null,
      RowSeverity.emergency => const _SeverityColors(
          labelBg: Color(0xFFD32F2F),
          tileBg: Color(0xFFFFEBEE),
        ),
      RowSeverity.priority => const _SeverityColors(
          labelBg: Color(0xFFF57C00),
          tileBg: Color(0xFFFFF8E1),
        ),
      RowSeverity.nonUrgent => const _SeverityColors(
          labelBg: Color(0xFF388E3C),
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
          _Label(branch.label, theme: theme, labelBg: palette?.labelBg),
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
        _Label(branch.label, theme: theme, labelBg: palette?.labelBg),
        if (hasCriteria) _CriteriaBox(criteria: branch.criteria, theme: theme),
        if (hasCriteria && hasActions)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 2),
            child: Center(child: FlowDownArrow(length: 10)),
          ),
        for (final action in branch.actions)
          _ActionTile(action: action, theme: theme, tileBg: palette?.tileBg),
        if (addTrailingFill) const Expanded(child: _TrailingFillLine()),
      ],
    );
  }
}

/// Vertical line that fills its slot — no arrow head. Used as the
/// bottom of a [BranchColumn] to bridge the empty space between the
/// last action tile and the convergence hub below, so the arrow looks
/// continuous from the action down into the hub.
class _TrailingFillLine extends StatelessWidget {
  const _TrailingFillLine();

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

class _Label extends StatelessWidget {
  const _Label(this.text, {required this.theme, this.labelBg});

  final String text;
  final TopicTheme theme;
  final Color? labelBg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 1),
      color: labelBg ?? theme.branchAccent,
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _CriteriaBox extends StatelessWidget {
  const _CriteriaBox({required this.criteria, required this.theme});

  final List<String> criteria;
  final TopicTheme theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        border: Border.all(color: theme.nodeBorder.withValues(alpha: 0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final c in criteria)
            Text(
              '• $c',
              style: const TextStyle(fontSize: 11, height: 1.2),
            ),
        ],
      ),
    );
  }
}

/// Medication tile matching WVEMS format: full-height coloured provider
/// band on the left (E/A/I), bold underlined drug name on the right.
class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.action,
    required this.theme,
    this.tileBg,
  });

  final TopicAction action;
  final TopicTheme theme;
  final Color? tileBg;

  @override
  Widget build(BuildContext context) {
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
                  horizontal: 6,
                  vertical: 6,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      action.text,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 14,
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
                          fontSize: 11,
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
      width: 26,
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
