import 'dart:ui' as ui; // Import dart:ui with alias
import 'package:dartz/dartz.dart' as dartz; // Import Either with prefix
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart'; // Import generated localizations
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/constants/app_constants.dart'; // Import constants for translation map
import '../../core/di/locator.dart';
import '../../core/error/failures.dart'; // Import Failure
import '../../core/services/file_logger_service.dart';
import '../../domain/entities/drug_entity.dart';
import '../../domain/entities/drug_interaction.dart'; // Import DrugInteraction
import '../../domain/repositories/interaction_repository.dart'; // Import InteractionRepository
import '../widgets/alternatives_tab_content.dart';
import '../widgets/interaction_card.dart'; // Import InteractionCard

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
    // Update tab count to 5 (Info, Alternatives, Dosage, Interactions, Price)
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
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: CustomScrollView(
        slivers: [
          // Hero Header with gradient and Pill icon
          _buildHeroHeader(context, colorScheme, textTheme, l10n, isDark),

          // Floating Drug Info Card
          _buildFloatingDrugCard(context, colorScheme, textTheme, l10n, isDark),

          // Interaction Alert Banner
          _buildInteractionAlert(context, colorScheme, textTheme, l10n),

          // Tabs Navigation
          _buildTabsNavigation(context, colorScheme, textTheme, l10n),

          // Tab Content
          SliverFillRemaining(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildInfoTab(context, colorScheme, textTheme, l10n),
                _buildAlternativesTab(context),
                _buildDosageTab(context, colorScheme, textTheme, l10n),
                _buildInteractionsTab(context, colorScheme, textTheme, l10n),
                _buildPriceTab(context, colorScheme, textTheme, l10n),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- Hero Header with Gradient Background ---
  Widget _buildHeroHeader(
    BuildContext context,
    ColorScheme colorScheme,
    TextTheme textTheme,
    AppLocalizations l10n,
    bool isDark,
  ) {
    return SliverAppBar(
      expandedHeight: 160,
      pinned: false,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors:
                  isDark
                      ? [
                        colorScheme.primary.withOpacity(0.8),
                        colorScheme.tertiary.withOpacity(0.6),
                      ]
                      : [colorScheme.primary, colorScheme.tertiary],
            ),
          ),
          child: Center(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(LucideIcons.pill, size: 48, color: Colors.white),
            ),
          ),
        ),
      ),
      leading: IconButton(
        icon: const Icon(LucideIcons.chevronRight, color: Colors.white),
        onPressed: () => Navigator.of(context).pop(),
      ),
      actions: [
        IconButton(
          icon: Icon(
            _isFavorite ? LucideIcons.heart : LucideIcons.heart,
            color: _isFavorite ? Colors.red : Colors.white,
          ),
          onPressed: _toggleFavorite,
        ),
        IconButton(
          icon: const Icon(LucideIcons.share2, color: Colors.white),
          onPressed: () {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('مشاركة قريباً')));
          },
        ),
      ],
    );
  }

  // --- Floating Drug Info Card ---
  Widget _buildFloatingDrugCard(
    BuildContext context,
    ColorScheme colorScheme,
    TextTheme textTheme,
    AppLocalizations l10n,
    bool isDark,
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

    final locale = Localizations.localeOf(context);
    final isArabic = locale.languageCode == 'ar';
    final displayName =
        (isArabic && widget.drug.arabicName.isNotEmpty)
            ? widget.drug.arabicName
            : widget.drug.tradeName;

    return SliverToBoxAdapter(
      child: Transform.translate(
        offset: const Offset(0, -24),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: colorScheme.shadow.withOpacity(isDark ? 0.3 : 0.1),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(
              color: colorScheme.outlineVariant.withOpacity(0.3),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                displayName,
                                style: textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (isPriceChanged && !isPriceIncreased)
                              Container(
                                margin: const EdgeInsetsDirectional.only(
                                  start: 8,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade100,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      LucideIcons.trendingDown,
                                      size: 12,
                                      color: Colors.green.shade800,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'سعر منخفض',
                                      style: TextStyle(
                                        color: Colors.green.shade800,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                        if (widget.drug.active.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              widget.drug.active,
                              style: textTheme.bodyLarge?.copyWith(
                                color: colorScheme.primary,
                                fontWeight: FontWeight.w500,
                              ),
                              textDirection: ui.TextDirection.ltr,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            '${_formatPrice(widget.drug.price)}',
                            style: textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              color:
                                  isPriceChanged
                                      ? (isPriceIncreased
                                          ? Colors.red.shade700
                                          : Colors.green.shade700)
                                      : colorScheme.primary,
                            ),
                            textDirection: ui.TextDirection.ltr,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'ج.م',
                            style: textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                      if (isPriceChanged && oldPriceValue != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            '${_formatPrice(widget.drug.oldPrice!)} ج.م',
                            style: textTheme.bodySmall?.copyWith(
                              decoration: TextDecoration.lineThrough,
                              color: colorScheme.onSurfaceVariant.withOpacity(
                                0.6,
                              ),
                            ),
                            textDirection: ui.TextDirection.ltr,
                          ),
                        ),
                    ],
                  ),
                  if (isPriceChanged && priceChangePercentage > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color:
                            isPriceIncreased
                                ? Colors.red.shade100
                                : Colors.green.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${isPriceIncreased ? '+' : '-'}${priceChangePercentage.toStringAsFixed(0)}%',
                        style: TextStyle(
                          color:
                              isPriceIncreased
                                  ? Colors.red.shade800
                                  : Colors.green.shade800,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Interaction Alert Banner ---
  Widget _buildInteractionAlert(
    BuildContext context,
    ColorScheme colorScheme,
    TextTheme textTheme,
    AppLocalizations l10n,
  ) {
    final bool hasInteractions = _interactionRepository.hasKnownInteractions(
      widget.drug,
    );

    if (!hasInteractions) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              // Switch to interactions tab
              _tabController.animateTo(3);
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber.shade200, width: 1),
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
                          'يوجد تفاعلات مسجلة لهذا الدواء',
                          style: textTheme.bodySmall?.copyWith(
                            color: Colors.amber.shade900,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    LucideIcons.chevronLeft,
                    size: 18,
                    color: Colors.amber.shade800,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- Tabs Navigation ---
  Widget _buildTabsNavigation(
    BuildContext context,
    ColorScheme colorScheme,
    TextTheme textTheme,
    AppLocalizations l10n,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: colorScheme.outlineVariant.withOpacity(0.3),
            ),
          ),
        ),
        child: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          labelColor: colorScheme.primary,
          unselectedLabelColor: colorScheme.onSurfaceVariant,
          labelStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
          unselectedLabelStyle: textTheme.labelLarge,
          indicator: UnderlineTabIndicator(
            borderSide: BorderSide(color: colorScheme.primary, width: 2),
          ),
          indicatorSize: TabBarIndicatorSize.label,
          tabs: [
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(LucideIcons.info, size: 16),
                  const SizedBox(width: 6),
                  const Text('المعلومات'),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(LucideIcons.replace, size: 16),
                  const SizedBox(width: 6),
                  const Text('البدائل'),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(LucideIcons.scale, size: 16),
                  const SizedBox(width: 6),
                  const Text('الجرعات'),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(LucideIcons.alertCircle, size: 16),
                  const SizedBox(width: 6),
                  const Text('التفاعلات'),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(LucideIcons.barChart2, size: 16),
                  const SizedBox(width: 6),
                  const Text('السعر'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Info Tab ---
  Widget _buildInfoTab(
    BuildContext context,
    ColorScheme colorScheme,
    TextTheme textTheme,
    AppLocalizations l10n,
  ) {
    final locale = Localizations.localeOf(context);
    final isArabic = locale.languageCode == 'ar';

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
              isArabic
                  ? (kCategoryTranslation[widget.drug.mainCategory] ??
                      widget.drug.mainCategory)
                  : widget.drug.mainCategory,
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
          'icon': LucideIcons.clock,
          'label': l10n.lastUpdateLabel,
          'value': _formatDate(widget.drug.lastPriceUpdate),
        },
    ];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Basic Info Grid
        if (infoItems.isNotEmpty) ...[
          _buildSectionTitle(context, 'المعلومات الأساسية'),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 2.8,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
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
          const SizedBox(height: 24),
        ],

        // Description
        if (widget.drug.description.trim().isNotEmpty) ...[
          _buildSectionTitle(context, 'الوصف'),
          const SizedBox(height: 12),
          _buildTextContent(context, widget.drug.description),
          const SizedBox(height: 24),
        ],
      ],
    );
  }

  // --- Dosage Tab ---
  Widget _buildDosageTab(
    BuildContext context,
    ColorScheme colorScheme,
    TextTheme textTheme,
    AppLocalizations l10n,
  ) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (widget.drug.usage.trim().isNotEmpty) ...[
          _buildSectionTitle(context, 'معلومات الجرعة'),
          const SizedBox(height: 12),
          _buildTextContent(context, widget.drug.usage),
        ] else ...[
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Icon(
                    LucideIcons.scale,
                    size: 48,
                    color: colorScheme.onSurfaceVariant.withOpacity(0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'لا توجد معلومات عن الجرعة متاحة',
                    style: textTheme.bodyLarge?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  // --- Interactions Tab ---
  Widget _buildInteractionsTab(
    BuildContext context,
    ColorScheme colorScheme,
    TextTheme textTheme,
    AppLocalizations l10n,
  ) {
    return FutureBuilder<dartz.Either<Failure, List<DrugInteraction>>>(
      future: _interactionRepository.findAllInteractionsForDrug(widget.drug),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        return snapshot.data!.fold(
          (Failure failure) => Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    LucideIcons.alertCircle,
                    size: 48,
                    color: colorScheme.error,
                  ),
                  const SizedBox(height: 16),
                  Text('فشل تحميل التفاعلات', style: textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text(
                    failure.message ?? 'حدث خطأ غير معروف',
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
          (List<DrugInteraction> interactions) {
            if (interactions.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        LucideIcons.check,
                        size: 48,
                        color: Colors.green.shade600,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'آمن',
                        style: textTheme.titleLarge?.copyWith(
                          color: Colors.green.shade700,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'لا توجد تفاعلات دوائية معروفة لهذا الدواء',
                        style: textTheme.bodyLarge?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: interactions.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                return InteractionCard(interaction: interactions[index]);
              },
            );
          },
        );
      },
    );
  }

  // --- Price Tab ---
  Widget _buildPriceTab(
    BuildContext context,
    ColorScheme colorScheme,
    TextTheme textTheme,
    AppLocalizations l10n,
  ) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              children: [
                Icon(
                  LucideIcons.barChart2,
                  size: 48,
                  color: colorScheme.onSurfaceVariant.withOpacity(0.3),
                ),
                const SizedBox(height: 16),
                Text(
                  'سجل الأسعار قريباً',
                  style: textTheme.titleLarge?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'سيتم عرض رسم بياني لتاريخ تطور السعر في التحديثات القادمة',
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant.withOpacity(0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Helper widgets
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
        color: Theme.of(context).colorScheme.surfaceContainerLow,
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
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outline.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withOpacity(0.5),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 16, color: colorScheme.primary),
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

  Widget _buildAlternativesTab(BuildContext context) {
    return AlternativesTabContent(originalDrug: widget.drug);
  }
}
