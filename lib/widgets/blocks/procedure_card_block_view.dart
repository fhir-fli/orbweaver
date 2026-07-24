import 'package:flutter/material.dart';
import 'package:orbweaver/models/topic.dart';
import 'package:orbweaver/theme/topic_theme.dart';
import 'package:orbweaver/widgets/mini_markdown.dart';

/// Renders a [ProcedureBlock] as a WVEMS-style procedure card: a scope-badged
/// header (provider level E/A/I/P, or a neutral chip for basic/all-level) over
/// an auto-numbered step list, matching the printed Procedures section
/// (pp.96-109).
///
/// The raw [ProcedureBlock.steps] lines are parsed here via the block's prefix
/// mini-syntax into typed [_Step]s, then each is laid out with its own gutter
/// (number / bullet), optional inline scope chip + dashed emphasis, and optional
/// highlight band. Line text renders through [MiniMarkdown] so `**bold**` and
/// `[links](topic:...)` behave as they do elsewhere.
class ProcedureCardBlockView extends StatelessWidget {
  const ProcedureCardBlockView({
    required this.block,
    required this.theme,
    super.key,
  });

  final ProcedureBlock block;
  final TopicTheme theme;

  static const Color _headerBg = Color(0xFFF3EFE6);
  static const Color _highlightBg = Color(0xFFFBD5DE);
  static const Color _ccHighlightBg = Color(0xFFE3DCF2);
  static const Color _dashColor = Colors.black45;

  Color _scopeColor(String? scope) => switch (scope) {
        'E' => theme.providerEmt,
        'P' => theme.providerParamedic,
        'A' => theme.providerAls,
        'I' => theme.providerIntermediate,
        _ => theme.providerAny,
      };

  @override
  Widget build(BuildContext context) {
    final steps = _parse(block.steps);

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: theme.header, width: 1.5),
        borderRadius: BorderRadius.circular(10),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Scope-badged header.
          Container(
            color: _headerBg,
            padding: const EdgeInsets.fromLTRB(8, 6, 10, 6),
            decoration: BoxDecoration(
              color: _headerBg,
              border: Border(bottom: BorderSide(color: theme.header, width: 1.5)),
            ),
            child: Row(
              children: [
                _ScopeChip(
                    letter: block.scope, color: _scopeColor(block.scope), size: 26),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    block.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Steps.
          Padding(
            padding: const EdgeInsets.fromLTRB(6, 6, 8, 7),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final s in steps) _StepRow(step: s, theme: theme),
              ],
            ),
          ),
          if (block.imagePath != null) _ProcedureImage(path: block.imagePath!),
        ],
      ),
    );
  }

  List<_Step> _parse(List<String> raw) {
    final out = <_Step>[];
    var counter = 0;
    for (final original in raw) {
      var s = original;
      var highlight = false;
      var ccHighlight = false;
      var bullet = false;
      var note = false;
      var standalone = false;
      var dashed = false;
      String? label;
      String? scope;

      if (s.startsWith('!')) {
        highlight = true;
        s = s.substring(1).trimLeft();
      } else if (s.startsWith('^')) {
        ccHighlight = true;
        s = s.substring(1).trimLeft();
      }

      if (s.startsWith('NOTE:')) {
        note = true;
        s = s.substring(5).trimLeft();
      } else if (s.startsWith('~')) {
        standalone = true;
        s = s.substring(1).trimLeft();
      } else if (s.startsWith('- ')) {
        bullet = true;
        s = s.substring(2);
      } else if (s.startsWith('@')) {
        final sp = s.indexOf(' ');
        final lbl = sp < 0 ? s.substring(1) : s.substring(1, sp);
        label = lbl;
        final lead = RegExp(r'^\d+').firstMatch(lbl);
        if (lead != null) counter = int.parse(lead.group(0)!);
        s = sp < 0 ? '' : s.substring(sp + 1);
      } else {
        counter++;
        label = '$counter';
      }

      if (s.startsWith(':')) {
        dashed = true;
        s = s.substring(1).trimLeft();
      }

      final m = RegExp(r'^\[([EAIP])\]\s+').firstMatch(s);
      if (m != null) {
        scope = m.group(1);
        s = s.substring(m.end);
      }

      out.add(_Step(
        label: label,
        bullet: bullet,
        note: note,
        standalone: standalone,
        scope: scope,
        dashed: dashed,
        highlight: highlight,
        ccHighlight: ccHighlight,
        text: s,
      ));
    }
    return out;
  }
}

/// One parsed procedure step / sub-bullet / note.
class _Step {
  const _Step({
    required this.text,
    this.label,
    this.bullet = false,
    this.note = false,
    this.standalone = false,
    this.scope,
    this.dashed = false,
    this.highlight = false,
    this.ccHighlight = false,
  });

