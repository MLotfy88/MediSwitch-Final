class SubscriptionEntity {
  final String userId;
  final SubscriptionTier tier;
  final String platform;
  final String? transactionId;
  final DateTime? startsAt;
  final DateTime? expiresAt;
  final SubscriptionStatus status;
  final bool autoRenew;

  const SubscriptionEntity({
    required this.userId,
    required this.tier,
    required this.platform,
    this.transactionId,
    this.startsAt,
    this.expiresAt,
    required this.status,
    this.autoRenew = true,
  });

  bool get isPremium =>
      tier == SubscriptionTier.premium && status == SubscriptionStatus.active;
  bool get isActive =>
      status == SubscriptionStatus.active &&
      (expiresAt?.isAfter(DateTime.now()) ?? false);
  bool get isTrial => status == SubscriptionStatus.trial;
  bool get isFree => tier == SubscriptionTier.free;
}

enum SubscriptionTier { free, premium }

enum SubscriptionStatus { active, canceled, expired, trial, paused }

extension SubscriptionTierExtension on SubscriptionTier {
  String get name {
    switch (this) {
      case SubscriptionTier.free:
        return 'Free';
      case SubscriptionTier.premium:
        return 'Premium';
    }
  }

  String get nameAr {
    switch (this) {
      case SubscriptionTier.free:
        return 'مجاني';
      case SubscriptionTier.premium:
        return 'مميز';
    }
  }

  String get icon {
    switch (this) {
      case SubscriptionTier.free:
        return '🆓';
      case SubscriptionTier.premium:
        return '💎';
    }
  }

  List<String> get features {
    switch (this) {
      case SubscriptionTier.free:
        return [
          'Basic drug search',
          'Up to 50 favorites',
          'Basic interaction checker (2 drugs)',
          'Ads supported',
        ];
      case SubscriptionTier.premium:
        return [
          'Ad-free experience',
          'Offline mode (full database)',
          'Unlimited favorites',
          'Advanced interaction checker (5+ drugs)',
          'PDF export',
          'Priority support',
          '7-day free trial',
        ];
    }
  }

  List<String> get featuresAr {
    switch (this) {
      case SubscriptionTier.free:
        return [
          'بحث أساسي عن الأدوية',
          'حتى 50 دواء في المفضلة',
          'فاحص تفاعلات أساسي (دوائين)',
          'مدعوم بالإعلانات',
        ];
      case SubscriptionTier.premium:
        return [
          'تجربة بدون إعلانات',
          'وضع عدم الاتصال (قاعدة بيانات كاملة)',
          'مفضلات غير محدودة',
          'فاحص تفاعلات متقدم (5+ أدوية)',
          'تصدير PDF',
          'دعم ذو أولوية',
          'تجربة مجانية 7 أيام',
        ];
    }
  }

  double get monthlyPrice {
    switch (this) {
      case SubscriptionTier.free:
        return 0.0;
      case SubscriptionTier.premium:
        return 2.99;
    }
  }

  double get yearlyPrice {
    switch (this) {
      case SubscriptionTier.free:
        return 0.0;
      case SubscriptionTier.premium:
        return 24.99; // Save 30%
    }
  }
}
