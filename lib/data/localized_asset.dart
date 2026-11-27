import 'package:flutter/services.dart' show AssetManifest, rootBundle;
import 'package:flutter/widgets.dart';

/// Where a translated copy of an English asset lives: a `<language>/`
/// folder beside the English file, same file name.
///
/// ```text
/// assets/books/protocolbook/topics/pb_014_cardiac_arrest.yaml      English
/// assets/books/protocolbook/topics/es/pb_014_cardiac_arrest.yaml   Spanish
/// assets/books/protocolbook/es/book.yaml                           Spanish manifest
/// assets/es/credits.yaml                                           Spanish credits
/// ```
String translatedPath(String englishPath, String language) {
  final slash = englishPath.lastIndexOf('/');
  final dir = slash < 0 ? '' : englishPath.substring(0, slash + 1);
  final file = englishPath.substring(slash + 1);
  return '$dir$language/$file';
}

/// Picks the translated copy of an asset when the bundle has one, else the
/// English file. A book, page or string file with no translation simply
/// shows in English.
class AssetLocalizer {
  AssetLocalizer(this.language, this._assets);

  /// English only: no lookups, every path stays as given.
  AssetLocalizer.english() : language = 'en', _assets = const {};

  static Future<AssetLocalizer> load(String language) async {
    if (language == 'en') return AssetLocalizer.english();
    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    return AssetLocalizer(language, manifest.listAssets().toSet());
  }

  final String language;
  final Set<String> _assets;

  String path(String englishPath) {
    if (language == 'en') return englishPath;
    final t = translatedPath(englishPath, language);
    return _assets.contains(t) ? t : englishPath;
  }
}

/// Hands the reading language's [AssetLocalizer] to the renderers, so a
/// picture with English text baked in can show its translated copy
/// (`images/es/<file>`) when one exists. Without a scope (tests, the
/// playground) every picture stays English.
class AssetLocalizerScope extends InheritedWidget {
  const AssetLocalizerScope({
    required this.localizer,
    required super.child,
    super.key,
  });

  final AssetLocalizer localizer;

  /// [englishPath], or its translated copy for the reading language.
  static String path(BuildContext context, String englishPath) =>
      context
          .dependOnInheritedWidgetOfExactType<AssetLocalizerScope>()
          ?.localizer
          .path(englishPath) ??
      englishPath;

  @override
  bool updateShouldNotify(AssetLocalizerScope oldWidget) =>
      oldWidget.localizer.language != localizer.language;
}
