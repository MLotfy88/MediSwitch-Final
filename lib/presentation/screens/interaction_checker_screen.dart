import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/di/locator.dart';
import '../../domain/entities/drug_entity.dart';
import '../../domain/entities/drug_interaction.dart';
import '../../domain/repositories/interaction_repository.dart';
import '../theme/app_colors.dart';
import '../widgets/drug_search_delegate.dart';
import '../widgets/interaction_card.dart';

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

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          _buildHeader(context, l10n, isRTL),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildSelectedDrugsCard(context, l10n, isRTL),
                const SizedBox(height: 16),
                if (_selectedDrugs.length >= 2) ...[
                  _buildResultsHeader(context, isRTL),
                  const SizedBox(height: 12),
                  if (_isLoading)
                    const Center(child: CircularProgressIndicator())
                  else if (_interactions.isEmpty)
                    _buildNoInteractionsCard(context, isRTL)
                  else
                    ..._interactions.map(
                      (i) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: InteractionCard(interaction: i),
                      ),
                    ),
                  const SizedBox(height: 16),
                ],
                _buildInfoNote(context, l10n, isRTL),
                const SizedBox(height: 80), // Bottom padding
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AppLocalizations l10n, bool isRTL) {
    return SliverAppBar(
      pinned: true,
      expandedHeight: 120, // Compact header as per docs style
      backgroundColor: AppColors.warning,
      leading: IconButton(
        icon: Icon(
          isRTL ? LucideIcons.arrowRight : LucideIcons.arrowLeft,
          color: AppColors.warningForeground,
        ),
        onPressed: () => Navigator.pop(context),
        style: IconButton.styleFrom(
          backgroundColor: Colors.white.withOpacity(0.1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFF59E0B),
                Color(0xFFD97706),
              ], // Warning gradient
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 60, 16, 16),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      LucideIcons.alertTriangle,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          l10n.navInteractions,
                          style: const TextStyle(
                            fontSize: 20, // text-lg -> 18-20
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
        ),
      ),
    );
  }

  Widget _buildSelectedDrugsCard(
    BuildContext context,
    AppLocalizations l10n,
    bool isRTL,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppColors.shadowCard,
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Icon(LucideIcons.pill, size: 16, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                isRTL ? 'الأدوية المحددة' : 'Selected Drugs',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: AppColors.foreground,
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.secondary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${_selectedDrugs.length}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.secondaryForeground,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Selected Drug Pills
          if (_selectedDrugs.isNotEmpty)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children:
                  _selectedDrugs
                      .map((drug) => _buildDrugChip(context, drug))
                      .toList(),
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                isRTL ? 'لم يتم تحديد أي أدوية بعد' : 'No drugs selected yet',
                style: const TextStyle(
                  color: AppColors.mutedForeground,
                  fontSize: 14,
                ),
              ),
            ),

          const SizedBox(height: 16),

          // Add Drug Button
          _buildAddDrugButton(context, l10n, isRTL),
        ],
      ),
    ).animate().fadeIn();
  }

  Widget _buildDrugChip(BuildContext context, DrugEntity drug) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(LucideIcons.pill, size: 14, color: AppColors.primary),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              drug.tradeName,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.primary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: () => _removeDrug(drug.id.toString()),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                LucideIcons.x,
                size: 10,
                color: AppColors.primary,
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
            color: AppColors.mutedForeground.withOpacity(0.3),
            width: 2,
            style:
                BorderStyle
                    .solid, // Should be dashed in pure CSS, simpler solid here or use package
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              LucideIcons.plus,
              size: 20,
              color: AppColors.mutedForeground,
            ),
            const SizedBox(width: 8),
            Text(
              isRTL ? 'إضافة دواء' : 'Add Drug',
              style: const TextStyle(
                color: AppColors.mutedForeground,
                fontWeight: FontWeight.w500,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsHeader(BuildContext context, bool isRTL) {
    return Row(
      children: [
        const Icon(
          LucideIcons.alertTriangle,
          size: 18,
          color: AppColors.warning,
        ),
        const SizedBox(width: 8),
        Text(
          isRTL ? 'نتائج التفاعلات' : 'Interaction Results',
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: AppColors.foreground,
          ),
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
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              LucideIcons.shieldCheck,
              color: AppColors.success,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isRTL ? 'لا توجد تفاعلات معروفة' : 'No Known Interactions',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: AppColors.success,
                  ),
                ),
                Text(
                  isRTL
                      ? 'الأدوية المحددة آمنة للاستخدام معًا'
                      : 'Selected drugs are safe to use together',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.success.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn();
  }

  Widget _buildInfoNote(
    BuildContext context,
    AppLocalizations l10n,
    bool isRTL,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.muted.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            LucideIcons.info,
            size: 20,
            color: AppColors.mutedForeground,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              isRTL
                  ? 'هذه المعلومات للإرشاد فقط. استشر طبيبك أو الصيدلي قبل إجراء أي تغييرات على أدويتك.'
                  : 'This information is for guidance only. Consult your doctor or pharmacist before making any changes to your medications.',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.mutedForeground,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
