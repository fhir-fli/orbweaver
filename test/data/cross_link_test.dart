// GUARD — every `[label](topic:some-id)` cross-link must resolve.
//
// A dead cross-link in a clinical reference is silent: MiniMarkdown renders the
// label normally, the tap handler finds nothing, and the user is left on the
// page wondering whether they mis-tapped. Nothing in the app or the build
// surfaces it.
//
// This caught three live ones: the WVEMS drug reference pointed at
// `wvems-2026-008` for Circulation / Shock, but that page is still the 2025
// edition (`wvems-2025-008`), so all three links were dead.
//
// Reads the YAML directly rather than going through loadLibrary(), so it also
// covers topics that are authored but not yet registered in a book.yaml.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// `[label](topic:the-id)` and `[label](topic:the-id#anchor)`.
final _linkPattern = RegExp(r'\(topic:([^)#]+)(#[^)]*)?\)');
final _idPattern = RegExp(r'^\s*id:\s*"([^"]+)"', multiLine: true);

void main() {
  test('every topic: cross-link resolves to a defined topic id', () {
    final files = Directory('assets/books')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.contains('/topics/') && f.path.endsWith('.yaml'))
        .toList();
    expect(files, isNotEmpty, reason: 'no topic YAML found — path wrong?');

    final ids = <String>{};
    final sources = <String, String>{};
    for (final f in files) {
      final text = f.readAsStringSync();
      sources[f.path] = text;
      for (final m in _idPattern.allMatches(text)) {
        ids.add(m.group(1)!);
      }
    }

    final broken = <String>[];
    var total = 0;
    sources.forEach((path, text) {
      for (final m in _linkPattern.allMatches(text)) {
        total++;
        final target = m.group(1)!.trim();
        if (!ids.contains(target)) {
          broken.add('${path.split('/').last} -> topic:$target');
        }
      }
    });

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
