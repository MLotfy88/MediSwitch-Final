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
// import '../bloc/interaction_provider.dart'; // InteractionProvider might not be needed directly here
import '../../domain/repositories/interaction_repository.dart'; // Import InteractionRepository
import '../../domain/entities/drug_interaction.dart'; // Import DrugInteraction
import '../widgets/interaction_card.dart'; // Import InteractionCard
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
  final InteractionRepository _interactionRepository =
      locator<InteractionRepository>(); // Inject InteractionRepository
  late TabController _tabController;
  bool _isLoadingInteractions = false; // State for loading interactions

  bool _isFavorite = false; // Placeholder for favorite state

  @override
  void initState() {
    super.initState();
    // Update tab count to 2 (Information, Alternatives)
    _tabController = TabController(length: 2, vsync: this);
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
    if (dateString == null || dateString.trim().isEmpty)
      return '-'; // Trim here too
    final trimmedDateString = dateString.trim(); // Trim the input string
    try {
      DateTime dateTime;
      // Handle different potential date formats from source
      if (trimmedDateString.contains('/')) {
        dateTime = DateFormat(
          'dd/MM/yyyy',
        ).parseStrict(trimmedDateString); // Use trimmed string
      } else {
        dateTime = DateFormat(
          'yyyy-MM-dd',
        ).parseStrict(trimmedDateString); // Use trimmed string
      }
      // Format using current locale
      final locale = Localizations.localeOf(context).languageCode;
      return DateFormat('d MMM yyyy', locale).format(dateTime);
    } catch (e) {
      _logger.w("Could not parse date for display: $trimmedDateString", e);
      return trimmedDateString; // Return trimmed string if parsing fails
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
        ),
        centerTitle: false, // Align title left (standard practice)
        actions: [
          IconButton(
            icon: Icon(
              _isFavorite ? Icons.favorite : Icons.favorite_border,
              color: _isFavorite ? Colors.red.shade500 : colorScheme.onSurface,
            ),
            onPressed: _toggleFavorite,
          ),
        ],
      ),
      // Wrap the body content with SafeArea
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              // Wrap Header
              child: _buildHeaderCard(context, colorScheme, textTheme, l10n),
            ),
            SliverToBoxAdapter(
              child: _buildActionButtons(context, l10n),
            ),
            SliverToBoxAdapter(
              // Wrap spacing
              child: AppSpacing.gapVMedium, // Add space before TabBar
            ),
            SliverToBoxAdapter(
              // Wrap TabBar
              child: _buildTabBar(context, colorScheme, textTheme, l10n),
            ),
            // Use SliverFillRemaining to allow TabBarView to expand
            SliverFillRemaining(
              child: TabBarView(
                controller: _tabController,
                // Keep physics NeverScrollableScrollPhysics if inner content handles scrolling
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  // Consolidated Information Tab
                  _buildConsolidatedInfoTab(
                    context,
                    colorScheme,
                    textTheme,
                    l10n,
                  ),
                  // Alternatives Tab
                  _buildAlternativesTab(context),
                ],
              ),
            ),
            SliverToBoxAdapter(
              // Wrap bottom padding
              child: AppSpacing.gapVLarge, // Add padding at the very bottom
            ),
          ],
        ),
      ),
    );
  }

  // --- NEW Header Card Design ---
  Widget _buildHeaderCard(
    BuildContext context,
    ColorScheme colorScheme,
    TextTheme textTheme,
    AppLocalizations l10n,
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
    final displayName =
        (isArabic && widget.drug.arabicName.isNotEmpty)
            ? widget.drug.arabicName
            : widget.drug.tradeName;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bool hasInteractions = _interactionRepository.hasKnownInteractions(widget.drug);

    return Container(
      margin: AppSpacing.edgeInsetsAllLarge,
      padding: AppSpacing.edgeInsetsAllLarge,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSpacing.medium),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.surface,
            isDark
                ? colorScheme.surfaceVariant.withOpacity(0.3)
                : colorScheme.surface,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(isDark ? 0.2 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: colorScheme.outline.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drug Name and Info
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                displayName,
                style: textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (widget.drug.active.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    widget.drug.active,
                    style: textTheme.bodyLarge?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                    textDirection: ui.TextDirection.ltr,
                  ),
                ),
              // Category and Dosage Form
              if (widget.drug.mainCategory.isNotEmpty || widget.drug.dosageForm.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (widget.drug.mainCategory.isNotEmpty)
                        CustomBadge(
                          label: isArabic
                              ? (kCategoryTranslation[widget.drug.mainCategory] ?? widget.drug.mainCategory)
                              : widget.drug.mainCategory,
                          backgroundColor: colorScheme.secondaryContainer,
                          textColor: colorScheme.onSecondaryContainer,
                        ),
                      if (widget.drug.dosageForm.isNotEmpty)
                        CustomBadge(
                          label: widget.drug.dosageForm,
                          backgroundColor: colorScheme.tertiaryContainer,
                          textColor: colorScheme.onTertiaryContainer,
                        ),
                    ],
                  ),
                ),
            ],
          ),
          
          // --- Interaction Warning Banner ---
          if (hasInteractions)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _showInteractionsDialog(context, l10n),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade500.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.amber.shade600.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          LucideIcons.alertTriangle,
                          color: Colors.amber.shade700,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'تنبيه تفاعلات دوائية',
                                style: textTheme.labelLarge?.copyWith(
                                  color: Colors.amber.shade800,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'يوجد تفاعلات مسجلة لهذا الدواء. اضغط للتفاصيل.',
                                style: textTheme.bodySmall?.copyWith(
                                  color: Colors.amber.shade900,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios,
                          size: 14,
                          color: Colors.amber.shade800,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          AppSpacing.gapVLarge,
          const Divider(height: 1),
          AppSpacing.gapVLarge,
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.priceLabel ?? 'Price', // Fallback if key missing
                    style: textTheme.labelMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        '${_formatPrice(widget.drug.price)} L.E',
                        style: textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: colorScheme.primary,
                        ),
                        textDirection: ui.TextDirection.ltr,
                      ),
                      if (isPriceChanged && oldPriceValue != null)
                        Padding(
                          padding: const EdgeInsetsDirectional.only(start: 8),
                          child: Text(
                            '${_formatPrice(widget.drug.oldPrice!)}',
                            style: textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                              decoration: TextDecoration.lineThrough,
                            ),
                            textDirection: ui.TextDirection.ltr,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              // Price Change Indicator
              if (isPriceChanged)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color:
                        isPriceIncreased
                            ? colorScheme.errorContainer.withOpacity(0.2)
                            : Colors.green.shade100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isPriceIncreased
                            ? LucideIcons.trendingUp
                            : LucideIcons.trendingDown,
                        size: 16,
                        color:
                            isPriceIncreased
                                ? colorScheme.error
                                : Colors.green.shade800,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${priceChangePercentage.toStringAsFixed(0)}%',
                        style: TextStyle(
                          color:
                              isPriceIncreased
                                  ? colorScheme.error
                                  : Colors.green.shade800,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // --- NEW Action Cards Grid ---
  Widget _buildActionButtons(BuildContext context, AppLocalizations l10n) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.large, vertical: AppSpacing.small),
      child: OutlinedButton.icon(
        onPressed: () {
          final l10n = AppLocalizations.of(context)!;
          _logger.i(
            "DrugDetailsScreen: Opening Weight Calculator for drug: ${widget.drug.tradeName}",
          );
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.calculatorComingSoon),
              duration: const Duration(seconds: 2),
            ),
          );
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const WeightCalculatorScreen(),
            ),
          );
        },
        icon: Icon(LucideIcons.calculator, size: 18),
        label: Text(l10n.doseCalculatorButton),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          side: BorderSide(color: colorScheme.primary.withOpacity(0.5)),
        ),
      ),
    );
  }



  // TabBar Section
  Widget _buildTabBar(
    BuildContext context,
    ColorScheme colorScheme,
    TextTheme textTheme,
    AppLocalizations l10n,
  ) {
    return Container(
      margin: AppSpacing.edgeInsetsHLarge,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant.withOpacity(0.5),
        borderRadius: BorderRadius.circular(AppSpacing.medium),
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: colorScheme.primary,
        unselectedLabelColor: colorScheme.onSurfaceVariant,
        labelStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
        unselectedLabelStyle: textTheme.labelLarge,
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(AppSpacing.small + 2),
          color: colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        tabs: [
          Tab(text: l10n.informationTab),
          Tab(text: l10n.alternativesTab),
        ],
      ),
    );
  }

  // --- Consolidated Information Tab Builder ---
  Widget _buildConsolidatedInfoTab(
    BuildContext context,
    ColorScheme colorScheme,
    TextTheme textTheme,
    AppLocalizations l10n,
  ) {
    _logger.d("DrugDetailsScreen: Building Info Tab using GridView");
    final infoItems = <Map<String, dynamic>>[
      if (widget.drug.company.isNotEmpty)
        {
          'icon': LucideIcons.building2,
          'label': l10n.companyLabel,
          'value': widget.drug.company,
        },
      if (widget.drug.mainCategory.isNotEmpty)
        {
          'icon': LucideIcons.folderOpen,
          'label': l10n.categoryLabel,
          'value':
              kCategoryTranslation[widget.drug.mainCategory] ??
              widget.drug.mainCategory,
        },
      if (widget.drug.dosageForm.isNotEmpty)
        {
          'icon': LucideIcons.packageSearch,
          'label': l10n.formLabel,
          'value': widget.drug.dosageForm,
        },
      if (widget.drug.concentration > 0 || widget.drug.unit.isNotEmpty)
        {
          'icon': LucideIcons.ruler,
          'label': l10n.concentrationLabel,
          'value':
              '${widget.drug.concentration.toStringAsFixed(widget.drug.concentration.truncateToDouble() == widget.drug.concentration ? 0 : 1)} ${widget.drug.unit}'
                  .trim(),
        },
      if (widget.drug.lastPriceUpdate.isNotEmpty)
        {
          'icon': LucideIcons.calendarClock,
          'label': l10n.lastUpdateLabel,
          'value': _formatDate(widget.drug.lastPriceUpdate),
        },
    ];

    final usageInfo = widget.drug.usage;

    return ListView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: AppSpacing.edgeInsetsAllLarge,
      children: [
        // Info Grid
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 2.8, // Adjusted for better fit
            crossAxisSpacing: AppSpacing.medium,
            mainAxisSpacing: AppSpacing.medium,
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
        // --- Usage Section ---
        if (usageInfo.trim().isNotEmpty) ...[
          AppSpacing.gapVXLarge,
          _buildSectionTitle(context, l10n.usageTab),
          AppSpacing.gapVMedium,
          _buildTextContent(context, usageInfo),
        ],
        // --- Description Section ---
        if (widget.drug.description.trim().isNotEmpty) ...[
          AppSpacing.gapVXLarge,
          _buildSectionTitle(context, l10n.descriptionTitle),
          AppSpacing.gapVMedium,
          _buildTextContent(context, widget.drug.description),
        ],
      ],
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.bold,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  Widget _buildTextContent(BuildContext context, String content) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
        ),
      ),
      child: Text(
        content,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.6),
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSpacing.small),
        border: Border.all(color: colorScheme.outline.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: colorScheme.surfaceVariant,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 16,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- Alternatives Tab Builder ---
  Widget _buildAlternativesTab(BuildContext context) {
    return AlternativesTabContent(originalDrug: widget.drug);
  }

  // --- Show Interactions Dialog ---
  Future<void> _showInteractionsDialog(
    BuildContext context,
    AppLocalizations l10n,
  ) async {
    setState(() => _isLoadingInteractions = true);
    _logger.i("Fetching interactions for drug: ${widget.drug.tradeName}");

    final result = await _interactionRepository.findAllInteractionsForDrug(
      widget.drug,
    );

    if (!mounted) return;

    setState(() => _isLoadingInteractions = false);

    result.fold(
      (failure) {
        _logger.e("Failed to fetch interactions: ${failure.message}");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "${l10n.errorFetchingInteractions}: ${failure.message}",
            ),
            backgroundColor: Colors.red,
          ),
        );
      },
      (List<DrugInteraction> interactions) {
        _logger.i(
          "Found ${interactions.length} interactions for ${widget.drug.tradeName}",
        );
        showDialog(
          context: context,
          builder: (BuildContext dialogContext) {
            return AlertDialog(
              title: Text(
                l10n.drugInteractionsDialogTitle(widget.drug.tradeName),
              ),
              content: SizedBox(
                width: double.maxFinite,
                child:
                    interactions.isEmpty
                        ? Center(child: Text(l10n.noInteractionsFound))
                        : ListView.separated(
                          shrinkWrap: true,
                          itemCount: interactions.length,
                          itemBuilder: (context, index) {
                            return InteractionCard(
                              interaction: interactions[index],
                            );
                          },
                          separatorBuilder:
                              (context, index) => const Divider(height: 1),
                        ),
              ),
              actions: <Widget>[
                TextButton(
                  child: Text(l10n.closeButton),
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                  },
                ),
              ],
              scrollable: true,
            );
          },
        );
      },
    );
  }
}
