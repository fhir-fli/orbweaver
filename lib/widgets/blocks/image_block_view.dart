import 'package:flutter/material.dart';
import 'package:orbweaver/models/topic.dart';
import 'package:orbweaver/theme/topic_theme.dart';

/// Renders an [ImageBlock] with an optional caption.
///
/// [ImageSize] maps to concrete widths; `full` stretches the block to the
/// column width. Missing/unloadable assets fall back to a labelled grey
/// placeholder so authoring can proceed before art is finalized.
class ImageBlockView extends StatelessWidget {
  const ImageBlockView({required this.block, required this.theme, super.key});

  final ImageBlock block;
  final TopicTheme theme;

  @override
  Widget build(BuildContext context) {
    final width = switch (block.size) {
      ImageSize.small => 120.0,
      ImageSize.medium => 200.0,
      ImageSize.large => 300.0,
      ImageSize.full => double.infinity,
    };

    return Column(
      children: [
        SizedBox(
          width: width == double.infinity ? null : width,
          child: Image.asset(
            block.path,
            errorBuilder: (context, error, stack) => _placeholder(width),
          ),
        ),
        if (block.caption != null)
          Padding(
            padding: const EdgeInsets.only(top: 3),
            child: Text(
              block.caption!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 9,
                fontStyle: FontStyle.italic,
                color: Colors.black54,
              ),
            ),
          ),
      ],
    );
  }

  Widget _placeholder(double width) {
    return Container(
      width: width == double.infinity ? null : width,
      height: 80,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        border: Border.all(color: const Color(0xFFBDBDBD)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Text(
          '[image missing]\n${block.path}',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 9,
            color: Color(0xFF757575),
            fontStyle: FontStyle.italic,
          ),
        ),
      ),
    );
  }
}
