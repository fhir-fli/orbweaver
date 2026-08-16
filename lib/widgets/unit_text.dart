import 'package:flutter/material.dart';

/// The print sets a unit smaller than the number it belongs to — 20 pt against
/// a 25 pt body — so the numeral is the thing you read and the unit is a label
/// hanging off it: **500** mL, **2.5** mg, **5** mcg/kg/min.
///
/// The audit measured 301 of these across pp.3-95 and suggested authoring an
/// inline mark for each. They are not authored: the rule is systematic, the
/// unit vocabulary is closed, and 301 hand-written marks would be 301 chances
/// to miss one. [unitAwareSpans] applies the rule wherever text is drawn.
///
/// [kUnitScale] is 0.85 rather than the print's exact 0.80. The audit flags
/// that 0.80 was chosen for 25 pt paper and is worth testing on a backlit
/// 12-14 px body first; at 0.85 a 12 px unit renders at 10.2 px, which stays
/// comfortably readable while still stepping down visibly.
const double kUnitScale = 0.85;

/// Scale for the registered mark. Smaller than a unit — the print runs it at
/// 0.667-0.80 — because it carries no clinical information at all.
const double kMarkScale = 0.7;

/// Unit tokens, read off the PDF rather than assumed — every span on the odd
/// prose pages set below body size with a number before it
/// (`tool/wvems_unit_census.py`, 276 instances, 41 distinct).
///
/// The measurement corrected two guesses worth recording:
///
/// * **Age is never a unit here.** `y/o`, `yr`, `months`, `days`, `weeks` do
///   not appear in the small tier at all, so "14 y/o" stays at body size.
/// * **Abbreviated time shrinks, spelled-out time does not** — `min`, `sec`,
///   `h`, `ms` are in the tier; `hours` and `minutes` are not.
///
/// Ordinals (`th`, `st`, `nd`) *are* in the print's small tier but are
/// deliberately excluded: they only occur in the `15th ed.` citation, which
/// §3.3 says to leave plain on a phone and §3.7 wants shrunk as a whole line.
const Set<String> kUnitTokens = {
  // mass / volume
  'mg', 'mcg', 'g', 'gram', 'grams', 'kg', 'lb', 'lbs',
  'mL', 'L', 'mEq',
  // pressure, electrical, misc
  'mmHg', 'mmhg', 'V', 'J', 'mph', '%', '°',
  // time (abbreviated only — see the doc comment)
  'min', 'sec', 'h', 'ms',
  // dose / rate compounds
  'mg/kg', 'mcg/kg', 'mcg/kg/min', 'mcg/min', 'mcg/mL', 'mg/mL', 'mg/min',
  'mL/kg', 'mL/hr', 'mEq/L', 'gtt/mL', 'gtt', 'L/min', '/min', '/kg',
  'unit', 'units',
};

/// A unit token immediately after a number: the digits, any space, the token.
/// Kept anchored to the number because "min" on its own is a word.
final RegExp _unitAfterNumber = RegExp(
  r'(?<=[0-9])(\s*)([A-Za-z°%/]+)',
);

/// The registered mark, which the print sets at 0.67-0.80 of the body (§3.3).
/// The app had 109 of them at full size, where a ® next to a drug name is
/// visually louder than the drug name's own emphasis.
final RegExp _registered = RegExp('®');

/// [text] split into spans, with any unit that follows a number set at
/// [kUnitScale] of [fontSize]. Returns a single span when there is nothing to
/// shrink, which is the common case.
///
/// [fontSize] is passed rather than read off [base] because callers routinely
/// leave the size to the ambient `DefaultTextStyle`; guessing it here would
/// silently mis-scale every unit in a flow node.
List<InlineSpan> unitAwareSpans(String text, TextStyle? base, double fontSize) {
  // (start, end, scale) for every run that steps down, in order.
  final marks = <(int, int, double)>[
    for (final m in _unitAfterNumber.allMatches(text))
      if (kUnitTokens.contains(m.group(2)))
        (m.start + m.group(1)!.length, m.end, kUnitScale),
    for (final m in _registered.allMatches(text)) (m.start, m.end, kMarkScale),
  ]..sort((a, b) => a.$1.compareTo(b.$1));
  if (marks.isEmpty) return [TextSpan(text: text, style: base)];

  final spans = <InlineSpan>[];
  var last = 0;
  for (final (start, end, scale) in marks) {
    if (start < last) continue; // overlapping marks: first one wins
    if (start > last) {
      spans.add(TextSpan(text: text.substring(last, start), style: base));
    }
    spans.add(
      TextSpan(
        text: text.substring(start, end),
        style: (base ?? const TextStyle()).copyWith(
          fontSize: fontSize * scale,
        ),
      ),
    );
    last = end;
  }
  if (last < text.length) {
    spans.add(TextSpan(text: text.substring(last), style: base));
  }
  return spans;
}
