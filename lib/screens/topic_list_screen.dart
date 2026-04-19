import 'package:flutter/material.dart';
import 'package:orbweaver/screens/topic_frame.dart';

/// Lists all bundled topics. Tapping one navigates to `TopicFrame`.
class TopicListScreen extends StatelessWidget {
  const TopicListScreen({super.key});

  static const _topics = <_TopicEntry>[
    _TopicEntry(
      title: 'Paediatric Triage of Sick Children',
      subtitle: 'Pocketbook p.12 · severity table',
      asset: 'assets/topics/pb_triage.yaml',
      category: 'medical',
    ),
    _TopicEntry(
      title: 'Paediatric Advanced Life Support',
      subtitle: 'Pocketbook p.13 · prose + severity flowchart',
      asset: 'assets/topics/pb_pals.yaml',
      category: 'medical',
    ),
    _TopicEntry(
      title: 'Adult Cardiac Arrest',
      subtitle: 'Pocketbook p.14 · asymmetric branches + callout',
      asset: 'assets/topics/pb_cardiac_arrest.yaml',
      category: 'medical',
    ),
    _TopicEntry(
      title: 'CPR Summary (Adults · Children · Infants)',
      subtitle: 'Pocketbook p.15 · comparison table with cell spans',
      asset: 'assets/topics/pb_cpr_summary.yaml',
      category: 'medical',
    ),
    _TopicEntry(
      title: 'Paediatric Emergency Weight Estimation',
      subtitle: 'Pocketbook p.16 · age/height → weight tables',
      asset: 'assets/topics/pb_weight_estimation.yaml',
      category: 'medical',
    ),
    _TopicEntry(
      title: 'Vital Rates — Percentiles by Age',
      subtitle: 'Pocketbook p.17 · RR and HR tables',
      asset: 'assets/topics/pb_vital_rates.yaml',
      category: 'medical',
    ),
    _TopicEntry(
      title: 'Girls — BP for Stature',
      subtitle: 'Pocketbook p.18 · tap-to-zoom chart',
      asset: 'assets/topics/pb_bp_girls.yaml',
      category: 'medical',
    ),
    _TopicEntry(
      title: 'Boys — BP for Stature',
      subtitle: 'Pocketbook p.19 · tap-to-zoom chart',
      asset: 'assets/topics/pb_bp_boys.yaml',
      category: 'medical',
    ),
    _TopicEntry(
      title: 'Resuscitation Medications',
      subtitle: 'Pocketbook p.20 · pediatric and adult dosing',
      asset: 'assets/topics/pb_resuscitation_meds.yaml',
      category: 'medical',
    ),
    _TopicEntry(
      title: 'Circulation / Shock',
      subtitle: 'WVEMS 2025-008 · severity flowchart',
      asset: 'assets/topics/wvems_2025_008.yaml',
      category: 'universal',
    ),
    _TopicEntry(
      title: 'Pediatric Meningitis Rx > 1 month',
      subtitle: 'Pocketbook p.55 · cascade flowchart',
      asset: 'assets/topics/pb_meningitis.yaml',
      category: 'medical',
    ),
    _TopicEntry(
      title: 'Triage of All Sick Children',
      subtitle: 'WHO IMCI Chart 2 · severity table',
      asset: 'assets/topics/who_triage_chart2.yaml',
      category: 'medical',
    ),
    _TopicEntry(
      title: 'Drug Reference: A',
      subtitle: 'WVEMS p.120 · drug cards',
      asset: 'assets/topics/wvems_drug_ref_a.yaml',
      category: 'universal',
    ),
    _TopicEntry(
      title: 'All Block Types Demo',
      subtitle: 'Smoke test · every block type',
      asset: 'assets/topics/demo_all_blocks.yaml',
      category: 'medical',
    ),
  ];

  static const _categoryColors = <String, Color>{
    'universal': Color(0xFF1E4E8C),
    'medical': Color(0xFF2E7D32),
    'trauma': Color(0xFFC55A11),
    'critical_care': Color(0xFF6A1B9A),
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEFEFEF),
      appBar: AppBar(
        title: const Text('Orbweaver'),
        backgroundColor: const Color(0xFF1E4E8C),
        foregroundColor: Colors.white,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: _topics.length,
        separatorBuilder: (context, index) => const SizedBox(height: 8),
        itemBuilder: (context, i) {
          final t = _topics[i];
          final color = _categoryColors[t.category] ?? Colors.grey;
          return Card(
            elevation: 2,
            child: ListTile(
              leading: Container(
                width: 6,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              title: Text(
                t.title,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
              subtitle: Text(
                t.subtitle,
                style: const TextStyle(fontSize: 12),
              ),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => TopicFrame(assetPath: t.asset),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _TopicEntry {
  const _TopicEntry({
    required this.title,
    required this.subtitle,
    required this.asset,
    required this.category,
  });

  final String title;
  final String subtitle;
  final String asset;
  final String category;
}
