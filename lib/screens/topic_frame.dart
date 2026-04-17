import 'package:flutter/material.dart';
import 'package:orbweaver/data/topic_loader.dart';
import 'package:orbweaver/models/topic.dart';
import 'package:orbweaver/widgets/topic_view.dart';

class TopicFrame extends StatelessWidget {
  const TopicFrame({required this.assetPath, super.key});

  final String assetPath;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Preview'),
        backgroundColor: const Color(0xFF1E4E8C),
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: FutureBuilder<Topic>(
          future: loadTopicAsset(assetPath),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Padding(
                padding: const EdgeInsets.all(16),
                child: Text('Error: ${snapshot.error}'),
              );
            }
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            return SingleChildScrollView(
              child: TopicView(topic: snapshot.data!),
            );
          },
        ),
      ),
    );
  }
}
