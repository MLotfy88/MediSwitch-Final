import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dart:ui' as ui; // Import dart:ui with alias
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
import 'package:flutter_gen/gen_l10n/app_localizations.dart'; // Import generated localizations
import '../../core/constants/app_constants.dart'; // Import constants for translation map

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
    // Use L.E. consistently
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
      // Format using current locale
      final locale = Localizations.localeOf(context).languageCode;
      return DateFormat('d MMM yyyy', locale).format(dateTime);
    } catch (e) {
      _logger.w("Could not parse date for display: $dateString", e);
      return dateString; // Return original string if parsing fails
    }
  }

  void _toggleFavorite() {
    _logger.i(
      "DrugDetailsScreen: Favorite button tapped (Premium - Not implemented).",
    );
    final l10n = AppLocalizations.of(context)!; // Get localizations instance
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.favoriteFeatureSnackbar), // Use localized string
        duration: const Duration(seconds: 2),
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
    final l10n = AppLocalizations.of(context)!; // Get localizations instance
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Scaffold(
      appBar: AppBar(
        // Inherits styling from main theme
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, size: 20),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: l10n.backTooltip, // Use localized string
        ),
        title: Text(
          l10n.drugDetailsTitle, // Use localized string
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
            _buildHeaderContent(
              context,
              colorScheme,
              textTheme,
              l10n,
            ), // Pass l10n
            _buildActionButtons(
              context,
              colorScheme,
              textTheme,
              l10n,
            ), // Pass l10n
            AppSpacing.gapVMedium, // Add space before TabBar
            _buildTabBar(context, colorScheme, textTheme, l10n), // Pass l10n
            // Use a Container with fixed height for TabBarView content
            Container(
              // Adjust height based on expected content size or screen percentage
              height:
                  MediaQuery.of(context).size.height * 0.35, // Example height
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildInfoTab(
                    context,
                    colorScheme,
                    textTheme,
                    l10n,
                  ), // Pass l10n
                  _buildUsageTab(
                    context,
                    colorScheme,
                    textTheme,
                    l10n,
                  ), // Pass l10n
                  _buildDosageTab(
                    context,
                    colorScheme,
                    textTheme,
                    l10n,
                  ), // Pass l10n
                  _buildSideEffectsTab(
                    context,
                    colorScheme,
                    textTheme,
                    l10n,
                  ), // Pass l10n
                  _buildContraindicationsTab(
                    context,
                    colorScheme,
                    textTheme,
                    l10n,
                  ), // Pass l10n
                ],
              ),
            ),
            _buildAlternativesSection(
              context,
              colorScheme,
              textTheme,
              l10n,
            ), // Pass l10n
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
    AppLocalizations l10n, // Add l10n parameter
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

    // Determine display name based on locale
    final locale = Localizations.localeOf(context);
    final isArabic = locale.languageCode == 'ar';
    final direction = Directionality.of(context); // Get text direction
    final displayName =
        (isArabic && widget.drug.arabicName.isNotEmpty)
            ? widget.drug.arabicName
            : widget.drug.tradeName;

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
                      displayName, // Use localized display name
                      style: textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ), // text-xl font-bold
                    ),
                    if (widget.drug.active.isNotEmpty)
                      Padding(
                        padding:
                            AppSpacing.edgeInsetsVXSmall, // Use constant (4px)
                        child: Text(
                          widget
                              .drug
                              .active, // Active ingredient always English
                          style: textTheme.bodyMedium?.copyWith(
                            color:
                                colorScheme
                                    .primary, // Highlight active ingredient
                          ), // text-sm text-primary
                          textDirection:
                              ui.TextDirection.ltr, // Ensure LTR using alias
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
                // Align based on text direction
                crossAxisAlignment:
                    direction == ui.TextDirection.ltr
                        ? CrossAxisAlignment.start
                        : CrossAxisAlignment.end,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        '${_formatPrice(widget.drug.price)} ${l10n.currencySymbol}', // Use localized currency
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
                        '${_formatPrice(widget.drug.oldPrice!)} ${l10n.currencySymbol}', // Use localized currency
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
                tooltip: l10n.addToFavoritesTooltip, // Use localized string
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
    AppLocalizations l10n, // Add l10n parameter
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
              label: Text(l10n.doseCalculatorButton), // Use localized string
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
              label: Text(l10n.drugInteractionsButton), // Use localized string
              onPressed: () {
                _logger.i(
                  "DrugDetailsScreen: Interaction Checker button tapped (Deferred for MVP).",
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      l10n.interactionCheckerSnackbar,
                    ), // Use localized string
                    duration: const Duration(seconds: 2),
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
    AppLocalizations l10n, // Add l10n parameter
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
        tabs: [
          Tab(text: l10n.infoTab), // Use localized string
          Tab(text: l10n.usageTab), // Use localized string
          Tab(text: l10n.dosageTab), // Use localized string
          Tab(text: l10n.sideEffectsTab), // Use localized string
          Tab(text: l10n.contraindicationsTab), // Use localized string
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
    AppLocalizations l10n, // Add l10n parameter
  ) {
    _logger.d("DrugDetailsScreen: Building Info Tab using GridView");
    final infoItems = <Map<String, dynamic>>[
      if (widget.drug.company.isNotEmpty)
        {
          'icon': LucideIcons.building2,
          'label': l10n.companyLabel, // Use localized string
          'value': widget.drug.company,
        },
      if (widget.drug.mainCategory.isNotEmpty)
        {
          'icon': LucideIcons.folderOpen,
          'label': l10n.categoryLabel, // Use localized string
          'value':
              kCategoryTranslation[widget.drug.mainCategory] ??
              widget
                  .drug
                  .mainCategory, // Use translated category name, fallback to original
        },
      if (widget.drug.dosageForm.isNotEmpty)
        {
          'icon': LucideIcons.packageSearch,
          'label': l10n.formLabel, // Use localized string
          'value': widget.drug.dosageForm,
        },
      if (widget.drug.concentration > 0 || widget.drug.unit.isNotEmpty)
        {
          'icon': LucideIcons.ruler,
          'label': l10n.concentrationLabel, // Use localized string
          'value':
              '${widget.drug.concentration.toStringAsFixed(widget.drug.concentration.truncateToDouble() == widget.drug.concentration ? 0 : 1)} ${widget.drug.unit}'
                  .trim(),
        },
      if (widget.drug.lastPriceUpdate.isNotEmpty)
        {
          'icon': LucideIcons.calendarClock,
          'label': l10n.lastUpdateLabel, // Use localized string
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
    AppLocalizations l10n, // Add l10n parameter
  ) {
    return SingleChildScrollView(
      // Ensure content is scrollable
      padding: AppSpacing.edgeInsetsAllLarge, // Use constant (16px)
      child: Text(
        widget.drug.usage.isNotEmpty
            ? widget.drug.usage
            : l10n.noUsageInfo, // Use localized string
        style: textTheme.bodyLarge,
      ),
    );
  }

  Widget _buildDosageTab(
    BuildContext context,
    ColorScheme colorScheme,
    TextTheme textTheme,
    AppLocalizations l10n, // Add l10n parameter
  ) {
    final standardDosageInfo =
        widget.drug.usage; // Placeholder - Needs specific dosage field

    return ListView(
      // Use ListView for potentially longer content
      padding: AppSpacing.edgeInsetsAllLarge, // Use constant (16px)
      children: [
        Text(
          l10n.dosageTitle, // Use localized string
          style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        AppSpacing.gapVMedium, // Use constant (12px)
        Text(
          standardDosageInfo
                  .isNotEmpty // Replace with actual dosage field check
              ? standardDosageInfo
              : l10n.consultDoctorOrPharmacist, // Use localized string
          style: textTheme.bodyLarge,
        ),
        AppSpacing.gapVXLarge, // Use constant (24px)
        const Divider(),
        AppSpacing.gapVLarge, // Use constant (16px)
        Text(
          l10n.weightDosageCalculatorTitle, // Use localized string
          style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        AppSpacing.gapVSmall, // Use constant (8px)
        Text(
          l10n.weightDosageCalculatorSubtitle, // Use localized string
          style: textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        AppSpacing.gapVLarge, // Use constant (16px)
        ElevatedButton.icon(
          icon: const Icon(LucideIcons.calculator, size: 18),
          label: Text(l10n.openDoseCalculatorButton), // Use localized string
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
    AppLocalizations l10n, // Add l10n parameter
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
            : l10n.noSideEffectsInfo, // Use localized string
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
    AppLocalizations l10n, // Add l10n parameter
  ) {
    // TODO: Fetch and display contraindications data (might be in description or usage)
    return SingleChildScrollView(
      // Ensure content is scrollable
      padding: AppSpacing.edgeInsetsAllLarge, // Use constant (16px)
      child: Text(
        l10n.noContraindicationsInfo, // Use localized string
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
    AppLocalizations l10n, // Add l10n parameter
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
            l10n.availableAlternativesTitle, // Use localized string
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
    AppLocalizations l10n, // Add l10n parameter
  ) {
    _logger.d("DrugDetailsScreen: Building Interactions Tab");
    final knownInteractions = []; // Placeholder

    return ListView(
      padding: AppSpacing.edgeInsetsAllLarge, // Use constant (16px)
      children: [
        Text(
          l10n.knownInteractionsTitle, // Use localized string
          style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        AppSpacing.gapVMedium, // Use constant (12px)
        if (knownInteractions.isNotEmpty)
          const Text("...") // Placeholder for interaction list
        else
          Text(
            l10n.noDirectInteractionInfo, // Use localized string
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        AppSpacing.gapVXLarge, // Use constant (24px)
        const Divider(),
        AppSpacing.gapVLarge, // Use constant (16px)
        Text(
          l10n.multiInteractionCheckerTitle, // Use localized string
          style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        AppSpacing.gapVSmall, // Use constant (8px)
        Text(
          l10n.multiInteractionCheckerSubtitle, // Use localized string
          style: textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        AppSpacing.gapVLarge, // Use constant (16px)
        ElevatedButton.icon(
          icon: const Icon(LucideIcons.zap, size: 18),
          label: Text(
            l10n.openInteractionCheckerButton,
          ), // Use localized string
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
