// GUARD — the print sets a unit smaller than the number it belongs to, and the
// vocabulary of what counts as a unit was *measured* off the PDF
// (`tool/wvems_unit_census.py`), not assumed. Two of those measurements
// contradict the obvious guess, so they are pinned here: an age is never a
// unit, and abbreviated time shrinks while spelled-out time does not.
//
// Without this, the next person to touch `kUnitTokens` would reasonably add
// `y/o` and `hours` and quietly diverge from the book.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orbweaver/widgets/unit_text.dart';

/// The text of every span rendered smaller than [size].
List<String> shrunk(String input, {double size = 14}) =>
    unitAwareSpans(
          input,
          TextStyle(fontSize: size),
          size,
        )
        .whereType<TextSpan>()
        .where((s) => (s.style?.fontSize ?? size) < size)
        .map(
          (
            s,
          ) => s.text!,
        )
        .toList();

void main() {
  group('unitAwareSpans', () {
    test('steps the unit down and leaves the number alone', () {
      expect(shrunk('500 mL'), ['mL']);
      expect(shrunk('2.5 mg'), ['mg']);
      expect(shrunk('5 mcg/kg/min'), ['mcg/kg/min']);
      expect(shrunk('40 mmHg'), ['mmHg']);
      expect(shrunk('2 grams'), ['grams']);
    });

    test('an age is never a unit — measured, not assumed', () {
      // `y/o`, `yr`, `months`, `days`, `weeks` do not appear in the print's
      // small tier at all across pp.5-95.
      expect(shrunk('14 y/o and over'), isEmpty);
      expect(shrunk('Children (1-13 y/o)'), isEmpty);
      expect(shrunk('under 5 months'), isEmpty);
    });

    test('abbreviated time shrinks, spelled-out time does not', () {
      expect(shrunk('Q 5 min x4'), ['min']);
      expect(shrunk('30 sec'), ['sec']);
      expect(shrunk('may last over 30 minutes'), isEmpty);
      expect(shrunk('within 6 hours'), isEmpty);
    });

    test('only a unit *after a number* is touched', () {
      // "min" is also an ordinary word; without a number before it, it stays.
      expect(shrunk('min 2 people'), isEmpty);
      expect(shrunk('Magnesium'), isEmpty);
    });

    test(
      'the gap before the unit keeps full size, so spacing is unchanged',
      () {
        final spans = unitAwareSpans(
          '500 mL',
          const TextStyle(fontSize: 14),
          14,
        ).cast<TextSpan>();
        expect(spans.map((s) => s.text).join(), '500 mL');
        expect(spans.first.text, '500 ');
        expect(spans.first.style!.fontSize, 14);
      },
    );

    test('text with no unit comes back as a single span', () {
      final spans = unitAwareSpans('Call Medical Control', null, 14);
      expect(spans, hasLength(1));
    });

    test('several units in one line each step down', () {
      expect(shrunk('Add 1 mg Epi into 1000 mL bag'), ['mg', 'mL']);
    });
  });
}
