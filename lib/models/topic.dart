// topic.dart
//
// Core model classes for the clinical quick-reference topic schema.
//
// A Topic is a vertical stack of Blocks. Each Block is one of five types:
//   prose       — markdown text (headings, bullets, emphasis)
//   table       — structured table (stub for now)
//   flowchart   — severity-branching or cascade variant
//   drug_card   — canonical drug reference card (stub for now)
//   image       — bitmap/vector asset with optional caption (stub for now)

import 'package:orbweaver/data/formula_registry.dart' show FormulaSeverity;
import 'package:yaml/yaml.dart';

// ─────────────────────────────────────────────────────────────
// ENUMS
// ─────────────────────────────────────────────────────────────

enum TopicCategory {
  universal,
  medical,
  trauma,
  criticalCare;

  static TopicCategory fromString(String? s) => switch (s) {
    'universal' => universal,
    'medical' => medical,
    'trauma' => trauma,
    'critical_care' => criticalCare,
    _ => universal,
  };
}

enum NodeShape {
  stadium,
  diamond,
  rectangle,
  roundedRectangle;

  static NodeShape fromString(String? s) => switch (s) {
    'stadium' => stadium,
    'diamond' => diamond,
    'rectangle' => rectangle,
    'rounded_rectangle' => roundedRectangle,
    _ => rectangle,
  };
}

enum ActionKind {
  procedure,
  medicationAdministration,
  diagnostic,
  assessment,
  referral,
  communication;

  static ActionKind fromString(String? s) => switch (s) {
    'procedure' => procedure,
    'medication_administration' => medicationAdministration,
    'diagnostic' => diagnostic,
    'assessment' => assessment,
    'referral' => referral,
    'communication' => communication,
    _ => procedure,
  };
}

/// WVEMS credentialing strip. The letter on a badge is the *minimum* level
/// cleared for that intervention — p.3: "You may use any intervention marked
/// for your level or lower."
///
/// [aemt] is the print's `A`. It reads as ALS to most ears but the book files
/// AEMT under **BLS**, so the enum is named for the credential, not the tier.
///
/// [paramedic] and [criticalCare] both draw a `P`; the print separates them by
/// fill. Plain paramedic is flat pink and appears exactly once in 166 pages
/// (the p.2 legend); all 29 body `P` badges are Critical Care, which the print
/// gives a purple gradient. Critical Care is a credential *on top of*
/// paramedic — p.3: "Critical Care (CC) is for credentialed paramedics only."
enum ProviderLevel {
  aemt,
  emt,
  intermediate,
  paramedic,
  criticalCare,
  any;

  static ProviderLevel fromString(String? s) => switch (s) {
    'A' => aemt,
    'E' => emt,
    'I' => intermediate,
    'P' => paramedic,
    'P(CC)' || 'CC' => criticalCare,
    _ => any,
  };

  /// The character printed inside the badge. Blank for [any] — the print's
  /// empty pale-grey band, which means EMR (every level).
  String get letter => switch (this) {
    emt => 'E',
    aemt => 'A',
    intermediate => 'I',
    paramedic || criticalCare => 'P',
    any => '',
  };
}

enum DosePopulation {
  adult,
  peds,
  both;

  static DosePopulation fromString(String? s) => switch (s) {
    'adult' => adult,
    'peds' => peds,
    'both' => both,
    _ => both,
  };
}

/// WHO IMCI-style row severity coloring for table rows.
enum RowSeverity {
  none,
  emergency, // pink — immediate treatment
  priority, // yellow — urgent assessment
  nonUrgent; // green — routine

  static RowSeverity fromString(String? s) => switch (s) {
    'emergency' => emergency,
    'priority' => priority,
    'non_urgent' => nonUrgent,
    _ => none,
  };
}

/// Size hint for image blocks. The renderer picks a concrete width.
enum ImageSize {
  small,
  medium,
  large,
  full;

  static ImageSize fromString(String? s) => switch (s) {
    'small' => small,
    'medium' => medium,
    'large' => large,
    'full' => full,
    _ => medium,
  };
}

/// Which answer (yes or no) in a cascade step leads to the terminal action.
/// The opposite answer leads to the next step.
enum YesNo {
  yes,
  no;

  static YesNo fromString(String? s) => switch (s) {
    'yes' => yes,
    'no' => no,
    _ => yes,
  };

  YesNo get opposite => this == yes ? no : yes;

  String get label => switch (this) {
    yes => 'Yes',
    no => 'No',
  };
}

enum FlowchartVariant {
  /// WVEMS-style: entry → decision → parallel branches → convergence.
  /// Branches are semantically flexible (severity, role, drug choice,
  /// binary present/absent). Same shape for all.
  severity,

  /// Linear Yes/No chain. Each step has decision + yes_action +
  /// no_continuation. Terminates when an action has no continuation.
  cascade,

  /// Single-column sequence with no decision and no branches — used by
  /// WVEMS protocols whose flow is just `entry → step → step → … →
  /// Consider` (e.g. Sting/Bite, Inhalation, Stroke). Steps are either
  /// content boxes (a titled white box with bullets — same look as a
  /// branch criteria box) or action tiles (the same `ActionTile` used by
  /// severity branches). Warnings, entry-chain, convergence,
  /// post-convergence and dose-table all work the same as severity.
  linear,

  /// Decision-into-card-grid pattern: an entry chain leads into a
  /// decision diamond (e.g. "Location?", "Cause?"), then a grid of
  /// referential cards (each a title with descriptive bullets — same
  /// box style as a branch criteria box).  The user reads the card that
  /// matches the patient's situation; there are no action tiles per
  /// card.  Used by Head Injury (062), Trunk Injury (064),
  /// Abdominal Pain (034), and Altered LOC (036).  Warnings,
  /// entry_chain, convergence, post_convergence and dose_table all
  /// work the same as severity.
  differential,

  /// Vertical multi-decision algorithm: a top-to-bottom spine of
  /// decision "stages", each a decision (prompt + optional criteria)
  /// with 2+ labelled outcomes. Each outcome either ends in a
  /// disposition box (a severity-tinted leaf), continues down the
  /// spine to the next stage, or `goto`s a named shared box (e.g. a
  /// shared "Treatment" box). Loop-backs render as a labelled
  /// reference to a named box, NOT a drawn backward arrow — so a
  /// genuinely branching clinical algorithm lays out cleanly as one
  /// connected vertical flow with no 2-D graph engine. Used by the
  /// ProtocolBook's complex algorithms (e.g. Hydrocarbon p.30).
  algorithm,

  /// Cyclic clinical algorithm: a vertical spine of nodes where an edge can
  /// target a node by `id`. A target BELOW flows normally; a target ABOVE
  /// renders as a labelled return arrow routed up the outer margin (a
  /// back-edge). Covers the reducible loop taxonomy — reassessment
  /// self-loops (CIWA-Ar), titration, resuscitation cycles (ACLS),
  /// escalation-with-recheck — from pure YAML. See [CycleFlowchart].
  cycle;

  static FlowchartVariant fromString(String? s) => switch (s) {
    'severity' => severity,
    'cascade' => cascade,
    'linear' => linear,
    'differential' => differential,
    'algorithm' => algorithm,
    'cycle' => cycle,
    _ => severity,
  };
}

// ─────────────────────────────────────────────────────────────
// FLOWCHART SUB-MODELS
// ─────────────────────────────────────────────────────────────

/// A single action within a branch or cascade step.
///
/// [timing] and [condition] are optional annotations that let a practitioner
/// reference express cyclic/conditional semantics without a separate
/// flowchart variant (e.g. "Epi — Q 5 min", "Amio — If VT/VF").
class TopicAction {
  const TopicAction({
    required this.text,
    this.kind = ActionKind.procedure,
    this.providerLevel = ProviderLevel.any,
    this.timing,
    this.condition,
    this.pedsOnly = false,
  });

  factory TopicAction.fromYaml(Map<dynamic, dynamic> map) => TopicAction(
    text: map['text'] as String,
    kind: ActionKind.fromString(map['kind'] as String?),
    providerLevel: ProviderLevel.fromString(map['provider_level'] as String?),
    timing: map['timing'] as String?,
    condition: map['condition'] as String?,
    pedsOnly: (map['peds_only'] as bool?) ?? false,
  );

  final String text;
  final ActionKind kind;
  final ProviderLevel providerLevel;
  final String? timing;
  final String? condition;

  /// True when the print gives this tile its pink `Peds` side tab — a
  /// full-height band on the tile's **right** edge, the mirror of the provider
  /// badge on the left. Three tiles carry it (pp.12 and 50 Epi, p.78 Needle
  /// Cric), and p.12's carries both at once: blue `I` left, pink `Peds` right.
  final bool pedsOnly;
}

/// A single branch from the decision diamond in a severity flowchart.
///
/// [severity] tints the branch visually (WHO-IMCI palette — pink/yellow/green)
/// so branches are distinguishable at a glance without reading labels.
/// Reuses the same [RowSeverity] enum as table rows so the urgency language
/// stays consistent across block types.
///
/// [continuation] supports asymmetric branch flow — e.g. Adult Cardiac
/// Arrest p.14, where only the "No Pulse" branch extends downward into
/// additional action boxes while "Definite Pulse" terminates. When set,
/// the renderer emits continuation-node rows below the branches row, with
/// content anchored in this branch's column and empty on the other side.
class TopicBranch {
  const TopicBranch({
    required this.id,
    required this.label,
    this.criteria = const [],
    this.actions = const [],
    this.severity = RowSeverity.none,
    this.continuation,
    this.continues = false,
  });

  factory TopicBranch.fromYaml(Map<dynamic, dynamic> map) => TopicBranch(
    id: map['id'] as String,
    label: map['label'] as String,
    criteria: _stringList(map['criteria']),
    actions: _mapList(map['actions'], TopicAction.fromYaml),
    severity: RowSeverity.fromString(map['severity'] as String?),
    continuation: _mapOrNull(map['continuation'], BranchContinuation.fromYaml),
    continues: map['continues'] as bool? ?? false,
  );

  final String id;
  final String label;
  final List<String> criteria;
  final List<TopicAction> actions;
  final RowSeverity severity;
  final BranchContinuation? continuation;

  /// When true, the branch renders as label + downward arrow only —
  /// no action tiles, no continuation box.  Used when this branch
  /// flows directly into whatever block comes next in the topic
  /// (e.g. malaria Yes → the severe Rx callout below).
  final bool continues;
}

/// Additional flowchart nodes that flow downward from a specific branch
/// after its action list, used when the flowchart is asymmetric (one
/// branch continues, the other terminates).
///
/// [entryArrowLabel] optionally labels the arrow from the branch's last
/// action into the first continuation node — e.g. "Every 2 minutes" for
/// a cyclic return to the compressions step.
class BranchContinuation {
  const BranchContinuation({
    required this.nodes,
    this.entryArrowLabel,
  });

  factory BranchContinuation.fromYaml(Map<dynamic, dynamic> map) =>
      BranchContinuation(
        entryArrowLabel: map['entry_arrow_label'] as String?,
        nodes: _mapList(map['nodes'], FlowNode.fromYaml),
      );

  final String? entryArrowLabel;
  final List<FlowNode> nodes;
}

/// A linked bullet in the convergence node.
class ConvergenceBullet {
  const ConvergenceBullet({required this.text, this.linkId});

