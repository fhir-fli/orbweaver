import 'package:flutter/material.dart';
import 'package:orbweaver/models/topic.dart';
import 'package:orbweaver/theme/topic_theme.dart';
import 'package:orbweaver/widgets/mini_markdown.dart';

/// Renders a [ProseBlock] using the minimal markdown subset implemented
/// in [MiniMarkdown]. Highlight blocks get a pink tinted container
/// (used for callouts and pediatric notes).
class ProseBlockView extends StatelessWidget {
  const ProseBlockView({required this.block, required this.theme, super.key});

  final ProseBlock block;
  final TopicTheme theme;

  @override
  Widget build(BuildContext context) {
    // Boxed prose — a rounded-border tile matching boxed-layout table
    // cells, used when the block is acting as a flow-grid cell inside
    // a RowBlock (e.g. p.22 malaria row 3: "Treat" / "Treat presumptively"
    // / "Don't treat").  Centered text, tight padding, no title banner.
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

    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (block.title != null)
          Text(
            block.title!,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: theme.header,
            ),
          ),
        MiniMarkdown(markdown: block.markdown),
      ],
    );

    if (!block.highlight) return body;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF0F5),
        border: Border.all(color: const Color(0xFFE57373)),
      ),
      child: body,
    );
  }
}
