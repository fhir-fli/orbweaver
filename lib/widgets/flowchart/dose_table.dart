import 'package:flutter/material.dart';
import 'package:orbweaver/models/topic.dart';
import 'package:orbweaver/theme/topic_theme.dart';
import 'package:orbweaver/widgets/flowchart/flow_link.dart';

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
      final wantsTab =
          showLabels && startsGroup && row.population != DosePopulation.both;
      children.add(
        Container(
          width: double.infinity,
          padding: const EdgeInsets.only(left: 6, top: 3, bottom: 3),
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
          child: Row(
            children: [
              Expanded(child: _DoseRowView(row: row)),
              if (wantsTab)
                _PopulationTab(population: row.population)
              else
                const SizedBox(width: 6),
            ],
          ),
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

/// The print's population tab: a solid block at the **right edge of the first
/// row** of each population group — `#666666` for adult, `#D23282` for peds,
/// white bold text — not a band above the group.
///
/// Measured on p.24, where an adult dose strip sits directly above a
/// paediatric one: each group's tab is one row tall, attached to that group's
/// first row, and rounded on its outer edge.
class _PopulationTab extends StatelessWidget {
  const _PopulationTab({required this.population});

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
      margin: const EdgeInsets.only(left: 6),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.horizontal(right: Radius.circular(4)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.3,
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
          child: FlowLinkText(
            row.drug,
            textAlign: TextAlign.left,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: FlowLinkText(
            row.dose,
            textAlign: TextAlign.left,
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
