import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orbweaver/widgets/mini_markdown.dart';

Widget _wrap(String md) => MaterialApp(
      home: Scaffold(body: MiniMarkdown(markdown: md)),
    );

void main() {
  testWidgets('joins a bullet wrapped across source lines into one line',
      (tester) async {
    await tester.pumpWidget(_wrap('- alpha beta\n  gamma delta'));
    // The soft-wrapped continuation joins the bullet, so the full text
    // lives in a single (RichText) run rather than two separate lines.
    expect(
      find.textContaining('alpha beta gamma delta', findRichText: true),
      findsOneWidget,
    );
  });

  testWidgets('a bold span may straddle a source-line wrap', (tester) async {
    await tester.pumpWidget(_wrap('give **immediate\ntreatment** now'));
    // Lines join before bold parsing, so the asterisks are consumed (no
    // literal **) and the run reads as one sentence.
    expect(
      find.textContaining('give immediate treatment now', findRichText: true),
      findsOneWidget,
    );
    expect(find.textContaining('**', findRichText: true), findsNothing);
  });

  testWidgets('a blank line keeps two paragraphs separate', (tester) async {
    await tester.pumpWidget(_wrap('first para\n\nsecond para'));
    expect(find.textContaining('first para', findRichText: true),
        findsOneWidget);
    expect(find.textContaining('second para', findRichText: true),
        findsOneWidget);
    // They are NOT joined into one run.
    expect(
      find.textContaining('first para second para', findRichText: true),
      findsNothing,
    );
  });
}
