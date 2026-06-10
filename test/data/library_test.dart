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

    test('who_imci: 1 chapter group with 5 charts, no flat topics key', () {
      final b = loadBook('who_imci');
      expect(b['topics'], isNull, reason: 'old flat key must be gone');
      final contents = b['contents'] as YamlList;
      expect(contents, hasLength(1));
      expect((contents.first as YamlMap)['title'], '1. Triage and emergency conditions');
      expect(leafCount(contents), 5);
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