  factory ConvergenceBullet.fromYaml(Map<dynamic, dynamic> map) =>
      ConvergenceBullet(
        text: map['text'] as String,
        linkId: map['link_id'] as String?,
      );

  final String text;
  final String? linkId;
}

/// A reference to a Critical Care protocol, rendered as the WVEMS
/// lavender pill below the convergence node (e.g. Abdominal Pain →
/// "Sepsis", Head Injury → "Elevated ICP").  The PDF colours these
/// links lavender to flag that the target is a Critical Care protocol
/// (credentialed providers only), distinct from the green "Consider"
/// terminator.  Like [ConvergenceBullet.linkId], [linkId] is a visual
/// cross-reference cue — the underline signals a referenced protocol;
/// the app does not navigate on tap.
class CriticalCareLink {
  const CriticalCareLink({required this.text, this.linkId});

  factory CriticalCareLink.fromYaml(Map<dynamic, dynamic> map) =>
      CriticalCareLink(
        text: map['text'] as String,
        linkId: map['link_id'] as String?,
      );

  final String text;
  final String? linkId;
}

/// A labeled arrow leaving the convergence node.
///
/// Two shapes:
///   - Loopback: [loopbackBranchId] names a branch to return to. Rendered
///     as an inline `↻ {label} → back to <branch colour / label>` note
///     under the convergence box (a real curved-arrow render is deferred).
///   - Forward: [loopbackBranchId] is null. Rendered as a labeled downward
///     arrow leading to [SeverityFlowchart.postConvergence].
class ConvergenceExit {
  const ConvergenceExit({required this.label, this.loopbackBranchId});

  factory ConvergenceExit.fromYaml(Map<dynamic, dynamic> map) =>
      ConvergenceExit(
        label: map['label'] as String,
        loopbackBranchId: map['loopback'] as String?,
      );

  final String label;
  final String? loopbackBranchId;
}

/// The bottom convergence node where all branches reconverge.
class ConvergenceNode {
  const ConvergenceNode({
    required this.text,
    this.shape = NodeShape.roundedRectangle,
    this.bullets = const [],
    this.exits = const [],
    this.warnings = const [],
  });

  factory ConvergenceNode.fromYaml(Map<dynamic, dynamic> map) =>
      ConvergenceNode(
        text: map['text'] as String,
        shape: NodeShape.fromString(map['shape'] as String?),
        bullets: _mapList(map['bullets'], ConvergenceBullet.fromYaml),
        exits: _mapList(map['exits'], ConvergenceExit.fromYaml),
        warnings: _mapList(map['warnings'], WarningCallout.fromYaml),
      );

  final String text;
  final NodeShape shape;
  final List<ConvergenceBullet> bullets;
  final List<ConvergenceExit> exits;

  /// Side callouts that flank the convergence stadium, matching the
  /// WVEMS PDF convention: `safety` is a red octagon on the left (e.g.
  /// "Ensure Patient DECON"); `caution` is a purple trapezoid on
  /// the right (e.g. "Consider Destination Triage").  Same callout
  /// widgets the entry stadium uses for its own side warnings.  Only
  /// the first of each type is rendered.
  final List<WarningCallout> warnings;
}

/// One row in the medication dose reference table.
class DoseRow {
  const DoseRow({
    required this.drug,
    required this.dose,
    required this.route,
    required this.frequency,
    this.population = DosePopulation.both,
  });

  factory DoseRow.fromYaml(Map<dynamic, dynamic> map) => DoseRow(
    drug: map['drug'] as String,
    dose: map['dose'] as String,
    route: map['route'] as String,
    frequency: map['frequency'] as String,
    population: DosePopulation.fromString(map['population'] as String?),
  );

  final String drug;
  final String dose;
  final String route;
  final String frequency;
  final DosePopulation population;
}

/// A flowchart node (entry, decision, or convergence).
class FlowNode {
  const FlowNode({
    required this.text,
    required this.shape,
    this.bands = const [],
    this.ccTitle,
  });

  factory FlowNode.fromYaml(Map<dynamic, dynamic> map) => FlowNode(
    text: map['text'] as String,
    shape: NodeShape.fromString(map['shape'] as String?),
    bands: _mapList(map['bands'], AgeBand.fromYaml),
    ccTitle: map['cc_title'] as String?,
  );

  final String text;
  final NodeShape shape;

  /// Age-tiered thresholds, one row each, drawn as a zebra inside the node.
  ///
  /// The print sets these entry stadiums as a small table rather than as
  /// free text — a title over one striped row per age band — because the
  /// reader is looking up *their* patient's row under time pressure, not
  /// reading a sentence (pp.8, 10, 12, 14, 82, 92).
  final List<AgeBand> bands;

  /// Header for the fused Critical-Care column, when the bands carry a
  /// [AgeBand.criticalCare] value. p.8 puts "Or MAP" there: the MAP
  /// thresholds are a credentialed measure, so the print gives them their own
  /// lavender stadium fused to the right of the blue one.
  final String? ccTitle;
}

/// One age row of a banded entry stadium: "Adult (14+)" → "90 mmHg", with an
/// optional Critical-Care value in the fused right-hand column.
class AgeBand {
  const AgeBand({required this.label, required this.value, this.criticalCare});

  factory AgeBand.fromYaml(Map<dynamic, dynamic> map) => AgeBand(
    label: map['label'] as String,
    value: map['value'] as String,
    criticalCare: map['cc'] as String?,
  );

  final String label;
  final String value;
  final String? criticalCare;
}

/// What the severity, linear and differential variants share: the entry
/// stadium chain with its side callouts at the top, and the convergence tail
/// (convergence, post-convergence, Critical Care pill, dose table) at the
/// bottom. The variants differ only in what sits between.
abstract class FlowchartBody {
  const FlowchartBody({
    this.entryChain = const [],
    this.convergence,
    this.postConvergence,
    this.criticalCareLink,
    this.doseTable = const [],
    this.warnings = const [],
  });

  final List<FlowNode> entryChain;
  final ConvergenceNode? convergence;
  final ConvergenceNode? postConvergence;

  /// Optional lavender Critical Care reference pill rendered below the
  /// convergence / post-convergence (WVEMS PDF convention).
  final CriticalCareLink? criticalCareLink;
  final List<DoseRow> doseTable;

  /// Side-of-flowchart warning callouts that flank the first entry node
  /// (matching the WVEMS protocol PDF convention). One `safety` is
  /// rendered as a red octagon on the left of the entry stadium; one
  /// `caution` is rendered as a purple trapezoid on the right.
  /// More than one of each is allowed but only the first of each type
  /// is rendered.
  final List<WarningCallout> warnings;
}

/// `entry_chain:` (a list of nodes) or the older single `entry:`; empty
/// when the flowchart declares neither.
List<FlowNode> _entryChainFromYaml(Map<dynamic, dynamic> map) {
  if (map['entry_chain'] != null) {
    return _mapList(map['entry_chain'], FlowNode.fromYaml);
  }
  if (map['entry'] != null) return [FlowNode.fromYaml(map['entry'] as Map)];
  return const [];
}

/// The parsed body of a `variant: severity` flowchart block.
///
/// [entryChain] is a sequence of boxes rendered top-down before the branch
/// fork (e.g. "Safe/Stimulate/Shout" → "Assess breathing" → "Unresponsive").
/// Accepts either a YAML list (`entry_chain: [...]`) or a single node
/// (`entry: {...}`) for backward compatibility with the older shape.
///
/// [decision] is an optional node rendered between the last entry and the
/// branches when authors want an explicit decision prompt. Usually unneeded
/// when branches are severity-coloured and self-evident.
///
/// [postConvergence] is an optional box rendered after the convergence node,
/// reached by a forward-labeled exit arrow from the convergence. Used for
/// "if no change → continue with these steps" continuations typical of
/// resuscitation algorithms.
class SeverityFlowchart extends FlowchartBody {
  const SeverityFlowchart({
    required this.branches,
    super.entryChain,
    this.preDecisionActions = const [],
    this.decision,
    super.convergence,
    super.postConvergence,
    super.criticalCareLink,
    super.doseTable,
    super.warnings,
  });

  factory SeverityFlowchart.fromYaml(Map<dynamic, dynamic> map) =>
      SeverityFlowchart(
        entryChain: _entryChainFromYaml(map),
        preDecisionActions: _mapList(
          map['pre_decision_actions'],
          TopicAction.fromYaml,
        ),
        decision: _mapOrNull(map['decision'], FlowNode.fromYaml),
        branches: _mapList(map['branches'], TopicBranch.fromYaml),
        convergence: _mapOrNull(map['convergence'], ConvergenceNode.fromYaml),
        postConvergence: _mapOrNull(
          map['post_convergence'],
          ConvergenceNode.fromYaml,
        ),
        criticalCareLink: _mapOrNull(
          map['critical_care_link'],
          CriticalCareLink.fromYaml,
        ),
        doseTable: _mapList(map['dose_table'], DoseRow.fromYaml),
        warnings: _mapList(map['warnings'], WarningCallout.fromYaml),
      );

  /// Action tiles rendered as a centred vertical badged stack between
  /// the entry chain and the decision diamond (e.g. Hyperkalemia's
  /// 12-Lead / Albuterol before the severity branch point). Same
  /// semantics as [DifferentialFlowchart.preDecisionActions].
  final List<TopicAction> preDecisionActions;
  final FlowNode? decision;
  final List<TopicBranch> branches;
}

/// Side-of-flowchart warning callout. Two visual styles map from
/// [WarningType] — see `lib/widgets/flowchart/warning_callouts.dart`.
class WarningCallout {
  const WarningCallout({required this.type, required this.text});

  factory WarningCallout.fromYaml(Map<dynamic, dynamic> map) => WarningCallout(
    type: WarningType.fromString(map['type'] as String?),
    text: map['text'] as String,
  );

  final WarningType type;
  final String text;
}

enum WarningType {
  /// Red octagon (stop sign). For provider-safety warnings that come
  /// before any patient assessment — e.g. scene safety, BSI.
  safety,

  /// Purple trapezoid (wide edge on top). For caveats that change how a
  /// clinician engages the patient — e.g. respect refusal, capacity
  /// assessment — and Critical Care cross-references (PDF p.70's
  /// "Consider Destination Triage").
  caution;

  static WarningType fromString(String? s) => switch (s) {
    'safety' => safety,
    'caution' => caution,
    _ => safety,
  };
}

/// One step in a linear flowchart — either a content box (a titled
/// white-bordered box with bulleted text, same look as a branch
/// criteria box) or an action tile (the same widget used for a
/// severity-branch action).
sealed class LinearStep {
  const LinearStep();

  factory LinearStep.fromYaml(Map<dynamic, dynamic> map) {
    final type = (map['type'] as String?) ?? 'action';
    if (type == 'content') {
      return LinearContentStep(
        title: map['title'] as String,
        bullets: _stringList(map['bullets']),
      );
    }
    return LinearActionStep(action: TopicAction.fromYaml(map));
  }
}

/// A titled box with bullets — same visual primitive as a branch
/// criteria box.  Used for "Assess for:" / similar reference content
/// embedded in the flow.
class LinearContentStep extends LinearStep {
  const LinearContentStep({required this.title, this.bullets = const []});

