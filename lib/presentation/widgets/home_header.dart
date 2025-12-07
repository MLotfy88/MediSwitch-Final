import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../screens/notifications/notifications_screen.dart';

class HomeHeader extends StatelessWidget {
  final int notificationCount;
  final VoidCallback? onNotificationTap;

  const HomeHeader({
    super.key,
    this.notificationCount = 0,
    this.onNotificationTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final hasNotifications = notificationCount > 0;

    return Container(
      height: 64.0,
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: colorScheme.outline.withOpacity(0.2),
            width: 1.0,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // App Icon + Name
          Row(
            children: [
              // App Icon
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.asset(
                    'assets/images/app_icon.png',
                    width: 40,
                    height: 40,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      // Fallback to pill icon if app_icon not found
                      return Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          LucideIcons.pill,
                          color: colorScheme.primary,
                          size: 24,
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // App Name
              Text(
                'MediSwitch',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),

          // Notification Button with Badge
          Stack(
            clipBehavior: Clip.none,
            children: [
              Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        if (onNotificationTap != null) {
                          onNotificationTap!();
                        } else {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const NotificationsScreen(),
                            ),
                          );
                        }
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest
                              .withOpacity(0.5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          LucideIcons.bell,
                          size: 22,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ),
                  )
                  .animate(onPlay: (controller) => controller.repeat())
                  .shake(
                    duration: hasNotifications ? 2000.ms : 0.ms,
                    delay: 3000.ms,
                    hz: 3,
                    curve: Curves.easeInOut,
                  ),
              // Notification Badge
              if (hasNotifications)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: colorScheme.error,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: colorScheme.surface,
                            width: 2,
                          ),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 18,
                          minHeight: 18,
                        ),
                        child: Center(
                          child: Text(
                            notificationCount > 9 ? '9+' : '$notificationCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                      .animate(onPlay: (controller) => controller.repeat())
                      .scale(
                        duration: 1000.ms,
                        begin: const Offset(0.9, 0.9),
                        end: const Offset(1.1, 1.1),
                        curve: Curves.easeInOut,
                      )
                      .then()
                      .scale(
                        duration: 1000.ms,
                        begin: const Offset(1.1, 1.1),
                        end: const Offset(0.9, 0.9),
                        curve: Curves.easeInOut,
                      ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
