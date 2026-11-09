import 'dart:io';
import 'package:cql/cql.dart';
import 'package:cql/src/internal.dart';
import 'package:fhir_r4_cql/fhir_r4_cql.dart';

const evalTime = '2026-11-09T10:00:00Z';

Map<String, dynamic> obs(
  String id,
  String system,
  String code,
  num value,
  String unit,
  String when, {
  String? encounter,
}) =>
    {
      'resourceType': 'Observation',
      'id': id,
      'status': 'final',
      'code': {
        'coding': [
          {'system': system, 'code': code},
        ],
      },
      'subject': {'reference': 'Patient/p'},
      if (encounter != null) 'encounter': {'reference': 'Encounter/$encounter'},
      'effectiveDateTime': when,
      'valueQuantity': {
        'value': value,
        'unit': unit,
        'system': 'http://unitsofmeasure.org',
        'code': unit,
      },
    };

Map<String, dynamic> caseCtx(
  String birth,
  num kg,
  List<List<dynamic>> seizures,
) {
  final o = <dynamic>[
    obs('w', 'http://loinc.org', '29463-7', kg, 'kg', '2026-11-09T09:00:00Z'),
    for (var i = 0; i < seizures.length; i++)
      obs(
        's$i',
        'http://snomed.info/sct',
        '313289001',
        seizures[i][0] as num,
        'min',
        seizures[i][1] as String,
        encounter: 'e1',
      ),
  ];
  return {
    'Patient': {'resourceType': 'Patient', 'id': 'p', 'birthDate': birth},
    'Observation': o,
    'Encounter': {
      'resourceType': 'Encounter',
      'id': 'e1',
      'status': 'in-progress',
      'class': {
        'system': 'http://terminology.hl7.org/CodeSystem/v3-ActCode',
        'code': 'EMER',
      },
    },
    'startTimestamp': CqlDateTime.fromString(evalTime),
  };
}

Future<void> main(List<String> args) async {
  final base = args[0];
  final out = File(args[1]).openWrite();
  final lm = LibraryManager(
    sourceProvider: FileSystemLibrarySourceProvider(basePath: base),
    parseLibrary: (String s, {LibraryManager? libraryManager}) =>
        libraryFromCql(s, libraryManager: libraryManager),
  );
  final lib = libraryFromCql(
    File('$base/PaediatricConvulsions.cql').readAsStringSync(),
    libraryManager: lm,
  );
  final cases = <String, Map<String, dynamic>>{
    'A child 2y 12kg seizure 12min': caseCtx('2024-05-01', 12, [
      [12, '2026-11-09T09:59:00Z'],
    ]),
    'B child 25kg seizure 6min': caseCtx('2020-01-01', 25, [
      [6, '2026-11-09T09:59:00Z'],
    ]),
    'C 60kg seizure 16min': caseCtx('2014-01-01', 60, [
      [16, '2026-11-09T09:59:00Z'],
    ]),
    'D neonate 10d 3kg': caseCtx('2026-10-30', 3, [
      [7, '2026-11-09T09:59:00Z'],
    ]),
    'E boundary 15kg': caseCtx('2022-01-01', 15, [
      [3, '2026-11-09T09:59:00Z'],
    ]),
    'F three short seizures in 2h': caseCtx('2022-01-01', 14, [
      [3, '2026-11-09T08:30:00Z'],
      [2, '2026-11-09T09:10:00Z'],
      [4, '2026-11-09T09:50:00Z'],
    ]),
  };
  // Expected values worked by hand from the printed page (p.42) for each case.
  // Stage 1 for case F is printed as observed: a recorded 4-minute seizure counts as
  // "presents convulsing" because a duration record cannot say the seizure has ended.
  final expected = <String, Map<String, String>>{
    'A child 2y 12kg seizure 12min': {
      'Is Neonate': 'false',
      'Stage 1 Applies': 'true',
      'Still Convulsing After 10 Minutes': 'true',
      'Still Convulsing After 15 Minutes': 'false',
      'Diazepam IV Dose': "2.4 'mg'",
      'Rectal Diazepam Suppository Count': '2',
      'Dextrose 10% Volume': "24.0 'mL'",
      'Phenobarbital Load Dose': "240.0 'mg'",
      'Phenobarbital Maintenance Dose Low': "36.0 'mg'",
      'Phenobarbital Maintenance Dose High': "60.0 'mg'",
    },
    'B child 25kg seizure 6min': {
      'Still Convulsing After 10 Minutes': 'false',
      'Diazepam IV Dose': "5.0 'mg'",
      'Rectal Diazepam Suppository Count': '4',
    },
    'C 60kg seizure 16min': {
      'Still Convulsing After 15 Minutes': 'true',
      'Diazepam IV Dose': "10.0 'mg'",
      'Rectal Diazepam Suppository Count': 'null',
    },
    'D neonate 10d 3kg': {
      'Is Neonate': 'true',
      'Stage 1 Applies': 'false',
      'Phenobarbital Load Dose': "60.0 'mg'",
      'Phenobarbital Repeat Dose': "30.0 'mg'",
      'Rectal Diazepam Suppository Count': '1',
    },
    'E boundary 15kg': {'Rectal Diazepam Suppository Count': '3'},
    'F three short seizures in 2h': {
      'Third Short Seizure In 2 Hours': 'true',
      'Stage 1 Applies': 'true',
    },
  };
  var failures = 0;
  for (final e in cases.entries) {
    out.writeln('== ${e.key}');
    try {
      final r = await lib.execute(e.value, const R4ModelResolver())
          as Map<String, dynamic>;
      for (final k in r.keys) {
        if (k == 'Patient' ||
            k.startsWith('Latest') ||
            k.startsWith('Seizure Durations') ||
            k.startsWith('Short Seizures') ||
            k == 'Current Seizure' ||
            !k.contains(RegExp('[A-Z]')) ||
            r[k] is Map ||
            r[k] is List ||
            r[k] is CqlLibrary) {
          continue;
        }
        out.writeln('  $k = ${r[k]}');
      }
      for (final x in (expected[e.key] ?? {}).entries) {
        final got = '${r[x.key]}';
        if (got != x.value) {
          failures++;
          out.writeln('  FAIL ${x.key}: expected ${x.value}, got $got');
        }
      }
    } catch (err, st) {
      failures++;
      out.writeln('  ERROR $err');
      out.writeln(st.toString().split('\n').take(12).join('\n'));
    }
    await out.flush();
  }
  out.writeln('failures: $failures');
  await out.close();
  if (failures > 0) exit(1);
}
