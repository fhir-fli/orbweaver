import 'package:flutter_test/flutter_test.dart';
import 'package:orbweaver/data/formula_strings.dart';
import 'package:orbweaver/data/formula_strings_loader.dart';
import 'package:orbweaver/data/library.dart';
import 'package:orbweaver/data/localized_asset.dart';
import 'package:orbweaver/data/topic_loader.dart';

/// The REAL loader in Spanish: a page with a translation loads it, a page
/// without one loads in English, and the tree is the same either way.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Spanish loads translated pages and falls back to English', () async {
    final en = await loadLibrary();
    final es = await loadLibrary(language: 'es');
    final calcEn = en.firstWhere((b) => b.id == 'calculators');
    final calcEs = es.firstWhere((b) => b.id == 'calculators');

    final mapEs = calcEs.allTopics.firstWhere((t) => t.id == 'calc-map');
    expect(mapEs.title, 'Presión arterial media');
    expect(mapEs.asset, 'assets/books/calculators/topics/es/calc_map.yaml');
    final topic = await loadTopicAsset(mapEs.asset);
    expect(topic.title, 'Presión arterial media');

    // Every calculator page now has a Spanish file, and each loads it.
    for (final t in calcEs.allTopics) {
      final english = calcEn.allTopics.firstWhere((e) => e.id == t.id);
      expect(t.asset, translatedPath(english.asset, 'es'));
    }

    // Same books, same topic ids, same order.
    expect(es.map((b) => b.id), en.map((b) => b.id));
    for (var i = 0; i < en.length; i++) {
      expect(
        es[i].allTopics.map((t) => t.id).toList(),
        en[i].allTopics.map((t) => t.id).toList(),
      );
    }
  });

  // Every bundled page is translated now, so the fallback is tested on a
  // bundle listing that lacks one.
  test('a page with no Spanish file stays English, at its English path', () {
    const en = 'assets/books/calculators/topics/calc_map.yaml';
    const es = 'assets/books/calculators/topics/es/calc_map.yaml';
    expect(AssetLocalizer('es', {en, es}).path(en), es);
    expect(AssetLocalizer('es', {en}).path(en), en);
    expect(AssetLocalizer.english().path(en), en);
  });

  test('the bundled Spanish calculator wording loads', () async {
    await loadFormulaStrings('es');
    expect(
      FormulaStrings.current!('map.mean_arterial_pressure'),
      'Presión arterial media',
    );
    await loadFormulaStrings('en');
    expect(
      FormulaStrings.current!('map.mean_arterial_pressure'),
      'Mean arterial pressure',
    );
  });
}
