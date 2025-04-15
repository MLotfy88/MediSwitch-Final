import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/drug_entity.dart';
import '../widgets/custom_badge.dart';
import '../../core/di/locator.dart';
import '../../core/services/file_logger_service.dart';
import '../widgets/alternatives_tab_content.dart';
import 'weight_calculator_screen.dart';
import 'interaction_checker_screen.dart';
import '../bloc/dose_calculator_provider.dart';
import '../bloc/interaction_provider.dart';

class DrugDetailsScreen extends StatefulWidget {
  final DrugEntity drug;

  const DrugDetailsScreen({super.key, required this.drug});

  @override
  State<DrugDetailsScreen> createState() => _DrugDetailsScreenState();
}

class _DrugDetailsScreenState extends State<DrugDetailsScreen>
    with SingleTickerProviderStateMixin {
  final FileLoggerService _logger = locator<FileLoggerService>();
  late TabController _tabController;

  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    // Update tab count to 5 based on design documentation
    _tabController = TabController(length: 5, vsync: this);
    _logger.i(
      "DrugDetailsScreen: initState for drug: ${widget.drug.tradeName}",
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _logger.i("DrugDetailsScreen: dispose for drug: ${widget.drug.tradeName}");
    super.dispose();
  }

  String _formatPrice(String priceString) {
    final price = double.tryParse(priceString);
    if (price == null) return priceString;
    return NumberFormat("#,##0.##", "en_US").format(price);
  }

  double? _parsePrice(String? priceString) {
    if (priceString == null) return null;
    final cleanedPrice = priceString.replaceAll(RegExp(r'[^0-9.]'), '');
    return double.tryParse(cleanedPrice);
  }

  String _formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return '-';
    try {
      DateTime dateTime;
      if (dateString.contains('/')) {
        dateTime = DateFormat('dd/MM/yyyy').parseStrict(dateString);
      } else {
        dateTime = DateFormat('yyyy-MM-dd').parseStrict(dateString);
      }
      return DateFormat('d MMM yyyy', 'ar').format(dateTime);
    } catch (e) {
      _logger.w("Could not parse date for display: $dateString", e);
      return dateString;
    }
  }

  void _toggleFavorite() {
    _logger.i(
      "DrugDetailsScreen: Favorite button tapped (Premium - Not implemented).",
    );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('ميزة المفضلة تتطلب الاشتراك Premium (قريباً).'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    _logger.i(
      "DrugDetailsScreen: Building widget for drug: ${widget.drug.tradeName}",
    );
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: colorScheme.surface, // bg-card
        elevation: 0,
        foregroundColor: colorScheme.onSurfaceVariant,
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft, size: 20),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: 'رجوع',
        ),
        title: Text(
          'تفاصيل الدواء',
          style: textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        centerTitle: false,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: colorScheme.outline, height: 1.0),
        ),
      ),
      body: ListView(
        // Use ListView for the main layout
        padding: EdgeInsets.zero,
        children: [
          _buildHeaderContent(context, colorScheme, textTheme),
          _buildActionButtons(context, colorScheme, textTheme),
          _buildTabBar(context, colorScheme, textTheme),
          // Use a Container with fixed height for TabBarView content
          Container(
            // Adjust height based on expected content size or screen percentage
            height: MediaQuery.of(context).size.height * 0.35, // Example height
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildInfoTab(context, colorScheme, textTheme),
                _buildUsageTab(context, colorScheme, textTheme),
                _buildDosageTab(context, colorScheme, textTheme),
                _buildSideEffectsTab(context, colorScheme, textTheme),
                _buildContraindicationsTab(context, colorScheme, textTheme),
              ],
            ),
          ),
          _buildAlternativesSection(context, colorScheme, textTheme),
        ],
      ),
    );
  }

  // Updated Header Content to match design reference more closely
  Widget _buildHeaderContent(
    BuildContext context,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    final double? oldPriceValue = _parsePrice(widget.drug.oldPrice);
    final double? currentPriceValue = _parsePrice(widget.drug.price);
    final bool isPriceChanged =
        oldPriceValue != null &&
        currentPriceValue != null &&
        oldPriceValue != currentPriceValue;
    final bool isPriceIncreased =
        isPriceChanged && currentPriceValue! > oldPriceValue!;
    final double priceChangePercentage =
        isPriceChanged && oldPriceValue! != 0
            ? ((currentPriceValue! - oldPriceValue) / oldPriceValue * 100).abs()
            : 0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16), // p-4
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: colorScheme.secondaryContainer.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8.0),
                  child:
                      widget.drug.imageUrl != null &&
                              widget.drug.imageUrl!.isNotEmpty
                          ? CachedNetworkImage(
                            imageUrl: widget.drug.imageUrl!,
                            fit: BoxFit.contain,
                            placeholder:
                                (context, url) => const Center(
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                            errorWidget:
                                (context, url, error) => Center(
                                  child: Icon(
                                    LucideIcons.pill,
                                    size: 30,
                                    color: colorScheme.onSecondaryContainer
                                        .withOpacity(0.5),
                                  ),
                                ),
                          )
                          : Center(
                            child: Icon(
                              LucideIcons.pill,
                              size: 30,
                              color: colorScheme.onSecondaryContainer
                                  .withOpacity(0.5),
                            ),
                          ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.drug.tradeName,
                      style: textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ), // text-xl font-bold
                    ),
                    if (widget.drug.active.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text(
                          widget.drug.active,
                          style: textTheme.bodyMedium?.copyWith(
                            color: colorScheme.primary,
                          ), // text-sm text-primary
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16), // gap-4
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        '${_formatPrice(widget.drug.price)} ج.م',
                        style: textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ), // text-lg font-bold
                      ),
                      if (isPriceChanged)
                        Padding(
                          padding: const EdgeInsetsDirectional.only(start: 6.0),
                          child: CustomBadge(
                            label:
                                '${priceChangePercentage.toStringAsFixed(0)}%',
                            backgroundColor:
                                isPriceIncreased
                                    ? colorScheme.errorContainer.withOpacity(
                                      0.7,
                                    )
                                    : Colors.green.shade100,
                            textColor:
                                isPriceIncreased
                                    ? colorScheme.onErrorContainer
                                    : Colors.green.shade900,
                            icon:
                                isPriceIncreased
                                    ? LucideIcons.arrowUp
                                    : LucideIcons.arrowDown,
                            iconSize: 12,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 1,
                            ),
                            // textStyle: textTheme.labelSmall, // Removed incorrect parameter
                          ),
                        ),
                    ],
                  ),
                  if (oldPriceValue != null)
                    Text(
                      '${_formatPrice(widget.drug.oldPrice!)} ج.م',
                      style: textTheme.bodyMedium?.copyWith(
                        // text-sm
                        color:
                            colorScheme
                                .onSurfaceVariant, // text-muted-foreground
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                ],
              ),
              IconButton(
                icon: Icon(
                  _isFavorite
                      ? Icons.favorite
                      : Icons.favorite_border, // Use Material favorite icons
                  color:
                      _isFavorite
                          ? Colors.red.shade500
                          : colorScheme.outline, // fill-red-500 when favorite
                  size: 24, // h-6 w-6
                ),
                tooltip: 'إضافة للمفضلة (Premium)',
                onPressed: _toggleFavorite,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Action Buttons Section
  Widget _buildActionButtons(
    BuildContext context,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        16.0,
        0,
        16.0,
        16.0,
      ), // mt-4 equivalent + horizontal padding
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              icon: Icon(LucideIcons.calculator, size: 16), // h-4 w-4
              label: const Text('حساب الجرعة'),
              onPressed: () {
                _logger.i(
                  "DrugDetailsScreen: Navigate to WeightCalculator tapped.",
                );
                context.read<DoseCalculatorProvider>().setSelectedDrug(
                  widget.drug,
                );
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const WeightCalculatorScreen(),
                  ),
                );
              },
              style: OutlinedButton.styleFrom(
                foregroundColor:
                    colorScheme.onSurfaceVariant, // Match text color
                side: BorderSide(color: colorScheme.outline), // border-border
              ),
            ),
          ),
          const SizedBox(width: 8), // gap-2
          Expanded(
            child: OutlinedButton.icon(
              icon: Icon(LucideIcons.zap, size: 16), // h-4 w-4
              label: const Text('التفاعلات الدوائية'),
              onPressed: () {
                _logger.i(
                  "DrugDetailsScreen: Navigate to InteractionChecker tapped.",
                );
                context.read<InteractionProvider>().addMedicine(widget.drug);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const InteractionCheckerScreen(),
                  ),
                );
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: colorScheme.onSurfaceVariant,
                side: BorderSide(color: colorScheme.outline),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // TabBar Section
  Widget _buildTabBar(
    BuildContext context,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0), // mt-6 equivalent?
      padding: const EdgeInsets.all(4.0), // p-1
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant, // bg-muted
        borderRadius: BorderRadius.circular(8.0), // rounded-lg
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: colorScheme.primary,
        unselectedLabelColor: colorScheme.onSurfaceVariant,
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(6.0),
          color: colorScheme.background,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        tabs: const [
          Tab(text: 'معلومات أساسية'),
          Tab(text: 'الاستخدامات'),
          Tab(text: 'الجرعات'),
          Tab(text: 'الآثار الجانبية'),
          Tab(text: 'موانع الاستخدام'),
        ],
      ),
    );
  }

  // --- Tab Content Builders ---

  // Updated Info Tab using GridView
  Widget _buildInfoTab(
    BuildContext context,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    _logger.d("DrugDetailsScreen: Building Info Tab using GridView");
    final infoItems = <Map<String, dynamic>>[
      if (widget.drug.company.isNotEmpty)
        {
          'icon': LucideIcons.building2,
          'label': "الشركة:",
          'value': widget.drug.company,
        },
      if (widget.drug.mainCategory.isNotEmpty)
        {
          'icon': LucideIcons.folderOpen,
          'label': "الفئة:",
          'value': widget.drug.mainCategory,
        },
      if (widget.drug.dosageForm.isNotEmpty)
        {
          'icon': LucideIcons.packageSearch,
          'label': "الشكل:",
          'value': widget.drug.dosageForm,
        },
      if (widget.drug.concentration != null || widget.drug.unit.isNotEmpty)
        {
          'icon': LucideIcons.ruler,
          'label': "التركيز:",
          'value':
              '${widget.drug.concentration?.toString() ?? ""} ${widget.drug.unit}'
                  .trim(),
        },
      if (widget.drug.lastPriceUpdate.isNotEmpty)
        {
          'icon': LucideIcons.calendarClock,
          'label': "آخر تحديث:",
          'value': _formatDate(widget.drug.lastPriceUpdate),
        },
      // {'icon': LucideIcons.box, 'label': "حجم العبوة:", 'value': '-'}, // Placeholder for package size
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0), // p-4 for tab content
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, // grid-cols-2
          childAspectRatio: 3.0, // Adjust aspect ratio
          crossAxisSpacing: 16.0, // gap-4
          mainAxisSpacing: 16.0, // gap-4
        ),
        itemCount: infoItems.length,
        itemBuilder: (context, index) {
          final item = infoItems[index];
          return _buildInfoGridItem(
            context,
            icon: item['icon'] as IconData,
            label: item['label'] as String,
            value: item['value'] as String,
          );
        },
      ),
    );
  }

  // Helper to build grid item for info tab (Matches reference style)
  Widget _buildInfoGridItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Container(
      padding: const EdgeInsets.all(12.0), // p-3
      decoration: BoxDecoration(
        color: colorScheme.surface, // bg-card
        borderRadius: BorderRadius.circular(8.0), // rounded-lg
        border: Border.all(color: colorScheme.outline), // border border-border
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 16,
                color: colorScheme.onSurfaceVariant,
              ), // h-4 w-4 text-muted-foreground
              const SizedBox(width: 6),
              Text(
                label,
                style: textTheme.labelMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ), // font-medium text-muted-foreground
              ),
            ],
          ),
          const SizedBox(height: 4), // space-y-1 equivalent
          Padding(
            padding: const EdgeInsetsDirectional.only(start: 22),
            child: Text(
              value,
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface,
              ), // Default text color
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // Placeholder Tab Builders (Update with actual content)
  Widget _buildUsageTab(
    BuildContext context,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Text(
        widget.drug.usage.isNotEmpty
            ? widget.drug.usage
            : "لا توجد معلومات استخدام متاحة.",
        style: textTheme.bodyLarge,
      ),
    );
  }

  Widget _buildDosageTab(
    BuildContext context,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    final standardDosageInfo = widget.drug.usage; // Placeholder

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        Text(
          "الجرعة",
          style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Text(
          standardDosageInfo.isNotEmpty
              ? standardDosageInfo
              : "راجع الطبيب أو الصيدلي لتحديد الجرعة المناسبة.",
          style: textTheme.bodyLarge,
        ),
        const SizedBox(height: 24),
        const Divider(),
        const SizedBox(height: 16),
        Text(
          "حاسبة الجرعة بالوزن",
          style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          "احسب الجرعة المناسبة للأطفال.",
          style: textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          icon: Icon(LucideIcons.calculator, size: 18),
          label: const Text('فتح حاسبة الجرعات'),
          onPressed: () {
            /* Navigation logic */
          },
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildSideEffectsTab(
    BuildContext context,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    // TODO: Fetch and display side effects data
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Text(
        "لا توجد معلومات آثار جانبية متاحة حالياً.",
        style: textTheme.bodyLarge?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _buildContraindicationsTab(
    BuildContext context,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    // TODO: Fetch and display contraindications data
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Text(
        "لا توجد معلومات موانع استخدام متاحة حالياً.",
        style: textTheme.bodyLarge?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  // Alternatives Section (Moved below tabs)
  Widget _buildAlternativesSection(
    BuildContext context,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 24.0, 16.0, 16.0), // mt-6 mb-4
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "البدائل المتاحة",
            style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ), // text-lg font-bold
          const SizedBox(height: 16), // mb-4
          AlternativesTabContent(originalDrug: widget.drug),
        ],
      ),
    );
  }

  // Removed _buildAlternativesTab

  Widget _buildInteractionsTab(
    BuildContext context,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    _logger.d("DrugDetailsScreen: Building Interactions Tab");
    final knownInteractions = []; // Placeholder

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        Text(
          "التفاعلات المعروفة",
          style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        if (knownInteractions.isNotEmpty)
          const Text("...")
        else
          Text(
            "لا توجد معلومات تفاعلات مباشرة لهذا الدواء حالياً.",
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        const SizedBox(height: 24),
        const Divider(),
        const SizedBox(height: 16),
        Text(
          "مدقق التفاعلات المتعددة",
          style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          "أضف هذا الدواء وأدوية أخرى لفحص التفاعلات المحتملة بينها.",
          style: textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          icon: Icon(LucideIcons.zap, size: 18),
          label: const Text('فتح مدقق التفاعلات'),
          onPressed: () {
            _logger.i(
              "DrugDetailsScreen: Navigate to InteractionChecker tapped.",
            );
            context.read<InteractionProvider>().addMedicine(widget.drug);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const InteractionCheckerScreen(),
              ),
            );
          },
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      ],
    );
  }
}
