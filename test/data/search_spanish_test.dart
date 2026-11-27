import 'package:flutter_test/flutter_test.dart';
import 'package:orbweaver/data/search_normalizer.dart';

void main() {
  String n(String s) => SearchNormalizer.normalize(s);

  test('an accented word stays one token', () {
    // Before folding, the punctuation strip split "neumonía" into
    // "neumon a", so no Spanish query with an accent could ever match.
    expect(n('Neumonía grave'), 'neumonia grave');
    expect(n('niño pequeño'), 'nino pequeno');
  });

  test('a query typed without accents finds accented text', () {
    expect(n('NEUMONÍA'), n('neumonia'));
    expect(n('Deshidratación'), n('deshidratacion'));
  });

  test('Spanish unit words collapse to the unit, as English ones do', () {
    expect(n('10 miligramos por kilogramo'), '10 mg por kg');
    expect(n('5 mililitros'), n('5 mL'));
  });

  test('English is unchanged', () {
    expect(n('Diarrhoea, 100 milligrams'), 'diarrhea 100 mg');
  });
}
