import 'package:material_ui/material_ui.dart';
import 'package:orbweaver/data/formula_strings_loader.dart';
import 'package:orbweaver/data/library.dart';
import 'package:orbweaver/data/library_scope.dart';
import 'package:orbweaver/l10n/l10n.dart';
import 'package:orbweaver/models/book.dart';
import 'package:orbweaver/screens/book_screen.dart';
import 'package:orbweaver/services/app_language.dart';

/// Single-book web build: opens straight into the WHO "Hospital Care for
/// Children" book with no shelf and no way to reach the other books — a
/// self-contained interactive rendering to show the WHO for permission.
///
/// Build: `flutter build web -t lib/main_who.dart`.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // The single-book web build has no shelf to put a picker on, so it
  // follows the browser's language.
  final language = AppLanguage.resolve(null);
  await loadFormulaStrings(language);
  final book = await loadBook('who_imci', language: language);
  runApp(WhoApp(book: book, language: language));
}

class WhoApp extends StatelessWidget {
  WhoApp({required this.book, this.language = 'en', super.key})
    : index = LibraryIndex([book]);

  final Book book;
  final String language;
  final LibraryIndex index;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: book.title,
      debugShowCheckedModeBanner: false,
      locale: Locale(language),
      supportedLocales: [for (final l in kSupportedLanguages) Locale(l)],
      localizationsDelegates: kLocalizationsDelegates,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: book.spineColor),
        useMaterial3: true,
      ),
      // Cross-links inside the WHO book resolve against this single-book index.
      builder: (context, child) =>
          LibraryScope(index: index, child: child ?? const SizedBox.shrink()),
      home: BookScreen(book: book),
    );
  }
}
