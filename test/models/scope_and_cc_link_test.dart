// Two fields the census of all 467 bundled topics found the parser dropping
// silently (2026-09-06): a `P(CC)` procedure scope fell to the all-level grey
// chip, and a prose block's `critical_care_link` was never read at all.
import 'package:flutter_test/flutter_test.dart';
import 'package:orbweaver/models/topic.dart';

void main() {
  test('procedure_card scope accepts the Critical Care spellings', () {
    for (final s in ['P(CC)', 'p(cc)', 'CC', 'cc']) {
      final b = ProcedureBlock.fromYaml({
        'type': 'procedure_card',
        'name': 'Cric',
        'scope': s,
      });
      expect(b.scope, 'P(CC)', reason: s);
      expect(ProviderLevel.fromString(b.scope), ProviderLevel.criticalCare);
    }
    expect(
      ProcedureBlock.fromYaml({
        'type': 'procedure_card',
        'name': 'x',
        'scope': 'e',
      }).scope,
      'E',
    );
    expect(
      ProcedureBlock.fromYaml({
        'type': 'procedure_card',
        'name': 'x',
        'scope': 'Q',
      }).scope,
      isNull,
    );
  });

  test('prose reads critical_care_link', () {
    final b = ProseBlock.fromYaml({
      'type': 'prose',
      'markdown': '- Transport emergently',
      'critical_care_link': {'text': '[Elevated ICP](topic:wvems-2026-086)'},
    });
    expect(b.criticalCareLink?.text, '[Elevated ICP](topic:wvems-2026-086)');
    expect(b.criticalCareLink?.linkId, isNull);
    expect(
      ProseBlock.fromYaml({'type': 'prose', 'markdown': 'x'}).criticalCareLink,
      isNull,
    );
  });
}
