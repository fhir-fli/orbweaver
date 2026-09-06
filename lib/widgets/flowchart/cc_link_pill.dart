import 'package:flutter/material.dart';
import 'package:orbweaver/data/library_scope.dart';
import 'package:orbweaver/models/topic.dart';
import 'package:orbweaver/theme/topic_theme.dart';
import 'package:orbweaver/widgets/flowchart/flow_link.dart';

/// The lavender Critical-Care tab the WVEMS print fuses under a node: the
/// same disposition, for a credentialed provider. Hung under a flowchart's
/// convergence / post-convergence, and under a prose section on the two
/// pages (p.6, p.62) where the print puts it there.
class CriticalCareLinkPill extends StatelessWidget {
  const CriticalCareLinkPill({required this.link, super.key});

  final CriticalCareLink link;

  @override
  Widget build(BuildContext context) {
    final theme = TopicThemeScope.of(context);
    // A tab fused to the stadium above it: square top corners so the two
    // read as one node, rounded bottom ones, and no top border where they
    // meet. The print draws it that way because the band is not a next step
    // — it is the same disposition, for a credentialed provider.
    final pill = Center(
      child: Container(
        padding: const EdgeInsets.fromLTRB(22, 4, 22, 6),
        decoration: BoxDecoration(
          color: theme.ccLinkFill,
          border: Border(
            left: BorderSide(color: theme.ccLinkBorder, width: 1.5),
            right: BorderSide(color: theme.ccLinkBorder, width: 1.5),
            bottom: BorderSide(color: theme.ccLinkBorder, width: 1.5),
          ),
          borderRadius: const BorderRadius.vertical(
            bottom: Radius.circular(14),
          ),
        ),
        child: FlowLinkText(
          link.text,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
            decoration: link.linkId != null ? TextDecoration.underline : null,
          ),
        ),
      ),
    );
    if (link.linkId == null) return pill;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => openLinkedTopic(context, link.linkId!),
      child: pill,
    );
  }
}