  /// Number label ("1", "2a") for a numbered step; null for bullets / notes.
  final String? label;
  final bool bullet;
  final bool note;
  final bool standalone;
  final String? scope;
  final bool dashed;
  final bool highlight;
  final bool ccHighlight;
  final String text;
}

class _StepRow extends StatelessWidget {
  const _StepRow({required this.step, required this.theme});

  final _Step step;
  final TopicTheme theme;

  Color _scopeColor(String? scope) => switch (scope) {
        'E' => theme.providerEmt,
        'P' => theme.providerParamedic,
        'A' => theme.providerAls,
        'I' => theme.providerIntermediate,
        _ => theme.providerAny,
      };

  @override
  Widget build(BuildContext context) {
    // NOTE paragraph: full-width, no gutter.
    if (step.note) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(4, 4, 2, 2),
        child: MiniMarkdown(
          markdown: '**NOTE:** ${step.text}',
          fontSize: 13.5,
          height: 1.3,
          linkColor: theme.header,
        ),
      );
    }

    final body = _body(context);

    final row = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _gutter(),
        Expanded(child: body),
      ],
    );

    if (step.highlight || step.ccHighlight) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 1),
        color: step.ccHighlight
            ? ProcedureCardBlockView._ccHighlightBg
            : ProcedureCardBlockView._highlightBg,
        padding: const EdgeInsets.symmetric(vertical: 1),
        child: row,
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: row,
    );
  }

  Widget _gutter() {
    if (step.label != null) {
      return SizedBox(
        width: 26,
        child: Padding(
          padding: const EdgeInsets.only(top: 1),
          child: Text(
            '${step.label}.',
            textAlign: TextAlign.right,
            style: const TextStyle(
                fontSize: 13.5, fontWeight: FontWeight.w700, color: Colors.black87),
          ),
        ),
      );
    }
    if (step.bullet) {
      // Indent sub-bullets under the number column, then a dash marker.
      return const Padding(
        padding: EdgeInsets.only(left: 26, top: 1, right: 2),
        child: Text('–',
            style: TextStyle(fontSize: 13.5, color: Colors.black54)),
      );
    }
    // Standalone scope note / list row — minimal indent, no marker.
    return const SizedBox(width: 4);
  }

  Widget _body(BuildContext context) {
    final text = MiniMarkdown(
      markdown: step.text,
      fontSize: 13.5,
      height: 1.3,
      linkColor: theme.header,
    );

    Widget content;
    if (step.scope != null) {
      content = Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1, right: 6),
            child: _ScopeChip(
                letter: step.scope, color: _scopeColor(step.scope), size: 19),
          ),
          Expanded(child: text),
        ],
      );
    } else {
      content = text;
    }

    if (step.dashed) {
      return Padding(
        padding: const EdgeInsets.only(left: 2, top: 1),
        child: CustomPaint(
          painter: _DashedBorderPainter(
              color: ProcedureCardBlockView._dashColor),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(6, 3, 6, 3),
            child: content,
          ),
        ),
      );
    }
    return Padding(padding: const EdgeInsets.only(left: 2), child: content);
  }
}

/// The provider-scope letter chip (E / A / I), or a blank neutral chip when the
/// procedure is basic / all-level (matching the printed grey index cells).
class _ScopeChip extends StatelessWidget {
  const _ScopeChip({required this.letter, required this.color, required this.size});

  final String? letter;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.black26),
      ),
      child: letter == null
          ? null
          : Text(
              letter!,
              style: TextStyle(
                fontSize: size * 0.62,
                fontWeight: FontWeight.w800,
                color: Colors.black87,
              ),
            ),
    );
  }
}

/// Optional bottom image (e.g. the Saline Lock blood-tube order photo).
class _ProcedureImage extends StatelessWidget {
  const _ProcedureImage({required this.path});
  final String path;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(4),
      child: Image.asset(
        path,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stack) => const SizedBox(
          height: 40,
          child: Center(
            child: Text('[image]',
                style: TextStyle(fontSize: 9, color: Colors.black38)),
          ),
        ),
      ),
    );
  }
}

/// Paints a rounded dashed rectangle around scope-gated notes.
class _DashedBorderPainter extends CustomPainter {
  _DashedBorderPainter({required this.color});

  final Color color;
  static const double radius = 6;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(radius),
    );
    final path = Path()..addRRect(rrect);
    const dash = 4.0;
    const gap = 3.0;
    for (final metric in path.computeMetrics()) {
      var dist = 0.0;
      while (dist < metric.length) {
        final len = (dist + dash).clamp(0.0, metric.length);
        canvas.drawPath(metric.extractPath(dist, len), paint);
        dist += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter old) => old.color != color;
}
