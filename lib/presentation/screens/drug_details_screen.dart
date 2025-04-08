import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
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
        title: Text(
          widget.drug.arabicName.isNotEmpty
              ? widget.drug.arabicName
              : widget.drug.tradeName,
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
                  labelColor: colorScheme.primary,
                  unselectedLabelColor: Colors.grey.shade600,
                  indicatorColor: colorScheme.primary,
                  indicatorWeight: 3.0,
                  isScrollable: true, // Allow tabs to scroll horizontally
                  tabAlignment: TabAlignment.start, // Align tabs to the start
                  labelStyle: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 15,
                  ),
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
    // Mimics .drug-header from prototype with Card styling
    return Card(
      elevation: 2, // Slightly more elevation
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ), // .rounded-lg
      clipBehavior: Clip.antiAlias, // Clip content to rounded corners
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment:
              CrossAxisAlignment.center, // Center items vertically
          children: [
            // Drug Image/Icon
            Container(
              width: 70, // Size from prototype analysis
              height: 70,
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withOpacity(0.3),
                borderRadius: BorderRadius.circular(
                  12,
                ), // Slightly less rounded than circle
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
            const SizedBox(width: 16.0),
            // Drug Name and Active Ingredient
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.drug.tradeName,
                    style: textTheme.titleLarge?.copyWith(
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
                        style: textTheme.titleMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  const SizedBox(height: 4.0),
                  Text(
                    widget.drug.active, // Active Ingredient
                    style: textTheme.bodyMedium?.copyWith(
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
    // For now, just showing current price based on prototype structure
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('السعر الحالي:', style: textTheme.titleMedium),
            Text(
              '${widget.drug.price} جنيه',
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
              ),
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
          Card(
            elevation: 0.5,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: colorScheme.outline.withOpacity(0.3)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(widget.drug.usage, style: textTheme.bodyLarge),
            ),
          )
        else
          Card(
            // Show a placeholder card if no usage info
            elevation: 0.5,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: colorScheme.outline.withOpacity(0.3)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'لا توجد معلومات جرعة قياسية متاحة لهذا الدواء.',
                style: textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).hintColor,
                ),
                textAlign: TextAlign.center,
              ),
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
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
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
        Card(
          // Info card
          elevation: 0.5,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: colorScheme.outline.withOpacity(0.3)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'يمكنك فحص التفاعلات المحتملة بين ${widget.drug.tradeName} وأدوية أخرى تستخدمها.',
              style: textTheme.bodyLarge,
            ),
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
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
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

  // Helper to build detail row
  Widget _buildDetailRow(String label, String value) {
    if (value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 8.0,
      ), // Increased vertical padding
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
          ), // Slightly larger label
          const SizedBox(width: 8), // Add space
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 15,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
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
