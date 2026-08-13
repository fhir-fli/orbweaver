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
    // Row index *within the current population group*. The print restarts
    // each group's zebra on its light colour (verified on p.24, where the
    // paediatric table under the adult one begins #FFDCE2, not #FFC0CB).
    var indexInGroup = 0;
    for (var i = 0; i < rows.length; i++) {
      final row = rows[i];
      final startsGroup = i == 0 || rows[i - 1].population != row.population;
      if (startsGroup) indexInGroup = 0;
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
            color: _stripe(theme, row.population, indexInGroup),
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
      indexInGroup++;
    }

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: theme.nodeBorder),
      ),
      child: Column(children: children),
    );
  }
}

/// The zebra fill for a dose row. The *pair* of alternating colours encodes
/// the population — grey for adult doses, pink for paediatric ones — so a
/// reader can tell whose dose a row is from the fill alone, without finding
/// the group header. `both` (a strip that does not distinguish) takes the
/// adult greys, which is what the print does on single-population pages.
Color _stripe(TopicTheme theme, DosePopulation population, int indexInGroup) {
  final light = population == DosePopulation.peds
      ? theme.pedsRowLight
      : theme.adultRowLight;
  final dark = population == DosePopulation.peds
      ? theme.pedsRowDark
      : theme.adultRowDark;
  return indexInGroup.isEven ? light : dark;
}

/// Thin full-width band labeling the dose rows that follow as Adult or Peds.
/// Print draws it as a right-hand vertical tab — solid #666666 for adult,
/// solid #D23282 for peds, white text; the app keeps the full-width
/// horizontal band (a better fit on a phone) and takes the tab's colours.
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
          color: Colors.white,
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
