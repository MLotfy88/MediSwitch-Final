class MedicineModel {
  final String tradeName;
  final String arabicName;
  final String oldPrice;
  final String price;
  final String active;
  final String mainCategory;
  final String mainCategoryAr;
  final String category;
  final String categoryAr;
  final String company;
  final String dosageForm;
  final String dosageFormAr;
  final String unit;
  final String usage;
  final String usageAr;
  final String description;
  final String lastPriceUpdate;

  // معرف اختياري للاستخدام مع قاعدة البيانات
  final int? id;

  MedicineModel({
    required this.tradeName,
    required this.arabicName,
    required this.oldPrice,
    required this.price,
    required this.active,
    required this.mainCategory,
    required this.mainCategoryAr,
    required this.category,
    required this.categoryAr,
    required this.company,
    required this.dosageForm,
    required this.dosageFormAr,
    required this.unit,
    required this.usage,
    required this.usageAr,
    required this.description,
    required this.lastPriceUpdate,
    this.id,
  });

  factory MedicineModel.fromCsv(List<dynamic> row) {
    return MedicineModel(
      tradeName: row[0] ?? '',
      arabicName: row[1] ?? '',
      oldPrice: row[2] ?? '',
      price: row[3] ?? '',
      active: row[4] ?? '',
      mainCategory: row[5] ?? '',
      mainCategoryAr: row[6] ?? '',
      category: row[7] ?? '',
      categoryAr: row[8] ?? '',
      company: row[9] ?? '',
      dosageForm: row[10] ?? '',
      dosageFormAr: row[11] ?? '',
      unit: row[12] ?? '',
      usage: row[13] ?? '',
      usageAr: row[14] ?? '',
      description: row[15] ?? '',
      lastPriceUpdate: row[16] ?? '',
    );
  }

  // تحويل النموذج إلى Map لاستخدامه مع قاعدة البيانات
  Map<String, dynamic> toMap() {
    return {
      'tradeName': tradeName,
      'arabicName': arabicName,
      'oldPrice': oldPrice,
      'price': price,
      'active': active,
      'mainCategory': mainCategory,
      'mainCategoryAr': mainCategoryAr,
      'category': category,
      'categoryAr': categoryAr,
      'company': company,
      'dosageForm': dosageForm,
      'dosageFormAr': dosageFormAr,
      'unit': unit,
      'usage': usage,
      'usageAr': usageAr,
      'description': description,
      'lastPriceUpdate': lastPriceUpdate,
    };
  }

  // إنشاء نموذج من Map من قاعدة البيانات
  factory MedicineModel.fromMap(Map<String, dynamic> map) {
    return MedicineModel(
      id: map['id'],
      tradeName: map['tradeName'] ?? '',
      arabicName: map['arabicName'] ?? '',
      oldPrice: map['oldPrice'] ?? '',
      price: map['price'] ?? '',
      active: map['active'] ?? '',
      mainCategory: map['mainCategory'] ?? '',
      mainCategoryAr: map['mainCategoryAr'] ?? '',
      category: map['category'] ?? '',
      categoryAr: map['categoryAr'] ?? '',
      company: map['company'] ?? '',
      dosageForm: map['dosageForm'] ?? '',
      dosageFormAr: map['dosageFormAr'] ?? '',
      unit: map['unit'] ?? '',
      usage: map['usage'] ?? '',
      usageAr: map['usageAr'] ?? '',
      description: map['description'] ?? '',
      lastPriceUpdate: map['lastPriceUpdate'] ?? '',
    );
  }

  @override
  String toString() {
    return '$tradeName - $arabicName - $price';
  }
}
