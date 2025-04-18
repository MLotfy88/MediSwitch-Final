import 'package:flutter/material.dart';

class SettingsListTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData leadingIcon;
  final Widget? trailing;
  final VoidCallback? onTap;

  const SettingsListTile({
    super.key,
    required this.title,
    this.subtitle,
    required this.leadingIcon,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return ListTile(
      leading: Icon(leadingIcon, color: colorScheme.onSurfaceVariant),
      title: Text(title, style: textTheme.titleMedium),
      subtitle:
          subtitle != null
              ? Text(
                subtitle!,
                style: textTheme.bodyMedium?.copyWith(
                  color:
                      colorScheme
                          .onSurfaceVariant, // Use onSurfaceVariant for better contrast
                ),
              )
              : null,
      trailing: trailing,
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16.0,
        vertical: 4.0,
      ), // Adjust padding
      // Add visual density or other styling if needed
    );
  }
}
