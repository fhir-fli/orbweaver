import 'package:flutter_test/flutter_test.dart';
import 'package:orbweaver/data/search_normalizer.dart';
import 'package:orbweaver/models/book.dart';

void main() {
  group('SearchNormalizer', () {
    test('British and American spellings normalise to the same token', () {
      for (final pair in [
        ['diarrhoea', 'diarrhea'],
        ['oedema', 'edema'],
        ['haemorrhage', 'hemorrhage'],
        ['paediatric', 'pediatric'],
        ['hypoglycaemia', 'hypoglycemia'],
        ['anaesthesia', 'anesthesia'],
        ['sulphate', 'sulfate'],
      ]) {
        expect(SearchNormalizer.normalize(pair[0]),
            SearchNormalizer.normalize(pair[1]),
            reason: '${pair[0]} vs ${pair[1]}');
      }
    });

    test('suffix rules generalise beyond the explicit map', () {
      // Words not in the explicit map, handled by suffix rules alone.
      expect(SearchNormalizer.normalize('vapour'), 'vapor');
      expect(SearchNormalizer.normalize('computerise'), 'computerize');
      expect(SearchNormalizer.normalize('sombre'), 'somber');
      // -our exceptions are left alone.
      expect(SearchNormalizer.normalize('hour'), 'hour');
    });

    test('dosing words collapse to abbreviations', () {
      expect(SearchNormalizer.normalize('100 milligrams'), '100 mg');
      expect(SearchNormalizer.normalize('5 millilitres'), '5 ml');
    });

    test('case, punctuation and hyphens are folded', () {
      expect(SearchNormalizer.normalize('Tip-toe, RUN!'), 'tip toe run');
      expect(SearchNormalizer.normalize('1,000'), '1000');
    });
  });

  group('BookTopic.matches (full-text, normalised)', () {
    BookTopic t(String searchSource) => BookTopic(
          id: 'x',
          title: 'x',
          subtitle: '',
          asset: 'a',
          searchText: SearchNormalizer.normalize(searchSource),
        );

    test('US query finds British-spelled content', () {
      final topic = t('Severe dehydration with diarrhoea and oedema');
      expect(topic.matches('diarrhea'), isTrue);
      expect(topic.matches('edema'), isTrue);
    });

    test('dosing query matches spelled-out units', () {
      expect(t('give 100 milligrams IV').matches('100 mg'), isTrue);
    });

    test('multi-term query requires all terms (token-AND)', () {
      final topic = t('rectal diazepam for convulsions');
      expect(topic.matches('diazepam rectal'), isTrue);
      expect(topic.matches('diazepam oral'), isFalse);
    });

    test('empty query matches everything', () {
      expect(t('anything').matches(''), isTrue);
    });
  });
}
