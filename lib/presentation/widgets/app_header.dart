import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mediswitch/core/constants/design_tokens.dart';
import 'package:mediswitch/presentation/theme/app_colors_extension.dart';

class AppHeader extends StatelessWidget {
  final String title;
  final String lastUpdated;
  final int notificationCount;
  final VoidCallback? onNotificationTap;

  const AppHeader({
    super.key,
    this.title = 'MediSwitch',
    this.lastUpdated = 'Dec 6, 2025',
    this.notificationCount = 3,
    this.onNotificationTap,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          decoration: BoxDecoration(
            color: Theme.of(
              context,
            ).scaffoldBackgroundColor.withValues(alpha: 0.95),
            border: Border(
              bottom: BorderSide(
                color: Theme.of(
                  context,
                ).colorScheme.outline.withValues(alpha: 0.5),
              ),
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
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Theme.of(context).colorScheme.primary,
                            Color.lerp(
                              Theme.of(context).colorScheme.primary,
                              Colors.black,
                              0.2,
                            )!,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: AppRadius.circularLg,
                        boxShadow: AppShadows.md,
                      ),
                      child: const Icon(
                        LucideIcons.heartPulse,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        Row(
                          children: [
                            Icon(
                              LucideIcons.refreshCw,
                              size: AppSpacing.md,
                              color:
                                  Theme.of(context).appColors.mutedForeground,
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            Text(
                              'Updated $lastUpdated',
                              style: TextStyle(
                                fontSize: 12,
                                color:
                                    Theme.of(context).appColors.mutedForeground,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),

                // Notifications
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    GestureDetector(
                      onTap: onNotificationTap,
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Theme.of(context).appColors.accent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          LucideIcons.bell,
                          size: 20,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    if (notificationCount > 0)
                      Positioned(
                        top: -4,
                        right: -4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.error,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: Theme.of(context).scaffoldBackgroundColor,
                              width: 2,
                            ),
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 18,
                            minHeight: 18,
                          ),
                          child: Center(
                            child: Text(
                              notificationCount > 9
                                  ? '9+'
                                  : notificationCount.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
