import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_spacing.dart'; // Import spacing constants
import '../../domain/entities/drug_entity.dart';
import '../bloc/alternatives_provider.dart';
import '../widgets/alternative_drug_card.dart'; // Import the new card widget

class AlternativesScreen extends StatefulWidget {
  final DrugEntity originalDrug;

  const AlternativesScreen({super.key, required this.originalDrug});

  @override
  State<AlternativesScreen> createState() => _AlternativesScreenState();
}

class _AlternativesScreenState extends State<AlternativesScreen> {
  @override
  void initState() {
    super.initState();
    // Trigger finding alternatives when the screen is initialized
    // Use addPostFrameCallback to ensure provider is available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        // Check if mounted before accessing context
        context.read<AlternativesProvider>().findAlternativesFor(
          widget.originalDrug,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AlternativesProvider>();
    final theme = Theme.of(context); // Get theme for consistent styling

    return Scaffold(
      appBar: AppBar(
        // Match general AppBar style (assuming it's defined in main theme)
        // backgroundColor: theme.colorScheme.surface, // Inherited from theme
        // foregroundColor: theme.colorScheme.onSurface, // Inherited from theme
        // elevation: 0.5, // Inherited from theme
        title: Text('بدائل ${widget.originalDrug.tradeName}'),
        centerTitle: true, // Keep centered for this screen
      ),
      body: Padding(
        // Use constants for padding
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.large, // Use constant (16px)
          vertical: AppSpacing.large + AppSpacing.xsmall, // Approx 20px (16+4)
        ),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.stretch, // Stretch children horizontally
          children: [
            // Display Original Drug Info (Optional) - Styled Card
            Card(
              // Use theme defaults for elevation, shape, color
              margin: const EdgeInsets.only(
                bottom: AppSpacing.large,
              ), // Use constant (16px)
              child: Padding(
                padding: AppSpacing.edgeInsetsAllMedium, // Use constant (12px)
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'الدواء الأصلي', // Clearer title
                      style: theme.textTheme.labelMedium?.copyWith(
                        color:
                            theme
                                .colorScheme
                                .onSurfaceVariant, // Use onSurfaceVariant
                      ),
                    ),
                    AppSpacing.gapVXSmall, // Use constant (4px)
                    Text(
                      widget.originalDrug.tradeName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface, // Use onSurface
                      ),
                    ),
                    // Optionally display dosage form for original drug too
                    if (widget.originalDrug.dosageForm.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(
                          top: AppSpacing.xxsmall,
                        ), // 2px
                        child: Text(
                          widget.originalDrug.dosageForm, // Display dosage form
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    if (widget.originalDrug.category != null &&
                        widget.originalDrug.category!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(
                          top: AppSpacing.xxsmall,
                        ), // 2px
                        child: Text(
                          'الفئة: ${widget.originalDrug.category}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color:
                                theme
                                    .colorScheme
                                    .onSurfaceVariant, // Use onSurfaceVariant
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            // const Divider(height: 24), // Removed divider, using card separation

            // Display Alternatives Title
            Padding(
              padding: const EdgeInsets.only(
                bottom: AppSpacing.medium, // Use constant (12px)
              ),
              child: Text(
                'البدائل المقترحة (نفس الفئة)', // Slightly more descriptive title
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.start,
              ),
            ),
            // const SizedBox(height: 8), // Replaced with Padding above

            // Loading/Error/List View
            if (provider.isLoading)
              const Expanded(child: Center(child: CircularProgressIndicator()))
            else if (provider.error.isNotEmpty)
              Expanded(
                child: Center(
                  child: Text(
                    provider.error,
                    style: TextStyle(
                      color: theme.colorScheme.error,
                    ), // Use theme error color
                  ),
                ),
              )
            else if (provider.alternatives.isEmpty)
              const Expanded(
                child: Center(child: Text('لا توجد بدائل متاحة لهذه الفئة.')),
              )
            else
              Expanded(
                child: ListView.separated(
                  // Use ListView.separated for spacing
                  itemCount: provider.alternatives.length,
                  separatorBuilder:
                      (context, index) =>
                          AppSpacing
                              .gapVMedium, // Use constant (12px) for separator
                  itemBuilder: (context, index) {
                    final alternative = provider.alternatives[index];
                    // Use the new AlternativeDrugCard
                    return AlternativeDrugCard(
                      drug: alternative,
                      onTap: () {
                        // Optional: Navigate to details of the alternative?
                        // Maybe show the same _showMedicineDetails modal from HomeScreen?
                        print(
                          'Tapped on alternative: ${alternative.tradeName}',
                        );
                      },
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
