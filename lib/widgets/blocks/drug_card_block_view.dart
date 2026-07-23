import 'package:flutter/material.dart';
import 'package:orbweaver/models/topic.dart';
import 'package:orbweaver/theme/topic_theme.dart';
import 'package:orbweaver/widgets/mini_markdown.dart';

/// Renders a [DrugCardBlock] as the WVEMS-style drug card: a dark name header
/// over three colour-coded sections — **Use** (green), **Caution** (amber),
/// **Notes** (lavender) — each with a vertical side-label, plus an optional
/// medication photo beside the Use/Caution rows.
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

  static const _header = Color(0xFF3E5C6B);
  static const _useBg = Color(0xFFCDE9CD);
  static const _cautionBg = Color(0xFFFBE9BE);
  static const _notesBg = Color(0xFFE3D7F1);

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
          _Section(label: 'Use', bg: _useBg, markdown: use, accent: theme.header),
        if (cautionMd != null)
          _Section(
              label: 'Caution',
              bg: _cautionBg,
              markdown: cautionMd,
              accent: theme.header),
      ],
    );

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: _header, width: 1.5),
        borderRadius: BorderRadius.circular(10),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Name header.
          Container(
            color: _header,
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
                          color: Colors.white70, fontSize: 12.5),
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
                bg: _notesBg,
                markdown: notesMd,
                accent: theme.header),
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
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(left: BorderSide(color: Color(0xFF3E5C6B), width: 1.5)),
      ),
      padding: const EdgeInsets.all(4),
      child: Image.asset(
        path,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stack) => const Center(
          child: Text('[photo]',
              style: TextStyle(fontSize: 9, color: Colors.black38)),
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
    required this.markdown,
    required this.accent,
  });

  final String label;
  final Color bg;
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
              decoration: const BoxDecoration(
                border: Border(right: BorderSide(color: Colors.black26)),
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
