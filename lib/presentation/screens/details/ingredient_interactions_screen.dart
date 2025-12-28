import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mediswitch/core/di/locator.dart';
import 'package:mediswitch/domain/entities/drug_entity.dart';
import 'package:mediswitch/domain/entities/drug_interaction.dart';
import 'package:mediswitch/domain/entities/high_risk_ingredient.dart';
import 'package:mediswitch/domain/entities/interaction_severity.dart';
import 'package:mediswitch/domain/repositories/interaction_repository.dart';
import 'package:mediswitch/presentation/theme/app_colors.dart';
import 'package:mediswitch/presentation/widgets/cards/interaction_card.dart';
import 'package:mediswitch/presentation/widgets/modern_search_bar.dart';

/// A screen that displays interactions for a specific ingredient or drug.
class IngredientInteractionsScreen extends StatefulWidget {
  /// The ingredient to filter by. If null, shows all high-risk interactions.
  final HighRiskIngredient? ingredient;

  /// Whether to show only food interactions.
  final bool onlyFood;

  /// Creates a screen to display drug interactions.
  const IngredientInteractionsScreen({
    super.key,
    this.ingredient,
    this.onlyFood = false,
  });

  @override
  State<IngredientInteractionsScreen> createState() =>
      _IngredientInteractionsScreenState();
}

