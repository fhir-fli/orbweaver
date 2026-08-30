// GUARD — a formulary dose that appears on NO page prescribing that drug.
//
// Five times a dose was corrected on the protocol page and the formulary entry
// for the same drug was left behind: meropenem and vancomycin kept the generic
// dose under a CNS indication; phenobarbital kept a 15 mg/kg loading dose in
// both books while every page moved to 20, along with a 320 mg cap that
// underdosed anyone over about 16 kg; lidocaine kept "4-5 mg/kg" while the page
// carried 4.5 plain and 7 with epinephrine.
//
// The formulary is read WITHOUT the page around it. That is what makes this
// dangerous rather than untidy: the reader looking a drug up gets the stale
// number and nothing tells them a protocol page says otherwise.
//
// The check lives in tool/formulary_page_parity.py because it reuses the dose
// extractor. Hundreds of formulary doses legitimately have no page — the
// formulary covers indications the topics never mention — so the check
// compares against a committed baseline and fails only on NEW ones.
//
// When this fails, do NOT reach for --bless first. Ask which of these it is:
//   1. a page dose changed and the formulary was not changed with it. Fix the
//      formulary. This is the bug the guard exists for.
//   2. a formulary dose changed and no page carries it. Fix whichever is wrong.
//   3. a genuinely new formulary entry for an indication no page covers. Then
//      run `python3 tool/formulary_page_parity.py --bless` and say why in the
//      commit message.
//
// Proven to fail before it was trusted: reintroducing the phenobarbital defect
// (loading 20 -> 25 mg/kg in the WHO formulary) produces
// "NEW ORPHAN WHO phenobarbital mg/kg 25" and exit 1.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('no formulary dose is stranded with no page prescribing it', () {
    final script = File('tool/formulary_page_parity.py');
    expect(script.existsSync(), isTrue,
        reason: 'tool/formulary_page_parity.py is missing');

    final probe = Process.runSync('python3', <String>['--version']);
    if (probe.exitCode != 0) {
      markTestSkipped('python3 not available; run the guard by hand: '
          'python3 tool/formulary_page_parity.py --extract');
      return;
    }

    // --extract re-reads the books, so the guard cannot pass on a stale
    // doses.tsv left over from an earlier run.
    final r = Process.runSync(
        'python3', <String>['tool/formulary_page_parity.py', '--extract']);
    expect(r.exitCode, 0,
        reason: '\n${r.stdout}${r.stderr}\n'
            'A formulary dose appears on no page prescribing that drug.\n'
            'If a page dose changed, change the formulary entry in the same '
            'commit. Read the header of this test before blessing anything.');
  }, timeout: const Timeout(Duration(minutes: 3)));
}
