import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orbweaver/services/error_log.dart';
import 'package:orbweaver/services/feedback_email.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Guards on the on-device error log.
///
/// The point: a "Report a problem" mail from the field arrives with the
/// trace of whatever broke, not a description of it. Each test fails if the
/// log stops holding what a report needs.
void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('a recorded error is kept, newest first, with its trace', () async {
    await ErrorLog.record(StateError('first'), StackTrace.current);
    await ErrorLog.record(ArgumentError('second'), null);
    final entries = await ErrorLog.entries();
    expect(entries, hasLength(2));
    expect(entries.first, contains('second'));
    expect(entries.last, contains('first'));
    expect(entries.last, contains('error_log_test.dart'));
  });

  test('only the last ${ErrorLog.keep} are kept', () async {
    for (var i = 0; i < ErrorLog.keep + 5; i++) {
      await ErrorLog.record(StateError('e$i'), null);
    }
    final entries = await ErrorLog.entries();
    expect(entries, hasLength(ErrorLog.keep));
    expect(entries.first, contains('e${ErrorLog.keep + 4}'));
    expect(entries.any((e) => e.contains('e0 ')), isFalse);
  });

  test('concurrent records lose nothing', () async {
    await Future.wait([
      for (var i = 0; i < 6; i++) ErrorLog.record(StateError('c$i'), null),
    ]);
    expect(await ErrorLog.entries(), hasLength(6));
  });

  test('install() routes an uncaught Flutter error into the log', () async {
    final before = FlutterError.onError;
    ErrorLog.install();
    try {
      FlutterError.onError!(
        FlutterErrorDetails(exception: StateError('from a build')),
      );
      await ErrorLog.flushForTest();
    } finally {
      FlutterError.onError = before;
    }
    final entries = await ErrorLog.entries();
    expect(entries.single, contains('from a build'));
  });

  test('the report body carries the recent errors below the fence', () {
    final body = buildBody(
      const FeedbackContext(
        bookId: 'wvems',
        recentErrors: ['2026-09-22T10:00:00Z  StateError: boom'],
      ),
      now: DateTime.utc(2026, 9, 22, 12),
    );
    expect(body, contains(kMetadataFence));
    expect(body.indexOf('boom'), greaterThan(body.indexOf(kMetadataFence)));
    expect(
      buildBody(const FeedbackContext(bookId: 'wvems')),
      isNot(contains('recent errors')),
    );
  });
}
