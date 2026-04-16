import 'package:flutter/material.dart';
import 'package:orbweaver/models/topic.dart';
import 'package:orbweaver/theme/topic_theme.dart';

/// A flowchart node (entry / decision / convergence / action).
///
/// Shape is taken from [NodeShape]. The "diamond" shape is faked with a
/// rounded rectangle and a clipped chevron band — real geometric diamonds
/// waste too much vertical space on a narrow screen.
class FlowNodeBox extends StatelessWidget {
  const FlowNodeBox({
    required this.text,
    required this.shape,
    required this.theme,
    this.compact = false,
    super.key,
  });

  final String text;
  final NodeShape shape;
  final TopicTheme theme;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final radius = switch (shape) {
      NodeShape.stadium => 999.0,
      NodeShape.roundedRectangle => 12.0,
      NodeShape.rectangle => 4.0,
      NodeShape.diamond => 8.0,
    };

    final padding = compact
        ? const EdgeInsets.symmetric(horizontal: 6, vertical: 2)
        : const EdgeInsets.symmetric(horizontal: 8, vertical: 3);

    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: shape == NodeShape.diamond
            ? theme.branchAccent.withValues(alpha: 0.15)
            : theme.nodeFill,
        border: Border.all(
          color: theme.nodeBorder,
          width: shape == NodeShape.diamond ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: compact ? 12 : 13,
          height: 1.2,
          fontWeight: shape == NodeShape.diamond
              ? FontWeight.w700
              : FontWeight.w500,
          color: Colors.black87,
        ),
      ),
    );
  }
}
