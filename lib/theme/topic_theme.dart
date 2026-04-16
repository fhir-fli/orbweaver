import 'package:flutter/material.dart';
import 'package:orbweaver/models/topic.dart';

/// Visual theme derived from a [TopicCategory].
///
/// Colors match the WVEMS convention so content ingested from WVEMS PDFs
/// stays visually recognizable:
///   universal     → blue
///   medical       → green
///   trauma        → orange
///   critical_care → purple
class TopicTheme {
  const TopicTheme({
    required this.header,
    required this.nodeBorder,
    required this.nodeFill,
    required this.branchAccent,
  });

  factory TopicTheme.of(TopicCategory category) => switch (category) {
        TopicCategory.universal => const TopicTheme(
            header: Color(0xFF1E4E8C),
            nodeBorder: Color(0xFF1E4E8C),
            nodeFill: Color(0xFFE8F0FA),
            branchAccent: Color(0xFF2C6BB5),
          ),
        TopicCategory.medical => const TopicTheme(
            header: Color(0xFF2E7D32),
            nodeBorder: Color(0xFF2E7D32),
            nodeFill: Color(0xFFEAF4EB),
            branchAccent: Color(0xFF43A047),
          ),
        TopicCategory.trauma => const TopicTheme(
            header: Color(0xFFC55A11),
            nodeBorder: Color(0xFFC55A11),
            nodeFill: Color(0xFFFBEEE4),
            branchAccent: Color(0xFFE57324),
          ),
        TopicCategory.criticalCare => const TopicTheme(
            header: Color(0xFF6A1B9A),
            nodeBorder: Color(0xFF6A1B9A),
            nodeFill: Color(0xFFF1E7F6),
            branchAccent: Color(0xFF8E24AA),
          ),
      };

  final Color header;
  final Color nodeBorder;
  final Color nodeFill;
  final Color branchAccent;
}
