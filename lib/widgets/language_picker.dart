import 'package:material_ui/material_ui.dart';
import 'package:orbweaver/l10n/l10n.dart';
import 'package:orbweaver/widgets/language_scope.dart';

/// Lets the reader pick the app's language. Each language is listed by its
/// own name, so a reader who cannot read the current language can still
/// find theirs.
Future<void> showLanguagePicker(BuildContext context) async {
  final scope = LanguageScope.maybeOf(context);
  if (scope == null) return;
  final l10n = context.l10n;
  // Returns the picked code, '' for "same as phone", or null when dismissed.
  final picked = await showDialog<String>(
    context: context,
    builder: (ctx) => SimpleDialog(
      title: Text(l10n.language),
      children: [
        _option(ctx, '', l10n.languageFollowPhone, scope.choice == null),
        for (final code in kSupportedLanguages)
          _option(
            ctx,
            code,
            lookupAppLocalizations(Locale(code)).languageName,
            scope.choice == code,
          ),
      ],
    ),
  );
  if (picked == null) return;
  await scope.onChoose(picked.isEmpty ? null : picked);
}

Widget _option(BuildContext ctx, String code, String label, bool selected) =>
    SimpleDialogOption(
      onPressed: () => Navigator.pop(ctx, code),
      child: Row(
        children: [
          Icon(
            selected ? Icons.radio_button_checked : Icons.radio_button_off,
            size: 20,
          ),
          const SizedBox(width: 12),
          Text(label),
        ],
      ),
    );
