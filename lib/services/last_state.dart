import 'package:shared_preferences/shared_preferences.dart';

/// Remembers the last book + topic the user was reading, so the next
/// launch can jump back to that topic automatically. Back-navigates
/// naturally: topic → book table of contents → shelf.
class LastState {
  static const _kBook = 'last_book_id';
  static const _kTopic = 'last_topic_id';

  static Future<LastStateSnapshot> load() async {
    final prefs = await SharedPreferences.getInstance();
    return LastStateSnapshot(
      bookId: prefs.getString(_kBook),
      topicId: prefs.getString(_kTopic),
    );
  }

  static Future<void> recordBook(String bookId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kBook, bookId);
    // A book visit clears the topic pointer — next launch lands on the
    // book's table of contents, not a stale topic.
    await prefs.remove(_kTopic);
  }

  static Future<void> recordTopic(String bookId, String topicId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kBook, bookId);
    await prefs.setString(_kTopic, topicId);
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kBook);
    await prefs.remove(_kTopic);
  }
}

class LastStateSnapshot {
  const LastStateSnapshot({this.bookId, this.topicId});

  final String? bookId;
  final String? topicId;
}
