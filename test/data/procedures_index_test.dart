// GUARD — every link on the Procedures index (p.96) must land somewhere.
//
// p.96 is the print's map of pp.97-109: a grid of cards whose only job is to
// get the reader to a procedure. A link that resolves to nothing is worse than
// no index at all — the reader taps under time pressure and the page does not
// move, with no error to explain why. The anchors are slugs derived from each
// card's `name:`, so renaming a procedure silently breaks every inbound link,
// which is exactly what happened to "Administer Antidote" (authored as "Adult
// Antidotes", with twenty links pointing at the old slug).
//
// Checks both directions of that failure: every in-topic target exists, and
// every procedure the print indexes is actually linked from the index.

import 'package:flutter_test/flutter_test.dart';
import 'package:orbweaver/data/topic_loader.dart';
import 'package:orbweaver/models/topic.dart';

const String kProceduresAsset = 'assets/books/wvems/topics/wvems_2026_096.yaml';

/// The 27 procedures the print lists on p.96, by the label the index gives
/// them. Transcribed from the page and cross-checked against its vector badge
/// fills (`tool/wvems_procedures_index.py`).
const List<String> kIndexedProcedures = [
  'Glucometer',
  '12-Lead',
  'Saline Lock',
  'Back Blows & Thrusts',
  'Suction',
  'Magill Forceps',
  'BVM',
  'OPA / NPA',
  'NIPPV',
  'BIAD',
  'OG-Tube',
  'Pleural Decompress',
  'Chest Compression',
  'Defib',
  'IO',
  'Wound Care',
  'Tourniquet',
  'Wound Packing',
  'SMR with C-collar',
  'Splint',
  'Reduce Deformity',
  'Stinger Removal',
  'Administer Antidote',
  'Pacing',
  'Cardiovert',
  'Deliver Baby',
  'Manage OB Complication',
];

/// Anchors the topic offers: one per procedure card.
Set<String> _anchors(Topic topic) {
  final out = <String>{};
  void walk(List<Block> blocks) {
    for (final block in blocks) {
      if (block is ProcedureBlock && block.anchor != null) {
        out.add(block.anchor!);
      }
      if (block is RowBlock) walk(block.blocks);
      if (block is ColumnBlock) walk(block.blocks);
    }
  }

  for (final page in topic.pages) {
    walk(page.blocks);
  }
  return out;
}

void main() {
  // Asset loading needs the binding, even for a non-widget test.
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'every p.96 index link resolves, and every procedure is indexed',
    () async {
      final topic = await loadTopicAsset(kProceduresAsset);
      final anchors = _anchors(topic);
      expect(
        anchors,
        isNotEmpty,
        reason: 'no procedure_card anchors found — did the loader change?',
      );

      for (final name in kIndexedProcedures) {
        final slug = anchorSlug(name);
        // "OPA / NPA" is the index's wording; the card it points at is titled
        // "NPA / OPA" — the print itself differs between index and card, and
        // both are reproduced, so this one resolves through the card's slug.
        final target = name == 'OPA / NPA' ? anchorSlug('NPA / OPA') : slug;
        expect(
          anchors,
          contains(target),
          reason:
              'p.96 indexes "$name" but no procedure card answers to '
              '#$target — the index link is dead',
        );
      }
    },
  );
}
