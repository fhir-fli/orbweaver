import 'package:yaml/yaml.dart';

/// A reusable **formulary** collection: a set of drug records that a
/// dedicated faceted view (`DrugIndexScreen`) presents three ways — A–Z,
/// by class, by indication — over one dataset. Loaded from a book's
/// `formulary.yaml` (see `assets/books/who_imci/formulary.yaml`).
///
/// The formulary is the first "collection" primitive: paper files a drug in
/// one place, but a phone can re-group the same records by any facet, so the
/// dataset is modelled once and the view re-slices it. Each drug's detail
/// body is a weight-band dose table + prose — the same material every other
/// book renders, just sourced from structured records rather than a topic
/// file per drug.
class Formulary {
  const Formulary({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.bands,
    required this.artBands,
    required this.facets,
    required this.classLabels,
    required this.classOrder,
    required this.indicationLabels,
    required this.indicationOrder,
    required this.drugs,
    this.intro,
  });

  final String id;
  final String title;
  final String subtitle;

  /// Optional markdown shown once at the top of the A–Z list — used for a
  /// formulary's front-matter (e.g. the ProtocolBook age-designation and
  /// "dose BD" vs "dose ÷ BD" dosing conventions).
  final String? intro;

  /// The two dose axes: the main weight-band grid (most drugs) and the
  /// antiretroviral surface-area/weight grid (6 bands, morning & evening).
  final FormularyAxis bands;
  final FormularyAxis artBands;

  /// The toggle lenses, in display order.
  final List<FormularyFacet> facets;

  /// class key → display label, plus the key order (defines group order in
  /// the "by class" lens).
  final Map<String, String> classLabels;
  final List<String> classOrder;

  /// indication key → display label, plus key order (group order in the
  /// "by indication" lens).
  final Map<String, String> indicationLabels;
  final List<String> indicationOrder;

  final List<Drug> drugs;

  String classLabel(String key) => classLabels[key] ?? key;
  String indicationLabel(String key) => indicationLabels[key] ?? key;

  Drug? drugById(String id) {
    for (final d in drugs) {
      if (d.id == id) return d;
    }
    return null;
  }

  factory Formulary.fromYaml(YamlMap root) {
    final f = root['formulary'] as YamlMap;
    final bands = FormularyAxis.fromYaml(f['bands'] as YamlMap);
    final artBands = FormularyAxis.fromYaml(f['bands_art'] as YamlMap);

    final classLabels = <String, String>{};
    final classOrder = <String>[];
    for (final c in (f['classes'] as YamlList? ?? const [])) {
      final m = c as YamlMap;
      final key = m['key'] as String;
      classLabels[key] = m['label'] as String;
      classOrder.add(key);
    }

    final indLabels = <String, String>{};
    final indOrder = <String>[];
    for (final c in (f['indications'] as YamlList? ?? const [])) {
      final m = c as YamlMap;
      final key = m['key'] as String;
      indLabels[key] = m['label'] as String;
      indOrder.add(key);
    }

    final facets = [
      for (final x in (f['facets'] as YamlList? ?? const []))
        FormularyFacet.fromYaml(x as YamlMap),
    ];

    final drugs = <Drug>[];
    for (final x in (f['drugs'] as YamlList? ?? const [])) {
      final m = x as YamlMap;
      final axis = (m['axis'] as String?) == 'art' ? artBands : bands;
      drugs.add(Drug.fromYaml(m, axis));
    }

    return Formulary(
      id: f['id'] as String,
      title: f['title'] as String,
      subtitle: (f['subtitle'] as String?) ?? '',
      bands: bands,
      artBands: artBands,
      facets: facets,
      classLabels: classLabels,
      classOrder: classOrder,
      indicationLabels: indLabels,
      indicationOrder: indOrder,
      drugs: drugs,
      intro: f['intro'] as String?,
    );
  }
}

/// One dose axis: a header label plus the ordered band column headers.
class FormularyAxis {
  const FormularyAxis({required this.label, required this.columns});

  final String label;
  final List<String> columns;

  factory FormularyAxis.fromYaml(YamlMap m) => FormularyAxis(
        label: m['label'] as String,
        columns: [for (final c in m['columns'] as YamlList) c as String],
      );
}

/// One toggle lens. [mode] is `alpha` (flat A–Z) or `group` (grouped by
/// [field]). [tap] is `detail` (navigate to the drug page) or `expand`
/// (expand the indication slice in place).
class FormularyFacet {
  const FormularyFacet({
    required this.key,
    required this.label,
    required this.mode,
    required this.tap,
    this.field,
  });

  final String key;
  final String label;
  final String mode; // 'alpha' | 'group'
  final String tap; // 'detail' | 'expand'
  final String? field; // 'class' | 'indications' (for group mode)

