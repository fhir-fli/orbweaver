import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:orbweaver/data/library_scope.dart';
import 'package:orbweaver/models/topic.dart';
import 'package:orbweaver/widgets/anchor_scope.dart';
import 'package:orbweaver/widgets/scope_chip.dart';
import 'package:orbweaver/widgets/unit_text.dart';
import 'package:url_launcher/url_launcher.dart';

/// Renders a minimal subset of markdown as a vertical [Column]:
///   - `{E}` / `{A}` / `{I}` / `{P}` / `{P(CC)}` / `{}` provider-scope badges
///   - `**bold**` inline emphasis
///   - `[text](target)` inline links (CommonMark). Targets:
///       `topic:<id>`  → open another topic (cross-book, by logical id)
///       `https://…`, `mailto:…` → open externally
///       `#<anchor>` → scroll this topic to the block with that `anchor:`
///       `topic:<id>#<anchor>` → open that topic scrolled to that block
///   - `- ` bullet lines (two-space indent per nesting level)
///   - blank lines become paragraph gaps
///
/// Soft-wrapped source lines are JOINED into one logical line: only a
/// blank line or a new `- ` bullet starts a new unit, so a long bullet or
/// paragraph wrapped across several YAML lines flows and wraps to the
/// container width instead of breaking at each source newline. (This also
/// means a `**bold**` span or a `[link](…)` may straddle a YAML line wrap.)
///
/// Stateful so the per-link [TapGestureRecognizer]s can be disposed.
class MiniMarkdown extends StatefulWidget {
  const MiniMarkdown({
    required this.markdown,
    this.fontSize = 14,
    this.height = 1.4,
    this.unitSpacing,
    this.color,
    this.bulletColor,
    this.linkColor,
    super.key,
  });

  final String markdown;
  final double fontSize;
  final double height;

  /// Vertical gap below each rendered unit (bullet or paragraph). Null
  /// keeps the historical 3 px / 2 px defaults.
  ///
  /// The printed protocols set bullets at the *same* pitch as a wrapped
  /// continuation line — there is no extra spacing between bullets at all
  /// (measured on PDF pp.11 and 71: 50-56 px pitch at 150 dpi, identical
  /// within a wrapped bullet and between bullets). Prose therefore passes
  /// a near-zero value; other call sites keep the looser default.
  final double? unitSpacing;

  final Color? color;

  /// Color of the square bullet glyph. Defaults to the text color when
  /// null. Set to the topic accent so list markers carry the book's color.
  final Color? bulletColor;

  /// Color of inline link text (always underlined). Defaults to
  /// [bulletColor] (the accent), else the text color.
  final Color? linkColor;

  @override
  State<MiniMarkdown> createState() => _MiniMarkdownState();
}

class _MiniMarkdownState extends State<MiniMarkdown> {
  /// Tap recognizers for the links built this frame — disposed and rebuilt
  /// on each build.
  final List<TapGestureRecognizer> _recognizers = [];

  @override
  void dispose() {
    _disposeRecognizers();
    super.dispose();
  }

  void _disposeRecognizers() {
    for (final r in _recognizers) {
      r.dispose();
    }
    _recognizers.clear();
  }

