import 'dart:async'; // Import Timer for debounce
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../domain/entities/drug_entity.dart'; // Use DrugEntity
import '../bloc/alternatives_provider.dart'; // Import AlternativesProvider
import '../bloc/medicine_provider.dart'; // Corrected provider path
import '../screens/alternatives_screen.dart'; // Import AlternativesScreen
import '../widgets/filter_bottom_sheet.dart'; // Import the bottom sheet widget
import '../../main.dart'; // Import MyApp to access findDrugAlternativesUseCase (temporary DI)
import '../../domain/usecases/find_drug_alternatives.dart'; // Import use case for provider creation

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = '';
  Timer? _debounce; // Timer for search debounce

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel(); // Cancel timer on dispose
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
          // Add Filter Button
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              // Open the FilterBottomSheet
              showModalBottomSheet(
                context: context,
                isScrollControlled: true, // Allows sheet to take up more height
                // Use the MedicineProvider from the current context
                builder:
                    (_) => ChangeNotifierProvider.value(
                      value: context.read<MedicineProvider>(),
                      child: const FilterBottomSheet(),
                    ),
              );
            },
            tooltip: 'فلترة حسب الفئة',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed:
                isLoading
                    ? null
                    : () {
                      // Disable while loading
                      medicineProvider.loadInitialData(); // Use renamed method
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
                    // Debounce logic
                    if (_debounce?.isActive ?? false) _debounce!.cancel();
                    _debounce = Timer(const Duration(milliseconds: 500), () {
                      if (mounted) {
                        // Check if widget is still mounted
                        context.read<MedicineProvider>().setSearchQuery(
                          value,
                        ); // Use context.read inside async callback
                      }
                    });
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
      // Provide FindDrugAlternativesUseCase to the builder context
      // This requires access to the use case instance, assuming it's available via MyApp
      builder: (builderContext) {
        // Use a different context name
        final findAlternativesUseCase =
            Provider.of<MyApp>(
              context,
              listen: false,
            ).findDrugAlternativesUseCase; // Temporary access via MyApp context
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
                // Display additional details
                _buildDetailRow('المادة الفعالة', drug.active),
                _buildDetailRow('الشركة', drug.company),
                _buildDetailRow('الشكل الصيدلي', drug.dosageForm),
                _buildDetailRow('الوحدة', drug.unit),
                _buildDetailRow('الاستخدام', drug.usage),
                _buildDetailRow('الوصف', drug.description),
                _buildDetailRow('آخر تحديث للسعر', drug.lastPriceUpdate),
                const SizedBox(height: 16),
                // Add "Find Alternatives" Button (Task 3.2.9)
                Center(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.sync_alt),
                    label: const Text('إيجاد البدائل'),
                    onPressed: () {
                      Navigator.pop(
                        builderContext,
                      ); // Close the bottom sheet first using builderContext
                      Navigator.push(
                        context, // Use the original context for navigation
                        MaterialPageRoute(
                          builder:
                              (_) => ChangeNotifierProvider(
                                // Use the use case obtained earlier
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
                // Add Favorite Button (Premium - Task 3.2.10)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8.0), // Add some space
                    child: OutlinedButton.icon(
                      icon: const Icon(
                        Icons.favorite_border,
                        size: 18,
                      ), // Or Icons.favorite if favorited
                      label: const Text('إضافة للمفضلة (Premium)'),
                      onPressed: null, // Disabled for now
                      // onPressed: () {
                      //   // TODO: Implement Premium check and favorite logic
                      //   ScaffoldMessenger.of(context).showSnackBar(
                      //     const SnackBar(content: Text('ميزة المفضلة متاحة في الإصدار المدفوع.')),
                      //   );
                      // },
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.red.withOpacity(0.5)),
                        foregroundColor: Colors.red.withOpacity(0.7),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8), // Bottom padding
              ], // Closing children list for Column
            ), // Closing Column
          ), // Closing SingleChildScrollView
        ); // Closing Container
      }, // Closing builder
    ); // Closing showModalBottomSheet
  } // Closing _showMedicineDetails

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
} // Closing State class
