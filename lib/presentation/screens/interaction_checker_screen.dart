import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/di/locator.dart';
import '../../domain/entities/drug_entity.dart';
import '../../domain/entities/drug_interaction.dart';
import '../../domain/repositories/interaction_repository.dart';
import '../theme/app_colors.dart';
import '../widgets/drug_search_delegate.dart';
import '../widgets/helpers/interaction_severity_helper.dart';

class InteractionCheckerScreen extends StatefulWidget {
  const InteractionCheckerScreen({super.key});

  @override
  State<InteractionCheckerScreen> createState() =>
      _InteractionCheckerScreenState();
}

class _InteractionCheckerScreenState extends State<InteractionCheckerScreen> {
  final InteractionRepository _interactionRepository =
      locator<InteractionRepository>();

  final List<DrugEntity> _selectedDrugs = [];
  List<DrugInteraction> _interactions = [];
  bool _isLoading = false;
  String? _errorMessage;
  bool _showSearch = false;

  @override
  void initState() {
    super.initState();
    _ensureInteractionDataLoaded();
  }

  Future<void> _ensureInteractionDataLoaded() async {
    final result = await _interactionRepository.loadInteractionData();
    result.fold((failure) {
      if (mounted) {
        setState(() {
          _errorMessage = "Failed to load interaction data: ${failure.message}";
        });
      }
    }, (_) => {});
  }

  void _addDrug(DrugEntity drug) {
    if (_selectedDrugs.any((d) => d.id == drug.id)) return;
    setState(() {
      _selectedDrugs.add(drug);
      _showSearch = false;
    });
    _checkInteractions();
  }

  void _removeDrug(String drugId) {
    setState(() {
      _selectedDrugs.removeWhere((d) => d.id.toString() == drugId);
    });
    _checkInteractions();
  }