  final String title;
  final List<String> bullets;
}

/// An action tile in a linear flow — same `ActionTile` widget the
/// severity branches use, with the same provider-level badge and
/// optional `timing` / `condition` subtitle.
class LinearActionStep extends LinearStep {
  const LinearActionStep({required this.action});

  final TopicAction action;
}

/// A single-column flowchart with no decision and no branches — used
/// by WVEMS protocols whose flow is `entry → step → step → … →
/// Consider`.  Reuses [entryChain], [convergence], [postConvergence],
/// [doseTable] and [warnings] with the same semantics as
/// [SeverityFlowchart].
class LinearFlowchart extends FlowchartBody {
  const LinearFlowchart({
    required this.steps,
    super.entryChain,
    super.convergence,
    super.postConvergence,
    super.criticalCareLink,
    super.doseTable,
    super.warnings,
  });

  factory LinearFlowchart.fromYaml(Map<dynamic, dynamic> map) =>
      LinearFlowchart(
        entryChain: _entryChainFromYaml(map),
        steps: _mapList(map['steps'], LinearStep.fromYaml),
        convergence: _mapOrNull(map['convergence'], ConvergenceNode.fromYaml),
        postConvergence: _mapOrNull(
          map['post_convergence'],
          ConvergenceNode.fromYaml,
        ),
        criticalCareLink: _mapOrNull(
          map['critical_care_link'],
          CriticalCareLink.fromYaml,
        ),
        doseTable: _mapList(map['dose_table'], DoseRow.fromYaml),
        warnings: _mapList(map['warnings'], WarningCallout.fromYaml),
      );

  final List<LinearStep> steps;
}

/// One card in a [DifferentialFlowchart] — a titled white-bordered box
/// with descriptive bullets, same visual primitive as a branch criteria
/// box (rendered via `BranchHeaderBox`).
class DifferentialCard {
  const DifferentialCard({required this.title, this.bullets = const []});

  factory DifferentialCard.fromYaml(Map<dynamic, dynamic> map) =>
      DifferentialCard(
        title: map['title'] as String,
        bullets: _stringList(map['bullets']),
      );

  final String title;
  final List<String> bullets;
}

/// Decision-into-card-grid flowchart — used by WVEMS protocols where a
/// single decision branches into N referential cards (e.g. Location?
/// → Skull Fx / Mouth / Scalp / Ears / Neck / Nose / Eyes / Teeth) that
/// the user reads to find the appropriate management for their
/// patient's specific situation.  Cards don't carry action tiles
/// themselves; downstream actions live in the convergence's bullets or
/// in the dose_table.  Reuses [entryChain], [convergence],
/// [postConvergence], [doseTable] and [warnings] with the same
/// semantics as [SeverityFlowchart] / [LinearFlowchart].
class DifferentialFlowchart extends FlowchartBody {
  const DifferentialFlowchart({
    required this.cards,
    super.entryChain,
    this.preDecisionActions = const [],
    this.decision,
    this.columns = 2,
    super.convergence,
    super.postConvergence,
    super.criticalCareLink,
    super.doseTable,
    super.warnings,
  });

  factory DifferentialFlowchart.fromYaml(Map<dynamic, dynamic> map) =>
      DifferentialFlowchart(
        entryChain: _entryChainFromYaml(map),
        preDecisionActions: _mapList(
          map['pre_decision_actions'],
          TopicAction.fromYaml,
        ),
        decision: _mapOrNull(map['decision'], FlowNode.fromYaml),
        cards: _mapList(map['cards'], DifferentialCard.fromYaml),
        columns: (map['columns'] as num?)?.toInt() ?? 2,
        convergence: _mapOrNull(map['convergence'], ConvergenceNode.fromYaml),
        postConvergence: _mapOrNull(
          map['post_convergence'],
          ConvergenceNode.fromYaml,
        ),
        criticalCareLink: _mapOrNull(
          map['critical_care_link'],
          CriticalCareLink.fromYaml,
        ),
        doseTable: _mapList(map['dose_table'], DoseRow.fromYaml),
        warnings: _mapList(map['warnings'], WarningCallout.fromYaml),
      );

  /// Action tiles rendered as a centred vertical badged stack between
  /// the entry chain and the decision diamond — matching WVEMS
  /// protocols whose flow runs assessments/interventions before the
  /// branch point (e.g. Altered LOC: Glucometer / 12-Lead / Saline
  /// Lock; Hyperkalemia: 12-Lead / Albuterol).
  final List<TopicAction> preDecisionActions;
  final FlowNode? decision;
  final List<DifferentialCard> cards;

  /// Grid column count — typically 2 (matching the WVEMS PDF layout).
  final int columns;
}

/// One step in a cascade flowchart.
///
/// [decision] is the yes/no question shown as the step's header. Optional
/// [criteria] are bullet points rendered beneath the question (e.g. a list
/// of red-flag signs to check).
///
/// [action] is the terminal action taken when the answer matches
/// [actionAnswer] (default: yes). [continuation] is the next step reached
/// via the opposite answer; null ends the chain.
class CascadeStep {
  const CascadeStep({
    required this.decision,
    this.criteria = const [],
    this.action,
    this.actionAnswer = YesNo.yes,
    this.continuation,
  });

  factory CascadeStep.fromYaml(Map<dynamic, dynamic> map) => CascadeStep(
    decision: map['decision'] as String,
    criteria: _stringList(map['criteria']),
    action: _mapOrNull(map['action'], TopicAction.fromYaml),
    actionAnswer: YesNo.fromString(map['action_answer'] as String?),
    continuation: _mapOrNull(map['continuation'], CascadeStep.fromYaml),
  );

  final String decision;
  final List<String> criteria;
  final TopicAction? action;
  final YesNo actionAnswer;
  final CascadeStep? continuation;

  YesNo get continuationAnswer => actionAnswer.opposite;
}

/// The parsed body of a `variant: cascade` flowchart block.
///
/// [terminalAction] (optional) is performed if the decision chain falls
/// through all steps without hitting an early-exit action — e.g. the
/// "perform LP" action at the bottom of a meningitis cascade that runs
/// only after every contraindication check passes.
///
/// [actionWidthFraction] is an author override for how wide the
/// right-hand action column should be, expressed as a fraction of the
/// cascade's total width (0.0–1.0). Defaults to 0.5. Tweak down (e.g.
/// 0.35) when action labels are short and the decision column needs
/// more room; tweak up when action labels themselves need more space.
/// The two action boxes in the same cascade always share this one
/// width so the column stays visually consistent.
class CascadeFlowchart {
  const CascadeFlowchart({
    required this.entry,
    required this.root,
    this.terminalAction,
    this.actionWidthFraction = 0.5,
  });

  factory CascadeFlowchart.fromYaml(Map<dynamic, dynamic> map) =>
      CascadeFlowchart(
        entry: FlowNode.fromYaml(map['entry'] as Map),
        root: CascadeStep.fromYaml(map['root'] as Map),
        terminalAction: _mapOrNull(
          map['terminal_action'],
          TopicAction.fromYaml,
        ),
        actionWidthFraction: (map['action_width'] as num?)?.toDouble() ?? 0.5,
      );

  final FlowNode entry;
  final CascadeStep root;
  final TopicAction? terminalAction;
  final double actionWidthFraction;
}

// ─────────────────────────────────────────────────────────────
// ALGORITHM FLOWCHART (variant: algorithm)
// ─────────────────────────────────────────────────────────────

/// A content box in an [AlgorithmFlowchart] — either a decision outcome's
/// result box (a disposition/endpoint or an intermediate step) or a named
/// shared box referenced by `goto`.
///
/// [id] (optional) makes the box referenceable from an outcome's `goto`.
/// [severity] tints the box using the WHO-IMCI severity palette (pink /
/// yellow / green); [RowSeverity.none] renders as the plain node fill.
class AlgoBox {
  const AlgoBox({
    this.id,
    required this.title,
    this.bullets = const [],
    this.severity = RowSeverity.none,
    this.table,
  });

  factory AlgoBox.fromYaml(Map<dynamic, dynamic> map) => AlgoBox(
    id: map['id'] as String?,
    title: map['title'] as String? ?? '',
    bullets: _stringList(map['bullets']),
    severity: RowSeverity.fromString(map['severity'] as String?),
    table: _mapOrNull(map['table'], AlgoTable.fromYaml),
  );

  final String? id;
  final String title;
  final List<String> bullets;
  final RowSeverity severity;

  /// Optional compact table rendered inside the box (below [title]). Lets a
  /// flowchart outcome BE a small reference table (e.g. Iron Studies) instead
  /// of pointing at a separate table block below the chart.
  final AlgoTable? table;
}

/// A small bordered table rendered inside an [AlgoBox]. [align] is one entry
/// per column ("left"/"center"/"right"); defaults to left for col 0, centre
/// for the rest.
class AlgoTable {
  const AlgoTable({required this.columns, required this.rows, this.align});

  factory AlgoTable.fromYaml(Map<dynamic, dynamic> map) => AlgoTable(
    columns: [
      for (final c in (map['columns'] as List? ?? const [])) c.toString(),
    ],
    rows: [
      for (final r in (map['rows'] as List? ?? const []))
        [for (final c in (r as List)) c.toString()],
    ],
    align: map['align'] != null
        ? [for (final a in (map['align'] as List)) a.toString()]
        : null,
  );

  final List<String> columns;
  final List<List<String>> rows;
  final List<String>? align;
}

/// One labelled outcome branch of an [AlgoStage] decision.
///
/// Exactly one target applies: an inline [box], or a [goto] reference to a
/// named [AlgorithmFlowchart.boxes] entry by id. [cont] (`continue: true`)
/// means the flow rejoins the spine and proceeds to the next stage after
/// this outcome; otherwise the outcome is a terminal leaf (the flow ends
/// in its box — a disposition).
class AlgoOutcome {
  const AlgoOutcome({
    required this.label,
    this.box,
    this.goto,
    this.cont = false,
  });

  factory AlgoOutcome.fromYaml(Map<dynamic, dynamic> map) => AlgoOutcome(
    label: map['label'] as String,
    box: _mapOrNull(map['box'], AlgoBox.fromYaml),
    goto: map['goto'] as String?,
    cont: (map['continue'] as bool?) ?? false,
  );

  final String label;
  final AlgoBox? box;
  final String? goto;
  final bool cont;
}

/// A decision stage on the vertical spine of an [AlgorithmFlowchart].
class AlgoStage {
  const AlgoStage({
    required this.decision,
    this.criteria = const [],
    required this.outcomes,
  });

  factory AlgoStage.fromYaml(Map<dynamic, dynamic> map) => AlgoStage(
    decision: map['decision'] as String,
    criteria: _stringList(map['criteria']),
    outcomes: [
      for (final o in (map['outcomes'] as List? ?? const []))
        AlgoOutcome.fromYaml(o as Map),
    ],
  );

  final String decision;
  final List<String> criteria;
  final List<AlgoOutcome> outcomes;
}

/// The parsed body of a `variant: algorithm` flowchart block — a vertical
/// multi-decision clinical algorithm. See [FlowchartVariant.algorithm].
class AlgorithmFlowchart {
  const AlgorithmFlowchart({
    this.entry,
    this.boxes = const [],
    required this.stages,
    this.terminal,
  });

