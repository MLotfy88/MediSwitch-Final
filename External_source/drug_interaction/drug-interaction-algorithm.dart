// import 'dart:collection';
// 
// class MultiDrugInteractionAnalyzer {
//   // معرف خاص للكائن الحالي (لتحسين الأداء في الخوارزميات المعقدة)
//   static int _nextId = 0;
//   
//   // تحليل التفاعلات بين مجموعة من الأدوية
//   // هذه الخوارزمية تحلل التفاعلات المباشرة وغير المباشرة مع أخذ التراكمية بعين الاعتبار
//   static Map<String, dynamic> analyzeInteractions(List<String> medicineNames) {
//     // إعادة تعيين مُعرف الكائن
//     _nextId = 0;
//     
//     // قائمة تفاعلات الدواء الثنائية
//     List<Map<String, dynamic>> pairwiseInteractions = DrugInteractionDatabase.findMultipleMedicineInteractions(medicineNames);
//     
//     // بناء رسم بياني للتفاعلات
//     final graph = _buildInteractionGraph(medicineNames, pairwiseInteractions);
//     
//     // حساب التفاعلات التراكمية باستخدام خوارزمية الاستكشاف بالعمق (DFS)
//     final List<Map<String, dynamic>> paths = _findInteractionPaths(graph);
//     
//     // تحديد المستوى الإجمالي للتفاعلات
//     InteractionSeverity overallSeverity = _calculateOverallSeverity(pairwiseInteractions);
//     
//     // تحديد التوصيات والتحذيرات استنادًا إلى التفاعلات
//     final recommendations = _generateRecommendations(pairwiseInteractions, paths);
//     
//     return {
//       'pairwise_interactions': pairwiseInteractions,
//       'interaction_paths': paths,
//       'overall_severity': overallSeverity.toString().split('.').last,
//       'requires_attention': overallSeverity.index >= InteractionSeverity.moderate.index,
//       'recommendations': recommendations,
//     };
//   }
//   
//   // بناء رسم بياني للتفاعلات بين الأدوية
//   static Map<String, Map<String, List<DrugInteraction>>> _buildInteractionGraph(
//     List<String> medicineNames, 
//     List<Map<String, dynamic>> pairwiseInteractions
//   ) {
//     // رسم بياني يمثل الأدوية والتفاعلات بينها
//     Map<String, Map<String, List<DrugInteraction>>> graph = {};
//     
//     // إعداد القائمة الفارغة لكل دواء
//     for (final name in medicineNames) {
//       graph[name] = {};
//     }
//     
//     // إضافة التفاعلات إلى الرسم البياني
//     for (final interaction in pairwiseInteractions) {
//       final medicine1 = interaction['medicine1'];
//       final medicine2 = interaction['medicine2'];
//       final interactions = interaction['interactions'] as List<DrugInteraction>;
//       
//       // إضافة التفاعلات في كلا الاتجاهين (رسم بياني غير موجه)
//       if (!graph[medicine1]!.containsKey(medicine2)) {
//         graph[medicine1]![medicine2] = [];
//       }
//       graph[medicine1]![medicine2]!.addAll(interactions);
//       
//       if (!graph[medicine2]!.containsKey(medicine1)) {
//         graph[medicine2]![medicine1] = [];
//       }
//       graph[medicine2]![medicine1]!.addAll(interactions);
//     }
//     
//     return graph;
//   }
//   
//   // البحث عن مسارات التفاعل باستخدام خوارزمية الاستكشاف بالعمق (DFS)
//   static List<Map<String, dynamic>> _findInteractionPaths(
//     Map<String, Map<String, List<DrugInteraction>>> graph
//   ) {
//     List<Map<String, dynamic>> paths = [];
//     Set<String> visited = {};
//     
//     // إنشاء كائنات لكل دواء في الرسم البياني
//     final medicines = graph.keys.map((name) => _DrugNode(++_nextId, name)).toList();
//     
//     // بدء الاستكشاف من كل دواء
//     for (final startNode in medicines) {
//       if (!visited.contains(startNode.name)) {
//         List<_DrugNode> currentPath = [startNode];
//         _dfs(graph, startNode, visited, currentPath, paths);
//       }
//     }
//     
//     return paths;
//   }
//   
//   // خوارزمية الاستكشاف بالعمق
//   static void _dfs(
//     Map<String, Map<String, List<DrugInteraction>>> graph,
//     _DrugNode current,
//     Set<String> visited,
//     List<_DrugNode> currentPath,
//     List<Map<String, dynamic>> paths
//   ) {
//     visited.add(current.name);
//     
//     // استكشاف كل الأدوية المرتبطة بالدواء الحالي
//     for (final neighborName in graph[current.name]!.keys) {
//       // تجنب تكرار زيارة نفس الدواء
//       if (visited.contains(neighborName)) continue;
//       
//       // المؤشر على الدواء المجاور
//       final neighbor = _DrugNode(++_nextId, neighborName);
//       
//       // التفاعلات بين الدواء الحالي والمجاور
//       final interactions = graph[current.name]![neighborName]!;
//       
//       // إذا كانت هناك تفاعلات، نسجل المسار
//       if (interactions.isNotEmpty) {
//         currentPath.add(neighbor);
//         
//         // إذا كان المسار يحتوي على 3 أدوية أو أكثر، نضيفه إلى القائمة
//         if (currentPath.length >= 3) {
//           List<String> pathNames = currentPath.map((node) => node.name).toList();
//           InteractionSeverity pathSeverity = _calculatePathSeverity(graph, currentPath);
//           
//           paths.add({
//             'path': pathNames,
//             'severity': pathSeverity.toString().split('.').last,
//             'description': _generatePathDescription(pathNames, pathSeverity),
//           });
//         }
//         
//         // استمرار الاستكشاف
//         _dfs(graph, neighbor, visited, currentPath, paths);
//         
//         // حذف الدواء المجاور من المسار الحالي عند العودة
//         currentPath.removeLast();
//       }
//     }
//   }
//   
//   // حساب شدة التفاعل في مسار معين
//   static InteractionSeverity _calculatePathSeverity(
//     Map<String, Map<String, List<DrugInteraction>>> graph,
//     List<_DrugNode> path
//   ) {
//     InteractionSeverity maxSeverity = InteractionSeverity.minor;
//     
//     // فحص التفاعلات بين كل زوج متتالي في المسار
//     for (int i = 0; i < path.length - 1; i++) {
//       final drug1 = path[i].name;
//       final drug2 = path[i + 1].name;
//       
//       final interactions = graph[drug1]![drug2]!;
//       for (final interaction in interactions) {
//         if (interaction.severity.index > maxSeverity.index) {
//           maxSeverity = interaction.severity;
//         }
//       }
//     }
//     
//     return maxSeverity;
//   }
//   
//   // حساب المستوى الإجمالي للتفاعلات
//   static InteractionSeverity _calculateOverallSeverity(List<Map<String, dynamic>> pairwiseInteractions) {
//     InteractionSeverity maxSeverity = InteractionSeverity.minor;
//     
//     for (final pair in pairwiseInteractions) {
//       final interactions = pair['interactions'] as List<DrugInteraction>;
//       for (final interaction in interactions) {
//         if (interaction.severity.index > maxSeverity.index) {
//           maxSeverity = interaction.severity;
//         }
//       }
//     }
//     
//     return maxSeverity;
//   }
//   
//   // إنشاء وصف لمسار تفاعل
//   static String _generatePathDescription(List<String> path, InteractionSeverity severity) {
//     final severityDesc = _getSeverityDescription(severity);
//     return 'تفاعل ${severityDesc} بين ${path.join(' و ')}';
//   }
//   
//   // الحصول على وصف لشدة التفاعل
//   static String _getSeverityDescription(InteractionSeverity severity) {
//     switch (severity) {
//       case InteractionSeverity.minor:
//         return 'بسيط';
//       case InteractionSeverity.moderate:
//         return 'متوسط';
//       case InteractionSeverity.major:
//         return 'كبير';
//       case InteractionSeverity.severe:
//         return 'شديد';
//       case InteractionSeverity.contraindicated:
//         return 'مضاد استطباب';
//       default:
//         return 'غير معروف';
//     }
//   }
//   
//   // إنشاء توصيات بناءً على التفاعلات
//   static List<Map<String, dynamic>> _generateRecommendations(
//     List<Map<String, dynamic>> pairwiseInteractions,
//     List<Map<String, dynamic>> paths
//   ) {
//     List<Map<String, dynamic>> recommendations = [];
//     
//     // التوصيات المبنية على التفاعلات الثنائية
//     for (final pair in pairwiseInteractions) {
//       final medicine1 = pair['medicine1'];
//       final medicine2 = pair['medicine2'];
//       final interactions = pair['interactions'] as List<DrugInteraction>;
//       
//       // البحث عن أعلى مستوى من التفاعل
//       InteractionSeverity maxSeverity = DrugInteractionDatabase.getHighestSeverity(interactions);
//       
//       // إنشاء توصية بناءً على شدة التفاعل
//       if (maxSeverity.index >= InteractionSeverity.moderate.index) {
//         recommendations.add({
//           'type': 'pair',
//           'medicines': [medicine1, medicine2],
//           'severity': maxSeverity.toString().split('.').last,
//           'recommendation': _getRecommendationForSeverity(maxSeverity, medicine1, medicine2),
//         });
//       }
//     }
//     
//     // التوصيات المبنية على مسارات التفاعل (للتفاعلات غير المباشرة)
//     for (final path in paths) {
//       final pathMedicines = path['path'] as List<String>;
//       final severity = InteractionSeverity.values.firstWhere(
//         (s) => s.toString().split('.').last == path['severity'],
//         orElse: () => InteractionSeverity.minor,
//       );
//       
//       // إضافة توصية فقط للمسارات ذات التفاعلات المهمة
//       if (severity.index >= InteractionSeverity.major.index) {
//         recommendations.add({
//           'type': 'path',
//           'medicines': pathMedicines,
//           'severity': severity.toString().split('.').last,
//           'recommendation': 'يجب مراقبة التفاعل التسلسلي بين ${pathMedicines.join(' و ')}',
//         });
//       }
//     }
//     
//     return recommendations;
//   }
//   
//   // الحصول على توصية بناءً على شدة التفاعل
//   static String _getRecommendationForSeverity(InteractionSeverity severity, String medicine1, String medicine2) {
//     switch (severity) {
//       case InteractionSeverity.contraindicated:
//         return 'لا يجب استخدام $medicine1 و $medicine2 معًا أبدًا';
//       case InteractionSeverity.severe:
//         return 'يفضل تجنب استخدام $medicine1 و $medicine2 معًا، والبحث عن بدائل';
//       case InteractionSeverity.major:
//         return 'يجب مراقبة المريض بعناية عند استخدام $medicine1 و $medicine2 معًا';
//       case InteractionSeverity.moderate:
//         return 'قد يحتاج المريض لتعديل الجرعة عند استخدام $medicine1 و $medicine2 معًا';
//       default:
//         return 'مراقبة طبيعية عند استخدام $medicine1 و $medicine2 معًا';
//     }
//   }
// }
// 
// // فئة مساعدة لتمثيل العقد في خوارزمية الاستكشاف بالعمق
// class _DrugNode {
//   final int id;  // معرف فريد للعقدة
//   final String name;  // اسم الدواء
//   
//   _DrugNode(this.id, this.name);
//   
//   @override
//   bool operator ==(Object other) {
//     if (identical(this, other)) return true;
//     return other is _DrugNode && other.id == id;
//   }
//   
//   @override
//   int get hashCode => id.hashCode;
// }
//
