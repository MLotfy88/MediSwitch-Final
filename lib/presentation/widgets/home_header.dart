import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';

class HomeHeader extends StatelessWidget {
  final int notificationCount;
  
  const HomeHeader({
    super.key,
    this.notificationCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final hasNotifications = notificationCount > 0;

    return Container(
      // Use tertiary color for background as defined in theme
      color: colorScheme.tertiary,
      // Apply specific height and padding from design doc
      height: 60.0, // Increased height from 40.0
      padding: const EdgeInsets.symmetric(
        horizontal: 4.0,
      ), // px-1 (adjust if p-1 meant all sides)
      // Add bottom border
      decoration: BoxDecoration(
        color: colorScheme.tertiary, // Ensure color is set if using decoration
        border: Border(
          bottom: BorderSide(
            color: colorScheme.outline,
            width: 1.0,
          ), // border-b border-border
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Logo - Adjust padding/size if needed
          Padding(
            padding: const EdgeInsets.only(
              left: 12.0,
            ), // Add some start padding
            child: Image.asset(
              'assets/images/logo.png', // Ensure logo path is correct
              height: 50, // Increased height from 40
              // color: colorScheme.onTertiary, // Apply white color if logo is single color
            ),
          ),
          // Notification Button with Badge
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                icon: Icon(
                  LucideIcons.bell,
                  size: 30,
                  color: colorScheme.onTertiary,
                ), // h-5 w-5, white
                onPressed: () {
                  // TODO: Implement notification logic
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('الإشعارات (قريباً)'),
                    ),
                  );
                },
                tooltip: 'الإشعارات',
                splashRadius: 20,
                // Add hover effect if needed (e.g., using hoverColor in IconButtonTheme)
              )
                  .animate(
                    onPlay: (controller) => controller.repeat(),
                  )
                  .shake(
                    duration: hasNotifications ? 2000.ms : 0.ms,
                    delay: 3000.ms,
                    hz: 3,
                    curve: Curves.easeInOut,
                  ),
              // Notification Badge
              if (hasNotifications)
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.red.shade600,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: colorScheme.tertiary,
                        width: 2,
                      ),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 20,
                      minHeight: 20,
                    ),
                    child: Center(
                      child: Text(
                        notificationCount > 99 ? '99+' : '$notificationCount',
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
