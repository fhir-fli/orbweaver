import 'package:flutter/services.dart' show rootBundle;
import 'package:orbweaver/models/topic.dart';

/// Loads a [Topic] from a bundled YAML asset.
Future<Topic> loadTopicAsset(String assetPath) async {
  final yaml = await rootBundle.loadString(assetPath);
  return Topic.fromYamlString(yaml);
}
