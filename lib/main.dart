import 'package:material_ui/material_ui.dart';
import 'package:orbweaver/data/formula_strings_loader.dart';
import 'package:orbweaver/data/library.dart';
import 'package:orbweaver/data/library_scope.dart';
import 'package:orbweaver/data/localized_asset.dart';
import 'package:orbweaver/l10n/l10n.dart';
import 'package:orbweaver/models/book.dart';
import 'package:orbweaver/screens/book_screen.dart';
import 'package:orbweaver/screens/shelf_screen.dart';
import 'package:orbweaver/screens/topic_frame.dart';
import 'package:orbweaver/services/app_language.dart';
import 'package:orbweaver/services/error_log.dart';
import 'package:orbweaver/services/last_state.dart';
import 'package:orbweaver/widgets/language_scope.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  ErrorLog.install();
  final choice = await AppLanguage.loadChoice();
  final language = AppLanguage.resolve(choice);
  await loadFormulaStrings(language);
  final library = await loadLibrary(language: language);
  final images = await AssetLocalizer.load(language);
  final snapshot = await LastState.load();
  runApp(
    OrbweaverApp(
      library: library,
      snapshot: snapshot,
      language: language,
      languageChoice: choice,
      images: images,
    ),
  );
}

class OrbweaverApp extends StatefulWidget {
  const OrbweaverApp({
    required this.library,
    required this.snapshot,
    this.language = 'en',
    this.languageChoice,
    this.images,
    super.key,
  });

  final List<Book> library;
  final LastStateSnapshot snapshot;

  /// The language [library] was loaded in.
  final String language;
  final String? languageChoice;

  /// Finds the reading language's copy of a picture; null = English.
  final AssetLocalizer? images;

  @override
  State<OrbweaverApp> createState() => _OrbweaverAppState();
}

class _OrbweaverAppState extends State<OrbweaverApp> {
  late List<Book> _library = widget.library;
  late LibraryIndex _index = LibraryIndex(_library);
  late String _language = widget.language;
  late String? _choice = widget.languageChoice;
  late AssetLocalizer _images = widget.images ?? AssetLocalizer.english();
  late LastStateSnapshot _snapshot = widget.snapshot;

  // A new key on a language change rebuilds the Navigator, so no route
  // keeps showing a page loaded in the old language.
  int _generation = 0;

  Future<void> _choose(String? choice) async {
    await AppLanguage.saveChoice(choice);
    final language = AppLanguage.resolve(choice);
    if (language != _language) await loadFormulaStrings(language);
    final library = language == _language
        ? _library
        : await loadLibrary(language: language);
    final images = language == _language
        ? _images
        : await AssetLocalizer.load(language);
    if (!mounted) return;
    setState(() {
      _choice = choice;
      _language = language;
      _library = library;
      _index = LibraryIndex(library);
      _images = images;
      _snapshot = const LastStateSnapshot();
      _generation++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      key: ValueKey(_generation),
      title: 'Orbweaver',
      debugShowCheckedModeBanner: false,
      locale: Locale(_language),
      supportedLocales: [for (final l in kSupportedLanguages) Locale(l)],
      localizationsDelegates: kLocalizationsDelegates,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      // Provide the link index above the Navigator so any pushed topic's
      // cross-links can resolve and navigate.
      builder: (context, child) => LanguageScope(
        choice: _choice,
        onChoose: _choose,
        child: LibraryScope(
          index: _index,
          child: AssetLocalizerScope(
            localizer: _images,
            child: child ?? const SizedBox.shrink(),
          ),
        ),
      ),
      onGenerateInitialRoutes: (_) => _restorePages(_snapshot, _library),
      onGenerateRoute: (settings) => MaterialPageRoute<void>(
        builder: (_) => ShelfScreen(books: _library),
      ),
    );
  }
}

/// Builds the initial route stack from persisted state. The shelf is
/// always on the bottom; book and topic routes are pushed on top if the
/// user had one open last session. Back button pops in reverse.
List<Route<void>> _restorePages(LastStateSnapshot s, List<Book> library) {
  final routes = <Route<void>>[
    MaterialPageRoute<void>(builder: (_) => ShelfScreen(books: library)),
  ];

  final book = s.bookId == null ? null : findBook(library, s.bookId!);
  if (book == null) return routes;
  routes.add(
    MaterialPageRoute<void>(
      settings: const RouteSettings(name: kBookRouteName),
      builder: (_) => BookScreen(book: book),
    ),
  );

  final topic = s.topicId == null ? null : findTopic(book, s.topicId!);
  if (topic == null) return routes;
  final siblings = protocolSiblings(book);
  final idx = siblings.indexWhere((t) => t.id == topic.id);
  routes.add(
    MaterialPageRoute<void>(
      builder: (_) => idx < 0
          ? TopicFrame(
              assetPath: topic.asset,
              palette: topic.palette,
              fontFamily: topic.fontFamily,
            )
          : TopicPager(siblings: siblings, initialIndex: idx, bookId: book.id),
    ),
  );

  return routes;
}
