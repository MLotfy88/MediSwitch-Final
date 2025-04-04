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

  @override
  List<Object?> get props => [name, arabicName, alternativeNames];
}
