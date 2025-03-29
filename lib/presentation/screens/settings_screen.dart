import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../bloc/settings_provider.dart'; // Import the provider

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Use Consumer to listen to changes in SettingsProvider
    return Consumer<SettingsProvider>(
      builder: (context, settingsProvider, child) {
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
                onTap: () {
                  // TODO: Implement language selection dialog/options
                  print('Language setting tapped');
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('سيتم إضافة تغيير اللغة لاحقاً.'),
                    ),
                  );
                },
              ),
              const Divider(),
              // TODO: Add Subscription Management UI (Task 3.6.4)
              ListTile(
                leading: const Icon(Icons.subscriptions),
                title: const Text('إدارة الاشتراك'),
                onTap: () {
                  print('Subscription setting tapped');
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('سيتم إضافة إدارة الاشتراك لاحقاً.'),
                    ),
                  );
                },
              ),
              const Divider(),
              // TODO: Add Links using url_launcher (Task 3.6.5)
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('عن التطبيق'),
                onTap: () {
                  print('About App tapped');
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('سيتم إضافة معلومات التطبيق لاحقاً.'),
                    ),
                  );
                },
              ),
              const Divider(),
              // TODO: Add Check for Update button (Task 3.6.6)
              ListTile(
                leading: const Icon(Icons.system_update_alt),
                title: const Text('التحقق من وجود تحديثات'),
                onTap: () {
                  print('Check for update tapped');
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('سيتم إضافة التحقق من التحديثات لاحقاً.'),
                    ),
                  );
                },
              ),
              const Divider(),
              // TODO: Display Last Update Date (Task 3.6.7)
              // This needs data from MedicineProvider or another source
              ListTile(
                leading: const Icon(Icons.history),
                title: const Text('تاريخ آخر تحديث للبيانات'),
                subtitle: const Text('غير متوفر حالياً'), // Placeholder
                onTap: null, // Not interactive for now
              ),
            ],
          ),
        );
      },
    );
  }
}
