import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:mediswitch/presentation/bloc/medicine_provider.dart';
import 'package:mediswitch/presentation/bloc/settings_provider.dart';
import 'package:mediswitch/presentation/screens/debug/log_viewer_screen.dart';
import 'package:mediswitch/presentation/screens/subscription_screen.dart';
import 'package:mediswitch/presentation/theme/app_colors_extension.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:mediswitch/core/constants/design_tokens.dart';
import 'package:lucide_icons/lucide_icons.dart';

class NewSettingsScreen extends StatelessWidget {
  const NewSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final settingsProvider = context.watch<SettingsProvider>();
    final medicineProvider = context.watch<MedicineProvider>();
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          // Header
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  colorScheme.primary,
                  colorScheme.primary,
                  Color.lerp(colorScheme.primary, Colors.black, 0.2)!,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + AppSpacing.lg,
              bottom: AppSpacing.xl2,
              left: AppSpacing.lg,
              right: AppSpacing.lg,
            ),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(LucideIcons.arrowLeft, color: Colors.white),
                  style: IconButton.styleFrom(
                    backgroundColor: colorScheme.onPrimary.withValues(
                      alpha: 0.1,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.lg),
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
              padding: AppSpacing.paddingLG,
              children: [
                // Profile Section
                _buildProfileCard(context, l10n),
                const SizedBox(height: AppSpacing.xl),

                // General
                _buildSectionHeader(context, l10n.generalSectionTitle),
                _buildSettingsCard(context, [
                  _buildTile(
                    context,
                    icon: LucideIcons.globe,
                    title: l10n.languageSettingTitle,
                    subtitle:
                        settingsProvider.locale.languageCode == 'ar'
                            ? 'العربية'
                            : 'English',
                    onTap:
                        () => _showLanguageDialog(
                          context,
                          settingsProvider,
                          l10n,
                        ),
                  ),
                  _buildDivider(context),
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
                      activeColor: colorScheme.primary,
                      onChanged:
                          (val) => settingsProvider.updateThemeMode(
                            val ? ThemeMode.dark : ThemeMode.light,
                          ),
                    ),
                  ),
                ]),

                const SizedBox(height: AppSpacing.xl2),

                // Data
                _buildSectionHeader(context, l10n.dataSectionTitle),
                _buildSettingsCard(context, [
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
                      icon: Icon(
                        LucideIcons.refreshCw,
                        size: 20,
                        color: colorScheme.primary,
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
                  _buildDivider(context),
                  _buildTile(
                    context,
                    icon: LucideIcons.fileText,
                    title: l10n.viewDebugLogsTitle,
                    onTap:
                        () => Navigator.push(
                          context,
                          MaterialPageRoute<void>(
                            builder: (_) => const LogViewerScreen(),
                          ),
                        ),
                  ),
                ]),

                const SizedBox(height: AppSpacing.xl2),

                // Subscription
                _buildSectionHeader(context, l10n.subscriptionSectionTitle),
                _buildSettingsCard(context, [
                  _buildTile(
                    context,
                    icon: LucideIcons.creditCard,
                    title: l10n.manageSubscriptionTitle,
                    subtitle: l10n.manageSubscriptionSubtitle,
                    onTap:
                        () => Navigator.push(
                          context,
                          MaterialPageRoute<void>(
                            builder: (_) => const SubscriptionScreen(),
                          ),
                        ), // Needs redesign
                  ),
                ]),

                const SizedBox(height: AppSpacing.xl2),

                // About
                _buildSectionHeader(context, l10n.aboutSectionTitle),
                _buildSettingsCard(context, [
                  _buildTile(
                    context,
                    icon: LucideIcons.info,
                    title: l10n.aboutAppTitle,
                    onTap: () => launchUrl(Uri.parse('https://example.com')),
                  ),
                  _buildDivider(context),
                  _buildTile(
                    context,
                    icon: LucideIcons.shieldCheck,
                    title: l10n.privacyPolicyTitle,
                    onTap: () => launchUrl(Uri.parse('https://example.com')),
                  ),
                  _buildDivider(context),
                  _buildTile(
                    context,
                    icon: LucideIcons.tag,
                    title: l10n.appVersionTitle,
                    subtitle: '1.0.0 (Build 12)',
                  ),
                ]),

                const SizedBox(height: AppSpacing.xl3),

                // Logout
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.error.withValues(alpha: 0.1),
                      foregroundColor: colorScheme.error,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: AppRadius.circularLg,
                      ),
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.lg,
                      ),
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
                const SizedBox(height: AppSpacing.xl3),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: AppSpacing.md,
        left: AppSpacing.xs,
        right: AppSpacing.xs,
      ),
      child: Text(
        title,
        style: TextStyle(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildSettingsCard(BuildContext context, List<Widget> children) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: AppRadius.circularXl2,
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.5)),
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
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.circularXl2,
        child: Padding(
          padding: AppSpacing.paddingLG,
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: AppRadius.circularSm,
                ),
                child: Icon(icon, color: colorScheme.primary, size: 20),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: Theme.of(context).appColors.mutedForeground,
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
                Icon(
                  LucideIcons.chevronRight,
                  size: 18,
                  color: Theme.of(context).appColors.mutedForeground,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDivider(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 1,
      indent: 60,
      color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.5),
    );
  }

  Widget _buildProfileCard(BuildContext context, AppLocalizations l10n) {
    return Container(
      padding: AppSpacing.paddingLG,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: AppRadius.circularXl2,
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: Theme.of(context).colorScheme.secondary,
            child: Text(
              l10n.profileInitialPlaceholder,
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
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
                  style: TextStyle(
                    color: Theme.of(context).appColors.mutedForeground,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: Icon(
              LucideIcons.edit3,
              size: 18,
              color: Theme.of(context).colorScheme.primary,
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
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
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
              isSelected
                  ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)
                  : Theme.of(context).colorScheme.surface,
          border: Border.all(
            color:
                isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(
                      context,
                    ).colorScheme.outline.withValues(alpha: 0.5),
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
                color:
                    isSelected
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.onSurface,
              ),
            ),
            if (isSelected)
              Icon(
                LucideIcons.check,
                color: Theme.of(context).colorScheme.primary,
              ),
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
