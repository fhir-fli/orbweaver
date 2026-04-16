import 'package:flutter/material.dart';
import 'package:orbweaver/models/topic.dart';
import 'package:orbweaver/theme/topic_theme.dart';
import 'package:orbweaver/widgets/flowchart/flow_node.dart';

/// Renders a `cascade`-variant flowchart as a vertical chain of decisions.
///
/// Each step has:
///   - a decision box (single-line question or question + bullet criteria)
///   - an action tile on the right (labelled Yes or No)
///   - a continuation arrow below (labelled with the opposite answer)
///
/// The cascade optionally ends with a terminal action box rendered below
/// the last decision — used when falling through all checks implies a
/// default treatment (e.g. "perform LP" after all meningitis
/// contraindication checks pass).
class CascadeFlowchartView extends StatelessWidget {
  const CascadeFlowchartView({
    required this.flowchart,
    required this.theme,
    super.key,
  });

  final CascadeFlowchart flowchart;
  final TopicTheme theme;

  List<CascadeStep> _flatten() {
    final out = <CascadeStep>[];
    CascadeStep? cur = flowchart.root;
    while (cur != null) {
      out.add(cur);
      cur = cur.continuation;
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final steps = _flatten();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FlowNodeBox(
          text: flowchart.entry.text,
          shape: flowchart.entry.shape,
          theme: theme,
        ),
        for (var i = 0; i < steps.length; i++)
          _StepRow(
            step: steps[i],
            theme: theme,
            isLast: i == steps.length - 1,
            actionWidthFraction: flowchart.actionWidthFraction,
          ),
        if (flowchart.terminalAction != null)
          _TerminalAction(action: flowchart.terminalAction!, theme: theme),
      ],
    );
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({
    required this.step,
    required this.theme,
    required this.isLast,
    required this.actionWidthFraction,
  });

  final CascadeStep step;
  final TopicTheme theme;
  final bool isLast;
  final double actionWidthFraction;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final actionWidth =
            constraints.maxWidth * actionWidthFraction.clamp(0.1, 0.9);
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _DecisionBox(
                    decision: step.decision,
                    criteria: step.criteria,
                    theme: theme,
                  ),
                  if (!isLast)
                    _ContinuationArrow(label: step.continuationAnswer),
                ],
              ),
            ),
            if (step.action != null) ...[
              _YesNoArrow(label: step.actionAnswer),
              SizedBox(
                width: actionWidth,
                child: _ActionBox(action: step.action!, theme: theme),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _DecisionBox extends StatelessWidget {
  const _DecisionBox({
    required this.decision,
    required this.criteria,
    required this.theme,
  });

  final String decision;
  final List<String> criteria;
  final TopicTheme theme;

  @override
  Widget build(BuildContext context) {
    if (criteria.isEmpty) {
      return FlowNodeBox(
        text: decision,
        shape: NodeShape.diamond,
        theme: theme,
        compact: true,
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: theme.branchAccent.withValues(alpha: 0.15),
        border: Border.all(color: theme.nodeBorder, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            decision,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 2),
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

class _ActionBox extends StatelessWidget {
  const _ActionBox({required this.action, required this.theme});

  final TopicAction action;
  final TopicTheme theme;

  @override
  Widget build(BuildContext context) {
    final hasAnnotations = action.timing != null || action.condition != null;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: theme.nodeFill,
        border: Border.all(color: theme.nodeBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            action.text,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              height: 1.2,
            ),
          ),
          if (hasAnnotations)
            Text(
              [
                if (action.timing != null) action.timing!,
                if (action.condition != null) action.condition!,
              ].join(' · '),
              style: const TextStyle(
                fontSize: 11,
                fontStyle: FontStyle.italic,
                color: Colors.black54,
              ),
            ),
        ],
      ),
    );
  }
}

class _YesNoArrow extends StatelessWidget {
  const _YesNoArrow({required this.label});

  final YesNo label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label.label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Colors.black54,
            ),
          ),
          const SizedBox(width: 2),
          const Icon(Icons.arrow_forward, size: 14, color: Colors.black54),
        ],
      ),
    );
  }
}

/// Vertical connector shown below a decision box, labelled with the answer
/// that leads to the next step (the one that did NOT trigger the action).
class _ContinuationArrow extends StatelessWidget {
  const _ContinuationArrow({required this.label});

  final YesNo label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label.label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Colors.black54,
            ),
          ),
          const SizedBox(width: 2),
          const Icon(Icons.arrow_downward, size: 14, color: Colors.black54),
        ],
      ),
    );
  }
}

class _TerminalAction extends StatelessWidget {
  const _TerminalAction({required this.action, required this.theme});

  final TopicAction action;
  final TopicTheme theme;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        decoration: BoxDecoration(
          color: theme.nodeFill,
          border: Border.all(color: theme.nodeBorder, width: 2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              action.text,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                height: 1.2,
              ),
            ),
            if (action.timing != null || action.condition != null)
              Text(
                [
                  if (action.timing != null) action.timing!,
                  if (action.condition != null) action.condition!,
                ].join(' · '),
                style: const TextStyle(
                  fontSize: 11,
                  fontStyle: FontStyle.italic,
                  color: Colors.black54,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
