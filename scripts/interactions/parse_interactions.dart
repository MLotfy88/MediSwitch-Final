import 'dart:io';
import 'dart:convert';

// --- Helper Functions ---

// يقدر درجة الخطورة بناءً على الكلمات المفتاحية
String estimateSeverity(String text) {
  text = text.toLowerCase();
  if (text.contains('contraindicated') ||
      text.contains('life-threatening') ||
      text.contains('severe, prolonged hypertension') ||
      text.contains('severe persistent hypertension')) {
    return 'contraindicated';
  }
  if (text.contains('severe') || text.contains('serious')) {
    return 'severe';
  }
  if (text.contains('major') || text.contains('significant')) {
    return 'major';
  }
  if (text.contains('moderate') ||
      text.contains('caution') ||
      text.contains('careful patient monitoring')) {
    return 'moderate';
  }
  if (text.contains('risk') ||
      text.contains('potential') ||
      text.contains('may lead to') ||
      text.contains('may increase') ||
      text.contains('may decrease') ||
      text.contains('may enhance') ||
      text.contains('may diminish') ||
      text.contains('may potentiate')) {
    return 'minor';
  }
  return 'unknown';
}

// يحاول استخلاص اسم الدواء المتفاعل (يستخدم كـ fallback)
String? extractInteractingDrugFallback(String textChunk) {
  final commonDrugs = [
    'aspirin',
    'warfarin',
    'cyclosporine',
    'lithium',
    'methotrexate',
    'digoxin',
    'ketoconazole',
    'phenytoin',
    'furosemide',
    'cisplatin',
    'diuretics',
    'antibiotics',
    'anticoagulants',
    'antidiabetics',
    'nsaids',
    'aminoglutethimide',
    'amphotericin b',
    'anticholinesterases',
    'cholestyramine',
    'estrogens',
    'vaccines',
    'pemetrexed',
  ];
  for (var drug in commonDrugs) {
    // يبحث عن الكلمة ككلمة كاملة
    if (RegExp(
      r'\b' + drug + r'\b',
      caseSensitive: false,
    ).hasMatch(textChunk)) {
      return drug;
    }
  }
  // يبحث عن كلمات بحرف كبير بعد كلمات الربط
  var regex = RegExp(
    r'(?:with|and|or|concomitantly with)\s+([A-Z][a-zA-Z]+(?:\s+[A-Z][a-zA-Z]+)*)',
  );
  var match = regex.firstMatch(textChunk);
  if (match != null) {
    return match.group(1);
  }
  // يبحث عن كلمات بحرف كبير في بداية الجملة (أقل دقة)
  regex = RegExp(r'^\s*([A-Z][a-zA-Z]+(?:\s+[A-Z][a-zA-Z]+)*)');
  match = regex.firstMatch(textChunk);
  if (match != null && match.group(1)!.length > 3) {
    // تجنب الكلمات القصيرة جداً
    // تجنب الكلمات الشائعة التي تبدأ بحرف كبير وليست أدوية بالضرورة
    final nonDrugStarters = [
      'The',
      'This',
      'It',
      'If',
      'When',
      'During',
      'Patients',
      'Routine',
      'Concurrent',
      'Therefore',
      'Because',
    ];
    if (!nonDrugStarters.contains(match.group(1))) {
      return match.group(1);
    }
  }
  return null;
}

