import 'package:flutter/material.dart';

/// The named color palette, resolved through the **book → chapter → topic**
/// cascade. Every semantic ("attention") color the renderer draws is a named
/// *role* here — nothing is hardcoded at a use site. A `palette:` map in
/// YAML may override any role at the book, chapter (group), or topic level;
/// each level inherits from its parent and overrides per-role. An orphaned
/// (pasted) topic with no cascade falls back to [kRoleDefaults] + a neutral
/// accent.
///
/// Content can therefore re-skin anything ("call attention with colors as
/// desired") by overriding a role, or by defining its own custom-named role
/// and referencing it from an element.
///
/// Neutral structural chrome (app background, hairline dividers, placeholder
/// greys) is intentionally *not* a role — it stays a fixed constant.

/// Accent used when no palette in the cascade declares one.
const Color kNeutralAccent = Color(0xFF455A64);

/// Default color for every semantic role. The accent-derived roles
/// (`accent_fill`, `accent_branch`) are deliberately absent — they are
/// computed from the resolved `accent` unless a layer overrides them.
const Map<String, Color> kRoleDefaults = {
  'accent': kNeutralAccent,

  // Severity bands — header chip + body tile, three levels. The table
  // RowSeverity tints reuse the tile colors.
  'severity_mild_header': Color(0xFFC8E6C9),
  'severity_mild_tile': Color(0xFFE8F5E9),
  'severity_moderate_header': Color(0xFFFFE082),
  'severity_moderate_tile': Color(0xFFFFF8E1),
  'severity_severe_header': Color(0xFFFFCDD2),
  'severity_severe_tile': Color(0xFFFFEBEE),

  // Provider-level badges (WVEMS credentialing strip). Fills sampled from
  // the printed legend (p.2) and confirmed against all 363 body badges.
  //
  // The two `P`s are separate roles now that `ProviderLevel.criticalCare`
  // exists. `provider_paramedic` is the print's flat pink, which appears
  // exactly once in 166 pages (the legend); every body `P` is Critical Care
  // and takes the purple the print gives it. Before the split, one lavender
  // stood for both and the distinction was unrenderable.
  'provider_emt': Color(0xFFFFD966),
  'provider_intermediate': Color(0xFF6FA8DC),
  'provider_aemt': Color(0xFF93C47D),
  'provider_paramedic': Color(0xFFD5A6BD),
  'provider_critical_care': Color(0xFFAB91D8),
  'provider_any': Color(0xFFEFEFEF),

  // Dose-table population coding. In the printed book the *row fill* of a
  // dose strip is what says who the dose is for — adult rows stripe grey,
  // paediatric rows pink, on every chapter (verified by column scanline on
  // p.24, where an adult table sits directly above a paediatric one:
  // #EFEFEF/#D9D9D9 above #FFDCE2/#FFC0CB). Each population's stripe
  // restarts on its light colour. `pop_adult` / `pop_peds` are the *label*
  // colours — print sets them as a right-hand vertical tab in solid grey /
  // magenta with white text; the app keeps its full-width band and takes
  // the tab's colours.
  'pop_adult': Color(0xFF666666),
  'pop_peds': Color(0xFFD23282),
  'adult_row_light': Color(0xFFEFEFEF),
  'adult_row_dark': Color(0xFFD9D9D9),
  'peds_row_light': Color(0xFFFFDCE2),
  'peds_row_dark': Color(0xFFFFC0CB),

  // Population / credentialing content bands. The printed protocols tint a
  // whole run of prose to flag *who* it applies to: pink for paediatric
  // content (WVEMS PDF pp.11, 13, 79 — a pink band appears on 78 of the 166
  // pages) and lavender for Critical Care, i.e. credentialed providers only
  // (pp.5, 9, 11 — 54 pages). `*_rule` is the bracket down the band's left
  // edge: the peds bracket is the print's own 0xFFDA5798, measured on every
  // odd page 3–95. The CC bracket is an app addition — print gives the CC
  // band no bracket and no heading at all (verified p.11), but a bare tint
  // with no left edge is easy to miss on a phone, so the app keeps one and
  // draws it in the Critical-Care purple.
  'peds_band_fill': Color(0xFFFFC0CB),
  'peds_band_rule': Color(0xFFDA5798),
  'cc_band_fill': Color(0xFFD9D2E9),
  'cc_band_rule': Color(0xFF6A1B9A),

  // Warning callouts. The print's red octagon and purple trapezoid are the
  // same two swatches as the Broselow RED and PURPLE bands, so matching
  // them exactly keeps the book internally coherent.
  'warning_safety': Color(0xFFCC0000),
  'warning_caution': Color(0xFF674EA7),

  // Flow-chart shapes.
  'flow_decision': Color(0xFFE6B8AF),
  'flow_entry': Color(0xFFCFE2F3),
  'flow_convergence': Color(0xFFD9EAD3),
  // The Critical-Care sub-tile under a convergence node: one colour, one
  // meaning — the same lavender as the CC content band, outlined in black
  // like every other solid box in the print.
  'cc_link_fill': Color(0xFFD9D2E9),
  'cc_link_border': Color(0xFF000000),

  // Note / inset (e.g. dose-table caption, "consider" note).
  'note_fill': Color(0xFFFFFDE7),
  'note_border': Color(0xFFF9A825),
  'note_text': Color(0xFF5D4037),

  // Attention callout (prose `callout: true`). `dash_*` is the same card in
  // its *conditional* form (`dashed: true`); the print draws the two
  // differently — a firm box is a solid black outline on a neutral grey
  // fill, a conditional one is a #999999 dashed outline on a near-white
  // fill — so they are separate roles. Both default to the `alert` pair, so
  // a book that does not distinguish them looks exactly as it did.
  'alert': Color(0xFFF6A609),
  'alert_fill': Color(0xFFFFF6D6),
  'alert_text': Color(0xFFB9770A),

  // Procedure card. Print draws the title tile pure white inside the card's
  // black outline (verified p.100); the app had a cream hardcoded here.
  'procedure_header_fill': Color(0xFFFFFFFF),

  // Drug-reference card: the header band and the three content zones, all
  // sampled from the printed cards (pp.118-143). The Notes zone is cyan by
  // default and lavender only on a Critical-Care drug — one purple for both
  // is what destroyed the CC signal. `*_spine` is the darker strip the print
  // runs down the label edge of each zone.
  'drug_card_header': Color(0xFF3A5D64),
  'drug_use_fill': Color(0xFFD9EAD3),
  'drug_use_spine': Color(0xFFB6D7A8),
  'drug_caution_fill': Color(0xFFFFF2CC),
  'drug_caution_spine': Color(0xFFFFE599),
  'drug_notes_fill': Color(0xFFD0E0E3),
  'drug_notes_spine': Color(0xFFA4C2F4),
  'drug_notes_cc_fill': Color(0xFFD9D2E9),
  'drug_notes_cc_spine': Color(0xFFB4A7D6),

  // The page behind everything. Print washes every page in a ~3 % tint of
  // its chapter accent, which is what makes a white flow node or an #EFEFEF
  // box read as raised rather than as page; the app was pure white, so that
  // separation was lost. The default stays white — a book adopts a wash by
  // overriding this per chapter.
  'page_wash': Color(0xFFFFFFFF),

  // Danger / contraindication text, and the warn tier of a computed value
  // (score / formula output).
  'danger_text': Color(0xFFC62828),
  'formula_warn': Color(0xFFB26A00),
};