class _IngredientInteractionsScreenState
    extends State<IngredientInteractionsScreen> {
  final InteractionRepository _interactionRepository =
      locator<InteractionRepository>();

  List<DrugInteraction> _allInteractions = []; // Full list for filtering
  List<DrugInteraction> _filteredInteractions = []; // Display list

  /// Whether data is currently being loaded
  bool _isLoading = true;

  /// Search query string
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadInteractions();
  }

  /// Loads interaction data from repository
  Future<void> _loadInteractions() async {
    try {
      List<DrugInteraction> specificList = [];

      if (widget.ingredient != null) {
        if (widget.onlyFood) {
          // --- FOOD ONLY ---
          try {
            // Create a temporary drug entity with the active ingredient name to lookup food interactions
            final tempDrug = DrugEntity(
              id: null,
              tradeName: '',
              arabicName: '',
              price: '0',
              // oldPrice: null,
              mainCategory: '',
              active:
                  widget.ingredient!.normalizedName ?? widget.ingredient!.name,
              company: '',
              dosageForm: '',
              concentration: '',
              unit: '',
              usage: '',
              description: '',
              lastPriceUpdate: '',
              pharmacology: '',
            );

            final foodInteractions = await _interactionRepository
                .getFoodInteractions(tempDrug);

            // Convert strings to DrugInteraction objects
            for (final foodDesc in foodInteractions) {
              specificList.add(
                DrugInteraction(
                  id: -1, // Dummy ID
                  ingredient1: widget.ingredient!.name,
                  ingredient2: 'Food / Diet',
                  severity: 'Major', // Assume significant if listed
                  effect: foodDesc,
                  source: 'Database', // or 'Food'
                  type: 'food',
                ),
              );
            }
          } on Exception catch (e) {
            debugPrint('Error loading food interactions: $e');
          }
        } else {
          // --- DRUG ONLY (High Risk) ---
          final repo = _interactionRepository;

          // DEBUG: Print what we're searching for
          final searchTerm =
              widget.ingredient!.normalizedName ?? widget.ingredient!.name;
          debugPrint('🔍 [IngredientInteractionsScreen] Ingredient Card Info:');
          debugPrint('   - Display Name: ${widget.ingredient!.name}');
          debugPrint(
            '   - Normalized Name: ${widget.ingredient!.normalizedName}',
          );
          debugPrint('   - Searching with: "$searchTerm"');

          specificList = await repo.getInteractionsWith(searchTerm);
        }
      } else {
        specificList = await _interactionRepository.getHighRiskInteractions();
      }

      // usage of severityEnum
      specificList.sort(
        (a, b) => _compareSeverity(b.severityEnum, a.severityEnum),
      );

      if (mounted) {
        setState(() {
          _allInteractions = specificList;
          _filteredInteractions = specificList;
          _isLoading = false;
        });
      }
    } on Exception catch (e) {
      debugPrint('Error loading interactions: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  int _compareSeverity(InteractionSeverity a, InteractionSeverity b) {
    return _getSeverityWeight(a).compareTo(_getSeverityWeight(b));
  }

  int _getSeverityWeight(InteractionSeverity severity) {
    switch (severity) {
      case InteractionSeverity.contraindicated:
        return 5;
      case InteractionSeverity.severe:
        return 4;
      case InteractionSeverity.major:
        return 3;
      case InteractionSeverity.moderate:
        return 2;
      case InteractionSeverity.minor:
        return 1;
      case InteractionSeverity.unknown:
        return 0;
    }
  }

  void _onSearch(String query) {
    final isRTL = Directionality.of(context) == TextDirection.rtl;
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredInteractions = List.from(_allInteractions);
      } else {
        final lowerQuery = query.toLowerCase();
        _filteredInteractions =
            _allInteractions.where((i) {
              final effect =
                  isRTL ? (i.arabicEffect ?? i.effect ?? '') : (i.effect ?? '');

              // Use normalizedName for comparison if available
              final searchKey =
                  widget.ingredient?.normalizedName?.toLowerCase() ??
                  widget.ingredient?.name.toLowerCase();

              final otherIngredient =
                  i.ingredient1.toLowerCase() == searchKey
                      ? i.ingredient2
                      : i.ingredient1;

              final isFoodInteraction = i.type == 'food';

              return otherIngredient.toLowerCase().contains(lowerQuery) ||
                  effect.toLowerCase().contains(lowerQuery) ||
                  (isFoodInteraction &&
                      (isRTL ? 'طعام' : 'food').toLowerCase().contains(
                        lowerQuery,
                      ));
            }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isRTL = Directionality.of(context) == TextDirection.rtl;
    final title =
        widget.onlyFood
            ? (isRTL ? 'تفاعلات الطعام' : 'Food Interactions')
            : (widget.ingredient?.displayName ??
                (isRTL ? 'التفاعلات الخطيرة' : 'High Risk Interactions'));

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 120,
            leading: IconButton(
              icon: Icon(
                isRTL ? LucideIcons.arrowRight : LucideIcons.arrowLeft,
                color: theme.colorScheme.onSurface,
              ),
              onPressed: () => Navigator.pop(context),
            ),
            backgroundColor: theme.scaffoldBackgroundColor,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(
                left: 16,
                right: 16,
                bottom: 16,
              ),
              centerTitle: true,
              title: Text(
                title,
                style: TextStyle(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppColors.danger.withValues(alpha: 0.1),
                      theme.scaffoldBackgroundColor,
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Search Bar (Only if showing ALL interactions)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: ModernSearchBar(
                hintText:
                    isRTL ? 'ابحث عن مادة فعالة...' : 'Search ingredient...',
                onChanged: _onSearch,
              ),
            ),
          ),

          if (_isLoading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_filteredInteractions.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.successSoft.withValues(alpha: 0.3),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        LucideIcons.checkCircle,
                        size: 48,
                        color: AppColors.success,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      isRTL
                          ? (_searchQuery.isNotEmpty
                              ? 'لا توجد نتائج'
                              : 'لا توجد تفاعلات مسجلة')
                          : (_searchQuery.isNotEmpty
                              ? 'No results found'
                              : 'No interactions found'),
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else ...[
            // 1. Primary Interactions (High Priority)
            if (_filteredInteractions.any((i) => i.isPrimaryIngredient))
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final primaryList =
                          _filteredInteractions
                              .where((i) => i.isPrimaryIngredient)
                              .toList();
                      if (index == 0) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _InteractionSectionHeader(
                            title:
                                isRTL
                                    ? 'تفاعلات مباشرة'
                                    : 'Direct Interactions',
                            subtitle:
                                isRTL
                                    ? '${widget.ingredient?.name ?? 'المادة'} كمكون أساسي'
                                    : '${widget.ingredient?.name ?? 'Ingredient'} as primary component',
                            icon: LucideIcons.alertTriangle,
                            color: AppColors.danger,
                          ),
                        );
                      }
                      final interaction = primaryList[index - 1];
                      return PaginationWrapper(
                        key: ValueKey('primary_${interaction.id}_$index'),
                        index: index - 1,
                        child: InteractionCard(
                          interaction: interaction,
                          onTap: () => _showInteractionDetails(interaction),
                        ),
                      );
                    },
                    childCount:
                        _filteredInteractions
                            .where((i) => i.isPrimaryIngredient)
                            .length +
                        1, // +1 for header
                  ),
                ),
              ),

            // 2. Secondary Interactions (Low Priority / Contextual)
            if (_filteredInteractions.any((i) => !i.isPrimaryIngredient))
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final secondaryList =
                          _filteredInteractions
                              .where((i) => !i.isPrimaryIngredient)
                              .toList();

                      if (index == 0) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 8, bottom: 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _InfoBanner(
                                text:
                                    isRTL
                                        ? 'التفاعلات التالية تحدث عند وجود ${widget.ingredient?.name} كمكون ثانوي أو ضمن تركيبة دوائية، وقد تكون أقل خطورة أو تعتمد على الكمية.'
                                        : 'These interactions occur when ${widget.ingredient?.name} is present as a secondary component. They might be less critical or dose-dependent.',
                                color: AppColors.info,
                              ),
                              const SizedBox(height: 16),
                              _InteractionSectionHeader(
                                title:
                                    isRTL
                                        ? 'تفاعلات ثانوية'
                                        : 'Secondary Interactions',
                                subtitle:
                                    isRTL
                                        ? 'أدوية تحتوي على ${widget.ingredient?.name}'
                                        : 'Drugs containing ${widget.ingredient?.name}',
                                icon: LucideIcons.info,
                                color: AppColors.info,
                              ),
                            ],
                          ),
                        );
                      }
                      final interaction = secondaryList[index - 1];
                      return PaginationWrapper(
                        key: ValueKey('secondary_${interaction.id}_$index'),
                        index: index - 1,
                        child: InteractionCard(
                          interaction: interaction,
                          onTap: () => _showInteractionDetails(interaction),
                        ),
                      );
                    },
                    childCount:
                        _filteredInteractions
                            .where((i) => !i.isPrimaryIngredient)
                            .length +
                        1, // +1 for header
                  ),
                ),
              ),
          ],
        ],
      ),
  void _showInteractionDetails(DrugInteraction interaction) {
    showDialog(
      context: context,
      builder: (context) {
        final isRTL = Directionality.of(context) == TextDirection.rtl;
        return AlertDialog(
          title: Text(
            isRTL ? 'تفاصيل التفاعل' : 'Interaction Details',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _DetailRow(
                  label: isRTL ? 'المادة الأولى' : 'Ingredient 1',
                  value: interaction.ingredient1,
                ),
                _DetailRow(
                  label: isRTL ? 'المادة الثانية' : 'Ingredient 2',
                  value: interaction.ingredient2,
                ),
                _DetailRow(
                  label: isRTL ? 'الخطورة' : 'Severity',
                  value: interaction.severity,
                  isSeverity: true,
                ),
                const Divider(height: 24),
                Text(
                  isRTL ? 'التأثير:' : 'Effect:',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  interaction.effect,
                  style: const TextStyle(height: 1.5, fontSize: 15),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(isRTL ? 'إغلاق' : 'Close'),
            ),
          ],
        );
      },
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isSeverity;

  const _DetailRow({
    required this.label,
    required this.value,
    this.isSeverity = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: isSeverity && value.toLowerCase().contains('severe')
                    ? AppColors.danger
                    : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InteractionSectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? icon;
  final Color? color;

  const _InteractionSectionHeader({
    required this.title,
    this.subtitle,
    this.icon,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        if (icon != null) ...[
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: (color ?? theme.colorScheme.primary).withValues(
                alpha: 0.1,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 20,
              color: color ?? theme.colorScheme.primary,
            ),
          ),
          const SizedBox(width: 12),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              if (subtitle != null)
                Text(
                  subtitle!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _InfoBanner extends StatelessWidget {
  final String text;
  final Color color;

  const _InfoBanner({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(LucideIcons.info, size: 20, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 13, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

class PaginationWrapper extends StatelessWidget {
  final Widget child;
  final int index;

  const PaginationWrapper({
    super.key,
    required this.child,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    return child
        .animate(delay: (20 * (index % 10)).ms) // Limit delay for long lists
        .fadeIn()
        .slideX(begin: 0.1, end: 0);
  }
}