  void _onLinkTap(String target) {
    if (target.startsWith('topic:')) {
      final parts = target.substring(6).split('#');
      openLinkedTopic(
        context,
        parts.first,
        anchor: parts.length > 1 && parts[1].isNotEmpty ? parts[1] : null,
      );
    } else if (target.startsWith('#')) {
      AnchorScope.of(context)?.scrollTo(target.substring(1));
    } else {
      final uri = Uri.tryParse(target);
      if (uri != null) {
        launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    _disposeRecognizers();

    // Strip trailing blank lines — YAML `|` block scalars always leave a
    // terminal newline, which otherwise renders as unwanted bottom
    // whitespace inside callouts.
    final rawLines = widget.markdown.trimRight().split('\n');
    final color = widget.color ?? Colors.black87;
    final bulletColor = widget.bulletColor ?? color;
    final linkColor = widget.linkColor ?? widget.bulletColor ?? color;

    final children = <Widget>[];
    _Unit? current;

    void flush() {
      if (current != null) {
        children.add(
          _UnitLine(
            unit: current!,
            fontSize: widget.fontSize,
            height: widget.height,
            unitSpacing: widget.unitSpacing,
            color: color,
            bulletColor: bulletColor,
            spans: _parseInline(current!.text, linkColor),
          ),
        );
        current = null;
      }
    }

    for (final raw in rawLines) {
      final trimmed = raw.trim();
      if (trimmed.isEmpty) {
        flush();
        children.add(SizedBox(height: widget.fontSize * 0.5));
        continue;
      }
      final leading = raw.length - raw.trimLeft().length;
      if (trimmed.startsWith('- ')) {
        flush();
        current = _Unit(
          level: leading ~/ 2,
          isBullet: true,
          text: trimmed.substring(2),
        );
      } else if (current != null) {
        current = current!.append(trimmed);
      } else {
        current = _Unit(level: leading ~/ 2, isBullet: false, text: trimmed);
      }
    }
    flush();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }

  /// Parses `**bold**` and `[text](target)` in one pass, emitting plain
  /// runs between. Escaped asterisks (`\*`) are protected via a sentinel.
  List<InlineSpan> _parseInline(
    String text,
    Color linkColor, {
    bool bold = false,
  }) {
    const sentinel = '';
    final stashed = text.replaceAll(r'\*', sentinel);
    String restore(String s) => s.replaceAll(sentinel, '*');
    final plainStyle = bold
        ? const TextStyle(fontWeight: FontWeight.w700)
        : null;

    final spans = <InlineSpan>[];
    TextSpan linkSpan(String display, String target) {
      final recognizer = TapGestureRecognizer()
        ..onTap = () => _onLinkTap(target);
      _recognizers.add(recognizer);
      return TextSpan(
        text: display,
        style: TextStyle(
          color: linkColor,
          decoration: TextDecoration.underline,
          fontWeight: bold ? FontWeight.w700 : null,
        ),
        recognizer: recognizer,
      );
    }

    // Order matters: explicit `[text](target)` first, then bold, then a bare
    // URL (so a URL already inside a markdown link isn't matched twice), then
    // the provider-scope badge. Braces are used by none of the others, so the
    // badge token cannot collide with the link syntax.
    final re = RegExp(
      r'\[([^\]]+)\]\(([^)]+)\)|\*\*(.+?)\*\*|(https?://[^\s)\]]+)'
      r'|\{(E|A|I|P\(CC\)|P|CC)?\}',
    );
    var last = 0;
    for (final m in re.allMatches(stashed)) {
      if (m.start > last) {
        spans.addAll(
          unitAwareSpans(
            restore(stashed.substring(last, m.start)),
            plainStyle,
            widget.fontSize,
          ),
        );
      }
      if (m.group(2) != null) {
        // Explicit link: group(1) = display text, group(2) = target.
        spans.add(linkSpan(restore(m.group(1)!), restore(m.group(2)!)));
      } else if (m.group(3) != null) {
        // Bold: recurse into the inner content (still stashed) so any link
        // it contains is parsed too, not leaked as raw markup.
        spans.addAll(_parseInline(m.group(3)!, linkColor, bold: true));
      } else if (m.group(0)!.startsWith('{')) {
        // Provider-scope badge. The print sets these inline in prose and band
        // bullets 31 times across 21 pages — the place a reader looks for the
        // permission boundary — and the app had no way to draw one, so they
        // were authored as two bold characters.
        spans.add(
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Padding(
              padding: const EdgeInsets.only(right: 3),
              child: ScopeChip(
                level: ProviderLevel.fromString(m.group(5)),
                size: widget.fontSize * 1.15,
              ),
            ),
          ),
        );
      } else {
        // Bare URL: linkify it. Trailing sentence punctuation stays plain.
        var url = restore(m.group(4)!);
        var trailing = '';
        while (url.isNotEmpty && '.,;:!?'.contains(url[url.length - 1])) {
          trailing = '${url[url.length - 1]}$trailing';
          url = url.substring(0, url.length - 1);
        }
        spans.add(linkSpan(url, url));
        if (trailing.isNotEmpty) {
          spans.add(TextSpan(text: trailing, style: plainStyle));
        }
      }
      last = m.end;
    }
    if (last < stashed.length) {
      spans.addAll(
        unitAwareSpans(
          restore(stashed.substring(last)),
          plainStyle,
          widget.fontSize,
        ),
      );
    }
    return spans;
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

/// Layout for one unit: a bullet (square glyph + hanging-indent body) or a
/// paragraph. The inline [spans] are pre-parsed by the parent.
class _UnitLine extends StatelessWidget {
  const _UnitLine({
    required this.unit,
    required this.fontSize,
    required this.height,
    required this.unitSpacing,
    required this.color,
    required this.bulletColor,
    required this.spans,
  });

  final _Unit unit;
  final double fontSize;
  final double height;
  final double? unitSpacing;
  final Color color;
  final Color bulletColor;
  final List<InlineSpan> spans;

  /// The print marks the two levels with different glyphs — a round `•` at
  /// level 0 (717 instances) and a dash at level 1 (419) — rather than by
  /// indent alone. A sub-bullet sitting only ~13 px inboard is easy to lose
  /// under a level-0 bullet that has just wrapped, which is exactly when it
  /// matters. `•` / `–` rather than the print's exact glyphs: the app's old
  /// `▪` was already heavier than the print's dot, and a round dot reads
  /// better on a backlit screen.
  String get _glyph => unit.level == 0 ? '\u2022' : '\u2013';

  /// Space *below* this unit. Print sets 27.0 pt between two top-level
  /// bullets against 24.0 pt for a continuation or a sub-bullet — a
  /// 1.125 : 1.00 ratio the app had flattened to a single 1 px everywhere.
  double get _gapBelow {
    final base = unitSpacing ?? (unit.isBullet ? 3.0 : 2.0);
    return unit.level == 0 && unit.isBullet ? base + 1.5 : base;
  }

  @override
  Widget build(BuildContext context) {
    final indent = unit.level * (fontSize * 0.9);
    final textStyle = TextStyle(
      fontSize: fontSize,
      height: height,
      color: color,
    );
    // Text.rich (not RichText) so the ambient MediaQuery.textScaler applies —
    // this is what lets the paged fit-to-screen shrink prose to fit.
    final text = Text.rich(TextSpan(style: textStyle, children: spans));

    if (!unit.isBullet) {
      return Padding(
        padding: EdgeInsets.only(left: indent, bottom: _gapBelow),
        child: text,
      );
    }

    return Padding(
      padding: EdgeInsets.only(left: indent, bottom: _gapBelow),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 7),
            child: Text(
              _glyph,
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
}
