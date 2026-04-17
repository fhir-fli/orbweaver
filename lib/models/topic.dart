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

enum ProviderLevel {
  als,
  emt,
  intermediate,
  any;

  static ProviderLevel fromString(String? s) => switch (s) {
        'A' => als,
        'E' => emt,
        'I' => intermediate,
        _ => any,
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
  cascade;

  static FlowchartVariant fromString(String? s) => switch (s) {
        'severity' => severity,
        'cascade' => cascade,
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
  });

  factory TopicAction.fromYaml(Map<dynamic, dynamic> map) => TopicAction(
        text: map['text'] as String,
        kind: ActionKind.fromString(map['kind'] as String?),
        providerLevel:
            ProviderLevel.fromString(map['provider_level'] as String?),
        timing: map['timing'] as String?,
        condition: map['condition'] as String?,
      );

  final String text;
  final ActionKind kind;
  final ProviderLevel providerLevel;
  final String? timing;
  final String? condition;
}

/// A single branch from the decision diamond in a severity flowchart.
///
/// [severity] tints the branch visually (WHO-IMCI palette — pink/yellow/green)
/// so branches are distinguishable at a glance without reading labels.
/// Reuses the same [RowSeverity] enum as table rows so the urgency language
/// stays consistent across block types.
class TopicBranch {
  const TopicBranch({
    required this.id,
    required this.label,
    this.criteria = const [],
    this.actions = const [],
    this.severity = RowSeverity.none,
  });

  factory TopicBranch.fromYaml(Map<dynamic, dynamic> map) => TopicBranch(
        id: map['id'] as String,
        label: map['label'] as String,
        criteria: _stringList(map['criteria']),
        actions: _mapList(map['actions'], TopicAction.fromYaml),
        severity: RowSeverity.fromString(map['severity'] as String?),
      );

  final String id;
  final String label;
  final List<String> criteria;
  final List<TopicAction> actions;
  final RowSeverity severity;
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
  });

  factory ConvergenceNode.fromYaml(Map<dynamic, dynamic> map) =>
      ConvergenceNode(
        text: map['text'] as String,
        shape: NodeShape.fromString(map['shape'] as String?),
        bullets: _mapList(map['bullets'], ConvergenceBullet.fromYaml),
        exits: _mapList(map['exits'], ConvergenceExit.fromYaml),
      );

  final String text;
  final NodeShape shape;
  final List<ConvergenceBullet> bullets;
  final List<ConvergenceExit> exits;
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
  const FlowNode({required this.text, required this.shape});

  factory FlowNode.fromYaml(Map<dynamic, dynamic> map) => FlowNode(
        text: map['text'] as String,
        shape: NodeShape.fromString(map['shape'] as String?),
      );

  final String text;
  final NodeShape shape;
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
class SeverityFlowchart {
  const SeverityFlowchart({
    required this.branches,
    this.entryChain = const [],
    this.decision,
    this.convergence,
    this.postConvergence,
    this.doseTable = const [],
  });

  factory SeverityFlowchart.fromYaml(Map<dynamic, dynamic> map) {
    final entryChain = <FlowNode>[];
    if (map['entry_chain'] != null) {
      entryChain.addAll(
        _mapList(map['entry_chain'], FlowNode.fromYaml),
      );
    } else if (map['entry'] != null) {
      entryChain.add(FlowNode.fromYaml(map['entry'] as Map));
    }
    return SeverityFlowchart(
      entryChain: entryChain,
      decision: map['decision'] != null
          ? FlowNode.fromYaml(map['decision'] as Map)
          : null,
      branches: _mapList(map['branches'], TopicBranch.fromYaml),
      convergence: map['convergence'] != null
          ? ConvergenceNode.fromYaml(map['convergence'] as Map)
          : null,
      postConvergence: map['post_convergence'] != null
          ? FlowNode.fromYaml(map['post_convergence'] as Map)
          : null,
      doseTable: _mapList(map['dose_table'], DoseRow.fromYaml),
    );
  }

  final List<FlowNode> entryChain;
  final FlowNode? decision;
  final List<TopicBranch> branches;
  final ConvergenceNode? convergence;
  final FlowNode? postConvergence;
  final List<DoseRow> doseTable;
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
        action: map['action'] != null
            ? TopicAction.fromYaml(map['action'] as Map)
            : null,
        actionAnswer: YesNo.fromString(map['action_answer'] as String?),
        continuation: map['continuation'] != null
            ? CascadeStep.fromYaml(map['continuation'] as Map)
            : null,
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
        terminalAction: map['terminal_action'] != null
            ? TopicAction.fromYaml(map['terminal_action'] as Map)
            : null,
        actionWidthFraction:
            (map['action_width'] as num?)?.toDouble() ?? 0.5,
      );

  final FlowNode entry;
  final CascadeStep root;
  final TopicAction? terminalAction;
  final double actionWidthFraction;
}

// ─────────────────────────────────────────────────────────────
// BLOCK HIERARCHY
// ─────────────────────────────────────────────────────────────

/// A single vertical section of a [Topic]. Sealed — add a case in every
/// `switch` on [Block] when a new variant is introduced.
sealed class Block {
  const Block();

  factory Block.fromYaml(Map<dynamic, dynamic> map) {
    final type = map['type'] as String?;
    return switch (type) {
      'prose' => ProseBlock.fromYaml(map),
      'flowchart' => FlowchartBlock.fromYaml(map),
      'table' => TableBlock.fromYaml(map),
      'drug_card' => DrugCardBlock.fromYaml(map),
      'image' => ImageBlock.fromYaml(map),
      _ => throw FormatException('Unknown block type: $type'),
    };
  }
}

