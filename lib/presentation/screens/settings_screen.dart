import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // Re-enable provider
import 'package:url_launcher/url_launcher.dart'; // Re-enable url_launcher
import '../bloc/settings_provider.dart'; // Re-enable SettingsProvider
import '../bloc/medicine_provider.dart'; // Re-enable MedicineProvider
import '../widgets/section_header.dart'; // Re-enable SectionHeader import
import '../widgets/settings_list_tile.dart'; // Re-enable SettingsListTile import
import '../screens/subscription_screen.dart'; // Import SubscriptionScreen

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Restore Original Build Logic
    final settingsProvider = context.watch<SettingsProvider>();
    final medicineProvider =
        context.watch<MedicineProvider>(); // Re-enable MedicineProvider access
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
        // Re-enable ListView
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        children: [
          // --- General Section ---
          const SectionHeader(
            title: 'عام',
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          ),
          SettingsListTile(
            title: 'اللغة',
            subtitle:
                settingsProvider.locale.languageCode == 'ar'
                    ? 'العربية'
                    : 'English',
            leadingIcon: Icons.language_outlined,
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              _showLanguageDialog(context, settingsProvider);
            },
          ),
          SettingsListTile(
            title: 'المظهر',
            subtitle: _themeModeToString(settingsProvider.themeMode),
            leadingIcon: Icons.brightness_6_outlined,
            trailing: Switch(
              value: settingsProvider.themeMode == ThemeMode.dark,
              onChanged: (isDark) {
                settingsProvider.updateThemeMode(
                  isDark ? ThemeMode.dark : ThemeMode.light,
                );
              },
            ),
            onTap: () {
              bool currentIsDark = settingsProvider.themeMode == ThemeMode.dark;
              settingsProvider.updateThemeMode(
                currentIsDark ? ThemeMode.light : ThemeMode.dark,
              );
            },
          ),
          const Divider(height: 24, indent: 16, endIndent: 16),

          // --- Data Section ---
          const SectionHeader(
            title: 'البيانات',
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          ),
          SettingsListTile(
            title: 'آخر تحديث للبيانات',
            subtitle:
                medicineProvider
                    .lastUpdateTimestampFormatted, // Use MedicineProvider
            leadingIcon: Icons.cloud_sync_outlined,
            trailing: IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'التحقق من وجود تحديث',
              onPressed: () async {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('جاري التحقق من التحديثات...')),
                );
                // Trigger update check via MedicineProvider
                await medicineProvider
                    .loadInitialData(); // This triggers the check
                // Show result
                ScaffoldMessenger.of(
                  context,
                ).hideCurrentSnackBar(); // Hide previous
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      medicineProvider.error.contains('فشل')
                          ? medicineProvider
                              .error // Show specific error
                          : 'البيانات محدثة.',
                    ),
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
            ),
            onTap: null, // No action on tap for this row
          ),
          const Divider(height: 24, indent: 16, endIndent: 16),

          // --- Subscription Section ---
          const SectionHeader(
            title: 'الاشتراك',
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          ),
          SettingsListTile(
            title: 'إدارة الاشتراك',
            subtitle: 'الترقية إلى Premium أو استعادة المشتريات',
            leadingIcon: Icons.star_border_outlined,
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              // TODO: Re-enable SubscriptionProvider and navigation later
              print('Navigate to Subscription Screen (disabled for now)');
              // Navigator.push(
              //   context,
              //   MaterialPageRoute(builder: (context) => const SubscriptionScreen()),
              // );
            },
          ),
          const Divider(height: 24, indent: 16, endIndent: 16),

          // --- About Section ---
          const SectionHeader(
            title: 'حول التطبيق',
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          ),
          SettingsListTile(
            title: 'عن MediSwitch',
            leadingIcon: Icons.info_outline,
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap:
                () => _launchUrl(
                  'https://your-about-us-url.com',
                ), // Replace with actual URL
          ),
          SettingsListTile(
            title: 'سياسة الخصوصية',
            leadingIcon: Icons.privacy_tip_outlined,
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap:
                () => _launchUrl(
                  'https://your-privacy-policy-url.com',
                ), // Replace with actual URL
          ),
          SettingsListTile(
            title: 'شروط الاستخدام',
            leadingIcon: Icons.gavel_outlined,
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap:
                () => _launchUrl(
                  'https://your-terms-of-service-url.com',
                ), // Replace with actual URL
          ),
          SettingsListTile(
            title: 'إصدار التطبيق',
            subtitle: '1.0.0+1', // TODO: Get version dynamically later
            leadingIcon: Icons.tag,
            onTap: null,
          ),
        ],
      ),
    );
  }

  // --- Helper Methods ---

  String _themeModeToString(ThemeMode themeMode) {
    switch (themeMode) {
      case ThemeMode.light:
        return 'فاتح';
      case ThemeMode.dark:
        return 'داكن';
      case ThemeMode.system:
      default:
        return 'النظام';
    }
  }

  Future<void> _showLanguageDialog(
    BuildContext context,
    SettingsProvider provider,
  ) async {
    final currentLocale = provider.locale;
    final selectedLocale = await showDialog<Locale>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('اختر اللغة'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              RadioListTile<Locale>(
                title: const Text('العربية'),
                value: const Locale('ar'),
                groupValue: currentLocale,
                onChanged: (Locale? value) {
                  Navigator.pop(context, value);
                },
              ),
              RadioListTile<Locale>(
                title: const Text('English'),
                value: const Locale('en'),
                groupValue: currentLocale,
                onChanged: (Locale? value) {
                  Navigator.pop(context, value);
                },
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('إلغاء'),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );

    if (selectedLocale != null) {
      provider.updateLocale(selectedLocale);
    }
  }

  Future<void> _launchUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      // Consider showing a snackbar if launching fails
      print('Could not launch $urlString');
    }
  }
}
