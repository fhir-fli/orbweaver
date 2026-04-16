import 'package:flutter/material.dart';
import 'package:orbweaver/data/topic_loader.dart';
import 'package:orbweaver/models/topic.dart';
import 'package:orbweaver/widgets/topic_view.dart';

/// Development harness: renders a [Topic] inside a fixed 375x667 frame
/// (iPhone SE logical size) with a visible border, so "does it fit" is
/// answered at a glance.
class TopicFrame extends StatelessWidget {
  const TopicFrame({required this.assetPath, super.key});

  final String assetPath;

  static const double frameWidth = 375;
  static const double frameHeight = 667;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEFEFEF),
      appBar: AppBar(
        title: const Text('Preview'),
        backgroundColor: const Color(0xFF1E4E8C),
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        // Outer scroll so the frame can exceed the window bounds on small
        // desktops / dev displays without clipping the top of the content.
        child: SingleChildScrollView(
          child: Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: FutureBuilder<Topic>(
                future: loadTopicAsset(assetPath),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Text('Error: ${snapshot.error}');
                  }
                  if (!snapshot.hasData) {
                    return const CircularProgressIndicator();
                  }
                  return _Frame(topic: snapshot.data!);
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Frame extends StatelessWidget {
  const _Frame({required this.topic});

  final Topic topic;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: TopicFrame.frameWidth,
      height: TopicFrame.frameHeight,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.black54, width: 2),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: ClipRect(
          child: SingleChildScrollView(
            child: TopicView(topic: topic),
          ),
        ),
      ),
    );
  }
}
