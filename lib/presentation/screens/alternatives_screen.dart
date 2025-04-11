import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
      context.read<AlternativesProvider>().findAlternativesFor(
        widget.originalDrug,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AlternativesProvider>();

    return Scaffold(
      appBar: AppBar(
        // Match general AppBar style
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        elevation: 0.5,
        title: Text('بدائل ${widget.originalDrug.tradeName}'),
        centerTitle: true, // Keep centered for this screen
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 16.0,
          vertical: 20.0,
        ), // Increased vertical padding
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.stretch, // Stretch children horizontally
          children: [
            // Display Original Drug Info (Optional) - Styled Card
            // Original Drug Card - Match general Card style
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12), // Match theme --radius
                side: BorderSide(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.5),
                ), // Subtle border
              ),
              color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(
                0.5,
              ), // Use surface variant
              margin: const EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'الدواء الأصلي', // Clearer title
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        // Adjust style
                        color:
                            Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant, // Use onSurfaceVariant
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.originalDrug.tradeName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        // Keep titleMedium
                        fontWeight: FontWeight.bold,
                        color:
                            Theme.of(
                              context,
                            ).colorScheme.onSurface, // Use onSurface
                      ),
                    ),
                    if (widget.originalDrug.mainCategory.isNotEmpty)
                      Text(
                        'الفئة: ${widget.originalDrug.mainCategory}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          // Adjust style
                          color:
                              Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant, // Use onSurfaceVariant
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
                bottom: 12.0,
              ), // Increased spacing below title
              child: Text(
                'البدائل المقترحة (نفس الفئة)', // Slightly more descriptive title
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
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
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              )
            else if (provider.alternatives.isEmpty)
              const Expanded(
                child: Center(child: Text('لا توجد بدائل متاحة لهذه الفئة.')),
              )
            else
              Expanded(
                child: ListView.builder(
                  itemCount: provider.alternatives.length,
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
