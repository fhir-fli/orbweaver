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

  // Provider-level badges (WVEMS credentialing strip).
  'provider_emt': Color(0xFFF2C24A),
  'provider_intermediate': Color(0xFF6FAADB),
  'provider_als': Color(0xFF7BBF86),
  'provider_paramedic': Color(0xFFAB91D8),
  'provider_any': Color(0xFFE0E0E0),

  // Dose-table population bands.
  'pop_adult': Color(0xFFD9D9D9),
  'pop_peds': Color(0xFFF8C9DA),

  // Population / credentialing content bands. The printed protocols tint a
  // whole run of prose to flag *who* it applies to: pink for paediatric
  // content (WVEMS PDF pp.11, 13, 79 — a pink band appears on 78 of the 166
  // pages) and lavender for Critical Care, i.e. credentialed providers only
  // (pp.5, 9, 11 — 54 pages). `*_rule` is the bracket the print draws down
  // the band's left edge; the peds bracket was sampled from the PDF at
  // 0xFFDA5798, the CC rule matches `cc_link_border` so every Critical Care
  // cue in the app reads as one colour.
  'peds_band_fill': Color(0xFFFBD5DE),
  'peds_band_rule': Color(0xFFDA5798),
  'cc_band_fill': Color(0xFFE3DCF2),
  'cc_band_rule': Color(0xFF6A1B9A),

  // Warning callouts.
  'warning_safety': Color(0xFFD32F2F),
  'warning_caution': Color(0xFF7E57C2),

  // Flow-chart shapes.
  'flow_decision': Color(0xFFF6BDAE),
  'flow_entry': Color(0xFFCDE0F1),
  'flow_convergence': Color(0xFFD5ECD6),
  'cc_link_fill': Color(0xFFF1E7F6),
  'cc_link_border': Color(0xFF6A1B9A),

  // Note / inset (e.g. dose-table caption, "consider" note).
  'note_fill': Color(0xFFFFFDE7),
  'note_border': Color(0xFFF9A825),
  'note_text': Color(0xFF5D4037),

  // Attention callout (prose `callout: true`).
  'alert': Color(0xFFF6A609),
  'alert_fill': Color(0xFFFFF6D6),
  'alert_text': Color(0xFFB9770A),

  // Danger / contraindication text.
  'danger_text': Color(0xFFC62828),
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
/// entry in order (book, then chapter, then topic), then derives
/// `accent_fill` / `accent_branch` from the resolved `accent` when no layer
/// set them explicitly.
Map<String, Color> resolvePalette(List<Map<String, Color>> layers) {
  final m = <String, Color>{...kRoleDefaults};
  for (final layer in layers) {
    m.addAll(layer);
  }
  final accent = m['accent'] ?? kNeutralAccent;
  m['accent_fill'] ??= _tint(accent);
  m['accent_branch'] ??= accent;
  return m;
}

/// A light wash of [c] over white — the node-fill tint derived from accent.
Color _tint(Color c) =>
    Color.alphaBlend(c.withValues(alpha: 0.12), Colors.white);
