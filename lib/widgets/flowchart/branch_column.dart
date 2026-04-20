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
    super.key,
  });

  final TopicBranch branch;
  final TopicTheme theme;

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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Label(branch.label, theme: theme, labelBg: palette?.labelBg),
        if (branch.criteria.isNotEmpty)
          _CriteriaBox(criteria: branch.criteria, theme: theme),
        for (final action in branch.actions)
          _ActionTile(action: action, theme: theme, tileBg: palette?.tileBg),
      ],
    );
  }
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
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        color: tileBg ?? theme.nodeFill,
        border: Border.all(color: theme.nodeBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (action.providerLevel != ProviderLevel.any) ...[
            _ProviderBadge(level: action.providerLevel),
            const SizedBox(width: 4),
          ],
          Expanded(
            child: Text(
              action.text,
              style: const TextStyle(
                fontSize: 12,
                height: 1.2,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProviderBadge extends StatelessWidget {
  const _ProviderBadge({required this.level});

  final ProviderLevel level;

  @override
  Widget build(BuildContext context) {
    final (letter, color) = switch (level) {
      ProviderLevel.emt => ('E', const Color(0xFF2E7D32)),
      ProviderLevel.intermediate => ('I', const Color(0xFFE65100)),
      ProviderLevel.als => ('A', const Color(0xFFC62828)),
      ProviderLevel.any => ('', Colors.transparent),
    };

    return Container(
      width: 16,
      height: 16,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(
        letter,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: Colors.white,
        ),
      ),
    );
  }
}
