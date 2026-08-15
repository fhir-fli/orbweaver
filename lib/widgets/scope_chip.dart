import 'package:flutter/material.dart';
import 'package:orbweaver/models/topic.dart';
import 'package:orbweaver/theme/topic_theme.dart';

/// The WVEMS provider-level badge: a small rounded square holding the
/// credential letter, filled by level.
///
/// The print draws this in five places — on a flow action tile, floated on a
/// procedure card's title, inline in a procedure step, inline in prose and
/// band bullets, and in the p.2 legend — so it lives here rather than inside
/// any one of them. 363 of them across 166 pages; they are the book's
/// permission boundary, not decoration.
class ScopeChip extends StatelessWidget {
  const ScopeChip({required this.level, this.size = 20, super.key});

  final ProviderLevel level;
  final double size;

  @override
  Widget build(BuildContext context) {
    final letter = level.letter;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: scopeFill(TopicThemeScope.of(context), level),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.black26),
      ),
      child: letter.isEmpty
          ? null
          : Text(
              letter,
              style: TextStyle(
                fontSize: size * 0.62,
                fontWeight: FontWeight.w800,
                color: Colors.black87,
                height: 1,
              ),
            ),
    );
  }
}

/// The printed fill for a credential level.
Color scopeFill(TopicTheme theme, ProviderLevel level) => switch (level) {
  ProviderLevel.emt => theme.providerEmt,
  ProviderLevel.intermediate => theme.providerIntermediate,
  ProviderLevel.aemt => theme.providerAemt,
  ProviderLevel.paramedic => theme.providerParamedic,
  ProviderLevel.criticalCare => theme.providerCriticalCare,
  ProviderLevel.any => theme.providerAny,
};
