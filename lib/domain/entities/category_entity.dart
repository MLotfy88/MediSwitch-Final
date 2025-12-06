import 'package:equatable/equatable.dart';

class CategoryEntity extends Equatable {
  final String id;
  final String name;
  final String nameAr;
  final String? icon;
  final String? color;
  final int drugCount;

  const CategoryEntity({
    required this.id,
    required this.name,
    required this.nameAr,
    this.icon,
    this.color,
    this.drugCount = 0,
  });

  @override
  List<Object?> get props => [id, name, nameAr, icon, color, drugCount];
}
