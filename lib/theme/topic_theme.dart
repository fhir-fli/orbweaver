import 'package:flutter/material.dart';
import 'package:orbweaver/theme/palette.dart';

/// Typed view over a resolved color [palette] (see `palette.dart`). Every
/// color the renderer draws is read from a named role here, so a book /
/// chapter / topic can re-skin any of them via its `palette:` cascade.
/// Nothing is hardcoded at a use site.
class TopicTheme {
  const TopicTheme(this.palette);

  /// Build a theme directly from a single accent color (the rest of the
  /// roles fall back to defaults, accent-derived where applicable). Used
  /// for standalone rendering when no cascade is available.
  factory TopicTheme.fromAccent(Color accent) =>
      TopicTheme(resolvePalette([
        {'accent': accent},
      ]));

  /// The resolved role → color map.
  final Map<String, Color> palette;

  Color _c(String role) =>
      palette[role] ?? kRoleDefaults[role] ?? kNeutralAccent;

  /// Look up an arbitrary (possibly custom) role by name.
  Color role(String name) => _c(name);

  // Identity / accent.
  Color get header => _c('accent');
  Color get nodeBorder => _c('accent');
  Color get nodeFill => _c('accent_fill');
  Color get branchAccent => _c('accent_branch');

  // Severity bands.
  Color get severityMildHeader => _c('severity_mild_header');
  Color get severityMildTile => _c('severity_mild_tile');
  Color get severityModerateHeader => _c('severity_moderate_header');
  Color get severityModerateTile => _c('severity_moderate_tile');
  Color get severitySevereHeader => _c('severity_severe_header');
  Color get severitySevereTile => _c('severity_severe_tile');

  // Provider badges.
  Color get providerEmt => _c('provider_emt');
  Color get providerIntermediate => _c('provider_intermediate');
  Color get providerAls => _c('provider_als');
  Color get providerParamedic => _c('provider_paramedic');
  Color get providerAny => _c('provider_any');

  // Dose populations.
  Color get popAdult => _c('pop_adult');
  Color get popPeds => _c('pop_peds');

  // Warnings.
  Color get warningSafety => _c('warning_safety');
  Color get warningCaution => _c('warning_caution');

  // Flow shapes.
  Color get flowDecision => _c('flow_decision');
  Color get flowEntry => _c('flow_entry');
  Color get flowConvergence => _c('flow_convergence');
  Color get ccLinkFill => _c('cc_link_fill');
  Color get ccLinkBorder => _c('cc_link_border');

  // Note / inset.
  Color get noteFill => _c('note_fill');
  Color get noteBorder => _c('note_border');
  Color get noteText => _c('note_text');

  // Attention callout.
  Color get alert => _c('alert');
  Color get alertFill => _c('alert_fill');
  Color get alertText => _c('alert_text');

  // Danger text.
  Color get dangerText => _c('danger_text');
}

/// Provides the resolved [TopicTheme] to the widget subtree, so deeply
/// nested leaf widgets (flow-chart shapes, provider badges, warning
/// callouts) can read palette roles from context instead of threading the
/// theme through every constructor. Wrapped around the content in
/// `TopicView`.
class TopicThemeScope extends InheritedWidget {
  const TopicThemeScope({
    required this.theme,
    required super.child,
    super.key,
  });

  final TopicTheme theme;

  static TopicTheme of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<TopicThemeScope>();
    return scope?.theme ?? TopicTheme.fromAccent(kNeutralAccent);
  }

  @override
  bool updateShouldNotify(TopicThemeScope oldWidget) =>
      oldWidget.theme.palette != theme.palette;
}
