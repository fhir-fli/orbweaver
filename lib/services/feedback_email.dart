import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:orbweaver/services/app_version.dart';
import 'package:url_launcher/url_launcher.dart';

/// "Report a problem with this page" — opens the reader's own mail app with a
/// message already addressed, subject-tagged and carrying the context.
///
/// Why it works this way. The app has no network code and collects nothing, and
/// that is a licence condition as well as a design choice, so feedback cannot be
/// posted anywhere. A `mailto:` hands the whole thing to the reader's mail app:
/// they see exactly what is being sent and nothing leaves the device unless they
/// press send.
///
/// The metadata block matters more than it looks. A report saying "this dose is
/// wrong" is unusable without knowing WHICH page and WHICH build, and a clinician
/// mid-shift will not type that out.

/// Where reports go.
const String kFeedbackAddress = 'greyzus@fhirfli.dev';

/// Every subject starts with this, so a mail filter catches all of them.
/// Do not change it without changing the filter.
const String kFeedbackSubjectTag = '[Orbweaver]';

/// Separator. Everything below it is generated; everything above is the reader's.
const String kMetadataFence =
    '--- please leave everything below this line ---';

/// The context a report needs to be actionable.
@immutable
class FeedbackContext {
  const FeedbackContext({
    this.bookId,
    this.bookTitle,
    this.topicId,
    this.topicTitle,
    this.pageLabel,
  });

  final String? bookId;
  final String? bookTitle;
  final String? topicId;
  final String? topicTitle;
  final String? pageLabel;

  /// Short tag for the subject line, so a full inbox is still sortable.
  String get subjectSuffix {
    if (topicId != null && topicId!.isNotEmpty) return topicId!;
    if (bookId != null && bookId!.isNotEmpty) return bookId!;
    return 'general';
  }
}

String _platformLine() {
  if (kIsWeb) return 'web';
  try {
    return '${Platform.operatingSystem} ${Platform.operatingSystemVersion}';
  } on Object {
    // Platform throws on some hosts; a missing line is better than a crash in
    // the middle of someone reporting a dosing error.
    return defaultTargetPlatform.name;
  }
}

String buildSubject(FeedbackContext c) =>
    '$kFeedbackSubjectTag ${c.subjectSuffix}';

String buildBody(FeedbackContext c, {DateTime? now}) {
  final when = (now ?? DateTime.now().toUtc()).toIso8601String();
  final lines = <String>[
    'What is wrong, or what would help? Write it here.',
    '',
    '',
    kMetadataFence,
    'app       orbweaver $kAppVersion',
    'platform  ${_platformLine()}',
    'when      $when',
  ];
  if (c.bookId != null) {
    lines.add('book      ${c.bookId}'
        '${c.bookTitle == null ? '' : '  ·  ${c.bookTitle}'}');
  }
  if (c.topicId != null) {
    lines.add('topic     ${c.topicId}'
        '${c.topicTitle == null ? '' : '  ·  ${c.topicTitle}'}');
  }
  if (c.pageLabel != null && c.pageLabel!.isNotEmpty) {
    lines.add('page      ${c.pageLabel}');
  }
  return lines.join('\n');
}

/// The `mailto:` URI. Built by hand rather than with `Uri(queryParameters:)`,
/// which encodes a space as `+`; several mail clients then show literal plus
/// signs through the whole body.
Uri buildFeedbackUri(FeedbackContext c, {DateTime? now}) {
  final q = 'subject=${Uri.encodeComponent(buildSubject(c))}'
      '&body=${Uri.encodeComponent(buildBody(c, now: now))}';
  return Uri.parse('mailto:$kFeedbackAddress?$q');
}

/// Opens the mail app. Returns false if the device has no mail client, so the
/// caller can tell the reader rather than appearing to do nothing.
Future<bool> sendFeedback(FeedbackContext c) async {
  final uri = buildFeedbackUri(c);
  try {
    return await launchUrl(uri, mode: LaunchMode.externalApplication);
  } on Object {
    return false;
  }
}