  factory AlgorithmFlowchart.fromYaml(Map<dynamic, dynamic> map) =>
      AlgorithmFlowchart(
        entry: _mapOrNull(map['entry'], FlowNode.fromYaml),
        boxes: [
          for (final b in (map['boxes'] as List? ?? const []))
            AlgoBox.fromYaml(b as Map),
        ],
        stages: [
          for (final s in (map['stages'] as List? ?? const []))
            AlgoStage.fromYaml(s as Map),
        ],
        terminal: _mapOrNull(map['terminal'], AlgoBox.fromYaml),
      );

  final FlowNode? entry;
  final List<AlgoBox> boxes;
  final List<AlgoStage> stages;
  final AlgoBox? terminal;

  /// Resolves an outcome's target box: its inline [AlgoOutcome.box], else
  /// the named box matching [AlgoOutcome.goto] in [boxes] (null if neither).
  AlgoBox? boxFor(AlgoOutcome o) {
    if (o.box != null) return o.box;
    if (o.goto != null) {
      for (final b in boxes) {
        if (b.id == o.goto) return b;
      }
    }
    return null;
  }
}

/// Which side of the spine a [CycleBranch] box sits on.
enum CycleSide {
  left,
  right;

  static CycleSide fromString(String? s) =>
      s == 'left' ? CycleSide.left : CycleSide.right;
}

/// A labelled branch off a [CycleNode] — a treatment/action/wait box placed
/// to one [side] of the spine, reached by a labelled arrow from the node.
///
/// If [loopTo] names a spine node id, a return arrow is drawn from this box
/// back up to that node (the loop), optionally annotated with [loopLabel]
/// (e.g. a reassessment interval "reassess q5–10 min"). If [loopTo] is null
/// the branch is a terminal side action (e.g. Wernicke → Thiamine).
class CycleBranch {
  const CycleBranch({
    required this.label,
    required this.side,
    required this.box,
    this.loopTo,
    this.loopLabel,
  });

  factory CycleBranch.fromYaml(Map<dynamic, dynamic> map) => CycleBranch(
    label: map['label'] as String? ?? '',
    side: CycleSide.fromString(map['side'] as String?),
    box: AlgoBox.fromYaml(map['box'] as Map),
    loopTo: map['loop_to'] as String?,
    loopLabel: map['loop_label'] as String?,
  );

  final String label;
  final CycleSide side;
  final AlgoBox box;
  final String? loopTo;
  final String? loopLabel;
}

/// One node on the vertical spine of a [CycleFlowchart].
///
/// `shape` is a plain [CycleNodeShape.box] rectangle or a
/// [CycleNodeShape.decision] diamond. `branches` are side boxes (each
/// optionally looping back). `downLabel` annotates the arrow to the next
/// spine node (e.g. a decision's "once stable" exit); null = a plain arrow.
/// `id` makes the node a valid [CycleBranch.loopTo] target.
enum CycleNodeShape {
  box,
  decision;

  static CycleNodeShape fromString(String? s) =>
      s == 'decision' ? CycleNodeShape.decision : CycleNodeShape.box;
}

class CycleNode {
  const CycleNode({
    this.id,
    required this.shape,
    required this.title,
    this.bullets = const [],
    this.severity = RowSeverity.none,
    this.branches = const [],
    this.downLabel,
  });

  factory CycleNode.fromYaml(Map<dynamic, dynamic> map) => CycleNode(
    id: map['id'] as String?,
    shape: CycleNodeShape.fromString(map['shape'] as String?),
    title: map['title'] as String,
    bullets: _stringList(map['bullets']),
    severity: RowSeverity.fromString(map['severity'] as String?),
    branches: [
      for (final b in (map['branches'] as List? ?? const []))
        CycleBranch.fromYaml(b as Map),
    ],
    downLabel: map['down_label'] as String?,
  );

  final String? id;
  final CycleNodeShape shape;
  final String title;
  final List<String> bullets;
  final RowSeverity severity;
  final List<CycleBranch> branches;
  final String? downLabel;
}

/// The parsed body of a `variant: cycle` flowchart — a vertical spine of
/// [nodes] with id-addressed edges. See [FlowchartVariant.cycle].
class CycleFlowchart {
  const CycleFlowchart({required this.nodes});

  factory CycleFlowchart.fromYaml(Map<dynamic, dynamic> map) => CycleFlowchart(
    nodes: [
      for (final n in (map['nodes'] as List? ?? const []))
        CycleNode.fromYaml(n as Map),
    ],
  );

  final List<CycleNode> nodes;

  /// Index of the spine node with [id], or -1.
  int indexOfId(String id) => nodes.indexWhere((n) => n.id == id);
}

// ─────────────────────────────────────────────────────────────
// BLOCK HIERARCHY
// ─────────────────────────────────────────────────────────────

/// A single vertical section of a [Topic]. Sealed — add a case in every
/// `switch` on [Block] when a new variant is introduced.
///
/// [flex] is only meaningful when this block is a direct child of a
/// [RowBlock] or [ColumnBlock] — it controls the share of available
/// space this child receives.  Default 1 (equal share).
sealed class Block {
  const Block({this.flex = 1, this.anchor, this.ownPaletteArgb = const {}});

  final int flex;

  /// Optional anchor slug. A `topic:<id>#<anchor>` or same-topic
  /// `#<anchor>` link scrolls the view to this block. Null = not a target.
  final String? anchor;

  /// This block's own `palette:` overrides as role → packed-ARGB ints
  /// (Flutter-free). A block is a "sub-thing" of its topic: it inherits the
  /// resolved book → chapter → topic palette and may override any role for
  /// itself (e.g. a single danger callout that should read red on an
  /// otherwise amber-callout topic). The renderer layers these over the
  /// topic theme. Empty = inherit everything.
  final Map<String, int> ownPaletteArgb;

  factory Block.fromYaml(Map<dynamic, dynamic> map) {
    final type = map['type'] as String?;
    return switch (type) {
      'prose' => ProseBlock.fromYaml(map),
      'band_callout' => BandCalloutBlock.fromYaml(map),
      'flowchart' => FlowchartBlock.fromYaml(map),
      'table' => TableBlock.fromYaml(map),
      'drug_card' => DrugCardBlock.fromYaml(map),
      'procedure_card' => ProcedureBlock.fromYaml(map),
      'image' => ImageBlock.fromYaml(map),
      'row' => RowBlock.fromYaml(map),
      'column' => ColumnBlock.fromYaml(map),
      'arrows' => ArrowsBlock.fromYaml(map),
      'merge_arrows' => MergeArrowsBlock.fromYaml(map),
      'conversion' => ConversionBlock.fromYaml(map),
      'formula' => FormulaBlock.fromYaml(map),
      'score' => ScoreBlock.fromYaml(map),
      _ => throw FormatException('Unknown block type: $type'),
    };
  }
}

int _flex(Map<dynamic, dynamic> map) => (map['flex'] as num?)?.toInt() ?? 1;

/// Horizontal layout primitive — renders its child blocks side-by-side in
/// a Row, each getting equal horizontal share. Used when two blocks (e.g.
/// a pair of narrow reference tables) read more naturally alongside each
/// other than stacked vertically.
class RowBlock extends Block {
  const RowBlock({required this.blocks, super.flex});

  factory RowBlock.fromYaml(Map<dynamic, dynamic> map) => RowBlock(
    blocks: _mapList(map['blocks'], Block.fromYaml),
    flex: _flex(map),
  );

  final List<Block> blocks;
}

/// Vertical layout primitive — mirror of [RowBlock].  Stacks child
/// blocks in a column with the standard 6 px gap between them.  Used
/// inside a [RowBlock] slot when the column needs to hold more than
/// one logical row (e.g. a "Treat presumptively" header over a pair
/// of "Order RDT" / "Order B/S" cells).
class ColumnBlock extends Block {
  const ColumnBlock({required this.blocks, super.flex});

  factory ColumnBlock.fromYaml(Map<dynamic, dynamic> map) => ColumnBlock(
    blocks: _mapList(map['blocks'], Block.fromYaml),
    flex: _flex(map),
  );

  final List<Block> blocks;
}

/// Horizontal run of down-arrows — a layout primitive for bridging two
/// stacked blocks in a flow-grid (e.g. between rows of a diagnostic
/// matrix).  [count] is the number of evenly-spaced arrows across the
/// block width; use `count: 4` under a 4-cell table row to visually link
/// the cells above to the cells below.
class ArrowsBlock extends Block {
  const ArrowsBlock({
    required this.count,
    this.label,
    this.length = 14,
    this.direction = ArrowDirection.down,
    this.inline = false,
    super.flex,
  });

  factory ArrowsBlock.fromYaml(Map<dynamic, dynamic> map) => ArrowsBlock(
    count: (map['count'] as num?)?.toInt() ?? 1,
    label: map['label'] as String?,
    length: (map['length'] as num?)?.toDouble() ?? 14,
    direction: ArrowDirection.fromString(map['direction'] as String?),
    inline: (map['inline'] as bool?) ?? false,
    flex: _flex(map),
  );

  final int count;
  final String? label;
  final double length;
  final ArrowDirection direction;

  /// When true (down direction only), the label renders beside the
  /// arrow instead of stacked above it — saves a line of vertical
  /// space when the arrow is on its own row.
  final bool inline;
}

enum ArrowDirection {
  down,
  right;

  static ArrowDirection fromString(String? s) => switch (s) {
    'right' => right,
    _ => down,
  };
}

/// Converging arrows — rendered as a short row of down-arrows at
/// [sources] column positions, joined by a horizontal rule, then a
/// single longer down-arrow descending from [targetCenter].  Used when
/// several diagnostic outcomes funnel into a single next step and a
/// straight column of arrows would misalign (e.g. p.22 malaria: three
/// "treat" outcomes → half-width severe-signs box).
///
/// [columns] is the total grid width this block spans (0-indexed
/// source/target column positions reference slots out of [columns]).
class MergeArrowsBlock extends Block {
  const MergeArrowsBlock({
    required this.columns,
    required this.sources,
    required this.targetCenter,
  });

  factory MergeArrowsBlock.fromYaml(Map<dynamic, dynamic> map) =>
      MergeArrowsBlock(
        columns: (map['columns'] as num?)?.toInt() ?? 1,
        sources: _intList(map['sources']),
        targetCenter: (map['target_center'] as num?)?.toDouble() ?? 0,
      );

  final int columns;
  final List<int> sources;

  /// Column index (fractional allowed) where the single converged
  /// down-arrow renders.  `2.5` means the arrow sits on the line
  /// between cols 2 and 3 — useful for centering under a span.
  final double targetCenter;
}

/// Markdown-authored text block. Most content lives here.
///
/// [highlight] triggers a tinted container (pediatrics pink). [callout]
/// triggers a distinct cream/tan box with a centered title pill, used
/// for the special "Poor Perfusion"-style sidebars in the WVEMS PDFs.
/// Details are a renderer concern.
class ProseBlock extends Block {
  const ProseBlock({
    required this.markdown,
    this.title,
    this.highlight = false,
    this.callout = false,
    this.dashed = false,
    this.boxed = false,
    this.textScale = 1.0,
    this.callEr = false,
    this.criticalCareLink,
    super.flex,
    super.anchor,
    super.ownPaletteArgb,
  });

