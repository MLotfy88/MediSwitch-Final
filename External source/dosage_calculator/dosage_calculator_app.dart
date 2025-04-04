// تطبيق حاسبة الجرعات الدوائية

import 'package:flutter/material.dart';
import 'dosage_calculator.dart';

void main() {
  runApp(const DosageCalculatorApp());
}

class DosageCalculatorApp extends StatelessWidget {
  const DosageCalculatorApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'حاسبة الجرعات الدوائية',
      theme: ThemeData(
        primarySwatch: Colors.teal,
        fontFamily: 'Cairo',
        textTheme: const TextTheme(
          headline6: TextStyle(fontWeight: FontWeight.bold),
          bodyText2: TextStyle(fontSize: 16),
        ),
      ),
      home: const DosageCalculatorScreen(),
      debugShowCheckedModeBanner: false,
      locale: const Locale('ar', 'EG'),
    );
  }
}

class DosageCalculatorScreen extends StatefulWidget {
  const DosageCalculatorScreen({Key? key}) : super(key: key);

  @override
  _DosageCalculatorScreenState createState() => _DosageCalculatorScreenState();
}

class _DosageCalculatorScreenState extends State<DosageCalculatorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _weightController = TextEditingController();
  final _ageController = TextEditingController();
  
  Medicine? _selectedMedicine;
  DosageResult? _dosageResult;
  
  // قائمة الأدوية المتاحة للاختيار
  final List<Medicine> _medicines = [
    Medicine(
      tradeName: 'Panadol',
      arabicName: 'بنادول',
      activeIngredient: 'paracetamol',
      dosageForm: 'tablet',
      dosageFormAr: 'أقراص',
      concentration: 500,
    ),
    Medicine(
      tradeName: 'Adol',
      arabicName: 'أدول',
      activeIngredient: 'paracetamol',
      dosageForm: 'syrup',
      dosageFormAr: 'شراب',
      concentration: 120,
    ),
    Medicine(
      tradeName: 'Brufen',
      arabicName: 'بروفين',
      activeIngredient: 'ibuprofen',
      dosageForm: 'tablet',
      dosageFormAr: 'أقراص',
      concentration: 400,
    ),
    Medicine(
      tradeName: 'Fevadol',
      arabicName: 'فيفادول',
      activeIngredient: 'ibuprofen',
      dosageForm: 'syrup',
      dosageFormAr: 'شراب',
      concentration: 100,
    ),
    Medicine(
      tradeName: 'Amoxil',
      arabicName: 'أموكسيل',
      activeIngredient: 'amoxicillin',
      dosageForm: 'capsule',
      dosageFormAr: 'كبسولة',
      concentration: 500,
    ),
    Medicine(
      tradeName: 'Amoxil',
      arabicName: 'أموكسيل',
      activeIngredient: 'amoxicillin',
      dosageForm: 'syrup',
      dosageFormAr: 'شراب',
      concentration: 125,
    ),
    Medicine(
      tradeName: 'Congestal',
      arabicName: 'كونجستال',
      activeIngredient: 'pseudoephedrine',
      dosageForm: 'tablet',
      dosageFormAr: 'أقراص',
      concentration: 60,
    ),
    Medicine(
      tradeName: 'Congestal',
      arabicName: 'كونجستال',
      activeIngredient: 'pseudoephedrine',
      dosageForm: 'syrup',
      dosageFormAr: 'شراب',
      concentration: 30,
    ),
  ];

  @override
  void dispose() {
    _weightController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  void _calculateDosage() {
    if (_formKey.currentState!.validate() && _selectedMedicine != null) {
      final double weight = double.parse(_weightController.text);
      final int age = int.parse(_ageController.text);
      
      setState(() {
        _dosageResult = DosageCalculator.calculateDosage(_selectedMedicine!, weight, age);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('حاسبة الجرعات الدوائية'),
        centerTitle: true,
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 20),
                  // اختيار الدواء
                  DropdownButtonFormField<Medicine>(
                    decoration: const InputDecoration(
                      labelText: 'اختر الدواء',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.medication),
                    ),
                    value: _selectedMedicine,
                    items: _medicines.map((medicine) {
                      return DropdownMenuItem<Medicine>(
                        value: medicine,
                        child: Text('${medicine.arabicName} (${medicine.tradeName}) - ${medicine.dosageFormAr} ${medicine.concentration} مجم'),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedMedicine = value;
                        _dosageResult = null; // إعادة تعيين النتيجة عند تغيير الدواء
                      });
                    },
                    validator: (value) {
                      if (value == null) {
                        return 'يرجى اختيار الدواء';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  // إدخال الوزن
                  TextFormField(
                    controller: _weightController,
                    decoration: const InputDecoration(
                      labelText: 'الوزن (كجم)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.monitor_weight),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'يرجى إدخال الوزن';
                      }
                      final double? weight = double.tryParse(value);
                      if (weight == null || weight <= 0) {
                        return 'يرجى إدخال وزن صحيح';
                      }
                      return null;
                    },
                    onChanged: (_) {
                      setState(() {
                        _dosageResult = null; // إعادة تعيين النتيجة عند تغيير الوزن
                      });
                    },
                  ),
                  const SizedBox(height: 20),
                  // إدخال العمر
                  TextFormField(
                    controller: _ageController,
                    decoration: const InputDecoration(
                      labelText: 'العمر (سنوات)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'يرجى إدخال العمر';
                      }
                      final int? age = int.tryParse(value);
                      if (age == null || age < 0) {
                        return 'يرجى إدخال عمر صحيح';
                      }
                      return null;
                    },
                    onChanged: (_) {
                      setState(() {
                        _dosageResult = null; // إعادة تعيين النتيجة عند تغيير العمر
                      });
                    },
                  ),
                  const SizedBox(height: 30),
                  // زر حساب الجرعة
                  ElevatedButton(
                    onPressed: _calculateDosage,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    child: const Text('حساب الجرعة'),
                  ),
                  const SizedBox(height: 30),
                  // عرض نتيجة حساب الجرعة
                  if (_dosageResult != null) ...[                    
                    Card(
                      elevation: 4,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'نتيجة حساب الجرعة:',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal),
                            ),
                            const Divider(),
                            const SizedBox(height: 10),
                            Text(
                              _dosageResult!.dosage,
                              style: const TextStyle(fontSize: 16),
                            ),
                            if (_dosageResult!.warning != null) ...[                              
                              const SizedBox(height: 15),
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.red.shade200),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.warning, color: Colors.red),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        _dosageResult!.warning!,
                                        style: TextStyle(color: Colors.red.shade800),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            if (_dosageResult!.notes != null) ...[                              
                              const SizedBox(height: 15),
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.blue.shade200),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.info, color: Colors.blue),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        _dosageResult!.notes!,
                                        style: TextStyle(color: Colors.blue.shade800),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'ملاحظة: هذه الحاسبة هي أداة مساعدة فقط ولا تغني عن استشارة الطبيب أو الصيدلي.',
                      style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}