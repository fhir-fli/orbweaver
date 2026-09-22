import 'package:flutter/material.dart';

/// The app bar the book, formulary and topic screens share: a coloured bar
/// whose [title] gives way to a search field while [searchOpen], with the
/// search toggle first among the [actions]. The screen owns the search
/// state; this widget only draws it.
class SearchAppBar extends StatelessWidget implements PreferredSizeWidget {
  const SearchAppBar({
    required this.title,
    required this.color,
    required this.hintText,
    required this.searchOpen,
    required this.controller,
    required this.onQueryChanged,
    required this.onToggleSearch,
    this.actions = const [],
    this.titleSpacing,
    this.searchTooltip,
    super.key,
  });

  final Widget title;
  final Color color;
  final String hintText;
  final bool searchOpen;
  final TextEditingController controller;
  final ValueChanged<String> onQueryChanged;
  final VoidCallback onToggleSearch;

  /// Further actions, placed after the search toggle.
  final List<Widget> actions;
  final double? titleSpacing;

  /// Tooltip on the search toggle while closed; while open it reads
  /// "Close search". No tooltips when null.
  final String? searchTooltip;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) => AppBar(
    backgroundColor: color,
    foregroundColor: Colors.white,
    titleSpacing: titleSpacing,
    title: searchOpen
        ? TextField(
            controller: controller,
            autofocus: true,
            style: const TextStyle(color: Colors.white, fontSize: 16),
            cursorColor: Colors.white,
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: const TextStyle(color: Colors.white70),
              border: InputBorder.none,
            ),
            onChanged: onQueryChanged,
          )
        : title,
    actions: [
      IconButton(
        tooltip: searchTooltip == null
            ? null
            : (searchOpen ? 'Close search' : searchTooltip),
        icon: Icon(searchOpen ? Icons.close : Icons.search),
        onPressed: onToggleSearch,
      ),
      ...actions,
    ],
  );
}
