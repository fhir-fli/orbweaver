// The comparison a translation must pass against its English source.
// Shared by test/l10n/translations_test.dart (every bundled translation) and
// tool/l10n/check_pair.dart (one pair from the command line).
// Pure Dart: package:yaml and package:crypto only.

import 'dart:io';

import 'package:crypto/crypto.dart';

/// Keys whose string values are prose a reader sees, and so are translated.
/// Any key NOT listed here must carry the identical value in a translation.
/// Adding a key is a decision: only add one whose values are never an id,
/// a path, a lookup key or an enum.
///
/// A `type.key` entry makes `key` translatable only inside a map whose
/// `type:` is `type`. A drug card's `class` and `indications` are prose
/// ("Oxymetazoline — α-adrenergic agonist", "Nosebleeds"), but the same keys
/// in a formulary are ids (`class: antiarrhythmic`, `indications: [hiv]`).
const kTranslatableKeys = <String>{
  'aliases',
  'drug_card.class',
  'drug_card.indications',
  'band_columns',
  'band_label',
  'bands',
  'bullets',
  'caption',
  'caveats',
  'cc_title',
  'cells',
  'columns',
  'condition',
  'criteria',
  'daily',
  'decision',
  'detail',
  'dose',
  'down_label',
  // WVEMS dose tables: the drug cell ("[NS Bolus](topic:...)").
  'drug',
  'form',
  // WVEMS dose tables: how often ("Q 5 min x2").
  'frequency',
  'help',
  'intro',
  'label',
  'list_subtitle',
  'lookup_label',
  'loop_label',
  'markdown',
  'name',
  'note',
  'notes',
  'pearls',
  'privacy_label',
  'reason',
  'reference_label',
  'regimen',
  'rows',
  'source',
  'steps',
  'subtitle',
  'tags',
  'text',
  // Statin tiers: the header and each row's tier must stay the same word
  // (conversion_block_view matches them); translations_test checks it.
  'tier',
  'tier_note',
  'tiers',
  'timing',
  // credits.yaml: what an image illustrates ("vial"); read by nothing but the screen.
  'use',
  'title',
  'warnings',
};

final sourceLine = RegExp(r'^# translated-from-sha256: ([0-9a-f]{64})\s*$');

final _numbers = RegExp(r'\d+(?:[.,]\d+)*');
final _comparisons = RegExp('[<>≤≥]');
// A unit counts only right after a number or a "/" ("0.1 mg/kg", "5 mL",
// "1-ml syringe"):
// a bare letter in prose ("e.g.", "GCS") is not a unit. An English plural
// ("9 mLs", "50mls") is the same unit, so the trailing "s" is matched but not
// captured: the unit compared is group 1.
final _units = RegExp(
  r'(?<=(?:\d|/)[\s-]?)(mg|mcg|µg|μg|ng|g|kg|mL|ml|L|dL|mmol|mEq|mOsm)s?(?![A-Za-zÀ-ÿ])',
);
final _links = RegExp(r'\]\(([^)]+)\)');

String sha256Of(File f) => sha256.convert(f.readAsBytesSync()).toString();

List<String> _sorted(Iterable<String> xs) => [...xs]..sort();

List<String> allMatches(RegExp re, String s, [int group = 0]) =>
    _sorted(re.allMatches(s).map((m) => m.group(group)!));

/// The block structure MiniMarkdown renders (lib/widgets/mini_markdown.dart):
/// a blank line is a break, a line starting "- " is a bullet at its indent
/// level, and any other line starts a paragraph unless it continues the one
/// before. A continuation (a soft-wrapped line) is not structure, so a longer
/// translation that wraps differently still has the same layout.
String layoutOf(String s) {
  final out = <String>[];
  var open = false;
  for (final raw in s.trimRight().split('\n')) {
    final t = raw.trim();
    final level = (raw.length - raw.trimLeft().length) ~/ 2;
    if (t.isEmpty) {
      out.add('_');
      open = false;
    } else if (t.startsWith('- ')) {
      out.add('b$level');
      open = true;
    } else if (!open) {
      out.add('p$level');
      open = true;
    }
  }
  return out.join(' ');
}

/// What must survive translation unchanged in one string.
Map<String, Object> safetyOf(String s) => {
  'numbers': allMatches(_numbers, s),
  'comparisons': allMatches(_comparisons, s),
  // "ml" and "mL" are one unit; the books use both spellings.
  'units': _sorted(allMatches(_units, s, 1).map((u) => u == 'ml' ? 'mL' : u)),
  'links': allMatches(_links, s, 1),
  'bold runs': '**'.allMatches(s).length,
  'layout': layoutOf(s),
};

/// Compares a parsed English node with its translation, appending each
/// difference to [problems].
void compareTranslation(
  Object? en,
  Object? tr,
  String path,
  String? key,
  List<String> problems,
) {
  if (en is Map) {
    if (tr is! Map) {
      problems.add('$path: English is a map, translation is not');
      return;
    }
    final ek = _sorted(en.keys.map((k) => '$k'));
    final tk = _sorted(tr.keys.map((k) => '$k'));
    if (ek.join(',') != tk.join(',')) {
      problems.add('$path: keys differ\n    en: $ek\n    tr: $tk');
      return;
    }
    for (final k in en.keys) {
      final scoped = '${en['type']}.$k';
      final key = kTranslatableKeys.contains(scoped) ? scoped : '$k';
      compareTranslation(en[k], tr[k], '$path.$k', key, problems);
    }
  } else if (en is List) {
    if (tr is! List || tr.length != en.length) {
      problems.add(
        '$path: list length ${en.length} vs '
        '${tr is List ? tr.length : 'not a list'}',
      );
      return;
    }
    for (var i = 0; i < en.length; i++) {
      compareTranslation(en[i], tr[i], '$path[$i]', key, problems);
    }
  } else if (en is String && tr is String && kTranslatableKeys.contains(key)) {
    final a = safetyOf(en);
    final b = safetyOf(tr);
    for (final part in a.keys) {
      if ('${a[part]}' != '${b[part]}') {
        problems.add(
          '$path: $part differ\n    en: ${a[part]}  «$en»\n'
          '    tr: ${b[part]}  «$tr»',
        );
      }
    }
  } else if (en != tr) {
    problems.add(
      '$path: must be identical (key "$key")\n    en: $en\n    tr: $tr',
    );
  }
}
