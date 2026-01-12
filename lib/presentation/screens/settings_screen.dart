import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mediswitch/presentation/theme/app_colors.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/di/locator.dart';
import '../../core/services/file_logger_service.dart';
import '../bloc/medicine_provider.dart';
import '../bloc/settings_provider.dart';
import '../pages/specialty_download_screen.dart';
import '../widgets/settings_list_tile.dart';
import 'admin/dashboard_screen.dart';
import 'debug/log_viewer_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  static final FileLoggerService _logger = locator<FileLoggerService>();

  static Future<void> _launchUrl(String urlString) async {
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

  @override
  Widget build(BuildContext context) {
    final settingsProvider = context.watch<SettingsProvider>();
    final medicineProvider = context.watch<MedicineProvider>();
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isRTL = Directionality.of(context) == TextDirection.rtl;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          // Sticky Header
          SliverAppBar(
            pinned: true,
            backgroundColor: theme.colorScheme.surface.withValues(
              alpha: 0.95,
            ), // backdrop-blur check
            elevation: 0,
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: Icon(
                    isRTL ? LucideIcons.arrowRight : LucideIcons.arrowLeft,
                    color: theme.colorScheme.onSurface,
                    size: 20,
                  ),
                  onPressed: () => Navigator.pop(context),
                  tooltip: l10n.backButtonTooltip,
                ),
              ),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    LucideIcons.settings,
                    color: theme.colorScheme.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.settingsTitle,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    Text(
                      isRTL ? 'تخصيص تجربتك' : 'Customize your experience',
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1.0),
              child: Container(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.2),
                height: 1.0,
              ),
            ),
          ),

          // Content
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // 1. Notifications Section (First in Docs)
                _buildSectionTitle(
                  context,
                  isRTL ? 'الإشعارات' : 'Notifications',
                ),
                _buildCard(
                  context,
                  children: [
                    SettingsListTile(
                      title: isRTL ? 'الإشعارات الفورية' : 'Push Notifications',
                      leadingIcon: LucideIcons.bell,
                      trailing: Switch(
                        value: settingsProvider.pushNotificationsEnabled,
                        onChanged:
                            (v) => settingsProvider.updatePushNotifications(v),
                      ),
                    ),
                    _buildDivider(context),
                    SettingsListTile(
                      title: isRTL ? 'تنبيهات الأسعار' : 'Price Change Alerts',
                      leadingIcon: LucideIcons.creditCard,
                      trailing: Switch(
                        value: settingsProvider.priceAlertsEnabled,
                        onChanged: (v) => settingsProvider.updatePriceAlerts(v),
                      ),
                    ),
                    _buildDivider(context),
                    SettingsListTile(
                      title:
                          isRTL ? 'تنبيهات الأدوية الجديدة' : 'New Drug Alerts',
                      leadingIcon: LucideIcons.star,
                      trailing: Switch(
                        value: settingsProvider.newDrugAlertsEnabled,
                        onChanged:
                            (v) => settingsProvider.updateNewDrugAlerts(v),
                      ),
                    ),
                    _buildDivider(context),
                    SettingsListTile(
                      title:
                          isRTL ? 'تحذيرات التفاعلات' : 'Interaction Warnings',
                      leadingIcon: LucideIcons.shield,
                      trailing: Switch(
                        value: settingsProvider.interactionAlertsEnabled,
                        onChanged:
                            (v) => settingsProvider.updateInteractionAlerts(v),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // 2. Appearance Section
                _buildSectionTitle(context, l10n.generalSectionTitle),
                _buildCard(
                  context,
                  children: [
                    SettingsListTile(
                      title: l10n.appearanceSettingTitle,
                      leadingIcon:
                          isDarkMode(context)
                              ? LucideIcons.moon
                              : LucideIcons.sun,
                      trailing: Switch(
                        value: settingsProvider.themeMode == ThemeMode.dark,
                        onChanged: (isDark) {
                          if (settingsProvider.isInitialized) {
                            settingsProvider.updateThemeMode(
                              isDark ? ThemeMode.dark : ThemeMode.light,
                            );
                          }
                        },
                      ),
                      onTap: () {
                        if (settingsProvider.isInitialized) {
                          settingsProvider.updateThemeMode(
                            settingsProvider.themeMode == ThemeMode.dark
                                ? ThemeMode.light
                                : ThemeMode.dark,
                          );
                        }
                      },
                    ),
                    _buildDivider(context),
                    SettingsListTile(
                      title: l10n.languageSettingTitle,
                      subtitle:
                          settingsProvider.locale.languageCode == 'ar'
                              ? l10n.languageArabic
                              : l10n.languageEnglish,
                      leadingIcon: LucideIcons.globe,
                      trailing: const Icon(
                        LucideIcons.chevronRight,
                        size: 18,
                      ), // Or custom logic
                      onTap:
                          () => _showLanguageDialog(context, settingsProvider),
                    ),
                    _buildDivider(context),
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
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  settingsProvider.locale.languageCode == 'ar'
                                      ? 'حجم الخط'
                                      : 'Font Size',
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              Text(
                                '${settingsProvider.fontSize.toInt()}px',
                                style: TextStyle(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
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
                              onChanged:
                                  (value) =>
                                      settingsProvider.updateFontSize(value),
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                isRTL ? 'صغير' : 'Small',
                                style: theme.textTheme.bodySmall,
                              ),
                              Text(
                                isRTL ? 'كبير' : 'Large',
                                style: theme.textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // 3. Sound & Haptics Section (New)
                _buildSectionTitle(
                  context,
                  isRTL ? 'الصوت والاهتزاز' : 'Sound & Haptics',
                ),
                _buildCard(
                  context,
                  children: [
                    SettingsListTile(
                      title: isRTL ? 'المؤثرات الصوتية' : 'Sound Effects',
                      leadingIcon: LucideIcons.volume2,
                      trailing: Switch(
                        value: settingsProvider.soundEffectsEnabled,
                        onChanged:
                            (v) => settingsProvider.updateSoundEffects(v),
                      ),
                    ),
                    _buildDivider(context),
                    SettingsListTile(
                      title: isRTL ? 'الاهتزاز' : 'Haptic Feedback',
                      leadingIcon: LucideIcons.vibrate,
                      trailing: Switch(
                        value: settingsProvider.hapticFeedbackEnabled,
                        onChanged:
                            (v) => settingsProvider.updateHapticFeedback(v),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // 4. Data Section
                _buildSectionTitle(context, l10n.dataSectionTitle),
                _buildCard(
                  context,
                  children: [
                    SettingsListTile(
                      title: l10n.lastDataUpdateTitle,
                      subtitle: _formatTimestamp(
                        context,
                        medicineProvider.lastUpdateTimestamp,
                        l10n,
                      ),
                      leadingIcon: LucideIcons.refreshCw,
                      onTap: () async {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(l10n.checkingForUpdatesSnackbar),
                            duration: const Duration(seconds: 1),
                          ),
                        );
                        await medicineProvider.loadInitialData();
                      },
                    ),
                    _buildDivider(context),
                    SettingsListTile(
                      title: isRTL ? 'الوضع دون اتصال' : 'Offline Mode',
                      leadingIcon: LucideIcons.download,
                      trailing: Switch(
                        value: settingsProvider.offlineModeEnabled,
                        onChanged: (v) => settingsProvider.updateOfflineMode(v),
                      ),
                    ),
                    _buildDivider(context),
                    SettingsListTile(
                      title:
                          isRTL
                              ? 'تحميل بيانات التخصص'
                              : 'Download Specialty Data',
                      subtitle:
                          isRTL
                              ? 'حمّل البيانات حسب مجال تخصصك'
                              : 'Download data for your specialty',
                      leadingIcon: LucideIcons.stethoscope,
                      trailing: const Icon(LucideIcons.chevronRight, size: 18),
                      onTap:
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const SpecialtyDownloadScreen(),
                            ),
                          ),
                    ),
                    _buildDivider(context),
                    SettingsListTile(
                      title: isRTL ? 'حجم التخزين المؤقت' : 'Cache Size',
                      leadingIcon: LucideIcons.database,
                      trailing: const Icon(LucideIcons.chevronRight, size: 18),
                      subtitle:
                          isRTL ? '12.5 ميجابايت' : '12.5 MB', // Hack for now
                      onTap: () {},
                    ),
                    _buildDivider(context),
                    SettingsListTile(
                      title: isRTL ? 'مسح السجل' : 'Clear History',
                      leadingIcon: LucideIcons.trash2,
                      trailing: const Icon(LucideIcons.chevronRight, size: 18),
                      onTap: () {
                        context.read<MedicineProvider>().clearRecentlyViewed();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              isRTL
                                  ? 'تم مسح سجل البحث'
                                  : 'Search history cleared',
                            ),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                    ),
                    _buildDivider(context),
                    SettingsListTile(
                      title: l10n.viewDebugLogsTitle,
                      leadingIcon: LucideIcons.fileText,
                      onTap:
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const LogViewerScreen(),
                            ),
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // 5. Location Section (New)
                _buildSectionTitle(context, isRTL ? 'الموقع' : 'Location'),
                _buildCard(
                  context,
                  children: [
                    SettingsListTile(
                      title: isRTL ? 'الموقع' : 'Location',
                      leadingIcon: LucideIcons.mapPin,
                      trailing: Text(
                        isRTL ? 'مصر' : 'Egypt',
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    _buildDivider(context),
                    SettingsListTile(
                      title: isRTL ? 'العملة' : 'Currency',
                      leadingIcon: LucideIcons.creditCard,
                      trailing: Text(
                        isRTL ? 'جنيه مصري' : 'EGP',
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // 6. About Section
                _buildSectionTitle(context, l10n.aboutSectionTitle),
                _buildCard(
                  context,
                  children: [
                    SettingsListTile(
                      title: l10n.aboutAppTitle,
                      leadingIcon: LucideIcons.info,
                      onTap: () => _launchUrl('https://example.com/about'),
                    ),
                    _buildDivider(context),
                    SettingsListTile(
                      title: l10n.privacyPolicyTitle,
                      leadingIcon: LucideIcons.shieldCheck,
                      onTap: () => _launchUrl('https://example.com/privacy'),
                    ),
                    _buildDivider(context),
                    SettingsListTile(
                      title: l10n.termsOfUseTitle,
                      leadingIcon: LucideIcons.gavel,
                      onTap: () => _launchUrl('https://example.com/terms'),
                    ),
                    _buildDivider(context),
                    SettingsListTile(
                      title: isRTL ? 'الملاحظات' : 'Feedback',
                      leadingIcon: LucideIcons.messageSquare,
                      onTap: () => _launchUrl('mailto:support@mediswitch.com'),
                    ),
                    _buildDivider(context),
                    SettingsListTile(
                      title: isRTL ? 'قيم التطبيق' : 'Rate App',
                      leadingIcon: LucideIcons.star,
                      onTap:
                          () =>
                              _launchUrl('market://details?id=com.mediswitch'),
                    ),
                    _buildDivider(context),
                    SettingsListTile(
                      title: l10n.appVersionTitle,
                      subtitle: '1.0.0',
                      leadingIcon: LucideIcons.tag,
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // 7. Administration Section (New)
                _buildSectionTitle(
                  context,
                  isRTL ? 'الإدارة' : 'Administration',
                ),
                _buildCard(
                  context,
                  children: [
                    SettingsListTile(
                      title: isRTL ? 'لوحة التحكم' : 'Admin Dashboard',
                      leadingIcon: LucideIcons.layoutDashboard,
                      leadingIconColor: theme.colorScheme.primary,
                      onTap:
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const AdminDashboardScreen(),
                            ),
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // Danger Zone
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 8),
                  child: Text(
                    isRTL ? 'منطقة الخطر' : 'Danger Zone',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.error,
                    ),
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.error.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: theme.colorScheme.error.withValues(alpha: 0.2),
                    ),
                  ),
                  child: SettingsListTile(
                    title: isRTL ? 'حذف جميع البيانات' : 'Delete All Data',
                    subtitle:
                        isRTL
                            ? 'سيؤدي هذا إلى حذف جميع بياناتك'
                            : 'This will delete all your data',
                    leadingIcon: LucideIcons.trash2,
                    leadingIconColor: theme.colorScheme.error,
                    titleColor: theme.colorScheme.error,
                    onTap:
                        () =>
                            _showDeleteConfirmDialog(context, settingsProvider),
                  ),
                ),

                const SizedBox(height: 80),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _buildCard(BuildContext context, {required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppColors.shadowCard,
      ),
      child: Column(children: children),
    );
  }

  Widget _buildDivider(BuildContext context) {
    return Divider(
      height: 1,
      indent: 56,
      color: Theme.of(
        context,
      ).colorScheme.outlineVariant.withValues(alpha: 0.2),
    );
  }

  bool isDarkMode(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  String _formatTimestamp(
    BuildContext context,
    int? timestamp,
    AppLocalizations l10n,
  ) {
    if (timestamp == null) return l10n.neverUpdated;
    // Simple format, can use intl DateFormat
    return DateTime.fromMillisecondsSinceEpoch(
      timestamp,
    ).toString().split('.')[0];
  }

  Future<void> _showLanguageDialog(
    BuildContext context,
    SettingsProvider provider,
  ) async {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context)!.languageSettingTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text(AppLocalizations.of(context)!.languageArabic),
                onTap: () {
                  provider.updateLocale(const Locale('ar'));
                  Navigator.pop(context);
                },
                trailing:
                    provider.locale.languageCode == 'ar'
                        ? const Icon(LucideIcons.check)
                        : null,
              ),
              ListTile(
                title: Text(AppLocalizations.of(context)!.languageEnglish),
                onTap: () {
                  provider.updateLocale(const Locale('en'));
                  Navigator.pop(context);
                },
                trailing:
                    provider.locale.languageCode == 'en'
                        ? const Icon(LucideIcons.check)
                        : null,
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showDeleteConfirmDialog(
    BuildContext context,
    SettingsProvider provider,
  ) async {
    final isRTL = Directionality.of(context) == TextDirection.rtl;
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(isRTL ? 'حذف جميع البيانات' : 'Delete All Data'),
            content: Text(
              isRTL
                  ? 'هل أنت متأكد أنك تريد حذف جميع البيانات؟ لا يمكن التراجع عن هذا الإجراء.'
                  : 'Are you sure you want to delete all data? This action cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(isRTL ? 'إلغاء' : 'Cancel'),
              ),
              TextButton(
                onPressed: () {
                  provider.clearAllData();
                  Navigator.pop(context);
                },
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: Text(isRTL ? 'حذف' : 'Delete'),
              ),
            ],
          ),
    );
  }
}
