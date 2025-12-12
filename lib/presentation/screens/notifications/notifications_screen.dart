import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mediswitch/core/utils/animation_helpers.dart';
import 'package:mediswitch/domain/entities/app_notification.dart';
import 'package:mediswitch/presentation/bloc/notification_provider.dart';
import 'package:provider/provider.dart';

/// Notifications Screen
class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isRTL = Directionality.of(context) == ui.TextDirection.rtl;
    final provider = context.watch<NotificationProvider>();
    final notifications = provider.notifications;
    final unreadCount = provider.unreadCount;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Column(
        children: [
          // Header
          Container(
            decoration: BoxDecoration(
              color: colorScheme.surface.withValues(alpha: 0.95),
              border: Border(
                bottom: BorderSide(
                  color: colorScheme.outline.withValues(alpha: 0.2),
                ),
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Back Button
                    if (Navigator.canPop(context))
                      Padding(
                        padding: const EdgeInsetsDirectional.only(end: 12),
                        child: IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: Icon(
                            isRTL
                                ? LucideIcons.arrowRight
                                : LucideIcons.arrowLeft,
                            color: colorScheme.onSurface,
                          ),
                          style: IconButton.styleFrom(
                            backgroundColor:
                                colorScheme.surfaceContainerHighest,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.all(6),
                            minimumSize: const Size(32, 32),
                          ),
                          iconSize: 18,
                        ),
                      ),

                    // Icon Container
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        LucideIcons.bell,
                        color: colorScheme.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Title
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isRTL ? 'الإشعارات' : 'Notifications',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          if (unreadCount > 0)
                            Text(
                              isRTL
                                  ? '$unreadCount غير مقروء'
                                  : '$unreadCount unread',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                        ],
                      ),
                    ),

                    // Mark All Read Button
                    if (unreadCount > 0)
                      TextButton(
                        onPressed: () => provider.markAllAsRead(),
                        child: Text(
                          isRTL ? 'قراءة الكل' : 'Mark all read',
                          style: TextStyle(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),

          // Notifications List
          Expanded(
            child:
                notifications.isEmpty
                    ? _buildEmptyState(context, isRTL, colorScheme)
                    : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: notifications.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final notification = notifications[index];
                        return FadeSlideAnimation(
                          delay: StaggeredAnimationHelper.delayFor(index),
                          child: _NotificationItemWidget(
                            notification: notification,
                            isRTL: isRTL,
                          ),
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(
    BuildContext context,
    bool isRTL,
    ColorScheme colorScheme,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                shape: BoxShape.circle,
              ),
              child: Icon(
                LucideIcons.bell,
                size: 40,
                color: colorScheme.onSurface.withValues(alpha: 0.4),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              isRTL ? 'لا توجد إشعارات' : 'No notifications',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              isRTL
                  ? 'ستظهر إشعاراتك هنا'
                  : 'Your notifications will appear here',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationItemWidget extends StatelessWidget {
  final AppNotification notification;
  final bool isRTL;

  const _NotificationItemWidget({
    required this.notification,
    required this.isRTL,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final (icon, color) = _getNotificationIcon(notification.type, colorScheme);
    final provider = context.read<NotificationProvider>();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          if (!notification.isRead) {
            provider.markAsRead(notification.id);
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color:
                notification.isRead
                    ? colorScheme.surface
                    : colorScheme.primaryContainer.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color:
                  notification.isRead
                      ? colorScheme.outline.withValues(alpha: 0.2)
                      : colorScheme.primary.withValues(alpha: 0.3),
              width: notification.isRead ? 1 : 2,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 20, color: color),
              ),
              const SizedBox(width: 12),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            isRTL ? notification.titleAr : notification.title,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (!notification.isRead)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: colorScheme.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Rich Text Message
                    _buildRichMessage(
                      context,
                      notification,
                      isRTL,
                      colorScheme,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatTimestamp(notification.timestamp, isRTL),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRichMessage(
    BuildContext context,
    AppNotification notification,
    bool isRTL,
    ColorScheme colorScheme,
  ) {
    if (notification.type == AppNotificationType.priceChange &&
        notification.metadata != null) {
      final drugName =
          (isRTL
              ? notification.metadata!['drugNameAr'] as String?
              : notification.metadata!['drugName'] as String?) ??
          notification.metadata!['drugName'] as String? ??
          '';
      final oldPrice = notification.metadata!['oldPrice'];
      final newPrice = notification.metadata!['newPrice'];
      final percent = notification.metadata!['changePercent'] as double? ?? 0.0;
      final isUp = percent > 0;
      final arrow = isUp ? "⬆" : "⬇";

      if (isRTL) {
        return RichText(
          text: TextSpan(
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.7),
            ),
            children: [
              const TextSpan(text: 'تغير سعر '),
              TextSpan(
                text: drugName,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const TextSpan(text: ' من '),
              TextSpan(text: '$oldPrice'),
              const TextSpan(text: ' إلى '),
              TextSpan(
                text: '$newPrice',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              TextSpan(
                text: ' ($arrow${percent.toStringAsFixed(1)}%)',
                style: TextStyle(
                  color: isUp ? colorScheme.error : Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      } else {
        return RichText(
          text: TextSpan(
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.7),
            ),
            children: [
              const TextSpan(text: 'Price of '),
              TextSpan(
                text: drugName,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const TextSpan(text: ' changed from '),
              TextSpan(text: '$oldPrice'),
              const TextSpan(text: ' to '),
              TextSpan(
                text: '$newPrice',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              TextSpan(
                text: ' ($arrow${percent.toStringAsFixed(1)}%)',
                style: TextStyle(
                  color: isUp ? colorScheme.error : Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      }
    }

    // Default: Plain Text
    return Text(
      isRTL ? notification.messageAr : notification.message,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
        color: colorScheme.onSurface.withValues(alpha: 0.7),
      ),
    );
  }

  (IconData, Color) _getNotificationIcon(
    AppNotificationType type,
    ColorScheme colorScheme,
  ) {
    switch (type) {
      case AppNotificationType.priceChange:
        return (LucideIcons.trendingDown, colorScheme.tertiary);
      case AppNotificationType.newDrug:
        return (LucideIcons.sparkles, colorScheme.primary);
      case AppNotificationType.interaction:
        return (LucideIcons.alertTriangle, colorScheme.error);
      case AppNotificationType.update:
        return (LucideIcons.refreshCw, colorScheme.secondary);
      case AppNotificationType.general:
        return (LucideIcons.bell, colorScheme.primary);
    }
  }

  String _formatTimestamp(DateTime timestamp, bool isRTL) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 60) {
      return isRTL
          ? 'منذ ${difference.inMinutes} دقيقة'
          : '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return isRTL
          ? 'منذ ${difference.inHours} ساعة'
          : '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return isRTL
          ? 'منذ ${difference.inDays} يوم'
          : '${difference.inDays}d ago';
    } else {
      return DateFormat('MMM d').format(timestamp);
    }
  }
}
