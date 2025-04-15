import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:in_app_purchase/in_app_purchase.dart'; // Import ProductDetails
import 'package:collection/collection.dart'; // Import collection package for firstWhereOrNull
import '../bloc/subscription_provider.dart';
import '../../core/di/locator.dart';
import '../../core/services/file_logger_service.dart';
import '../widgets/custom_badge.dart'; // For premium badge

// Define product ID locally (or import from a constants file)
// Ensure this matches the ID in SubscriptionProvider and your store configuration
const String _premiumMonthlyProductId = 'mediswitch_premium_monthly';

class SubscriptionScreen extends StatelessWidget {
  const SubscriptionScreen({super.key});

  static final FileLoggerService _logger = locator<FileLoggerService>();

  @override
  Widget build(BuildContext context) {
    _logger.d("SubscriptionScreen: Building widget.");
    final provider = context.watch<SubscriptionProvider>();
    final theme = Theme.of(context); // Define theme here to pass to helper
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    // Find the monthly premium product details using firstWhereOrNull
    final ProductDetails? premiumProduct = provider.products.firstWhereOrNull(
      (p) => p.id == _premiumMonthlyProductId,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('الاشتراك Premium')),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Current Status Card
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('حالة الاشتراك الحالية:', style: textTheme.titleMedium),
                  CustomBadge(
                    // Use isPremiumUser getter
                    label: provider.isPremiumUser ? 'Premium' : 'مجاني',
                    backgroundColor:
                        provider.isPremiumUser
                            ? Colors.amber.shade700
                            : colorScheme.secondaryContainer,
                    textColor:
                        provider.isPremiumUser
                            ? Colors.white
                            : colorScheme.onSecondaryContainer,
                    icon: provider.isPremiumUser ? LucideIcons.star : null,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Premium Plan Card
          if (premiumProduct != null)
            Card(
              elevation: 1,
              color: colorScheme.primaryContainer.withOpacity(0.3),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0),
                side: BorderSide(color: colorScheme.primary.withOpacity(0.5)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          premiumProduct.title,
                          style: textTheme.headlineSmall?.copyWith(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Icon(
                          LucideIcons.gem,
                          color: colorScheme.primary,
                          size: 28,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'احصل على الميزات الحصرية:',
                      style: textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    // Pass theme to helper function
                    _buildFeatureRow(
                      theme,
                      LucideIcons.history,
                      'حفظ سجل البحث',
                    ),
                    _buildFeatureRow(
                      theme,
                      LucideIcons.bellRing,
                      'تنبيهات تغير الأسعار',
                    ),
                    _buildFeatureRow(
                      theme,
                      LucideIcons.save,
                      'حفظ حسابات الجرعات',
                    ),
                    _buildFeatureRow(
                      theme,
                      LucideIcons.star,
                      'إضافة الأدوية للمفضلة',
                    ),
                    _buildFeatureRow(
                      theme,
                      LucideIcons.zapOff,
                      'إزالة الإعلانات',
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          premiumProduct.price,
                          style: textTheme.displaySmall?.copyWith(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      icon:
                          provider.isLoading
                              ? const SizedBox.shrink()
                              : Icon(LucideIcons.shoppingCart, size: 18),
                      label: Text(
                        provider.isLoading ? 'جاري المعالجة...' : 'اشترك الآن',
                      ),
                      onPressed:
                          provider.isLoading ||
                                  provider
                                      .isPremiumUser // Use isPremiumUser
                              ? null
                              : () {
                                _logger.i(
                                  "SubscriptionScreen: Subscribe button tapped for ${premiumProduct.id}.",
                                );
                                // Call correct purchase method
                                provider.purchaseSubscription(premiumProduct);
                              },
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 52),
                        textStyle: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else if (provider.isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: CircularProgressIndicator(),
              ),
            )
          else
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 32.0,
                  horizontal: 16.0,
                ),
                child: Text(
                  provider.error.isNotEmpty
                      ? 'خطأ في تحميل خطط الاشتراك: ${provider.error}'
                      : 'خطط الاشتراك غير متاحة حالياً.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: colorScheme.error),
                ),
              ),
            ),

          const SizedBox(height: 24),

          // Restore Purchases Button
          TextButton(
            onPressed:
                provider.isLoading
                    ? null
                    : () {
                      _logger.i(
                        "SubscriptionScreen: Restore purchases tapped.",
                      );
                      provider.restorePurchases();
                    },
            child: const Text('استعادة المشتريات السابقة'),
          ),
        ],
      ),
    );
  }

  // Pass Theme context to helper function
  Widget _buildFeatureRow(ThemeData theme, IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: theme.colorScheme.primary,
          ), // Use theme from argument
          const SizedBox(width: 12),
          Expanded(
            child: Text(text, style: theme.textTheme.bodyMedium),
          ), // Use theme from argument
        ],
      ),
    );
  }
}
