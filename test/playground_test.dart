// The docs-site playground: paste YAML, see the real renderer's output and
// the schema's verdict.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orbweaver/main_playground.dart';
import 'package:orbweaver/widgets/topic_view.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> boot(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    // The schema and the first example load through real asset IO, which
    // fake test time does not advance; poll under runAsync until the first
    // render has happened.
    await tester.runAsync(() async {
      await tester.pumpWidget(const PlaygroundApp());
      for (var i = 0; i < 200; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 25));
        await tester.pump();
        if (find.byKey(const Key('valid')).evaluate().isNotEmpty) return;
      }
    });
  }

  testWidgets('boots on the first example, valid, and renders it', (
    tester,
  ) async {
    await boot(tester);
    expect(find.byKey(const Key('valid')), findsOneWidget);
    expect(find.byType(TopicView), findsOneWidget);
  });

  testWidgets('a misspelt key is named and the page still renders', (
    tester,
  ) async {
    await boot(tester);
    await tester.enterText(find.byKey(const Key('yaml')), '''
topic:
  id: "t"
  title: "T"
  blocks:
    - type: "prose"
      markdown: "hello"
      markdwn: "typo"
''');
    await tester.tap(find.byKey(const Key('render')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('schema-problems')), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const Key('schema-problems')),
        matching: find.textContaining('markdwn'),
      ),
      findsOneWidget,
    );
    expect(find.byType(TopicView), findsOneWidget);
  });

  testWidgets('a topic the app cannot read shows the error, no page', (
    tester,
  ) async {
    await boot(tester);
    await tester.enterText(find.byKey(const Key('yaml')), '''
topic:
  id: "t"
  title: "T"
  blocks:
    - type: "proze"
      markdown: "hello"
''');
    await tester.tap(find.byKey(const Key('render')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('parse-error')), findsOneWidget);
    expect(find.byType(TopicView), findsNothing);
  });

  testWidgets('every example loads valid', (tester) async {
    await boot(tester);
    for (final e in kExamples) {
      await tester.tap(find.byType(DropdownButton<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text(e.label).last);
      await tester.runAsync(() async {
        for (var i = 0; i < 200; i++) {
          await Future<void>.delayed(const Duration(milliseconds: 25));
          await tester.pump();
          if (find.byType(TopicView).evaluate().isNotEmpty &&
              find.byKey(const Key('valid')).evaluate().isNotEmpty) {
            return;
          }
        }
      });
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('valid')), findsOneWidget, reason: e.label);
      expect(find.byType(TopicView), findsOneWidget, reason: e.label);
    }
  });
}
