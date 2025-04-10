import 'package:flutter/material.dart';
// import 'package:flutter_svg/flutter_svg.dart'; // No longer needed if logo is PNG

class HomeHeader extends StatelessWidget {
  final String? title; // Optional title
  final bool showNotification;
  final VoidCallback? onNotificationTap; // Callback for notification icon

  const HomeHeader({
    super.key,
    this.title,
    this.showNotification = true, // Default to true as in React component
    this.onNotificationTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    // Define the specific background color from the design
    // TODO: Consider adding this color to the theme definition later
    const headerBackgroundColor = Color(0xFF16BC88);
    // Determine a contrasting foreground color (e.g., white)
    final foregroundColor = Colors.white; // Assuming white contrasts well

    return Container(
      color: headerBackgroundColor,
      padding: EdgeInsets.only(
        top:
            MediaQuery.of(context).padding.top +
            10, // Adjust for status bar + padding
        left: 16,
        right: 16,
        bottom: 10,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Title or Logo
          title != null
              ? Text(
                title!,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: foregroundColor,
                  fontWeight: FontWeight.bold,
                ),
              )
              : Image.asset(
                // Use Image.asset for PNG logo
                'assets/images/logo.png', // Correct path
                height: 36, // Adjust height as needed
                // color: foregroundColor, // Color doesn't usually apply well to PNGs unless it's a mask
              ),

          // Notification Icon
          if (showNotification)
            IconButton(
              icon: Icon(
                Icons.notifications_none_outlined,
                color: foregroundColor,
              ), // Using Material icon
              tooltip: 'الإشعارات', // Accessibility tooltip
              onPressed:
                  onNotificationTap ??
                  () {
                    // Default action if no callback provided
                    print('Notification icon tapped');
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('سيتم إضافة الإشعارات لاحقاً.'),
                      ),
                    );
                  },
              // Add splash/highlight color that fits the background
              splashColor: Colors.white.withOpacity(0.2),
              highlightColor: Colors.white.withOpacity(0.1),
            )
          else
            const SizedBox(
              width: 48,
            ), // Placeholder to maintain balance if icon hidden
        ],
      ),
    );
  }
}
