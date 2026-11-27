import 'package:flutter_test/flutter_test.dart';
import 'package:orbweaver/services/app_language.dart';

void main() {
  test('a stored choice wins over the phone', () {
    expect(AppLanguage.resolve('es', phoneLanguages: ['en']), 'es');
  });
  test('same-as-phone takes the first phone language the app has', () {
    expect(AppLanguage.resolve(null, phoneLanguages: ['de', 'es', 'en']), 'es');
  });
  test('a phone in a language the app lacks gets English', () {
    expect(AppLanguage.resolve(null, phoneLanguages: ['ht', 'de']), 'en');
  });
}
