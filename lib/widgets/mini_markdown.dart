import 'package:flutter/material.dart';

/// Renders a minimal subset of markdown as a vertical [Column]:
///   - `**bold**` inline emphasis
///   - `- ` bullet lines (two-space indent per nesting level)
///   - blank lines become paragraph gaps
///
/// Used by both `ProseBlockView` and `MarkdownCell` inside tables.
/// Kept deliberately minimal — full GFM (links, headings, nested lists
/// deeper than one level, tables inside prose) is deferred until a
/// topic needs it. For now, a topic that needs full markdown can add
/// the `flutter_markdown` package and a new block type.
class MiniMarkdown extends StatelessWidget {
  const MiniMarkdown({
    required this.markdown,
    this.fontSize = 13,
    this.height = 1.1,
    this.color,
    super.key,
  });

  final String markdown;
  final double fontSize;
  final double height;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final lines = markdown.split('\n');
    final children = <Widget>[];
    for (final raw in lines) {
      if (raw.trim().isEmpty) {
        children.add(SizedBox(height: fontSize * 0.25));
        continue;
      }
      children.add(
        _MarkdownLine(
          raw: raw,
          fontSize: fontSize,
          height: height,
          color: color ?? Colors.black87,
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }
}

class _MarkdownLine extends StatelessWidget {
  const _MarkdownLine({
    required this.raw,
    required this.fontSize,
    required this.height,
    required this.color,
  });

  final String raw;
  final double fontSize;
  final double height;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final leading = raw.length - raw.trimLeft().length;
    final trimmed = raw.trim();
    final isBullet = trimmed.startsWith('- ');
    final content = isBullet ? trimmed.substring(2) : trimmed;
    final indent = (leading ~/ 2) * (fontSize * 0.8);

    return Padding(
      padding: EdgeInsets.only(left: indent),
      child: RichText(
        text: TextSpan(
          style: TextStyle(
            fontSize: fontSize,
            height: height,
            color: color,
          ),
          children: [
            if (isBullet) const TextSpan(text: '• '),
            ..._parseBold(content),
          ],
        ),
      ),
    );
  }

  List<InlineSpan> _parseBold(String text) {
    final spans = <InlineSpan>[];
    final re = RegExp(r'\*\*(.+?)\*\*');
    var lastEnd = 0;
    for (final m in re.allMatches(text)) {
      if (m.start > lastEnd) {
        spans.add(TextSpan(text: text.substring(lastEnd, m.start)));
      }
      spans.add(
        TextSpan(
          text: m.group(1),
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      );
      lastEnd = m.end;
    }
    if (lastEnd < text.length) {
      spans.add(TextSpan(text: text.substring(lastEnd)));
    }
    return spans;
  }
}
