// GUARD — every `[label](topic:some-id)` cross-link must resolve.
//
// A dead cross-link in a clinical reference is silent: MiniMarkdown renders the
// label normally, the tap handler finds nothing, and the user is left on the
// page wondering whether they mis-tapped. Nothing in the app or the build
// surfaces it.
//
// This caught three live ones: the WVEMS drug reference pointed at
// `wvems-2026-008` for Circulation / Shock while that protocol still shipped
// as the 2025 edition (`wvems-2025-008`), so all three links were dead. The
// 2026 edition of pp.8-9 has since replaced it.
//
// The `#anchor` half is guarded too. A quarter of the print's cross-references
// point into the drug reference and another tenth into the procedures — one
// topic each, holding fifty and thirty-one cards — so a link whose anchor names
// nothing lands the reader at the top of the wrong card with no error anywhere.
//
// Reads the YAML directly rather than going through loadLibrary(), so it also
// covers topics that are authored but not yet registered in a book.yaml.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// `[label](topic:the-id)` and `[label](topic:the-id#anchor)`.
final _linkPattern = RegExp(r'\(topic:([^)#]+)(?:#([^)]*))?\)');
final _idPattern = RegExp(r'^\s*id:\s*"([^"]+)"', multiLine: true);

/// An explicit `anchor: "slug"` on a block.
final _anchorPattern = RegExp(r'^\s*anchor:\s*"([^"]+)"', multiLine: true);

/// Drug and procedure cards default their anchor to a slug of `name:`
/// (`anchorSlug` in lib/models/topic.dart), so their slugs are derived here
/// the same way rather than authored 81 times.
final _namePattern = RegExp(r'^\s*name:\s*"([^"]+)"', multiLine: true);

String _slug(String name) => name
    .toLowerCase()
    .replaceAll(RegExp('[^a-z0-9]+'), '-')
    .replaceAll(RegExp(r'^-+|-+$'), '');

void main() {
  test('every topic: cross-link resolves to a defined topic id', () {
    final files = Directory('assets/books')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.contains('/topics/') && f.path.endsWith('.yaml'))
        .toList();
    expect(files, isNotEmpty, reason: 'no topic YAML found — path wrong?');

    final ids = <String>{};
    final anchorsById = <String, Set<String>>{};
    final sources = <String, String>{};
    for (final f in files) {
      final text = f.readAsStringSync();
      sources[f.path] = text;
      final fileIds = _idPattern
          .allMatches(text)
          .map((m) => m.group(1)!)
          .toList();
      ids.addAll(fileIds);
      // A topic file holds one topic, so every anchor in it belongs to that
      // topic. The `id:` regex also matches nested ids (flowchart boxes), so
      // the topic's own id is the first one in the file.
      if (fileIds.isNotEmpty) {
        final slugs = <String>{
          ...anchorsById[fileIds.first] ?? const {},
          ..._anchorPattern.allMatches(text).map((m) => m.group(1)!),
          ..._namePattern.allMatches(text).map((m) => _slug(m.group(1)!)),
        };
        anchorsById[fileIds.first] = slugs;
      }
    }

    final broken = <String>[];
    var total = 0;
    var anchored = 0;
    sources.forEach((path, text) {
      for (final m in _linkPattern.allMatches(text)) {
        total++;
        final target = m.group(1)!.trim();
        final anchor = m.group(2)?.trim();
        final name = path.split('/').last;
        if (!ids.contains(target)) {
          broken.add('$name -> topic:$target');
          continue;
        }
        if (anchor != null && anchor.isNotEmpty) {
          anchored++;
          if (!(anchorsById[target] ?? const {}).contains(anchor)) {
            broken.add('$name -> topic:$target#$anchor (no such anchor)');
          }
        }
      }
    });

    expect(
      anchored,
      greaterThan(50),
      reason:
          'suspiciously few anchored cross-links ($anchored) — the print '
          'points a quarter of its links into the drug reference alone.',
    );

    expect(
      total,
      greaterThan(100),
      reason:
          'suspiciously few cross-links found ($total) — did the link '
          'syntax change? A guard that stops matching stops guarding.',
    );
    expect(
      broken,
      isEmpty,
      reason:
          'Dead cross-links. These render as normal text and do nothing '
          'when tapped:\n  ${broken.join("\n  ")}',
    );
  });
}
