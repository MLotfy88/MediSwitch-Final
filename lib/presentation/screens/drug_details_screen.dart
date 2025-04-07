import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../domain/entities/drug_entity.dart';
import '../bloc/alternatives_provider.dart';
import '../screens/alternatives_screen.dart';
import '../../main.dart'; // TODO: Remove temporary DI access
import '../../domain/usecases/find_drug_alternatives.dart';
// TODO: Import Interaction Checker related widgets/providers when ready
// TODO: Import Dosage Calculator related widgets/providers when ready

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
    // TODO: Replace temporary access via MyApp with proper DI
    final findAlternativesUseCase =
        Provider.of<MyApp>(context, listen: false).findDrugAlternativesUseCase;
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.drug.arabicName.isNotEmpty
              ? widget.drug.arabicName
              : widget.drug.tradeName,
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.favorite_border,
            ), // TODO: Implement favorite state logic
            tooltip: 'إضافة للمفضلة (Premium)',
            onPressed: () {
              // TODO: Implement Premium check and favorite logic
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('ميزة المفضلة متاحة في الإصدار المدفوع.'),
                ),
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
            _buildAlternativesTab(context, findAlternativesUseCase),
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

  Widget _buildAlternativesTab(
    BuildContext context,
    FindDrugAlternativesUseCase findAlternativesUseCase,
  ) {
    // Embeds the AlternativesScreen directly within the tab
    return ChangeNotifierProvider(
      create:
          (_) => AlternativesProvider(
            findDrugAlternativesUseCase: findAlternativesUseCase,
          ),
      child: AlternativesScreen(
        originalDrug: widget.drug,
      ), // Removed isEmbedded
    );
  }

  Widget _buildDosageTab(BuildContext context) {
    // Placeholder for Dosage Calculator specific to this drug, styled like prototype
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Card(
        // Wrap form in a card
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'حاسبة الجرعات لـ ${widget.drug.tradeName}',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 20),
              TextField(
                decoration: InputDecoration(
                  labelText: 'الوزن (كجم)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: const Icon(Icons.monitor_weight_outlined),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextField(
                decoration: InputDecoration(
                  labelText: 'العمر (سنوات)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: const Icon(Icons.person_outline),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 24),
              Center(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.calculate_outlined),
                  label: const Text('حساب الجرعة'),
                  onPressed: () {
                    // TODO: Implement dosage calculation logic
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('جاري العمل على حاسبة الجرعات...'),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Placeholder for result
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.surfaceVariant.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(8),
                  border: Border(
                    left: BorderSide(
                      color: Theme.of(context).colorScheme.primary,
                      width: 4,
                    ),
                  ),
                ),
                child: const Text('سيتم عرض نتيجة حساب الجرعة هنا.'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInteractionsTab(BuildContext context) {
    // Placeholder for Interactions specific to this drug
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'التفاعلات الدوائية المعروفة لـ ${widget.drug.tradeName}',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          // TODO: Fetch and display known interactions for this drug using InteractionCard widget (to be created)
          const ListTile(
            leading: Icon(Icons.warning_amber_rounded, color: Colors.orange),
            title: Text('وارفارين'),
            subtitle: Text('قد يزيد الباراسيتامول من تأثير الوارفارين.'),
          ),
          const ListTile(
            leading: Icon(Icons.info_outline_rounded, color: Colors.blue),
            title: Text('ميتوكلوبراميد'),
            subtitle: Text('قد يزيد من سرعة امتصاص الباراسيتامول.'),
          ),
          const SizedBox(height: 24),
          Center(
            child: ElevatedButton.icon(
              icon: const Icon(Icons.health_and_safety_outlined),
              label: const Text('فحص التفاعلات مع أدوية أخرى'),
              onPressed: () {
                // TODO: Navigate to the full Interaction Checker screen, potentially pre-filling this drug
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('جاري العمل على شاشة فحص التفاعلات...'),
                  ),
                );
                print("Navigate to Interaction Checker");
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ),
        ],
      ),
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
