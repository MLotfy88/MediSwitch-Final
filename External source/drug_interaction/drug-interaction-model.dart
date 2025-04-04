import 'dart:convert';
import 'package:flutter/services.dart';

// نموذج المكون النشط للدواء
class ActiveIngredient {
  final String name;
  final String arabicName;
  final List<String> alternativeNames; // أسماء بديلة للمكون النشط
  
  ActiveIngredient({
    required this.name,
    this.arabicName = '',
    this.alternativeNames = const [],
  });
  
  factory ActiveIngredient.fromJson(Map<String, dynamic> json) {
    return ActiveIngredient(
      name: json['name'],
      arabicName: json['arabic_name'] ?? '',
      alternativeNames: List<String>.from(json['alternative_names'] ?? []),
    );
  }
}

// مستوى شدة التفاعل
enum InteractionSeverity {
  minor,     // منخفض
  moderate,  // متوسط
  major,     // عالي
  severe,    // شديد الخطورة
  contraindicated, // مضاد استطباب
}

// نوع التفاعل
enum InteractionType {
  pharmacokinetic,  // حركية الدواء
  pharmacodynamic,  // ديناميكية الدواء
  therapeutic,      // علاجي
  unknown,          // غير معروف
}

// نموذج التفاعل الدوائي
class DrugInteraction {
  final String ingredient1;
  final String ingredient2;
  final InteractionSeverity severity;
  final InteractionType type;
  final String effect;
  final String arabicEffect;
  final String recommendation;
  final String arabicRecommendation;
  
  DrugInteraction({
    required this.ingredient1,
    required this.ingredient2,
    required this.severity,
    this.type = InteractionType.unknown,
    required this.effect,
    this.arabicEffect = '',
    required this.recommendation,
    this.arabicRecommendation = '',
  });
  
  factory DrugInteraction.fromJson(Map<String, dynamic> json) {
    return DrugInteraction(
      ingredient1: json['ingredient1'],
      ingredient2: json['ingredient2'],
      severity: InteractionSeverity.values.firstWhere(
        (e) => e.toString() == 'InteractionSeverity.${json['severity']}',
        orElse: () => InteractionSeverity.unknown,
      ),
      type: InteractionType.values.firstWhere(
        (e) => e.toString() == 'InteractionType.${json['type']}',
        orElse: () => InteractionType.unknown,
      ),
      effect: json['effect'],
      arabicEffect: json['arabic_effect'] ?? '',
      recommendation: json['recommendation'],
      arabicRecommendation: json['arabic_recommendation'] ?? '',
    );
  }
}

// قاعدة بيانات التفاعلات الدوائية
class DrugInteractionDatabase {
  static List<ActiveIngredient> _activeIngredients = [];
  static List<DrugInteraction> _interactions = [];
  static Map<String, List<String>> _medicineToIngredients = {};
  
  // تحميل قاعدة البيانات من ملفات JSON
  static Future<void> loadDatabase() async {
    try {
      // تحميل قائمة المكونات النشطة
      final String ingredientsJson = await rootBundle.loadString('assets/data/active_ingredients.json');
      final List<dynamic> ingredientsData = json.decode(ingredientsJson);
      _activeIngredients = ingredientsData.map((data) => ActiveIngredient.fromJson(data)).toList();
      
      // تحميل قائمة التفاعلات
      final String interactionsJson = await rootBundle.loadString('assets/data/drug_interactions.json');
      final List<dynamic> interactionsData = json.decode(interactionsJson);
      _interactions = interactionsData.map((data) => DrugInteraction.fromJson(data)).toList();
      
      // تحميل علاقة الأدوية بالمكونات النشطة
      final String medicineIngredientsJson = await rootBundle.loadString('assets/data/medicine_ingredients.json');
      final Map<String, dynamic> medicineIngredientsData = json.decode(medicineIngredientsJson);
      
      _medicineToIngredients = {};
      medicineIngredientsData.forEach((medicine, ingredients) {
        _medicineToIngredients[medicine] = List<String>.from(ingredients);
      });
      
      print('تم تحميل ${_activeIngredients.length} مكون نشط و ${_interactions.length} تفاعل دوائي');
    } catch (e) {
      print('خطأ في تحميل قاعدة بيانات التفاعلات: $e');
    }
  }
  
  // الحصول على المكونات النشطة لدواء معين
  static List<String> getIngredientsForMedicine(String medicineName) {
    return _medicineToIngredients[medicineName] ?? [];
  }
  
  // البحث عن التفاعلات بين مكونين نشطين
  static List<DrugInteraction> findInteractions(String ingredient1, String ingredient2) {
    return _interactions.where((interaction) =>
      (interaction.ingredient1 == ingredient1 && interaction.ingredient2 == ingredient2) ||
      (interaction.ingredient1 == ingredient2 && interaction.ingredient2 == ingredient1)
    ).toList();
  }
  
  // البحث عن التفاعلات بين دوائين
  static List<DrugInteraction> findMedicineInteractions(String medicine1, String medicine2) {
    final ingredients1 = getIngredientsForMedicine(medicine1);
    final ingredients2 = getIngredientsForMedicine(medicine2);
    
    List<DrugInteraction> interactions = [];
    
    // فحص كل المكونات النشطة في الدواء الأول مع المكونات النشطة في الدواء الثاني
    for (final ing1 in ingredients1) {
      for (final ing2 in ingredients2) {
        interactions.addAll(findInteractions(ing1, ing2));
      }
    }
    
    return interactions;
  }
  
  // البحث عن التفاعلات بين مجموعة أدوية
  static List<Map<String, dynamic>> findMultipleMedicineInteractions(List<String> medicines) {
    List<Map<String, dynamic>> results = [];
    
    // فحص كل الأزواج الممكنة من الأدوية
    for (int i = 0; i < medicines.length; i++) {
      for (int j = i + 1; j < medicines.length; j++) {
        final interactions = findMedicineInteractions(medicines[i], medicines[j]);
        
        if (interactions.isNotEmpty) {
          results.add({
            'medicine1': medicines[i],
            'medicine2': medicines[j],
            'interactions': interactions,
          });
        }
      }
    }
    
    return results;
  }
  
  // الحصول على أعلى مستوى شدة للتفاعلات بين مجموعة أدوية
  static InteractionSeverity getHighestSeverity(List<DrugInteraction> interactions) {
    if (interactions.isEmpty) return InteractionSeverity.minor;
    
    InteractionSeverity highest = InteractionSeverity.minor;
    
    for (final interaction in interactions) {
      if (interaction.severity.index > highest.index) {
        highest = interaction.severity;
      }
    }
    
    return highest;
  }
}
