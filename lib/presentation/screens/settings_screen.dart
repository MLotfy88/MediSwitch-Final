import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart'; // Import url_launcher
import '../bloc/settings_provider.dart'; // Import the provider
import '../bloc/medicine_provider.dart'; // Import MedicineProvider to access timestamp

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Use Consumer2 to listen to both SettingsProvider and MedicineProvider
    return Consumer2<SettingsProvider, MedicineProvider>(
      builder: (context, settingsProvider, medicineProvider, child) {
        return Scaffold(
          appBar: AppBar(title: const Text('الإعدادات')),
          body: ListView(
            // Use ListView for settings items
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            children: [
              // Dark Mode Toggle
              SwitchListTile(
                title: const Text('الوضع الداكن'),
                secondary: Icon(
                  settingsProvider.themeMode == ThemeMode.dark
                      ? Icons.dark_mode
                      : Icons.light_mode,
                ),
                value: settingsProvider.themeMode == ThemeMode.dark,
                onChanged: (bool value) {
                  // Update theme mode using the provider
                  settingsProvider.updateThemeMode(
                    value ? ThemeMode.dark : ThemeMode.light,
                  );
                },
              ),
              const Divider(),
              // TODO: Add Language Selection (Task 3.6.3)
              ListTile(
                leading: const Icon(Icons.language),
                title: const Text('اللغة'),
                subtitle: Text(
                  settingsProvider.locale.languageCode == 'ar'
                      ? 'العربية'
                      : 'English',
                ),
                onTap: () async {
                  // Make onTap async
                  // Show language selection dialog
                  final Locale? selectedLocale = await showDialog<Locale>(
                    context: context,
                    builder: (BuildContext context) {
                      return SimpleDialog(
                        title: const Text('اختر اللغة'),
                        children: <Widget>[
                          SimpleDialogOption(
                            onPressed: () {
                              Navigator.pop(context, const Locale('ar'));
                            },
                            child: const Text('العربية'),
                          ),
                          SimpleDialogOption(
                            onPressed: () {
                              Navigator.pop(context, const Locale('en'));
                            },
                            child: const Text('English'),
                          ),
                        ],
                      );
                    },
                  );

                  // Update locale if a selection was made
                  if (selectedLocale != null && context.mounted) {
                    context.read<SettingsProvider>().updateLocale(
                      selectedLocale,
                    );
                  }
                },
              ),
              const Divider(),
              // Subscription Management UI Placeholder (Task 3.6.4)
              ListTile(
                leading: const Icon(
                  Icons.workspace_premium_outlined,
                ), // Changed icon
                title: const Text('الاشتراك المميز (Premium)'),
                subtitle: const Text(
                  'إزالة الإعلانات، سجل البحث، والمزيد!',
                ), // Added subtitle
                trailing: const Chip(
                  // Added a chip for status indication
                  label: Text('مستخدم مجاني'),
                  backgroundColor: Colors.grey,
                  labelStyle: TextStyle(color: Colors.white, fontSize: 12),
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
              const Divider(),
              // Links Section (Task 3.6.5)
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('عن التطبيق'),
                trailing: const Icon(Icons.open_in_new, size: 18),
                onTap: () {
                  // TODO: Replace with actual About page URL when available
                  _launchURL(context, 'https://example.com/about');
                },
              ),
              ListTile(
                leading: const Icon(Icons.privacy_tip_outlined),
                title: const Text('سياسة الخصوصية'),
                trailing: const Icon(Icons.open_in_new, size: 18),
                onTap: () {
                  // TODO: Replace with actual Privacy Policy URL
                  _launchURL(context, 'https://example.com/privacy');
                },
              ),
              ListTile(
                leading: const Icon(Icons.gavel_outlined),
                title: const Text('شروط الخدمة'),
                trailing: const Icon(Icons.open_in_new, size: 18),
                onTap: () {
                  // TODO: Replace with actual Terms of Service URL
                  _launchURL(context, 'https://example.com/terms');
                },
              ),
              const Divider(),
              // Check for Update button (Task 3.6.6)
              ListTile(
                leading: const Icon(Icons.system_update_alt),
                title: const Text('التحقق من وجود تحديثات'),
                onTap: () async {
                  // Make onTap async
                  // Show feedback that check is starting
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('جاري التحقق من وجود تحديثات...'),
                      duration: Duration(seconds: 2), // Short duration
                    ),
                  );
                  // Trigger the update check in MedicineProvider
                  // Use context.read as it's a one-off action
                  await context.read<MedicineProvider>().loadInitialData();
                  // Show feedback after completion (optional, depends on desired UX)
                  // Check if the widget is still mounted before showing another SnackBar
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('اكتمل التحقق من التحديثات.'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                },
              ),
              const Divider(),
              // Display Last Update Date (Task 3.6.7)
              ListTile(
                leading: const Icon(Icons.history),
                title: const Text('تاريخ آخر تحديث للبيانات'),
                subtitle: Text(
                  medicineProvider
                      .lastUpdateTimestampFormatted, // Get formatted timestamp
                ),
                onTap: null, // Not interactive
              ),
            ],
          ),
        );
      },
    );
  }

  // Helper function to launch URLs safely
  Future<void> _launchURL(BuildContext context, String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      // Show error message if URL can't be launched
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('تعذر فتح الرابط: $urlString')));
      }
      print('Could not launch $urlString');
    }
  }
}
