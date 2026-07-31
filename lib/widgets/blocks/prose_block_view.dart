import 'package:flutter/material.dart';
import 'package:orbweaver/models/topic.dart';
import 'package:orbweaver/theme/topic_theme.dart';
import 'package:orbweaver/widgets/mini_markdown.dart';
import 'package:orbweaver/widgets/section_bracket.dart';

/// Line height for prose bodies. The printed protocols run a 50-56 px line
/// pitch at 150 dpi against 47-50 px of ink (measured on PDF pp.11 and 71)
/// — a leading ratio of roughly 1.06. 1.18 keeps nearly all of that
/// density while leaving a little air for underlined links and mixed
/// weights on a backlit screen. Tight leading is how the print fits five
/// sections on a page, and buying that height back is what lets the paged
/// fit-scaler run nearer 1.0, so the text ends up *larger* on screen.
const double kProseLineHeight = 1.18;

/// Gap below each bullet / paragraph. The print puts no extra space
/// between bullets at all (its bullet-to-bullet pitch equals its
/// within-bullet wrap pitch), so this is 1 px purely so adjacent
/// underlined links never touch.
const double kProseUnitSpacing = 1;

/// Renders a [ProseBlock] using the minimal markdown subset in
/// [MiniMarkdown]. All colors come from the resolved [theme]: `accent`
/// (= `theme.header`) tints the section title, square bullets, and the
/// highlight rule; the `alert` roles color the attention callout.
class ProseBlockView extends StatelessWidget {
  const ProseBlockView({
    required this.block,
    required this.theme,
    super.key,
  });

  final ProseBlock block;
  final TopicTheme theme;

  @override
  Widget build(BuildContext context) {
    final accent = theme.header;
    // Boxed prose — a rounded-border tile matching boxed-layout table
    // cells.  Untitled: acts as a flow-grid cell inside a RowBlock
    // (centered text, tight padding).  Titled: a labelled criteria panel
    // (bold accent header + left-aligned body), e.g. the WVEMS Termination
    // "Special Cases / ALS / BLS" boxes.
    if (block.boxed) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          border: Border.all(color: theme.nodeBorder.withValues(alpha: 0.6)),
          borderRadius: BorderRadius.circular(4),
        ),
        alignment: block.title == null ? Alignment.center : null,
        child: block.title == null
            ? MiniMarkdown(markdown: block.markdown)
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 3),
                    child: Text(
                      block.title!,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: accent,
                      ),
                    ),
                  ),
                  MiniMarkdown(markdown: block.markdown),
                ],
              ),
      );
    }

    if (block.callout) {
      // Attention callout: a bright amber card with the title as a solid
      // amber chip on top — meant to draw the eye (e.g. "Act now"). Sized
      // to content and centered so it reads as an inset, not a section.
      //
      // `dashed:` swaps the solid outline for a dashed one, which is the
      // print's distinction between a *conditional* box and a firm one:
      // PDF p.71 draws the "If Major Intervention / Call a TRAUMA Alert"
      // box dashed while the "ABLS rate:" box beside it is solid, and p.43
      // dashes the conditional peds Versed sub-box the same way.
      return Align(
        alignment: Alignment.center,
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
          decoration: BoxDecoration(
            color: theme.alertFill,
            border: block.dashed
                ? null
                : Border.all(color: theme.alert, width: 1.4),
            borderRadius: BorderRadius.circular(10),
          ),
          foregroundDecoration: block.dashed
              ? _DashedRoundedBorder(color: theme.alert, width: 1.4)
              : null,
          child: IntrinsicWidth(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (block.title != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: theme.alert,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      block.title!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                const SizedBox(height: 8),
                DefaultTextStyle.merge(
                  textAlign: TextAlign.center,
                  child: MiniMarkdown(
                    markdown: block.markdown,
                    bulletColor: theme.alertText,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final markdown = MiniMarkdown(
      markdown: block.markdown,
      bulletColor: accent,
      height: kProseLineHeight,
      unitSpacing: kProseUnitSpacing,
    );

    // Untitled prose is just the text — nothing to bracket.
    if (block.title == null) return markdown;

    // Titled prose is a printed *section*: a `[` bracket down the left
    // with the title in the gap after its top arm, and the body running
    // the full width (see SectionBracket). `highlight:` only decides
    // whether the body carries a faint accent tint — it deliberately adds
    // no padding, because five sections a page means every pixel of
    // section chrome is paid five times over.
    return SectionBracket(
      color: accent,
      title: block.title,
      titleStyle: TextStyle(
        fontSize: 15.5,
        fontWeight: FontWeight.w800,
        color: accent,
        height: 1.2,
      ),
      bodyFill: block.highlight ? accent.withValues(alpha: 0.06) : null,
      child: markdown,
    );
  }
}

/// Dashed rounded-rectangle outline, used as a `foregroundDecoration` so it
/// draws over the fill without shifting layout. Walks the rounded-rect path
/// with [Path.computeMetrics] so the dashes wrap the corners evenly instead
/// of restarting on each side.
class _DashedRoundedBorder extends Decoration {
  const _DashedRoundedBorder({required this.color, required this.width});

  final Color color;
  final double width;

  /// Corner radius of the callout card this outlines.
  static const double radius = 10;

  /// Dash / gap lengths, matching the print's medium-dash outline.
  static const double dash = 5;
  static const double gap = 4;

  @override
  BoxPainter createBoxPainter([VoidCallback? onChanged]) =>
      _DashedBoxPainter(this);
}

class _DashedBoxPainter extends BoxPainter {
  _DashedBoxPainter(this.spec);

  final _DashedRoundedBorder spec;

  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration cfg) {
    final size = cfg.size;
    if (size == null) return;
    // Inset by half the stroke so the dashes sit inside the box, matching
    // where a solid `Border.all` would draw.
    final half = spec.width / 2;
    final rect = Rect.fromLTWH(
      offset.dx + half,
      offset.dy + half,
      size.width - spec.width,
      size.height - spec.width,
    );
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(_DashedRoundedBorder.radius)),
      );
    final paint = Paint()
      ..color = spec.color
      ..style = PaintingStyle.stroke
      ..strokeWidth = spec.width;
    for (final metric in path.computeMetrics()) {
      var d = 0.0;
      while (d < metric.length) {
        final end = d + _DashedRoundedBorder.dash;
        canvas.drawPath(
          metric.extractPath(d, end < metric.length ? end : metric.length),
          paint,
        );
        d = end + _DashedRoundedBorder.gap;
      }
    }
  }
}
