import 'package:mediswitch/domain/entities/subscription_entity.dart';

class SubscriptionModel extends SubscriptionEntity {
  const SubscriptionModel({
    required super.userId,
    required super.tier,
    required super.platform,
    super.transactionId,
    super.startsAt,
    super.expiresAt,
    required super.status,
    super.autoRenew,
  });

  factory SubscriptionModel.fromJson(Map<String, dynamic> json) {
    return SubscriptionModel(
      userId: json['user_id'] as String,
      tier: _parseTier(json['tier'] as String?),
      platform: json['platform'] as String? ?? 'android',
      transactionId: json['transaction_id'] as String?,
      startsAt:
          json['starts_at'] != null
              ? DateTime.fromMillisecondsSinceEpoch(
                (json['starts_at'] as int) * 1000,
              )
              : null,
      expiresAt:
          json['expires_at'] != null
              ? DateTime.fromMillisecondsSinceEpoch(
                (json['expires_at'] as int) * 1000,
              )
              : null,
      status: _parseStatus(json['status'] as String?),
      autoRenew: json['auto_renew'] == 1 || json['auto_renew'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'tier': tier.name.toLowerCase(),
      'platform': platform,
      'transaction_id': transactionId,
      'starts_at':
          startsAt != null
              ? (startsAt!.millisecondsSinceEpoch / 1000).floor()
              : null,
      'expires_at':
          expiresAt != null
              ? (expiresAt!.millisecondsSinceEpoch / 1000).floor()
              : null,
      'status': status.name.toLowerCase(),
      'auto_renew': autoRenew ? 1 : 0,
    };
  }

  static SubscriptionTier _parseTier(String? tier) {
    switch (tier?.toLowerCase()) {
      case 'premium':
        return SubscriptionTier.premium;
      case 'free':
      default:
        return SubscriptionTier.free;
    }
  }

  static SubscriptionStatus _parseStatus(String? status) {
    switch (status?.toLowerCase()) {
      case 'active':
        return SubscriptionStatus.active;
      case 'canceled':
        return SubscriptionStatus.canceled;
      case 'expired':
        return SubscriptionStatus.expired;
      case 'trial':
        return SubscriptionStatus.trial;
      case 'paused':
        return SubscriptionStatus.paused;
      default:
        return SubscriptionStatus.expired;
    }
  }

  SubscriptionModel copyWith({
    String? userId,
    SubscriptionTier? tier,
    String? platform,
    String? transactionId,
    DateTime? startsAt,
    DateTime? expiresAt,
    SubscriptionStatus? status,
    bool? autoRenew,
  }) {
    return SubscriptionModel(
      userId: userId ?? this.userId,
      tier: tier ?? this.tier,
      platform: platform ?? this.platform,
      transactionId: transactionId ?? this.transactionId,
      startsAt: startsAt ?? this.startsAt,
      expiresAt: expiresAt ?? this.expiresAt,
      status: status ?? this.status,
      autoRenew: autoRenew ?? this.autoRenew,
    );
  }
}
