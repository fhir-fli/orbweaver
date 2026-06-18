import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orbweaver/theme/palette.dart';

void main() {
  group('parsePaletteColor', () {
    test('parses 0xAARRGGBB, 0xRRGGBB, #RRGGBB, bare RRGGBB', () {
      expect(parsePaletteColor('0xFFD81B60'), const Color(0xFFD81B60));
      expect(parsePaletteColor('0xD81B60'), const Color(0xFFD81B60));
      expect(parsePaletteColor('#D81B60'), const Color(0xFFD81B60));
      expect(parsePaletteColor('D81B60'), const Color(0xFFD81B60));
    });

    test('returns null for malformed or non-string input', () {
      expect(parsePaletteColor('zzz'), isNull);
      expect(parsePaletteColor('0x12345'), isNull); // 5 hex digits
      expect(parsePaletteColor(123), isNull);
      expect(parsePaletteColor(null), isNull);
    });
  });

  group('parsePaletteOverrides', () {
    test('parses a role→hex map and skips bad entries', () {
      final m = parsePaletteOverrides({
        'accent': '0xFFD81B60',
        'severity_mild_tile': '#00FF00',
        'bad': 'not-a-color',
      });
      expect(m['accent'], const Color(0xFFD81B60));
      expect(m['severity_mild_tile'], const Color(0xFF00FF00));
      expect(m.containsKey('bad'), isFalse);
    });

    test('non-map input → empty', () {
      expect(parsePaletteOverrides(null), isEmpty);
      expect(parsePaletteOverrides('x'), isEmpty);
    });
  });

  group('resolvePalette cascade', () {
    test('empty layers → defaults + neutral accent', () {
      final p = resolvePalette([]);
      expect(p['accent'], kNeutralAccent);
      expect(p['severity_severe_tile'],
          kRoleDefaults['severity_severe_tile']);
      expect(p['provider_emt'], kRoleDefaults['provider_emt']);
    });

    test('accent-derived roles fall out of the resolved accent', () {
      final p = resolvePalette([]);
      // branch defaults to the accent; fill is a derived lighter tint.
      expect(p['accent_branch'], kNeutralAccent);
      expect(p['accent_fill'], isNotNull);
      expect(p['accent_fill'], isNot(kNeutralAccent));
    });

    test('later layers override earlier ones, per role', () {
      final p = resolvePalette([
        {'accent': const Color(0xFF1111FF)}, // book
        {'accent': const Color(0xFF22AA22)}, // chapter wins
      ]);
      expect(p['accent'], const Color(0xFF22AA22));
    });

    test('roles are independent across layers', () {
      final p = resolvePalette([
        {'accent': const Color(0xFF1111FF)},
        {'severity_severe_tile': const Color(0xFFFF0000)},
      ]);
      expect(p['accent'], const Color(0xFF1111FF));
      expect(p['severity_severe_tile'], const Color(0xFFFF0000));
    });

    test('accent override re-derives branch (and fill) from it', () {
      final magenta = const Color(0xFFD81B60);
      final p = resolvePalette([
        {'accent': magenta},
      ]);
      expect(p['accent_branch'], magenta);
      expect(p['accent_fill'], isNot(kNeutralAccent));
    });

    test('explicit accent_fill override is preserved, not re-derived', () {
      final p = resolvePalette([
        {'accent': const Color(0xFFD81B60), 'accent_fill': const Color(0xFF00FFFF)},
      ]);
      expect(p['accent_fill'], const Color(0xFF00FFFF));
    });

    test('custom role names pass through', () {
      final p = resolvePalette([
        {'my_stroke_alert': const Color(0xFFFF9900)},
      ]);
      expect(p['my_stroke_alert'], const Color(0xFFFF9900));
    });
  });
}
