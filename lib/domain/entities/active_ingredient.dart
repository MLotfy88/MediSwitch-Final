// lib/domain/entities/active_ingredient.dart

import 'package:equatable/equatable.dart';

// نموذج المكون النشط للدواء في طبقة المجال
class ActiveIngredient extends Equatable {
  final String name; // اسم المكون النشط باللغة الإنجليزية (الموحد)
  final String arabicName; // اسم المكون النشط باللغة العربية (للعرض)
  final List<String> alternativeNames; // أسماء بديلة للمكون النشط (للمطابقة)

  const ActiveIngredient({
    required this.name,
    this.arabicName = '',
    this.alternativeNames = const [],
  });

  // Factory constructor to create an instance from JSON
  factory ActiveIngredient.fromJson(Map<String, dynamic> json) {
    return ActiveIngredient(
      name: json['name'] as String? ?? '',
      arabicName: json['arabic_name'] as String? ?? '', // Match JSON key
      // Ensure alternative_names is treated as a List<String>
      alternativeNames:
          (json['alternative_names'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
    );
  }

  @override
  List<Object?> get props => [name, arabicName, alternativeNames];
}
