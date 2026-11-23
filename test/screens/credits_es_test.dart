import 'package:flutter_test/flutter_test.dart';
import 'package:orbweaver/screens/credits_screen.dart';

/// The Spanish credits translate the prose only. Everything that identifies
/// a work, a person or a licence must match the English exactly, and the WHO
/// entry stays English: WHO licence 202610340 (WHO-LICENCE.md) says
/// "Translating: No", and its clause 3 disclaimer is required as granted.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'Spanish credits: prose translated, citations and licences unchanged',
    () async {
      final en = await loadCredits();
      final es = await loadCredits(language: 'es');

      expect(es.intro, startsWith('Orbweaver incluye material'));
      expect(es.intro, isNot(en.intro));
      expect(es.privacyUrl, en.privacyUrl);

      expect(es.sources.length, en.sources.length);
      for (var i = 0; i < en.sources.length; i++) {
        expect(es.sources[i].title, en.sources[i].title);
        expect(es.sources[i].by, en.sources[i].by);
      }
      final whoEn = en.sources.firstWhere(
        (s) => s.by == 'World Health Organization',
      );
      final whoEs = es.sources.firstWhere(
        (s) => s.by == 'World Health Organization',
      );
      expect(whoEs.note, whoEn.note);
      expect(whoEs.note, contains('202610340'));

      expect(es.images.length, en.images.length);
      for (var i = 0; i < en.images.length; i++) {
        final a = en.images[i];
        final b = es.images[i];
        // Only what the image shows ("use") is translated.
        expect(
          [b.file, b.source, b.sourceUrl, b.author, b.licence, b.licenceUrl],
          [a.file, a.source, a.sourceUrl, a.author, a.licence, a.licenceUrl],
          reason: a.file,
        );
      }
    },
  );

  test('English credits load from the English file', () async {
    final en = await loadCredits();
    expect(en.intro, startsWith('Orbweaver bundles material'));
  });
}
