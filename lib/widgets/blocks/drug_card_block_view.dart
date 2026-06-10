import 'package:flutter/material.dart';
import 'package:orbweaver/models/topic.dart';
import 'package:orbweaver/theme/topic_theme.dart';

/// Renders a [DrugCardBlock] as a bordered card with sectioned bullet
/// lists (Indications / Contraindications / Dose / Warnings / Pearls).
class DrugCardBlockView extends StatelessWidget {
  const DrugCardBlockView({
    required this.block,
    required this.theme,
    super.key,
  });

  final DrugCardBlock block;
  final TopicTheme theme;

  @override
  Widget build(BuildContext context) {
    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          block.name,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: theme.header,
          ),
        ),
        if (block.drugClass != null)
          Text(
            block.drugClass!,
            style: const TextStyle(
              fontSize: 11,
              fontStyle: FontStyle.italic,
              color: Colors.black54,
            ),
          ),
        if (block.indications.isNotEmpty)
          _BulletSection(
            label: 'Indications',
            items: block.indications,
            dangerColor: theme.dangerText,
          ),
        if (block.contraindications.isNotEmpty)
          _BulletSection(
            label: 'Contraindications',
            items: block.contraindications,
            dangerColor: theme.dangerText,
          ),
        if (block.doses.isNotEmpty) _DoseSection(doses: block.doses),
        if (block.warnings.isNotEmpty)
          _BulletSection(
            label: 'Warnings',
            items: block.warnings,
            dangerColor: theme.dangerText,
            emphasize: true,
          ),
        if (block.pearls.isNotEmpty)
          _BulletSection(
            label: 'Pearls',
            items: block.pearls,
            dangerColor: theme.dangerText,
          ),
      ],
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: theme.nodeFill,
        border: Border.all(color: theme.nodeBorder, width: 1.5),
      ),
      child: block.imagePath == null
          ? body
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: body),
                const SizedBox(width: 4),
                SizedBox(
                  width: 76,
                  child: Image.asset(
                    block.imagePath!,
                    errorBuilder: (context, error, stack) =>
                        _imagePlaceholder(),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _imagePlaceholder() => Container(
        height: 72,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F5),
          border: Border.all(color: const Color(0xFFBDBDBD)),
        ),
        padding: const EdgeInsets.all(3),
        child: Text(
          '[image missing]\n${block.imagePath}',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 8,
            color: Color(0xFF757575),
            fontStyle: FontStyle.italic,
          ),
        ),
      );
}

class _BulletSection extends StatelessWidget {
  const _BulletSection({
    required this.label,
    required this.items,
    required this.dangerColor,
    this.emphasize = false,
  });

  final String label;
  final List<String> items;
  final Color dangerColor;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: emphasize
                ? dangerColor
                : Colors.black.withValues(alpha: 0.75),
          ),
        ),
        for (final item in items)
          Padding(
            padding: const EdgeInsets.only(left: 6),
            child: Text(
              '• $item',
              style: const TextStyle(fontSize: 12, height: 1.2),
            ),
          ),
      ],
    );
  }
}

class _DoseSection extends StatelessWidget {
  const _DoseSection({required this.doses});

  final List<DrugDose> doses;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Dose',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: Colors.black.withValues(alpha: 0.75),
          ),
        ),
        for (final d in doses)
          Padding(
            padding: const EdgeInsets.only(left: 6),
            child: RichText(
              text: TextSpan(
                style: const TextStyle(
                  fontSize: 12,
                  height: 1.2,
                  color: Colors.black87,
                ),
                children: [
                  TextSpan(
                    text: '${_popLabel(d.population)}: ',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  TextSpan(text: d.text),
                ],
              ),
            ),
          ),
      ],
    );
  }

  String _popLabel(DosePopulation p) => switch (p) {
        DosePopulation.adult => 'Adult',
        DosePopulation.peds => 'Peds',
        DosePopulation.both => 'All',
      };
}
