import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../domain/entities/drug_entity.dart';
import '../../domain/entities/drug_interaction.dart';
import '../../domain/entities/interaction_severity.dart';
import '../../domain/entities/interaction_type.dart';
import '../../domain/entities/interaction_analysis_result.dart';
import '../bloc/interaction_provider.dart';
import '../bloc/medicine_provider.dart';
import '../widgets/custom_search_delegate.dart'; // Import the search delegate

class InteractionCheckerScreen extends StatelessWidget {
  const InteractionCheckerScreen({super.key});

  // Function to show medicine search
  Future<void> _showMedicineSearch(BuildContext context) async {
    final interactionProvider = context.read<InteractionProvider>();
    final medicineProvider = context.read<MedicineProvider>();

    // Ensure medicine data is loaded
    if (medicineProvider.medicines.isEmpty && !medicineProvider.isLoading) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('جاري تحميل قائمة الأدوية...')),
      );
      // Optionally trigger loading if needed
      return;
    }
    if (medicineProvider.isLoading) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('قائمة الأدوية لا تزال قيد التحميل...')),
      );
      return;
    }

    // Filter out already selected medicines before passing to search delegate
    final availableMedicines =
        medicineProvider.medicines
            .where(
              (med) =>
                  !interactionProvider.selectedMedicines.any(
                    (selected) =>
                        selected.tradeName ==
                        med.tradeName, // Compare using tradeName
                  ),
            )
            .toList();

    if (availableMedicines.isEmpty && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم اختيار كل الأدوية المتاحة.')),
      );
      return;
    }

    final selectedDrug = await showSearch<DrugEntity?>(
      context: context,
      delegate: CustomSearchDelegate(
        searchFieldLabel: 'ابحث عن دواء لإضافته...',
        medicines: availableMedicines, // Pass only available medicines
        searchLogic: (query) {
          if (query.isEmpty) {
            return availableMedicines; // Show available if query is empty
          }
          final lowerCaseQuery = query.toLowerCase();
          return availableMedicines.where((drug) {
            return drug.tradeName.toLowerCase().contains(lowerCaseQuery) ||
                drug.arabicName.toLowerCase().contains(lowerCaseQuery);
          }).toList();
        },
      ),
    );

    if (selectedDrug != null && context.mounted) {
      context.read<InteractionProvider>().addMedicine(selectedDrug);
    }
  }

  @override
  Widget build(BuildContext context) {
    final interactionProvider = context.watch<InteractionProvider>();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final bool canAnalyze = interactionProvider.selectedMedicines.length >= 2;

    // Define card padding and margin
    const cardMargin = EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0);
    const cardPadding = EdgeInsets.all(16.0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('مدقق التفاعلات الدوائية'),
        // Match general AppBar style
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        elevation: 0.5,
        actions: [
          if (interactionProvider.selectedMedicines.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear_all),
              tooltip: 'مسح الكل',
              onPressed:
                  () => context.read<InteractionProvider>().clearSelection(),
            ),
        ],
      ),
      body: Column(
        // Use Column for layout
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Selection Card - Match general Card style
          Card(
            margin: cardMargin,
            elevation: 0, // No elevation
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12), // Match theme --radius
              side: BorderSide(
                color: Theme.of(context).colorScheme.outline.withOpacity(0.5),
              ), // Subtle border
            ),
            child: Padding(
              padding: cardPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('الأدوية المختارة:', style: textTheme.titleMedium),
                  const SizedBox(height: 12),
                  interactionProvider.selectedMedicines.isEmpty
                      ? Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12.0),
                        child: Text(
                          'لم يتم اختيار أدوية بعد. اضغط أدناه للإضافة.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: theme.hintColor),
                        ),
                      )
                      : Wrap(
                        spacing: 8.0,
                        runSpacing: 6.0,
                        children:
                            interactionProvider.selectedMedicines.map((drug) {
                              // Match shadcn Badge/Chip style
                              return Chip(
                                label: Text(drug.tradeName),
                                deleteIcon: const Icon(Icons.close, size: 16),
                                onDeleted:
                                    () => context
                                        .read<InteractionProvider>()
                                        .removeMedicine(drug),
                                backgroundColor: colorScheme.secondaryContainer
                                    .withOpacity(
                                      0.6,
                                    ), // Use secondary container
                                labelStyle: TextStyle(
                                  color: colorScheme.onSecondaryContainer,
                                  fontSize: 13, // Slightly smaller
                                ),
                                deleteIconColor: colorScheme
                                    .onSecondaryContainer
                                    .withOpacity(0.7),
                                side:
                                    BorderSide
                                        .none, // Remove border or make very subtle
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ), // Adjust padding
                                visualDensity: VisualDensity.compact,
                              );
                            }).toList(),
                      ),
                  const SizedBox(height: 16),
                  // Add Drug Button
                  // Match shadcn Button (outline variant)
                  OutlinedButton.icon(
                    icon: const Icon(Icons.add_circle_outline, size: 20),
                    label: const Text('إضافة دواء للفحص'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colorScheme.primary,
                      side: BorderSide(
                        color: colorScheme.primary.withOpacity(0.7),
                      ), // Match theme border
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ), // Match theme --radius
                    ),
                    onPressed: () => _showMedicineSearch(context),
                  ),
                ],
              ),
            ),
          ),

          // Analyze Button
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: ElevatedButton.icon(
              icon:
                  interactionProvider.isLoading
                      ? Container(
                        width: 20,
                        height: 20,
                        margin: const EdgeInsets.only(right: 8),
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: colorScheme.onPrimary,
                        ),
                      )
                      : const Icon(Icons.science_outlined),
              label: Text(
                interactionProvider.isLoading
                    ? 'جاري الفحص...'
                    : 'فحص التفاعلات',
              ),
              // Match shadcn Button (default variant)
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14.0),
                textStyle: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600, // Slightly bolder
                ),
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                shape: RoundedRectangleBorder(
                  // Match theme --radius
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ).copyWith(
                // Handle disabled state explicitly
                backgroundColor: MaterialStateProperty.resolveWith<Color?>((
                  Set<MaterialState> states,
                ) {
                  if (states.contains(MaterialState.disabled)) {
                    return colorScheme.primary.withOpacity(
                      0.5,
                    ); // Example disabled color
                  }
                  return colorScheme.primary; // Use the component's default.
                }),
                foregroundColor: MaterialStateProperty.resolveWith<Color?>((
                  Set<MaterialState> states,
                ) {
                  if (states.contains(MaterialState.disabled)) {
                    return colorScheme.onPrimary.withOpacity(
                      0.7,
                    ); // Example disabled text color
                  }
                  return colorScheme.onPrimary;
                }),
              ),
              onPressed:
                  (canAnalyze && !interactionProvider.isLoading)
                      ? () =>
                          context
                              .read<InteractionProvider>()
                              .analyzeInteractions()
                      : null, // Disable if less than 2 drugs or loading
            ),
          ),

          const Divider(height: 16, indent: 16, endIndent: 16),

          // Results Area
          Expanded(
            // Make results area scrollable
            child: _buildResultsArea(context, interactionProvider),
          ),
        ],
      ),
    );
  }

  // --- Build Helper Methods ---

  // Helper widget to conditionally build the results area
  Widget _buildResultsArea(BuildContext context, InteractionProvider provider) {
    final theme = Theme.of(context);

    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    } else if (provider.error.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Text(
            'خطأ: ${provider.error}',
            style: TextStyle(color: theme.colorScheme.error),
            textAlign: TextAlign.center,
          ),
        ),
      );
    } else if (provider.analysisResult != null) {
      return _buildResultsList(context, provider.analysisResult!);
    } else if (provider.selectedMedicines.length < 2) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Text(
            'أضف دوائين على الأقل لبدء فحص التفاعلات.',
            textAlign: TextAlign.center,
            style: TextStyle(color: theme.hintColor),
          ),
        ),
      );
    } else {
      // Ready to analyze state
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Text(
            'اضغط على "فحص التفاعلات" لعرض النتائج.',
            textAlign: TextAlign.center,
            style: TextStyle(color: theme.hintColor),
          ),
        ),
      );
    }
  }

  // Helper widget to build the results display list
  Widget _buildResultsList(
    BuildContext context,
    InteractionAnalysisResult result,
  ) {
    final theme = Theme.of(context);
    final interactionProvider =
        context.read<InteractionProvider>(); // Needed for original names

    // Handle case where analysis ran but found nothing significant
    if (result.interactions.isEmpty && result.recommendations.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Text(
            "لم يتم العثور على تفاعلات ذات أهمية سريرية.",
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      children: [
        // Overall Severity Badge
        _buildSeveritySummary(context, result.overallSeverity),
        const SizedBox(height: 16),

        // Recommendations Section
        if (result.recommendations.isNotEmpty) ...[
          Text('التوصيات الهامة:', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          // Recommendations Card - Match general Card style
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12), // Match theme --radius
              side: BorderSide(
                color: theme.colorScheme.outline.withOpacity(0.5),
              ), // Subtle border
            ),
            color: theme.colorScheme.surfaceVariant.withOpacity(
              0.5,
            ), // Use surface variant
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                children:
                    result.recommendations
                        .map(
                          (rec) => Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  size: 18,
                                  color: theme.colorScheme.primary,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    rec,
                                    style: theme.textTheme.bodyMedium,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                        .toList(),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Detailed Interactions Section
        if (result.interactions.isNotEmpty) ...[
          Text(
            'تفاصيل التفاعلات (${result.interactions.length}):',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          ...result.interactions
              .map(
                (interaction) => _buildInteractionCard(
                  context,
                  interaction,
                  interactionProvider.selectedMedicines,
                ),
              )
              .toList(),
        ],
      ],
    );
  }

  // Helper to build the overall severity summary badge
  Widget _buildSeveritySummary(
    BuildContext context,
    InteractionSeverity severity,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    Color bgColor;
    Color textColor;
    IconData iconData;
    String text = _getSeverityArabicName(severity);

    switch (severity) {
      case InteractionSeverity.minor:
        bgColor = Colors.green.shade50;
        textColor = Colors.green.shade900;
        iconData = Icons.check_circle_outline;
        break;
      case InteractionSeverity.moderate:
        bgColor = Colors.orange.shade50;
        textColor = Colors.orange.shade900;
        iconData = Icons.warning_amber_rounded;
        break;
      case InteractionSeverity.major:
        bgColor = Colors.deepOrange.shade50;
        textColor = Colors.deepOrange.shade900;
        iconData = Icons.warning_rounded;
        break;
      case InteractionSeverity.severe:
      case InteractionSeverity.contraindicated:
        bgColor = Colors.red.shade50;
        textColor = Colors.red.shade900;
        iconData = Icons.dangerous_outlined;
        break;
      default: // unknown or none
        bgColor = Colors.grey.shade100;
        textColor = Colors.grey.shade800;
        iconData = Icons.info_outline;
        text = "لا توجد تفاعلات خطيرة"; // Adjust text for 'none' case
    }

    // Match shadcn Alert style
    return Container(
      padding: const EdgeInsets.all(16), // Consistent padding
      decoration: BoxDecoration(
        color: bgColor, // Background based on severity
        borderRadius: BorderRadius.circular(8), // Match theme --radius
        border: Border.all(
          color: textColor.withOpacity(0.6),
        ), // Border based on severity text color
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(iconData, color: textColor, size: 22),
          const SizedBox(width: 10),
          Text(
            severity == InteractionSeverity.unknown
                ? text
                : 'الخطورة العامة: $text',
            style: theme.textTheme.titleMedium?.copyWith(
              color: textColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // Helper to build a card for a single interaction
  Widget _buildInteractionCard(
    BuildContext context,
    DrugInteraction interaction,
    List<DrugEntity> selectedMedicines,
  ) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    final med1Name = _findMedicineNameForIngredient(
      interaction.ingredient1,
      selectedMedicines,
    );
    final med2Name = _findMedicineNameForIngredient(
      interaction.ingredient2,
      selectedMedicines,
    );

    final severityText = _getSeverityArabicName(interaction.severity);
    final typeText = _getInteractionTypeArabicName(interaction.type);
    final effectText =
        interaction.arabicEffect.isNotEmpty
            ? interaction.arabicEffect
            : interaction.effect;
    final recommendationText =
        interaction.arabicRecommendation.isNotEmpty
            ? interaction.arabicRecommendation
            : interaction.recommendation;

    Color severityColor = _getSeverityColor(interaction.severity);
    Color severityBgColor = _getSeverityBgColor(interaction.severity);

    // Match general Card style
    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      elevation: 0, // No elevation
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12), // Match theme --radius
        side: BorderSide(
          color: severityColor.withOpacity(0.5),
        ), // Border color based on severity
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with Drug Names and Severity Badge
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    '${med1Name ?? interaction.ingredient1} + ${med2Name ?? interaction.ingredient2}',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: severityBgColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    severityText,
                    style: TextStyle(
                      color: severityColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 16),

            // Effect
            Text(
              'التأثير:',
              style: textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Text(effectText, style: textTheme.bodyMedium),
            const SizedBox(height: 12),

            // Recommendation
            Text(
              'التوصية:',
              style: textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline,
                  size: 18,
                  color: Colors.blueGrey.shade400,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    recommendationText,
                    style: textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),

            // Interaction Type (Optional)
            if (interaction.type != InteractionType.unknown) ...[
              const SizedBox(height: 8),
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: Text(
                  'نوع التفاعل: $typeText',
                  style: textTheme.labelSmall?.copyWith(
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Helper to find medicine name
  String? _findMedicineNameForIngredient(
    String ingredient,
    List<DrugEntity> medicines,
  ) {
    // Prioritize exact match first if possible (assuming DrugEntity has active ingredient list/field)
    // This is a placeholder - requires DrugEntity to have structured active ingredient info
    // for (final med in medicines) {
    //   if (med.activeIngredients?.contains(ingredient) ?? false) { // Example check
    //      return med.arabicName.isNotEmpty ? med.arabicName : med.tradeName;
    //   }
    // }

    // Fallback: check if ingredient name is part of the medicine's active ingredient string
    for (final med in medicines) {
      if (med.active.toLowerCase().contains(ingredient.toLowerCase())) {
        return med.arabicName.isNotEmpty ? med.arabicName : med.tradeName;
      }
    }
    return ingredient; // Fallback to ingredient name if not found
  }

  // Helper to get severity color
  Color _getSeverityColor(InteractionSeverity severity) {
    switch (severity) {
      case InteractionSeverity.minor:
        return Colors.green.shade800;
      case InteractionSeverity.moderate:
        return Colors.orange.shade900;
      case InteractionSeverity.major:
        return Colors.deepOrange.shade800;
      case InteractionSeverity.severe:
      case InteractionSeverity.contraindicated:
        return Colors.red.shade900;
      default:
        return Colors.grey.shade700;
    }
  }

  // Helper to get severity background color
  Color _getSeverityBgColor(InteractionSeverity severity) {
    switch (severity) {
      case InteractionSeverity.minor:
        return Colors.green.shade100;
      case InteractionSeverity.moderate:
        return Colors.orange.shade100;
      case InteractionSeverity.major:
        return Colors.deepOrange.shade100;
      case InteractionSeverity.severe:
      case InteractionSeverity.contraindicated:
        return Colors.red.shade100;
      default:
        return Colors.grey.shade200;
    }
  }

  // Helper to get Arabic name for severity
  String _getSeverityArabicName(InteractionSeverity severity) {
    switch (severity) {
      case InteractionSeverity.minor:
        return 'بسيط';
      case InteractionSeverity.moderate:
        return 'متوسط';
      case InteractionSeverity.major:
        return 'كبير';
      case InteractionSeverity.severe:
        return 'شديد';
      case InteractionSeverity.contraindicated:
        return 'مضاد استطباب';
      default:
        return 'غير معروف';
    }
  }

  // Helper to get Arabic name for interaction type
  String _getInteractionTypeArabicName(InteractionType type) {
    switch (type) {
      case InteractionType.pharmacokinetic:
        return 'حركية الدواء';
      case InteractionType.pharmacodynamic:
        return 'ديناميكية الدواء';
      case InteractionType.therapeutic:
        return 'علاجي';
      default:
        return 'غير محدد';
    }
  }
}
