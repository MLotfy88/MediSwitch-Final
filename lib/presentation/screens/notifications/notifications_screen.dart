import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mediswitch/core/utils/animation_helpers.dart';
import 'package:mediswitch/presentation/bloc/medicine_provider.dart';
import 'package:provider/provider.dart';

/// Notifications Screen
/// Matches design-refresh/src/components/screens/NotificationsScreen.tsx
class NotificationsScreen extends StatefulWidget {
  /// Constructor for NotificationsScreen
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  // Notifications list
  List<NotificationItem> _notifications = [];

  @override
  void initState() {
    super.initState();
    // Defer loading to didChangeDependencies or use a post-frame callback
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadNotificationsFromProvider();
    });
  }

  void _loadNotificationsFromProvider() {
    final provider = context.read<MedicineProvider>();
    final newDrugs = provider.recentlyUpdatedDrugs.take(3).toList();
    final highRiskDrugs = provider.highRiskDrugs.take(2).toList();

    final List<NotificationItem> generated = [];

    // Generate "New Drug" notifications
    for (final drug in newDrugs) {
      generated.add(
        NotificationItem(
          id: 'new_${drug.id}',
          type: NotificationType.newDrug,
          title: 'New Drug Added',
          titleAr: 'دواء جديد تمت إضافته',
          message: '${drug.tradeName} has been added to the database.',
          messageAr: 'تم إضافة ${drug.arabicName} إلى قاعدة البيانات.',
          timestamp: DateTime.now().subtract(const Duration(hours: 2)),
          read: false,
        ),
      );
    }

    // Generate "Interaction/Risk" notifications
    for (final drug in highRiskDrugs) {
      generated.add(
        NotificationItem(
          id: 'risk_${drug.id}',
          type: NotificationType.interaction,
          title: 'High Risk Alert',
          titleAr: 'تنبيه دواء عالي الخطورة',
          message: '${drug.tradeName} is classified as high risk.',
          messageAr: 'يصنف ${drug.arabicName} كدواء عالي الخطورة.',
          timestamp: DateTime.now().subtract(const Duration(days: 1)),
          read: true,
        ),
      );
    }

    // Add a generic update notification
    generated.add(
      NotificationItem(
        id: 'update_1',
        type: NotificationType.update,
        title: 'Database Updated',
        titleAr: 'تحديث قاعدة البيانات',
        message: 'Drug database has been updated successfully.',
        messageAr: 'تم تحديث قاعدة بيانات الأدوية بنجاح.',
        timestamp: DateTime.now().subtract(const Duration(days: 2)),
        read: true,
      ),
    );

    setState(() {
      _notifications = generated;
    });
  }

  void _markAsRead(String id) {
    setState(() {
      final index = _notifications.indexWhere((n) => n.id == id);
      if (index != -1) {
        _notifications[index] = _notifications[index].copyWith(read: true);
      }
    });
  }

  void _markAllAsRead() {
    setState(() {
      for (int i = 0; i < _notifications.length; i++) {
        _notifications[i] = _notifications[i].copyWith(read: true);
      }
    });
  }

  void _deleteNotification(String id) {
    setState(() {
      _notifications.removeWhere((n) => n.id == id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isRTL = Directionality.of(context) == ui.TextDirection.rtl;

    final unreadCount = _notifications.where((n) => !n.read).length;

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
                            padding: const EdgeInsets.all(6), // Reduced padding
                            minimumSize: const Size(
                              32,
                              32,
                            ), // Reduced size (was 40)
                          ),
                          iconSize: 18, // Reduced icon size
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
                              fontSize:
                                  18, // Explicitly reduced (was titleLarge ~22)
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
                        onPressed: _markAllAsRead,
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
                _notifications.isEmpty
                    ? _buildEmptyState(context, isRTL, colorScheme)
                    : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _notifications.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final notification = _notifications[index];
                        return FadeSlideAnimation(
                          delay: StaggeredAnimationHelper.delayFor(index),
                          child: _buildNotificationItem(
                            context,
                            notification,
                            isRTL,
                            colorScheme,
                          ),
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationItem(
    BuildContext context,
    NotificationItem notification,
    bool isRTL,
    ColorScheme colorScheme,
  ) {
    final (icon, color) = _getNotificationIcon(notification.type, colorScheme);

    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: colorScheme.error,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(LucideIcons.trash2, color: Colors.white),
      ),
      onDismissed: (_) => _deleteNotification(notification.id),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            if (!notification.read) {
              _markAsRead(notification.id);
            }
            // Add navigation logic if needed
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color:
                  notification.read
                      ? colorScheme.surface
                      : colorScheme.primaryContainer.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color:
                    notification.read
                        ? colorScheme.outline.withValues(alpha: 0.2)
                        : colorScheme.primary.withValues(alpha: 0.3),
                width: notification.read ? 1 : 2,
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
                              style: Theme.of(context).textTheme.titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                          ),
                          if (!notification.read)
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
                      Text(
                        isRTL ? notification.messageAr : notification.message,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatTimestamp(notification.timestamp, isRTL),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
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
      ),
    );
  }

  (IconData, Color) _getNotificationIcon(
    NotificationType type,
    ColorScheme colorScheme,
  ) {
    switch (type) {
      case NotificationType.priceChange:
        return (LucideIcons.trendingDown, colorScheme.tertiary);
      case NotificationType.newDrug:
        return (LucideIcons.sparkles, colorScheme.primary);
      case NotificationType.interaction:
        return (LucideIcons.alertTriangle, colorScheme.error);
      case NotificationType.update:
        return (LucideIcons.refreshCw, colorScheme.secondary);
    }
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

/// Enum for notification types
enum NotificationType {
  /// Price change notification
  priceChange,

  /// New drug notification
  newDrug,

  /// Interaction alert
  interaction,

  /// General update
  update,
}

/// Notification Item Model
class NotificationItem {
  /// ID
  final String id;

  /// Type
  final NotificationType type;

  /// Title En
  final String title;

  /// Title Ar
  final String titleAr;

  /// Message En
  final String message;

  /// Message Ar
  final String messageAr;

  /// Timestamp
  final DateTime timestamp;

  /// Read status
  final bool read;

  /// Constructor
  NotificationItem({
    required this.id,
    required this.type,
    required this.title,
    required this.titleAr,
    required this.message,
    required this.messageAr,
    required this.timestamp,
    required this.read,
  });

  /// Copy with
  NotificationItem copyWith({
    String? id,
    NotificationType? type,
    String? title,
    String? titleAr,
    String? message,
    String? messageAr,
    DateTime? timestamp,
    bool? read,
  }) {
    return NotificationItem(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      titleAr: titleAr ?? this.titleAr,
      message: message ?? this.message,
      messageAr: messageAr ?? this.messageAr,
      timestamp: timestamp ?? this.timestamp,
      read: read ?? this.read,
    );
  }
}