  factory ProseBlock.fromYaml(Map<dynamic, dynamic> map) => ProseBlock(
    title: map['title'] as String?,
    markdown: map['markdown'] as String,
    highlight: (map['highlight'] as bool?) ?? false,
    callout: (map['callout'] as bool?) ?? false,
    dashed: (map['dashed'] as bool?) ?? false,
    boxed: (map['boxed'] as bool?) ?? false,
    textScale: (map['text_scale'] as num?)?.toDouble() ?? 1.0,
    callEr: (map['call_er'] as bool?) ?? false,
    criticalCareLink: _mapOrNull(
      map['critical_care_link'],
      CriticalCareLink.fromYaml,
    ),
    flex: _flex(map),
    anchor: map['anchor'] as String?,
    ownPaletteArgb: _parsePaletteArgb(map['palette']),
  );

  final String? title;
  final String markdown;
  final bool highlight;
  final bool callout;

  /// Lavender Critical-Care tab fused under this box, the same pill a
  /// flowchart hangs under its convergence. The print puts it under a prose
  /// section on two pages (p.6 Airway → Ventilator, p.62 Head Injury →
  /// Elevated ICP); before this field existed those two tabs were parsed
  /// into nothing and never drawn.
  final CriticalCareLink? criticalCareLink;

  /// Body size for this block as a fraction of the prose body.
  ///
  /// The print keeps a whole tier below the body for matter that must recede:
  /// URLs and `[Ver: …]` stamps at 12 pt (0.48 of body) and attributions at
  /// 9-12 pt, so a Medscape URL does not carry the same weight as a drug dose
  /// (audit §3.7). 0.48 is unreadable at a 12-14 px body, so a References
  /// block takes 0.8 — the same intent, sized for a screen.
  final double textScale;

  /// Pairs this box with the print's "Call ER" tile on its right.
  ///
  /// The print has no separate alert badge — the marker *is* the composition
  /// `dashed box { … "Call a <X> Alert" } + Call-ER tile` (audit §4.2), on
  /// exactly the 12 pages that carry the tile. Explicit rather than inferred
  /// from `dashed`, because a dashed box is also the print's form for an
  /// ordinary conditional (p.43's peds Versed sub-box), which gets no tile.
  final bool callEr;

  /// Draws a [callout] box's outline dashed instead of solid. The print
  /// uses this to separate a **conditional** box from a firm one — PDF
  /// p.71 dashes "If Major Intervention / Or Major Mechanism / Call a
  /// TRAUMA Alert" while the "ABLS rate:" box beside it stays solid, and
  /// p.43 dashes the conditional peds Versed sub-box. Ignored unless
  /// [callout] is set.
  final bool dashed;

  /// When true, the prose body is wrapped in a rounded-border tile
  /// (matching boxed-layout table cells) with centered text.  Used
  /// when the block is a grid cell inside a RowBlock flow layout.
  final bool boxed;
}

// ─────────────────────────────────────────────────────────────
// BAND CALLOUT BLOCK
// ─────────────────────────────────────────────────────────────

/// Which population / credential a [BandCalloutBlock] applies to. The
/// printed protocols use exactly two of these tints.
enum CalloutBand {
  /// Paediatric-only content — pink band, pink left bracket. The printed
  /// "Pediatrics" section that closes almost every protocol text page.
  peds,

  /// Critical Care content — lavender band, purple left bracket. The
  /// printed "Consider … if indicated and credentialed for CC." lines,
  /// and whole sections on the Critical Care pages.
  criticalCare;

  static CalloutBand fromString(String? s) => switch (s) {
    'peds' => peds,
    'pediatrics' => peds,
    'critical_care' => criticalCare,
    'cc' => criticalCare,
    _ => peds,
  };

  /// Section label the print uses when the band stands on its own, used
  /// when the author gives no `title:`.
  String get defaultTitle => switch (this) {
    peds => 'Pediatrics',
    criticalCare => 'Critical Care',
  };
}

/// A banded callout: a run of markdown the printed protocols tint to flag
/// **who** it applies to. Distinct from [ProseBlock]'s `callout: true`,
/// which is the amber attention card — this block carries the WVEMS
/// population/credentialing convention instead:
///
///   - [CalloutBand.peds] — pink fill + pink left bracket. In the source
///     PDF a pink band appears on 78 of the 166 pages, and the pink
///     "Pediatrics" section bracket on 50 (pp.3-95 odd, 110, 144, 147);
///     it is the single most frequent callout in the book.
///   - [CalloutBand.criticalCare] — lavender fill + purple left bracket.
///     Lavender appears on 54 pages (e.g. p.11's three "Consider …
///     credentialed for CC." lines, p.5's "Consider Intubation …").
///
/// Body text renders through MiniMarkdown like any other prose, so
/// `**bold**` and `[links](topic:…)` behave the same. Colors come from the
/// `peds_band_*` / `cc_band_*` palette roles, so a book, chapter, topic or
/// this very block may re-skin them.
class BandCalloutBlock extends Block {
  const BandCalloutBlock({
    required this.band,
    required this.markdown,
    this.title,
    super.flex,
    super.anchor,
    super.ownPaletteArgb,
  });

  factory BandCalloutBlock.fromYaml(Map<dynamic, dynamic> map) =>
      BandCalloutBlock(
        band: CalloutBand.fromString(map['band'] as String?),
        markdown: map['markdown'] as String,
        title: map['title'] as String?,
        flex: _flex(map),
        anchor: map['anchor'] as String?,
        ownPaletteArgb: _parsePaletteArgb(map['palette']),
      );

  final CalloutBand band;
  final String markdown;

  /// Section label shown inside the band. Null falls back to
  /// [CalloutBand.defaultTitle]; pass an empty string for a bare band
  /// (the print's line-level use, where the tinted line sits inside some
  /// other section and carries no heading of its own).
  final String? title;
}

/// A flowchart in one of the supported variants.
///
/// Exactly one variant body is populated, selected by [variant]. The `cycle`
/// variant carries a [CycleFlowchart] for genuinely cyclic algorithms
/// (reassessment loops, resuscitation cycles) drawn with real back-edges.
class FlowchartBlock extends Block {
  const FlowchartBlock({
    required this.variant,
    this.severity,
    this.cascade,
    this.linear,
    this.differential,
    this.algorithm,
    this.cycle,
    super.anchor,
    super.ownPaletteArgb,
  });

  factory FlowchartBlock.fromYaml(Map<dynamic, dynamic> map) {
    final variant = FlowchartVariant.fromString(map['variant'] as String?);
    final anchor = map['anchor'] as String?;
    final palette = _parsePaletteArgb(map['palette']);
    return switch (variant) {
      FlowchartVariant.severity => FlowchartBlock(
        variant: variant,
        severity: SeverityFlowchart.fromYaml(map),
        anchor: anchor,
        ownPaletteArgb: palette,
      ),
      FlowchartVariant.cascade => FlowchartBlock(
        variant: variant,
        cascade: CascadeFlowchart.fromYaml(map),
        anchor: anchor,
        ownPaletteArgb: palette,
      ),
      FlowchartVariant.linear => FlowchartBlock(
        variant: variant,
        linear: LinearFlowchart.fromYaml(map),
        anchor: anchor,
        ownPaletteArgb: palette,
      ),
      FlowchartVariant.differential => FlowchartBlock(
        variant: variant,
        differential: DifferentialFlowchart.fromYaml(map),
        anchor: anchor,
        ownPaletteArgb: palette,
      ),
      FlowchartVariant.algorithm => FlowchartBlock(
        variant: variant,
        algorithm: AlgorithmFlowchart.fromYaml(map),
        anchor: anchor,
        ownPaletteArgb: palette,
      ),
      FlowchartVariant.cycle => FlowchartBlock(
        variant: variant,
        cycle: CycleFlowchart.fromYaml(map),
        anchor: anchor,
        ownPaletteArgb: palette,
      ),
    };
  }

  final FlowchartVariant variant;
  final SeverityFlowchart? severity;
  final CascadeFlowchart? cascade;
  final LinearFlowchart? linear;
  final DifferentialFlowchart? differential;
  final AlgorithmFlowchart? algorithm;
  final CycleFlowchart? cycle;
}

// ─────────────────────────────────────────────────────────────
// TABLE BLOCK
// ─────────────────────────────────────────────────────────────

/// A cell's content is one of:
///   - plain text (single-line string)
///   - a bulleted list of strings (YAML list)
///   - a multi-line markdown block (string containing a newline, or
///     a YAML block scalar with `|`) — rendered via `MiniMarkdown`
///     with `**bold**` spans and `- ` bullets. Used for cells with
///     structured sub-sections (e.g. WHO IMCI Chart 2 treat cells with
///     "If no severe malnutrition: ... / If severe malnutrition: ...").
///
/// [span] is the number of table columns this cell covers. Default 1.
/// Structured cells (YAML map form) can set `span:` to merge neighbouring
/// columns — e.g. in a Component × (Adults | Children | Infants) table,
/// a row where all three populations share one value has a `span: 3`
/// cell instead of three duplicated cells.
sealed class TableCell {
  const TableCell({this.span = 1});

  final int span;

  factory TableCell.fromYaml(dynamic raw) {
    if (raw is String) {
      if (raw.contains('\n')) return MarkdownCell(raw);
      return TextCell(raw);
    }
    if (raw is YamlList) {
      return BulletCell(raw.map((e) => e as String).toList());
    }
    if (raw is List) return BulletCell(raw.cast<String>());
    if (raw is Map) {
      final span = (raw['span'] as num?)?.toInt() ?? 1;
      if (raw['bullets'] != null) {
        return BulletCell(_stringList(raw['bullets']), span: span);
      }
      final text = raw['text'] as String? ?? '';
      if (text.contains('\n')) return MarkdownCell(text, span: span);
      return TextCell(text, span: span);
    }
    return const TextCell('');
  }
}

class TextCell extends TableCell {
  const TextCell(this.text, {super.span});
  final String text;
}

class BulletCell extends TableCell {
  const BulletCell(this.items, {super.span});
  final List<String> items;
}

class MarkdownCell extends TableCell {
  const MarkdownCell(this.markdown, {super.span});
  final String markdown;
}

/// A single data row in a table.
///
/// [title] is an optional row-level banner rendered above the row's cells
/// (e.g. "Priority signs (3TPR-MOB)" as a prominent heading for the row,
/// distinct from the cell contents below it).
///
/// [header] is an optional row-header label rendered as a left column
/// (e.g. "Compression rate" in a CPR-by-age table).
///
/// [group] collapses consecutive rows under a single category label
/// (e.g. "Compression" spanning rate/depth/ratio rows).
///
/// [severity] drives WHO IMCI-style background coloring.
class TopicTableRow {
  const TopicTableRow({
    required this.cells,
    this.title,
    this.header,
    this.group,
    this.severity = RowSeverity.none,
  });

  factory TopicTableRow.fromYaml(Map<dynamic, dynamic> map) {
    final rawCells = map['cells'];
    final cellList = rawCells is YamlList
        ? rawCells.toList()
        : (rawCells as List?) ?? const [];
    return TopicTableRow(
      title: map['title'] as String?,
      header: map['header'] as String?,
      group: map['group'] as String?,
      severity: RowSeverity.fromString(map['severity'] as String?),
      cells: cellList.map(TableCell.fromYaml).toList(),
    );
  }

