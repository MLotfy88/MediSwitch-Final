// lib/presentation/screens/interaction_checker_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../domain/entities/drug_entity.dart'; // Import DrugEntity
import '../../domain/entities/drug_interaction.dart';
import '../../domain/entities/interaction_severity.dart'; // Import enum
import '../../domain/entities/interaction_type.dart'; // Import enum
import '../../domain/entities/interaction_analysis_result.dart';
import '../bloc/interaction_provider.dart'; // Import the provider
import '../bloc/medicine_provider.dart'; // To access the full medicine list

class InteractionCheckerScreen extends StatelessWidget {
  const InteractionCheckerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Access the provider
    final interactionProvider = context.watch<InteractionProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('مدقق التفاعلات الدوائية'),
        actions: [
          // Add a clear button if needed
          if (interactionProvider.selectedMedicines.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear_all),
              tooltip: 'مسح الكل',
              onPressed: () {
                context.read<InteractionProvider>().clearSelection();
              },
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Section to display selected drugs as Chips
            Text(
              'الأدوية المختارة:',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            interactionProvider.selectedMedicines.isEmpty
                ? Container(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: const Text(
                    'لم يتم اختيار أدوية بعد.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                )
                : Wrap(
                  spacing: 8.0,
                  runSpacing: 4.0,
                  children:
                      interactionProvider.selectedMedicines.map((drug) {
                        return Chip(
                          label: Text(drug.tradeName),
                          deleteIcon: const Icon(Icons.close, size: 18),
                          onDeleted: () {
                            context.read<InteractionProvider>().removeMedicine(
                              drug,
                            );
                          },
                        );
                      }).toList(),
                ),
            const SizedBox(height: 16),
            // Add Drug Button
            ElevatedButton.icon(
              icon: const Icon(Icons.add_circle_outline),
              label: const Text('إضافة دواء للفحص'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onPressed: () async {
                // Show dialog to select a drug
                final medicineProvider = context.read<MedicineProvider>();
                // Ensure medicine data is loaded before showing dialog
                if (medicineProvider.medicines.isEmpty &&
                    !medicineProvider.isLoading) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('جاري تحميل قائمة الأدوية...'),
                    ),
                  );
                  // Optionally trigger loading if needed
                  return;
                }
                if (medicineProvider.isLoading) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('قائمة الأدوية لا تزال قيد التحميل...'),
                    ),
                  );
                  return;
                }

                final selectedDrug = await _showDrugSelectionDialog(
                  context,
                  medicineProvider.medicines, // Pass the full list
                  interactionProvider
                      .selectedMedicines, // Pass selected to filter
                );
                if (selectedDrug != null) {
                  context.read<InteractionProvider>().addMedicine(selectedDrug);
                }
              },
            ),
            const SizedBox(height: 24),
            const Divider(), // Separator before results
            const SizedBox(height: 16),

            // Results Display Area
            _buildResultsArea(context, interactionProvider),
          ],
        ),
      ),
    );
  }

  // --- Build Helper Methods ---

  // Dialog to select a drug (similar to weight calculator)
  Future<DrugEntity?> _showDrugSelectionDialog(
    BuildContext context,
    List<DrugEntity> allMedicines,
    List<DrugEntity> alreadySelected,
  ) async {
    // Filter out already selected medicines
    final availableMedicines =
        allMedicines
            .where(
              (med) =>
                  !alreadySelected.any(
                    (selected) => selected.tradeName == med.tradeName,
                  ),
            )
            .toList();

    // Simple dialog for now, consider adding search later
    return showDialog<DrugEntity>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('اختر دواء لإضافته'),
          content: SizedBox(
            width: double.maxFinite,
            child:
                availableMedicines.isEmpty
                    ? const Text('لا توجد أدوية أخرى متاحة أو تم اختيار الكل.')
                    : ListView.builder(
                      shrinkWrap: true,
                      itemCount: availableMedicines.length,
                      itemBuilder: (BuildContext context, int index) {
                        final drug = availableMedicines[index];
                        return ListTile(
                          title: Text(drug.tradeName),
                          subtitle: Text(drug.arabicName),
                          onTap: () {
                            Navigator.of(context).pop(drug);
                          },
                        );
                      },
                    ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('إلغاء'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  // Helper widget to conditionally build the results area
  Widget _buildResultsArea(BuildContext context, InteractionProvider provider) {
    if (provider.isLoading) {
      return const Expanded(
        // Use Expanded here
        child: Center(child: CircularProgressIndicator()),
      );
    } else if (provider.error.isNotEmpty) {
      return Expanded(
        // Use Expanded here
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Text(
              'خطأ: ${provider.error}',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    } else if (provider.analysisResult != null) {
      // Use the existing helper to build the list content
      return _buildResultsList(context, provider.analysisResult!);
    } else if (provider.selectedMedicines.length < 2) {
      return const Expanded(
        // Use Expanded here
        child: Center(child: Text('أضف دوائين على الأقل لفحص التفاعلات.')),
      );
    } else {
      // Initial state before analysis triggered for >= 2 drugs
      return const Expanded(
        // Use Expanded here
        child: Center(child: Text('جاهز لفحص التفاعلات...')),
      );
    }
  }

  // Helper widget to build the results display list
  Widget _buildResultsList(
    BuildContext context,
    InteractionAnalysisResult result,
  ) {
    final interactionProvider =
        context.read<InteractionProvider>(); // Needed for original names

    return Expanded(
      // Add Expanded here since ListView is returned directly
      child: ListView(
        children: [
          // Overall Severity Badge
          _buildSeveritySummary(context, result.overallSeverity),
          const SizedBox(height: 16),

          // Recommendations Section
          if (result.recommendations.isNotEmpty) ...[
            Text(
              'التوصيات الهامة:',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            ...result.recommendations
                .map(
                  (rec) => Padding(
                    padding: const EdgeInsets.only(bottom: 8.0, right: 8.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 18,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(child: Text(rec)),
                      ],
                    ),
                  ),
                )
                .toList(),
            const SizedBox(height: 16),
          ],

          // Detailed Interactions Section
          if (result.interactions.isNotEmpty) ...[
            Text(
              'تفاصيل التفاعلات (${result.interactions.length}):',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            ...result.interactions
                .map(
                  (interaction) => _buildInteractionCard(
                    context,
                    interaction,
                    interactionProvider
                        .selectedMedicines, // Pass selected for name lookup
                  ),
                )
                .toList(),
          ] else if (result.recommendations.isEmpty) ...[
            // Show message if no interactions and no recommendations (e.g., only minor)
            const Center(
              child: Text("لم يتم العثور على تفاعلات ذات أهمية سريرية."),
            ),
          ],
        ],
      ),
    );
  }

  // Helper to build the overall severity summary badge
  Widget _buildSeveritySummary(
    BuildContext context,
    InteractionSeverity severity,
  ) {
    Color bgColor;
    Color textColor;
    String text = _getSeverityArabicName(severity); // Use helper

    switch (severity) {
      case InteractionSeverity.minor:
        bgColor = Colors.green.shade100;
        textColor = Colors.green.shade900;
        break;
      case InteractionSeverity.moderate:
        bgColor = Colors.orange.shade100;
        textColor = Colors.orange.shade900;
        break;
      case InteractionSeverity.major:
        bgColor = Colors.deepOrange.shade100;
        textColor = Colors.deepOrange.shade900;
        break;
      case InteractionSeverity.severe:
      case InteractionSeverity.contraindicated:
        bgColor = Colors.red.shade100;
        textColor = Colors.red.shade900;
        break;
      default: // unknown
        bgColor = Colors.grey.shade200;
        textColor = Colors.grey.shade800;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: textColor.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.warning_amber_rounded, color: textColor, size: 20),
          const SizedBox(width: 8),
          Text(
            'مستوى الخطورة العام: $text',
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.bold,
              fontSize: 16,
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
    // Find original medicine names (similar logic to service)
    // final interactionProvider = context.read<InteractionProvider>(); // Access provider again if needed
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

    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: severityColor.withOpacity(0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with Drug Names and Severity Badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    '${med1Name ?? interaction.ingredient1} + ${med2Name ?? interaction.ingredient2}',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: severityColor.withOpacity(0.15),
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
            Text(effectText, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 8),

            // Recommendation
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline,
                  size: 16,
                  color: Colors.blueGrey.shade400,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    recommendationText,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.blueGrey.shade700,
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
                  style: Theme.of(
                    context,
                  ).textTheme.labelSmall?.copyWith(color: Colors.grey.shade600),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Helper to find medicine name (could be moved to provider or utility)
  String? _findMedicineNameForIngredient(
    String ingredient,
    List<DrugEntity> medicines,
  ) {
    // Simple search in active ingredient string for now
    // A more robust solution would use the medicine-to-ingredient map
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
        return Colors.green.shade700;
      case InteractionSeverity.moderate:
        return Colors.orange.shade800;
      case InteractionSeverity.major:
        return Colors.deepOrange.shade700;
      case InteractionSeverity.severe:
      case InteractionSeverity.contraindicated:
        return Colors.red.shade800;
      default:
        return Colors.grey.shade700;
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
