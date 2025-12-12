import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../bloc/medicine_provider.dart';
import '../theme/app_colors_extension.dart';

/// App Header with real logo, notifications, and last update date
class AppHeader extends StatelessWidget {
  final VoidCallback? onNotificationTap;
  final VoidCallback? onRefreshTap;
  final bool isSyncing;

  const AppHeader({
    super.key,
    this.onNotificationTap,
    this.onRefreshTap,
    this.isSyncing = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appColors = theme.appColors;
    final isDark = theme.brightness == Brightness.dark;
    final medicineProvider = context.watch<MedicineProvider>();

    // ✅ حساب عدد التنبيهات الحقيقي (الأدوية المحدثة اليوم)
    final todayUpdates =
        medicineProvider.recentlyUpdatedDrugs.where((drug) {
          if (drug.lastPriceUpdate == null) return false;
          try {
            final updateDate = DateFormat(
              'yyyy-MM-dd',
            ).parse(drug.lastPriceUpdate!);
            final today = DateTime.now();
            return updateDate.year == today.year &&
                updateDate.month == today.month &&
                updateDate.day == today.day;
          } catch (e) {
            return false;
          }
        }).length;

    // ✅ آخر تاريخ مزامنة ناجحة من MedicineProvider
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;
    String lastUpdateText = l10n.neverUpdated;

    if (medicineProvider.lastUpdateTimestamp != null) {
      try {
        final syncDate = DateTime.fromMillisecondsSinceEpoch(
          medicineProvider.lastUpdateTimestamp!,
        );
        lastUpdateText = DateFormat('MMM d, yyyy', locale).format(syncDate);
      } catch (e) {
        lastUpdateText = l10n.lastUpdateUnavailable;
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.95),
        border: Border(
          bottom: BorderSide(color: theme.dividerColor.withValues(alpha: 0.5)),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Logo & Title
            Row(
              children: [
                // ✅ استخدام اللوجو الحقيقي للتطبيق
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        theme.colorScheme.primary,
                        theme.colorScheme.primary.withValues(alpha: 0.8),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: theme.colorScheme.primary.withValues(alpha: 0.3),
                        offset: const Offset(0, 4),
                        blurRadius: 12,
                        spreadRadius: -2,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Image.asset(
                      'assets/images/app_logo.png',
                      width: 40,
                      height: 40,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        // Fallback إذا لم يكن اللوجو موجوداً
                        return const Icon(
                          LucideIcons.pill,
                          size: 20,
                          color: Colors.white,
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'MediSwitch',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    // ✅ عرض تاريخ آخر تحديث الحقيقي
                    Row(
                      children: [
                        Icon(
                          LucideIcons.refreshCw,
                          size: 12,
                          color: appColors.mutedForeground,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          lastUpdateText,
                          style: TextStyle(
                            fontSize: 12,
                            color: appColors.mutedForeground,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),

            // Action Buttons (Refresh + Notifications)
            Row(
              children: [
                // Refresh Button
                GestureDetector(
                  onTap: isSyncing ? null : onRefreshTap,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: appColors.accent.withValues(
                        alpha: isDark ? 0.2 : 0.1,
                      ),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child:
                        isSyncing
                            ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: theme.colorScheme.primary,
                              ),
                            )
                            : Icon(
                              LucideIcons.refreshCw,
                              size: 20,
                              color: theme.colorScheme.onSurface,
                            ),
                  ),
                ),
                const SizedBox(width: 12),
                // Notification Button
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    GestureDetector(
                      onTap: onNotificationTap,
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: appColors.accent.withValues(
                            alpha: isDark ? 0.2 : 0.1,
                          ),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Icon(
                          LucideIcons.bell,
                          size: 20,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ),
                    // ✅ عرض عدد التنبيهات الحقيقي
                    if (todayUpdates > 0)
                      Positioned(
                        top: -4,
                        right: -4,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.error,
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 18,
                            minHeight: 18,
                          ),
                          child: Center(
                            child: Text(
                              todayUpdates > 9 ? '+9' : todayUpdates.toString(),
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