  final String? title;
  final String? header;
  final String? group;
  final RowSeverity severity;
  final List<TableCell> cells;
}

/// Structured table block.
///
/// Supports: column headers, row headers, row severity coloring, grouped
/// row headers (contiguous same-`group` rows collapse visually), and
/// bulleted cell content.
class TableBlock extends Block {
  const TableBlock({
    required this.rows,
    this.title,
    this.columns = const [],
    this.columnFlex = const [],
    this.columnWidths = const [],
    this.columnAlign = const [],
    this.columnTintArgb = const [],
    this.columnBar = const [],
    this.zebra = false,
    this.stickyHeader = false,
    this.stickyFirstColumn = false,
    this.lookup = false,
    this.lookupLabel,
    this.maxHeight,
    this.layout = TableLayout.standard,
    super.flex,
    super.anchor,
    super.ownPaletteArgb,
  });

  factory TableBlock.fromYaml(Map<dynamic, dynamic> map) => TableBlock(
    title: map['title'] as String?,
    columns: _stringList(map['columns']),
    columnFlex: _intList(map['column_flex']),
    columnWidths: _doubleList(map['column_widths']),
    columnAlign: _alignList(map['column_align']),
    columnTintArgb: _argbList(map['column_tint']),
    columnBar: _boolList(map['column_bar']),
    zebra: map['zebra'] == true,
    stickyHeader: map['sticky_header'] == true,
    stickyFirstColumn: map['sticky_first_column'] == true,
    lookup: map['lookup'] == true,
    lookupLabel: map['lookup_label'] as String?,
    maxHeight: (map['max_height'] as num?)?.toDouble(),
    rows: _mapList(map['rows'], TopicTableRow.fromYaml),
    layout: TableLayout.fromString(map['layout'] as String?),
    flex: _flex(map),
    anchor: map['anchor'] as String?,
    ownPaletteArgb: _parsePaletteArgb(map['palette']),
  );

  final String? title;
  final List<String> columns;

  /// Optional per-column flex weights, one per entry in [columns].  When
  /// set (and length matches [columns]), the header row and every data
  /// row distribute width by these weights instead of equally — e.g.
  /// `[5, 2, 2, 2]` makes a wide label column with narrow value columns
  /// (matches the WVEMS APGAR layout).  Empty = equal columns.
  final List<int> columnFlex;

  /// Optional per-column fixed widths (logical px), one per entry in
  /// [columns].  Used only by [TableLayout.scroll], where columns cannot
  /// flex (the table is wider than the screen and scrolls horizontally),
  /// so each needs an explicit width — e.g. the §3.14 neonatal drug-dose
  /// matrix (Drug/Dosage/Form + 7 weight-band columns).
  final List<double> columnWidths;

  /// Optional per-column text alignment (`left`/`right`/`center`), one per
  /// [columns]. `right` lines up decimals in numeric reference tables (the
  /// standard convention for figures). Empty / short → left.
  final List<CellAlign> columnAlign;

  /// Optional per-column background tint (packed ARGB, one per [columns];
  /// an empty string / null entry = no tint). Highlights a whole column —
  /// e.g. the −2 SD / −3 SD decision-boundary columns in the growth tables.
  /// Composited under zebra/severity so the column reads through striping.
  final List<int?> columnTintArgb;

  /// Optional per-column in-cell magnitude bars (one bool per [columns]).
  /// When true and the cell parses as a number, a horizontal bar scaled to
  /// that column's min…max is drawn behind the value — the "in-cell bar"
  /// encoding (good for spotting magnitude/extremes at a glance).
  final List<bool> columnBar;

  /// Soft alternating row shading (zebra striping). Evidence-based aid for
  /// row-tracking in wide lookup tables — keeps the eye on the correct row.
  /// Applied only where a row has no explicit [RowSeverity] tint.
  final bool zebra;

  /// Pin the header row while the body scrolls vertically (scroll layout).
  final bool stickyHeader;

  /// Pin the first (label) column while the body scrolls horizontally
  /// (scroll layout) — the age / length / height column stays visible.
  final bool stickyFirstColumn;

  /// Show a "go to row" finder above the table: the reader types a value,
  /// and the table scrolls to and highlights the row whose first (key)
  /// column matches — nearest value for a numeric key column, text match
  /// otherwise. A general aid for any long keyed lookup table (growth
  /// z-scores, dose-by-weight matrices, conversion tables…). Implies a
  /// bounded, internally-scrolling panel (like [stickyFirstColumn]).
  final bool lookup;

  /// Optional label/hint for the [lookup] finder field. Defaults to
  /// "Go to " followed by the first column's header.
  final String? lookupLabel;

  /// Optional max height (logical px) for a scroll-layout table: the grid
  /// becomes a bounded, internally-scrolling panel instead of an
  /// arbitrarily tall page — essential for the ~130-row growth tables.
  final double? maxHeight;

  final List<TopicTableRow> rows;
  final TableLayout layout;
}

/// Per-column text alignment for [TableBlock].
enum CellAlign {
  left,
  right,
  center;

  static CellAlign fromString(String? s) => switch (s) {
    'right' => right,
    'center' => center,
    _ => left,
  };
}

/// Table rendering modes.
///
/// [standard] is the default dense grid — outer border, 1 px dividers
/// between cells, row-level severity tinting.  [boxed] renders each cell
/// as its own rounded-border tile with a visible gap between them —
/// useful when the table is acting as a flow-grid row (e.g. p.22 malaria
/// diagnostic matrix) and the cells read as discrete steps, not as
/// rows of comparable data.
enum TableLayout {
  standard,
  boxed,

  /// A table too wide for the screen (many columns).  Columns take fixed
  /// [TableBlock.columnWidths] and the whole grid scrolls horizontally
  /// inside a scrollbar.  Used by the §3.14 neonatal drug-dose matrix.
  scroll;

  static TableLayout fromString(String? s) => switch (s) {
    'boxed' => boxed,
    'scroll' => scroll,
    _ => standard,
  };
}

// ─────────────────────────────────────────────────────────────
// DRUG CARD BLOCK
// ─────────────────────────────────────────────────────────────

/// A single dose line within a drug card (one population variant).
class DrugDose {
  const DrugDose({
    required this.text,
    this.population = DosePopulation.both,
  });

  factory DrugDose.fromYaml(Map<dynamic, dynamic> map) => DrugDose(
    text: map['text'] as String,
    population: DosePopulation.fromString(map['population'] as String?),
  );

  final String text;
  final DosePopulation population;
}

/// Canonical drug reference card.
///
/// Field set chosen to match WVEMS drug reference (pp.120-140),
/// pocketbook drug cards, and WHO essential medicines entries.
/// Optional [imagePath] renders a small product shot on the right
/// side of the card (WVEMS convention). Falls back to a grey
/// placeholder if the asset is missing, same as `ImageBlock`.
class DrugCardBlock extends Block {
  const DrugCardBlock({
    required this.name,
    this.drugClass,
    this.indications = const [],
    this.contraindications = const [],
    this.doses = const [],
    this.warnings = const [],
    this.pearls = const [],
    this.imagePath,
    this.criticalCare = false,
    super.anchor,
    super.ownPaletteArgb,
  });

  factory DrugCardBlock.fromYaml(Map<dynamic, dynamic> map) => DrugCardBlock(
    name: map['name'] as String,
    drugClass: map['class'] as String?,
    indications: _stringList(map['indications']),
    contraindications: _stringList(map['contraindications']),
    doses: _mapList(map['doses'], DrugDose.fromYaml),
    warnings: _stringList(map['warnings']),
    pearls: _stringList(map['pearls']),
    imagePath: map['image'] as String?,
    criticalCare: map['critical_care'] as bool? ?? false,
    anchor: map['anchor'] as String? ?? anchorSlug(map['name'] as String),
    ownPaletteArgb: _parsePaletteArgb(map['palette']),
  );

  final String name;
  final String? drugClass;
  final List<String> indications;
  final List<String> contraindications;
  final List<DrugDose> doses;
  final List<String> warnings;
  final List<String> pearls;
  final String? imagePath;

  /// The drug is Critical-Care restricted. In the printed cards this shows
  /// as the Notes zone turning lavender (#D9D2E9) instead of cyan — the Use
  /// and Caution zones are unchanged (verified p.139, Propofol).
  final bool criticalCare;
}

// ─────────────────────────────────────────────────────────────
// PROCEDURE CARD BLOCK
// ─────────────────────────────────────────────────────────────

/// A single how-to procedure card (WVEMS Procedures section, pp.96-109):
/// a scope-badged header (provider level E/A/I, or none for basic/all-level)
/// over an auto-numbered step list.
///
/// Each entry in [steps] is a raw line parsed by the renderer via a compact
/// prefix mini-syntax (kept terse because a procedure runs 4-8 steps and the
/// section holds ~30 procedures):
///   - plain line            → next auto-numbered step ("1.", "2." …)
///   - `@2a text`            → explicit step label "2a"; resets the auto
///                             counter to the leading integer so a following
///                             plain step numbers correctly
///   - `- text`              → indented sub-bullet (not numbered)
///   - `~[E] text`           → standalone scope note (no number), dashed
///   - `[E] text` on a step  → inline provider-scope chip (tag is one of
///                             `[E]` / `[A]` / `[I]` / `[P]`); works on numbered
///                             steps, sub-bullets and standalone notes alike
///   - `:` before the text    → dashed-border emphasis (scope-gated callout);
///                             usually paired with a scope tag, e.g. `:[I] …`
///   - leading `!`           → pink highlight band (peds / age distinctions),
///                             composable with any of the above (e.g. `!- text`)
///   - leading `^`           → lavender highlight band (Critical Care / advanced
///                             option), composable the same way
///   - `NOTE: text`          → full-width note paragraph (no number)
/// Emphasis (`**bold**`) and links render through MiniMarkdown as elsewhere.
class ProcedureBlock extends Block {
  const ProcedureBlock({
    required this.name,
    this.scope,
    this.steps = const [],
    this.imagePath,
    super.anchor,
    super.ownPaletteArgb,
  });

  factory ProcedureBlock.fromYaml(Map<dynamic, dynamic> map) => ProcedureBlock(
    name: map['name'] as String,
    scope: _normalizeScope(map['scope'] as String?),
    steps: _stringList(map['steps']),
    imagePath: map['image'] as String?,
    anchor: map['anchor'] as String? ?? anchorSlug(map['name'] as String),
    ownPaletteArgb: _parsePaletteArgb(map['palette']),
  );

  final String name;

  /// Provider-level badge: `E`, `A`, `I`, `P` (paramedic) or `P(CC)` (Critical
  /// Care). Null = basic / all-level (rendered as a neutral grey chip, matching
  /// the printed index).
  final String? scope;
  final List<String> steps;
  final String? imagePath;

  /// Accepts the same spellings as [ProviderLevel.fromString] so a Critical
  /// Care procedure (`P(CC)` / `CC`) keeps its lavender badge instead of
  /// silently dropping to the all-level grey chip. Anything else is null.
  static String? _normalizeScope(String? s) {
    if (s == null) return null;
    final v = s.trim().toUpperCase();
    if (v == 'P(CC)' || v == 'CC') return 'P(CC)';
    return (v == 'E' || v == 'A' || v == 'I' || v == 'P') ? v : null;
  }
}

