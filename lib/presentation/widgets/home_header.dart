import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart'; // Correct package name
import 'package:provider/provider.dart';
import '../bloc/settings_provider.dart'; // To potentially get user info later

class HomeHeader extends StatelessWidget {
  const HomeHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    // final settingsProvider = context.watch<SettingsProvider>(); // Get user info if needed

    // Use SafeArea to avoid status bar overlap
    return SafeArea(
      bottom: false, // Only apply padding to the top
      child: Container(
        // Use tertiary color for background as defined in theme
        color: colorScheme.tertiary,
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Display Logo
            Image.asset(
              'assets/images/logo.png', // Use logo from assets
              height: 36, // Adjust height as needed
              // Optionally add error builder
            ),

            // Action Icons (Notification Bell)
            Row(
              children: [
                IconButton(
                  icon: Icon(LucideIcons.bell, color: colorScheme.onTertiary),
                  onPressed: () {
                    // TODO: Implement notification action
                    print("Notification button pressed");
                  },
                  tooltip: 'الإشعارات',
                  splashRadius: 24, // Standard splash radius
                  // Add visual density or padding if needed
                ),
                // Add Avatar later if needed
                // CircleAvatar(
                //   radius: 20,
                //   backgroundColor: colorScheme.onTertiary.withOpacity(0.2),
                //   child: Text(
                //     'أ', // Placeholder initial
                //     style: TextStyle(color: colorScheme.onTertiary, fontWeight: FontWeight.bold),
                //   ),
                // ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
