# توثيق مفصل لخوارزمية تفاعلات الأدوية

## نظرة عامة

خوارزمية تفاعلات الأدوية هي نظام متقدم لتحليل واكتشاف التفاعلات المحتملة بين الأدوية المختلفة. تم تصميم هذه الخوارزمية لتكون جزءًا من تطبيق MediSwitch، وتعمل بشكل متكامل مع قاعدة بيانات الأدوية الرئيسية. تهدف الخوارزمية إلى تحديد التفاعلات الثنائية والمتعددة بين الأدوية، وتصنيف شدتها، وتقديم توصيات للمستخدمين.

## هيكل البيانات

### 1. المكون النشط (ActiveIngredient)

```dart
class ActiveIngredient {
  final String name;               // اسم المكون النشط باللغة الإنجليزية
  final String arabicName;         // اسم المكون النشط باللغة العربية
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
```

### 2. مستوى شدة التفاعل (InteractionSeverity)

```dart
enum InteractionSeverity {
  minor,           // منخفض: تأثير بسيط، لا يتطلب تدخلاً عادةً
  moderate,        // متوسط: قد يتطلب مراقبة أو تعديل الجرعة
  major,           // عالي: يتطلب تدخلاً طبياً أو تغيير العلاج
  severe,          // شديد الخطورة: قد يسبب ضرراً كبيراً
  contraindicated, // مضاد استطباب: يجب تجنب الجمع بين الدوائين
}
```

### 3. نوع التفاعل (InteractionType)

```dart
enum InteractionType {
  pharmacokinetic,  // حركية الدواء: تأثير على امتصاص، توزيع، استقلاب أو إفراز الدواء
  pharmacodynamic,  // ديناميكية الدواء: تأثير على آلية عمل الدواء
  therapeutic,      // علاجي: تأثير على الفعالية العلاجية
  unknown,          // غير معروف: آلية غير محددة
}
```

### 4. التفاعل الدوائي (DrugInteraction)

```dart
class DrugInteraction {
  final String ingredient1;          // المكون النشط الأول
  final String ingredient2;          // المكون النشط الثاني
  final InteractionSeverity severity; // شدة التفاعل
  final InteractionType type;         // نوع التفاعل
  final String effect;                // تأثير التفاعل باللغة الإنجليزية
  final String arabicEffect;          // تأثير التفاعل باللغة العربية
  final String recommendation;        // التوصية باللغة الإنجليزية
  final String arabicRecommendation;  // التوصية باللغة العربية
  
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
}
```

## الخوارزميات المستخدمة

### 1. خوارزمية تحليل التفاعلات المتعددة

تستخدم هذه الخوارزمية نهج الرسم البياني (Graph-based approach) لتحليل التفاعلات بين مجموعة من الأدوية. تتكون الخوارزمية من الخطوات التالية:

#### أ. بناء الرسم البياني للتفاعلات

```dart
Map<String, Map<String, List<DrugInteraction>>> _buildInteractionGraph(
  List<String> medicineNames, 
  List<Map<String, dynamic>> pairwiseInteractions
) {
  // رسم بياني يمثل الأدوية والتفاعلات بينها
  Map<String, Map<String, List<DrugInteraction>>> graph = {};
  
  // إعداد القائمة الفارغة لكل دواء
  for (final name in medicineNames) {
    graph[name] = {};
  }
  
  // إضافة التفاعلات إلى الرسم البياني
  for (final interaction in pairwiseInteractions) {
    final medicine1 = interaction['medicine1'];
    final medicine2 = interaction['medicine2'];
    final interactions = interaction['interactions'] as List<DrugInteraction>;
    
    // إضافة التفاعلات في كلا الاتجاهين (رسم بياني غير موجه)
    if (!graph[medicine1]!.containsKey(medicine2)) {
      graph[medicine1]![medicine2] = [];
    }
    graph[medicine1]![medicine2]!.addAll(interactions);
    
    if (!graph[medicine2]!.containsKey(medicine1)) {
      graph[medicine2]![medicine1] = [];
    }
    graph[medicine2]![medicine1]!.addAll(interactions);
  }
  
  return graph;
}
```

#### ب. البحث عن مسارات التفاعل باستخدام خوارزمية الاستكشاف بالعمق (DFS)

```dart
List<Map<String, dynamic>> _findInteractionPaths(
  Map<String, Map<String, List<DrugInteraction>>> graph
) {
  List<Map<String, dynamic>> paths = [];
  Set<String> visited = {};
  
  // إنشاء كائنات لكل دواء في الرسم البياني
  final medicines = graph.keys.map((name) => _DrugNode(++_nextId, name)).toList();
  
  // بدء الاستكشاف من كل دواء
  for (final startNode in medicines) {
    if (!visited.contains(startNode.name)) {
      List<_DrugNode> currentPath = [startNode];
      _dfs(graph, startNode, visited, currentPath, paths);
    }
  }
  
  return paths;
}
```

