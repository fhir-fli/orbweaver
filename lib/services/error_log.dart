import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:orbweaver/services/last_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The last [keep] uncaught errors, kept on the device so that a "Report a
/// problem" mail carries the trace of what broke instead of a description
/// of it.
///
/// Nothing leaves the device by itself: the app has no network code, and
/// the entries only travel inside a mail the reader composes and sends
/// (see feedback_email.dart). Every error is still surfaced the way Flutter
/// surfaces it (the red box in debug, the console in release); recording
/// is in addition to that, never instead of it.
class ErrorLog {
  static const _kKey = 'error_log';

  /// How many entries stay on the device.
  static const int keep = 20;

  /// How much of one stack trace an entry keeps. The trace's head holds the
  /// frames that matter, and a mailto body has to stay small.
  static const int traceChars = 1200;

  /// Writes are serialised through this chain so two errors recorded in
  /// the same frame cannot each read the list and overwrite the other.
  static Future<void> _pending = Future<void>.value();

  /// Installs the two handlers: [FlutterError.onError] for errors raised
  /// while building, laying out or painting, and
  /// [PlatformDispatcher.onError] for uncaught asynchronous errors.
  static void install() {
    final previous = FlutterError.onError ?? FlutterError.presentError;
    FlutterError.onError = (details) {
      previous(details);
      unawaited(record(details.exception, details.stack));
    };
    PlatformDispatcher.instance.onError = (error, stack) {
      FlutterError.presentError(
        FlutterErrorDetails(
          exception: error,
          stack: stack,
          library: 'orbweaver',
        ),
      );
      unawaited(record(error, stack));
      return true;
    };
  }

  /// Appends one entry (UTC time, the book and topic open at the time, the
  /// error, the head of its trace) and drops the oldest beyond [keep].
  static Future<void> record(Object error, StackTrace? stack) {
    final when = DateTime.now().toUtc().toIso8601String();
    return _pending = _pending.then((_) => _append(when, error, stack));
  }

  static Future<void> _append(
    String when,
    Object error,
    StackTrace? stack,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final state = await LastState.load();
    final where = [
      if (state.bookId != null) state.bookId!,
      if (state.topicId != null) state.topicId!,
    ].join(' / ');
    final trace = stack == null ? '' : stack.toString();
    final entry = [
      '$when  ${where.isEmpty ? '' : '$where  '}$error',
      if (trace.length > traceChars)
        trace.substring(0, traceChars)
      else if (trace.isNotEmpty)
        trace,
    ].join('\n');
    final entries = <String>[entry, ...?prefs.getStringList(_kKey)];
    await prefs.setStringList(_kKey, entries.take(keep).toList());
  }

  /// The entries, newest first.
  static Future<List<String>> entries() async {
    await _pending;
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_kKey) ?? const [];
  }

  static Future<void> clear() async {
    await _pending;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kKey);
  }

  /// Waits for records queued by a handler (which cannot await) to land.
  @visibleForTesting
  static Future<void> flushForTest() => _pending;
}
