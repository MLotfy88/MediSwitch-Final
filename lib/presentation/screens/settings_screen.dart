import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../bloc/settings_provider.dart';
import '../bloc/medicine_provider.dart';
import '../widgets/section_header.dart'; // Import SectionHeader

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
    // Reduced vertical padding inside cards for tighter list items
    const cardPadding = EdgeInsets.symmetric(vertical: 4.0);
    // Define content padding for ListTiles
    const tileContentPadding = EdgeInsets.symmetric(
      horizontal: 16.0,
      vertical: 8.0,
    ); // Adjusted vertical padding

    return Scaffold(
      appBar: AppBar(
        title: const Text('الإعدادات'),
        // Match general AppBar style
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0.5,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(
          vertical: 8.0,
        ), // Padding for the whole list
        children: [
          // --- User Profile Section ---
          // User Profile Card - Match general Card style
          Card(
            margin: cardMargin,
            elevation: 0, // No elevation
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12), // Match theme --radius
              side: BorderSide(
                color: colorScheme.outline.withOpacity(0.5),
              ), // Subtle border
            ),
            child: Padding(
              padding: const EdgeInsets.all(
                16.0,
              ), // Keep larger padding for profile section
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
                            'أحمد محمد', // Placeholder
                            style: theme.textTheme.titleLarge,
                          ),
                          Text(
                            'ahmed@example.com', // Placeholder
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
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
                    // Match shadcn Button (secondary variant)
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 40),
                      backgroundColor: colorScheme.secondaryContainer,
                      foregroundColor: colorScheme.onSecondaryContainer,
                      elevation: 0, // Flat style
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          8.0,
                        ), // Match theme --radius
                      ),
                      textStyle: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // --- General Settings Section ---
          const SectionHeader(
            title: 'الإعدادات العامة',
            padding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 0),
          ),
          // General Settings Card - Match general Card style
          Card(
            margin: cardMargin,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12), // Match theme --radius
              side: BorderSide(
                color: colorScheme.outline.withOpacity(0.5),
              ), // Subtle border
            ),
            child: Padding(
              padding: cardPadding, // Use reduced padding
              child: Column(
                children: [
                  SwitchListTile(
                    contentPadding: tileContentPadding, // Apply content padding
                    title: const Text('الوضع الداكن'),
                    secondary: Icon(
                      settingsProvider.themeMode == ThemeMode.dark
                          ? Icons.dark_mode_outlined
                          : Icons.light_mode_outlined,
                      color:
                          colorScheme
                              .onSurfaceVariant, // Use muted color for icon
                    ),
                    value: settingsProvider.themeMode == ThemeMode.dark,
                    onChanged: (bool value) {
                      settingsProvider.updateThemeMode(
                        value ? ThemeMode.dark : ThemeMode.light,
                      );
                    },
                  ),
                  _buildDivider(context),
                  ListTile(
                    contentPadding: tileContentPadding, // Apply content padding
                    leading: Icon(
                      Icons.language_outlined,
                      color:
                          colorScheme
                              .onSurfaceVariant, // Use muted color for icon
                    ),
                    title: const Text('اللغة'),
                    trailing: Row(
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
                  _buildDivider(context),
                  SwitchListTile(
                    contentPadding: tileContentPadding, // Apply content padding
                    title: const Text('الإشعارات'),
                    secondary: Icon(
                      Icons.notifications_outlined,
                      color:
                          colorScheme
                              .onSurfaceVariant, // Use muted color for icon
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
          const SectionHeader(
            title: 'الأمان والخصوصية',
            padding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 0),
          ),
          // Security Card - Match general Card style
          Card(
            margin: cardMargin,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12), // Match theme --radius
              side: BorderSide(
                color: colorScheme.outline.withOpacity(0.5),
              ), // Subtle border
            ),
            child: Padding(
              padding: cardPadding, // Use reduced padding
              child: Column(
                children: [
                  ListTile(
                    contentPadding: tileContentPadding, // Apply content padding
                    leading: Icon(
                      Icons.lock_outline,
                      color:
                          colorScheme
                              .onSurfaceVariant, // Use muted color for icon
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
                  _buildDivider(context),
                  ListTile(
                    contentPadding: tileContentPadding, // Apply content padding
                    leading: Icon(
                      Icons.privacy_tip_outlined,
                      color:
                          colorScheme
                              .onSurfaceVariant, // Use muted color for icon
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
          const SectionHeader(
            title: 'الاشتراك',
            padding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 0),
          ),
          // Subscription Card - Match general Card style
          Card(
            margin: cardMargin,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12), // Match theme --radius
              side: BorderSide(
                color: colorScheme.outline.withOpacity(0.5),
              ), // Subtle border
            ),
            child: Padding(
              padding: cardPadding, // Use reduced padding
              child: ListTile(
                contentPadding: tileContentPadding, // Apply content padding
                leading: Icon(
                  Icons.workspace_premium_outlined,
                  color:
                      colorScheme.onSurfaceVariant, // Use muted color for icon
                ),
                title: const Text('الاشتراك المميز (Premium)'),
                subtitle: const Text('إزالة الإعلانات، سجل البحث، والمزيد!'),
                // Use a more subtle badge/chip style
                trailing: Chip(
                  label: Text(
                    'مستخدم مجاني', // TODO: Update based on actual status
                  ),
                  backgroundColor:
                      colorScheme.surfaceVariant, // Use surface variant
                  labelStyle: TextStyle(
                    color:
                        colorScheme.onSurfaceVariant, // Use on surface variant
                    fontSize: 12,
                  ),
                  side: BorderSide.none, // Remove border
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                  ), // Adjust padding
                  visualDensity: VisualDensity.compact,
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
          const SectionHeader(
            title: 'حول التطبيق',
            padding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 0),
          ),
          // About Card - Match general Card style
          Card(
            margin: cardMargin,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12), // Match theme --radius
              side: BorderSide(
                color: colorScheme.outline.withOpacity(0.5),
              ), // Subtle border
            ),
            child: Padding(
              padding: cardPadding, // Use reduced padding
              child: Column(
                children: [
                  ListTile(
                    contentPadding: tileContentPadding, // Apply content padding
                    leading: Icon(
                      Icons.info_outline,
                      color:
                          colorScheme
                              .onSurfaceVariant, // Use muted color for icon
                    ),
                    title: const Text('إصدار التطبيق'),
                    trailing: Text(
                      'v1.0.0', // Placeholder version
                      style: TextStyle(color: colorScheme.onSurfaceVariant),
                    ),
                  ),
                  _buildDivider(context),
                  ListTile(
                    contentPadding: tileContentPadding, // Apply content padding
                    leading: Icon(
                      Icons.gavel_outlined,
                      color:
                          colorScheme
                              .onSurfaceVariant, // Use muted color for icon
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
                          'https://www.google.com', // Placeholder URL
                        ), // TODO: Replace with actual Terms URL
                  ),
                  _buildDivider(context),
                  ListTile(
                    contentPadding: tileContentPadding, // Apply content padding
                    leading: Icon(
                      Icons.privacy_tip_outlined,
                      color:
                          colorScheme
                              .onSurfaceVariant, // Use muted color for icon
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
                          'https://www.google.com', // Placeholder URL
                        ), // TODO: Replace with actual Privacy URL
                  ),
                  _buildDivider(context),
                  ListTile(
                    contentPadding: tileContentPadding, // Apply content padding
                    leading: Icon(
                      Icons.history_outlined,
                      color:
                          colorScheme
                              .onSurfaceVariant, // Use muted color for icon
                    ),
                    title: const Text('تاريخ آخر تحديث للبيانات'),
                    subtitle: Text(
                      medicineProvider.lastUpdateTimestampFormatted,
                    ),
                  ),
                  _buildDivider(context),
                  ListTile(
                    contentPadding: tileContentPadding, // Apply content padding
                    leading: Icon(
                      Icons.update_outlined,
                      color:
                          colorScheme
                              .onSurfaceVariant, // Use muted color for icon
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
              // Match shadcn Button (destructive variant)
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 45),
                backgroundColor: colorScheme.error, // Use error color
                foregroundColor: colorScheme.onError, // Use onError color
                elevation: 0, // Flat style
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    8.0,
                  ), // Match theme --radius
                ),
                textStyle: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper for dividers within cards
  Widget _buildDivider(BuildContext context) {
    // Accept context
    // Use Theme's dividerColor
    return Divider(
      height: 1,
      indent: 16,
      endIndent: 16,
      color: Theme.of(context).dividerColor.withOpacity(0.5),
    );
  }

  // Helper to show language selection dialog
  Future<Locale?> _showLanguageDialog(BuildContext context) async {
    // TODO: Improve dialog styling to match shadcn/ui Dialog/AlertDialog if possible
    return await showDialog<Locale>(
      context: context,
      builder: (BuildContext context) {
        // Use AlertDialog for a more standard look, closer to shadcn
        return AlertDialog(
          title: const Text('اختر اللغة'),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ), // Match card radius
          contentPadding: const EdgeInsets.only(
            top: 12.0,
            bottom: 0,
          ), // Adjust padding
          content: Column(
            mainAxisSize: MainAxisSize.min, // Make column height fit content
            children: <Widget>[
              RadioListTile<Locale>(
                title: const Text('العربية'),
                value: const Locale('ar'),
                groupValue:
                    context
                        .read<SettingsProvider>()
                        .locale, // Get current locale
                onChanged: (Locale? value) => Navigator.pop(context, value),
              ),
              RadioListTile<Locale>(
                title: const Text('English'),
                value: const Locale('en'),
                groupValue: context.read<SettingsProvider>().locale,
                onChanged: (Locale? value) => Navigator.pop(context, value),
              ),
            ],
          ),
          // Add actions if needed (e.g., Cancel button)
          // actions: <Widget>[
          //   TextButton(
          //     child: const Text('إلغاء'),
          //     onPressed: () => Navigator.of(context).pop(),
          //   ),
          // ],
        );
      },
    );
  }
}