#### ج. خوارزمية الاستكشاف بالعمق (DFS)

```dart
void _dfs(
  Map<String, Map<String, List<DrugInteraction>>> graph,
  _DrugNode current,
  Set<String> visited,
  List<_DrugNode> currentPath,
  List<Map<String, dynamic>> paths
) {
  visited.add(current.name);
  
  // استكشاف كل الأدوية المرتبطة بالدواء الحالي
  for (final neighborName in graph[current.name]!.keys) {
    // تجنب تكرار زيارة نفس الدواء
    if (visited.contains(neighborName)) continue;
    
    // المؤشر على الدواء المجاور
    final neighbor = _DrugNode(++_nextId, neighborName);
    
    // التفاعلات بين الدواء الحالي والمجاور
    final interactions = graph[current.name]![neighborName]!;
    
    // إذا كانت هناك تفاعلات، نسجل المسار
    if (interactions.isNotEmpty) {
      currentPath.add(neighbor);
      
      // إذا كان المسار يحتوي على 3 أدوية أو أكثر، نضيفه إلى القائمة
      if (currentPath.length >= 3) {
        List<String> pathNames = currentPath.map((node) => node.name).toList();
        InteractionSeverity pathSeverity = _calculatePathSeverity(graph, currentPath);
        
        paths.add({
          'path': pathNames,
          'severity': pathSeverity.toString().split('.').last,
          'description': _generatePathDescription(pathNames, pathSeverity),
        });
      }
      
      // استمرار الاستكشاف
      _dfs(graph, neighbor, visited, currentPath, paths);
      
      // حذف الدواء المجاور من المسار الحالي عند العودة
      currentPath.removeLast();
    }
  }
}
```

#### د. حساب شدة التفاعل في مسار معين

```dart
InteractionSeverity _calculatePathSeverity(
  Map<String, Map<String, List<DrugInteraction>>> graph,
  List<_DrugNode> path
) {
  InteractionSeverity maxSeverity = InteractionSeverity.minor;
  
  // فحص التفاعلات بين كل زوج متتالي في المسار
  for (int i = 0; i < path.length - 1; i++) {
    final drug1 = path[i].name;
    final drug2 = path[i + 1].name;
    
    final interactions = graph[drug1]![drug2]!;
    for (final interaction in interactions) {
      if (interaction.severity.index > maxSeverity.index) {
        maxSeverity = interaction.severity;
      }
    }
  }
  
  return maxSeverity;
}
```

### 2. خوارزمية توليد التوصيات

```dart
List<String> _generateRecommendations(
  List<Map<String, dynamic>> pairwiseInteractions,
  List<Map<String, dynamic>> paths
) {
  List<String> recommendations = [];
  
  // توصيات بناءً على التفاعلات الثنائية
  for (final pair in pairwiseInteractions) {
    final medicine1 = pair['medicine1'];
    final medicine2 = pair['medicine2'];
    final interactions = pair['interactions'] as List<DrugInteraction>;
    
    for (final interaction in interactions) {
      if (interaction.severity.index >= InteractionSeverity.moderate.index) {
        recommendations.add(
          "${_getSeverityArabicName(interaction.severity)}: ${interaction.arabicEffect.isNotEmpty ? interaction.arabicEffect : interaction.effect} بين ${medicine1} و ${medicine2}. ${interaction.arabicRecommendation.isNotEmpty ? interaction.arabicRecommendation : interaction.recommendation}"
        );
      }
    }
  }
  
  // توصيات بناءً على مسارات التفاعل المتعددة
  for (final path in paths) {
    final pathDrugs = path['path'] as List<String>;
    final severity = path['severity'] as String;
    
    if (_getSeverityFromString(severity).index >= InteractionSeverity.major.index) {
      recommendations.add(
        "تفاعل متعدد ${_getSeverityArabicName(_getSeverityFromString(severity))}: تم اكتشاف تفاعل متعدد بين ${pathDrugs.join(' و ')}. يرجى استشارة الطبيب."
      );
    }
  }
  
  return recommendations;
}
```

## تكامل خوارزمية تفاعلات الأدوية مع قاعدة البيانات

### 1. قراءة بيانات الأدوية من ملف Excel

