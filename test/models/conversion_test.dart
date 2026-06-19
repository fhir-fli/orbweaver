import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:orbweaver/models/topic.dart';

ConversionBlock _load(String topicFile) {
  final yaml =
      File('assets/books/conversions/topics/$topicFile').readAsStringSync();
  return Topic.fromYamlString(yaml).blocks.whereType<ConversionBlock>().single;
}

void main() {
  group('Opioid converter (equivalence)', () {
    late ConversionBlock b;
    setUpAll(() => b = _load('conv_opioids.yaml'));

    ConversionAgent agent(String name, String? route) {
      final a = b.agentFor(name, route);
      expect(a, isNotNull, reason: '$name/$route should exist');
      return a!;
    }

    test('mode, reference, source are set', () {
      expect(b.mode, ConversionMode.equivalence);
      expect(b.reference, 'oral morphine');
      expect(b.referenceLabel, 'MME');
      expect(b.source, isNotNull);
    });

    test('reference identity: oral morphine factor 1.0', () {
      final m = agent('Morphine', 'PO');
      expect(m.factor, 1.0);
      expect(b.toReference(m, 30), 30); // MME == dose
    });

    test('golden MME pairs', () {
      // oxycodone 20 mg PO → 30 MME
      expect(b.toReference(agent('Oxycodone', 'PO'), 20), closeTo(30, 1e-9));
      // hydromorphone 4 mg PO → 20 MME (CDC factor 5.0)
      expect(b.toReference(agent('Hydromorphone', 'PO'), 4), closeTo(20, 1e-9));
      // tramadol 100 mg PO → 20 MME (CDC factor 0.2)
      expect(b.toReference(agent('Tramadol', 'PO'), 100), closeTo(20, 1e-9));
      // morphine 10 mg IV/SC → 30 MME
      expect(b.toReference(agent('Morphine', 'IV/SC'), 10), closeTo(30, 1e-9));
      // codeine 200 mg PO → 30 MME
      expect(b.toReference(agent('Codeine', 'PO'), 200), closeTo(30, 1e-9));
    });

    test('direct A→reference→B conversion', () {
      // oxycodone 30 mg PO → MME → oral morphine
      final mme = b.toReference(agent('Oxycodone', 'PO'), 30)!; // 45
      expect(b.fromReference(agent('Morphine', 'PO'), mme), closeTo(45, 1e-9));
      // …→ hydromorphone PO (÷5)
      expect(
        b.fromReference(agent('Hydromorphone', 'PO'), mme),
        closeTo(9, 1e-9),
      );
    });

    test('round-trip A→ref→B→ref→A returns the original', () {
      final oxy = agent('Oxycodone', 'PO');
      final hydro = agent('Hydromorphone', 'PO');
      final mme1 = b.toReference(oxy, 20)!;
      final hydroDose = b.fromReference(hydro, mme1)!;
      final mme2 = b.toReference(hydro, hydroDose)!;
      expect(b.fromReference(oxy, mme2), closeTo(20, 1e-9));
    });

    test('route variants apply distinct factors', () {
      expect(agent('Morphine', 'PO').factor, 1.0);
      expect(agent('Morphine', 'IV/SC').factor, 3.0);
      expect(agent('Hydromorphone', 'PO').factor, 5.0);
      expect(agent('Hydromorphone', 'IV').factor, 20.0);
    });

    test('dangerous agents are excluded, not convertible', () {
      final excludedNames = b.excluded.map((e) => e.name).toList();
      expect(excludedNames, contains('Methadone'));
      expect(
        excludedNames.any((n) => n.contains('Fentanyl')),
        isTrue,
      );
      expect(excludedNames, contains('Buprenorphine'));
      // and they are NOT selectable agents
      expect(b.agentNames, isNot(contains('Methadone')));
    });

    test('every agent has a positive factor', () {
      for (final a in b.agents) {
        expect(a.factor, isNotNull, reason: '${a.name} needs a factor');
        expect(a.factor! > 0, isTrue);
      }
    });
  });

  group('Benzodiazepine converter (equivalence)', () {
    late ConversionBlock b;
    setUpAll(() => b = _load('conv_benzodiazepines.yaml'));

    ConversionAgent agent(String name) => b.agentFor(name, null)!;

    test('golden diazepam-equivalent pairs', () {
      // lorazepam 1 mg ≈ diazepam 10 mg
      final eq = b.toReference(agent('Lorazepam'), 1)!;
      expect(eq, closeTo(10, 1e-9));
      expect(b.fromReference(agent('Diazepam'), eq), closeTo(10, 1e-9));
      // alprazolam 0.5 mg ≈ diazepam 10 mg
      expect(b.toReference(agent('Alprazolam'), 0.5), closeTo(10, 1e-9));
      // clonazepam 0.5 mg ≈ diazepam 10 mg
      expect(b.toReference(agent('Clonazepam'), 0.5), closeTo(10, 1e-9));
    });

    test('reference identity: diazepam factor 1.0', () {
      expect(agent('Diazepam').factor, 1.0);
    });

    test('oxazepam corrected to 0.5 (20 mg ≈ 10 mg diazepam)', () {
      expect(agent('Oxazepam').factor, 0.5);
      expect(b.toReference(agent('Oxazepam'), 20), closeTo(10, 1e-9));
    });

    test('midazolam is excluded', () {
      expect(b.excluded.map((e) => e.name), contains('Midazolam'));
    });
  });

  group('Statin matrix (tiers)', () {
    late ConversionBlock b;
    setUpAll(() => b = _load('conv_statins.yaml'));

    test('mode + tiers declared', () {
      expect(b.mode, ConversionMode.tiers);
      expect(b.tiers, ['Low', 'Moderate', 'High']);
      expect(b.source, isNotNull);
    });

    test('every dose references a declared tier', () {
      for (final a in b.agents) {
        for (final d in a.doses) {
          expect(b.tiers, contains(d.tier),
              reason: '${a.name} ${d.dose} tier "${d.tier}" not declared');
        }
      }
    });

    test('tier equivalence: High-intensity doses across agents', () {
      List<String> highDoses(String name) => [
            for (final a in b.agents)
              if (a.name == name)
                for (final d in a.doses)
                  if (d.tier == 'High') d.dose,
          ];
      expect(highDoses('Atorvastatin'), ['40 mg', '80 mg']);
      expect(highDoses('Rosuvastatin'), ['20 mg', '40 mg']);
      // Simvastatin has no High-intensity dose.
      expect(highDoses('Simvastatin'), isEmpty);
    });

    test('pitavastatin 1 mg corrected to Moderate (no Low pitavastatin)', () {
      final pitavastatin =
          b.agents.firstWhere((a) => a.name == 'Pitavastatin');
      expect(pitavastatin.doses.any((d) => d.tier == 'Low'), isFalse);
      expect(
        pitavastatin.doses.firstWhere((d) => d.dose == '1 mg').tier,
        'Moderate',
      );
    });

    test('agents have no equivalence factors (tiers mode)', () {
      for (final a in b.agents) {
        expect(a.factor, isNull);
        expect(a.doses, isNotEmpty);
      }
    });
  });
}
