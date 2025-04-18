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
import '../../core/constants/app_spacing.dart'; // Import spacing constants

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

  bool _isFavorite = false; // Placeholder for favorite state

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
      // Handle different potential date formats from source
      if (dateString.contains('/')) {
        dateTime = DateFormat('dd/MM/yyyy').parseStrict(dateString);
      } else {
        dateTime = DateFormat('yyyy-MM-dd').parseStrict(dateString);
      }
      // Format using Arabic locale for display
      return DateFormat('d MMM yyyy', 'ar').format(dateTime);
    } catch (e) {
      _logger.w("Could not parse date for display: $dateString", e);
      return dateString; // Return original string if parsing fails
    }
  }

  void _toggleFavorite() {
    _logger.i(
      "DrugDetailsScreen: Favorite button tapped (Premium - Not implemented).",
    );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('ميزة المفضلة تتطلب الاشتراك Premium (قريباً).'),
        duration: Duration(seconds: 2),
      ),
    );
    // setState(() {
    //   _isFavorite = !_isFavorite;
    // });
    // TODO: Implement actual favorite logic (e.g., save to local storage/backend)
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
        // Inherits styling from main theme
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, size: 20),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: 'رجوع',
        ),
        title: Text(
          'تفاصيل الدواء',
          // Style inherited from main theme's appBarTheme.titleTextStyle
        ),
        centerTitle: false, // Align title left (standard practice)
        // Bottom border inherited from main theme's appBarTheme
      ),
      // Wrap the body content with SafeArea
      body: SafeArea(
        child: ListView(
          // Use ListView for the main layout
          padding: EdgeInsets.zero, // Remove default ListView padding
          children: [
            _buildHeaderContent(context, colorScheme, textTheme),
            _buildActionButtons(context, colorScheme, textTheme),
            AppSpacing.gapVMedium, // Add space before TabBar
            _buildTabBar(context, colorScheme, textTheme),
            // Use a Container with fixed height for TabBarView content
            Container(
              // Adjust height based on expected content size or screen percentage
              height:
                  MediaQuery.of(context).size.height * 0.35, // Example height
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
            AppSpacing.gapVLarge, // Add padding at the very bottom
          ],
        ),
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
        isPriceChanged && oldPriceValue != null && oldPriceValue != 0
            ? ((currentPriceValue! - oldPriceValue) / oldPriceValue * 100).abs()
            : 0;

    return Padding(
      padding: AppSpacing.edgeInsetsAllLarge, // Use constant (16px)
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
                  borderRadius: BorderRadius.circular(
                    AppSpacing.small,
                  ), // Use constant (8px)
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(
                    AppSpacing.small,
                  ), // Use constant (8px)
                  child:
                      widget.drug.imageUrl != null &&
                              widget.drug.imageUrl!.isNotEmpty
                          ? CachedNetworkImage(
                            imageUrl: widget.drug.imageUrl!,
                            fit:
                                BoxFit
                                    .contain, // Use contain to avoid distortion
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
                            // Fallback icon
                            child: Icon(
                              LucideIcons.pill,
                              size: 30,
                              color: colorScheme.onSecondaryContainer
                                  .withOpacity(0.5),
                            ),
                          ),
                ),
              ),
              AppSpacing.gapHLarge, // Use constant (16px)
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
                        padding:
                            AppSpacing.edgeInsetsVXSmall, // Use constant (4px)
                        child: Text(
                          widget.drug.active,
                          style: textTheme.bodyMedium?.copyWith(
                            color:
                                colorScheme
                                    .primary, // Highlight active ingredient
                          ), // text-sm text-primary
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          AppSpacing.gapVLarge, // Use constant (16px)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment:
                CrossAxisAlignment.end, // Align price and favorite icon
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
                          // Approx 6px start padding
                          padding: const EdgeInsetsDirectional.only(
                            start: AppSpacing.small - AppSpacing.xxsmall,
                          ),
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
                              horizontal: AppSpacing.xsmall, // 4px
                              vertical: 1.0, // 1px
                            ),
                          ),
                        ),
                    ],
                  ),
                  if (oldPriceValue != null)
                    Padding(
                      padding: const EdgeInsets.only(
                        top: AppSpacing.xxsmall,
                      ), // 2px
                      child: Text(
                        '${_formatPrice(widget.drug.oldPrice!)} ج.م',
                        style: textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant, // Muted color
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                    ),
                ],
              ),
              IconButton(
                icon: Icon(
                  _isFavorite ? Icons.favorite : Icons.favorite_border,
                  color:
                      _isFavorite ? Colors.red.shade500 : colorScheme.outline,
                  size: 24, // h-6 w-6
                ),
                tooltip: 'إضافة للمفضلة (Premium)',
                onPressed: _toggleFavorite,
                padding: EdgeInsets.zero, // Remove default padding
                constraints: const BoxConstraints(), // Allow tight constraints
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
      // Consistent horizontal padding, bottom padding added
      padding: const EdgeInsets.only(
        left: AppSpacing.large,
        right: AppSpacing.large,
        bottom: AppSpacing.large,
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              icon: const Icon(LucideIcons.calculator, size: 16), // h-4 w-4
              label: const Text('حساب الجرعة'),
              onPressed: () {
                _logger.i("DrugDetailsScreen: Dose Calculator button tapped.");
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
              // Style inherited from main theme
            ),
          ),
          AppSpacing.gapHSmall, // Use constant (8px)
          Expanded(
            child: OutlinedButton.icon(
              icon: const Icon(LucideIcons.zap, size: 16), // h-4 w-4
              label: const Text('التفاعلات الدوائية'),
              onPressed: () {
                _logger.i(
                  "DrugDetailsScreen: Interaction Checker button tapped (Deferred for MVP).",
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('ميزة مدقق التفاعلات قيد التطوير (قريباً).'),
                    duration: Duration(seconds: 2),
                  ),
                );
                // context.read<InteractionProvider>().addMedicine(widget.drug);
                // Navigator.push(
                //   context,
                //   MaterialPageRoute(
                //     builder: (context) => const InteractionCheckerScreen(),
                //   ),
                // );
              },
              style: OutlinedButton.styleFrom(
                // Keep dimmed style for deferred feature
                foregroundColor: colorScheme.onSurfaceVariant.withOpacity(0.6),
                side: BorderSide(color: colorScheme.outline.withOpacity(0.6)),
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
      margin: AppSpacing.edgeInsetsHLarge, // Use constant (16px)
      padding: AppSpacing.edgeInsetsAllXSmall, // Use constant (4px)
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant, // bg-muted
        borderRadius: BorderRadius.circular(
          AppSpacing.small,
        ), // Use constant (8px)
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: colorScheme.primary,
        unselectedLabelColor: colorScheme.onSurfaceVariant,
        labelStyle: textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w600,
        ), // Use theme style
        unselectedLabelStyle: textTheme.labelLarge, // Use theme style
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(
            AppSpacing.small - AppSpacing.xxsmall,
          ), // 6px
          color: colorScheme.background, // Use background for contrast
          boxShadow: [
            // Subtle shadow from reference
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        indicatorSize: TabBarIndicatorSize.tab, // Make indicator fill tab
        tabs: const [
          Tab(text: 'معلومات'), // Shortened labels if needed
          Tab(text: 'استخدام'),
          Tab(text: 'جرعات'),
          Tab(text: 'آثار'),
          Tab(text: 'موانع'),
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
      if (widget.drug.concentration > 0 || widget.drug.unit.isNotEmpty)
        {
          'icon': LucideIcons.ruler,
          'label': "التركيز:",
          'value':
              '${widget.drug.concentration.toStringAsFixed(widget.drug.concentration.truncateToDouble() == widget.drug.concentration ? 0 : 1)} ${widget.drug.unit}'
                  .trim(),
        },
      if (widget.drug.lastPriceUpdate.isNotEmpty)
        {
          'icon': LucideIcons.calendarClock,
          'label': "آخر تحديث:",
          'value': _formatDate(widget.drug.lastPriceUpdate),
        },
      // {'icon': LucideIcons.box, 'label': "حجم العبوة:", 'value': '-'}, // Placeholder
    ];

    // Use SingleChildScrollView + Column for simpler layout if GridView causes issues
    return SingleChildScrollView(
      padding: AppSpacing.edgeInsetsAllLarge, // Use constant (16px)
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, // grid-cols-2
          childAspectRatio: 3.0, // Adjust aspect ratio as needed
          crossAxisSpacing: AppSpacing.large, // Use constant (16px)
          mainAxisSpacing: AppSpacing.large, // Use constant (16px)
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

  // Helper to build grid item for info tab
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
      padding: AppSpacing.edgeInsetsAllMedium, // Use constant (12px)
      decoration: BoxDecoration(
        color: colorScheme.surface, // bg-card
        borderRadius: BorderRadius.circular(
          AppSpacing.small,
        ), // Use constant (8px)
        border: Border.all(color: colorScheme.outline), // border border-border
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment:
            MainAxisAlignment.center, // Center content vertically
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 16,
                color: colorScheme.onSurfaceVariant,
              ), // h-4 w-4 text-muted-foreground
              // Approx 6px width
              const SizedBox(width: AppSpacing.small - AppSpacing.xxsmall),
              Text(
                label,
                style: textTheme.labelMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ), // font-medium text-muted-foreground
              ),
            ],
          ),
          AppSpacing.gapVXSmall, // Use constant (4px)
          Padding(
            // Indent value text (16px icon + 6px gap = 22px)
            padding: const EdgeInsetsDirectional.only(
              start: AppSpacing.large + AppSpacing.small - AppSpacing.xxsmall,
            ),
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
    return SingleChildScrollView(
      // Ensure content is scrollable
      padding: AppSpacing.edgeInsetsAllLarge, // Use constant (16px)
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
    final standardDosageInfo =
        widget.drug.usage; // Placeholder - Needs specific dosage field

    return ListView(
      // Use ListView for potentially longer content
      padding: AppSpacing.edgeInsetsAllLarge, // Use constant (16px)
      children: [
        Text(
          "الجرعة",
          style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        AppSpacing.gapVMedium, // Use constant (12px)
        Text(
          standardDosageInfo
                  .isNotEmpty // Replace with actual dosage field check
              ? standardDosageInfo
              : "راجع الطبيب أو الصيدلي لتحديد الجرعة المناسبة.",
          style: textTheme.bodyLarge,
        ),
        AppSpacing.gapVXLarge, // Use constant (24px)
        const Divider(),
        AppSpacing.gapVLarge, // Use constant (16px)
        Text(
          "حاسبة الجرعة بالوزن",
          style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        AppSpacing.gapVSmall, // Use constant (8px)
        Text(
          "احسب الجرعة المناسبة للأطفال.",
          style: textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        AppSpacing.gapVLarge, // Use constant (16px)
        ElevatedButton.icon(
          icon: const Icon(LucideIcons.calculator, size: 18),
          label: const Text('فتح حاسبة الجرعات'),
          onPressed: () {
            _logger.i("DrugDetailsScreen: Dose Calculator button tapped.");
            context.read<DoseCalculatorProvider>().setSelectedDrug(widget.drug);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const WeightCalculatorScreen(),
              ),
            );
          },
          style: ElevatedButton.styleFrom(
            padding: AppSpacing.edgeInsetsVMedium, // Use constant (12px)
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
    // TODO: Fetch and display side effects data from drug.description or specific field
    return SingleChildScrollView(
      // Ensure content is scrollable
      padding: AppSpacing.edgeInsetsAllLarge, // Use constant (16px)
      child: Text(
        widget
                .drug
                .description
                .isNotEmpty // Example: Use description field
            ? widget.drug.description
            : "لا توجد معلومات آثار جانبية متاحة حالياً.",
        style: textTheme.bodyLarge?.copyWith(
          color:
              widget.drug.description.isEmpty
                  ? colorScheme.onSurfaceVariant
                  : null,
        ),
      ),
    );
  }

  Widget _buildContraindicationsTab(
    BuildContext context,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    // TODO: Fetch and display contraindications data (might be in description or usage)
    return SingleChildScrollView(
      // Ensure content is scrollable
      padding: AppSpacing.edgeInsetsAllLarge, // Use constant (16px)
      child: Text(
        "لا توجد معلومات موانع استخدام متاحة حالياً.", // Placeholder
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
      // Use constants for padding (16px left/right, 24px top, 16px bottom)
      padding: const EdgeInsets.only(
        left: AppSpacing.large,
        top: AppSpacing.xlarge,
        right: AppSpacing.large,
        bottom: AppSpacing.large,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "البدائل المتاحة",
            style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ), // text-lg font-bold
          AppSpacing.gapVLarge, // Use constant (16px)
          AlternativesTabContent(
            originalDrug: widget.drug,
          ), // This widget handles its own state/content
        ],
      ),
    );
  }

  // Removed _buildAlternativesTab

  // Placeholder for Interactions Tab (if re-added)
  Widget _buildInteractionsTab(
    BuildContext context,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    _logger.d("DrugDetailsScreen: Building Interactions Tab");
    final knownInteractions = []; // Placeholder

    return ListView(
      padding: AppSpacing.edgeInsetsAllLarge, // Use constant (16px)
      children: [
        Text(
          "التفاعلات المعروفة",
          style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        AppSpacing.gapVMedium, // Use constant (12px)
        if (knownInteractions.isNotEmpty)
          const Text("...") // Placeholder for interaction list
        else
          Text(
            "لا توجد معلومات تفاعلات مباشرة لهذا الدواء حالياً.",
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        AppSpacing.gapVXLarge, // Use constant (24px)
        const Divider(),
        AppSpacing.gapVLarge, // Use constant (16px)
        Text(
          "مدقق التفاعلات المتعددة",
          style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        AppSpacing.gapVSmall, // Use constant (8px)
        Text(
          "أضف هذا الدواء وأدوية أخرى لفحص التفاعلات المحتملة بينها.",
          style: textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        AppSpacing.gapVLarge, // Use constant (16px)
        ElevatedButton.icon(
          icon: const Icon(LucideIcons.zap, size: 18),
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
            padding: AppSpacing.edgeInsetsVMedium, // Use constant (12px)
          ),
        ),
      ],
    );
  }
}
