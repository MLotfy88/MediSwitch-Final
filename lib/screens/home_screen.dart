import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/medicine.dart';
import '../main.dart';

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
    final medicineProvider = Provider.of<MedicineProvider>(context);
    // Removed duplicate declaration below
    final medicines =
        medicineProvider.filteredMedicines; // Use filtered list for display
    final isLoading = medicineProvider.isLoading;
    final error = medicineProvider.error;
    final categories =
        medicineProvider.categories; // Get categories from provider

    return Scaffold(
      appBar: AppBar(
        title: const Text('MediSwitch'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              medicineProvider.loadMedicines();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // حقل البحث
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
                // قائمة الفئات
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
          // عرض رسالة الخطأ إذا وجدت
          if (error.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(error, style: const TextStyle(color: Colors.red)),
            ),
          // عرض مؤشر التحميل أثناء تحميل البيانات
          if (isLoading)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          // عرض قائمة الأدوية
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
                          final medicine = medicines[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 16.0,
                              vertical: 8.0,
                            ),
                            child: ListTile(
                              title: Text(
                                medicine.tradeName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(medicine.arabicName),
                                  const SizedBox(height: 4.0),
                                  Text('السعر: ${medicine.price} جنيه'),
                                  if (medicine.mainCategory.isNotEmpty)
                                    Text('الفئة: ${medicine.mainCategory}'),
                                ],
                              ),
                              isThreeLine: true,
                              onTap: () {
                                // عرض تفاصيل الدواء عند النقر عليه
                                _showMedicineDetails(context, medicine);
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

  // عرض تفاصيل الدواء في نافذة منبثقة
  void _showMedicineDetails(BuildContext context, Medicine medicine) {
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
                  medicine.tradeName,
                  style: const TextStyle(
                    fontSize: 20.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8.0),
                Text(
                  medicine.arabicName,
                  style: const TextStyle(fontSize: 18.0),
                ),
                const Divider(),
                _buildDetailRow('السعر الحالي', '${medicine.price} جنيه'),
                if (medicine.oldPrice.isNotEmpty)
                  _buildDetailRow('السعر القديم', '${medicine.oldPrice} جنيه'),
                _buildDetailRow('الشركة المصنعة', medicine.company),
                _buildDetailRow('الفئة الرئيسية', medicine.mainCategoryAr),
                _buildDetailRow('الفئة الفرعية', medicine.categoryAr),
                _buildDetailRow('الشكل الدوائي', medicine.dosageFormAr),
                _buildDetailRow('الوحدة', medicine.unit),
                if (medicine.usage.isNotEmpty)
                  _buildDetailRow('الاستخدام', medicine.usageAr),
                if (medicine.description.isNotEmpty)
                  _buildDetailRow('الوصف', medicine.description),
                if (medicine.lastPriceUpdate.isNotEmpty)
                  _buildDetailRow('آخر تحديث للسعر', medicine.lastPriceUpdate),
              ],
            ),
          ),
        );
      },
    );
  }

  // بناء صف لعرض التفاصيل
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
