import 'package:flutter/material.dart';
import 'package:orbweaver/screens/topic_frame.dart';

void main() {
  runApp(const OrbweaverApp());
}

class OrbweaverApp extends StatelessWidget {
  const OrbweaverApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Orbweaver',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const TopicFrame(
        assetPath: 'assets/topics/wvems_drug_ref_a.yaml',
      ),
    );
  }
}
