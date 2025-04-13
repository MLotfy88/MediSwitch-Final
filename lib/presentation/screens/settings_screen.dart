import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // Re-enable provider
import 'package:url_launcher/url_launcher.dart'; // Re-enable url_launcher
import '../bloc/settings_provider.dart'; // Re-enable SettingsProvider
// import '../bloc/medicine_provider.dart'; // Keep disabled for now
// import '../widgets/section_header.dart'; // Keep disabled for now
// import '../widgets/settings_list_tile.dart'; // Keep disabled for now

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Re-enable basic Scaffold structure
    final settingsProvider =
        context.watch<SettingsProvider>(); // Need this for theme/locale access
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('الإعدادات'),
        backgroundColor: theme.scaffoldBackgroundColor, // Match background
        elevation: 0,
        foregroundColor: colorScheme.onBackground,
      ),
      body: const Center(
        child: Text(
          'Settings Screen Content Placeholder',
        ), // Placeholder for content
      ),
    );

    // --- Original Build Logic Commented Out ---
    /*
    final settingsProvider = context.watch<SettingsProvider>();
    final medicineProvider = context.watch<MedicineProvider>();
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('الإعدادات'),
        backgroundColor: theme.scaffoldBackgroundColor, // Match background
        elevation: 0,
        foregroundColor: colorScheme.onBackground,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        children: [
          // --- General Section ---
          const SectionHeader( ... ),
          SettingsListTile( ... Language ... ),
          SettingsListTile( ... Theme ... ),
          const Divider(height: 24, indent: 16, endIndent: 16),

          // --- Data Section ---
           const SectionHeader( ... ),
           SettingsListTile( ... Last Update ... ),
           const Divider(height: 24, indent: 16, endIndent: 16),


          // --- Subscription Section ---
          const SectionHeader( ... ),
          SettingsListTile( ... Subscription ... ),
          const Divider(height: 24, indent: 16, endIndent: 16),

          // --- About Section ---
          const SectionHeader( ... ),
          SettingsListTile( ... About ... ),
          SettingsListTile( ... Privacy ... ),
          SettingsListTile( ... Terms ... ),
          SettingsListTile( ... Version ... ),
        ],
      ),
    );
    */
  }

  // --- Helper Methods (Keep commented out for now) ---
  /*
  String _themeModeToString(ThemeMode themeMode) { ... }
  Future<void> _showLanguageDialog(BuildContext context, SettingsProvider provider) async { ... }
  Future<void> _launchUrl(String urlString) async { ... }
  */
}
