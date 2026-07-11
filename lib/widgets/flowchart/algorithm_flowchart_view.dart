import 'package:flutter/material.dart';
import 'package:orbweaver/models/topic.dart';
import 'package:orbweaver/theme/topic_theme.dart';
import 'package:orbweaver/widgets/flowchart/flow_node.dart';

/// Renders a `algorithm`-variant flowchart: a vertical multi-decision
/// clinical algorithm.
///
/// Layout is a single top-to-bottom spine — an optional entry stadium,
/// then each [AlgoStage] as a decision box with its labelled outcomes
/// stacked beneath, then an optional terminal disposition. Outcomes that
/// `continue` rejoin the spine (a down-arrow leads to the next stage);
/// outcomes that terminate render as severity-tinted leaf boxes. A `goto`
/// outcome resolves its named shared box and renders it inline.
///
/// This deliberately avoids a 2-D node graph: loop-backs are expressed as
/// labelled references to named boxes, so a branching algorithm stays a
/// clean vertical flow that reads well on a phone.
class AlgorithmFlowchartView extends StatelessWidget {
  const AlgorithmFlowchartView({
    required this.flowchart,
    required this.theme,
    super.key,
  });

  final AlgorithmFlowchart flowchart;
  final TopicTheme theme;

  @override
  Widget build(BuildContext context) {
    final stages = flowchart.stages;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (flowchart.entry != null) ...[
          FlowNodeBox(
            text: flowchart.entry!.text,
            shape: flowchart.entry!.shape,
            theme: theme,
          ),
          const _SpineArrow(),
        ],
        for (var i = 0; i < stages.length; i++) ...[
          _StageView(stage: stages[i], flowchart: flowchart, theme: theme),
          if (i < stages.length - 1 || flowchart.terminal != null)
            const _SpineArrow(),
        ],
        if (flowchart.terminal != null)
          _AlgoBoxView(box: flowchart.terminal!, theme: theme, terminal: true),
      ],
    );
  }
}

/// One decision stage: the decision box, then its outcomes stacked below.
class _StageView extends StatelessWidget {
  const _StageView({
    required this.stage,
    required this.flowchart,
    required this.theme,
  });

  final AlgoStage stage;
  final AlgorithmFlowchart flowchart;
  final TopicTheme theme;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _DecisionBox(
          decision: stage.decision,
          criteria: stage.criteria,
          theme: theme,
        ),
        const SizedBox(height: 6),
        for (final o in stage.outcomes)
          _OutcomeView(
            outcome: o,
            box: flowchart.boxFor(o),
            theme: theme,
          ),
      ],
    );
  }
}

/// A single labelled outcome: an answer label + the box it leads to.
class _OutcomeView extends StatelessWidget {
  const _OutcomeView({
    required this.outcome,
    required this.box,
    required this.theme,
  });

  final AlgoOutcome outcome;
  final AlgoBox? box;
  final TopicTheme theme;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 12, bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.subdirectory_arrow_right,
                  size: 15, color: Colors.black45),
              const SizedBox(width: 3),
              Flexible(
                child: Text(
                  outcome.label,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
              ),
              // A tiny cue that this branch rejoins the main flow rather
              // than ending here.
              if (outcome.cont) ...[
                const SizedBox(width: 4),
                const Text(
                  '(continue ↓)',
                  style: TextStyle(
                    fontSize: 10,
                    fontStyle: FontStyle.italic,
                    color: Colors.black38,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 2),
          if (box != null)
            _AlgoBoxView(box: box!, theme: theme, terminal: !outcome.cont),
        ],
      ),
    );
  }
}

/// The decision prompt box (bold question + optional criteria bullets),
/// filled with the branch accent so it reads clearly as a decision point.
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: theme.branchAccent.withValues(alpha: 0.15),
        border: Border.all(color: theme.nodeBorder, width: 2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            decision,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              height: 1.2,
            ),
          ),
          for (final c in criteria)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                '• $c',
                style: const TextStyle(fontSize: 11, height: 1.2),
              ),
            ),
        ],
      ),
    );
  }
}

/// A result box — an outcome's disposition/step or a shared box. Terminal
/// (leaf) boxes get a heavier border; severity tints the fill.
class _AlgoBoxView extends StatelessWidget {
  const _AlgoBoxView({
    required this.box,
    required this.theme,
    this.terminal = false,
  });

  final AlgoBox box;
  final TopicTheme theme;
  final bool terminal;

  @override
  Widget build(BuildContext context) {
    final fill = _severityFill(theme, box.severity);
    final border = _severityBorder(theme, box.severity) ?? theme.nodeBorder;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: fill ?? Colors.white,
        border: Border.all(color: border, width: terminal ? 2 : 1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            box.title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              height: 1.2,
            ),
          ),
          for (final b in box.bullets)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                '• $b',
                style: const TextStyle(fontSize: 11, height: 1.2),
              ),
            ),
        ],
      ),
    );
  }
}

/// A centered down-arrow linking one spine element to the next.
class _SpineArrow extends StatelessWidget {
  const _SpineArrow();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 2),
      child: Icon(Icons.arrow_downward, size: 16, color: Colors.black45),
    );
  }
}

Color? _severityFill(TopicTheme t, RowSeverity s) => switch (s) {
      RowSeverity.emergency => t.severitySevereTile,
      RowSeverity.priority => t.severityModerateTile,
      RowSeverity.nonUrgent => t.severityMildTile,
      RowSeverity.none => null,
    };

Color? _severityBorder(TopicTheme t, RowSeverity s) => switch (s) {
      RowSeverity.emergency => t.severitySevereHeader,
      RowSeverity.priority => t.severityModerateHeader,
      RowSeverity.nonUrgent => t.severityMildHeader,
      RowSeverity.none => null,
    };