  Future<void> _checkInteractions() async {
    if (_selectedDrugs.length < 2) {
      setState(() {
        _interactions = [];
        _errorMessage = null;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await _interactionRepository.findInteractionsForMedicines(
      _selectedDrugs,
    );

    if (mounted) {
      setState(() {
        result.fold(
          (failure) {
            _errorMessage = "Error: ${failure.message}";
            _interactions = [];
          },
          (interactions) {
            _interactions = interactions;
          },
        );
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isRTL = Directionality.of(context) == TextDirection.rtl;
    final theme = Theme.of(context);

    return Scaffold(
      body: Column(
        children: [
          // Gradient Header
          _buildHeader(context, l10n, isRTL),
          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Selected Drugs Card
                  _buildSelectedDrugsCard(context, l10n, isRTL),
                  const SizedBox(height: 16),

                  // Results
                  if (_selectedDrugs.length >= 2) ...[
                    _buildResultsSection(context, l10n, isRTL),
                    const SizedBox(height: 16),
                  ],

                  // Info Note
                  _buildInfoNote(context, l10n, isRTL),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AppLocalizations l10n, bool isRTL) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.warning.withOpacity(0.9), AppColors.warning],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Back Button
              Material(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  onTap: () => Navigator.pop(context),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Icon(
                      isRTL ? LucideIcons.arrowRight : LucideIcons.arrowLeft,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Icon
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  LucideIcons.alertTriangle,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              // Title
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.navInteractions,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      isRTL
                          ? 'أضف الأدوية للتحقق من التفاعلات'
                          : 'Add drugs to check for interactions',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedDrugsCard(
    BuildContext context,
    AppLocalizations l10n,
    bool isRTL,
  ) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: AppColors.shadowCard,
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(
                LucideIcons.pill,
                size: 16,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                isRTL ? 'الأدوية المحددة' : 'Selected Drugs',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${_selectedDrugs.length}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSecondaryContainer,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Selected Drug Pills
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ..._selectedDrugs.map((drug) => _buildDrugChip(context, drug)),
              if (_selectedDrugs.isEmpty)
                Text(
                  isRTL ? 'لم يتم تحديد أي أدوية بعد' : 'No drugs selected yet',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Add Drug Button / Search
          if (_showSearch)
            _buildSearchSection(context, l10n, isRTL)
          else
            _buildAddDrugButton(context, l10n, isRTL),
        ],
      ),
    );
  }

  Widget _buildDrugChip(BuildContext context, DrugEntity drug) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.pill, size: 14, color: theme.colorScheme.primary),
          const SizedBox(width: 6),
          Text(
            drug.tradeName,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: () => _removeDrug(drug.id.toString()),
            child: Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                LucideIcons.x,
                size: 12,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddDrugButton(
    BuildContext context,
    AppLocalizations l10n,
    bool isRTL,
  ) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: () async {
        final result = await showSearch<DrugEntity?>(
          context: context,
          delegate: DrugSearchDelegate(),
        );
        if (result != null) {
          _addDrug(result);
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(
            color: theme.colorScheme.outlineVariant,
            width: 2,
            style: BorderStyle.solid,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              LucideIcons.plus,
              size: 18,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 8),
            Text(
              isRTL ? 'إضافة دواء' : 'Add Drug',
              style: TextStyle(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchSection(
    BuildContext context,
    AppLocalizations l10n,
    bool isRTL,
  ) {
    // Simplified - use the search delegate directly
    return Column(
      children: [
        ElevatedButton(
          onPressed: () async {
            final result = await showSearch<DrugEntity?>(
              context: context,
              delegate: DrugSearchDelegate(),
            );
            if (result != null) {
              _addDrug(result);
            }
          },
          child: Text(isRTL ? 'ابحث عن دواء' : 'Search for a drug'),
        ),
        TextButton(
          onPressed: () => setState(() => _showSearch = false),
          child: Text(isRTL ? 'إلغاء' : 'Cancel'),
        ),
      ],
    );
  }

  Widget _buildResultsSection(
    BuildContext context,
    AppLocalizations l10n,
    bool isRTL,
  ) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              LucideIcons.alertTriangle,
              size: 16,
              color: AppColors.warning,
            ),
            const SizedBox(width: 8),
            Text(
              isRTL ? 'نتائج التفاعلات' : 'Interaction Results',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        if (_isLoading)
          const Center(child: CircularProgressIndicator())
        else if (_interactions.isEmpty)
          _buildNoInteractionsCard(context, isRTL)
        else
          ..._interactions.map(
            (i) => _buildInteractionResultCard(context, i, isRTL),
          ),
      ],
    );
  }

  Widget _buildNoInteractionsCard(BuildContext context, bool isRTL) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.successSoft,
        border: Border.all(color: AppColors.success.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              LucideIcons.shieldCheck,
              color: AppColors.success,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isRTL ? 'لا توجد تفاعلات معروفة' : 'No Known Interactions',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.success,
                  ),
                ),
                Text(
                  isRTL
                      ? 'الأدوية المحددة آمنة للاستخدام معًا'
                      : 'Selected drugs are safe to use together',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.success.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInteractionResultCard(
    BuildContext context,
    DrugInteraction interaction,
    bool isRTL,
  ) {
    final severityColor = InteractionSeverityHelper.getSeverityColor(
      interaction.severity,
    );
    final severityBg = InteractionSeverityHelper.getSeverityBackgroundColor(
      interaction.severity,
    );
    final severityIcon = InteractionSeverityHelper.getSeverityIcon(
      interaction.severity,
    );
    final severityLabel =
        isRTL
            ? InteractionSeverityHelper.getSeverityLabelAr(interaction.severity)
            : InteractionSeverityHelper.getSeverityLabelEn(
              interaction.severity,
            );

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: severityBg,
        border: Border.all(color: severityColor.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: severityBg,
              shape: BoxShape.circle,
            ),
            child: Icon(severityIcon, color: severityColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Drug Names + Badge
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${interaction.ingredient1} + ${interaction.ingredient2}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: severityColor,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        severityLabel,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Description
                Text(
                  isRTL && interaction.arabicEffect.isNotEmpty
                      ? interaction.arabicEffect
                      : interaction.effect,
                  style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
                // Recommendation
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.surface.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isRTL ? 'التوصية:' : 'Recommendation:',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isRTL && interaction.arabicRecommendation.isNotEmpty
                            ? interaction.arabicRecommendation
                            : interaction.recommendation,
                        style: TextStyle(
                          fontSize: 13,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoNote(
    BuildContext context,
    AppLocalizations l10n,
    bool isRTL,
  ) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            LucideIcons.info,
            size: 18,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              isRTL
                  ? 'هذه المعلومات للإرشاد فقط. استشر طبيبك أو الصيدلي قبل إجراء أي تغييرات على أدويتك.'
                  : 'This information is for guidance only. Consult your doctor or pharmacist before making any changes to your medications.',
              style: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
