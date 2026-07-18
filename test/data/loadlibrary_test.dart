import 'package:flutter_test/flutter_test.dart';
import 'package:orbweaver/data/library.dart';

/// End-to-end load test: exercises the REAL `loadLibrary()` path (rootBundle
/// asset loading + `_loadTopicRow` + tree flattening) that the structural
/// `library_test.dart` (raw-YAML parsing) never touches. Guards against a
/// topic silently dropping out of a book's loaded tree.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('loadLibrary: protocolbook loads all 69 topics incl. TB Diagnosis',
      () async {
    final books = await loadLibrary();
    final pb = books.firstWhere((b) => b.id == 'protocolbook');
    final titles = pb.allTopics.map((t) => t.title).toList();
    expect(titles, hasLength(69));
    expect(
      titles,
      contains('Hydrocarbon Ingestion (Kerosene, Paraffin)'),
    );
    expect(
      titles,
      contains('Benzodiazepine / Opioid Ingestion'),
    );
    expect(
      titles,
      contains('Paracetamol / Acetaminophen Toxicity'),
    );
    expect(
      titles,
      contains('Alcohol Intoxication'),
    );
    expect(
      titles,
      contains('Alcohol Withdrawal'),
    );
    expect(
      titles,
      contains('CIWA-Ar Scale'),
    );
    expect(
      titles,
      contains('Anaphylaxis'),
    );
    expect(
      titles,
      contains('Animal Bite'),
    );
    expect(
      titles,
      contains('Suspected Snake Bite'),
    );
    expect(
      titles,
      contains('Paediatric Convulsions'),
    );
    expect(
      titles,
      contains('Paediatric Dehydration Protocol'),
    );
    expect(
      titles,
      contains('Paediatric Sepsis & Septic Shock'),
    );
    expect(
      titles,
      contains('Paediatric Pneumonia (2–59 months)'),
    );
    expect(
      titles,
      contains('Paediatric Hyperglycemia & DKA'),
    );
    expect(
      titles,
      contains('Urinary Tract & Kidney Disorders'),
    );
    expect(
      titles,
      contains('Wheezing Child (Bronchiolitis & Asthma)'),
    );
    expect(
      titles,
      contains('Pediatric Heart Failure'),
    );
    expect(
      titles,
      contains('Acute Rheumatic Fever (ARF)'),
    );
    expect(
      titles,
      contains('Sickle Cell Disease'),
    );
    expect(
      titles,
      contains('Sickle Cell Acute Management'),
    );
    expect(
      titles,
      contains('Sickle Cell Stroke'),
    );
    expect(
      titles,
      contains('Sickle Cell Acute Chest Syndrome'),
    );
    expect(
      titles,
      contains('SAM — Assessment & Classification'),
    );
    expect(
      titles,
      contains('SAM — Admission & Acute Complications'),
    );
    expect(
      titles,
      contains('SAM — Feeding (F-75 / RUTF / F-100)'),
    );
    expect(
      titles,
      contains('Epistaxis (Nosebleed)'),
    );
    expect(
      titles,
      contains('Otitis Media'),
    );
    expect(
      titles,
      contains('Otitis Externa'),
    );
    expect(
      titles,
      contains('Mastoiditis'),
    );
    expect(
      titles,
      contains('Pharyngitis'),
    );
    expect(
      titles,
      contains('Sinusitis'),
    );
    expect(
      titles,
      contains('TB — Diagnosis & Systemic Score'),
    );
    expect(
      titles,
      contains('TB — Pulmonary Scoring Systems'),
    );
    expect(
      titles,
      contains('TB — Treatment'),
    );
    expect(
      titles,
      contains('Anaemia — Approach & Transfusion Thresholds'),
    );
    expect(
      titles,
      contains('Anaemia — Evaluate the Cause'),
    );
    expect(
      titles,
      contains('Transfusions'),
    );
    expect(
      titles,
      contains('Pain — Neonatal (NIPS)'),
    );
    expect(
      titles,
      contains('Pain — r-FLACC (2 mo – 7 yr)'),
    );
    expect(
      titles,
      contains('Pain — Faces & Jerry-Can Scales'),
    );
    expect(
      titles,
      contains('Pain — Numeric Scale & WHO Analgesic Ladder'),
    );
    expect(
      titles,
      contains('Newborn Feeding & Fluid Requirements'),
    );
    expect(
      titles,
      contains('Neonatal CPAP'),
    );
    expect(
      titles,
      contains('Early-Onset Neonatal Sepsis — Risk & Prevention'),
    );
    expect(
      titles,
      contains('Neonatal Sepsis — Treatment'),
    );
    expect(
      titles,
      contains('Neonatal Jaundice'),
    );
    expect(
      titles,
      contains('Ballard Score (Gestational Age)'),
    );
    expect(
      titles,
      contains('Adult Heart Failure'),
    );
    expect(
      titles,
      contains('TIA / Stroke'),
    );
    expect(
      titles,
      contains('Adult Sepsis'),
    );
    expect(
      titles,
      contains('Adult Convulsions'),
    );
  });
}
