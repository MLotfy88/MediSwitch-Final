import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../bloc/settings_provider.dart';
import '../bloc/medicine_provider.dart'; // Re-enable MedicineProvider import
import '../widgets/section_header.dart';
import '../widgets/settings_list_tile.dart';
import '../screens/subscription_screen.dart'; // Import SubscriptionScreen
import '../../core/di/locator.dart'; // Import locator
import '../../core/services/file_logger_service.dart'; // Import logger

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  // Get logger instance
  static final FileLoggerService _logger = locator<FileLoggerService>();

  @override
  Widget build(BuildContext context) {
    _logger.i("SettingsScreen: Building widget...");
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
              _logger.i("SettingsScreen: Language tile tapped.");
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
                _logger.i(
                  "SettingsScreen: Theme switch toggled to ${isDark ? 'Dark' : 'Light'}.",
                );
                settingsProvider.updateThemeMode(
                  isDark ? ThemeMode.dark : ThemeMode.light,
                );
              },
            ),
            onTap: () {
              bool currentIsDark = settingsProvider.themeMode == ThemeMode.dark;
              _logger.i(
                "SettingsScreen: Theme tile tapped. Toggling to ${currentIsDark ? 'Light' : 'Dark'}.",
              );
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
                _logger.i("SettingsScreen: Refresh data button pressed.");
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
                _logger.i(
                  "SettingsScreen: Refresh data complete. Error: '${medicineProvider.error}'",
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
              _logger.i("SettingsScreen: Manage Subscription tile tapped.");
              // TODO: Re-enable SubscriptionProvider and navigation later
              // For now, just navigate if the screen exists
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SubscriptionScreen(),
                ), // Assuming SubscriptionScreen exists
              );
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
    _logger.d("SettingsScreen: Showing language dialog.");
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
      _logger.i(
        "SettingsScreen: Language selected: ${selectedLocale.languageCode}",
      );
      provider.updateLocale(selectedLocale);
    } else {
      _logger.d("SettingsScreen: Language dialog cancelled.");
    }
  }

  Future<void> _launchUrl(String urlString) async {
    _logger.i("SettingsScreen: Attempting to launch URL: $urlString");
    final Uri url = Uri.parse(urlString);
    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        _logger.e('Could not launch $urlString');
        // Optionally show a snackbar to the user
      } else {
        _logger.i("SettingsScreen: URL launched successfully.");
      }
    } catch (e, s) {
      _logger.e(
        "SettingsScreen: Error launching URL $urlString",
        e,
        s,
      ); // Correct parameters
    }
  }
}
