import 'package:material_ui/material_ui.dart';

/// Lets any screen change the reading language. The app reloads the
/// library in the new language and rebuilds from the shelf.
class LanguageScope extends InheritedWidget {
  const LanguageScope({
    required this.choice,
    required this.onChoose,
    required super.child,
    super.key,
  });

  /// The stored choice; null = same as the phone.
  final String? choice;
  final Future<void> Function(String? choice) onChoose;

  static LanguageScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<LanguageScope>();

  @override
  bool updateShouldNotify(LanguageScope old) => old.choice != choice;
}
