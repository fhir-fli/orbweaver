import 'package:flutter_test/flutter_test.dart';
import 'package:orbweaver/data/library.dart';

/// End-to-end load test: exercises the REAL `loadLibrary()` path (rootBundle
/// asset loading + `_loadTopicRow` + tree flattening) that the structural
/// `library_test.dart` (raw-YAML parsing) never touches. Guards against a
/// topic silently dropping out of a book's loaded tree.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('loadLibrary: protocolbook loads all 19 topics incl. Hydrocarbon',
      () async {
    final books = await loadLibrary();
    final pb = books.firstWhere((b) => b.id == 'protocolbook');
    final titles = pb.allTopics.map((t) => t.title).toList();
    expect(titles, hasLength(19));
    expect(
      titles,
      contains('Hydrocarbon Ingestion (Kerosene, Paraffin)'),
    );
  });
}
