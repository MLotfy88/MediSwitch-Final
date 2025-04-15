import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../bloc/interaction_provider.dart';
import '../bloc/medicine_provider.dart'; // To get drug list for selection
import '../../domain/entities/drug_entity.dart';
import '../../domain/entities/drug_interaction.dart';
import '../../domain/entities/interaction_severity.dart';
import '../../domain/entities/interaction_analysis_result.dart';
import '../../core/di/locator.dart';
import '../../core/services/file_logger_service.dart';
import '../widgets/custom_badge.dart';
import '../widgets/drug_selection_dialog.dart'; // Import the custom dialog
import '../widgets/interaction_card.dart'; // Import the new card widget

class InteractionCheckerScreen extends StatefulWidget {
  const InteractionCheckerScreen({super.key});

  @override
  State<InteractionCheckerScreen> createState() =>
      _InteractionCheckerScreenState();
}

class _InteractionCheckerScreenState extends State<InteractionCheckerScreen> {
  final FileLoggerService _logger = locator<FileLoggerService>();

  Future<void> _showDrugSelectionDialog() async {
    _logger.i("InteractionCheckerScreen: Add Drug button tapped.");
    final allDrugs = context.read<MedicineProvider>().filteredMedicines;
    final interactionProvider = context.read<InteractionProvider>();
    DrugEntity? dialogSelectedDrug;

    final selectedDrug = await showDialog<DrugEntity>(
      context: context,
      builder:
          (context) => DrugSelectionDialog(
            allDrugs: allDrugs,
            alreadySelectedDrugs: interactionProvider.selectedMedicines,
          ),
    );

    if (selectedDrug != null) {
      _logger.i(
        "InteractionCheckerScreen: Drug selected: ${selectedDrug.tradeName}",
      );
      interactionProvider.addMedicine(selectedDrug);
    } else {
      _logger.d(
        "InteractionCheckerScreen: Drug selection cancelled or failed.",
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    _logger.d("InteractionCheckerScreen: Building widget.");
    final provider = context.watch<InteractionProvider>();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('مدقق التفاعلات الدوائية')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'الأدوية المختارة:',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                color: colorScheme.surfaceVariant.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              constraints: const BoxConstraints(minHeight: 50),
              child: Wrap(
                spacing: 8.0,
                runSpacing: 4.0,
                children:
                    provider.selectedMedicines.isEmpty
                        ? [
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 8.0,
                              ),
                              child: Text(
                                'أضف دوائين أو أكثر لبدء الفحص.',
                                style: textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ),
                        ]
                        : provider.selectedMedicines
                            .map(
                              (drug) => Chip(
                                label: Text(drug.tradeName),
                                onDeleted: () {
                                  _logger.i(
                                    "InteractionCheckerScreen: Removing drug: ${drug.tradeName}",
                                  );
                                  provider.removeMedicine(drug);
                                },
                                deleteIcon: Icon(LucideIcons.xCircle, size: 18),
                                deleteIconColor: colorScheme
                                    .onSecondaryContainer
                                    .withOpacity(0.7),
                                backgroundColor: colorScheme.secondaryContainer,
                                labelStyle: textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.onSecondaryContainer,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                              ),
                            )
                            .toList(),
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              icon: Icon(LucideIcons.plusCircle, size: 18),
              label: const Text('إضافة دواء'),
              onPressed: _showDrugSelectionDialog,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon:
                  provider.isLoading
                      ? Container(
                        width: 20,
                        height: 20,
                        margin: const EdgeInsets.only(left: 8),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: colorScheme.onPrimary,
                        ),
                      )
                      : Icon(LucideIcons.zap, size: 18),
              label: Text(
                provider.isLoading ? 'جاري الفحص...' : 'فحص التفاعلات',
              ),
              onPressed:
                  provider.isLoading || provider.selectedMedicines.length < 2
                      ? null
                      : () {
                        _logger.i(
                          "InteractionCheckerScreen: Check Interactions button pressed.",
                        );
                        provider.analyzeInteractions();
                      },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                textStyle: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),
            Text(
              'نتائج فحص التفاعلات:',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Expanded(child: _buildResultsArea(context, provider)),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsArea(BuildContext context, InteractionProvider provider) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    } else if (provider.error.isNotEmpty) {
      return Center(
        child: Text(
          'خطأ: ${provider.error}',
          style: TextStyle(color: colorScheme.error),
        ),
      );
    } else if (provider.analysisResult == null) {
      return Center(
        child: Text(
          'أضف دوائين على الأقل ثم اضغط "فحص التفاعلات".',
          style: TextStyle(color: colorScheme.onSurfaceVariant),
        ),
      );
    } else {
      final result = provider.analysisResult!;
      return Column(
        children: [
          if (result.interactions.isNotEmpty) ...[
            _buildOverallSeverity(context, result.overallSeverity),
            const SizedBox(height: 16),
          ],
          Expanded(
            child:
                result.interactions.isEmpty
                    ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            LucideIcons.checkCheck,
                            size: 48,
                            color: Colors.green.shade600,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'لا توجد تفاعلات معروفة بين الأدوية المختارة.',
                            style: TextStyle(color: colorScheme.secondary),
                          ),
                        ],
                      ),
                    )
                    : ListView.separated(
                      itemCount: result.interactions.length,
                      itemBuilder: (context, index) {
                        final interaction = result.interactions[index];
                        // Use the dedicated InteractionCard widget
                        return InteractionCard(interaction: interaction);
                      },
                      separatorBuilder:
                          (context, index) => const SizedBox(height: 12),
                    ),
          ),
        ],
      );
    }
  }

  Widget _buildOverallSeverity(
    BuildContext context,
    InteractionSeverity severity,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    Color bgColor;
    Color textColor;
    String text;
    IconData icon;

    switch (severity) {
      case InteractionSeverity.major:
        bgColor = colorScheme.errorContainer;
        textColor = colorScheme.onErrorContainer;
        text = 'خطورة عالية';
        icon = LucideIcons.alertOctagon;
        break;
      case InteractionSeverity.moderate:
        bgColor = Colors.orange.shade100;
        textColor = Colors.orange.shade900;
        text = 'خطورة متوسطة';
        icon = LucideIcons.alertTriangle;
        break;
      case InteractionSeverity.minor:
        bgColor = colorScheme.secondaryContainer;
        textColor = colorScheme.onSecondaryContainer;
        text = 'خطورة طفيفة';
        icon = LucideIcons.info;
        break;
      default:
        bgColor = colorScheme.surfaceVariant;
        textColor = colorScheme.onSurfaceVariant;
        text = 'غير معروفة';
        icon = LucideIcons.helpCircle;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: bgColor.withOpacity(0.8),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: textColor, size: 20),
          const SizedBox(width: 8),
          Text(
            'مستوى الخطورة العام: $text',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  // Removed _buildInteractionCard helper function
}