```dart
Future<void> loadMedicines() async {
  try {
    // الحصول على مسار التطبيق
    final directory = await getApplicationDocumentsDirectory();
    final excelFile = File('${directory.path}/assets/medicines_database.xlsx');
    
    // إذا لم يكن الملف موجودًا، نسخه من أصول التطبيق
    if (!await excelFile.exists()) {
      final byteData = await rootBundle.load('assets/medicines_database.xlsx');
      await excelFile.writeAsBytes(byteData.buffer.asUint8List());
    }
    
    // قراءة ملف الإكسل
    final bytes = await excelFile.readAsBytes();
    final excel = Excel.decodeBytes(bytes);
    
    final sheet = excel.tables.keys.first;
    final table = excel.tables[sheet]!;
    
    // قراءة رؤوس الأعمدة
    List<String> headers = [];
    for (var cell in table.rows[0]) {
      headers.add(cell?.value.toString() ?? '');
    }
    
    // قراءة بيانات الأدوية
    _medicines = [];
    for (int i = 1; i < table.rows.length; i++) {
      final row = table.rows[i];
      final rowData = row.map((cell) => cell?.value).toList();
      _medicines.add(Medicine.fromExcelRow(rowData, headers));
    }
    
    print('تم تحميل ${_medicines.length} دواء من قاعدة البيانات');
  } catch (e) {
    print('خطأ في تحميل بيانات الأدوية: $e');
  }
}
```

### 2. تحميل قاعدة بيانات التفاعلات

```dart
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
    
    // تحميل قائمة الأدوية والمكونات النشطة
    final String medicineIngredientsJson = await rootBundle.loadString('assets/data/medicine_ingredients.json');
    _medicineToIngredients = Map<String, List<String>>.from(json.decode(medicineIngredientsJson));
    
    print('تم تحميل ${_activeIngredients.length} مكون نشط و ${_interactions.length} تفاعل دوائي');
  } catch (e) {
    print('خطأ في تحميل قاعدة بيانات التفاعلات: $e');
  }
}
```

### 3. البحث عن التفاعلات بين الأدوية

```dart
static List<Map<String, dynamic>> findMultipleMedicineInteractions(List<String> medicineNames) {
  List<Map<String, dynamic>> results = [];
  
  // الحصول على جميع أزواج الأدوية الممكنة
  for (int i = 0; i < medicineNames.length; i++) {
    for (int j = i + 1; j < medicineNames.length; j++) {
      final medicine1 = medicineNames[i];
      final medicine2 = medicineNames[j];
      
      // البحث عن التفاعلات بين الدوائين
      final interactions = findInteractionsBetweenMedicines(medicine1, medicine2);
      
      if (interactions.isNotEmpty) {
        results.add({
          'medicine1': medicine1,
          'medicine2': medicine2,
          'interactions': interactions,
        });
      }
    }
  }
  
  return results;
}
```

### 4. البحث عن التفاعلات بين دوائين

```dart
static List<DrugInteraction> findInteractionsBetweenMedicines(String medicine1, String medicine2) {
  // الحصول على المكونات النشطة للدوائين
  final ingredients1 = _getMedicineIngredients(medicine1);
  final ingredients2 = _getMedicineIngredients(medicine2);
  
  List<DrugInteraction> results = [];
  
  // البحث عن التفاعلات بين كل زوج من المكونات النشطة
  for (final ing1 in ingredients1) {
    for (final ing2 in ingredients2) {
      final interactions = _findInteractionsBetweenIngredients(ing1, ing2);
      results.addAll(interactions);
    }
  }
  
  return results;
}
```

## تنفيذ واجهة المستخدم

### 1. شاشة فحص التفاعلات الدوائية

