import 'package:equatable/equatable.dart';

enum AppNotificationType { priceChange, newDrug, interaction, update, general }

class AppNotification extends Equatable {
  final String id;
  final AppNotificationType type;
  final String title;
  final String titleAr;
  final String message;
  final String messageAr;
  final DateTime timestamp;
  final bool isRead;
  final Map<String, dynamic>? metadata;

  // Metadata helpers
  String? get drugId => metadata?['drugId'] as String?;
  String? get drugName => metadata?['drugName'] as String?;
  double? get oldPrice => metadata?['oldPrice'] as double?;
  double? get newPrice => metadata?['newPrice'] as double?;
  double? get changePercent => metadata?['changePercent'] as double?;

  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.titleAr,
    required this.message,
    required this.messageAr,
    required this.timestamp,
    this.isRead = false,
    this.metadata,
  });

  AppNotification copyWith({
    String? id,
    AppNotificationType? type,
    String? title,
    String? titleAr,
    String? message,
    String? messageAr,
    DateTime? timestamp,
    bool? isRead,
    Map<String, dynamic>? metadata,
  }) {
    return AppNotification(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      titleAr: titleAr ?? this.titleAr,
      message: message ?? this.message,
      messageAr: messageAr ?? this.messageAr,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      metadata: metadata ?? this.metadata,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.index,
      'title': title,
      'titleAr': titleAr,
      'message': message,
      'messageAr': messageAr,
      'timestamp': timestamp.toIso8601String(),
      'isRead': isRead,
      'metadata': metadata,
    };
  }

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] as String,
      type: AppNotificationType.values[json['type'] as int],
      title: json['title'] as String,
      titleAr: json['titleAr'] as String,
      message: json['message'] as String,
      messageAr: json['messageAr'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      isRead: json['isRead'] as bool,
      metadata:
          json['metadata'] != null
              ? Map<String, dynamic>.from(json['metadata'] as Map)
              : null,
    );
  }

  @override
  List<Object?> get props => [
    id,
    type,
    title,
    titleAr,
    message,
    messageAr,
    timestamp,
    isRead,
    metadata,
  ];
}
