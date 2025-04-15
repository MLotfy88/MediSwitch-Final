import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:lucide_icons/lucide_icons.dart'; // Import Lucide Icons
import '../bloc/settings_provider.dart';
import '../bloc/medicine_provider.dart';
import '../widgets/section_header.dart';
import '../widgets/settings_list_tile.dart';
import '../screens/subscription_screen.dart';
import '../../core/di/locator.dart';
import '../../core/services/file_logger_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  static final FileLoggerService _logger = locator<FileLoggerService>();

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
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
        children: [
          // --- Profile Section (Placeholder) ---
          _buildProfileSection(context), // Call the helper
          const SizedBox(height: 16),

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
              const Divider(height: 1, indent: 56),
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
          const SizedBox(height: 16),

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
                  icon: Icon(LucideIcons.refreshCw, size: 20),
                  tooltip: 'التحقق من وجود تحديث',
                  onPressed: () async {
                    _logger.i("SettingsScreen: Refresh data button pressed.");
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('جاري التحقق من التحديثات...'),
                      ),
                    );
                    await medicineProvider.loadInitialData();
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
            ],
          ),
          const SizedBox(height: 16),

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
                  _logger.i("SettingsScreen: Manage Subscription tile tapped.");
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
          const SizedBox(height: 16),

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
                onTap: () => _launchUrl('https://your-about-us-url.com'),
              ),
              const Divider(height: 1, indent: 56),
              SettingsListTile(
                title: 'سياسة الخصوصية',
                leadingIcon: LucideIcons.shieldCheck,
                trailing: Icon(
                  LucideIcons.chevronLeft,
                  size: 18,
                  color: colorScheme.onSurfaceVariant,
                ),
                onTap: () => _launchUrl('https://your-privacy-policy-url.com'),
              ),
              const Divider(height: 1, indent: 56),
              SettingsListTile(
                title: 'شروط الاستخدام',
                leadingIcon: LucideIcons.gavel,
                trailing: Icon(
                  LucideIcons.chevronLeft,
                  size: 18,
                  color: colorScheme.onSurfaceVariant,
                ),
                onTap:
                    () => _launchUrl('https://your-terms-of-service-url.com'),
              ),
              const Divider(height: 1, indent: 56),
              SettingsListTile(
                title: 'إصدار التطبيق',
                subtitle: '1.0.0+1', // TODO: Get version dynamically
                leadingIcon: LucideIcons.tag,
                onTap: null,
              ),
            ],
          ),
          const SizedBox(height: 24),

          // --- Logout Button ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: ElevatedButton.icon(
              icon: Icon(LucideIcons.logOut, size: 18),
              label: const Text('تسجيل الخروج'),
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.error,
                foregroundColor: colorScheme.onError,
                minimumSize: const Size(double.infinity, 48),
              ),
              onPressed: () {
                _logger.i("SettingsScreen: Logout button pressed.");
                // TODO: Implement logout logic
              },
            ),
          ),
          const SizedBox(height: 16),
        ],
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
            16.0,
          ), // Add padding inside the card content
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
              const SizedBox(width: 16),
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
              const SizedBox(width: 8),
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
          padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 8.0),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Column(children: children),
        ),
      ],
    );
  }

  // Helper Methods
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
      } else {
        _logger.i("SettingsScreen: URL launched successfully.");
      }
    } catch (e, s) {
      _logger.e("SettingsScreen: Error launching URL $urlString", e, s);
    }
  }
}