// *** دالة التحليل المحسنة (الإصدار الخامس - تقسيم الجمل داخل الوصف) ***
List<Map<String, String?>> parseInteractionDetails(String? text) {
  if (text == null ||
      text.isEmpty ||
      text.toLowerCase().contains('no known drug interactions') ||
      text.toLowerCase().contains('non-greasy')) {
    return [];
  }

  final List<Map<String, String?>> interactions = [];
  // Regex to find potential interaction headers (Capitalized Name[, optional stuff] + Colon)
  final headerPattern = RegExp(
    r'([A-Z][a-zA-Z,\s]+(?:\s*,\s*oral)?)\s*:',
    multiLine: true,
  );
  final matches = headerPattern.allMatches(text).toList();
  int currentPos = 0;

  // دالة مساعدة لتحليل مقطع نصي (بتقسيمه إلى جمل)
  void analyzeChunk(String chunk, String? mainSubstance) {
    if (chunk.isEmpty) return;
    // تقسيم الجمل مع الحفاظ على بعض علامات الترقيم الهامة مثل الأقواس
    final sentences =
        chunk
            .split(RegExp(r'(?<=[.!?])\s+|\n'))
            .where((s) => s.trim().isNotEmpty)
            .toList();
    bool chunkInteractionAdded = false;
    for (final sentence in sentences) {
      final trimmedSentence = sentence.trim();
      if (trimmedSentence.isEmpty ||
          trimmedSentence.toLowerCase().startsWith('drug interactions') ||
          trimmedSentence.toLowerCase().startsWith('clinically significant'))
        continue;

      final severity = estimateSeverity(trimmedSentence);
      // محاولة استخلاص دواء من الجملة نفسها
      final sentenceSubstance = extractInteractingDrugFallback(trimmedSentence);

      // نضيف الجملة كتفاعل إذا كانت ذات معنى (طويلة كفاية أو لها خطورة/دواء محدد)
      if (trimmedSentence.length > 10 ||
          severity != 'unknown' ||
          sentenceSubstance != null) {
        interactions.add({
          // نستخدم الدواء المستخلص من الجملة، أو الدواء الرئيسي للمقطع، أو null
          'interacting_substance': sentenceSubstance ?? mainSubstance,
          'severity': severity,
          'description': trimmedSentence,
        });
        chunkInteractionAdded = true;
      }
    }
    // إذا لم يتم إضافة أي جملة من المقطع، ولكن المقطع نفسه طويل، نضيفه كاملاً
    if (!chunkInteractionAdded && chunk.length > 50) {
      interactions.add({
        'interacting_substance': mainSubstance, // نستخدم المادة الرئيسية للمقطع
        'severity': estimateSeverity(chunk),
        'description': chunk,
      });
    }
  }

  if (matches.isEmpty) {
    // لا يوجد نمط "الاسم :". نحلل النص كاملاً بتقسيم الجمل.
    analyzeChunk(text.trim(), null);
  } else {
    // وجدنا نمط "الاسم :"
    // 1. معالجة النص قبل أول تطابق
    String initialChunk = text.substring(0, matches.first.start).trim();
    if (initialChunk.isNotEmpty &&
        !initialChunk.toLowerCase().startsWith('drug interactions') &&
        !initialChunk.toLowerCase().startsWith('clinically significant')) {
      analyzeChunk(initialChunk, null); // لا يوجد مادة رئيسية لهذا المقطع
    }
    currentPos = matches.first.start;

    // 2. المرور على كل تطابق
    for (int i = 0; i < matches.length; i++) {
      final match = matches[i];
      final String mainSubstanceForChunk = match
          .group(1)!
          .trim()
          .replaceAll(RegExp(r'\s+,$'), ''); // الاسم قبل ":"
      final int descriptionStartIndex = match.end;
      final int descriptionEndIndex =
          (i + 1 < matches.length) ? matches[i + 1].start : text.length;
      final String descriptionChunk =
          text.substring(descriptionStartIndex, descriptionEndIndex).trim();

      // تحليل مقطع الوصف بتقسيمه إلى جمل
      analyzeChunk(descriptionChunk, mainSubstanceForChunk);

      currentPos = descriptionEndIndex;
    }

    // 3. معالجة النص المتبقي بعد آخر تطابق
    if (currentPos < text.length) {
      String finalChunk = text.substring(currentPos).trim();
      if (finalChunk.isNotEmpty) {
        analyzeChunk(finalChunk, null); // لا يوجد مادة رئيسية لهذا المقطع
      }
    }
  }

  // فلترة النتائج غير المفيدة (وصف قصير جداً بدون مادة متفاعلة أو خطورة معروفة)
  interactions.removeWhere(
    (item) =>
        item['interacting_substance'] == null &&
        item['severity'] == 'unknown' &&
        (item['description']?.length ?? 0) < 20,
  ); // زيادة طول الوصف المطلوب قليلاً

  // إذا لم ينتج أي شيء بعد كل هذا، نضيف النص الأصلي كـ fallback أخير (إذا كان ذا صلة)
  if (interactions.isEmpty &&
      text.isNotEmpty &&
      text.length > 10 &&
      (text.toLowerCase().contains('interaction') ||
          text.toLowerCase().contains('concomitant') ||
          text.toLowerCase().contains('risk'))) {
    interactions.add({
      'interacting_substance': null,
      'severity': 'unknown',
      'description': text.trim(),
    });
  }

  return interactions;
}

// --- Main Function --- (تبقى كما هي)
Future<void> main() async {
  final inputFile = File('drug-interactions.md');
  final outputFile = File('drug_interactions_structured_data.json');
  final lines = await inputFile.readAsLines();

  final List<Map<String, dynamic>> structuredData = [];

  for (int i = 1; i < lines.length; i++) {
    final line = lines[i].trim();
    if (line.isEmpty) continue;

    final parts = line.split('\t');
    final String activeIngredient = parts[0].trim();
    String? interactionsText = null;

    if (parts.length > 1) {
      interactionsText = parts.sublist(1).join('\t').trim();
      interactionsText = interactionsText.replaceAll(' | ', '\n').trim();
    }

    if (activeIngredient.isNotEmpty) {
      final parsedInteractions = parseInteractionDetails(interactionsText);

      // نضيف السجل فقط إذا كان هناك تفاعلات تم تحليلها
      // أو إذا كان النص الأصلي لا يشير بوضوح إلى عدم وجود تفاعلات
      if (parsedInteractions.isNotEmpty ||
          (interactionsText != null &&
              !interactionsText.toLowerCase().contains(
                'no known drug interactions',
              ) &&
              !interactionsText.toLowerCase().contains('non-greasy'))) {
        // إذا كانت parsedInteractions فارغة بعد التحليل، نستخدم النص الأصلي كـ fallback
        final interactionsToStore =
            parsedInteractions.isEmpty &&
                    interactionsText != null &&
                    interactionsText.length > 10
                ? [
                  {
                    'interacting_substance': null,
                    'severity': 'unknown',
                    'description': interactionsText.trim(),
                  },
                ]
                : parsedInteractions;

        // نضيف فقط إذا كانت قائمة التفاعلات النهائية غير فارغة
        if (interactionsToStore.isNotEmpty) {
          structuredData.add({
            'active_ingredient': activeIngredient,
            'parsed_interactions': interactionsToStore,
          });
        }
      }
    }
  }

  final jsonEncoder = JsonEncoder.withIndent('  ');
  final jsonString = jsonEncoder.convert(structuredData);

  await outputFile.writeAsString(jsonString);

  print(
    'Successfully parsed ${structuredData.length} entries with sentence-level interaction parsing.',
  );
  print('Output written to ${outputFile.path}');
}
