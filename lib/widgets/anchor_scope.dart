import 'package:flutter/material.dart';

/// Provides a same-topic anchor-scroll callback to descendants, so a
/// `#<anchor>` link deep in the markdown can ask the topic view to scroll
/// to the block that declared that `anchor:` slug. Provided by `TopicView`.
class AnchorScope extends InheritedWidget {
  const AnchorScope({
    required this.scrollTo,
    required super.child,
    super.key,
  });

  /// Scrolls the topic to the block whose `anchor:` slug equals `slug`.
  /// No-op if the slug isn't present in this topic.
  final void Function(String slug) scrollTo;

  static AnchorScope? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AnchorScope>();

  @override
  bool updateShouldNotify(AnchorScope oldWidget) => false;
}
