import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart'; // Import generated localizations
import 'package:intl/intl.dart'; // Import intl for DateFormat
import 'package:lucide_icons/lucide_icons.dart'; // Import Lucide Icons
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/app_spacing.dart'; // Import spacing constants
import '../../core/di/locator.dart';
import '../../core/services/file_logger_service.dart';
import '../bloc/medicine_provider.dart';
import '../bloc/settings_provider.dart';
import '../screens/subscription_screen.dart';
import '../widgets/settings_list_tile.dart';
import 'debug/log_viewer_screen.dart'; // Import the log viewer screen

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
    final l10n = AppLocalizations.of(context)!; // Get l10n instance

    return Scaffold(
      // Use localized string for AppBar title
      appBar: AppBar(title: Text(l10n.settingsTitle)),
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
              // Use localized string
              title: l10n.generalSectionTitle,
              children: [
                SettingsListTile(
                  // Use localized string for Language setting title
                  title: l10n.languageSettingTitle,
                  subtitle:
                      settingsProvider.locale.languageCode == 'ar'
                          ? l10n
                              .languageArabic // Use localized string
                          : l10n.languageEnglish, // Use localized string
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
                  // Use localized string
                  title: l10n.appearanceSettingTitle,
                  subtitle: _themeModeToString(
                    settingsProvider.themeMode,
                    l10n,
                  ), // Pass l10n
                  leadingIcon:
                      isDarkMode(context) ? LucideIcons.moon : LucideIcons.sun,
                  trailing: Switch(
                    value: settingsProvider.themeMode == ThemeMode.dark,
                    // Allow interaction always, but check initialization inside
                    onChanged: (isDark) {
                      // Check if initialized before updating
                      if (settingsProvider.isInitialized) {
                        _logger.i(
                          "SettingsScreen: Theme switch toggled to ${isDark ? 'Dark' : 'Light'}.",
                        );
                        settingsProvider.updateThemeMode(
                          isDark ? ThemeMode.dark : ThemeMode.light,
                        );
                      } else {
                        _logger.w(
                          "SettingsScreen: Theme switch toggled but provider not initialized yet.",
                        );
                      }
                    },
                  ),
                  // Allow interaction always, but check initialization inside
                  onTap: () {
                    // Check if initialized before updating
                    if (settingsProvider.isInitialized) {
                      bool currentIsDark =
                          settingsProvider.themeMode == ThemeMode.dark;
                      _logger.i(
                        "SettingsScreen: Theme tile tapped. Toggling to ${currentIsDark ? 'Light' : 'Dark'}.",
                      );
                      settingsProvider.updateThemeMode(
                        currentIsDark ? ThemeMode.light : ThemeMode.dark,
                      );
                    } else {
                      _logger.w(
                        "SettingsScreen: Theme tile tapped but provider not initialized yet.",
                      );
                    }
                  },
                ),
                // Font Size Slider
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            LucideIcons.type,
                            size: 20,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              settingsProvider.locale.languageCode == 'ar'
                                  ? 'حجم الخط'
                                  : 'Font Size',
                              style: textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Text(
                            '${settingsProvider.fontSize.toInt()}px',
                            style: textTheme.bodyMedium?.copyWith(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackHeight: 4,
                          thumbShape: const RoundSliderThumbShape(
                            enabledThumbRadius: 8,
                          ),
                        ),
                        child: Slider(
                          value: settingsProvider.fontSize,
                          min: 12,
                          max: 24,
                          divisions: 12,
                          onChanged: (value) {
                            settingsProvider.updateFontSize(value);
                          },
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            settingsProvider.locale.languageCode == 'ar'
                                ? 'صغير'
                                : 'Small',
                            style: textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          Text(
                            settingsProvider.locale.languageCode == 'ar'
                                ? 'كبير'
                                : 'Large',
                            style: textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            AppSpacing.gapVLarge,
            // --- Notifications Section ---
            _buildSectionCard(
              context,
              title:
                  settingsProvider.locale.languageCode == 'ar'
                      ? 'الإشعارات'
                      : 'Notifications',
              children: [
                SettingsListTile(
                  title:
                      settingsProvider.locale.languageCode == 'ar'
                          ? 'الإشعارات الفورية'
                          : 'Push Notifications',
                  subtitle:
                      settingsProvider.locale.languageCode == 'ar'
                          ? 'تلقي إشعارات التطبيق'
                          : 'Receive app notifications',
                  leadingIcon: LucideIcons.bell,
                  trailing: Switch(
                    value: settingsProvider.pushNotificationsEnabled,
                    onChanged: (value) {
                      settingsProvider.updatePushNotifications(value);
                    },
                  ),
                  onTap: () {
                    settingsProvider.updatePushNotifications(
                      !settingsProvider.pushNotificationsEnabled,
                    );
                  },
                ),
                SettingsListTile(
                  title:
                      settingsProvider.locale.languageCode == 'ar'
                          ? 'تنبيهات الأسعار'
                          : 'Price Change Alerts',
                  subtitle:
                      settingsProvider.locale.languageCode == 'ar'
                          ? 'إشعار عند تغيير الأسعار'
                          : 'Get notified when prices change',
                  leadingIcon: LucideIcons.creditCard,
                  trailing: Switch(
                    value: settingsProvider.priceAlertsEnabled,
                    onChanged: (value) {
                      settingsProvider.updatePriceAlerts(value);
                    },
                  ),
                  onTap: () {
                    settingsProvider.updatePriceAlerts(
                      !settingsProvider.priceAlertsEnabled,
                    );
                  },
                ),
                SettingsListTile(
                  title:
                      settingsProvider.locale.languageCode == 'ar'
                          ? 'تنبيهات الأدوية الجديدة'
                          : 'New Drug Alerts',
                  leadingIcon: LucideIcons.star,
                  trailing: Switch(
                    value: settingsProvider.newDrugAlertsEnabled,
                    onChanged: (value) {
                      settingsProvider.updateNewDrugAlerts(value);
                    },
                  ),
                  onTap: () {
                    settingsProvider.updateNewDrugAlerts(
                      !settingsProvider.newDrugAlertsEnabled,
                    );
                  },
                ),
                SettingsListTile(
                  title:
                      settingsProvider.locale.languageCode == 'ar'
                          ? 'تحذيرات التفاعلات'
                          : 'Interaction Warnings',
                  subtitle:
                      settingsProvider.locale.languageCode == 'ar'
                          ? 'تنبيهات السلامة الحرجة'
                          : 'Critical safety alerts',
                  leadingIcon: LucideIcons.shield,
                  trailing: Switch(
                    value: settingsProvider.interactionAlertsEnabled,
                    onChanged: (value) {
                      settingsProvider.updateInteractionAlerts(value);
                    },
                  ),
                  onTap: () {
                    settingsProvider.updateInteractionAlerts(
                      !settingsProvider.interactionAlertsEnabled,
                    );
                  },
                ),
              ],
            ),
            AppSpacing.gapVLarge,
            // --- Sound & Haptics Section ---
            _buildSectionCard(
              context,
              title:
                  settingsProvider.locale.languageCode == 'ar'
                      ? 'الصوت والاهتزاز'
                      : 'Sound & Haptics',
              children: [
                SettingsListTile(
                  title:
                      settingsProvider.locale.languageCode == 'ar'
                          ? 'المؤثرات الصوتية'
                          : 'Sound Effects',
                  leadingIcon: LucideIcons.volume2,
                  trailing: Switch(
                    value: settingsProvider.soundEffectsEnabled,
                    onChanged: (value) {
                      settingsProvider.updateSoundEffects(value);
                    },
                  ),
                  onTap: () {
                    settingsProvider.updateSoundEffects(
                      !settingsProvider.soundEffectsEnabled,
                    );
                  },
                ),
                SettingsListTile(
                  title:
                      settingsProvider.locale.languageCode == 'ar'
                          ? 'الاهتزاز'
                          : 'Haptic Feedback',
                  leadingIcon: LucideIcons.smartphone,
                  trailing: Switch(
                    value: settingsProvider.hapticFeedbackEnabled,
                    onChanged: (value) {
                      settingsProvider.updateHapticFeedback(value);
                    },
                  ),
                  onTap: () {
                    settingsProvider.updateHapticFeedback(
                      !settingsProvider.hapticFeedbackEnabled,
                    );
                  },
                ),
              ],
            ),
            AppSpacing.gapVLarge, // Use constant (16px)
            // --- Data Section ---
            _buildSectionCard(
              context,
              // Use localized string
              title: l10n.dataSectionTitle,
              children: [
                SettingsListTile(
                  title: l10n.lastDataUpdateTitle, // Use localized string
                  subtitle: _formatTimestamp(
                    // Call helper function
                    context,
                    medicineProvider.lastUpdateTimestamp, // Pass raw timestamp
                    l10n, // Pass localizations
                  ),
                  leadingIcon: LucideIcons.refreshCw,
                  trailing: IconButton(
                    icon: const Icon(LucideIcons.refreshCw, size: 20),
                    tooltip: l10n.checkForUpdateTooltip, // Use localized string
                    onPressed: () async {
                      _logger.i("SettingsScreen: Refresh data button pressed.");
                      // Show snackbar *before* async operation
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            l10n.checkingForUpdatesSnackbar,
                          ), // Use localized string
                          duration: const Duration(
                            seconds: 1,
                          ), // Shorter duration
                        ),
                      );
                      await medicineProvider.loadInitialData();
                      // Check if mounted *after* await before showing next snackbar
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).hideCurrentSnackBar();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              medicineProvider.error.contains(
                                    'فشل',
                                  ) // Keep error check logic
                                  ? medicineProvider
                                      .error // Show specific error if available
                                  : l10n
                                      .dataUpToDateSnackbar, // Use localized string
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
                // Offline Mode Toggle
                SettingsListTile(
                  title:
                      settingsProvider.locale.languageCode == 'ar'
                          ? 'الوضع دون اتصال'
                          : 'Offline Mode',
                  subtitle:
                      settingsProvider.locale.languageCode == 'ar'
                          ? 'تحميل قاعدة البيانات للاستخدام دون اتصال'
                          : 'Download database for offline use',
                  leadingIcon: LucideIcons.download,
                  trailing: Switch(
                    value: settingsProvider.offlineModeEnabled,
                    onChanged: (value) {
                      settingsProvider.updateOfflineMode(value);
                    },
                  ),
                  onTap: () {
                    settingsProvider.updateOfflineMode(
                      !settingsProvider.offlineModeEnabled,
                    );
                  },
                ),
                // --- Add Log Viewer Tile ---
                SettingsListTile(
                  title: l10n.viewDebugLogsTitle, // Use localized string
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
              // Use localized string
              title: l10n.subscriptionSectionTitle,
              children: [
                SettingsListTile(
                  title: l10n.manageSubscriptionTitle, // Use localized string
                  subtitle:
                      l10n.manageSubscriptionSubtitle, // Use localized string
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
              // Use localized string
              title: l10n.aboutSectionTitle,
              children: [
                SettingsListTile(
                  title: l10n.aboutAppTitle, // Use localized string
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
                  title: l10n.privacyPolicyTitle, // Use localized string
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
                  title: l10n.termsOfUseTitle, // Use localized string
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
                  title: l10n.appVersionTitle, // Use localized string
                  subtitle: '1.0.0+1', // TODO: Get version dynamically
                  leadingIcon: LucideIcons.tag,
                  onTap: null,
                ),
              ],
            ),
            AppSpacing.gapVXLarge, // Use constant (24px)
            // --- Danger Zone ---
            Padding(
              padding: AppSpacing.edgeInsetsHSmall,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 8, bottom: 8),
                    child: Text(
                      settingsProvider.locale.languageCode == 'ar'
                          ? 'منطقة الخطر'
                          : 'Danger Zone',
                      style: textTheme.titleSmall?.copyWith(
                        color: colorScheme.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: colorScheme.error.withOpacity(0.05),
                      border: Border.all(
                        color: colorScheme.error.withOpacity(0.2),
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap:
                            () => _showDeleteConfirmDialog(
                              context,
                              settingsProvider,
                            ),
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: colorScheme.error.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  LucideIcons.trash2,
                                  size: 18,
                                  color: colorScheme.error,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      settingsProvider.locale.languageCode ==
                                              'ar'
                                          ? 'حذف جميع البيانات'
                                          : 'Delete All Data',
                                      style: textTheme.bodyLarge?.copyWith(
                                        color: colorScheme.error,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Text(
                                      settingsProvider.locale.languageCode ==
                                              'ar'
                                          ? 'سيؤدي هذا إلى حذف جميع بياناتك'
                                          : 'This will delete all your data',
                                      style: textTheme.bodySmall?.copyWith(
                                        color: colorScheme.error.withOpacity(
                                          0.7,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            AppSpacing.gapVLarge,
            // --- Logout Button ---
            Padding(
              padding: AppSpacing.edgeInsetsHSmall, // Use constant (8px)
              child: ElevatedButton.icon(
                icon: const Icon(LucideIcons.logOut, size: 18),
                label: Text(l10n.logoutButton), // Use localized string
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
    final l10n = AppLocalizations.of(context)!; // Get l10n instance
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    // Use localized placeholders
    final String userName = l10n.profileNamePlaceholder;
    final String userEmail = l10n.profileEmailPlaceholder;
    final String userInitial = l10n.profileInitialPlaceholder;

    return _buildSectionCard(
      context,
      // Use localized string
      title: l10n.profileSectionTitle,
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

  String _themeModeToString(ThemeMode themeMode, AppLocalizations l10n) {
    // Add l10n parameter
    switch (themeMode) {
      case ThemeMode.light:
        return l10n.themeModeLight; // Use localized string
      case ThemeMode.dark:
        return l10n.themeModeDark; // Use localized string
      case ThemeMode.system:
      default:
        return l10n.themeModeSystem; // Use localized string
    }
  }

  Future<void> _showLanguageDialog(
    BuildContext context,
    SettingsProvider provider,
  ) async {
    _logger.d("SettingsScreen: Showing language dialog.");
    final l10n = AppLocalizations.of(context)!; // Get l10n instance
    final currentLocale = provider.locale;
    final selectedLocale = await showDialog<Locale>(
      context: context,
      builder: (BuildContext dialogContext) {
        // Use different context name
        return AlertDialog(
          title: Text(l10n.languageDialogTitle), // Use localized string
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              RadioListTile<Locale>(
                title: Text(l10n.languageArabic), // Use localized string
                value: const Locale('ar'),
                groupValue: currentLocale,
                onChanged: (Locale? value) {
                  Navigator.pop(dialogContext, value); // Use dialogContext
                },
              ),
              RadioListTile<Locale>(
                title: Text(l10n.languageEnglish), // Use localized string
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
              child: Text(l10n.dialogCancelButton), // Use localized string
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

  // Helper function to format the timestamp locally
  String _formatTimestamp(
    BuildContext context,
    int? timestamp,
    AppLocalizations l10n,
  ) {
    if (timestamp == null) {
      return l10n.lastUpdateUnavailable; // Use localized string
    }
    try {
      final dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
      final locale =
          Localizations.localeOf(
            context,
          ).toString(); // Get current locale string
      // Use locale-aware formatting
      return DateFormat('d MMM yyyy, HH:mm', locale).format(dateTime);
    } catch (e) {
      _logger.e("Error formatting timestamp in SettingsScreen", e);
      return l10n.lastUpdateInvalidFormat; // Use localized string
    }
  }

  // Show confirm dialog for deleting all data
  static Future<void> _showDeleteConfirmDialog(
    BuildContext context,
    SettingsProvider provider,
  ) async {
    final isAr = provider.locale.languageCode == 'ar';
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(isAr ? 'حذف جميع البيانات' : 'Delete All Data'),
            content: Text(
              isAr
                  ? 'هل أنت متأكد؟ سيتم حذف جميع الإعدادات والبيانات المحفوظة.'
                  : 'Are you sure? This will delete all settings and saved data.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(isAr ? 'إلغاء' : 'Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(
                  isAr ? 'حذف' : 'Delete',
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      await provider.clearAllData();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isAr ? 'تم حذف جميع البيانات' : 'All data deleted'),
          ),
        );
      }
    }
  }
}
