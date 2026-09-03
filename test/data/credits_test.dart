import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:yaml/yaml.dart';

/// Licence-compliance guard for the in-app credits.
///
/// The bundled Wikimedia images are CC BY and CC BY-SA. Both require that
/// attribution - author, source and licence - reaches the people who see the
/// work. Before 2026-09-02 the attributions sat in a markdown file inside the
/// asset bundle that nothing displayed, which is not attribution.
///
/// These fail if an image loses its author, source or licence, and if an image
/// ships with no credit at all.
void main() {
  final doc = loadYaml(File('assets/credits.yaml').readAsStringSync()) as YamlMap;
  final credits = doc['credits'] as YamlMap;
  final images = (credits['images'] as YamlMap)['items'] as YamlList;

  test('every credited image names an author, a source and a licence', () {
    final bad = <String>[];
    for (final raw in images) {
      final i = raw as YamlMap;
      final file = (i['file'] ?? '').toString();
      for (final field in ['use', 'source', 'author', 'licence']) {
        if ((i[field] ?? '').toString().trim().isEmpty) {
          bad.add('$file: $field is empty');
        }
      }
    }
    expect(bad, isEmpty, reason: bad.join('\n'));
  });

  test('a CC BY or CC BY-SA image carries a licence URL', () {
    // CC0 and public domain require no attribution and are exempt; everything
    // else must link the licence it is used under.
    final bad = <String>[];
    for (final raw in images) {
      final i = raw as YamlMap;
      final lic = (i['licence'] ?? '').toString().toLowerCase();
      if (lic.contains('cc0') || lic.contains('public domain')) continue;
      if ((i['licence_url'] ?? '').toString().trim().isEmpty) {
        bad.add('${i['file']}: ${i['licence']} has no licence_url');
      }
    }
    expect(bad, isEmpty, reason: bad.join('\n'));
  });

  test('every bundled Wikimedia image is credited', () {
    // The credit list must not fall behind the bundle. Only the WVEMS form and
    // equipment images come from Wikimedia; the chart and ECG images in the
    // other books are ours or the publishers'.
    final credited = {
      for (final raw in images) ((raw as YamlMap)['file'] ?? '').toString(),
    };
    final uncredited = <String>[];
    for (final f in Directory('assets/books/wvems/images').listSync().whereType<File>()) {
      final name = f.uri.pathSegments.last;
      if (!name.startsWith('form_') && !name.startsWith('eq_')) continue;
      if (!credited.contains(name)) uncredited.add(name);
    }
    expect(uncredited, isEmpty,
        reason: 'bundled but credited nowhere: ${uncredited.join(', ')}');
  });

  test('the privacy link is present and points at the live policy', () {
    // Play requires this at production, not for closed testing, but the app
    // should say what it collects whether or not a store demands it.
    final url = (credits['privacy_url'] ?? '').toString();
    expect(url, startsWith('https://'));
    expect(url, contains('orbweaver-privacy'));
    expect((credits['privacy_label'] ?? '').toString().trim(), isNotEmpty);
  });

  test('each book carries a source acknowledgement', () {
    final sources = credits['sources'] as YamlList;
    expect(sources.length, greaterThanOrEqualTo(3));
    for (final raw in sources) {
      final s = raw as YamlMap;
      expect((s['title'] ?? '').toString().trim(), isNotEmpty);
      expect((s['by'] ?? '').toString().trim(), isNotEmpty);
    }
  });
}
