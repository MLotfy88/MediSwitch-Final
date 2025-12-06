import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../theme/app_colors.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../widgets/home/drug_card.dart';

// Assuming DrugUIModel is shared or redefined here.
// Ideally should be in a shared models directory.
// For now, reusing the one defined in drug_card.dart or redefining simpler version for this screen.

class DrugDetailsScreen extends StatefulWidget {
  final VoidCallback? onBack;

  const DrugDetailsScreen({Key? key, this.onBack}) : super(key: key);

  @override
  State<DrugDetailsScreen> createState() => _DrugDetailsScreenState();
}

class _DrugDetailsScreenState extends State<DrugDetailsScreen> {
  String activeTab = 'info';
  bool isFavorite = false;

  // Mock Data
  final mockDrug = DrugUIModel(
    id: '1',
    tradeNameEn: 'Augmentin 1g',
    tradeNameAr: 'اوجمنتين ١ جرام',
    activeIngredient: 'Amoxicillin 875mg + Clavulanic Acid 125mg',
    form: 'tablet',
    currentPrice: 185.00,
    oldPrice: 195.00,
    company: 'GlaxoSmithKline (GSK)',
    isPopular: true,
  );

  final String registrationNumber = 'EGY-2024-00123';
  final String description =
      'Augmentin is a combination antibiotic used to treat a wide variety of bacterial infections. It works by stopping the growth of bacteria.';

  final mockDosage = {
    'strength': '1000mg (875mg + 125mg)',
    'standardDose': '1 Tablet every 12 hours',
    'instructions':
        'Take at the start of a meal to reduce GI side effects. Complete the full course even if symptoms improve.',
    'maxDaily': '2 tablets (2000mg)',
  };

  final List<DrugUIModel> mockAlternatives = [
    DrugUIModel(
      id: 'alt1',
      tradeNameEn: 'Hibiotic 1g',
      tradeNameAr: 'هايبيوتك',
      activeIngredient: 'Amoxicillin + Clavulanic Acid',
      form: 'tablet',
      currentPrice: 145.00,
      company: 'Amoun Pharma',
    ),
    DrugUIModel(
      id: 'alt2',
      tradeNameEn: 'Megamox 1g',
      tradeNameAr: 'ميجاموكس',
      activeIngredient: 'Amoxicillin + Clavulanic Acid',
      form: 'tablet',
      currentPrice: 160.00,
      oldPrice: 175.00,
      company: 'Pharco',
    ),
  ];

  final mockInteractions = [
    {
      'id': '1',
      'name': 'Warfarin',
      'severity': 'major',
      'description': 'Increased risk of bleeding',
    },
    {
      'id': '2',
      'name': 'Methotrexate',
      'severity': 'major',
      'description': 'Increased methotrexate toxicity',
    },
    {
      'id': '3',
      'name': 'Oral Contraceptives',
      'severity': 'moderate',
      'description': 'May reduce contraceptive efficacy',
    },
    {
      'id': '4',
      'name': 'Probenecid',
      'severity': 'minor',
      'description': 'Increased amoxicillin levels',
    },
  ];

  final mockPriceHistory = [
    {'date': 'Nov 2024', 'price': 195.00},
    {'date': 'Oct 2024', 'price': 195.00},
    {'date': 'Sep 2024', 'price': 180.00},
    {'date': 'Aug 2024', 'price': 175.00},
    {'date': 'Jul 2024', 'price': 175.00},
    {'date': 'Jun 2024', 'price': 165.00},
  ];

