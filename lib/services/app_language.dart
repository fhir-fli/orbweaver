import 'dart:ui' show PlatformDispatcher;

import 'package:orbweaver/l10n/l10n.dart' show kSupportedLanguages;
import 'package:shared_preferences/shared_preferences.dart';

/// The reader's language choice. `null` means "same as the phone": the first
/// phone language the app supports, else English.
class AppLanguage {
  static const _kKey = 'app_language';

  /// The stored override, or null to follow the phone.
  static Future<String?> loadChoice() async {
    final prefs = await SharedPreferences.getInstance();
    final v = prefs.getString(_kKey);
    return kSupportedLanguages.contains(v) ? v : null;
  }

  static Future<void> saveChoice(String? language) async {
    final prefs = await SharedPreferences.getInstance();
    if (language == null) {
      await prefs.remove(_kKey);
    } else {
      await prefs.setString(_kKey, language);
    }
  }

  /// The language to show for [choice], resolving "same as phone" against
  /// the phone's ordered language list.
  static String resolve(String? choice, {List<String>? phoneLanguages}) {
    if (choice != null) return choice;
    final phone =
        phoneLanguages ??
        [for (final l in PlatformDispatcher.instance.locales) l.languageCode];
    for (final code in phone) {
      if (kSupportedLanguages.contains(code)) return code;
    }
    return 'en';
  }
}
