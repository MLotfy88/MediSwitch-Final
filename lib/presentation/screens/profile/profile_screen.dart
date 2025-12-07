import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mediswitch/presentation/screens/settings_screen.dart';

/// Profile Screen
/// Matches design-refresh/src/components/screens/ProfileScreen.tsx
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isRTL = Directionality.of(context) == TextDirection.rtl;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Hero Header containing Avatar, Info and Stats
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    colorScheme.primary,
                    colorScheme.primary,
                    // Use a slightly darker shade if available, or just manipulate primary
                    HSLColor.fromColor(
                      colorScheme.primary,
                    ).withLightness(0.4).toColor(),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
                  child: Column(
                    children: [
                      // Avatar & User Info
                      Row(
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: colorScheme.onPrimary.withOpacity(0.2),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: colorScheme.onPrimary,
                                width: 2,
                              ),
                            ),
                            child: Center(
                              child: Icon(
                                LucideIcons.user,
                                size: 40,
                                color: colorScheme.onPrimary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isRTL
                                      ? 'مستخدم MediSwitch'
                                      : 'MediSwitch User',
                                  style: theme.textTheme.headlineSmall
                                      ?.copyWith(
                                        color: colorScheme.onPrimary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  isRTL ? 'صيدلي' : 'Pharmacist',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: colorScheme.onPrimary.withOpacity(
                                      0.8,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),

                      // Stats Cards inside Header
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              context,
                              count: '24',
                              label: isRTL ? 'المفضلة' : 'Favorites',
                              colorScheme: colorScheme,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildStatCard(
                              context,
                              count: '156',
                              label: isRTL ? 'عمليات البحث' : 'Searches',
                              colorScheme: colorScheme,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildStatCard(
                              context,
                              count: '89',
                              label: isRTL ? 'الأدوية المعروضة' : 'Viewed',
                              colorScheme: colorScheme,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Menu Items Container
            Transform.translate(
              offset: const Offset(0, -20),
              child: Container(
                decoration: BoxDecoration(
                  color: theme.scaffoldBackgroundColor,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 24,
                ),
                child: Column(
                  children: [
                    // Settings Menu
                    Container(
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          _buildMenuItem(
                            context,
                            icon: LucideIcons.bell,
                            title: isRTL ? 'الإشعارات' : 'Notifications',
                            isToggle: true,
                            onTap: () {},
                          ),
                          _buildDivider(theme),
                          _buildMenuItem(
                            context,
                            icon: LucideIcons.moon,
                            title: isRTL ? 'الوضع الداكن' : 'Dark Mode',
                            isToggle: true,
                            onTap: () {},
                          ),
                          _buildDivider(theme),
                          _buildMenuItem(
                            context,
                            icon: LucideIcons.globe,
                            title: isRTL ? 'اللغة' : 'Language',
                            trailingText: isRTL ? 'العربية' : 'English',
                            onTap: () {},
                          ),
                          _buildDivider(theme),
                          _buildMenuItem(
                            context,
                            icon: LucideIcons.shield,
                            title:
                                isRTL
                                    ? 'الخصوصية والأمان'
                                    : 'Privacy & Security',
                            onTap: () {},
                          ),
                          _buildDivider(theme),
                          _buildMenuItem(
                            context,
                            icon: LucideIcons.helpCircle,
                            title: isRTL ? 'المساعدة والدعم' : 'Help & Support',
                            onTap: () {},
                          ),
                          _buildDivider(theme),
                          _buildMenuItem(
                            context,
                            icon: LucideIcons.settings,
                            title: isRTL ? 'الإعدادات' : 'Settings',
                            isLast: true,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const SettingsScreen(),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Logout Button
                    _buildLogoutButton(context, isRTL, theme),

                    const SizedBox(height: 24),

                    // Version Info
                    Text(
                      'MediSwitch v1.0.0',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 100), // Bottom View Padding
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required String count,
    required String label,
    required ColorScheme colorScheme,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: colorScheme.onPrimary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            count,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: colorScheme.onPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: colorScheme.onPrimary.withOpacity(0.8),
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    bool isToggle = false,
    bool isLast = false,
    String? trailingText,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius:
            isLast
                ? const BorderRadius.vertical(bottom: Radius.circular(16))
                : null, // Only round bottom corners if last
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color:
                      theme
                          .scaffoldBackgroundColor, // bg-muted equivalent often
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 18, color: colorScheme.onSurface),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (isToggle)
                SizedBox(
                  height: 24,
                  child: Switch(
                    value: true, // Mock value
                    onChanged: (v) {},
                    activeColor: colorScheme.primary,
                  ),
                )
              else if (trailingText != null)
                Row(
                  children: [
                    Text(
                      trailingText,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      LucideIcons.chevronRight,
                      size: 16,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ],
                )
              else
                Icon(
                  LucideIcons.chevronRight,
                  size: 18,
                  color: colorScheme.onSurfaceVariant,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDivider(ThemeData theme) {
    return Divider(
      height: 1,
      thickness: 1,
      indent: 64, // Align with text start
      color: theme.colorScheme.outlineVariant.withOpacity(0.5),
    );
  }

  Widget _buildLogoutButton(BuildContext context, bool isRTL, ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.error.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {},
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  LucideIcons.logOut,
                  size: 20,
                  color: theme.colorScheme.error,
                ),
                const SizedBox(width: 8),
                Text(
                  isRTL ? 'تسجيل الخروج' : 'Sign Out',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.error,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
