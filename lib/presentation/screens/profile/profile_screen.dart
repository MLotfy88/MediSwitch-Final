import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

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
      body: Column(
        children: [
          // Header with Gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  colorScheme.primary,
                  colorScheme.primary,
                  colorScheme.primaryContainer,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    // Avatar
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                      ),
                      child: const Center(
                        child: Text(
                          'U',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Name
                    Text(
                      isRTL ? 'مستخدم جديد' : 'User Name',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),

                    // Email
                    Text(
                      'user@example.com',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Edit Profile Button
                    OutlinedButton.icon(
                      onPressed: () {
                        // TODO: Navigate to edit profile
                      },
                      icon: const Icon(
                        LucideIcons.edit3,
                        size: 16,
                        color: Colors.white,
                      ),
                      label: Text(
                        isRTL ? 'تعديل الملف الشخصي' : 'Edit Profile',
                        style: const TextStyle(color: Colors.white),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.white),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Stats Cards
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    context,
                    icon: LucideIcons.heart,
                    count: '12',
                    label: isRTL ? 'مفضلة' : 'Favorites',
                    color: colorScheme.error,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    context,
                    icon: LucideIcons.search,
                    count: '45',
                    label: isRTL ? 'بحث' : 'Searches',
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    context,
                    icon: LucideIcons.history,
                    count: '28',
                    label: isRTL ? 'سجل' : 'History',
                    color: colorScheme.tertiary,
                  ),
                ),
              ],
            ),
          ),

          // Menu Items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildSectionHeader(context, isRTL ? 'الحساب' : 'Account'),
                _buildMenuItem(
                  context,
                  icon: LucideIcons.user,
                  title: isRTL ? 'معلومات الحساب' : 'Account Info',
                  onTap: () {},
                ),
                _buildMenuItem(
                  context,
                  icon: LucideIcons.creditCard,
                  title: isRTL ? 'الاشتراك' : 'Subscription',
                  onTap: () {},
                ),
                _buildMenuItem(
                  context,
                  icon: LucideIcons.settings,
                  title: isRTL ? 'الإعدادات' : 'Settings',
                  onTap: () {},
                ),

                const SizedBox(height: 24),
                _buildSectionHeader(context, isRTL ? 'النشاط' : 'Activity'),
                _buildMenuItem(
                  context,
                  icon: LucideIcons.heart,
                  title: isRTL ? 'المفضلة' : 'Favorites',
                  badge: '12',
                  onTap: () {},
                ),
                _buildMenuItem(
                  context,
                  icon: LucideIcons.history,
                  title: isRTL ? 'السجل' : 'History',
                  onTap: () {},
                ),
                _buildMenuItem(
                  context,
                  icon: LucideIcons.bell,
                  title: isRTL ? 'الإشعارات' : 'Notifications',
                  badge: '3',
                  onTap: () {},
                ),

                const SizedBox(height: 24),
                _buildSectionHeader(context, isRTL ? 'الدعم' : 'Support'),
                _buildMenuItem(
                  context,
                  icon: LucideIcons.helpCircle,
                  title: isRTL ? 'المساعدة والدعم' : 'Help & Support',
                  onTap: () {},
                ),
                _buildMenuItem(
                  context,
                  icon: LucideIcons.messageSquare,
                  title: isRTL ? 'إرسال ملاحظات' : 'Send Feedback',
                  onTap: () {},
                ),
                _buildMenuItem(
                  context,
                  icon: LucideIcons.info,
                  title: isRTL ? 'حول التطبيق' : 'About',
                  onTap: () {},
                ),

                const SizedBox(height: 32),

                // Logout Button
                _buildLogoutButton(context, isRTL),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required IconData icon,
    required String count,
    required String label,
    required Color color,
  }) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 8),
          Text(
            count,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, right: 4, bottom: 12),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? badge,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colorScheme.outline.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 20, color: colorScheme.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (badge != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    badge,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.onPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Icon(
                LucideIcons.chevronRight,
                size: 18,
                color: colorScheme.onSurface.withOpacity(0.4),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context, bool isRTL) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ElevatedButton.icon(
      onPressed: () {
        // TODO: Logout logic
      },
      icon: const Icon(LucideIcons.logOut, size: 18),
      label: Text(
        isRTL ? 'تسجيل الخروج' : 'Logout',
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: colorScheme.error.withOpacity(0.1),
        foregroundColor: colorScheme.error,
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
