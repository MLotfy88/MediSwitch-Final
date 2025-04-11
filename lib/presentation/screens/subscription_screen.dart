import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:in_app_purchase/in_app_purchase.dart'; // Import for ProductDetails
import '../bloc/subscription_provider.dart'; // Import the provider

class SubscriptionScreen extends StatelessWidget {
  const SubscriptionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final subscriptionProvider = context.watch<SubscriptionProvider>();
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('الاشتراك المميز (Premium)'),
        // Match general AppBar style
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0.5,
      ),
      body: _buildBody(
        context,
        subscriptionProvider,
        theme,
        textTheme,
        colorScheme,
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    SubscriptionProvider provider,
    ThemeData theme,
    TextTheme textTheme,
    ColorScheme colorScheme,
  ) {
    if (!provider.isStoreAvailable) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Text(
            'المتجر غير متاح حالياً على هذا الجهاز. لا يمكن عرض خيارات الشراء.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    if (provider.isLoading && provider.products.isEmpty) {
      // Show loading only if products haven't been loaded yet
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.error.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, color: colorScheme.error, size: 40),
              const SizedBox(height: 16),
              Text(
                'حدث خطأ:\n${provider.error}',
                textAlign: TextAlign.center,
                style: TextStyle(color: colorScheme.error),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed:
                    () =>
                        context
                            .read<SubscriptionProvider>()
                            .retryInitialization(), // Add retry method to provider
                child: const Text('إعادة المحاولة'),
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        // Current Status Section
        _buildStatusCard(context, provider, textTheme, colorScheme),
        const SizedBox(height: 24),

        // Available Products Section
        Text('خيارات الاشتراك:', style: textTheme.titleLarge),
        const SizedBox(height: 8),
        if (provider.products.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24.0),
            child: Center(child: Text('لا توجد خطط اشتراك متاحة حالياً.')),
          )
        else
          ...provider.products.map(
            (product) => _buildProductCard(
              context,
              provider,
              product,
              textTheme,
              colorScheme,
            ),
          ),

        const SizedBox(height: 24),
        const Divider(),
        const SizedBox(height: 16),

        // Restore Purchases Button
        Center(
          // Match shadcn Button (outline variant)
          child: OutlinedButton(
            onPressed:
                provider.isLoading
                    ? null
                    : () =>
                        context.read<SubscriptionProvider>().restorePurchases(),
            style: OutlinedButton.styleFrom(
              foregroundColor: colorScheme.primary,
              side: BorderSide(color: colorScheme.primary.withOpacity(0.7)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            child: const Text('استعادة المشتريات السابقة'),
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: Text(
            'إذا كنت قد اشتركت سابقاً على هذا الحساب، اضغط هنا لاستعادة اشتراكك.',
            textAlign: TextAlign.center,
            style: textTheme.bodySmall?.copyWith(color: theme.hintColor),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusCard(
    BuildContext context,
    SubscriptionProvider provider,
    TextTheme textTheme,
    ColorScheme colorScheme,
  ) {
    // Match general Card style
    return Card(
      elevation: 0, // No elevation
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12), // Match theme --radius
        side: BorderSide(
          color: colorScheme.outline.withOpacity(0.5),
        ), // Subtle border
      ),
      color:
          provider.isPremiumUser
              ? colorScheme.primaryContainer.withOpacity(
                0.3,
              ) // Use lighter primary container for premium
              : colorScheme.surfaceVariant.withOpacity(
                0.5,
              ), // Use surface variant for free
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(
              provider.isPremiumUser
                  ? Icons.workspace_premium
                  : Icons.account_circle_outlined,
              size: 30,
              color:
                  // Use consistent colors based on card background
                  provider.isPremiumUser
                      ? colorScheme
                          .primary // Use primary color for premium icon
                      : colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'حالة الاشتراك الحالية:',
                    style: textTheme.labelLarge?.copyWith(
                      color:
                          // Use consistent colors based on card background
                          provider.isPremiumUser
                              ? colorScheme.onPrimaryContainer
                              : colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    provider.isPremiumUser ? 'مميز (Premium)' : 'مجاني',
                    style: textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color:
                          // Use consistent colors based on card background
                          provider.isPremiumUser
                              ? colorScheme.onPrimaryContainer
                              : colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductCard(
    BuildContext context,
    SubscriptionProvider provider,
    ProductDetails product,
    TextTheme textTheme,
    ColorScheme colorScheme,
  ) {
    // Match general Card style
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      elevation: 0, // No elevation
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12), // Match theme --radius
        side: BorderSide(
          color: colorScheme.outline.withOpacity(0.5),
        ), // Subtle border
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              product.title,
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            if (product.description.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(product.description, style: textTheme.bodyMedium),
            ],
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  product.price,
                  style: textTheme.headlineSmall?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                // Match shadcn Button style
                ElevatedButton(
                  onPressed:
                      provider.isLoading
                          ? null
                          : () => provider.purchaseSubscription(product),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ), // Match theme --radius
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ), // Adjust padding
                    textStyle: const TextStyle(fontWeight: FontWeight.w600),
                  ).copyWith(
                    // Handle disabled state
                    backgroundColor: MaterialStateProperty.resolveWith<Color?>((
                      Set<MaterialState> states,
                    ) {
                      if (states.contains(MaterialState.disabled)) {
                        return colorScheme.primary.withOpacity(0.5);
                      }
                      return colorScheme.primary;
                    }),
                    foregroundColor: MaterialStateProperty.resolveWith<Color?>((
                      Set<MaterialState> states,
                    ) {
                      if (states.contains(MaterialState.disabled)) {
                        return colorScheme.onPrimary.withOpacity(0.7);
                      }
                      return colorScheme.onPrimary;
                    }),
                  ),
                  child:
                      provider.isLoading
                          ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                          : const Text('اشترك الآن'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Add this method to SubscriptionProvider
extension SubscriptionProviderRetry on SubscriptionProvider {
  Future<void> retryInitialization() async {
    // This extension method might not be strictly necessary anymore
    // as the initialize method is public, but we keep it for the retry button logic.
    if (!isLoading) {
      print("Retrying subscription initialization...");
      await initialize(); // Call the public initialize method
    }
  }
}
