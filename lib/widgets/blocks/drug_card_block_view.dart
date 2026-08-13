import 'package:flutter/material.dart';
import 'package:orbweaver/models/topic.dart';
import 'package:orbweaver/theme/topic_theme.dart';
import 'package:orbweaver/widgets/mini_markdown.dart';

/// Renders a [DrugCardBlock] as the WVEMS-style drug card: a dark teal name
/// header over three colour-coded sections — **Use** (green), **Caution**
/// (amber), **Notes** (cyan, or lavender when the drug is Critical-Care
/// restricted) — each with a vertical side-label on the darker spine strip
/// the print draws, plus an optional medication photo beside the Use/Caution
/// rows.
///
/// Every fill is a palette role with the printed card's own value as its
/// default (pp.118-143). The Notes zone is the one that carries the CC
/// signal: print reserves lavender for CC drugs and gives every other drug
/// cyan, so colouring them all lavender — as this view used to — says every
/// drug is Critical Care.
///
/// Emphasis (bold) is authored in the content itself (e.g. a dose amount), not
/// applied to the labels — matching the printed cards, where the value is bold
/// and the "Adult:" / "Peds:" prefixes are not.
class DrugCardBlockView extends StatelessWidget {
  const DrugCardBlockView({
    required this.block,
    required this.theme,
    super.key,
  });

  final DrugCardBlock block;
  final TopicTheme theme;

  String? _useMd() {
    final lines = <String>[
      for (final i in block.indications) '- Tx: $i',
      for (final d in block.doses)
        d.population == DosePopulation.both
            ? '- ${d.text}'
            : '- ${_pop(d.population)}: ${d.text}',
    ];
    return lines.isEmpty ? null : lines.join('\n');
  }

  String? _bulletsMd(List<String> items) =>
      items.isEmpty ? null : [for (final i in items) '- $i'].join('\n');

  @override
  Widget build(BuildContext context) {
    final caution = [...block.contraindications, ...block.warnings];
    final use = _useMd();
    final cautionMd = _bulletsMd(caution);
    final notesMd = _bulletsMd(block.pearls);

    final topSections = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (use != null)
          _Section(
            label: 'Use',
            bg: theme.drugUseFill,
            spine: theme.drugUseSpine,
            markdown: use,
            accent: theme.header,
          ),
        if (cautionMd != null)
          _Section(
            label: 'Caution',
            bg: theme.drugCautionFill,
            spine: theme.drugCautionSpine,
            markdown: cautionMd,
            accent: theme.header,
          ),
      ],
    );

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: theme.drugCardHeader, width: 1.5),
        borderRadius: BorderRadius.circular(10),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Name header.
          Container(
            color: theme.drugCardHeader,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Flexible(
                  child: Text(
                    block.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                if (block.drugClass != null) ...[
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      block.drugClass!,
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12.5,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          // Use + Caution, with the medication photo beside them.
          if (block.imagePath != null)
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: topSections),
                  _DrugImage(path: block.imagePath!),
                ],
              ),
            )
          else
            topSections,
          if (notesMd != null)
            _Section(
              label: 'Notes',
              bg: block.criticalCare
                  ? theme.drugNotesCcFill
                  : theme.drugNotesFill,
              spine: block.criticalCare
                  ? theme.drugNotesCcSpine
                  : theme.drugNotesSpine,
              markdown: notesMd,
              accent: theme.header,
            ),
        ],
      ),
    );
  }

  String _pop(DosePopulation p) => switch (p) {
    DosePopulation.adult => 'Adult',
    DosePopulation.peds => 'Peds',
    DosePopulation.both => '',
  };
}

/// The medication photo beside the Use/Caution rows.
class _DrugImage extends StatelessWidget {
  const _DrugImage({required this.path});
  final String path;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 108,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          left: BorderSide(
            color: TopicThemeScope.of(context).drugCardHeader,
            width: 1.5,
          ),
        ),
      ),
      padding: const EdgeInsets.all(4),
      child: Image.asset(
        path,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stack) => const Center(
          child: Text(
            '[photo]',
            style: TextStyle(fontSize: 9, color: Colors.black38),
          ),
        ),
      ),
    );
  }
}

/// One colour-coded drug-card section: a vertical side-label + a MiniMarkdown
/// body (so links in the notes stay tappable).
class _Section extends StatelessWidget {
  const _Section({
    required this.label,
    required this.bg,
    required this.spine,
    required this.markdown,
    required this.accent,
  });

  final String label;
  final Color bg;

  /// The darker strip the print runs down the label edge of each zone.
  final Color spine;
  final String markdown;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: bg,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 30,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: spine,
                border: const Border(
                  right: BorderSide(color: Colors.black26),
                ),
              ),
              child: RotatedBox(
                quarterTurns: 3,
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Colors.black87,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 5, 8, 5),
                child: MiniMarkdown(
                  markdown: markdown,
                  fontSize: 13,
                  height: 1.25,
                  bulletColor: Colors.black54,
                  linkColor: accent,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
