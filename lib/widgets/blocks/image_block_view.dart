import 'package:flutter/material.dart';
import 'package:orbweaver/models/topic.dart';
import 'package:orbweaver/theme/topic_theme.dart';

/// Renders an [ImageBlock] with an optional caption.
///
/// [ImageSize] maps to concrete widths; `full` stretches the block to the
/// column width. Missing/unloadable assets fall back to a labelled grey
/// placeholder so authoring can proceed before art is finalized.
///
/// Tapping the image opens a fullscreen zoomable viewer backed by an
/// [InteractiveViewer] — important for high-detail reference figures
/// (BP-for-Stature charts, growth curves) where the inline size can't
/// show every axis label legibly on a phone.
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

    final imageChild = Image.asset(
      block.path,
      errorBuilder: (context, error, stack) => _placeholder(width),
    );

    return Column(
      children: [
        GestureDetector(
          onTap: () => _openZoom(context),
          child: SizedBox(
            width: width == double.infinity ? null : width,
            child: imageChild,
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

  void _openZoom(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => _ZoomableImageView(
          path: block.path,
          caption: block.caption,
        ),
      ),
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

class _ZoomableImageView extends StatelessWidget {
  const _ZoomableImageView({required this.path, this.caption});

  final String path;
  final String? caption;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: caption == null
            ? null
            : Text(
                caption!,
                style: const TextStyle(fontSize: 12),
                overflow: TextOverflow.ellipsis,
              ),
      ),
      body: InteractiveViewer(
        maxScale: 6,
        child: Center(child: Image.asset(path)),
      ),
    );
  }
}
