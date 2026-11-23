import 'package:flutter/services.dart' show AssetManifest, rootBundle;

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
