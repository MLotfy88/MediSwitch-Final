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
    _tabController = TabController(length: 4, vsync: this);
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
      body: NestedScrollView(
        headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
          return <Widget>[
            SliverAppBar(
              expandedHeight: 250.0,
              floating: false,
              pinned: true,
              elevation: innerBoxIsScrolled ? 1 : 0,
              forceElevated: innerBoxIsScrolled,
              backgroundColor: theme.scaffoldBackgroundColor,
              foregroundColor: colorScheme.onBackground,
              title: Text(widget.drug.tradeName, style: textTheme.titleLarge),
              centerTitle: false,
              actions: [
                IconButton(
                  icon: Icon(
                    _isFavorite ? LucideIcons.star : LucideIcons.starOff,
                    color:
                        _isFavorite
                            ? Colors.amber.shade600
                            : colorScheme.outline,
                  ),
                  tooltip: 'إضافة للمفضلة (Premium)',
                  onPressed: _toggleFavorite,
                ),
                const SizedBox(width: 8),
              ],
              flexibleSpace: FlexibleSpaceBar(
                collapseMode: CollapseMode.pin,
                background: _buildHeaderContent(
                  context,
                  colorScheme,
                  textTheme,
                ),
              ),
              bottom: TabBar(
                controller: _tabController,
                labelColor: colorScheme.primary,
                unselectedLabelColor: colorScheme.onSurfaceVariant,
                indicatorColor: colorScheme.primary,
                isScrollable: false,
                tabs: const [
                  Tab(text: 'معلومات'),
                  Tab(text: 'البدائل'),
                  Tab(text: 'الجرعات'),
                  Tab(text: 'التفاعلات'),
                ],
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildInfoTab(context, colorScheme, textTheme),
            _buildAlternativesTab(context),
            _buildDosageTab(context, colorScheme, textTheme),
            _buildInteractionsTab(context, colorScheme, textTheme),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderContent(
    BuildContext context,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(
          top: kToolbarHeight + 8,
          left: 16,
          right: 16,
          bottom: kTextTabBarHeight + 16,
        ), // Adjusted bottom padding
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: colorScheme.secondaryContainer.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12.0),
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
                                  size: 40,
                                  color: colorScheme.onSecondaryContainer
                                      .withOpacity(0.5),
                                ),
                              ),
                        )
                        : Center(
                          child: Icon(
                            LucideIcons.pill,
                            size: 40,
                            color: colorScheme.onSecondaryContainer.withOpacity(
                              0.5,
                            ),
                          ),
                        ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 8),
                  Text(
                    widget.drug.tradeName,
                    style: textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (widget.drug.arabicName.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2.0),
                      child: Text(
                        widget.drug.arabicName,
                        style: textTheme.titleSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  const SizedBox(height: 6),
                  if (widget.drug.active.isNotEmpty)
                    Text(
                      widget.drug.active,
                      style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${_formatPrice(widget.drug.price)} ج.م',
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Tab Content Builders ---

  Widget _buildInfoTab(
    BuildContext context,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    _logger.d("DrugDetailsScreen: Building Info Tab");
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 20.0),
      children: [
        _buildInfoRow(
          textTheme,
          colorScheme,
          "الاسم التجاري:",
          widget.drug.tradeName,
        ),
        _buildInfoRow(
          textTheme,
          colorScheme,
          "الاسم العربي:",
          widget.drug.arabicName,
        ),
        _buildInfoRow(
          textTheme,
          colorScheme,
          "المادة الفعالة:",
          widget.drug.active,
        ),
        _buildInfoRow(
          textTheme,
          colorScheme,
          "السعر:",
          '${_formatPrice(widget.drug.price)} ج.م',
        ),
        _buildInfoRow(
          textTheme,
          colorScheme,
          "الفئة الرئيسية:",
          widget.drug.mainCategory,
        ),
        _buildInfoRow(textTheme, colorScheme, "الشركة:", widget.drug.company),
        _buildInfoRow(
          textTheme,
          colorScheme,
          "الشكل الصيدلي:",
          widget.drug.dosageForm,
        ),
        if (widget.drug.concentration != null || widget.drug.unit.isNotEmpty)
          _buildInfoRow(
            textTheme,
            colorScheme,
            "التركيز/الوحدة:",
            '${widget.drug.concentration?.toString() ?? ""} ${widget.drug.unit}'
                .trim(),
          ),
        _buildInfoRow(textTheme, colorScheme, "الاستخدام:", widget.drug.usage),
        _buildInfoRow(
          textTheme,
          colorScheme,
          "الوصف:",
          widget.drug.description,
        ),
        _buildInfoRow(
          textTheme,
          colorScheme,
          "آخر تحديث للسعر:",
          _formatDate(widget.drug.lastPriceUpdate),
        ),
      ],
    );
  }

  Widget _buildInfoRow(
    TextTheme textTheme,
    ColorScheme colorScheme,
    String label,
    String value,
  ) {
    if (value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              style: textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlternativesTab(BuildContext context) {
    _logger.d("DrugDetailsScreen: Building Alternatives Tab");
    return AlternativesTabContent(originalDrug: widget.drug);
  }

  Widget _buildDosageTab(
    BuildContext context,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    _logger.d("DrugDetailsScreen: Building Dosage Tab");
    final standardDosageInfo = widget.drug.usage;

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        Text(
          "الجرعة القياسية",
          style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        if (standardDosageInfo.isNotEmpty)
          Text(standardDosageInfo, style: textTheme.bodyLarge)
        else
          Text(
            "لا تتوفر معلومات الجرعة القياسية لهذا الدواء حالياً.",
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
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
          "احسب الجرعة المناسبة للأطفال بناءً على الوزن والعمر.",
          style: textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          icon: Icon(LucideIcons.calculator, size: 18),
          label: const Text('فتح حاسبة الجرعات'),
          onPressed: () {
            _logger.i(
              "DrugDetailsScreen: Navigate to WeightCalculator tapped.",
            );
            context.read<DoseCalculatorProvider>().setSelectedDrug(widget.drug);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const WeightCalculatorScreen(),
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

  Widget _buildInteractionsTab(
    BuildContext context,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    _logger.d("DrugDetailsScreen: Building Interactions Tab");
    // TODO: Fetch and display known interactions for this specific drug
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
          // TODO: Build list of known interactions here
          const Text("...")
        else
          Text(
            "لا تتوفر معلومات تفاعلات مباشرة لهذا الدواء حالياً.",
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
