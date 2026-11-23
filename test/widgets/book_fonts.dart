import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

/// The fit guards must measure a page in the face the app draws it in. A
/// book can set `font_family:` (WVEMS uses RobotoCondensed, about 12%
/// narrower than Roboto), and TopicFrame applies it with
/// `DefaultTextStyle.merge` inside the Scaffold body (outside it, the
/// Scaffold's own text style wins). Measured in plain Roboto, all 46 English
/// WVEMS prose pages came out taller than in RobotoCondensed (2026-11-22).
Future<void> loadBookFonts(WidgetTester tester) async {
  final files = Directory('assets/fonts')
      .listSync()
      .whereType<File>()
      .where(
        (f) => f.path.contains('RobotoCondensed-') && f.path.endsWith('.ttf'),
      )
      .toList();
  expect(
    files,
    isNotEmpty,
    reason:
        'RobotoCondensed not found in assets/fonts; WVEMS pages would be '
        'measured in the wrong face.',
  );
  await tester.runAsync(() async {
    final loader = FontLoader('RobotoCondensed');
    for (final f in files) {
      loader.addFont(Future.value(f.readAsBytesSync().buffer.asByteData()));
    }
    await loader.load();
  });
}

/// The same wrapping TopicFrame gives a topic whose book sets a font.
Widget withBookFont(String? family, Widget child) => family == null
    ? child
    : DefaultTextStyle.merge(
        style: TextStyle(fontFamily: family),
        child: child,
      );
