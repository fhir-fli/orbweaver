import 'package:flutter/material.dart';
import 'package:orbweaver/models/topic.dart';
import 'package:orbweaver/theme/topic_theme.dart';
import 'package:orbweaver/widgets/mini_markdown.dart';

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
    // cells, used when the block is acting as a flow-grid cell inside
    // a RowBlock.  Centered text, tight padding, no title banner.
    if (block.boxed) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(
          border: Border.all(color: theme.nodeBorder.withValues(alpha: 0.6)),
          borderRadius: BorderRadius.circular(4),
        ),
        alignment: Alignment.center,
        child: MiniMarkdown(markdown: block.markdown),
      );
    }

    if (block.callout) {
      // Attention callout: a bright amber card with the title as a solid
      // amber chip on top — meant to draw the eye (e.g. "Act now"). Sized
      // to content and centered so it reads as an inset, not a section.
      return Align(
        alignment: Alignment.center,
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
          decoration: BoxDecoration(
            color: theme.alertFill,
            border: Border.all(color: theme.alert, width: 1.4),
            borderRadius: BorderRadius.circular(10),
          ),
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

    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (block.title != null) ...[
          Text(
            block.title!,
            style: TextStyle(
              fontSize: 15.5,
              fontWeight: FontWeight.w800,
              color: accent,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 6),
        ],
        MiniMarkdown(markdown: block.markdown, bulletColor: accent),
      ],
    );

    if (!block.highlight) return body;

    // Highlight: a clean light card with a left accent rule, instead of a
    // heavy pink-bordered box. Sets key content apart without the WVEMS
    // look.
    return Container(
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.06),
        border: Border(left: BorderSide(color: accent, width: 4)),
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(6),
          bottomRight: Radius.circular(6),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(12, 10, 10, 12),
      child: body,
    );
  }
}
