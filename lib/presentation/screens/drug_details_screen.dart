import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart'; // Import intl
import '../../domain/entities/drug_entity.dart';
import '../bloc/alternatives_provider.dart';
import '../screens/alternatives_screen.dart';
// import '../../main.dart'; // No longer needed
// import '../../domain/usecases/find_drug_alternatives.dart'; // No longer needed directly
import '../screens/weight_calculator_screen.dart'; // Import Calculator Screen
import '../screens/interaction_checker_screen.dart'; // Import Interaction Screen
import '../bloc/dose_calculator_provider.dart'; // Import Dose Calculator Provider
import '../bloc/interaction_provider.dart'; // Import Interaction Provider
import '../bloc/subscription_provider.dart'; // Import Subscription Provider

class DrugDetailsScreen extends StatefulWidget {
  final DrugEntity drug;

  const DrugDetailsScreen({super.key, required this.drug});

  @override
  State<DrugDetailsScreen> createState() => _DrugDetailsScreenState();
}

class _DrugDetailsScreenState extends State<DrugDetailsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    // Initialize TabController with 4 tabs as per prototype
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Access providers via context
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    // Access SubscriptionProvider
    final subscriptionProvider = context.watch<SubscriptionProvider>();

    return Scaffold(
      appBar: AppBar(
        // Match general AppBar style (e.g., from HomeHeader or theme)
        backgroundColor: colorScheme.surface, // Use surface color? or primary?
        foregroundColor: colorScheme.onSurface, // Adjust foreground accordingly
        elevation: 0.5, // Subtle elevation or 0
        title: Text(
          widget.drug.arabicName.isNotEmpty
              ? widget.drug.arabicName
              : widget.drug.tradeName,
          style: textTheme.titleLarge, // Use consistent title style
        ),
        actions: [
          // Favorite Button - Premium Feature Control
          Consumer<SubscriptionProvider>(
            // Use Consumer for reactivity
            builder: (context, subProvider, child) {
              // TODO: Add logic to check if this specific drug IS already a favorite
              bool isCurrentlyFavorite = false; // Placeholder
              bool canFavorite = subProvider.isPremiumUser;

              return IconButton(
                icon: Icon(
                  isCurrentlyFavorite ? Icons.favorite : Icons.favorite_border,
                  color: canFavorite ? colorScheme.primary : Colors.grey,
                ),
                tooltip:
                    canFavorite
                        ? (isCurrentlyFavorite
                            ? 'إزالة من المفضلة'
                            : 'إضافة للمفضلة')
                        : 'إضافة للمفضلة (ميزة Premium)',
                onPressed: () {
                  if (canFavorite) {
                    // TODO: Implement actual add/remove favorite logic
                    print('Toggle favorite for ${widget.drug.tradeName}');
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          isCurrentlyFavorite
                              ? 'تمت الإزالة من المفضلة (مؤقت)'
                              : 'تمت الإضافة للمفضلة (مؤقت)',
                        ),
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  } else {
                    // Show premium required message
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text(
                          'ميزة المفضلة تتطلب اشتراك Premium.',
                        ),
                        action: SnackBarAction(
                          label: 'اشترك الآن',
                          onPressed: () {
                            // TODO: Navigate to SubscriptionScreen
                            print('Navigate to Subscription Screen');
                          },
                        ),
                      ),
                    );
                  }
                },
              );
            },
          ),
        ],
      ),
      body: NestedScrollView(
        // Use NestedScrollView for collapsing header effect with tabs
        headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
          return <Widget>[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  16.0,
                  16.0,
                  16.0,
                  8.0,
                ), // Adjust padding
                child: _buildDrugHeader(context, textTheme, colorScheme),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
                child: _buildPriceSection(context, textTheme, colorScheme),
              ),
            ),
            SliverPersistentHeader(
              // Make TabBar sticky
              delegate: _SliverAppBarDelegate(
                TabBar(
                  controller: _tabController,
                  // Match shadcn Tabs style
                  labelColor: colorScheme.primary, // Active tab color
                  unselectedLabelColor:
                      colorScheme.onSurfaceVariant, // Inactive tab color
                  indicatorColor: colorScheme.primary, // Indicator color
                  indicatorWeight: 2.0, // Indicator thickness
                  indicatorSize:
                      TabBarIndicatorSize.label, // Indicator size matches label
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  labelStyle: textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ), // Active label style
                  unselectedLabelStyle:
                      textTheme.bodyLarge, // Inactive label style
                  tabs: const [
                    Tab(text: 'معلومات'),
                    Tab(text: 'البدائل'),
                    Tab(text: 'الجرعات'),
                    Tab(text: 'التفاعلات'),
                  ],
                ),
              ),
              pinned: true,
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            // --- Info Tab ---
            _buildInfoTab(context, textTheme),
            // --- Alternatives Tab ---
            _buildAlternativesTab(context), // No longer needs use case passed
            // --- Dosage Tab ---
            _buildDosageTab(context),
            // --- Interactions Tab ---
            _buildInteractionsTab(context),
          ],
        ),
      ),
    );
  }

  // --- Header Builder ---
  Widget _buildDrugHeader(
    BuildContext context,
    TextTheme textTheme,
    ColorScheme colorScheme,
  ) {
    // Match shadcn Card style more closely
    return Card(
      elevation: 0, // shadcn cards often have 0 elevation
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12), // Match theme --radius
        side: BorderSide(
          color: colorScheme.outline.withOpacity(0.5),
        ), // Subtle border
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment:
              CrossAxisAlignment.center, // Center items vertically
          children: [
            // Drug Image/Icon - Wrapped with Hero
            Hero(
              tag:
                  'drug_image_${widget.drug.tradeName}', // Use the same tag as in DrugListItem
              child: Container(
                // Placeholder container for image/icon
                width: 64, // Adjust size
                height: 64,
                decoration: BoxDecoration(
                  color: colorScheme.secondaryContainer.withOpacity(
                    0.3,
                  ), // Use secondary container
                  borderRadius: BorderRadius.circular(
                    8,
                  ), // Match theme --radius
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12.0),
                  child:
                      widget.drug.imageUrl != null &&
                              widget.drug.imageUrl!.isNotEmpty
                          ? CachedNetworkImage(
                            imageUrl: widget.drug.imageUrl!,
                            placeholder:
                                (context, url) => const Center(
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.0,
                                  ),
                                ),
                            errorWidget:
                                (context, url, error) => Icon(
                                  Icons.medication_liquid_outlined,
                                  color: colorScheme.primary.withOpacity(0.7),
                                  size: 35,
                                ),
                            fit: BoxFit.cover,
                          )
                          : Icon(
                            Icons.medication_liquid_outlined,
                            color: colorScheme.primary.withOpacity(0.7),
                            size: 35,
                          ), // Placeholder icon
                ),
              ),
            ),
            const SizedBox(width: 16.0),
            // Drug Name and Active Ingredient
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.drug.tradeName,
                    style: textTheme.titleMedium?.copyWith(
                      // Adjust text style if needed
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (widget.drug.arabicName.isNotEmpty &&
                      widget.drug.arabicName != widget.drug.tradeName)
                    Padding(
                      padding: const EdgeInsets.only(top: 2.0),
                      child: Text(
                        widget.drug.arabicName,
                        style: textTheme.bodyMedium?.copyWith(
                          // Adjust text style
                          color: colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  const SizedBox(height: 4.0),
                  Text(
                    widget.drug.active, // Active Ingredient
                    style: textTheme.bodySmall?.copyWith(
                      // Adjust text style
                      color: colorScheme.secondary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Price Section Builder ---
  Widget _buildPriceSection(
    BuildContext context,
    TextTheme textTheme,
    ColorScheme colorScheme,
  ) {
    // TODO: Add logic for old price and percentage change if available
    // Match shadcn Card style
    return Card(
      elevation: 0, // No elevation
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12), // Match theme --radius
        side: BorderSide(
          color: colorScheme.outline.withOpacity(0.5),
        ), // Subtle border
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('السعر الحالي:', style: textTheme.bodyLarge), // Adjust style
            // Format the price
            Builder(
              // Use Builder to access context for NumberFormat locale if needed
              builder: (context) {
                final priceDouble = double.tryParse(widget.drug.price);
                final formattedPrice =
                    priceDouble != null
                        ? NumberFormat("#,##0.##", "en_US").format(
                          priceDouble,
                        ) // Basic formatting
                        : widget.drug.price; // Fallback to original string
                return Text(
                  '$formattedPrice جنيه',
                  style: textTheme.titleMedium?.copyWith(
                    // Adjust style
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                );
              },
            ),
            // Placeholder for price change indicator
            // Container(
            //   padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            //   decoration: BoxDecoration(
            //     color: Colors.red.shade100, // Example for decrease
            //     borderRadius: BorderRadius.circular(12),
            //   ),
            //   child: Text('-16.7%', style: TextStyle(color: Colors.red.shade800, fontSize: 12, fontWeight: FontWeight.bold)),
            // )
          ],
        ),
      ),
    );
  }

  // --- Tab Builders ---

  Widget _buildInfoTab(BuildContext context, TextTheme textTheme) {
    // Displays drug details based on prototype's "معلومات" tab
    return ListView(
      // Use ListView for potentially long content
      padding: const EdgeInsets.all(16.0),
      children: [
        _buildDetailRow('الشركة', widget.drug.company),
        _buildDetailRow('الفئة الرئيسية', widget.drug.mainCategory),
        _buildDetailRow('الشكل الصيدلي', widget.drug.dosageForm),
        _buildDetailRow('الوحدة', widget.drug.unit),
        _buildDetailRow('الاستخدام', widget.drug.usage),
        _buildDetailRow('الوصف', widget.drug.description),
        _buildDetailRow('آخر تحديث للسعر', widget.drug.lastPriceUpdate),
      ],
    );
  }

  Widget _buildAlternativesTab(BuildContext context) {
    // AlternativesProvider is now provided globally via main.dart
    // We just need to ensure the screen uses it correctly.
    // The AlternativesScreen itself likely uses context.watch/read
    return AlternativesScreen(
      originalDrug: widget.drug,
    ); // Pass the drug, provider is accessed internally by AlternativesScreen
  }

  Widget _buildDosageTab(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final bool hasUsageInfo = widget.drug.usage.isNotEmpty;

    return ListView(
      // Use ListView for consistency and potential future additions
      padding: const EdgeInsets.all(16.0),
      children: [
        Text('معلومات الجرعة القياسية', style: textTheme.titleLarge),
        const SizedBox(height: 16),
        if (hasUsageInfo)
          // Use a simpler container or just Text if no card needed
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 12.0,
            ),
            decoration: BoxDecoration(
              color: colorScheme.surfaceVariant.withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colorScheme.outline.withOpacity(0.3)),
            ),
            child: Text(widget.drug.usage, style: textTheme.bodyLarge),
          )
        else
          Container(
            // Placeholder container
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 12.0,
            ),
            decoration: BoxDecoration(
              color: colorScheme.surfaceVariant.withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colorScheme.outline.withOpacity(0.3)),
            ),
            child: Text(
              'لا توجد معلومات جرعة قياسية متاحة لهذا الدواء.',
              style: textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).hintColor,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        const SizedBox(height: 24),
        const Divider(),
        const SizedBox(height: 16),
        Center(
          child: ElevatedButton.icon(
            icon: const Icon(Icons.calculate_outlined),
            label: const Text('حساب الجرعة بالوزن'),
            onPressed: () {
              // Clear previous calculator state and set the drug
              final doseProvider = context.read<DoseCalculatorProvider>();
              doseProvider.setSelectedDrug(widget.drug);
              // Navigate to the calculator screen
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const WeightCalculatorScreen(),
                ),
              );
            },
            // Match shadcn button style
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
              textStyle: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInteractionsTab(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return ListView(
      // Use ListView for consistency
      padding: const EdgeInsets.all(16.0),
      children: [
        Text('فحص التفاعلات الدوائية', style: textTheme.titleLarge),
        const SizedBox(height: 16),
        // Use a simpler container or just Text
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          decoration: BoxDecoration(
            color: colorScheme.surfaceVariant.withOpacity(0.5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colorScheme.outline.withOpacity(0.3)),
          ),
          child: Text(
            'يمكنك فحص التفاعلات المحتملة بين ${widget.drug.tradeName} وأدوية أخرى تستخدمها.',
            style: textTheme.bodyLarge,
          ),
        ),
        const SizedBox(height: 24),
        Center(
          child: ElevatedButton.icon(
            icon: const Icon(Icons.health_and_safety_outlined),
            label: const Text('فحص التفاعلات الآن'),
            onPressed: () {
              // Clear previous interaction state and add current drug
              final interactionProvider = context.read<InteractionProvider>();
              interactionProvider.clearSelection();
              interactionProvider.addMedicine(widget.drug);

              // Navigate to the interaction checker screen
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const InteractionCheckerScreen(),
                ),
              );
            },
            // Match shadcn button style
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
              textStyle: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ),
        const SizedBox(height: 16),
        // TODO: Optionally display known interactions for *this* drug if data is available
        // This would require fetching/filtering interaction data based on the current drug.
        // Example:
        // Text('تفاعلات معروفة:', style: textTheme.titleMedium),
        // FutureBuilder<List<DrugInteraction>>(
        //   future: fetchKnownInteractionsFor(widget.drug), // Hypothetical function
        //   builder: (context, snapshot) {
        //     if (snapshot.connectionState == ConnectionState.waiting) {
        //       return const Center(child: CircularProgressIndicator());
        //     } else if (snapshot.hasError) {
        //       return const Text('خطأ في تحميل التفاعلات المعروفة.');
        //     } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
        //       return const Text('لا توجد تفاعلات معروفة مسجلة لهذا الدواء.');
        //     } else {
        //       return Column(
        //         children: snapshot.data!.map((interaction) => _buildInteractionCard(...)).toList(),
        //       );
        //     }
        //   },
        // ),
      ],
    );
  }

  // Helper to build detail row (Improved styling)
  Widget _buildDetailRow(String label, String value) {
    if (value.isEmpty) return const SizedBox.shrink();
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0), // Adjusted padding
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110, // Fixed width for label column
            child: Text(
              label,
              style: textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600, // Make label slightly bolder
                color:
                    colorScheme.onSurfaceVariant, // Use a slightly muted color
              ),
            ),
          ),
          const SizedBox(width: 12), // Increased space
          Expanded(
            child: Text(
              value,
              style: textTheme.bodyLarge, // Use bodyLarge for value
            ),
          ),
        ],
      ),
    );
  }
}

// Helper class to make TabBar sticky under SliverAppBar
class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._tabBar);

  final TabBar _tabBar;

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    // Add a background color and potentially a bottom border to match AppBar style
    return Container(
      color:
          Theme.of(
            context,
          ).scaffoldBackgroundColor, // Or Theme.of(context).appBarTheme.backgroundColor
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false; // TabBar itself usually doesn't change
  }
}
