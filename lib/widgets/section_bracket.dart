import 'package:flutter/material.dart';
import 'package:orbweaver/widgets/scope_chip.dart';

/// The printed WVEMS section bracket — a `[` drawn down the left of a
/// section: a short arm right at the top with the title sitting in the gap
/// after it, the rule down the full height, and a matching arm at the
/// bottom. Body lines then run the **full** width, starting right at the
/// rule.
///
/// This is what the print uses for every section on every text page
/// (Imperatives / Medications / Notes / Pediatrics / References — see PDF
/// pp.11, 43, 71); it is deliberately not a full-width header bar, which
/// is what makes five sections fit on one printed page. Ordinary sections
/// draw the bracket in the topic accent, a population band draws it in the
/// band colour (pink for peds, purple for Critical Care).
///
/// Geometry measured off the source PDF at 150 dpi (p.71): the rule sits
/// 9 px from the text edge and is 7 px thick, the top/bottom arms run to
/// x = 62 (53 px long), and the title starts at x = 64-69. Scaled to the
/// 393-logical-px phone frame (393 / 1275) that is a 2.2 px rule, a 16 px
/// arm, and a title inset of ~20 px.
class SectionBracket extends StatelessWidget {
  const SectionBracket({
    required this.color,
    required this.child,
    this.title,
    this.titleStyle,
    this.bodyFill,
    super.key,
  });

  /// Bracket colour — the topic accent for an ordinary section, the band
  /// rule colour for a peds / Critical Care band.
  final Color color;

  /// Section body (usually a `MiniMarkdown`).
  final Widget child;

  /// Section label shown in the gap after the top arm. Null = no title,
  /// in which case the bracket still spans the body (the print's
  /// untitled tinted runs).
  final String? title;
  final TextStyle? titleStyle;

  /// Optional tint painted behind the **body only**, not the title — the
  /// print fills a peds band from below the heading down (p.71).
  final Color? bodyFill;

  /// Length of the top and bottom arms.
  static const double _arm = 16;

  /// Where the title starts: just past the arm.
  static const double _titleInset = 20;

  /// Where body lines start — a hair right of the rule, as in print,
  /// so bullets get essentially the full width.
  static const double _bodyInset = 4;

  static const double _stroke = 2;

  @override
  Widget build(BuildContext context) {
    final body = bodyFill == null
        ? child
        : ColoredBox(color: bodyFill!, child: child);
    return CustomPaint(
      painter: _BracketPainter(color: color, arm: _arm, stroke: _stroke),
      child: Padding(
        padding: const EdgeInsets.only(left: _bodyInset),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (title != null)
              Padding(
                padding: const EdgeInsets.only(left: _titleInset - _bodyInset),
                child: _Title(title: title!, style: titleStyle),
              ),
            body,
          ],
        ),
      ),
    );
  }
}

class _BracketPainter extends CustomPainter {
  const _BracketPainter({
    required this.color,
    required this.arm,
    required this.stroke,
  });

  final Color color;
  final double arm;
  final double stroke;

  @override
  void paint(Canvas canvas, Size size) {
    // Half the stroke width keeps the whole rule inside the section box
    // instead of straddling its edge.
    final inset = stroke / 2;
    final path = Path()
      ..moveTo(arm, inset)
      ..lineTo(inset, inset)
      ..lineTo(inset, size.height - inset)
      ..lineTo(arm, size.height - inset);
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeJoin = StrokeJoin.miter,
    );
  }

  @override
  bool shouldRepaint(_BracketPainter old) =>
      old.color != color || old.arm != arm || old.stroke != stroke;
}

/// A section heading, with the provider badge the print sets before it when
/// the title opens with a `{E}` token.
class _Title extends StatelessWidget {
  const _Title({required this.title, this.style});

  final String title;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final (level, rest) = splitLeadingScope(title);
    if (level == null) return Text(title, style: style);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ScopeChip(level: level, size: (style?.fontSize ?? 16) * 1.05),
        const SizedBox(width: 6),
        Flexible(child: Text(rest, style: style)),
      ],
    );
  }
}
