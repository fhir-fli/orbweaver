import 'package:flutter/material.dart';
import 'package:orbweaver/models/topic.dart';
import 'package:orbweaver/theme/topic_theme.dart';

/// Compact medication dose reference strip at the bottom of the flowchart.
class DoseTable extends StatelessWidget {
  const DoseTable({
    required this.rows,
    required this.theme,
    super.key,
  });

  final List<DoseRow> rows;
  final TopicTheme theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: theme.nodeBorder),
      ),
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: i.isEven
                    ? theme.nodeFill
                    : theme.nodeFill.withValues(alpha: 0.5),
                border: i == 0
                    ? null
                    : Border(
                        top: BorderSide(
                          color: theme.nodeBorder.withValues(alpha: 0.4),
                        ),
                      ),
              ),
              child: _DoseRowView(row: rows[i]),
            ),
        ],
      ),
    );
  }
}

class _DoseRowView extends StatelessWidget {
  const _DoseRowView({required this.row});

  final DoseRow row;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: Text(
            row.drug,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            row.dose,
            style: const TextStyle(fontSize: 12),
          ),
        ),
        Expanded(
          flex: 2,
          child: Text(
            row.route,
            style: const TextStyle(fontSize: 12),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            row.frequency,
            textAlign: TextAlign.right,
            style: const TextStyle(fontSize: 12),
          ),
        ),
      ],
    );
  }
}
