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
    // Show Adult / Peds section labels only when the table actually
    // mixes populations (matches the WVEMS PDF's gray Adult / pink Peds
    // tabs). A table whose rows are all `both` renders label-free, as
    // before — the common case for single-population dose strips.
    final showLabels = rows.any((r) => r.population != DosePopulation.both);

    final children = <Widget>[];
    for (var i = 0; i < rows.length; i++) {
      final row = rows[i];
      final startsGroup = i == 0 || rows[i - 1].population != row.population;
      if (showLabels &&
          startsGroup &&
          row.population != DosePopulation.both) {
        children.add(_PopulationLabel(population: row.population));
      }
      children.add(
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
          child: _DoseRowView(row: row),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: theme.nodeBorder),
      ),
      child: Column(children: children),
    );
  }
}

/// Thin full-width band labeling the dose rows that follow as Adult or
/// Peds — gray for adult, pink for peds, matching the WVEMS PDF.
class _PopulationLabel extends StatelessWidget {
  const _PopulationLabel({required this.population});

  final DosePopulation population;

  @override
  Widget build(BuildContext context) {
    final theme = TopicThemeScope.of(context);
    final (label, bg) = switch (population) {
      DosePopulation.adult => ('Adult', theme.popAdult),
      DosePopulation.peds => ('Peds', theme.popPeds),
      DosePopulation.both => ('', Colors.transparent),
    };
    return Container(
      width: double.infinity,
      color: bg,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
          color: Colors.black87,
        ),
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
