import 'package:material_ui/material_ui.dart';
import 'package:orbweaver/l10n/l10n.dart';
import 'package:orbweaver/models/book.dart';
import 'package:orbweaver/screens/book_screen.dart';
import 'package:orbweaver/screens/credits_screen.dart';
import 'package:orbweaver/services/feedback_email.dart';
import 'package:orbweaver/theme/palette.dart';
import 'package:orbweaver/widgets/language_picker.dart';

/// Library shelf — grid of book covers. Tapping a cover pushes the
/// book's topic list. The book list is loaded from the manifest YAMLs
/// (see `loadLibrary`) and passed in — the shelf hardcodes nothing.
class ShelfScreen extends StatelessWidget {
  const ShelfScreen({required this.books, super.key});

  final List<Book> books;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kScreenChrome,
      appBar: AppBar(
        title: const Text('Orbweaver'),
        backgroundColor: const Color(0xFF1E4E8C),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.translate),
            tooltip: context.l10n.language,
            onPressed: () => showLanguagePicker(context),
          ),
          // General feedback, for anything not tied to one page. The per-page
          // button on a topic carries the page id; this one does not, so it is
          // tagged "general" and still lands in the same mail folder.
          IconButton(
            icon: const Icon(Icons.flag_outlined),
            tooltip: context.l10n.reportProblemGeneral,
            onPressed: () => sendFeedback(
              FeedbackContext(
                prompt: context.l10n.feedbackPrompt,
                language: Localizations.localeOf(context).languageCode,
              ),
            ),
          ),
          // Not decoration: the bundled Wikimedia images are CC BY and CC BY-SA,
          // and both require the attribution reach whoever sees the work.
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: context.l10n.sourcesCredits,
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => const CreditsScreen(),
              ),
            ),
          ),
        ],
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.62,
          crossAxisSpacing: 16,
          mainAxisSpacing: 20,
        ),
        itemCount: books.length,
        itemBuilder: (context, i) => _CoverCard(book: books[i]),
      ),
    );
  }
}

class _CoverCard extends StatelessWidget {
  const _CoverCard({required this.book});

  final Book book;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute<void>(
          settings: const RouteSettings(name: kBookRouteName),
          builder: (_) => BookScreen(book: book),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Material(
              elevation: 4,
              clipBehavior: Clip.antiAlias,
              borderRadius: BorderRadius.circular(4),
              child: book.coverAsset.isEmpty
                  ? _FallbackCover(book: book)
                  : Image.asset(book.coverAsset, fit: BoxFit.cover),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            book.title,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            context.l10n.bookTopicCount(book.allTopics.length),
            style: const TextStyle(fontSize: 11, color: Colors.black54),
          ),
        ],
      ),
    );
  }
}

class _FallbackCover extends StatelessWidget {
  const _FallbackCover({required this.book});

  final Book book;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: book.spineColor,
      padding: const EdgeInsets.all(16),
      child: Center(
        child: Text(
          book.title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