  factory FormularyFacet.fromYaml(YamlMap m) => FormularyFacet(
        key: m['key'] as String,
        label: m['label'] as String,
        mode: m['mode'] as String,
        tap: m['tap'] as String,
        field: m['field'] as String?,
      );
}

/// One drug record. [bandColumns]/[bandLabel] are the resolved dose axis for
/// this drug (main or ART), copied in at load so the detail page is
/// self-contained. [daily] is set for antituberculosis drugs (dosed by daily
/// mg/kg, no band grid).
class Drug {
  const Drug({
    required this.id,
    required this.name,
    required this.className,
    required this.bandLabel,
    required this.bandColumns,
    this.subtitle = '',
    this.indications = const [],
    this.page,
    this.doses = const [],
    this.daily,
    this.dose,
    this.notes,
    this.regimen,
    this.review = false,
  });

  final String id;
  final String name;
  final String className;
  final String subtitle;
  final List<String> indications;
  final int? page;
  final List<DoseRow> doses;

  /// Antituberculosis daily dose (mg/kg), when there is no band grid.
  final String? daily;

  /// Free-form "dose & route" markdown, for prose-dose formularies (e.g. the
  /// ProtocolBook A–Z list) whose drugs are dosed by population / indication
  /// rather than a weight-band grid. Rendered as a MiniMarkdown card.
  final String? dose;

  /// Shared regimen line (antiretrovirals list it once above the forms).
  final String? regimen;
  final String? notes;

  /// Indication came from the EMLc fallback and awaits OpenEvidence review.
  final bool review;

  final String bandLabel;
  final List<String> bandColumns;

  /// [axis] is the shared axis this drug inherits (main or ART). A drug may
  /// override the header with `band_label` and/or supply its own
  /// `band_columns` when its weight bands differ from the shared axes (e.g.
  /// the antimalarial ACTs and the TB fixed-dose combination, which are
  /// dosed on their own bands). Overrides keep those doses honest instead of
  /// forcing them onto a mismatched grid.
  factory Drug.fromYaml(YamlMap m, FormularyAxis axis) {
    final ownColumns = m['band_columns'] as YamlList?;
    return Drug(
      id: m['id'] as String,
      name: m['name'] as String,
      className: m['class'] as String,
      subtitle: (m['subtitle'] as String?) ?? '',
      indications: [
        for (final i in m['indications'] as YamlList? ?? const []) i as String,
      ],
      page: m['page'] as int?,
      regimen: m['regimen'] as String?,
      daily: m['daily'] as String?,
      dose: m['dose'] as String?,
      notes: m['notes'] as String?,
      review: (m['review'] as bool?) ?? false,
      bandLabel: (m['band_label'] as String?) ?? axis.label,
      bandColumns: ownColumns != null
          ? [for (final c in ownColumns) c as String]
          : axis.columns,
      doses: [
        for (final d in m['doses'] as YamlList? ?? const [])
          DoseRow.fromYaml(d as YamlMap),
      ],
    );
  }

  /// The dose row most relevant to [indicationKey] (for the by-indication
  /// inline-expand): the first dose tagged with that indication, else the
  /// first dose.
  DoseRow? doseForIndication(String indicationKey) {
    for (final d in doses) {
      if (d.indication == indicationKey) return d;
    }
    return doses.isNotEmpty ? doses.first : null;
  }

  /// Free text folded into the search index (name, subtitle, every dose's
  /// label/regimen/form/bands, notes, daily).
  String get searchBlob {
    final b = StringBuffer()
      ..write('$name ')
      ..write('$subtitle ')
      ..write('${indications.join(' ')} ');
    if (regimen != null) b.write('$regimen ');
    if (daily != null) b.write('$daily ');
    if (dose != null) b.write('$dose ');
    for (final d in doses) {
      b
        ..write('${d.label} ')
        ..write('${d.regimen ?? ''} ')
        ..write('${d.form ?? ''} ')
        ..write('${d.bands.join(' ')} ');
    }
    if (notes != null) b.write('$notes ');
    return b.toString();
  }
}

/// One dose row within a drug: a [label] (form or indication or step),
/// optional [regimen]/[form] detail, and the per-band values.
class DoseRow {
  const DoseRow({
    required this.label,
    this.indication,
    this.regimen,
    this.form,
    this.bands = const [],
  });

  final String label;
  final String? indication;
  final String? regimen;
  final String? form;
  final List<String> bands;

  factory DoseRow.fromYaml(YamlMap m) => DoseRow(
        label: m['label'] as String,
        indication: m['indication'] as String?,
        regimen: m['regimen'] as String?,
        form: m['form'] as String?,
        bands: [for (final b in m['bands'] as YamlList? ?? const []) b as String],
      );
}
