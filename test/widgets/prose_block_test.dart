// Covers the two prose treatments taken from the printed protocols:
//   - titled prose is a bracketed *section* (PDF pp.11, 43, 71 — a "[" down
//     the left with the title in the gap and the body running full width),
//     not a full-width header bar;
//   - a `callout:` box may be drawn dashed to mean *conditional*, which is
//     how the print separates p.71's "Call a TRAUMA Alert" box from the
//     solid "ABLS rate:" box beside it.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orbweaver/models/topic.dart';
import 'package:orbweaver/theme/palette.dart';
import 'package:orbweaver/theme/topic_theme.dart';
import 'package:orbweaver/widgets/section_bracket.dart';
import 'package:orbweaver/widgets/topic_view.dart';

const Color kAccent = Color(0xFF6D9EEB);

String _topicYaml(String blockYaml) =>
    '''
topic:
  id: "t"
  title: "T"
  layout: "paged"
  pages:
  - page_number: 1
    blocks:
$blockYaml
''';

Future<Topic> _pump(WidgetTester tester, String blockYaml) async {
  final topic = Topic.fromYamlString(_topicYaml(blockYaml));
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: TopicPageBody(
            page: topic.pages.first,
            theme: TopicTheme(
              resolvePalette([
                {'accent': kAccent},
              ]),
            ),
          ),
        ),
      ),
    ),
  );
  return topic;
}

void main() {
  group('titled prose renders as a bracketed section', () {
    testWidgets('bracket takes the accent and no tint without highlight', (
      tester,
    ) async {
      await _pump(tester, '''
    - type: "prose"
      title: "Notes"
      markdown: |
        - Rule of 9s can estimate BSA in adults.
''');
      final bracket = tester.widget<SectionBracket>(
        find.byType(SectionBracket),
      );
      expect(bracket.color, kAccent);
      expect(bracket.title, 'Notes');
      expect(bracket.bodyFill, isNull);
    });

    testWidgets('highlight tints the body only', (tester) async {
      await _pump(tester, '''
    - type: "prose"
      title: "Imperatives"
      highlight: true
      markdown: |
        - Confirm elevated systolic BP.
''');
      expect(
        tester.widget<SectionBracket>(find.byType(SectionBracket)).bodyFill,
        isNotNull,
      );
    });

    testWidgets('untitled prose is not bracketed', (tester) async {
      await _pump(tester, '''
    - type: "prose"
      markdown: |
        - A bare run of text.
''');
      expect(find.byType(SectionBracket), findsNothing);
    });
  });

  group('callout outline', () {
    /// The decorated box the callout draws its border with.
    DecoratedBox _card(WidgetTester tester) => tester
        .widgetList<DecoratedBox>(find.byType(DecoratedBox))
        .firstWhere((d) {
          final dec = d.decoration;
          return dec is BoxDecoration && dec.borderRadius != null;
        });

    testWidgets('solid by default', (tester) async {
      await _pump(tester, '''
    - type: "prose"
      title: "ABLS rate:"
      callout: true
      markdown: |
        - 14+ y/o: 500 mL/hr
''');
      final card = _card(tester);
      expect((card.decoration as BoxDecoration).border, isNotNull);
      // No foreground pass is installed when the border is solid.
      expect(
        tester
            .widgetList<DecoratedBox>(find.byType(DecoratedBox))
            .where((d) => d.position == DecorationPosition.foreground),
        isEmpty,
      );
    });

    testWidgets('dashed: true swaps the solid border for a dashed overlay', (
      tester,
    ) async {
      final topic = await _pump(tester, '''
    - type: "prose"
      title: "TRAUMA Alert"
      callout: true
      dashed: true
      markdown: |
        - If Major Intervention
        - Or Major Mechanism
''');
      expect((topic.pages.first.blocks.single as ProseBlock).dashed, isTrue);
      final card = _card(tester);
      expect((card.decoration as BoxDecoration).border, isNull);
      expect(
        tester
            .widgetList<DecoratedBox>(find.byType(DecoratedBox))
            .where((d) => d.position == DecorationPosition.foreground),
        isNotEmpty,
      );
    });
  });
}
