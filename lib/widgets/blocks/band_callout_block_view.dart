import 'package:flutter/material.dart';
import 'package:orbweaver/models/topic.dart';
import 'package:orbweaver/theme/topic_theme.dart';
import 'package:orbweaver/widgets/blocks/prose_block_view.dart';
import 'package:orbweaver/widgets/mini_markdown.dart';
import 'package:orbweaver/widgets/section_bracket.dart';

/// Renders a [BandCalloutBlock] as the printed WVEMS population band: the
/// same `[` section bracket every other section gets, but drawn in the band
/// colour, with the **body** sitting on a tint (pink for paediatric
/// content, lavender for Critical Care).
///
/// This is exactly what the print does — PDF p.71's "Pediatrics" section
/// has a pink bracket and a pink band under a heading that sits on the bare
/// page, while its "Notes" and "References" sections above and below carry
/// the identical bracket in grey. Because the band is structurally the same
/// as a prose section, it costs the same vertical space and shares the
/// print's tight leading via [kProseLineHeight] / [kProseUnitSpacing].
///
/// Both colours come from palette roles (`peds_band_*` / `cc_band_*`),
/// never from constants here, so a book / chapter / topic / block may
/// re-skin them. Note the print sets its section titles in black and
/// carries the population signal purely in the bracket and band; here the
/// title takes the band colour too, so a peds band can never be mistaken
/// for its chapter accent (on Burns, for example, the accent is salmon
/// while the print's peds band is still pink).
class BandCalloutBlockView extends StatelessWidget {
  const BandCalloutBlockView({
    required this.block,
    required this.theme,
    super.key,
  });

  final BandCalloutBlock block;
  final TopicTheme theme;

  @override
  Widget build(BuildContext context) {
    final (fill, rule) = switch (block.band) {
      CalloutBand.peds => (theme.pedsBandFill, theme.pedsBandRule),
      CalloutBand.criticalCare => (theme.ccBandFill, theme.ccBandRule),
    };
    // Null title takes the print's section label ("Pediatrics" / "Critical
    // Care"); an explicit empty string means a bare tinted run with no
    // heading, which is how the print marks a single CC or peds line
    // sitting inside somebody else's section (p.11, p.79).
    final title = block.title ?? block.band.defaultTitle;

    return SectionBracket(
      color: rule,
      title: title.isEmpty ? null : title,
      titleStyle: TextStyle(
        fontSize: kSectionTitleSize,
        fontWeight: FontWeight.w800,
        color: rule,
        height: 1.2,
      ),
      bodyFill: fill,
      // Links stay on the topic accent (as everywhere else); only the
      // bullet glyphs take the band colour, matching the print's coloured
      // bullets inside a tinted run.
      child: MiniMarkdown(
        markdown: block.markdown,
        bulletColor: rule,
        linkColor: theme.header,
        height: kProseLineHeight,
        unitSpacing: kProseUnitSpacing,
      ),
    );
  }
}
