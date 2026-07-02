import 'dart:io';

import 'package:flutter/material.dart' show Color;
import 'package:flutter_test/flutter_test.dart';
import 'package:orbweaver/data/library.dart';
import 'package:orbweaver/models/book.dart';
import 'package:yaml/yaml.dart';

/// Builds a leaf topic with the given id (title/subtitle/asset derived).
BookTopic _t(String id) =>
    BookTopic(id: id, title: id, subtitle: '', asset: 'topics/$id.yaml');

Book _book(List<BookNode> contents) => Book(
      id: 'b',
      title: 'B',
      subtitle: '',
      coverAsset: '',
      spineColor: const Color(0xFF000000),
      contents: contents,
    );

void main() {
  group('Book.allTopics walker', () {
    test('flat book yields its leaves in order', () {
      final book = _book([BookLeaf(_t('a')), BookLeaf(_t('b'))]);
      expect(book.allTopics.map((t) => t.id), ['a', 'b']);
    });

    test('depth-first: group overview before its children, recursively', () {
      // chapter
      //   leaf a
      //   section (overview: ov)
      //     leaf b
      //     subsection
      //       leaf c
      //   leaf d
      final book = _book([
        BookGroup(
          title: 'chapter',
          children: [
            BookLeaf(_t('a')),
            BookGroup(
              title: 'section',
              overview: _t('ov'),
              children: [
                BookLeaf(_t('b')),
                BookGroup(
                  title: 'subsection',
                  children: [BookLeaf(_t('c'))],
                ),
              ],
            ),
            BookLeaf(_t('d')),
          ],
        ),
      ]);
      expect(book.allTopics.map((t) => t.id), ['a', 'ov', 'b', 'c', 'd']);
    });

    test('findTopic resolves a deeply-nested id and misses cleanly', () {
      final book = _book([
        BookGroup(
          title: 'ch',
          children: [
            BookGroup(title: 'sec', children: [BookLeaf(_t('deep'))]),
          ],
        ),
      ]);
      expect(findTopic(book, 'deep')?.id, 'deep');
      expect(findTopic(book, 'nope'), isNull);
    });

    test('empty book has no topics', () {
      expect(_book([]).allTopics, isEmpty);
    });
  });

  group('migrated manifests parse as a contents tree', () {
    // Structural check on the real book.yaml files (no rootBundle needed):
    // the contents key exists and has the expected shape. Guards against a
    // manifest regressing to the old flat `topics:` form.
    int leafCount(YamlList nodes) {
      var n = 0;
      for (final entry in nodes) {
        final map = entry as YamlMap;
        if (map['title'] == null) {
          n++; // leaf
        } else {
          if (map['topic'] != null) n++; // group overview
          n += leafCount(map['children'] as YamlList? ?? YamlList());
        }
      }
      return n;
    }

    YamlMap loadBook(String id) {
      final raw = File('assets/books/$id/book.yaml').readAsStringSync();
      return (loadYaml(raw) as YamlMap)['book'] as YamlMap;
    }

    test('who_imci: 3 chapter groups (Ch.1 = 33, Ch.2 = 5, Ch.3 = 23)', () {
      final b = loadBook('who_imci');
      expect(b['topics'], isNull, reason: 'old flat key must be gone');
      final contents = b['contents'] as YamlList;
      expect(contents, hasLength(3));
      expect((contents[0] as YamlMap)['title'],
          '1. Triage and emergency conditions');
      expect((contents[1] as YamlMap)['title'],
          '2. Diagnostic approaches to the sick child');
      expect((contents[2] as YamlMap)['title'],
          '3. Problems of the neonate and young infant');
      // Ch.1 (33) + Ch.2 (5) + Ch.3 (10 leaves + §3.11/§3.12/§3.13 groups,
      // each overview + children = 5+4+4 = 13; 10+13 = 23) = 61 topics.
      expect(leafCount(contents), 61);
    });

    test('who_imci: Chapter 2 is a red-tabbed group of 5 sections', () {
      final b = loadBook('who_imci');
      final ch2 = (b['contents'] as YamlList)[1] as YamlMap;
      expect(ch2['palette']['accent'], '0xFFEF2B3E');
      expect((ch2['children'] as YamlList), hasLength(5));
    });

    test('who_imci: Chapter 3 is an orange-tabbed group; §3.11 nests', () {
      final b = loadBook('who_imci');
      final ch3 = (b['contents'] as YamlList)[2] as YamlMap;
      expect(ch3['palette']['accent'], '0xFFF05418');
      // 3.1–3.10 leaves + §3.11/§3.12/§3.13 subsection groups = 13 children.
      final children = ch3['children'] as YamlList;
      expect(children, hasLength(13));
      final g = children.firstWhere(
        (n) => (n as YamlMap)['title'] == '3.11 Preterm & low-birth-weight infants',
      ) as YamlMap;
      expect(g['topic'], isNotNull);
      expect((g['children'] as YamlList), hasLength(4));
    });

    test('who_imci: §1.5 is a nested subsection group with 3 children', () {
      final b = loadBook('who_imci');
      final ch1 = (b['contents'] as YamlList).first as YamlMap;
      final children = ch1['children'] as YamlList;
      final group = children.firstWhere(
        (n) => (n as YamlMap)['title'] == '1.5 Diagnostic considerations',
      ) as YamlMap;
      // The group carries its own overview topic plus 3 subsection leaves.
      expect(group['topic'], isNotNull);
      expect((group['children'] as YamlList), hasLength(3));
    });

    test('wvems: 5 groups (4 sections + drug ref), 47 topics total', () {
      final b = loadBook('wvems');
      expect(b['topics'], isNull);
      final contents = b['contents'] as YamlList;
      expect(contents, hasLength(5));
      expect(leafCount(contents), 47);
    });

    test('protocolbook: flat list of 15 leaves', () {
      final b = loadBook('protocolbook');
      expect(b['topics'], isNull);
      final contents = b['contents'] as YamlList;
      expect(contents, hasLength(15));
      expect(leafCount(contents), 15);
    });
  });
}
