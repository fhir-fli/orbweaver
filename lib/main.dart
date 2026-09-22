import 'package:flutter/material.dart';
import 'package:orbweaver/data/library.dart';
import 'package:orbweaver/data/library_scope.dart';
import 'package:orbweaver/models/book.dart';
import 'package:orbweaver/screens/book_screen.dart';
import 'package:orbweaver/screens/shelf_screen.dart';
import 'package:orbweaver/screens/topic_frame.dart';
import 'package:orbweaver/services/error_log.dart';
import 'package:orbweaver/services/last_state.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  ErrorLog.install();
  final library = await loadLibrary();
  final snapshot = await LastState.load();
  runApp(OrbweaverApp(library: library, snapshot: snapshot));
}

class OrbweaverApp extends StatelessWidget {
  OrbweaverApp({required this.library, required this.snapshot, super.key})
    : index = LibraryIndex(library);

  final List<Book> library;
  final LibraryIndex index;
  final LastStateSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Orbweaver',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      // Provide the link index above the Navigator so any pushed topic's
      // cross-links can resolve and navigate.
      builder: (context, child) =>
          LibraryScope(index: index, child: child ?? const SizedBox.shrink()),
      onGenerateInitialRoutes: (_) => _restorePages(snapshot, library),
      onGenerateRoute: (settings) => MaterialPageRoute<void>(
        builder: (_) => ShelfScreen(books: library),
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