  @override
  Widget build(BuildContext context) {
    final isRTL = Directionality.of(context) == TextDirection.rtl;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n =
        AppLocalizations.of(
          context,
        )!; // Assumes AppLocalizations is available in context

    final tabs = [
      {'id': 'info', 'label': l10n.infoTab, 'icon': LucideIcons.info},
      {'id': 'dosage', 'label': l10n.dosageTab, 'icon': LucideIcons.droplets},
      {
        'id': 'alternatives',
        'label': l10n.alternativesTab,
        'icon': LucideIcons.gitCompare,
      },
      {
        'id': 'interactions',
        'label': l10n.interactionsTab,
        'icon': LucideIcons.alertTriangle,
      },
      {'id': 'price', 'label': l10n.priceTab, 'icon': LucideIcons.trendingDown},
    ];

    return Scaffold(
      backgroundColor: colorScheme.background,
      body: Column(
        children: [
          _buildHeader(context, isRTL, colorScheme),
          _buildTabs(tabs, colorScheme),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: _buildTabContent(isRTL, colorScheme, l10n),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    bool isRTL,
    ColorScheme colorScheme,
  ) {
    double priceChange = 0;
    if (mockDrug.oldPrice != null) {
      priceChange =
          ((mockDrug.currentPrice - mockDrug.oldPrice!) / mockDrug.oldPrice!) *
          100;
    }

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.primary, // Use theme primary
        // Optional: Add gradient if desired, but solid primary is safer for dark/light adaptation unless we define gradients in theme
        // gradient: LinearGradient(...)
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed:
                        widget.onBack ?? () => Navigator.of(context).pop(),
                    icon: Icon(
                      LucideIcons.arrowLeft,
                      color: colorScheme.onPrimary,
                    ),
                    style: IconButton.styleFrom(
                      backgroundColor: colorScheme.onPrimary.withOpacity(0.1),
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        onPressed: () {},
                        icon: Icon(
                          LucideIcons.share2,
                          color: colorScheme.onPrimary,
                        ),
                        style: IconButton.styleFrom(
                          backgroundColor: colorScheme.onPrimary.withOpacity(
                            0.1,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed:
                            () => setState(() => isFavorite = !isFavorite),
                        icon: Icon(
                          LucideIcons.heart,
                          color:
                              isFavorite
                                  ? AppColors.danger
                                  : colorScheme.onPrimary,
                        ),
                        style: IconButton.styleFrom(
                          backgroundColor:
                              isFavorite
                                  ? colorScheme.surface
                                  : colorScheme.onPrimary.withOpacity(0.1),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: colorScheme.onPrimary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          LucideIcons.pill,
                          color: colorScheme.onPrimary,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    mockDrug.tradeNameEn,
                                    style: TextStyle(
                                      color: colorScheme.onPrimary,
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                if (mockDrug.isPopular)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                          colorScheme
                                              .surface, // Inverted for badge on primary
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(
                                        color: colorScheme.onPrimary,
                                      ),
                                    ),
                                    child: Text(
                                      'POPULAR',
                                      style: TextStyle(
                                        color: colorScheme.primary,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            Text(
                              mockDrug.tradeNameAr,
                              style: TextStyle(
                                color: colorScheme.onPrimary.withOpacity(0.8),
                                fontFamily: 'Cairo',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    mockDrug.company,
                    style: TextStyle(
                      color: colorScheme.onPrimary.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        '${mockDrug.currentPrice.toStringAsFixed(2)} EGP',
                        style: TextStyle(
                          color: colorScheme.onPrimary,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 12),
                      if (mockDrug.oldPrice != null)
                        Text(
                          mockDrug.oldPrice!.toStringAsFixed(2),
                          style: TextStyle(
                            color: colorScheme.onPrimary.withOpacity(0.6),
                            decoration: TextDecoration.lineThrough,
                            fontSize: 18,
                          ),
                        ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.success.withOpacity(
                            0.2,
                          ), // Keep semantic colors or add to theme
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              LucideIcons.trendingDown,
                              color: AppColors.successSoft,
                              size: 12,
                            ),
                            Text(
                              '${priceChange.abs().toStringAsFixed(0)}%',
                              style: const TextStyle(
                                color: AppColors.successSoft,
                                fontSize: 12,
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
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabs(List<Map<String, dynamic>> tabs, ColorScheme colorScheme) {
    return Container(
      color: colorScheme.surface,
      width: double.infinity,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          children:
              tabs.map((tab) {
                final isActive = activeTab == tab['id'];
                return GestureDetector(
                  onTap: () => setState(() => activeTab = tab['id'] as String),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color:
                              isActive
                                  ? colorScheme.primary
                                  : Colors.transparent,
                          width: 2,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          tab['icon'] as IconData,
                          size: 16,
                          color:
                              isActive
                                  ? colorScheme.primary
                                  : colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          tab['label'] as String,
                          style: TextStyle(
                            color:
                                isActive
                                    ? colorScheme.primary
                                    : colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
        ),
      ),
    );
  }

  Widget _buildTabContent(
    bool isRTL,
    ColorScheme colorScheme,
    AppLocalizations l10n,
  ) {
    switch (activeTab) {
      case 'info':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCard(
              title: l10n.descriptionTitle,
              colorScheme: colorScheme,
              child: Text(
                description,
                style: TextStyle(
                  height: 1.5,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildCard(
              title: l10n.infoTab, // Reusing generic title
              colorScheme: colorScheme,
              child: Column(
                children: [
                  _buildDetailRow(
                    LucideIcons.hash,
                    "Registration Number",
                    registrationNumber,
                    colorScheme,
                  ), // Needs generic label
                  _buildDetailRow(
                    LucideIcons.flaskConical,
                    "Active Ingredient",
                    mockDrug.activeIngredient,
                    colorScheme,
                  ),
                  _buildDetailRow(
                    LucideIcons.building,
                    l10n.companyLabel.replaceAll(':', ''),
                    mockDrug.company,
                    colorScheme,
                  ),
                  _buildDetailRow(
                    LucideIcons.tablets,
                    l10n.formLabel.replaceAll(':', ''),
                    mockDrug.form,
                    colorScheme,
                  ),
                ],
              ),
            ),
          ],
        ).animate().fadeIn();

      case 'dosage':
        return Column(
          children: [
            _buildCard(
              title: l10n.dosageTitle,
              colorScheme: colorScheme,
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          LucideIcons.pill,
                          color: colorScheme.primary,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              mockDosage['strength'] as String,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: colorScheme.onSurface,
                              ),
                            ),
                            Text(
                              "Strength",
                              style: TextStyle(
                                color: colorScheme.onSurfaceVariant,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Divider(),
                  ),
                  _buildDosageRow(
                    LucideIcons.clock,
                    "Standard Dose",
                    mockDosage['standardDose'] as String,
                    colorScheme,
                  ),
                  const SizedBox(height: 12),
                  _buildDosageRow(
                    LucideIcons.info,
                    "Maximum Daily Dose",
                    mockDosage['maxDaily'] as String,
                    colorScheme,
                  ),
                ],
              ),
            ),
          ],
        ).animate().fadeIn();

      case 'alternatives':
        return Column(
          children: [
            if (mockAlternatives.isEmpty)
              Center(
                child: Text(
                  l10n.noAlternativesFound,
                  style: TextStyle(color: colorScheme.onSurfaceVariant),
                ),
              )
            else
              ...mockAlternatives.map(
                (d) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: DrugCard(drug: d, isRTL: isRTL),
                ),
              ),
          ],
        ).animate().fadeIn();

      case 'interactions':
        return Column(
          children:
              mockInteractions.map((i) {
                final severity = i['severity'] as String;
                Color color = AppColors.info; // Default
                if (severity == 'major') color = AppColors.danger;
                if (severity == 'moderate') color = AppColors.warning;

                // Adjust color for dark mode if needed, or stick to semantic colors which stand out on dark too.
                // Usually semantic colors (Red, Orange, Blue) are fine on dark.

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: color.withOpacity(0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            i['name'] as String,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              severity.toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        i['description'] as String,
                        style: TextStyle(
                          color: colorScheme.onSurfaceVariant,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
        ).animate().fadeIn();

      case 'price':
        return _buildCard(
          title: l10n.priceTab,
          colorScheme: colorScheme,
          child: Column(
            children:
                mockPriceHistory.map((item) {
                  final price = item['price'] as double;
                  final date = item['date'] as String;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          date,
                          style: TextStyle(color: colorScheme.onSurfaceVariant),
                        ),
                        Text(
                          '${price.toStringAsFixed(2)} EGP',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
          ),
        ).animate().fadeIn();

      default:
        return Container();
    }
  }

  Widget _buildCard({
    required String title,
    required Widget child,
    required ColorScheme colorScheme,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface, // Was AppColors.card
        borderRadius: BorderRadius.circular(16),
        boxShadow:
            AppColors
                .shadowCard, // Shadows might need adjustment for dark mode, but usually opacity handles it.
        border: Border.all(color: colorScheme.outline.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    IconData icon,
    String label,
    String value,
    ColorScheme colorScheme,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: colorScheme.surfaceVariant, // Was AppColors.accent
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: colorScheme.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDosageRow(
    IconData icon,
    String label,
    String value,
    ColorScheme colorScheme,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: colorScheme.onSurfaceVariant),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
