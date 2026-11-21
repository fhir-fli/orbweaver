import 'package:flutter_test/flutter_test.dart';
import 'package:orbweaver/data/formula_strings.dart';
import 'package:orbweaver/data/formula_strings_loader.dart';
import 'package:orbweaver/data/library.dart';
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

    // A page with no Spanish file stays English, at its English path.
    final otherEs = calcEs.allTopics.firstWhere((t) => t.id != 'calc-map');
    final otherEn = calcEn.allTopics.firstWhere((t) => t.id == otherEs.id);
    expect(otherEs.title, otherEn.title);
    expect(otherEs.asset, otherEn.asset);

    // Same books, same topic ids, same order.
    expect(es.map((b) => b.id), en.map((b) => b.id));
    for (var i = 0; i < en.length; i++) {
      expect(
        es[i].allTopics.map((t) => t.id).toList(),
        en[i].allTopics.map((t) => t.id).toList(),
      );
    }
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