// ─────────────────────────────────────────────────────────────
// IMAGE BLOCK
// ─────────────────────────────────────────────────────────────

/// Image asset block with optional caption and size hint.
class ImageBlock extends Block {
  const ImageBlock({
    required this.path,
    this.caption,
    this.size = ImageSize.medium,
    super.anchor,
    super.ownPaletteArgb,
  });

  factory ImageBlock.fromYaml(Map<dynamic, dynamic> map) => ImageBlock(
    path: map['path'] as String,
    caption: map['caption'] as String?,
    size: ImageSize.fromString(map['size'] as String?),
    anchor: map['anchor'] as String?,
    ownPaletteArgb: _parsePaletteArgb(map['palette']),
  );

  final String path;
  final String? caption;
  final ImageSize size;
}

// ─────────────────────────────────────────────────────────────
// CONVERSION BLOCK (interactive dose conversion)
// ─────────────────────────────────────────────────────────────

/// How a conversion is computed. See docs/conversion_block.md.
enum ConversionMode {
  /// Titratable classes (opioids/benzos/steroids): free numeric entry,
  /// each agent has a [ConversionAgent.factor] to a reference anchor.
  equivalence,

  /// Fixed manufactured strengths (statins/inhalers): selection only;
  /// agents enumerate [ConversionAgent.doses], each tagged with a tier.
  tiers;

  static ConversionMode fromString(String? s) =>
      s == 'tiers' ? tiers : equivalence;
}

/// One agent in a conversion. In `equivalence` mode it carries a [factor]
/// (multiplier to the reference) and optional [route]/[unit]; in `tiers`
/// mode it carries [doses].
class ConversionAgent {
  const ConversionAgent({
    required this.name,
    this.route,
    this.factor,
    this.unit,
    this.doses = const [],
  });

  factory ConversionAgent.fromYaml(Map<dynamic, dynamic> map) =>
      ConversionAgent(
        name: map['name'] as String,
        route: map['route'] as String?,
        factor: (map['factor'] as num?)?.toDouble(),
        unit: map['unit'] as String?,
        doses: _mapList(map['doses'], ConversionDose.fromYaml),
      );

  final String name;
  final String? route;
  final double? factor;
  final String? unit;
  final List<ConversionDose> doses;
}

/// A discrete manufactured strength (tiers mode) tagged with its tier.
class ConversionDose {
  const ConversionDose({required this.dose, required this.tier});

  factory ConversionDose.fromYaml(Map<dynamic, dynamic> map) => ConversionDose(
    dose: '${map['dose']}',
    tier: map['tier'] as String,
  );

  final String dose;
  final String tier;
}

/// An agent that must NOT be auto-converted (nonlinear/special), shown with
/// the reason instead of being silently dropped.
class ConversionExcluded {
  const ConversionExcluded({required this.name, required this.reason});

  factory ConversionExcluded.fromYaml(Map<dynamic, dynamic> map) =>
      ConversionExcluded(
        name: map['name'] as String,
        reason: map['reason'] as String,
      );

  final String name;
  final String reason;
}

/// Interactive dose-conversion block. The first stateful block type.
class ConversionBlock extends Block {
  const ConversionBlock({
    required this.mode,
    required this.agents,
    this.title,
    this.reference,
    this.referenceLabel,
    this.unit,
    this.source,
    this.tiers = const [],
    this.tierNote,
    this.excluded = const [],
    this.caveats = const [],
    super.anchor,
    super.ownPaletteArgb,
  });

  factory ConversionBlock.fromYaml(Map<dynamic, dynamic> map) =>
      ConversionBlock(
        mode: ConversionMode.fromString(map['mode'] as String?),
        title: map['title'] as String?,
        reference: map['reference'] as String?,
        referenceLabel: map['reference_label'] as String?,
        unit: map['unit'] as String?,
        source: map['source'] as String?,
        tiers: _stringList(map['tiers']),
        tierNote: map['tier_note'] as String?,
        agents: _mapList(map['agents'], ConversionAgent.fromYaml),
        excluded: _mapList(map['excluded'], ConversionExcluded.fromYaml),
        caveats: _stringList(map['caveats']),
        anchor: map['anchor'] as String?,
        ownPaletteArgb: _parsePaletteArgb(map['palette']),
      );

  final ConversionMode mode;
  final String? title;

  /// The reference anchor's name (equivalence mode), e.g. "oral morphine".
  final String? reference;

  /// Short label for the reference/anchor line, e.g. "MME".
  final String? referenceLabel;

  /// Default dose unit (per-agent [ConversionAgent.unit] overrides).
  final String? unit;

  /// Where the factors / tiers come from — required for clinical safety.
  final String? source;

  /// Ordered tier names (tiers mode), low → high.
  final List<String> tiers;
  final String? tierNote;

  final List<ConversionAgent> agents;
  final List<ConversionExcluded> excluded;
  final List<String> caveats;

  /// Distinct agent names in declared order (for the drug dropdowns).
  List<String> get agentNames {
    final seen = <String>{};
    final out = <String>[];
    for (final a in agents) {
      if (seen.add(a.name)) out.add(a.name);
    }
    return out;
  }

  /// Routes available for [name] (equivalence mode).
  List<String?> routesFor(String name) => [
    for (final a in agents)
      if (a.name == name) a.route,
  ];

  ConversionAgent? agentFor(String name, String? route) {
    for (final a in agents) {
      if (a.name == name && a.route == route) return a;
    }
    return null;
  }

  /// Reference-equivalents of [dose] of [agent] (equivalence mode):
  /// dose × factor. Returns null if the agent has no factor.
  double? toReference(ConversionAgent agent, double dose) =>
      agent.factor == null ? null : dose * agent.factor!;

  /// Dose of [agent] equivalent to [referenceEquivalents].
  double? fromReference(ConversionAgent agent, double referenceEquivalents) =>
      agent.factor == null || agent.factor == 0
      ? null
      : referenceEquivalents / agent.factor!;
}

// ─────────────────────────────────────────────────────────────
// FORMULA BLOCK (numbers in → number out)
// ─────────────────────────────────────────────────────────────
// The math lives in lib/data/formula_registry.dart (pure Dart, unit-tested)
// keyed by [FormulaBlock.kind]. This block only declares the form. See
// docs/formula_block.md.

enum FormulaInputType {
  number,
  select,

  /// A yes/no checkbox; contributes a bool (true when checked) to the values.
  boolean;

  static FormulaInputType fromString(String? s) => switch (s) {
    'select' => select,
    'boolean' => boolean,
    _ => number,
  };
}

/// One option in a `select` input (a unit toggle, sex, …).
class FormulaOption {
  const FormulaOption({required this.value, this.label});

  factory FormulaOption.fromYaml(dynamic raw) => raw is Map
      ? FormulaOption(value: '${raw['value']}', label: raw['label'] as String?)
      : FormulaOption(value: '$raw');

  final String value;
  final String? label;
  String get display => label ?? value;
}

/// One user input of a [FormulaBlock] — drives a form field. The compute
/// function reads values by [key].
class FormulaInput {
  const FormulaInput({
    required this.key,
    required this.label,
    required this.type,
    this.unit,
    this.help,
    this.defaultValue,
    this.options = const [],
    this.optional = false,
  });

  factory FormulaInput.fromYaml(Map<dynamic, dynamic> map) => FormulaInput(
    key: map['key'] as String,
    label: map['label'] as String,
    type: FormulaInputType.fromString(map['type'] as String?),
    unit: map['unit'] as String?,
    help: map['help'] as String?,
    defaultValue: map['default'] == null ? null : '${map['default']}',
    options: [
      for (final o in map['options'] as List? ?? const [])
        FormulaOption.fromYaml(o),
    ],
    optional: (map['optional'] as bool?) ?? false,
  );

  final String key;
  final String label;
  final FormulaInputType type;
  final String? unit;
  final String? help;

  /// Default as a string (parsed to num for number inputs; the selected option
  /// value for selects, falling back to the first option).
  final String? defaultValue;
  final List<FormulaOption> options;

  /// Optional inputs don't block computation when blank (e.g. albumin for the
  /// anion-gap correction, or actual weight for adjusted body weight).
  final bool optional;
}

/// Interactive formula calculator block. Numeric/select inputs → one or more
/// computed outputs via the registry keyed by [kind]. The first stateful block
/// after [ConversionBlock].
class FormulaBlock extends Block {
  const FormulaBlock({
    required this.kind,
    required this.inputs,
    this.title,
    this.source,
    this.notes = const [],
    this.caveats = const [],
    super.anchor,
    super.ownPaletteArgb,
  });

  factory FormulaBlock.fromYaml(Map<dynamic, dynamic> map) => FormulaBlock(
    kind: map['kind'] as String,
    title: map['title'] as String?,
    source: map['source'] as String?,
    inputs: _mapList(map['inputs'], FormulaInput.fromYaml),
    notes: _stringList(map['notes']),
    caveats: _stringList(map['caveats']),
    anchor: map['anchor'] as String?,
    ownPaletteArgb: _parsePaletteArgb(map['palette']),
  );

  /// Registry key selecting the compute function (see formula_registry.dart).
  final String kind;
  final String? title;

  /// Provenance of the formula — required for clinical safety (shown as source).
  final String? source;

  final List<FormulaInput> inputs;

  /// Static explanatory lines shown under the result (e.g. the formula itself).
  final List<String> notes;
  final List<String> caveats;
}

// ─────────────────────────────────────────────────────────────
// SCORE BLOCK (criteria → summed points → risk band)
// ─────────────────────────────────────────────────────────────
// Fully declarative: points + bands live in YAML; the sum + band lookup is in
// lib/data/score_engine.dart (pure Dart, unit-tested). General enough for
// risk scores AND questionnaire/screening instruments. See docs/score_block.md.

enum ScoreItemType {
  /// A yes/no criterion contributing [ScoreItem.points] when on.
  toggle,

  /// A pick-one criterion; the chosen [ScoreOption] contributes its points.
  /// Rendered as chips.
  choice,

  /// Like [choice] but rendered as a compact 0–N stepper with the selected
  /// level's anchor label — for graded scales (CIWA-Ar, COWS, PHQ-9, …) whose
  /// many levels would be too busy as chips. Scored identically to [choice].
  scale;

  static ScoreItemType fromString(String? s) => switch (s) {
    'choice' => choice,
    'scale' => scale,
    _ => toggle,
  };
}

/// One option of a `choice` item.
class ScoreOption {
  const ScoreOption({
    required this.value,
    required this.label,
    required this.points,
  });

  factory ScoreOption.fromYaml(Map<dynamic, dynamic> m) => ScoreOption(
    value: '${m['value']}',
    label: (m['label'] as String?) ?? '${m['value']}',
    points: (m['points'] as num?) ?? 0,
  );

  final String value;
  final String label;
  final num points;
}

/// One scored criterion.
class ScoreItem {
  const ScoreItem({
    required this.key,
    required this.label,
    required this.type,
    this.help,
    this.points = 0,
    this.options = const [],
    this.defaultValue,
  });

