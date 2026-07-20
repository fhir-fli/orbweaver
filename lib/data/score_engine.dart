// score_engine.dart
//
// The compute half of the `score` block. Pure Dart — NO Flutter — so scoring
// is unit-testable in isolation with golden vectors.
//
// Unlike `formula` (real math per kind), a clinical SCORE is a weighted sum of
// selected criteria plus a threshold-band lookup, so it is fully declarative:
// the points and bands live in the topic YAML and this engine sums + resolves
// them. Correctness testing therefore checks that the ENCODED points/bands
// match the published score (golden selection → total → band vectors), plus
// that the declared bands cover the whole achievable range (no gaps).

import 'package:orbweaver/models/topic.dart';

class ScoreResult {
  const ScoreResult(this.total, this.band);
  final num total;
  final ScoreBand? band;
}

/// Sums the points of the current selections and resolves the interpretation
/// band. [selections] maps `item.key` → `true` (toggle on) or an option
/// `value` (choice). A toggle that's off / absent, or a choice with no matching
/// option, contributes nothing.
ScoreResult computeScore(ScoreBlock block, Map<String, dynamic> selections) {
  num total = 0;
  for (final item in block.items) {
    switch (item.type) {
      case ScoreItemType.toggle:
        if (selections[item.key] == true) total += item.points;
      case ScoreItemType.choice:
        final v = selections[item.key];
        for (final o in item.options) {
          if (o.value == v) {
            total += o.points;
            break;
          }
        }
    }
  }
  return ScoreResult(total, bandFor(block, total));
}

/// The first band whose interval contains [total] (null = no band covers it).
ScoreBand? bandFor(ScoreBlock block, num total) {
  for (final b in block.bands) {
    final max = b.max;
    if (total >= b.min && (max == null || total <= max)) return b;
  }
  return null;
}

/// Every total reachable from the declared items (each toggle on/off, each
/// choice one option). Lets tests prove the bands cover ALL reachable scores —
/// robust to negative and half-point scores where simple min/max contiguity
/// checks would false-positive.
Set<num> reachableTotals(ScoreBlock block) {
  var totals = <num>{0};
  for (final item in block.items) {
    final contribs = item.type == ScoreItemType.toggle
        ? <num>[0, item.points]
        : (item.options.isEmpty
            ? <num>[0]
            : item.options.map((o) => o.points).toList());
    final next = <num>{};
    for (final t in totals) {
      for (final c in contribs) {
        next.add(t + c);
      }
    }
    totals = next;
  }
  return totals;
}

/// The minimum and maximum totals reachable from the declared items — assuming
/// each choice item always has one option selected (its default). Used by tests
/// to prove the bands cover the whole range with no gaps.
({num min, num max}) scoreRange(ScoreBlock block) {
  num lo = 0;
  num hi = 0;
  for (final item in block.items) {
    if (item.type == ScoreItemType.toggle) {
      // off contributes 0; a negative-point toggle can only lower the total.
      if (item.points < 0) {
        lo += item.points;
      } else {
        hi += item.points;
      }
    } else {
      final pts = item.options.map((o) => o.points);
      lo += pts.reduce((a, b) => a < b ? a : b);
      hi += pts.reduce((a, b) => a > b ? a : b);
    }
  }
  return (min: lo, max: hi);
}
