// The dose-strip zebra encodes POPULATION, not the chapter.
//
// In the printed WVEMS book every flowchart page ends in a medication dose
// strip whose alternating row fills say who the doses are for: adult rows
// stripe #EFEFEF/#D9D9D9, paediatric rows #FFDCE2/#FFC0CB, on every chapter.
// Measured by column scanline on PDF p.24, where an adult table sits directly
// above a paediatric one and each restarts on its own light colour; p.12 and
// p.50 carry peds-only strips on a blue and a green page respectively, so the
// stripe does not follow the accent.
//
// The app used to stripe `theme.nodeFill` (= accent_fill, the chapter tint)
// for every row, which threw the population away and replaced it with a colour
// carrying no clinical information. These tests hold the fix in place.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orbweaver/models/topic.dart';
import 'package:orbweaver/theme/palette.dart';
import 'package:orbweaver/theme/topic_theme.dart';
import 'package:orbweaver/widgets/flowchart/dose_table.dart';

const _adultLight = Color(0xFFEFEFEF);
const _adultDark = Color(0xFFD9D9D9);
const _pedsLight = Color(0xFFFFDCE2);
const _pedsDark = Color(0xFFFFC0CB);

DoseRow _row(String drug, DosePopulation population) => DoseRow(
  drug: drug,
  dose: '1 mg',
  route: 'IV',
  frequency: 'once',
  population: population,
);

/// Every BoxDecoration colour in the tree, in visual order.
List<Color?> _decorationFills(WidgetTester tester) => tester
    .widgetList<Container>(find.byType(Container))
    .map((c) => c.decoration)
    .whereType<BoxDecoration>()
    .map((d) => d.color)
    .toList();

final _zebra = <Color>{_adultLight, _adultDark, _pedsLight, _pedsDark};
final _tabs = <Color>{const Color(0xFF666666), const Color(0xFFD23282)};

/// The row fills, in visual order — the population tab is drawn with a
/// BoxDecoration too now (the print puts it at the right edge of a group's
/// first row, not in a band above it), so the two are told apart by colour.
List<Color?> _rowFills(WidgetTester tester) =>
    _decorationFills(tester).where(_zebra.contains).toList();

/// The population tab fills, in visual order.
List<Color?> _tabFills(WidgetTester tester) =>
    _decorationFills(tester).where(_tabs.contains).toList();

Future<void> _pump(
  WidgetTester tester,
  List<DoseRow> rows, {
  Color accent = const Color(0xFF1E4E8C),
}) async {
  final theme = TopicTheme(
    resolvePalette([
      {'accent': accent},
    ]),
  );
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: TopicThemeScope(
          theme: theme,
          child: DoseTable(rows: rows, theme: theme),
        ),
      ),
    ),
  );
}

void main() {
  group('dose-table zebra', () {
    testWidgets('adult rows stripe grey, peds rows pink, each group '
        'restarting light', (tester) async {
      await _pump(tester, [
        _row('Epi', DosePopulation.adult),
        _row('Amiodarone', DosePopulation.adult),
        _row('Epi', DosePopulation.peds),
        _row('Amiodarone', DosePopulation.peds),
      ]);

      // The outer border container has no colour, so drop it.
      final fills = _rowFills(tester).whereType<Color>().toList();
      expect(fills, [_adultLight, _adultDark, _pedsLight, _pedsDark]);
    });

    testWidgets('the stripe does not follow the chapter accent', (
      tester,
    ) async {
      final rows = [
        _row('Epi', DosePopulation.peds),
        _row('Amiodarone', DosePopulation.peds),
      ];

      await _pump(tester, rows); // Universal
      final onBlue = _rowFills(tester).whereType<Color>().toList();

      await _pump(tester, rows, accent: const Color(0xFF2E7D32)); // Medical
      final onGreen = _rowFills(tester).whereType<Color>().toList();

      expect(onBlue, [_pedsLight, _pedsDark]);
      expect(onGreen, onBlue);
    });

    testWidgets('a strip that does not distinguish population takes the '
        'adult greys', (tester) async {
      await _pump(tester, [
        _row('Epi', DosePopulation.both),
        _row('Amiodarone', DosePopulation.both),
        _row('Atropine', DosePopulation.both),
      ]);

      final fills = _rowFills(tester).whereType<Color>().toList();
      expect(fills, [_adultLight, _adultDark, _adultLight]);
    });

    testWidgets('the population tab takes the print colours, white on '
        'solid', (tester) async {
      await _pump(tester, [
        _row('Epi', DosePopulation.adult),
        _row('Epi', DosePopulation.peds),
      ]);

      expect(_tabFills(tester), [
        const Color(0xFF666666),
        const Color(0xFFD23282),
      ]);

      for (final label in ['Adult', 'Peds']) {
        final text = tester.widget<Text>(find.text(label));
        expect(text.style?.color, Colors.white);
      }
    });
  });
}
