import 'package:flutter/material.dart';
import 'package:orbweaver/data/library.dart';
import 'package:orbweaver/screens/book_screen.dart';
import 'package:orbweaver/screens/shelf_screen.dart';
import 'package:orbweaver/screens/topic_frame.dart';
import 'package:orbweaver/services/last_state.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final snapshot = await LastState.load();
  runApp(OrbweaverApp(snapshot: snapshot));
}

class OrbweaverApp extends StatelessWidget {
  const OrbweaverApp({required this.snapshot, super.key});

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
      onGenerateInitialRoutes: (_) => _restorePages(snapshot),
      onGenerateRoute: (settings) => MaterialPageRoute<void>(
        builder: (_) => const ShelfScreen(),
      ),
    );
  }
}

/// Builds the initial route stack from persisted state. The shelf is
/// always on the bottom; book and topic routes are pushed on top if the
/// user had one open last session. Back button pops in reverse.
List<Route<void>> _restorePages(LastStateSnapshot s) {
  final routes = <Route<void>>[
    MaterialPageRoute<void>(builder: (_) => const ShelfScreen()),
  ];

  final book = s.bookId == null ? null : findBook(s.bookId!);
  if (book == null) return routes;
  routes.add(MaterialPageRoute<void>(builder: (_) => BookScreen(book: book)));

  final topic = s.topicId == null ? null : findTopic(book, s.topicId!);
  if (topic == null) return routes;
  routes.add(MaterialPageRoute<void>(
    builder: (_) => TopicFrame(assetPath: topic.asset),
  ));

  return routes;
}
