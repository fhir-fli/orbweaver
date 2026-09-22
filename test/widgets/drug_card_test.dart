// The drug card's Notes zone carries the Critical-Care signal.
//
// In the printed drug reference (PDF pp.118-143) every card has the same
// green Use zone and amber Caution zone, and the Notes zone is pale cyan
// #D0E0E3 — except on a Critical-Care drug, where it is lavender #D9D2E9.
// Verified by exact-RGB detection over all 26 pages: 11 of the 50 cards are
// lavender (3% Saline, Etomidate, Heparin, Lasix, Levophed, Lopressor, Neo
// Push, Propofol, Rocephin, Rocuronium, Succinylcholine), while p.124
// (Benadryl, Bicarb) and most of the book are cyan. Propofol also confirms
// that only the Notes zone changes: its Use stays green and Caution amber.
//
// The view used to hardcode one purple for every card, so every drug read as
// Critical Care and the signal meant nothing.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orbweaver/models/topic.dart';
import 'package:orbweaver/theme/palette.dart';
import 'package:orbweaver/theme/topic_theme.dart';
import 'package:orbweaver/widgets/blocks/drug_card_block_view.dart';

const _use = Color(0xFFD9EAD3);
const _caution = Color(0xFFFFF2CC);
const _notes = Color(0xFFD0E0E3);
const _notesCc = Color(0xFFD9D2E9);

/// Every zone fill in the card, in visual order (Use, Caution, Notes).
List<Color> _zoneFills(WidgetTester tester) => tester
    .widgetList<ColoredBox>(find.byType(ColoredBox))
    .map((c) => c.color)
    .where((c) => c != Colors.white)
    .toList();

Future<void> _pump(WidgetTester tester, {required bool criticalCare}) async {
  final theme = TopicTheme(
    resolvePalette([
      {'accent': const Color(0xFF3A5D64)},
    ]),
  );
  final block = DrugCardBlock(
    name: 'Rocephin',
    indications: const ['Infection'],
    contraindications: const ['Cephalosporin allergy'],
    pearls: const ['Reconstitute with 3 mL'],
    criticalCare: criticalCare,
  );
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: TopicThemeScope(
            theme: theme,
            child: DrugCardBlockView(block: block, theme: theme),
          ),
        ),
      ),
    ),
  );
}

void main() {
  group('drug card zones', () {
    testWidgets('an ordinary drug gets a cyan Notes zone', (tester) async {
      await _pump(tester, criticalCare: false);
      final fills = _zoneFills(tester);
      expect(fills, contains(_notes));
      expect(fills, isNot(contains(_notesCc)));
    });

    testWidgets('a Critical-Care drug gets a lavender Notes zone, and only '
        'the Notes zone changes', (tester) async {
      await _pump(tester, criticalCare: true);
      final fills = _zoneFills(tester);
      expect(fills, contains(_notesCc));
      expect(fills, isNot(contains(_notes)));
      // Use and Caution are the same on a CC drug (verified p.139, Propofol).
      expect(fills, contains(_use));
      expect(fills, contains(_caution));
    });
  });
}
