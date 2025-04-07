import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../bloc/settings_provider.dart';
import '../bloc/medicine_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  // Helper function to launch URLs safely
  Future<void> _launchURL(BuildContext context, String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('تعذر فتح الرابط: $urlString')));
      }
      print('Could not launch $urlString');
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsProvider = context.watch<SettingsProvider>();
    final medicineProvider = context.watch<MedicineProvider>(); // For timestamp
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Define card padding and margin
    const cardMargin = EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0);
    const cardPadding = EdgeInsets.symmetric(
      vertical: 8.0,
    ); // Padding inside card

    return Scaffold(
      appBar: AppBar(title: const Text('الإعدادات')),
      body: ListView(
        padding: const EdgeInsets.symmetric(
          vertical: 8.0,
        ), // Padding for the whole list
        children: [
          // --- User Profile Section ---
          Card(
            margin: cardMargin,
            elevation: 1, // Subtle shadow
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ), // .rounded-lg
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: colorScheme.primaryContainer,
                        child: Icon(
                          Icons.person_outline,
                          size: 35,
                          color: colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'أحمد محمد',
                            style: theme.textTheme.titleLarge,
                          ), // Placeholder
                          Text(
                            'ahmed@example.com',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ), // Placeholder
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: const Text('تعديل الملف الشخصي'),
                    onPressed: () {
                      // TODO: Implement profile editing
                      print('Edit Profile Tapped');
                    },
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(
                        double.infinity,
                        40,
                      ), // Full width
                      backgroundColor: colorScheme.secondaryContainer,
                      foregroundColor: colorScheme.onSecondaryContainer,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // --- General Settings Section ---
          _buildSettingsSectionTitle(context, 'الإعدادات العامة'),
          Card(
            margin: cardMargin,
            elevation: 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: cardPadding,
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text('الوضع الداكن'),
                    secondary: Icon(
                      settingsProvider.themeMode == ThemeMode.dark
                          ? Icons.dark_mode_outlined
                          : Icons.light_mode_outlined,
                      color: colorScheme.primary,
                    ),
                    value: settingsProvider.themeMode == ThemeMode.dark,
                    onChanged: (bool value) {
                      settingsProvider.updateThemeMode(
                        value ? ThemeMode.dark : ThemeMode.light,
                      );
                    },
                  ),
                  _buildDivider(),
                  ListTile(
                    leading: Icon(
                      Icons.language_outlined,
                      color: colorScheme.primary,
                    ),
                    title: const Text('اللغة'),
                    trailing: Row(
                      // Use Row for text and chevron
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          settingsProvider.locale.languageCode == 'ar'
                              ? 'العربية'
                              : 'English',
                          style: TextStyle(color: colorScheme.onSurfaceVariant),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 14,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ],
                    ),
                    onTap: () async {
                      final Locale? selectedLocale = await _showLanguageDialog(
                        context,
                      );
                      if (selectedLocale != null && context.mounted) {
                        context.read<SettingsProvider>().updateLocale(
                          selectedLocale,
                        );
                      }
                    },
                  ),
                  _buildDivider(),
                  SwitchListTile(
                    // Using SwitchListTile for Notifications
                    title: const Text('الإشعارات'),
                    secondary: Icon(
                      Icons.notifications_outlined,
                      color: colorScheme.primary,
                    ),
                    value: true, // Placeholder value
                    onChanged: (bool value) {
                      // TODO: Implement notification preference logic
                      print('Notifications Toggled: $value');
                    },
                  ),
                ],
              ),
            ),
          ),

          // --- Security & Privacy Section ---
          _buildSettingsSectionTitle(context, 'الأمان والخصوصية'),
          Card(
            margin: cardMargin,
            elevation: 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: cardPadding,
              child: Column(
                children: [
                  ListTile(
                    leading: Icon(
                      Icons.lock_outline,
                      color: colorScheme.primary,
                    ),
                    title: const Text('تغيير كلمة المرور'),
                    trailing: Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 14,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    onTap: () {
                      // TODO: Implement change password navigation/logic
                      print('Change Password Tapped');
                    },
                  ),
                  _buildDivider(),
                  ListTile(
                    leading: Icon(
                      Icons.privacy_tip_outlined,
                      color: colorScheme.primary,
                    ),
                    title: const Text('إعدادات الخصوصية'),
                    trailing: Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 14,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    onTap: () {
                      // TODO: Implement privacy settings navigation/logic
                      print('Privacy Settings Tapped');
                    },
                  ),
                ],
              ),
            ),
          ),

          // --- Subscription Section ---
          _buildSettingsSectionTitle(context, 'الاشتراك'),
          Card(
            margin: cardMargin,
            elevation: 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: cardPadding,
              child: ListTile(
                leading: Icon(
                  Icons.workspace_premium_outlined,
                  color: colorScheme.primary,
                ),
                title: const Text('الاشتراك المميز (Premium)'),
                subtitle: const Text('إزالة الإعلانات، سجل البحث، والمزيد!'),
                trailing: Chip(
                  label: const Text(
                    'مستخدم مجاني',
                  ), // TODO: Update based on actual status
                  backgroundColor: Colors.grey.shade400,
                  labelStyle: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                ),
                onTap: () {
                  // TODO: Implement navigation to subscription purchase/management screen
                  print('Subscription setting tapped');
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('سيتم إضافة شاشة إدارة الاشتراك لاحقاً.'),
                    ),
                  );
                },
              ),
            ),
          ),

          // --- About App Section ---
          _buildSettingsSectionTitle(context, 'حول التطبيق'),
          Card(
            margin: cardMargin,
            elevation: 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: cardPadding,
              child: Column(
                children: [
                  ListTile(
                    leading: Icon(
                      Icons.info_outline,
                      color: colorScheme.primary,
                    ),
                    title: const Text('إصدار التطبيق'),
                    trailing: Text(
                      'v1.0.0',
                      style: TextStyle(color: colorScheme.onSurfaceVariant),
                    ), // Placeholder version
                  ),
                  _buildDivider(),
                  ListTile(
                    leading: Icon(
                      Icons.gavel_outlined,
                      color: colorScheme.primary,
                    ),
                    title: const Text('شروط الخدمة'),
                    trailing: Icon(
                      Icons.open_in_new,
                      size: 18,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    onTap:
                        () => _launchURL(
                          context,
                          'https://example.com/terms',
                        ), // TODO: Update URL
                  ),
                  _buildDivider(),
                  ListTile(
                    leading: Icon(
                      Icons.privacy_tip_outlined,
                      color: colorScheme.primary,
                    ),
                    title: const Text('سياسة الخصوصية'),
                    trailing: Icon(
                      Icons.open_in_new,
                      size: 18,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    onTap:
                        () => _launchURL(
                          context,
                          'https://example.com/privacy',
                        ), // TODO: Update URL
                  ),
                  _buildDivider(),
                  ListTile(
                    leading: Icon(
                      Icons.history_outlined,
                      color: colorScheme.primary,
                    ),
                    title: const Text('تاريخ آخر تحديث للبيانات'),
                    subtitle: Text(
                      medicineProvider.lastUpdateTimestampFormatted,
                    ),
                  ),
                  _buildDivider(),
                  ListTile(
                    leading: Icon(
                      Icons.update_outlined,
                      color: colorScheme.primary,
                    ),
                    title: const Text('التحقق من وجود تحديثات'),
                    onTap: () async {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('جاري التحقق...'),
                          duration: Duration(seconds: 1),
                        ),
                      );
                      await context.read<MedicineProvider>().loadInitialData();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('اكتمل التحقق.'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          ),

          // --- Logout Button ---
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 24.0,
            ),
            child: ElevatedButton.icon(
              icon: const Icon(Icons.logout),
              label: const Text('تسجيل الخروج'),
              onPressed: () {
                // TODO: Implement logout logic
                print('Logout Tapped');
              },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 45),
                backgroundColor: colorScheme.errorContainer,
                foregroundColor: colorScheme.onErrorContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper for section titles
  Widget _buildSettingsSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(
        left: 16.0,
        right: 16.0,
        top: 16.0,
        bottom: 4.0,
      ),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // Helper for dividers within cards
  Widget _buildDivider() {
    return const Divider(height: 1, indent: 16, endIndent: 16);
  }

  // Helper to show language selection dialog
  Future<Locale?> _showLanguageDialog(BuildContext context) async {
    return await showDialog<Locale>(
      context: context,
      builder: (BuildContext context) {
        return SimpleDialog(
          title: const Text('اختر اللغة'),
          children: <Widget>[
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, const Locale('ar')),
              child: const Text('العربية'),
            ),
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, const Locale('en')),
              child: const Text('English'),
            ),
          ],
        );
      },
    );
  }
}
