import 'package:flutter/material.dart';

/// Renders a minimal subset of markdown as a vertical [Column]:
///   - `**bold**` inline emphasis
///   - `- ` bullet lines (two-space indent per nesting level)
///   - blank lines become paragraph gaps
///
/// Soft-wrapped source lines are JOINED into one logical line: only a
/// blank line or a new `- ` bullet starts a new unit, so a long bullet or
/// paragraph wrapped across several YAML lines flows and wraps to the
/// container width instead of breaking at each source newline. (This also
/// means a `**bold**` span may straddle a YAML line wrap safely.)
///
/// Used by both `ProseBlockView` and `MarkdownCell` inside tables.
/// Kept deliberately minimal — full GFM (links, headings, nested lists
/// deeper than one level, tables inside prose) is deferred until a topic
/// needs it.
class MiniMarkdown extends StatelessWidget {
  const MiniMarkdown({
    required this.markdown,
    this.fontSize = 14,
    this.height = 1.4,
    this.color,
    this.bulletColor,
    super.key,
  });

  final String markdown;
  final double fontSize;
  final double height;
  final Color? color;

  /// Color of the square bullet glyph. Defaults to the text color when
  /// null. Set to the topic accent so list markers carry the book's color.
  final Color? bulletColor;

  @override
  Widget build(BuildContext context) {
    // Strip trailing blank lines — YAML `|` block scalars always leave a
    // terminal newline, which otherwise renders as unwanted bottom
    // whitespace inside callouts.
    final rawLines = markdown.trimRight().split('\n');

    final children = <Widget>[];
    _Unit? current;

    void flush() {
      if (current != null) {
        children.add(
          _UnitLine(
            unit: current!,
            fontSize: fontSize,
            height: height,
            color: color ?? Colors.black87,
            bulletColor: bulletColor ?? color ?? Colors.black87,
          ),
        );
        current = null;
      }
    }

    for (final raw in rawLines) {
      final trimmed = raw.trim();
      if (trimmed.isEmpty) {
        flush();
        children.add(SizedBox(height: fontSize * 0.5));
        continue;
      }
      final leading = raw.length - raw.trimLeft().length;
      if (trimmed.startsWith('- ')) {
        // A new bullet at this indent level starts a new unit.
        flush();
        current = _Unit(
          level: leading ~/ 2,
          isBullet: true,
          text: trimmed.substring(2),
        );
      } else if (current != null) {
        // Continuation of the current bullet/paragraph — join with a space.
        current = current!.append(trimmed);
      } else {
        // Start of a plain paragraph.
        current = _Unit(level: leading ~/ 2, isBullet: false, text: trimmed);
      }
    }
    flush();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }
}

/// One logical line of markdown: a bullet or a paragraph, after soft-wrapped
/// source lines have been joined.
class _Unit {
  const _Unit({
    required this.level,
    required this.isBullet,
    required this.text,
  });

  final int level;
  final bool isBullet;
  final String text;

  _Unit append(String more) =>
      _Unit(level: level, isBullet: isBullet, text: '$text $more');
}

class _UnitLine extends StatelessWidget {
  const _UnitLine({
    required this.unit,
    required this.fontSize,
    required this.height,
    required this.color,
    required this.bulletColor,
  });

  final _Unit unit;
  final double fontSize;
  final double height;
  final Color color;
  final Color bulletColor;

  @override
  Widget build(BuildContext context) {
    final indent = unit.level * (fontSize * 0.9);
    final textStyle = TextStyle(fontSize: fontSize, height: height, color: color);
    final text = RichText(text: TextSpan(style: textStyle, children: _parseBold(unit.text)));

    if (!unit.isBullet) {
      return Padding(
        padding: EdgeInsets.only(left: indent, bottom: 2),
        child: text,
      );
    }

    // Bullet: square glyph + hanging-indent body so wrapped lines align
    // under the text, not under the marker.
    return Padding(
      padding: EdgeInsets.only(left: indent, bottom: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 7),
            child: Text(
              '▪',
              style: TextStyle(
                fontSize: fontSize * 0.95,
                height: height,
                fontWeight: FontWeight.w900,
                color: bulletColor,
              ),
            ),
          ),
          Expanded(child: text),
        ],
      ),
    );
  }

  List<InlineSpan> _parseBold(String text) {
    // Stash escaped asterisks (`\*`) behind a sentinel so they don't
    // participate in bold parsing, then restore as literal `*` in the
    // emitted spans.
    const sentinel = '';
    final stashed = text.replaceAll(r'\*', sentinel);
    final spans = <InlineSpan>[];
    final re = RegExp(r'\*\*(.+?)\*\*');
    var lastEnd = 0;
    for (final m in re.allMatches(stashed)) {
      if (m.start > lastEnd) {
        spans.add(TextSpan(
          text: stashed.substring(lastEnd, m.start).replaceAll(sentinel, '*'),
        ));
      }
      spans.add(
        TextSpan(
          text: m.group(1)!.replaceAll(sentinel, '*'),
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      );
      lastEnd = m.end;
    }
    if (lastEnd < stashed.length) {
      spans.add(TextSpan(
        text: stashed.substring(lastEnd).replaceAll(sentinel, '*'),
      ));
    }
    return spans;
  }
}