```dart
class DrugInteractionScreen extends StatefulWidget {
  @override
  _DrugInteractionScreenState createState() => _DrugInteractionScreenState();
}

class _DrugInteractionScreenState extends State<DrugInteractionScreen> {
  List<Medicine> _selectedMedicines = [];
  Map<String, dynamic>? _interactionResults;
  bool _isLoading = false;
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('فحص تفاعلات الأدوية'),
        centerTitle: true,
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // قسم اختيار الأدوية
              Text(
                'اختر الأدوية المراد فحص تفاعلاتها:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              
              // قائمة الأدوية المختارة
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _selectedMedicines.map((medicine) => _buildMedicineChip(medicine)).toList(),
              ),
              
              // زر إضافة دواء
              OutlinedButton.icon(
                onPressed: _showMedicineSelectionDialog,
                icon: Icon(Icons.add),
                label: Text('إضافة دواء'),
              ),
              
              SizedBox(height: 16),
              
              // زر فحص التفاعلات
              ElevatedButton(
                onPressed: _selectedMedicines.length >= 2 ? _checkInteractions : null,
                child: Text('فحص التفاعلات'),
              ),
              
              SizedBox(height: 16),
              
              // عرض نتائج التفاعلات
              if (_isLoading)
                Center(child: CircularProgressIndicator()),
                
              if (_interactionResults != null && !_isLoading)
                Expanded(
                  child: _buildInteractionResults(),
                ),
            ],
          ),
        ),
      ),
    );
  }
  
  // بناء رقاقة الدواء المختار
  Widget _buildMedicineChip(Medicine medicine) {
    return Chip(
      label: Text(medicine.arabicName),
      deleteIcon: Icon(Icons.close, size: 18),
      onDeleted: () {
        setState(() {
          _selectedMedicines.remove(medicine);
          _interactionResults = null;
        });
      },
    );
  }
  
  // عرض مربع حوار اختيار الدواء
  void _showMedicineSelectionDialog() async {
    final Medicine? selected = await showDialog<Medicine>(
      context: context,
      builder: (context) => MedicineSelectionDialog(),
    );
    
    if (selected != null && !_selectedMedicines.contains(selected)) {
      setState(() {
        _selectedMedicines.add(selected);
        _interactionResults = null;
      });
    }
  }
  
  // فحص التفاعلات بين الأدوية المختارة
  void _checkInteractions() async {
    setState(() {
      _isLoading = true;
    });
    
    // تحويل الأدوية المختارة إلى قائمة أسماء
    final List<String> medicineNames = _selectedMedicines.map((m) => m.tradeName).toList();
    
    // استدعاء خوارزمية تحليل التفاعلات
    final results = await compute(
      MultiDrugInteractionAnalyzer.analyzeInteractions,
      medicineNames,
    );
    
    setState(() {
      _interactionResults = results;
      _isLoading = false;
    });
  }
  
  // بناء نتائج التفاعلات
  Widget _buildInteractionResults() {
    final pairwiseInteractions = _interactionResults!['pairwise_interactions'] as List<dynamic>;
    final overallSeverity = _interactionResults!['overall_severity'] as String;
    final recommendations = _interactionResults!['recommendations'] as List<String>;
    
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ملخص التفاعلات
          _buildSeveritySummary(overallSeverity),
          
          SizedBox(height: 16),
          
          // التوصيات
          if (recommendations.isNotEmpty) ...[            
            Text(
              'التوصيات:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            ...recommendations.map((rec) => _buildRecommendationItem(rec)).toList(),
            SizedBox(height: 16),
          ],
          
          // تفاصيل التفاعلات الثنائية
          Text(
            'تفاصيل التفاعلات:',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          ...pairwiseInteractions.map((pair) => _buildInteractionItem(pair)).toList(),
        ],
      ),
    );
  }
  
  // بناء ملخص شدة التفاعلات
  Widget _buildSeveritySummary(String severity) {
    Color color;
    String text;
    
    switch (severity) {
      case 'minor':
        color = Colors.green;
        text = 'تفاعلات بسيطة';
        break;
      case 'moderate':
        color = Colors.orange;
        text = 'تفاعلات متوسطة';
        break;
      case 'major':
        color = Colors.deepOrange;
        text = 'تفاعلات كبيرة';
        break;
      case 'severe':
        color = Colors.red;
        text = 'تفاعلات شديدة';
        break;
      case 'contraindicated':
        color = Colors.purple;
        text = 'تفاعلات مضادة للاستطباب';
        break;
      default:
        color = Colors.grey;
        text = 'غير معروف';
    }
    
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color),
      ),
      child: Row(
        children: [
          Icon(Icons.warning, color: color),
          SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(color: color, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
  
  // بناء عنصر توصية
  Widget _buildRecommendationItem(String recommendation) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, size: 18, color: Colors.blue),
          SizedBox(width: 8),
          Expanded(
            child: Text(recommendation),
          ),
        ],
      ),
    );
  }
  
  // بناء عنصر تفاعل
  Widget _buildInteractionItem(Map<String, dynamic> interaction) {
    final medicine1 = interaction['medicine1'] as String;
    final medicine2 = interaction['medicine2'] as String;
    final interactions = interaction['interactions'] as List<dynamic>;
    
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$medicine1 + $medicine2',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Divider(),
            ...interactions.map((interaction) => _buildInteractionDetail(interaction)).toList(),
          ],
        ),
      ),
    );
  }
  
  // بناء تفاصيل التفاعل
  Widget _buildInteractionDetail(DrugInteraction interaction) {
    Color color;
    
    switch (interaction.severity) {
      case InteractionSeverity.minor:
        color = Colors.green;
        break;
      case InteractionSeverity.moderate:
        color = Colors.orange;
        break;
      case InteractionSeverity.major:
        color = Colors.deepOrange;
        break;
      case InteractionSeverity.severe:
        color = Colors.red;
        break;
      case InteractionSeverity.contraindicated:
        color = Colors.purple;
        break;
      default:
        color = Colors.grey;
    }
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: color),
                ),
                child: Text(
                  _getSeverityArabicName(interaction.severity),
                  style: TextStyle(color: color, fontSize: 12),
                ),
              ),
              SizedBox(width: 8),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(