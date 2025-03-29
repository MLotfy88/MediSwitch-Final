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
        title: Text('بدائل ${widget.originalDrug.tradeName}'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Display Original Drug Info (Optional)
            Text(
              'الدواء الأصلي: ${widget.originalDrug.tradeName}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text('الفئة: ${widget.originalDrug.mainCategory}'),
            const Divider(height: 24),

            // Display Alternatives
            const Text(
              'البدائل (نفس الفئة):',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

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