/// Parses a `palette:` YAML node into role → [Color] overrides. Each value
/// is a `"0xAARRGGBB"` / `"0xRRGGBB"` / `"#RRGGBB"` string. Unparseable
/// entries are skipped.
Map<String, Color> parsePaletteOverrides(dynamic node) {
  if (node is! Map) return const {};
  final out = <String, Color>{};
  node.forEach((k, v) {
    final c = parsePaletteColor(v);
    if (c != null) out['$k'] = c;
  });
  return out;
}

/// Parses a single hex color string to a [Color] (opaque if no alpha).
Color? parsePaletteColor(dynamic raw) {
  if (raw is! String) return null;
  var hex = raw.trim();
  if (hex.startsWith('0x') || hex.startsWith('0X')) hex = hex.substring(2);
  if (hex.startsWith('#')) hex = hex.substring(1);
  if (hex.length == 6) hex = 'FF$hex';
  if (hex.length != 8) return null;
  final v = int.tryParse(hex, radix: 16);
  return v == null ? null : Color(v);
}

/// Resolves the cascade: [kRoleDefaults] overlaid by each override [layers]
/// entry in order (book, then chapter, then topic), then derives the roles
/// that have no fixed default because they follow another role.
///
/// `accent_fill` / `accent_branch` follow the resolved `accent`, and so do
/// `node_border`, `section_rule`, `section_title` and `box_border` — which is
/// how every book drew that chrome before those roles existed. A book adopts
/// the printed book's *neutral* chrome (a #666666 bracket, black titles,
/// black outlines) by overriding them, and every other book keeps its
/// accent-tinted look untouched. `dash_*` likewise follows the `alert` pair,
/// so a book that does not distinguish a conditional box from a firm one is
/// unaffected.
Map<String, Color> resolvePalette(List<Map<String, Color>> layers) {
  final m = <String, Color>{...kRoleDefaults};
  for (final layer in layers) {
    m.addAll(layer);
  }
  final accent = m['accent'] ?? kNeutralAccent;
  m['accent_fill'] ??= _tint(accent);
  m['accent_branch'] ??= accent;
  m['node_border'] ??= accent;
  m['section_rule'] ??= accent;
  m['section_title'] ??= accent;
  // The pre-role behaviour of a boxed prose tile was the accent at 60 %.
  m['box_border'] ??= accent.withValues(alpha: 0.6);
  m['dash_rule'] ??= m['alert'] ?? kRoleDefaults['alert']!;
  m['dash_fill'] ??= m['alert_fill'] ?? kRoleDefaults['alert_fill']!;
  return m;
}

/// A light wash of [c] over white — the node-fill tint derived from accent.
Color _tint(Color c) =>
    Color.alphaBlend(c.withValues(alpha: 0.12), Colors.white);
