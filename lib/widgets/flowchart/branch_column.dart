import 'package:flutter/material.dart';
import 'package:orbweaver/models/topic.dart';
import 'package:orbweaver/theme/topic_theme.dart';

/// One branch from the decision diamond — rendered as a vertical column:
///   label header → criteria bullets → stacked action items.
///
/// Each action displays its provider-level badge (A/E/I) on the left if set.
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Label(branch.label, theme: theme),
        if (branch.criteria.isNotEmpty)
          _CriteriaBox(criteria: branch.criteria, theme: theme),
        for (final action in branch.actions)
          _ActionTile(action: action, theme: theme),
      ],
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text, {required this.theme});

  final String text;
  final TopicTheme theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 1),
      color: theme.branchAccent,
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
  const _ActionTile({required this.action, required this.theme});

  final TopicAction action;
  final TopicTheme theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        color: theme.nodeFill,
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
