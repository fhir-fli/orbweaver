import 'dart:io';

import 'package:flutter/material.dart' show Color;
import 'package:flutter_test/flutter_test.dart';
import 'package:orbweaver/data/library.dart';
import 'package:orbweaver/models/book.dart';
import 'package:orbweaver/models/formulary.dart';
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

    test(
        'who_imci: 12 chapters + Annex 1 + Annex 2 (Ch.1 = 33, Ch.2 = 5, '
        'Ch.3 = 24, Ch.4 = 24, Ch.5 = 9, Ch.6 = 25, Ch.7 = 27, Ch.8 = 34, '
        'Ch.9 = 33, Ch.10 = 15, Ch.11 = 3, Ch.12 = 8, Annex 1 = 13, '
        'Annex 2 = formulary)', () {
      final b = loadBook('who_imci');
      expect(b['topics'], isNull, reason: 'old flat key must be gone');
      final contents = b['contents'] as YamlList;
      expect(contents, hasLength(17));
      expect((contents[0] as YamlMap)['title'],
          '1. Triage and emergency conditions');
      expect((contents[1] as YamlMap)['title'],
          '2. Diagnostic approaches to the sick child');
      expect((contents[2] as YamlMap)['title'],
          '3. Problems of the neonate and young infant');
      expect((contents[3] as YamlMap)['title'],
          '4. Cough or difficulty in breathing');
      expect((contents[4] as YamlMap)['title'], '5. Diarrhoea');
      expect((contents[5] as YamlMap)['title'], '6. Fever');
      expect((contents[6] as YamlMap)['title'],
          '7. Severe acute malnutrition');
      expect((contents[7] as YamlMap)['title'],
          '8. Children with HIV/AIDS');
      expect((contents[8] as YamlMap)['title'],
          '9. Common surgical problems');
      expect((contents[9] as YamlMap)['title'], '10. Supportive care');
      expect((contents[10] as YamlMap)['title'],
          '11. Monitoring the child\'s progress');
      expect((contents[11] as YamlMap)['title'],
          '12. Counselling & discharge from hospital');
      expect((contents[12] as YamlMap)['title'],
          'Annex 1 · Practical procedures');
      expect((contents[13] as YamlMap)['title'], 'Annex 2 · Drug dosages');
      // Annexes 3 & 4 are single-table leaves (no title, bare topic refs).
      expect((contents[14] as YamlMap)['topic'], 'topics/who_a3_equipment.yaml');
      expect((contents[15] as YamlMap)['topic'], 'topics/who_a4_iv_fluids.yaml');
      expect((contents[16] as YamlMap)['title'],
          'Annex 5 · Assessing nutritional status');
      // Ch.1 (33) + Ch.2 (5) + Ch.3 (24) + Ch.4 (24) + Ch.5 (9)
      // + Ch.6 (25) + Ch.7 (27) + Ch.8 (34) + Ch.9 (33) + Ch.10 (15)
      // + Ch.11 (3) + Ch.12 (8) + Annex 1 (13) + Annex 3 (1) + Annex 4 (1)
      // + Annex 5 (3: A5.1 + A5.2 length + A5.2 height) = 258 manifest
      // topics. Annex 2 is a `view: collection` group with no manifest
      // children — its 82 drugs are generated at load from formulary.yaml.
      expect(leafCount(contents), 258);
    });

    test('who_imci: Annex 2 is a steel-blue formulary collection', () {
      final b = loadBook('who_imci');
      final a2 = (b['contents'] as YamlList)[13] as YamlMap;
      expect(a2['view'], 'collection');
      expect(a2['formulary'], 'formulary.yaml');
      expect(a2['palette']['accent'], '0xFF5981BF');
      // The collection has no inline children — drugs come from the dataset.
      expect(a2['children'], isNull);
    });

    test('who_imci: formulary.yaml loads as a Formulary (82 drugs, 3 lenses)',
        () {
      final raw =
          File('assets/books/who_imci/formulary.yaml').readAsStringSync();
      final f = Formulary.fromYaml(loadYaml(raw) as YamlMap);
      expect(f.drugs, hasLength(82));
      expect(f.facets.map((x) => x.key), ['alpha', 'class', 'indication']);
      expect(f.classOrder, contains('antibiotic'));
      expect(f.bands.columns, hasLength(5));
      expect(f.artBands.columns, hasLength(6));
      // A known multi-indication drug is modelled correctly.
      final cef = f.drugById('ceftriaxone')!;
      expect(cef.className, 'antibiotic');
      expect(cef.indications, containsAll(<String>['meningitis', 'sepsis']));
      expect(cef.doses.length, greaterThanOrEqualTo(3));
      expect(cef.bandColumns, hasLength(5));
      // An antiretroviral rides the 6-band ART axis.
      final lpv = f.drugById('lopinavir-ritonavir')!;
      expect(lpv.className, 'antiretroviral');
      expect(lpv.bandColumns, hasLength(6));
      // A drug may carry its own weight bands (ACTs, TB FDC) that match
      // neither shared axis.
      final dhap = f.drugById('dihydroartemisinin-piperaquine')!;
      expect(dhap.bandColumns, ['5–<8', '8–<11', '11–<17', '17–<25', '25–<36']);
      expect(f.drugById('rhz-fdc')!.bandColumns, hasLength(4));
      // A pre-referral drug with no band grid renders from regimen + notes.
      expect(f.drugById('rectal-artesunate')!.doses, isEmpty);
      // Every dose row's band count matches its drug's axis width.
      for (final d in f.drugs) {
        for (final dose in d.doses) {
          if (dose.bands.isNotEmpty) {
            expect(dose.bands, hasLength(d.bandColumns.length),
                reason: '${d.name} / ${dose.label}');
          }
        }
      }
    });

    test('who_imci: Annex 1 is a steel-blue-tabbed group; A1.2 nests', () {
      final b = loadBook('who_imci');
      final a1 = (b['contents'] as YamlList)[12] as YamlMap;
      expect(a1['palette']['accent'], '0xFF5981BF');
      expect(a1['topic'], isNotNull, reason: 'annex has its own overview');
      // A1.1 leaf + A1.2 group + A1.3/A1.4/A1.5/A1.6/A1.7 leaves = 7.
      final children = a1['children'] as YamlList;
      expect(children, hasLength(7));
      final g = children.firstWhere(
        (n) => (n as YamlMap)['title'] == 'A1.2 Giving parenteral fluids',
      ) as YamlMap;
      expect(g['topic'], isNotNull);
      // 5 sub-procedures (A1.2.1–A1.2.5) nested under the A1.2 overview.
      expect((g['children'] as YamlList), hasLength(5));
    });

    test('who_imci: Chapter 10 is a royal-blue-tabbed group; §10.1 & §10.6 nest',
        () {
      final b = loadBook('who_imci');
      final ch10 = (b['contents'] as YamlList)[9] as YamlMap;
      expect(ch10['palette']['accent'], '0xFF1C63B7');
      // 10.1 & 10.6 groups + 10.2/10.3/10.4/10.5/10.7/10.8 leaves = 8.
      final children = ch10['children'] as YamlList;
      expect(children, hasLength(8));
      final g = children.firstWhere(
        (n) => (n as YamlMap)['title'] == '10.6 Blood transfusion',
      ) as YamlMap;
      expect(g['topic'], isNotNull);
      // 5 sub-topics (10.6.1–10.6.5) nested under the §10.6 overview.
      expect((g['children'] as YamlList), hasLength(5));
    });

    test('who_imci: Ch.11 (violet) & Ch.12 (blue-violet) are flat leaf groups',
        () {
      final b = loadBook('who_imci');
      final ch11 = (b['contents'] as YamlList)[10] as YamlMap;
      expect(ch11['palette']['accent'], '0xFF542791');
      // 11.1/11.2/11.3 — three leaf sections, no nesting.
      final c11 = ch11['children'] as YamlList;
      expect(c11, hasLength(3));
      expect(c11.every((n) => (n as YamlMap)['title'] == null), isTrue);

      final ch12 = (b['contents'] as YamlList)[11] as YamlMap;
      expect(ch12['palette']['accent'], '0xFF7264B8');
      // 12.1–12.8 — eight leaf sections, no nesting.
      final c12 = ch12['children'] as YamlList;
      expect(c12, hasLength(8));
      expect(c12.every((n) => (n as YamlMap)['title'] == null), isTrue);
    });

    test('who_imci: Chapter 8 is a cyan-teal-tabbed group; §8.1 nests', () {
      final b = loadBook('who_imci');
      final ch8 = (b['contents'] as YamlList)[7] as YamlMap;
      expect(ch8['palette']['accent'], '0xFF00AAAF');
      // 8.1–8.7 all nested groups = 7 direct children.
      final children = ch8['children'] as YamlList;
      expect(children, hasLength(7));
      final g = children.firstWhere(
        (n) => (n as YamlMap)['title'] == '8.7 Palliative & end-of-life care',
      ) as YamlMap;
      expect(g['topic'], isNotNull);
      // 6 sub-topics (8.7.1–8.7.6) nested under the §8.7 overview.
      expect((g['children'] as YamlList), hasLength(6));
    });

    test('who_imci: Chapter 9 is a sky-blue-tabbed group; §9.4 nests', () {
      final b = loadBook('who_imci');
      final ch9 = (b['contents'] as YamlList)[8] as YamlMap;
      expect(ch9['palette']['accent'], '0xFF00ADEF');
      // 9.1–9.5 all nested groups = 5 direct children.
      final children = ch9['children'] as YamlList;
      expect(children, hasLength(5));
      final g = children.firstWhere(
        (n) => (n as YamlMap)['title'] == '9.4 Abdominal problems',
      ) as YamlMap;
      expect(g['topic'], isNotNull);
      // 9 sub-topics (9.4.1–9.4.9) nested under the §9.4 overview.
      expect((g['children'] as YamlList), hasLength(9));
    });

    test('who_imci: Chapter 6 is a green-tabbed group; §6.3 nests', () {
      final b = loadBook('who_imci');
      final ch6 = (b['contents'] as YamlList)[5] as YamlMap;
      expect(ch6['palette']['accent'], '0xFF40BA4E');
      // 6.1/6.2/6.3/6.4/6.7/6.10 groups + 6.5/6.6/6.8/6.9/6.11 leaves = 11.
      final children = ch6['children'] as YamlList;
      expect(children, hasLength(11));
      final g = children.firstWhere(
        (n) => (n as YamlMap)['title'] == '6.3 Meningitis',
      ) as YamlMap;
      expect(g['topic'], isNotNull);
      expect((g['children'] as YamlList), hasLength(4));
    });

    test('who_imci: Chapter 7 is a teal-tabbed group; §7.4 nests', () {
      final b = loadBook('who_imci');
      final ch7 = (b['contents'] as YamlList)[6] as YamlMap;
      expect(ch7['palette']['accent'], '0xFF009167');
      // 7.1/7.2/7.3 leaves + 7.4/7.5/7.6/7.7 groups = 7 direct children.
      final children = ch7['children'] as YamlList;
      expect(children, hasLength(7));
      final g = children.firstWhere(
        (n) => (n as YamlMap)['title'] == '7.4 General management (10 steps)',
      ) as YamlMap;
      expect(g['topic'], isNotNull);
      // 10 steps (7.4.1–7.4.10) nested under the §7.4 overview.
      expect((g['children'] as YamlList), hasLength(10));
    });

    test('who_imci: Chapter 5 is an olive-tabbed group; §5.2 nests', () {
      final b = loadBook('who_imci');
      final ch5 = (b['contents'] as YamlList)[4] as YamlMap;
      expect(ch5['palette']['accent'], '0xFF999100');
      // 5.1 leaf, 5.2 group, 5.3 group, 5.4 leaf = 4 direct children.
      final children = ch5['children'] as YamlList;
      expect(children, hasLength(4));
      final g = children.firstWhere(
        (n) => (n as YamlMap)['title'] == '5.2 Acute diarrhoea',
      ) as YamlMap;
      expect(g['topic'], isNotNull);
      expect((g['children'] as YamlList), hasLength(3));
    });

    test('who_imci: Chapter 4 is a brown-tabbed group; §4.6 nests', () {
      final b = loadBook('who_imci');
      final ch4 = (b['contents'] as YamlList)[3] as YamlMap;
      expect(ch4['palette']['accent'], '0xFF9C5400');
      // 4.1–4.9 = 9 direct children (leaves + subsection groups).
      final children = ch4['children'] as YamlList;
      expect(children, hasLength(9));
      final g = children.firstWhere(
        (n) =>
            (n as YamlMap)['title'] ==
            '4.6 Conditions presenting with stridor',
      ) as YamlMap;
      expect(g['topic'], isNotNull);
      expect((g['children'] as YamlList), hasLength(4));
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
      // 3.1–3.10 + §3.14 leaves + §3.11/§3.12/§3.13 subsection groups = 14.
      final children = ch3['children'] as YamlList;
      expect(children, hasLength(14));
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

    test('protocolbook: section groups (Emergency 15, Ingestions 11, '
        'Paediatric 8, Cardiac 2, Sickle Cell 4, SAM 3, ENT 6, TB 3, '
        'Anaemia 3, Pain 4, Neonatal 6, IM 9 = 74 leaves)', () {
      final b = loadBook('protocolbook');
      expect(b['topics'], isNull, reason: 'old flat key must be gone');
      final contents = b['contents'] as YamlList;
      // Twelve section groups so far, mirroring the book's dividers.
      expect(contents, hasLength(12));
      expect((contents[0] as YamlMap)['title'], 'Emergency Protocols');
      expect((contents[1] as YamlMap)['title'],
          'Ingestions, Anaphylaxis & Bites');
      expect((contents[2] as YamlMap)['title'], 'Paediatric Protocols');
      expect((contents[3] as YamlMap)['title'],
          'Paediatric Cardiac Protocols');
      expect((contents[4] as YamlMap)['title'], 'Sickle Cell Disease');
      expect((contents[5] as YamlMap)['title'], 'Severe Acute Malnutrition');
      expect((contents[6] as YamlMap)['title'], 'Ear, Nose & Throat');
      expect((contents[7] as YamlMap)['title'], 'Paediatric Tuberculosis');
      expect((contents[8] as YamlMap)['title'], 'Anaemia & Transfusion');
      expect((contents[9] as YamlMap)['title'], 'Pain Management');
      expect((contents[10] as YamlMap)['title'], 'Neonatal Protocols');
      expect((contents[11] as YamlMap)['title'], 'Internal Medicine Protocols');
      // Each group carries its own accent.
      expect((contents[0] as YamlMap)['palette']['accent'], '0xFFC62828');
      expect((contents[1] as YamlMap)['palette']['accent'], '0xFF6A1B9A');
      expect((contents[2] as YamlMap)['palette']['accent'], '0xFF2E7D32');
      expect((contents[3] as YamlMap)['palette']['accent'], '0xFFAD1457');
      expect((contents[4] as YamlMap)['palette']['accent'], '0xFFBF360C');
      expect((contents[5] as YamlMap)['palette']['accent'], '0xFF00695C');
      expect((contents[6] as YamlMap)['palette']['accent'], '0xFF5D4037');
      expect((contents[7] as YamlMap)['palette']['accent'], '0xFF283593');
      expect((contents[8] as YamlMap)['palette']['accent'], '0xFF37474F');
      expect((contents[9] as YamlMap)['palette']['accent'], '0xFFEF6C00');
      expect((contents[10] as YamlMap)['palette']['accent'], '0xFF0277BD');
      expect((contents[11] as YamlMap)['palette']['accent'], '0xFF0D47A1');
      // Emergency Protocols = p.12–26 (15 topics), ending in Altered
      // Mental Status; Ingestions has Poisoning (p.28); Paediatric has
      // Meningitis (p.55) for now.
      final emergency = (contents[0] as YamlMap)['children'] as YamlList;
      expect(emergency, hasLength(15));
      expect((emergency[14] as YamlMap)['topic'],
          'topics/pb_altered_mental_status.yaml');
      final ingestions = (contents[1] as YamlMap)['children'] as YamlList;
      expect(ingestions, hasLength(11));
      expect((ingestions[0] as YamlMap)['topic'],
          'topics/pb_poisoning_ingestion.yaml');
      expect((ingestions[1] as YamlMap)['topic'],
          'topics/pb_organophosphate.yaml');
      expect((ingestions[2] as YamlMap)['topic'],
          'topics/pb_hydrocarbon.yaml');
      expect((ingestions[3] as YamlMap)['topic'],
          'topics/pb_benzo_opioid.yaml');
      expect((ingestions[4] as YamlMap)['topic'],
          'topics/pb_paracetamol.yaml');
      expect((ingestions[5] as YamlMap)['topic'],
          'topics/pb_alcohol_intoxication.yaml');
      expect((ingestions[6] as YamlMap)['topic'],
          'topics/pb_alcohol_withdrawal.yaml');
      expect((ingestions[7] as YamlMap)['topic'],
          'topics/pb_ciwa_ar.yaml');
      expect((ingestions[8] as YamlMap)['topic'],
          'topics/pb_anaphylaxis.yaml');
      expect((ingestions[9] as YamlMap)['topic'],
          'topics/pb_animal_bite.yaml');
      expect((ingestions[10] as YamlMap)['topic'],
          'topics/pb_snake_bite.yaml');
      final paediatric = (contents[2] as YamlMap)['children'] as YamlList;
      expect(paediatric, hasLength(8));
      expect((paediatric[0] as YamlMap)['topic'],
          'topics/pb_paediatric_convulsions.yaml');
      expect((paediatric[1] as YamlMap)['topic'],
          'topics/pb_paediatric_dehydration.yaml');
      expect((paediatric[2] as YamlMap)['topic'],
          'topics/pb_paediatric_sepsis.yaml');
      expect((paediatric[3] as YamlMap)['topic'],
          'topics/pb_paediatric_pneumonia.yaml');
      expect((paediatric[4] as YamlMap)['topic'],
          'topics/pb_paediatric_dka.yaml');
      expect((paediatric[5] as YamlMap)['topic'],
          'topics/pb_uti_kidney.yaml');
      expect((paediatric[6] as YamlMap)['topic'],
          'topics/pb_wheezing_child.yaml');
      expect((paediatric[7] as YamlMap)['topic'],
          'topics/pb_meningitis.yaml');
      final cardiac = (contents[3] as YamlMap)['children'] as YamlList;
      expect(cardiac, hasLength(2));
      expect((cardiac[0] as YamlMap)['topic'],
          'topics/pb_heart_failure.yaml');
      expect((cardiac[1] as YamlMap)['topic'],
          'topics/pb_rheumatic_fever.yaml');
      final sickle = (contents[4] as YamlMap)['children'] as YamlList;
      expect(sickle, hasLength(4));
      expect((sickle[0] as YamlMap)['topic'],
          'topics/pb_sickle_cell.yaml');
      expect((sickle[1] as YamlMap)['topic'],
          'topics/pb_sickle_cell_acute.yaml');
      expect((sickle[2] as YamlMap)['topic'],
          'topics/pb_sickle_cell_stroke.yaml');
      expect((sickle[3] as YamlMap)['topic'],
          'topics/pb_sickle_cell_acs.yaml');
      final sam = (contents[5] as YamlMap)['children'] as YamlList;
      expect(sam, hasLength(3));
      expect((sam[0] as YamlMap)['topic'],
          'topics/pb_sam_assessment.yaml');
      expect((sam[1] as YamlMap)['topic'],
          'topics/pb_sam_management.yaml');
      expect((sam[2] as YamlMap)['topic'],
          'topics/pb_sam_feeding.yaml');
      final ent = (contents[6] as YamlMap)['children'] as YamlList;
      expect(ent, hasLength(6));
      expect((ent[0] as YamlMap)['topic'],
          'topics/pb_epistaxis.yaml');
      expect((ent[1] as YamlMap)['topic'],
          'topics/pb_otitis_media.yaml');
      expect((ent[2] as YamlMap)['topic'],
          'topics/pb_otitis_externa.yaml');
      expect((ent[3] as YamlMap)['topic'],
          'topics/pb_mastoiditis.yaml');
      expect((ent[4] as YamlMap)['topic'],
          'topics/pb_pharyngitis.yaml');
      expect((ent[5] as YamlMap)['topic'],
          'topics/pb_sinusitis.yaml');
      final tb = (contents[7] as YamlMap)['children'] as YamlList;
      expect(tb, hasLength(3));
      expect((tb[0] as YamlMap)['topic'],
          'topics/pb_tb_diagnosis.yaml');
      expect((tb[1] as YamlMap)['topic'],
          'topics/pb_tb_scoring.yaml');
      expect((tb[2] as YamlMap)['topic'],
          'topics/pb_tb_treatment.yaml');
      final anaemia = (contents[8] as YamlMap)['children'] as YamlList;
      expect(anaemia, hasLength(3));
      expect((anaemia[0] as YamlMap)['topic'],
          'topics/pb_anaemia.yaml');
      expect((anaemia[1] as YamlMap)['topic'],
          'topics/pb_anaemia_workup.yaml');
      expect((anaemia[2] as YamlMap)['topic'],
          'topics/pb_transfusions.yaml');
      final pain = (contents[9] as YamlMap)['children'] as YamlList;
      expect(pain, hasLength(4));
      expect((pain[0] as YamlMap)['topic'],
          'topics/pb_pain_nips.yaml');
      expect((pain[1] as YamlMap)['topic'],
          'topics/pb_pain_flacc.yaml');
      expect((pain[2] as YamlMap)['topic'],
          'topics/pb_pain_faces.yaml');
      expect((pain[3] as YamlMap)['topic'],
          'topics/pb_pain_ladder.yaml');
      final neo = (contents[10] as YamlMap)['children'] as YamlList;
      expect(neo, hasLength(6));
      expect((neo[0] as YamlMap)['topic'],
          'topics/pb_neo_feeding.yaml');
      expect((neo[1] as YamlMap)['topic'],
          'topics/pb_neo_cpap.yaml');
      expect((neo[2] as YamlMap)['topic'],
          'topics/pb_neo_sepsis_prevention.yaml');
      expect((neo[3] as YamlMap)['topic'],
          'topics/pb_neo_sepsis_treatment.yaml');
      expect((neo[4] as YamlMap)['topic'],
          'topics/pb_neo_jaundice.yaml');
      expect((neo[5] as YamlMap)['topic'],
          'topics/pb_neo_ballard.yaml');
      final im = (contents[11] as YamlMap)['children'] as YamlList;
      expect(im, hasLength(9));
      expect((im[0] as YamlMap)['topic'],
          'topics/pb_im_heart_failure.yaml');
      expect((im[1] as YamlMap)['topic'],
          'topics/pb_im_stroke.yaml');
      expect((im[2] as YamlMap)['topic'],
          'topics/pb_im_sepsis.yaml');
      expect((im[3] as YamlMap)['topic'],
          'topics/pb_im_convulsions.yaml');
      expect((im[4] as YamlMap)['topic'],
          'topics/pb_im_meningitis.yaml');
      expect((im[5] as YamlMap)['topic'],
          'topics/pb_im_gi_bleed.yaml');
      expect((im[6] as YamlMap)['topic'],
          'topics/pb_im_dka.yaml');
      expect((im[7] as YamlMap)['topic'],
          'topics/pb_im_hypertension.yaml');
      expect((im[8] as YamlMap)['topic'],
          'topics/pb_im_liver_failure.yaml');
      expect(leafCount(contents), 74);
    });
  });
}
