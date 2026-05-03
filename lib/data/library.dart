import 'package:flutter/material.dart';
import 'package:orbweaver/models/book.dart';

/// The set of books on the shelf.
///
/// Topics that share a prefix belong to the same book (pb_ = Protocol
/// Quick Reference, wvems_ = WVEMS, who_ = WHO IMCI, demo_ = Block Demos).
/// This list is the source of truth for the shelf screen.
const library = <Book>[
  Book(
    id: 'protocolbook',
    title: 'Quick Reference',
    subtitle: 'Paediatrics & Internal Medicine',
    coverAsset: 'assets/covers/protocolbook.jpg',
    spineColor: Color(0xFF2E7D32),
    topics: [
      BookTopic(
        id: 'pb_triage',
        title: 'Paediatric Triage of Sick Children',
        subtitle: 'p.12 · severity table',
        asset: 'assets/topics/pb_triage.yaml',
        tags: ['triage', 'pediatric', 'emergency'],
      ),
      BookTopic(
        id: 'pb_pals',
        title: 'Paediatric Advanced Life Support',
        subtitle: 'p.13 · PALS flowchart',
        asset: 'assets/topics/pb_pals.yaml',
        tags: ['pals', 'resuscitation', 'pediatric', 'cpr'],
      ),
      BookTopic(
        id: 'pb_cardiac_arrest',
        title: 'Adult Cardiac Arrest',
        subtitle: 'p.14 · ACLS branches',
        asset: 'assets/topics/pb_cardiac_arrest.yaml',
        tags: ['acls', 'resuscitation', 'adult', 'cpr'],
      ),
      BookTopic(
        id: 'pb_cpr_summary',
        title: 'CPR Summary (Adults · Children · Infants)',
        subtitle: 'p.15 · comparison table',
        asset: 'assets/topics/pb_cpr_summary.yaml',
        tags: ['cpr', 'resuscitation'],
      ),
      BookTopic(
        id: 'pb_weight_estimation',
        title: 'Paediatric Weight Estimation',
        subtitle: 'p.16 · age/height → weight',
        asset: 'assets/topics/pb_weight_estimation.yaml',
        tags: ['weight', 'pediatric', 'dosing'],
      ),
      BookTopic(
        id: 'pb_vital_rates',
        title: 'Vital Rates — Percentiles by Age',
        subtitle: 'p.17 · RR and HR tables',
        asset: 'assets/topics/pb_vital_rates.yaml',
        tags: ['vitals', 'respiratory rate', 'heart rate', 'pediatric'],
      ),
      BookTopic(
        id: 'pb_bp_girls',
        title: 'Girls — BP for Stature',
        subtitle: 'p.18 · tap-to-zoom chart',
        asset: 'assets/topics/pb_bp_girls.yaml',
        tags: ['blood pressure', 'bp', 'pediatric', 'girls'],
      ),
      BookTopic(
        id: 'pb_bp_boys',
        title: 'Boys — BP for Stature',
        subtitle: 'p.19 · tap-to-zoom chart',
        asset: 'assets/topics/pb_bp_boys.yaml',
        tags: ['blood pressure', 'bp', 'pediatric', 'boys'],
      ),
      BookTopic(
        id: 'pb_resuscitation_meds',
        title: 'Resuscitation Medications',
        subtitle: 'p.20 · pediatric & adult dosing',
        asset: 'assets/topics/pb_resuscitation_meds.yaml',
        tags: ['medications', 'resuscitation', 'dosing'],
      ),
      BookTopic(
        id: 'pb_io_line',
        title: 'Intra-osseous Line Placement',
        subtitle: 'p.21 · technique + illustration',
        asset: 'assets/topics/pb_io_line.yaml',
        tags: ['io', 'procedure', 'vascular access', 'shock'],
      ),
      BookTopic(
        id: 'pb_malaria',
        title: 'Malaria',
        subtitle: 'p.22 · diagnosis + severe Rx',
        asset: 'assets/topics/pb_malaria.yaml',
        tags: ['malaria', 'infectious', 'tropical', 'artesunate'],
      ),
      BookTopic(
        id: 'pb_malaria_complications',
        title: 'Malaria — Complications & Co-infection',
        subtitle: 'p.23 · AKI, anemia, Rx failure',
        asset: 'assets/topics/pb_malaria_complications.yaml',
        tags: ['malaria', 'complications', 'co-infection', 'aki', 'anemia'],
      ),
      BookTopic(
        id: 'pb_malaria_severe_meds',
        title: 'Malaria — Severe Rx',
        subtitle: 'p.23 · parenteral ladder (inpatient)',
        asset: 'assets/topics/pb_malaria_severe_meds.yaml',
        tags: ['malaria', 'severe', 'artesunate', 'artemether', 'quinine', 'parenteral'],
      ),
      BookTopic(
        id: 'pb_malaria_uncomplicated',
        title: 'Malaria — Uncomplicated Rx',
        subtitle: 'p.24 · PO regimens (outpatient)',
        asset: 'assets/topics/pb_malaria_uncomplicated.yaml',
        tags: ['malaria', 'uncomplicated', 'coartem', 'outpatient', 'dosing'],
      ),
      BookTopic(
        id: 'pb_meningitis',
        title: 'Paediatric Meningitis Rx > 1 month',
        subtitle: 'p.55 · cascade flowchart',
        asset: 'assets/topics/pb_meningitis.yaml',
        tags: ['meningitis', 'pediatric', 'antibiotics'],
      ),
    ],
  ),
  Book(
    id: 'wvems',
    title: 'WVEMS Protocols',
    subtitle: '2026 Edition · Prehospital',
    coverAsset: 'assets/covers/wvems.png',
    spineColor: Color(0xFF1E4E8C),
    topics: [
      BookTopic(
        id: 'wvems_2025_008',
        title: 'Circulation / Shock',
        subtitle: '2025-008 · severity flowchart',
        asset: 'assets/topics/wvems_2025_008.yaml',
        tags: ['shock', 'circulation', 'prehospital'],
      ),
      BookTopic(
        id: 'wvems_2026_016',
        title: 'Fever',
        subtitle: '2026-016 · Tylenol / Ibuprofen',
        asset: 'assets/topics/wvems_2026_016.yaml',
        tags: ['fever', 'tylenol', 'ibuprofen', 'sepsis', 'infection'],
      ),
      BookTopic(
        id: 'wvems_2026_020',
        title: 'Pain',
        subtitle: '2026-020 · analgesia ladder',
        asset: 'assets/topics/wvems_2026_020.yaml',
        tags: ['pain', 'analgesia', 'fentanyl', 'ketamine'],
      ),
      BookTopic(
        id: 'wvems_2026_022',
        title: 'Nausea / Vomiting',
        subtitle: '2026-022 · Zofran',
        asset: 'assets/topics/wvems_2026_022.yaml',
        tags: ['nausea', 'vomiting', 'emesis', 'zofran', 'ondansetron'],
      ),
      BookTopic(
        id: 'wvems_2026_042',
        title: 'Seizure',
        subtitle: '2026-042 · Versed / Keppra / Mag',
        asset: 'assets/topics/wvems_2026_042.yaml',
        tags: ['seizure', 'epilepsy', 'convulsion', 'versed', 'midazolam', 'keppra'],
      ),
      BookTopic(
        id: 'wvems_drug_ref_a',
        title: 'Drug Reference: A',
        subtitle: 'p.120 · drug cards',
        asset: 'assets/topics/wvems_drug_ref_a.yaml',
        tags: ['drugs', 'medications', 'reference'],
      ),
    ],
  ),
  Book(
    id: 'who_imci',
    title: 'Hospital Care for Children',
    subtitle: 'WHO · IMCI 2nd ed.',
    coverAsset: 'assets/covers/who.png',
    spineColor: Color(0xFF1565C0),
    topics: [
      BookTopic(
        id: 'who_triage_chart2',
        title: 'Triage of All Sick Children',
        subtitle: 'IMCI Chart 2 · severity table',
        asset: 'assets/topics/who_triage_chart2.yaml',
        tags: ['triage', 'imci', 'pediatric'],
      ),
    ],
  ),
  Book(
    id: 'pocket_medicine',
    title: 'Pocket Medicine',
    subtitle: 'Sabatine · MGH Handbook',
    coverAsset: 'assets/covers/pocket_medicine.jpg',
    spineColor: Color(0xFF6A1B9A),
    topics: [],
  ),
  Book(
    id: 'demos',
    title: 'Block Demos',
    subtitle: 'Schema smoke tests',
    coverAsset: '',
    spineColor: Color(0xFF546E7A),
    topics: [
      BookTopic(
        id: 'demo_all_blocks',
        title: 'All Block Types Demo',
        subtitle: 'Every block type',
        asset: 'assets/topics/demo_all_blocks.yaml',
        tags: ['demo', 'test'],
      ),
    ],
  ),
];

Book? findBook(String id) {
  for (final b in library) {
    if (b.id == id) return b;
  }
  return null;
}

BookTopic? findTopic(Book book, String topicId) {
  for (final t in book.topics) {
    if (t.id == topicId) return t;
  }
  return null;
}
