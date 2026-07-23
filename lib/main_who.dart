import 'package:flutter/material.dart';
import 'package:orbweaver/data/library.dart';
import 'package:orbweaver/data/library_scope.dart';
import 'package:orbweaver/models/book.dart';
import 'package:orbweaver/screens/book_screen.dart';

/// Single-book web build: opens straight into the WHO "Hospital Care for
/// Children" book with no shelf and no way to reach the other books — a
/// self-contained interactive rendering to show the WHO for permission.
///
/// Build: `flutter build web -t lib/main_who.dart`.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final book = await loadBook('who_imci');
  runApp(WhoApp(book: book));
}

class WhoApp extends StatelessWidget {
  WhoApp({required this.book, super.key}) : index = LibraryIndex([book]);

  final Book book;
  final LibraryIndex index;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: book.title,
      debugShowCheckedModeBanner: false,
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
