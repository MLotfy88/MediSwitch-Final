import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/app_notification.dart';

class NotificationProvider extends ChangeNotifier {
  List<AppNotification> _notifications = [];
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  List<AppNotification> get notifications => List.unmodifiable(_notifications);

  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  NotificationProvider() {
    _init();
  }

  Future<void> _init() async {
    await _loadNotifications();
    await _initLocalNotifications();
    _isInitialized = true;
  }

  Future<void> _initLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings();
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (response) {
        // Handle notification tap
      },
    );
  }

  Future<void> _loadNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString('app_notifications');
    if (jsonString != null) {
      try {
        final dynamic decoded = jsonDecode(jsonString);
        if (decoded is List) {
          _notifications =
              decoded
                  .map(
                    (e) => AppNotification.fromJson(
                      Map<String, dynamic>.from(e as Map),
                    ),
                  )
                  .toList();
          // Sort by timestamp desc
          _notifications.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        }
      } catch (e) {
        // Handle corruption, maybe clear
        debugPrint("Error loading notifications: $e");
      }
    }
    notifyListeners();
  }

  Future<void> _saveNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = jsonEncode(
      _notifications.map((n) => n.toJson()).toList(),
    );
    await prefs.setString('app_notifications', jsonString);
    notifyListeners();
  }

  Future<void> addNotification(
    AppNotification notification, {
    bool showSystemNotification = true,
  }) async {
    _notifications.insert(0, notification);
    await _saveNotifications();

    if (showSystemNotification) {
      await _showSystemNotification(notification);
    }
  }

  Future<void> markAsRead(String id) async {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1 && !_notifications[index].isRead) {
      _notifications[index] = _notifications[index].copyWith(isRead: true);
      await _saveNotifications();
    }
  }

  Future<void> markAllAsRead() async {
    bool changed = false;
    for (int i = 0; i < _notifications.length; i++) {
      if (!_notifications[i].isRead) {
        _notifications[i] = _notifications[i].copyWith(isRead: true);
        changed = true;
      }
    }
    if (changed) {
      await _saveNotifications();
    }
  }

  Future<void> clearAll() async {
    _notifications.clear();
    await _saveNotifications();
  }

  Future<void> _showSystemNotification(AppNotification notification) async {
    const androidDetails = AndroidNotificationDetails(
      'mediswitch_updates',
      'MediSwitch Updates',
      channelDescription: 'Notifications for drug updates and alerts',
      importance: Importance.max,
      priority: Priority.high,
      styleInformation: BigTextStyleInformation(''), // To allow long text
    );
    const iosDetails = DarwinNotificationDetails();
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // Simple localization check (defaulting to English title if generic)
    // In a real scenario, we might want to check the current app locale,
    // but system notifications happen outside the app context often.
    // We will show English title and body, maybe combine Ar?
    // For now, let's use the English fields as primary, or concatenated.

    // User requested "Bilingual support".
    // "Rich text" in system notification is limited. We can use formatted strings.

    // Construct body based on type
    String body = notification.message;
    String title = notification.title;

    await _localNotifications.show(
      notification.id.hashCode,
      title,
      body,
      details,
      payload: notification.id,
    );
  }
}
