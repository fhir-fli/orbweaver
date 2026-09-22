import 'package:flutter/material.dart';
import 'package:orbweaver/theme/topic_theme.dart';

/// The card every interactive calculator block (score, formula, conversion)
/// sits in: an accent-tinted fill and border, the block's title, then the
/// block's own [body], then the notes, the caveats box and the source line
/// the model declares. The three blocks differ only in the body.
class CalculatorFrame extends StatelessWidget {
  const CalculatorFrame({
    required this.accent,
    required this.theme,
    required this.body,
    this.title,
    this.notes = const [],
    this.caveats = const [],
    this.source,
    super.key,
  });

  final Color accent;
  final TopicTheme theme;

  /// The block's interactive content, laid out between the title and the
  /// notes.
  final List<Widget> body;
  final String? title;
  final List<String> notes;
  final List<String> caveats;
  final String? source;

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: accent.withValues(alpha: 0.04),
      border: Border.all(color: accent.withValues(alpha: 0.5)),
      borderRadius: BorderRadius.circular(8),
    ),
    padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null)
          Text(
            title!,
            style: TextStyle(
              fontSize: 15.5,
              fontWeight: FontWeight.w800,
              color: accent,
            ),
          ),
        const SizedBox(height: 8),
        ...body,
        if (notes.isNotEmpty) ...[
          const SizedBox(height: 10),
          for (final n in notes)
            Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Text(
                n,
                style: const TextStyle(fontSize: 12, color: Colors.black87),
              ),
            ),
        ],
        if (caveats.isNotEmpty) ...[
          const SizedBox(height: 10),
          _CaveatsBox(caveats: caveats, theme: theme),
        ],
        if (source != null) ...[
          const SizedBox(height: 8),
          Text(
            'Source: $source',
            style: const TextStyle(fontSize: 10.5, color: Colors.black54),
          ),
        ],
      ],
    ),
  );
}

/// The alert-tinted box listing a calculator's caveats, one ⚠ line each.
class _CaveatsBox extends StatelessWidget {
  const _CaveatsBox({required this.caveats, required this.theme});

  final List<String> caveats;
  final TopicTheme theme;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
    decoration: BoxDecoration(
      color: theme.alertFill,
      border: Border.all(color: theme.alert, width: 1.2),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final c in caveats)
          Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: Text(
              '⚠ $c',
              style: TextStyle(
                fontSize: 12,
                color: theme.alertText,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    ),
  );
}
