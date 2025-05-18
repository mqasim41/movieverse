import 'package:flutter/material.dart';
import '../../config/theme.dart';

/// Standardized app bar for consistent navigation throughout the app
class MovieVerseAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final Widget? leading;
  final Widget? flexibleSpace;
  final bool centerTitle;
  final double elevation;
  final Color? backgroundColor;
  final Widget? bottom;

  const MovieVerseAppBar({
    super.key,
    required this.title,
    this.actions,
    this.leading,
    this.flexibleSpace,
    this.centerTitle = false,
    this.elevation = 0,
    this.backgroundColor,
    this.bottom,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveBackgroundColor =
        backgroundColor ?? theme.appBarTheme.backgroundColor;

    return AppBar(
      title: Text(
        title,
        style: theme.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
      actions: actions,
      leading: leading,
      flexibleSpace: flexibleSpace,
      centerTitle: centerTitle,
      elevation: elevation,
      scrolledUnderElevation: elevation > 0 ? 4 : 0,
      backgroundColor: effectiveBackgroundColor,
      bottom: bottom != null
          ? PreferredSize(
              preferredSize: const Size.fromHeight(48),
              child: bottom!,
            )
          : null,
    );
  }

  @override
  Size get preferredSize => bottom != null
      ? const Size.fromHeight(kToolbarHeight + 48)
      : const Size.fromHeight(kToolbarHeight);
}

/// Search app bar that replaces the standard app bar when searching
class SearchAppBar extends StatelessWidget implements PreferredSizeWidget {
  final TextEditingController controller;
  final VoidCallback? onClear;
  final VoidCallback? onCancel;
  final ValueChanged<String>? onSubmitted;
  final String hintText;

  const SearchAppBar({
    super.key,
    required this.controller,
    this.onClear,
    this.onCancel,
    this.onSubmitted,
    this.hintText = 'Search...',
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppBar(
      titleSpacing: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: onCancel,
      ),
      title: TextField(
        controller: controller,
        decoration: InputDecoration(
          hintText: hintText,
          border: InputBorder.none,
          hintStyle: TextStyle(
            color: theme.colorScheme.onSurface.withOpacity(0.7),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        ),
        style: theme.textTheme.titleMedium,
        textInputAction: TextInputAction.search,
        onSubmitted: onSubmitted,
        autofocus: true,
      ),
      actions: [
        if (controller.text.isNotEmpty)
          IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () {
              controller.clear();
              if (onClear != null) onClear!();
            },
          ),
        IconButton(
          icon: const Icon(Icons.search),
          onPressed: () {
            if (onSubmitted != null) onSubmitted!(controller.text);
          },
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
