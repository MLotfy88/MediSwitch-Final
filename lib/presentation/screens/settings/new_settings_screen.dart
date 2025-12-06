import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../theme/app_colors.dart';
import '../../bloc/settings_provider.dart';
import '../../bloc/medicine_provider.dart';
import '../debug/log_viewer_screen.dart';
import '../../screens/subscription_screen.dart';

class NewSettingsScreen extends StatelessWidget {
  const NewSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final settingsProvider = context.watch<SettingsProvider>();
    final medicineProvider = context.watch<MedicineProvider>();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          // Header
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary,
                  AppColors.primary,
                  AppColors.primaryDark,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 16,
              bottom: 24,
              left: 16,
              right: 16,
            ),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(LucideIcons.arrowLeft, color: Colors.white),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white.withOpacity(0.1),
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  l10n.settingsTitle,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Profile Section
                _buildProfileCard(context, l10n),
                const SizedBox(height: 20),

                // General
                _buildSectionHeader(l10n.generalSectionTitle),
                _buildSettingsCard([
                  _buildTile(
                    context,
                    icon: LucideIcons.globe,
                    title: l10n.languageSettingTitle,
                    subtitle:
                        settingsProvider.locale.languageCode == 'ar'
                            ? "العربية"
                            : "English",
                    onTap:
                        () => _showLanguageDialog(
                          context,
                          settingsProvider,
                          l10n,
                        ),
                  ),
                  _buildDivider(),
                  _buildTile(
                    context,
                    icon:
                        settingsProvider.themeMode == ThemeMode.dark
                            ? LucideIcons.moon
                            : LucideIcons.sun,
                    title: l10n.appearanceSettingTitle,
                    subtitle:
                        settingsProvider.themeMode == ThemeMode.dark
                            ? l10n.themeModeDark
                            : l10n.themeModeLight,
                    trailing: Switch(
                      value: settingsProvider.themeMode == ThemeMode.dark,
                      activeColor: AppColors.primary,
                      onChanged:
                          (val) => settingsProvider.updateThemeMode(
                            val ? ThemeMode.dark : ThemeMode.light,
                          ),
                    ),
                  ),
                ]),

                const SizedBox(height: 24),

                // Data
                _buildSectionHeader(l10n.dataSectionTitle),
                _buildSettingsCard([
                  _buildTile(
                    context,
                    icon: LucideIcons.refreshCw,
                    title: l10n.lastDataUpdateTitle,
                    subtitle: _formatTimestamp(
                      context,
                      medicineProvider.lastUpdateTimestamp,
                      l10n,
                    ),
                    trailing: IconButton(
                      icon: const Icon(
                        LucideIcons.refreshCw,
                        size: 20,
                        color: AppColors.primary,
                      ),
                      onPressed: () async {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(l10n.checkingForUpdatesSnackbar),
                          ),
                        );
                        await medicineProvider.loadInitialData();
                      },
                    ),
                  ),
                  _buildDivider(),
                  _buildTile(
                    context,
                    icon: LucideIcons.fileText,
                    title: l10n.viewDebugLogsTitle,
                    onTap:
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const LogViewerScreen(),
                          ),
                        ),
                  ),
                ]),

                const SizedBox(height: 24),

                // Subscription
                _buildSectionHeader(l10n.subscriptionSectionTitle),
                _buildSettingsCard([
                  _buildTile(
                    context,
                    icon: LucideIcons.creditCard,
                    title: l10n.manageSubscriptionTitle,
                    subtitle: l10n.manageSubscriptionSubtitle,
                    onTap:
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const SubscriptionScreen(),
                          ),
                        ), // Needs redesign
                  ),
                ]),

                const SizedBox(height: 24),

                // About
                _buildSectionHeader(l10n.aboutSectionTitle),
                _buildSettingsCard([
                  _buildTile(
                    context,
                    icon: LucideIcons.info,
                    title: l10n.aboutAppTitle,
                    onTap: () => launchUrl(Uri.parse('https://example.com')),
                  ),
                  _buildDivider(),
                  _buildTile(
                    context,
                    icon: LucideIcons.shieldCheck,
                    title: l10n.privacyPolicyTitle,
                    onTap: () => launchUrl(Uri.parse('https://example.com')),
                  ),
                  _buildDivider(),
                  _buildTile(
                    context,
                    icon: LucideIcons.tag,
                    title: l10n.appVersionTitle,
                    subtitle: "1.0.0 (Build 12)",
                  ),
                ]),

                const SizedBox(height: 32),

                // Logout
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.danger.withOpacity(0.1),
                      foregroundColor: AppColors.danger,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(
                      l10n.logoutButton,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4, right: 4),
      child: Text(
        title,
        style: const TextStyle(
          color: AppColors.primary,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildSettingsCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppColors.shadowCard,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.foreground,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: AppColors.mutedForeground,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null)
                trailing
              else if (onTap != null)
                const Icon(
                  LucideIcons.chevronRight,
                  size: 18,
                  color: AppColors.mutedForeground,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return const Divider(
      height: 1,
      thickness: 1,
      indent: 60,
      color: AppColors.border,
    );
  }

  Widget _buildProfileCard(BuildContext context, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppColors.shadowCard,
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: AppColors.secondary,
            child: Text(
              l10n.profileInitialPlaceholder,
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.profileNamePlaceholder,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  l10n.profileEmailPlaceholder,
                  style: const TextStyle(
                    color: AppColors.mutedForeground,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(
              LucideIcons.edit3,
              size: 18,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  void _showLanguageDialog(
    BuildContext context,
    SettingsProvider provider,
    AppLocalizations l10n,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder:
          (ctx) => Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n.languageDialogTitle,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 24),
                _buildLanguageOption(ctx, provider, l10n, 'English', 'en'),
                const SizedBox(height: 12),
                _buildLanguageOption(ctx, provider, l10n, 'العربية', 'ar'),
                const SizedBox(height: 24),
              ],
            ),
          ),
    );
  }

  Widget _buildLanguageOption(
    BuildContext context,
    SettingsProvider provider,
    AppLocalizations l10n,
    String label,
    String code,
  ) {
    final isSelected = provider.locale.languageCode == code;
    return InkWell(
      onTap: () {
        provider.updateLocale(Locale(code));
        Navigator.pop(context);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color:
              isSelected ? AppColors.primary.withOpacity(0.1) : AppColors.card,
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: isSelected ? AppColors.primary : AppColors.foreground,
              ),
            ),
            if (isSelected)
              const Icon(LucideIcons.check, color: AppColors.primary),
          ],
        ),
      ),
    );
  }

  String _formatTimestamp(
    BuildContext context,
    int? timestamp,
    AppLocalizations l10n,
  ) {
    if (timestamp == null) return l10n.lastUpdateUnavailable;
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return DateFormat.yMMMd().add_jm().format(date);
  }
}
