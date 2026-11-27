// Pictures with English text baked in get a Spanish copy (tool/l10n/images.py
// writes it to `images/es/<same name>`). The renderer shows that copy in
// Spanish, the English file everywhere else, and WHO pictures never have a
// copy: licence 202610340 (WHO-LICENCE.md) says "Translating: No".

import 'package:flutter/services.dart' show AssetManifest, rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:orbweaver/data/localized_asset.dart';
import 'package:orbweaver/models/topic.dart';
import 'package:orbweaver/theme/palette.dart';
import 'package:orbweaver/theme/topic_theme.dart';
import 'package:orbweaver/widgets/blocks/image_block_view.dart';

const _waveform = 'assets/books/protocolbook/images/pb_ecg_waveform.png';
const _waveformEs = 'assets/books/protocolbook/images/es/pb_ecg_waveform.png';
// Wong-Baker FACES: no changes without the foundation's written permission,
// so it has no Spanish copy; the page's table carries the Spanish words.
const _painFaces = 'assets/books/protocolbook/images/pb_pain_faces.png';

/// Every asset path an [Image.asset] on screen is showing.
List<String> _shown(WidgetTester tester) => tester
    .widgetList<Image>(find.byType(Image))
    .map((i) => (i.image as AssetImage).assetName)
    .toList();

Future<void> _pump(
  WidgetTester tester,
  String path, {
  AssetLocalizer? localizer,
}) async {
  final theme = TopicTheme(
    resolvePalette([
      {'accent': const Color(0xFF3A5D64)},
    ]),
  );
  final view = ImageBlockView(
    block: ImageBlock(path: path, size: ImageSize.full),
    theme: theme,
  );
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, child) => localizer == null
          ? child!
          : AssetLocalizerScope(localizer: localizer, child: child!),
      home: Scaffold(body: SingleChildScrollView(child: view)),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Set<String> assets;
  setUpAll(() async {
    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    assets = manifest.listAssets().toSet();
  });

  test('every Spanish picture copies an English one; none is WHO', () {
    final copies = assets.where((a) => a.contains('/images/es/')).toList();
    // 16 ProtocolBook pictures and the WVEMS rule of nines (images.py).
    expect(copies, hasLength(17));
    for (final c in copies) {
      expect(assets, contains(c.replaceFirst('/images/es/', '/images/')));
      expect(c, isNot(contains('who_imci')));
    }
    expect(assets, isNot(contains(translatedPath(_painFaces, 'es'))));
  });

  testWidgets('Spanish shows the Spanish copy, inline and zoomed', (
    tester,
  ) async {
    await _pump(tester, _waveform, localizer: AssetLocalizer('es', assets));
    expect(_shown(tester), [_waveformEs]);
    // Images never decode in a widget test, so the picture has no size to
    // hit; open the zoom view through its tap handler.
    tester
        .widget<GestureDetector>(
          find.ancestor(
            of: find.byType(Image),
            matching: find.byType(GestureDetector),
          ),
        )
        .onTap!();
    await tester.pumpAndSettle();
    expect(find.byType(InteractiveViewer), findsOneWidget);
    expect(
      tester
          .widgetList<Image>(
            find.descendant(
              of: find.byType(InteractiveViewer),
              matching: find.byType(Image),
            ),
          )
          .map((i) => (i.image as AssetImage).assetName),
      [_waveformEs],
    );
  });

  testWidgets('Spanish falls back to English where there is no copy', (
    tester,
  ) async {
    await _pump(tester, _painFaces, localizer: AssetLocalizer('es', assets));
    expect(_shown(tester), [_painFaces]);
  });

  testWidgets('English, and no scope at all, show the English file', (
    tester,
  ) async {
    await _pump(tester, _waveform, localizer: AssetLocalizer.english());
    expect(_shown(tester), [_waveform]);
    await _pump(tester, _waveform);
    expect(_shown(tester), [_waveform]);
  });
}