  factory ScoreItem.fromYaml(Map<dynamic, dynamic> m) => ScoreItem(
    key: m['key'] as String,
    label: m['label'] as String,
    type: ScoreItemType.fromString(m['type'] as String?),
    help: m['help'] as String?,
    points: (m['points'] as num?) ?? 0,
    options: [
      for (final o in m['options'] as List? ?? const [])
        ScoreOption.fromYaml(o as Map),
    ],
    defaultValue: m['default'] == null ? null : '${m['default']}',
  );

  final String key;
  final String label;
  final ScoreItemType type;
  final String? help;

  /// Points added when a `toggle` item is on.
  final num points;

  /// Options for a `choice` item.
  final List<ScoreOption> options;

  /// A `choice` item's initially-selected option value (falls back to the
  /// first option). Ignored for toggles (which start off).
  final String? defaultValue;
}

/// A total-score interval mapping to an interpretation. [max] null = open-ended.
class ScoreBand {
  const ScoreBand({
    required this.min,
    required this.label,
    this.max,
    this.detail,
    this.severity = FormulaSeverity.none,
  });

  factory ScoreBand.fromYaml(Map<dynamic, dynamic> m) => ScoreBand(
    min: (m['min'] as num?) ?? 0,
    max: m['max'] as num?,
    label: m['label'] as String,
    detail: m['detail'] as String?,
    severity: switch (m['severity'] as String?) {
      'alert' => FormulaSeverity.alert,
      'warn' => FormulaSeverity.warn,
      'info' => FormulaSeverity.info,
      _ => FormulaSeverity.none,
    },
  );

  final num min;
  final num? max;
  final String label;
  final String? detail;
  final FormulaSeverity severity;
}

/// Interactive additive-score calculator (tap criteria → summed points → risk
/// band). The scoring is in score_engine.dart. Stateful, like [FormulaBlock].
class ScoreBlock extends Block {
  const ScoreBlock({
    required this.items,
    required this.bands,
    this.title,
    this.unit = 'points',
    this.showTotal = true,
    this.source,
    this.notes = const [],
    this.caveats = const [],
    super.anchor,
    super.ownPaletteArgb,
  });

  factory ScoreBlock.fromYaml(Map<dynamic, dynamic> map) => ScoreBlock(
    title: map['title'] as String?,
    unit: (map['unit'] as String?) ?? 'points',
    showTotal: (map['show_total'] as bool?) ?? true,
    source: map['source'] as String?,
    items: _mapList(map['items'], ScoreItem.fromYaml),
    bands: _mapList(map['bands'], ScoreBand.fromYaml),
    notes: _stringList(map['notes']),
    caveats: _stringList(map['caveats']),
    anchor: map['anchor'] as String?,
    ownPaletteArgb: _parsePaletteArgb(map['palette']),
  );

  final String? title;
  final String unit;

  /// Whether the summed total is displayed. A decision TREE encoded as
  /// weighted points (PECARN: any high-risk predictor outranks every
  /// intermediate one) resolves to a band, but its point total means nothing
  /// to a reader, so such blocks set `show_total: false` and show only the band.
  final bool showTotal;

  /// Provenance of the score — required for clinical safety (shown as source).
  final String? source;

  final List<ScoreItem> items;
  final List<ScoreBand> bands;
  final List<String> notes;
  final List<String> caveats;
}

// ─────────────────────────────────────────────────────────────
// TOPIC (root)
// ─────────────────────────────────────────────────────────────

/// One page within a [Topic]. Maps to a single source-PDF page.
/// [pageNumber] is the printed page number on that page; surfaces in
/// the header badge and the page-break divider when scrolling past it.
class TopicPage {
  const TopicPage({required this.blocks, this.pageNumber});

  factory TopicPage.fromYaml(Map<dynamic, dynamic> map) => TopicPage(
    pageNumber: map['page_number'] as int?,
    blocks: _mapList(map['blocks'], Block.fromYaml),
  );

  final int? pageNumber;
  final List<Block> blocks;
}

/// How a topic's [TopicPage]s are presented to the reader.
///
/// [scroll] — one continuous free-scrolling column (the default; best for
/// mostly-prose topics). [paged] — "sticky" pages that snap one full screen at
/// a time (best for a protocol whose flowchart page and prose page should each
/// own a screen). Each [paged] page is expected to fit one screen.
enum TopicLayout {
  scroll,
  paged;

  static TopicLayout fromString(String? s) =>
      s == 'paged' ? TopicLayout.paged : TopicLayout.scroll;
}

/// A clinical quick-reference topic — one or more [TopicPage]s.
///
/// YAML may express a topic in two forms:
///   1. Top-level `pages:` (preferred) — each page has its own
///      `page_number` and `blocks`.
///   2. Top-level `blocks:` + `page_number` (legacy single-page form).
///      Parsed into a single [TopicPage] for uniform rendering.
class Topic {
  const Topic({
    required this.id,
    required this.title,
    required this.pages,
    this.version,
    this.lastReviewed,
    this.tags = const [],
    this.aliases = const [],
    this.category = TopicCategory.universal,
    this.ownPaletteArgb = const {},
    this.layout = TopicLayout.scroll,
  });

  /// Parse from a YAML string (e.g., loaded from an asset file).
  factory Topic.fromYamlString(String yamlString) {
    final doc = loadYaml(yamlString) as YamlMap;
    return Topic.fromYaml(doc['topic'] as Map);
  }

  factory Topic.fromYaml(Map<dynamic, dynamic> map) {
    final rawPages = map['pages'];
    final pages = rawPages != null
        ? _mapList(rawPages, TopicPage.fromYaml)
        : <TopicPage>[
            TopicPage(
              pageNumber: map['page_number'] as int?,
              blocks: _mapList(map['blocks'], Block.fromYaml),
            ),
          ];
    return Topic(
      id: map['id'] as String,
      title: map['title'] as String,
      version: map['version'] as String?,
      lastReviewed: map['last_reviewed'] as String?,
      tags: _stringList(map['tags']),
      aliases: _stringList(map['aliases']),
      category: TopicCategory.fromString(map['category'] as String?),
      ownPaletteArgb: _parsePaletteArgb(map['palette']),
      pages: pages,
      layout: TopicLayout.fromString(map['layout'] as String?),
    );
  }

  final String id;
  final String title;
  final String? version;
  final String? lastReviewed;
  final List<String> tags;
  final List<String> aliases;
  final TopicCategory category;

  /// The topic's own `palette:` overrides as role → packed-ARGB ints
  /// (Flutter-free). This is only the innermost cascade layer a topic
  /// declares for itself; when opened inside a book the loader merges it
  /// over the book/chapter palette and the renderer uses that resolved
  /// map. For a standalone (pasted) topic, the renderer resolves from this
  /// alone over the defaults.
  final Map<String, int> ownPaletteArgb;

  final List<TopicPage> pages;

  /// Presentation mode — free [TopicLayout.scroll] (default) or sticky
  /// [TopicLayout.paged] (snap one screen per page).
  final TopicLayout layout;

  /// First page's [TopicPage.pageNumber]. Convenience for places that
  /// only need the topic's starting page number (e.g., TOC subtitles).
  int? get pageNumber => pages.isNotEmpty ? pages.first.pageNumber : null;

  /// Flattened blocks across all pages. Retained so callers that don't
  /// care about page boundaries (tests, search indexing) keep working.
  List<Block> get blocks => [for (final p in pages) ...p.blocks];
}

// ─────────────────────────────────────────────────────────────
// UTILITIES
// ─────────────────────────────────────────────────────────────

/// Slugifies a card's name into its default anchor: lowercase, every run of
/// non-alphanumerics collapsed to one hyphen, ends trimmed.
///
/// Drug and procedure cards get this for free (see [DrugCardBlock.fromYaml],
/// [ProcedureBlock.fromYaml]) so a `topic:<id>#<slug>` cross-reference can
/// reach one card out of fifty without every card being hand-anchored. The
/// print's own cross-references name the card ("Versed", "Needle Decompression"),
/// so the slug is derivable from the link text rather than invented.
///
///     '3% Saline'    → '3-saline'
///     'Afrin®'       → 'afrin'
///     'Epi 1:10,000' → 'epi-1-10-000'
String anchorSlug(String name) => name
    .toLowerCase()
    .replaceAll(RegExp('[^a-z0-9]+'), '-')
    .replaceAll(RegExp(r'^-+|-+$'), '');

List<String> _stringList(dynamic raw) {
  if (raw == null) return const [];
  if (raw is YamlList) return raw.map((e) => e as String).toList();
  if (raw is List) return raw.cast<String>();
  return const [];
}

/// Parses a `palette:` YAML map (role → hex string) into role → packed-ARGB
/// ints. Skips unparseable entries. Kept Flutter-free so the model has no
/// material dependency (the renderer converts ints → `Color`).
Map<String, int> _parsePaletteArgb(dynamic node) {
  if (node is! Map) return const {};
  final out = <String, int>{};
  node.forEach((k, v) {
    final argb = _parseHexArgb(v);
    if (argb != null) out['$k'] = argb;
  });
  return out;
}

/// Parses a `"0xAARRGGBB"` / `"0xRRGGBB"` / `"#RRGGBB"` color string to a
/// packed ARGB int (alpha defaults to opaque). Returns null if malformed.
int? _parseHexArgb(dynamic raw) {
  if (raw is! String) return null;
  var hex = raw.trim();
  if (hex.startsWith('0x') || hex.startsWith('0X')) hex = hex.substring(2);
  if (hex.startsWith('#')) hex = hex.substring(1);
  if (hex.length == 6) hex = 'FF$hex';
  if (hex.length != 8) return null;
  return int.tryParse(hex, radix: 16);
}

List<int> _intList(dynamic raw) {
  if (raw == null) return const [];
  final list = raw is YamlList ? raw.toList() : raw as List;
  return list.map((e) => (e as num).toInt()).toList();
}

List<double> _doubleList(dynamic raw) {
  if (raw == null) return const [];
  final list = raw is YamlList ? raw.toList() : raw as List;
  return list.map((e) => (e as num).toDouble()).toList();
}

/// Parses a `column_align:` list of `left`/`right`/`center` strings.
List<CellAlign> _alignList(dynamic raw) {
  if (raw == null) return const [];
  final list = raw is YamlList ? raw.toList() : raw as List;
  return list.map((e) => CellAlign.fromString(e as String?)).toList();
}

/// Parses a `column_tint:` list of hex color strings; an empty string or
/// unparseable entry becomes `null` (no tint for that column).
List<int?> _argbList(dynamic raw) {
  if (raw == null) return const [];
  final list = raw is YamlList ? raw.toList() : raw as List;
  return list.map(_parseHexArgb).toList();
}

/// Parses a `column_bar:` list of bools (non-`true` entries → false).
List<bool> _boolList(dynamic raw) {
  if (raw == null) return const [];
  final list = raw is YamlList ? raw.toList() : raw as List;
  return list.map((e) => e == true).toList();
}

/// [fromMap] applied to [raw] when it is present; null when the key is absent.
T? _mapOrNull<T>(dynamic raw, T Function(Map<dynamic, dynamic>) fromMap) =>
    raw == null ? null : fromMap(raw as Map);

List<T> _mapList<T>(
  dynamic raw,
  T Function(Map<dynamic, dynamic>) fromMap,
) {
  if (raw == null) return const [];
  final list = raw is YamlList ? raw.toList() : raw as List;
  return list.map((e) => fromMap(e as Map)).toList();
}
