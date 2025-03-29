import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/models/medicine_model.dart'; // Keep for details temporarily? No, use Entity.
import '../../domain/entities/drug_entity.dart'; // Use DrugEntity
import '../bloc/medicine_provider.dart'; // Corrected provider path

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Use watch for continuous listening, or select for specific properties
    final medicineProvider = context.watch<MedicineProvider>();
    final medicines =
        medicineProvider.filteredMedicines; // Now List<DrugEntity>
    final isLoading = medicineProvider.isLoading;
    final error = medicineProvider.error;
    final categories = medicineProvider.categories;

    return Scaffold(
      appBar: AppBar(
        title: const Text('MediSwitch'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed:
                isLoading
                    ? null
                    : () {
                      // Disable while loading
                      medicineProvider.loadMedicines();
                    },
            tooltip: 'تحديث البيانات',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Search Field
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    labelText: 'بحث عن دواء',
                    hintText: 'أدخل اسم الدواء',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    suffixIcon:
                        _searchController.text.isNotEmpty
                            ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                medicineProvider.setSearchQuery('');
                              },
                            )
                            : null,
                  ),
                  onChanged: (value) {
                    medicineProvider.setSearchQuery(value);
                  },
                ),
                const SizedBox(height: 16.0),
                // Category Chips
                if (categories.isNotEmpty)
                  SizedBox(
                    height: 50,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4.0),
                          child: ChoiceChip(
                            label: const Text('الكل'),
                            selected: _selectedCategory.isEmpty,
                            onSelected: (selected) {
                              if (selected) {
                                setState(() {
                                  _selectedCategory = '';
                                });
                                medicineProvider.setCategory('');
                              }
                            },
                          ),
                        ),
                        ...categories.map((category) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4.0,
                            ),
                            child: ChoiceChip(
                              label: Text(category),
                              selected: _selectedCategory == category,
                              onSelected: (selected) {
                                if (selected) {
                                  setState(() {
                                    _selectedCategory = category;
                                  });
                                  medicineProvider.setCategory(category);
                                }
                              },
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          // Loading/Error Indicator
          if (isLoading)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else if (error.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(error, style: const TextStyle(color: Colors.red)),
            )
          // Medicine List
          else
            Expanded(
              child:
                  medicines.isEmpty
                      ? const Center(
                        child: Text('لا توجد أدوية متطابقة مع البحث'),
                      )
                      : ListView.builder(
                        itemCount: medicines.length,
                        itemBuilder: (context, index) {
                          final drug = medicines[index]; // Now DrugEntity
                          return Card(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 16.0,
                              vertical: 8.0,
                            ),
                            child: ListTile(
                              title: Text(
                                drug.tradeName, // Use DrugEntity field
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(drug.arabicName), // Use DrugEntity field
                                  const SizedBox(height: 4.0),
                                  Text(
                                    'السعر: ${drug.price} جنيه',
                                  ), // Use DrugEntity field
                                  if (drug.mainCategory.isNotEmpty)
                                    Text(
                                      'الفئة: ${drug.mainCategory}',
                                    ), // Use DrugEntity field
                                ],
                              ),
                              isThreeLine: true, // Adjust based on content
                              onTap: () {
                                // Pass DrugEntity to details
                                _showMedicineDetails(context, drug);
                              },
                            ),
                          );
                        },
                      ),
            ),
        ],
      ),
    );
  }

  // Show details using DrugEntity
  void _showMedicineDetails(BuildContext context, DrugEntity drug) {
    // Changed type to DrugEntity
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16.0),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 50,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                  ),
                ),
                const SizedBox(height: 16.0),
                Text(
                  drug.tradeName, // Use DrugEntity field
                  style: const TextStyle(
                    fontSize: 20.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8.0),
                Text(
                  drug.arabicName, // Use DrugEntity field
                  style: const TextStyle(fontSize: 18.0),
                ),
                const Divider(),
                _buildDetailRow(
                  'السعر الحالي',
                  '${drug.price} جنيه',
                ), // Use DrugEntity field
                _buildDetailRow(
                  'الفئة الرئيسية',
                  drug.mainCategory,
                ), // Use DrugEntity field
                // Add more details here later by adding fields to DrugEntity
                // and mapping them in DrugRepositoryImpl
                // Example: _buildDetailRow('الشركة المصنعة', drug.company),
              ],
            ),
          ),
        );
      },
    );
  }

  // Helper to build detail row (unchanged)
  Widget _buildDetailRow(String label, String value) {
    if (value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
