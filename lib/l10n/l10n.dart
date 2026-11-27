import 'package:material_ui/material_ui.dart';
import 'package:orbweaver/l10n/gen/app_localizations.dart';

export 'package:orbweaver/l10n/gen/app_localizations.dart';

/// The languages the app ships, in picker order. English is the source
/// language: every book is authored in it, and any file without a
/// translation falls back to it.
const kSupportedLanguages = <String>['en', 'es'];

/// The delegates every app entry point installs. `material_ui` supplies its
/// own Material/Cupertino/Widgets delegates (the generated
/// `AppLocalizations.localizationsDelegates` names flutter/material's, which
/// `material_ui` widgets do not read).
const kLocalizationsDelegates = <LocalizationsDelegate<dynamic>>[
  AppLocalizations.delegate,
  ...GlobalMaterialLocalizations.delegates,
];

extension L10nContext on BuildContext {
  /// Interface strings for the current language. A widget pumped without a
  /// localized app around it (a bare widget test) gets English, the source
  /// language, rather than a null.
  AppLocalizations get l10n =>
      Localizations.of<AppLocalizations>(this, AppLocalizations) ??
      lookupAppLocalizations(const Locale('en'));
}
