import 'package:flutter/material.dart';
import 'package:orbweaver/models/topic.dart';
import 'package:orbweaver/theme/topic_theme.dart';
import 'package:orbweaver/widgets/flowchart/branch_column.dart';
import 'package:orbweaver/widgets/flowchart/dose_table.dart';
import 'package:orbweaver/widgets/flowchart/flow_node.dart';

/// Renders a severity-variant flowchart:
///   entry → decision → branches → convergence → dose table.
///
/// The topic header (title + page number) is NOT rendered here — it lives
/// one level up in `TopicView` so every block in a topic sits under the
/// same header.
class SeverityFlowchartView extends StatelessWidget {
  const SeverityFlowchartView({
    required this.flowchart,
    required this.theme,
    super.key,
  });

  final SeverityFlowchart flowchart;
  final TopicTheme theme;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FlowNodeBox(
          text: flowchart.entry.text,
          shape: flowchart.entry.shape,
          theme: theme,
        ),
        FlowNodeBox(
          text: flowchart.decision.text,
          shape: flowchart.decision.shape,
          theme: theme,
        ),
        _BranchesRow(branches: flowchart.branches, theme: theme),
        if (flowchart.convergence != null)
          _ConvergenceBox(node: flowchart.convergence!, theme: theme),
        if (flowchart.doseTable.isNotEmpty)
          DoseTable(rows: flowchart.doseTable, theme: theme),
      ],
    );
  }
}

class _BranchesRow extends StatelessWidget {
  const _BranchesRow({required this.branches, required this.theme});

  final List<TopicBranch> branches;
  final TopicTheme theme;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < branches.length; i++) ...[
            if (i > 0) const SizedBox(width: 4),
            Expanded(
              child: BranchColumn(branch: branches[i], theme: theme),
            ),
          ],
        ],
      ),
    );
  }
}

class _ConvergenceBox extends StatelessWidget {
  const _ConvergenceBox({required this.node, required this.theme});

  final ConvergenceNode node;
  final TopicTheme theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: theme.nodeFill,
        border: Border.all(color: theme.nodeBorder, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            node.text,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Wrap(
            spacing: 8,
            runSpacing: 2,
            children: [
              for (final b in node.bullets)
                Text(
                  '• ${b.text}',
                  style: const TextStyle(fontSize: 12, height: 1.2),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