/// Markdown-authored text block. Most content lives here.
///
/// [highlight] triggers a tinted container (e.g. pediatrics pink, callout
/// boxes). Details are a renderer concern.
class ProseBlock extends Block {
  const ProseBlock({
    required this.markdown,
    this.title,
    this.highlight = false,
  });

  factory ProseBlock.fromYaml(Map<dynamic, dynamic> map) => ProseBlock(
        title: map['title'] as String?,
        markdown: map['markdown'] as String,
        highlight: (map['highlight'] as bool?) ?? false,
      );

  final String? title;
  final String markdown;
  final bool highlight;
}

/// A flowchart in one of the supported variants.
///
/// Exactly one of [severity] or [cascade] is populated, selected by
/// [variant]. A third `cycle` variant was considered and rejected — cyclic
/// ACLS-style loops are expressed via [TopicAction.timing] and
/// [TopicAction.condition] on actions within the existing variants.
class FlowchartBlock extends Block {
  const FlowchartBlock({required this.variant, this.severity, this.cascade});

  factory FlowchartBlock.fromYaml(Map<dynamic, dynamic> map) {
    final variant = FlowchartVariant.fromString(map['variant'] as String?);
    return switch (variant) {
      FlowchartVariant.severity => FlowchartBlock(
          variant: variant,
          severity: SeverityFlowchart.fromYaml(map),
        ),
      FlowchartVariant.cascade => FlowchartBlock(
          variant: variant,
          cascade: CascadeFlowchart.fromYaml(map),
        ),
    };
  }

  final FlowchartVariant variant;
  final SeverityFlowchart? severity;
  final CascadeFlowchart? cascade;
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
sealed class TableCell {
  const TableCell();

  factory TableCell.fromYaml(dynamic raw) {
    if (raw is String) {
      if (raw.contains('\n')) return MarkdownCell(raw);
      return TextCell(raw);
    }
    if (raw is YamlList) {
      return BulletCell(raw.map((e) => e as String).toList());
    }
    if (raw is List) return BulletCell(raw.cast<String>());
    return const TextCell('');
  }
}

class TextCell extends TableCell {
  const TextCell(this.text);
  final String text;
}

class BulletCell extends TableCell {
  const BulletCell(this.items);
  final List<String> items;
}

class MarkdownCell extends TableCell {
  const MarkdownCell(this.markdown);
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
  });

  factory TableBlock.fromYaml(Map<dynamic, dynamic> map) => TableBlock(
        title: map['title'] as String?,
        columns: _stringList(map['columns']),
        rows: _mapList(map['rows'], TopicTableRow.fromYaml),
      );

  final String? title;
  final List<String> columns;
  final List<TopicTableRow> rows;
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
      );

  final String name;
  final String? drugClass;
  final List<String> indications;
  final List<String> contraindications;
  final List<DrugDose> doses;
  final List<String> warnings;
  final List<String> pearls;
  final String? imagePath;
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
  });

  factory ImageBlock.fromYaml(Map<dynamic, dynamic> map) => ImageBlock(
        path: map['path'] as String,
        caption: map['caption'] as String?,
        size: ImageSize.fromString(map['size'] as String?),
      );

  final String path;
  final String? caption;
  final ImageSize size;
}

// ─────────────────────────────────────────────────────────────
// TOPIC (root)
// ─────────────────────────────────────────────────────────────

/// A clinical quick-reference topic — a stack of [Block]s plus metadata.
class Topic {
  const Topic({
    required this.id,
    required this.title,
    required this.blocks,
    this.version,
    this.lastReviewed,
    this.tags = const [],
    this.aliases = const [],
    this.category = TopicCategory.universal,
    this.pageNumber,
  });

  /// Parse from a YAML string (e.g., loaded from an asset file).
  factory Topic.fromYamlString(String yamlString) {
    final doc = loadYaml(yamlString) as YamlMap;
    return Topic.fromYaml(doc['topic'] as Map);
  }

  factory Topic.fromYaml(Map<dynamic, dynamic> map) => Topic(
        id: map['id'] as String,
        title: map['title'] as String,
        version: map['version'] as String?,
        lastReviewed: map['last_reviewed'] as String?,
        tags: _stringList(map['tags']),
        aliases: _stringList(map['aliases']),
        category: TopicCategory.fromString(map['category'] as String?),
        pageNumber: map['page_number'] as int?,
        blocks: _mapList(map['blocks'], Block.fromYaml),
      );

  final String id;
  final String title;
  final String? version;
  final String? lastReviewed;
  final List<String> tags;
  final List<String> aliases;
  final TopicCategory category;
  final int? pageNumber;
  final List<Block> blocks;
}

// ─────────────────────────────────────────────────────────────
// UTILITIES
// ─────────────────────────────────────────────────────────────

List<String> _stringList(dynamic raw) {
  if (raw == null) return const [];
  if (raw is YamlList) return raw.map((e) => e as String).toList();
  if (raw is List) return raw.cast<String>();
  return const [];
}

List<T> _mapList<T>(
  dynamic raw,
  T Function(Map<dynamic, dynamic>) fromMap,
) {
  if (raw == null) return const [];
  final list = raw is YamlList ? raw.toList() : raw as List;
  return list.map((e) => fromMap(e as Map)).toList();
}
