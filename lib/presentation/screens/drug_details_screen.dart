import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // Needed for accessing providers
import '../../domain/entities/drug_entity.dart';
import '../bloc/alternatives_provider.dart'; // For Alternatives button
import '../screens/alternatives_screen.dart'; // For Alternatives button
import '../../main.dart'; // Import MyApp to access findDrugAlternativesUseCase (temporary DI)
import '../../domain/usecases/find_drug_alternatives.dart'; // Import use case for provider creation
import 'package:cached_network_image/cached_network_image.dart'; // Import for image display

class DrugDetailsScreen extends StatelessWidget {
  final DrugEntity drug;

  const DrugDetailsScreen({super.key, required this.drug});

  @override
  Widget build(BuildContext context) {
    // Access the use case needed for AlternativesProvider
    // TODO: Replace temporary access via MyApp with proper DI
    final findAlternativesUseCase =
        Provider.of<MyApp>(context, listen: false).findDrugAlternativesUseCase;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          drug.arabicName.isNotEmpty ? drug.arabicName : drug.tradeName,
        ),
        actions: [
          // Favorite Button Placeholder (Premium - Task 3.2.10)
          IconButton(
            icon: const Icon(Icons.favorite_border), // Or Icons.favorite
            tooltip: 'إضافة للمفضلة (Premium)',
            onPressed: () {
              // TODO: Implement Premium check and favorite logic
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('ميزة المفضلة متاحة في الإصدار المدفوع.'),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Drug Header ---
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image Placeholder or CachedNetworkImage
                SizedBox(
                  width: 80,
                  height: 80,
                  child: ClipRRect(
                    // Clip image to rounded corners
                    borderRadius: BorderRadius.circular(8.0),
                    child:
                        drug.imageUrl != null && drug.imageUrl!.isNotEmpty
                            ? CachedNetworkImage(
                              imageUrl: drug.imageUrl!,
                              placeholder:
                                  (context, url) => Container(
                                    color: Colors.grey.shade200,
                                    child: const Center(
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.0,
                                      ),
                                    ),
                                  ),
                              errorWidget:
                                  (context, url, error) => Container(
                                    // Placeholder on error
                                    color: Colors.grey.shade200,
                                    child: const Icon(
                                      Icons.medication_outlined,
                                      color: Colors.grey,
                                      size: 40,
                                    ),
                                  ),
                              fit: BoxFit.cover,
                            )
                            : Container(
                              // Placeholder if no image URL
                              color: Colors.grey.shade200,
                              child: const Icon(
                                Icons.medication_outlined,
                                color: Colors.grey,
                                size: 40,
                              ),
                            ),
                  ),
                ),
                const SizedBox(width: 16.0),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        drug.tradeName,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      if (drug.arabicName.isNotEmpty &&
                          drug.arabicName != drug.tradeName)
                        Text(
                          drug.arabicName,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      const SizedBox(height: 4.0),
                      Text(
                        drug.active, // Active Ingredient
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16.0),

            // --- Price Section ---
            Card(
              elevation: 1,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'السعر الحالي:',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      '${drug.price} جنيه',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Divider(height: 24.0),

            // --- Details Section ---
            Text('التفاصيل:', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8.0),
            _buildDetailRow('الشركة', drug.company),
            _buildDetailRow('الفئة الرئيسية', drug.mainCategory),
            // _buildDetailRow('الفئة الفرعية', drug.category), // Removed as 'category' is not in DrugEntity
            _buildDetailRow('الشكل الصيدلي', drug.dosageForm),
            _buildDetailRow('الوحدة', drug.unit),
            _buildDetailRow('الاستخدام', drug.usage),
            _buildDetailRow('الوصف', drug.description),
            _buildDetailRow('آخر تحديث للسعر', drug.lastPriceUpdate),

            const Divider(height: 24.0),

            // --- Actions ---
            Center(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.sync_alt),
                label: const Text('إيجاد البدائل'),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder:
                          (_) => ChangeNotifierProvider(
                            create:
                                (_) => AlternativesProvider(
                                  findDrugAlternativesUseCase:
                                      findAlternativesUseCase,
                                ),
                            child: AlternativesScreen(originalDrug: drug),
                          ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16.0),
            // TODO: Add Interaction Check Button/Section later
          ],
        ),
      ),
    );
  }

  // Helper to build detail row
  Widget _buildDetailRow(String label, String value) {
    if (value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.w600)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
