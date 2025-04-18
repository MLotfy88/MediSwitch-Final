import 'package:flutter/foundation.dart'; // Import for kDebugMode (though not used in this diff)
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:lucide_icons/lucide_icons.dart'; // Import Lucide Icons
import '../bloc/settings_provider.dart';
import '../bloc/medicine_provider.dart';
import '../widgets/section_header.dart'; // Keep if used elsewhere, otherwise remove
import '../widgets/settings_list_tile.dart';
import '../screens/subscription_screen.dart';
import 'debug/log_viewer_screen.dart'; // Import the log viewer screen
import '../../core/di/locator.dart';
import '../../core/services/file_logger_service.dart';
import '../../core/constants/app_spacing.dart'; // Import spacing constants

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  // Make logger static as it doesn't depend on instance state
  static final FileLoggerService _logger = locator<FileLoggerService>();

  // Make _launchUrl static as it doesn't depend on instance state
  static Future<void> _launchUrl(String urlString) async {
    _logger.i("SettingsScreen: Attempting to launch URL: $urlString");
    final Uri url = Uri.parse(urlString);
    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        _logger.e('Could not launch $urlString');
        // Cannot show SnackBar here as we don't have context
      } else {
        _logger.i("SettingsScreen: URL launched successfully.");
      }
    } catch (e, s) {
      _logger.e("SettingsScreen: Error launching URL $urlString", e, s);
      // Cannot show SnackBar here
    }
  }

  @override
  Widget build(BuildContext context) {
    _logger.i("SettingsScreen: Building widget...");
    final settingsProvider = context.watch<SettingsProvider>();
    final medicineProvider = context.watch<MedicineProvider>();
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('الإعدادات')),
      // Wrap the body content with SafeArea
      body: SafeArea(
        child: ListView(
          // Use constants for padding
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.large, // Use constant (16px)
            horizontal: AppSpacing.small, // Use constant (8px)
          ),
          children: [
            // --- Profile Section (Placeholder) ---
            _buildProfileSection(context), // Call the helper
            AppSpacing.gapVLarge, // Use constant (16px)
            // --- General Section ---
            _buildSectionCard(
              context,
              title: 'عام',
              children: [
                SettingsListTile(
                  title: 'اللغة',
                  subtitle:
                      settingsProvider.locale.languageCode == 'ar'
                          ? 'العربية'
                          : 'English',
                  leadingIcon: LucideIcons.globe,
                  trailing: Icon(
                    LucideIcons.chevronLeft,
                    size: 18,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  onTap: () {
                    _logger.i("SettingsScreen: Language tile tapped.");
                    _showLanguageDialog(context, settingsProvider);
                  },
                ),
                // Divider handled by ListView.separated in _buildSectionCard
                SettingsListTile(
                  title: 'المظهر',
                  subtitle: _themeModeToString(settingsProvider.themeMode),
                  leadingIcon:
                      isDarkMode(context) ? LucideIcons.moon : LucideIcons.sun,
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
                    bool currentIsDark =
                        settingsProvider.themeMode == ThemeMode.dark;
                    _logger.i(
                      "SettingsScreen: Theme tile tapped. Toggling to ${currentIsDark ? 'Light' : 'Dark'}.",
                    );
                    settingsProvider.updateThemeMode(
                      currentIsDark ? ThemeMode.light : ThemeMode.dark,
                    );
                  },
                ),
              ],
            ),
            AppSpacing.gapVLarge, // Use constant (16px)
            // --- Data Section ---
            _buildSectionCard(
              context,
              title: 'البيانات',
              children: [
                SettingsListTile(
                  title: 'آخر تحديث للبيانات',
                  subtitle: medicineProvider.lastUpdateTimestampFormatted,
                  leadingIcon: LucideIcons.refreshCw,
                  trailing: IconButton(
                    icon: const Icon(LucideIcons.refreshCw, size: 20),
                    tooltip: 'التحقق من وجود تحديث',
                    onPressed: () async {
                      _logger.i("SettingsScreen: Refresh data button pressed.");
                      // Show snackbar *before* async operation
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('جاري التحقق من التحديثات...'),
                          duration: Duration(seconds: 1), // Shorter duration
                        ),
                      );
                      await medicineProvider.loadInitialData();
                      // Check if mounted *after* await before showing next snackbar
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).hideCurrentSnackBar();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              medicineProvider.error.contains('فشل')
                                  ? medicineProvider.error
                                  : 'البيانات محدثة.',
                            ),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      }
                      _logger.i(
                        "SettingsScreen: Refresh data complete. Error: '${medicineProvider.error}'",
                      );
                    },
                    splashRadius: 24,
                  ),
                  onTap: null,
                ),
                // Divider handled by ListView.separated
                // --- Add Log Viewer Tile ---
                SettingsListTile(
                  title: 'عرض سجلات التصحيح', // View Debug Logs
                  leadingIcon: LucideIcons.fileText, // Or LucideIcons.bug
                  trailing: Icon(
                    LucideIcons.chevronLeft,
                    size: 18,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  onTap: () {
                    _logger.i("SettingsScreen: View Logs tile tapped.");
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LogViewerScreen(),
                      ),
                    );
                  },
                ),
                // --- End Log Viewer Tile ---
              ],
            ),
            AppSpacing.gapVLarge, // Use constant (16px)
            // --- Subscription Section ---
            _buildSectionCard(
              context,
              title: 'الاشتراك',
              children: [
                SettingsListTile(
                  title: 'إدارة الاشتراك',
                  subtitle: 'الترقية إلى Premium',
                  leadingIcon: LucideIcons.creditCard,
                  trailing: Icon(
                    LucideIcons.chevronLeft,
                    size: 18,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  onTap: () {
                    _logger.i(
                      "SettingsScreen: Manage Subscription tile tapped.",
                    );
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SubscriptionScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
            AppSpacing.gapVLarge, // Use constant (16px)
            // --- About Section ---
            _buildSectionCard(
              context,
              title: 'حول التطبيق',
              children: [
                SettingsListTile(
                  title: 'عن MediSwitch',
                  leadingIcon: LucideIcons.info,
                  trailing: Icon(
                    LucideIcons.chevronLeft,
                    size: 18,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  onTap:
                      () => _launchUrl(
                        'https://your-about-us-url.com',
                      ), // Replace with actual URL
                ),
                // Divider handled by ListView.separated
                SettingsListTile(
                  title: 'سياسة الخصوصية',
                  leadingIcon: LucideIcons.shieldCheck,
                  trailing: Icon(
                    LucideIcons.chevronLeft,
                    size: 18,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  onTap:
                      () => _launchUrl(
                        'https://your-privacy-policy-url.com',
                      ), // Replace with actual URL
                ),
                // Divider handled by ListView.separated
                SettingsListTile(
                  title: 'شروط الاستخدام',
                  leadingIcon: LucideIcons.gavel,
                  trailing: Icon(
                    LucideIcons.chevronLeft,
                    size: 18,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  onTap:
                      () => _launchUrl(
                        'https://your-terms-of-service-url.com',
                      ), // Replace with actual URL
                ),
                // Divider handled by ListView.separated
                SettingsListTile(
                  title: 'إصدار التطبيق',
                  subtitle: '1.0.0+1', // TODO: Get version dynamically
                  leadingIcon: LucideIcons.tag,
                  onTap: null,
                ),
              ],
            ),
            AppSpacing.gapVXLarge, // Use constant (24px)
            // --- Logout Button ---
            Padding(
              padding: AppSpacing.edgeInsetsHSmall, // Use constant (8px)
              child: ElevatedButton.icon(
                icon: const Icon(LucideIcons.logOut, size: 18),
                label: const Text('تسجيل الخروج'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.error,
                  foregroundColor: colorScheme.onError,
                  minimumSize: const Size(
                    double.infinity,
                    48,
                  ), // Keep specific height
                ),
                onPressed: () {
                  _logger.i("SettingsScreen: Logout button pressed.");
                  // TODO: Implement logout logic (e.g., clear user session, navigate to login)
                },
              ),
            ),
            AppSpacing.gapVLarge, // Use constant (16px)
          ],
        ),
      ),
    );
  }

  // Helper to build profile section card
  Widget _buildProfileSection(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    // Placeholder data for now
    const String userName = "أحمد محمد";
    const String userEmail = "ahmed@example.com";
    const String userInitial = "أ";

    return _buildSectionCard(
      context,
      title: 'الملف الشخصي',
      children: [
        Padding(
          padding: const EdgeInsets.all(
            AppSpacing.large, // Use constant (16px)
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 28, // Slightly larger avatar
                backgroundColor: colorScheme.primary.withOpacity(0.1),
                child: Text(
                  userInitial,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              AppSpacing.gapHLarge, // Use constant (16px)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      userEmail,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              AppSpacing.gapHSmall, // Use constant (8px)
              // Edit button (optional, functionality TBD)
              // OutlinedButton(
              //   onPressed: () { _logger.i("SettingsScreen: Edit profile tapped (Not implemented)."); },
              //   child: Text('تعديل'),
              // ),
            ],
          ),
        ),
      ],
    );
  }

  // Helper to build section cards for better visual grouping
  Widget _buildSectionCard(
    BuildContext context, {
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          // Use constants for padding
          padding: const EdgeInsets.only(
            left: AppSpacing.large, // 16px
            right: AppSpacing.large, // 16px
            bottom: AppSpacing.small, // 8px
          ),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
        Card(
          margin: AppSpacing.edgeInsetsHSmall, // Use constant (8px)
          // Use ListView.separated for consistent spacing between tiles
          child: ListView.separated(
            shrinkWrap: true, // Important for ListView inside Column
            physics: const NeverScrollableScrollPhysics(), // Disable scrolling
            itemCount: children.length,
            itemBuilder: (context, index) => children[index],
            // Use Divider for visual separation, height 1 is standard
            separatorBuilder:
                (context, index) => const Divider(
                  height: 1,
                  indent: 56,
                  endIndent: 0,
                ), // Keep divider for visual style
            // Alternative: Use AppSpacing for separator:
            // separatorBuilder: (context, index) => AppSpacing.gapVSmall,
          ),
        ),
      ],
    );
  }

  // Helper Methods (moved outside build method)
  bool isDarkMode(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

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
      builder: (BuildContext dialogContext) {
        // Use different context name
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
                  Navigator.pop(dialogContext, value); // Use dialogContext
                },
              ),
              RadioListTile<Locale>(
                title: const Text('English'),
                value: const Locale('en'),
                groupValue: currentLocale,
                onChanged: (Locale? value) {
                  Navigator.pop(dialogContext, value); // Use dialogContext
                },
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('إلغاء'),
              onPressed: () {
                Navigator.pop(dialogContext); // Use dialogContext
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
      // No need to check mounted here as provider call is synchronous
      provider.updateLocale(selectedLocale);
    } else {
      _logger.d("SettingsScreen: Language dialog cancelled.");
    }
  }
}
