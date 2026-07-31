// Covers the `band_callout` block end to end: YAML -> BandCalloutBlock ->
// BandCalloutBlockView, both bands, and the palette cascade that colours it.
//
// This is the peds / Critical Care convention from the printed protocols
// (PDF pp.11, 13, 71, 79): a section bracket and a content band in pink for
// paediatric content and lavender for Critical Care. It must NOT follow the
// chapter accent — on Burns the accent is salmon and on Seizure it is green,
// yet the print's peds band is pink on both, which is exactly the bug that
// `highlight: true` has when it is used to mark a peds section.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orbweaver/models/topic.dart';
import 'package:orbweaver/theme/palette.dart';
import 'package:orbweaver/theme/topic_theme.dart';
import 'package:orbweaver/widgets/section_bracket.dart';
import 'package:orbweaver/widgets/topic_view.dart';

/// A one-page topic whose only block is the given YAML block body.
String _topicYaml(String blockYaml) => '''
topic:
  id: "t"
  title: "T"
  layout: "paged"
  pages:
  - page_number: 1
    blocks:
$blockYaml
''';

Future<Topic> _pump(WidgetTester tester, String blockYaml,
    {Color accent = const Color(0xFFDD7E6B)}) async {
  final topic = Topic.fromYamlString(_topicYaml(blockYaml));
  final theme = TopicTheme(resolvePalette([
    {'accent': accent},
    {for (final e in topic.ownPaletteArgb.entries) e.key: Color(e.value)},
  ]));
  await tester.pumpWidget(MaterialApp(
    home: Scaffold(
      body: SingleChildScrollView(
        child: TopicPageBody(page: topic.pages.first, theme: theme),
      ),
    ),
  ));
  return topic;
}

/// The bracket the band renders through (there is exactly one per band).
SectionBracket _bracket(WidgetTester tester) =>
    tester.widget<SectionBracket>(find.byType(SectionBracket));

void main() {
  group('band_callout', () {
    testWidgets('peds band parses and renders pink, not the chapter accent',
        (tester) async {
      // Salmon accent = the Burns chapter, where print still uses pink.
      final topic = await _pump(tester, '''
    - type: "band_callout"
      band: "peds"
      markdown: |
        - Use **Peds Reference** for peds dosing.
''');

      final block = topic.pages.first.blocks.single;
      expect(block, isA<BandCalloutBlock>());
      expect((block as BandCalloutBlock).band, CalloutBand.peds);

      final bracket = _bracket(tester);
      expect(bracket.color, kRoleDefaults['peds_band_rule']);
      expect(bracket.bodyFill, kRoleDefaults['peds_band_fill']);
      // Title falls back to the print's section label.
      expect(bracket.title, 'Pediatrics');
      expect(find.text('Pediatrics'), findsOneWidget);
      expect(find.textContaining('Peds Reference'), findsOneWidget);
    });

    testWidgets('critical_care band renders lavender with its own label',
        (tester) async {
      final topic = await _pump(tester, '''
    - type: "band_callout"
      band: "critical_care"
      markdown: |
        - Consider **Malignant HTN** if credentialed for CC.
''');

      expect(
        (topic.pages.first.blocks.single as BandCalloutBlock).band,
        CalloutBand.criticalCare,
      );
      final bracket = _bracket(tester);
      expect(bracket.color, kRoleDefaults['cc_band_rule']);
      expect(bracket.bodyFill, kRoleDefaults['cc_band_fill']);
      expect(bracket.title, 'Critical Care');
    });

    testWidgets('an explicit title overrides the default label',
        (tester) async {
      await _pump(tester, '''
    - type: "band_callout"
      band: "peds"
      title: "Infants"
      markdown: |
        - Refer to Neonate under 30 days.
''');
      expect(_bracket(tester).title, 'Infants');
    });

    testWidgets('an empty title gives a bare band with no heading',
        (tester) async {
      // The print's line-level use: a single tinted line inside somebody
      // else's section (PDF p.79's "Etomidate is not appropriate under 10").
      await _pump(tester, '''
    - type: "band_callout"
      band: "peds"
      title: ""
      markdown: |
        - Etomidate is not appropriate under 10 y/o.
''');
      final bracket = _bracket(tester);
      expect(bracket.title, isNull);
      expect(bracket.bodyFill, kRoleDefaults['peds_band_fill']);
    });

    testWidgets('a block-level palette override re-skins the band',
        (tester) async {
      // Proves the colours are palette roles, not constants at the use site.
      await _pump(tester, '''
    - type: "band_callout"
      band: "peds"
      palette:
        peds_band_fill: "0xFF112233"
        peds_band_rule: "0xFF445566"
      markdown: |
        - Overridden.
''');
      final bracket = _bracket(tester);
      expect(bracket.bodyFill, const Color(0xFF112233));
      expect(bracket.color, const Color(0xFF445566));
    });
  });
}
