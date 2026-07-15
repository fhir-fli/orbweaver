import 'package:flutter_test/flutter_test.dart';
import 'package:orbweaver/data/library.dart';

/// End-to-end load test: exercises the REAL `loadLibrary()` path (rootBundle
/// asset loading + `_loadTopicRow` + tree flattening) that the structural
/// `library_test.dart` (raw-YAML parsing) never touches. Guards against a
/// topic silently dropping out of a book's loaded tree.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('loadLibrary: protocolbook loads all 29 topics incl. Dehydration',
      () async {
    final books = await loadLibrary();
    final pb = books.firstWhere((b) => b.id == 'protocolbook');
    final titles = pb.allTopics.map((t) => t.title).toList();
    expect(titles, hasLength(29));
    expect(
      titles,
      contains('Hydrocarbon Ingestion (Kerosene, Paraffin)'),
    );
    expect(
      titles,
      contains('Benzodiazepine / Opioid Ingestion'),
    );
    expect(
      titles,
      contains('Paracetamol / Acetaminophen Toxicity'),
    );
    expect(
      titles,
      contains('Alcohol Intoxication'),
    );
    expect(
      titles,
      contains('Alcohol Withdrawal'),
    );
    expect(
      titles,
      contains('CIWA-Ar Scale'),
    );
    expect(
      titles,
      contains('Anaphylaxis'),
    );
    expect(
      titles,
      contains('Animal Bite'),
    );
    expect(
      titles,
      contains('Suspected Snake Bite'),
    );
    expect(
      titles,
      contains('Paediatric Convulsions'),
    );
    expect(
      titles,
      contains('Paediatric Dehydration Protocol'),
    );
  });
}
