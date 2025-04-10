بالتأكيد، سأقوم بإعادة كتابة الخطة مع إضافة ترقيم فرعي للمهام لتسهيل التتبع والمتابعة بشكل دقيق.

---

### **خطة عمل تطبيق MediSwitch (فائقة التفصيل مع ترقيم فرعي)**

**الاستراتيجية المعتمدة:**
*   **البيانات:** Excel/CSV كمصدر أساسي، يُعالج في الـ Frontend.
*   **الأداء:** أولوية قصوى للمعالجة في الخلفية (Isolates)، هياكل بيانات مُحسّنة، وتحسينات UI.
*   **الجودة:** تطبيق Clean Architecture، كود نظيف، اختبارات شاملة، CI/CD.
*   **المرونة:** الاستعداد لتقييم DB محلي (Hive/Isar) لاحقًا إذا كان الأداء غير كافٍ.

---

### **المرحلة 0: التأسيس والتخطيط (الأسبوع 1)**

*   **0.1. تأكيد المتطلبات النهائية والتخطيط:**
    *   `[x]` 0.1.1. مراجعة واعتماد استراتيجية "Excel/CSV كقاعدة بيانات" للمعالجة في Frontend.
    *   `[x]` 0.1.2. اعتماد HTTPS فقط لتأمين نقل الملفات.
    *   `[x]` 0.1.3. اعتماد آلية تحديث عبر فحص الإصدار عند التشغيل مع إشعار للمستخدم.
    *   `[x]` 0.1.4. تحديد إطار عمل الـ Backend النهائي (مثل Node.js/Express أو Python/Django). (Django chosen)
    *   `[x]` 0.1.5. تحديد حل إدارة الحالة النهائي في Flutter (تم اعتماد Provider حالياً).
    *   `[x]` 0.1.6. تحديد وتطبيق حل حقن التبعيات النهائي (تم استخدام get_it).
        *   `[x]` 0.1.6.1. اختيار المكتبة النهائية (get_it).
        *   `[x]` 0.1.6.2. إعداد `locator.dart` وتسجيل التبعيات (DataSources, Repositories, UseCases, Providers).
        *   `[x]` 0.1.6.3. تحديث `main.dart` لتهيئة Locator وتوفير Providers.
        *   `[x]` 0.1.6.4. إعادة هيكلة الشاشات (مثل `DrugDetailsScreen`) لاستخدام Providers من Locator.
*   **0.2. إعداد بيئات التطوير والمستودعات:**
    *   `[ ]` 0.2.1. تثبيت/تحديث Flutter SDK (>= 3.x.x) وتكوين دعم Android/iOS/Web.
    *   `[ ]` 0.2.2. تثبيت أدوات بناء الـ Backend المختارة. (Python/Django assumed installed)
    *   `[x]` 0.2.3. إعداد مستودع Git مركزي (Monorepo أو منفصل).
    *   `[ ]` 0.2.4. إعداد بيئة التطوير المحلية (IDE, API Client).
    *   `[x]` 0.2.5. توثيق خطوات إعداد وتمكين Wi-Fi Debugging (ADB) في `README.md`.
*   **0.3. بناء هيكل مشروع الواجهة الأمامية (Flutter - `lib`):**
    *   `[x]` 0.3.1. تنفيذ هيكل المجلدات (Clean Architecture: core, data, domain, presentation, config, di). (Directories created)
    *   `[x]` 0.3.2. إنشاء ملفات `.dart` أولية فارغة للمكونات الرئيسية. (Placeholders created for core, data, domain)
*   **0.4. بناء هيكل مشروع الواجهة الخلفية (Backend):**
    *   `[x]` 0.4.1. تنفيذ هيكل المجلدات المختار. (Django default structure created)
    *   `[x]` 0.4.2. إعداد ملفات التكوين الأساسية (`.env`). (Django settings configured, .env created)
*   **0.5. إضافة وإدارة التبعيات:**
    *   `[x]` 0.5.1. (Frontend) إضافة التبعيات إلى `pubspec.yaml`. (Core dependencies added)
    *   `[x]` 0.5.2. (Backend) إضافة التبعيات إلى `package.json` أو `requirements.txt`. (requirements.txt created and installed)
    *   `[ ]` 0.5.3. إعداد أدوات إدارة الإصدارات (FVM؟).
*   **0.6. إعداد أدوات الجودة والأداء:**
    *   `[x]` 0.6.1. تفعيل وتخصيص قواعد lint صارمة (Frontend).
    *   `[x]` 0.6.2. إعداد linter مماثل للـ Backend.
    *   `[x]` 0.6.3. إنشاء نموذج أولي (Prototype) لاختبار قراءة Excel/CSV باستخدام `compute()`. (Implemented in CsvLocalDataSource)
*   **0.7. تصميم الواجهة (UI/UX) الأولي:**
    *   `[x]` 0.7.1. استخدام النموذج الأولي للواجهة (`External_source/prototype/`) كمرجع أساسي للـ Wireframes والتصميم.
    *   `[x]` 0.7.2. اعتماد لوحة الألوان والخطوط المحددة في (`External_source/prototype/css/`).

---

### **المرحلة 1: تطوير الواجهة الخلفية - الوظائف الأساسية (الأسبوع 2-3)**

*   **1.1. نظام مصادقة الأدمن:**
    *   `[x]` 1.1.1. تصميم مخطط قاعدة بيانات الأدمن. (Using default Django User model)
    *   `[x]` 1.1.2. تنفيذ خدمة تجزئة كلمات المرور. (Using default Django hashing)
    *   `[x]` 1.1.3. بناء API Endpoint `POST /api/v1/admin/auth/login`. (Simple JWT endpoint configured)
    *   `[x]` 1.1.4. بناء API Endpoint `POST /api/v1/admin/auth/register` (اختياري). (Register endpoint created)
    *   `[x]` 1.1.5. تنفيذ آلية تجديد التوكن (تم التأكد من وجود URL وتفعيل ROTATE_REFRESH_TOKENS).
    *   `[x]` 1.1.6. بناء واجهة ويب بسيطة لتسجيل الدخول.
    *   `[ ]` 1.1.7. إنشاء Middleware للتحقق من JWT. (DRF/SimpleJWT handles basic checks)
*   **1.2. إدارة ملف Excel/CSV وتوفيره:**
    *   `[x]` 1.2.1. تحديد استراتيجية تخزين الملف (Local/Cloud Storage). (Local disk chosen for now)
    *   `[x]` 1.2.2. بناء API Endpoint `POST /api/v1/admin/data/upload` (تم التحقق من منطق تحديث الإصدار عبر `ActiveDataFile.update_active_file`).
        *   `[x]` 1.2.2.1. استقبال الملف. (Implemented)
        *   `[x]` 1.2.2.2. التحقق من الامتداد. (Implemented)
        *   `[x]` 1.2.2.3. التحقق المتقدم من Headers/الأعمدة (تم التنفيذ في 4.1.1).
        *   `[x]` 1.2.2.4. نقل الملف للمخزن الدائم كـ "نشط جديد". (Implemented - overwrites)
        *   `[x]` 1.2.2.5. (اختياري) أرشفة الملف القديم. (Implemented - deletes old)
        *   `[x]` 1.2.2.6. تحديث سجل الملف النشط وإصداره.
    *   `[x]` 1.2.3. بناء واجهة ويب لرفع الملف في لوحة التحكم.
    *   `[x]` 1.2.4. بناء API Endpoint `GET /api/v1/data/latest-drugs.{ext}`: (Implemented as /api/v1/data/latest/)
        *   `[x]` 1.2.4.1. قراءة مسار الملف النشط. (Implemented in view)
        *   `[x]` 1.2.4.2. إرجاع الملف مع Headers مناسبة. (Implemented in view)
    *   `[x]` 1.2.5. بناء API Endpoint `GET /api/v1/data/version`. (Implemented)
    *   `[ ]` 1.2.6. تكوين خدمة CDN لتقديم الملف (إذا أمكن).
*   **1.3. النشر الأولي للـ Backend:**
    *   `[x]` 1.3.1. إعداد Dockerfile للـ Backend (تم إنشاء Dockerfile و .dockerignore، إضافة gunicorn/whitenoise، وتحديث settings.py).
    *   `[ ]` 1.3.2. نشر الـ Backend على منصة سحابية.
    *   `[ ]` 1.3.3. تكوين متغيرات البيئة.
    *   `[ ]` 1.3.4. اختبار Endpoints الأساسية.

---

### **المرحلة 2: تطوير الواجهة الأمامية - تحميل ومعالجة البيانات (الأسبوع 3-5)**

*   **2.1. بناء طبقة البيانات (`Data Layer`):**
    *   `[x]` 2.1.1. **`RemoteDataSource`:**
        *   `[x]` 2.1.1.1. تنفيذ استدعاء `GET /api/v1/data/version`. (Implemented in DrugRemoteDataSourceImpl)
        *   `[x]` 2.1.1.2. تنفيذ استدعاء `GET /api/v1/data/latest-drugs.{ext}`. (Implemented in DrugRemoteDataSourceImpl)
        *   `[x]` 2.1.1.3. معالجة أخطاء الشبكة. (Basic error handling implemented)
    *   `[x]` 2.1.2. **`LocalDataSource`:** (Implemented as CsvLocalDataSource)
        *   `[x]` 2.1.2.1. استخدام `path_provider` للحصول على مسار التخزين. (Implemented)
        *   `[x]` 2.1.2.2. تنفيذ حفظ الملف المُنزَّل. (Implemented in saveDownloadedCsv)
        *   `[x]` 2.1.2.3. تنفيذ دالة `parseExcelCsvFile(filePath)` التي تعمل داخل `compute()`. (Implemented in CsvLocalDataSource)
        *   `[x]` 2.1.2.4. تنفيذ قراءة/كتابة آخر إصدار/تاريخ تحديث محلي (`shared_preferences`). (Implemented)
    *   `[x]` 2.1.3. **`DrugRepositoryImpl`:** (Basic implementation for getAllDrugs)
        *   `[x]` 2.1.3.1. تنفيذ دالة `getDrugs()` للتحقق من التحديث، التنزيل، التحليل (باستخدام `compute()`). (Implemented as getAllDrugs with _shouldUpdateData and _updateLocalDataFromRemote)
        *   `[x]` 2.1.3.2. بناء فهارس `Map` في الذاكرة بعد التحليل.
        *   `[x]` 2.1.3.3. تحويل `List<DrugModel>` إلى `List<DrugEntity>`. (Done in getAllDrugs)
        *   `[x]` 2.1.3.4. تخزين البيانات والفهارس في الذاكرة (عبر State Management). (Basic implementation in MedicineProvider)
        *   `[x]` 2.1.3.5. معالجة الأخطاء وإرجاع حالة مناسبة (`Either<Failure, ...>`). (Done in getAllDrugs)
*   **2.2. بناء طبقة المجال (`Domain Layer`):**
    *   `[x]` 2.2.1. تعريف `DrugEntity`. (`DrugEntity` defined)
    *   `[x]` 2.2.2. تعريف `DrugRepository` interface. (Interface defined and updated with search/filter methods)
    *   `[x]` 2.2.3. بناء Use Cases الأساسية (GetAllDrugs, SearchDrugs, FilterDrugsByCategory, GetAvailableCategories). (Implemented)
*   **2.3. إدارة الحالة للبيانات:**
    *   `[x]` 2.3.1. إعداد `DrugListProvider`/`Bloc`. (`MedicineProvider` refactored)
    *   `[x]` 2.3.2. ربط حالات التحميل (`isLoading`, `error`, `data`) بالواجهة. (`HomeScreen` uses provider state)

---

### **المرحلة 3: تطوير الواجهة الأمامية - واجهة المستخدم والميزات الأساسية (الأسبوع 6-10)**

*   **3.1. الواجهة الأساسية والشاشة الرئيسية (`HomeScreen`):** (تمت إعادة الهيكلة بناءً على Prototype)
    *   `[x]` 3.1.1. `MaterialApp`: السمات، اللغات، التوجيه. (`main.dart` setup)
    *   `[x]` 3.1.2. `HomeScreen`: استخدام `CustomScrollView` و `SliverAppBar` للهيكل العام (تم التنفيذ).
    *   `[x]` 3.1.3. عرض حالة تحميل البيانات باستخدام `Consumer`/`BlocBuilder`.
    *   `[x]` 3.1.4. `BottomNavigationBar`: التنقل بين الشاشات الرئيسية. (`main_screen.dart` handles this)
    *   `[x]` 3.1.5. بناء `Header` مخصص (معلومات المستخدم + شريط البحث) (تم التنفيذ بناءً على Prototype).
    *   `[x]` 3.1.6. بناء أقسام أفقية (الفئات، المحدثة مؤخراً، الأكثر بحثاً) (تم التنفيذ بناءً على Prototype).
    *   `[x]` 3.1.7. تطبيق التصميم المتجاوب (ListView/GridView).
*   **3.2. شاشة البحث (`SearchScreen`) وتفاصيل الدواء (`DrugDetailsScreen`):**
    *   `[~]` 3.2.1. `SearchScreen`: `AppBar` مخصص مع حقل بحث نشط وزر فلترة (بناءً على Prototype).
    *   `[x]` 3.2.2. `SearchProvider`/`Bloc`: إدارة حالة البحث (متصل بـ `MedicineProvider`).
    *   `[x]` 3.2.3. تطبيق `Debouncer` على `TextField`.
    *   `[x]` 3.2.4. تنفيذ منطق البحث/الفلترة في Provider/Bloc.
    *   `[~]` 3.2.5. بناء `FilterBottomSheet` (بناءً على Prototype مع Chips و Slider).
    *   `[x]` 3.2.6. `ListView.builder`/`GridView.builder` لعرض النتائج.
    *   `[~]` 3.2.7. `DrugDetailsScreen`: شاشة مخصصة مع `NestedScrollView` و `TabBar` (بناءً على Prototype).
        *   `[~]` 3.2.7.1. بناء `Header` لعرض معلومات الدواء الأساسية والصورة.
        *   `[~]` 3.2.7.2. بناء قسم السعر.
        *   `[~]` 3.2.7.3. بناء `TabBar` و `TabBarView` للأقسام (معلومات، بدائل، جرعات، تفاعلات).
        *   `[~]` 3.2.7.4. بناء محتوى تبويب "معلومات".
        *   `[x]` 3.2.7.5. بناء محتوى تبويب "البدائل" (تضمين `AlternativesScreen`).
        *   `[x]` 3.2.7.6. بناء محتوى تبويب "الجرعات" (عرض معلومات الاستخدام + زر للحاسبة).
        *   `[x]` 3.2.7.7. بناء محتوى تبويب "التفاعلات" (زر لمدقق التفاعلات).
    *   `[x]` 3.2.8. عرض المعلومات الأساسية (تم نقله إلى تبويب "معلومات").
    *   `[x]` 3.2.9. زر "إيجاد البدائل" (موجود في تبويب "البدائل").
    *   `[~]` 3.2.10. زر "المفضلة" (Premium). (UI مضاف في AppBar، المنطق مؤجل لـ 5.3.6).
    *   `[x]` 3.2.11. استخدام `CachedNetworkImage` (تم التحديث في `DrugListItem`، يتطلب وجود `imageUrl` في البيانات).
*   `[~]` **3.3. شاشة حاسبة الجرعة (`weight_calculator_screen.dart`):** (UI Refactored based on Prototype, Logic exists)
    *   `[x]` 3.3.1. `DoseCalculatorProvider`/`Bloc`. (Exists)
    *   `[x]` 3.3.2. بناء الفورم (`Form`, `TextFormField`, `Dropdown`/Search). (Exists in `weight_calculator_screen.dart`)
    *   `[x]` 3.3.3. إضافة `Form Validation`. (Basic validation exists)
    *   `[ ]` 3.3.4. **تحديد هياكل البيانات:**
        *   `[x]` 3.3.4.1. تعريف فئة `DosageResult` (تم التعريف في `External source/dosage_calculator/dosage_calculator.dart` و `enhanced_documentation.md`).
        *   `[x]` 3.3.4.2. مراجعة وتحديث `DrugEntity` (الموجودة في `lib/domain/entities/drug_entity.dart`) لتضمين معلومات التركيز والشكل الصيدلاني اللازمة للحسابات (الحقول موجودة بالفعل).
    *   `[x]` 3.3.5. **بناء خدمة حساب الجرعات (`DosageCalculatorService`):**
        *   `[x]` 3.3.5.1. إنشاء ملف الخدمة في `lib/domain/services/` أو مكان مناسب.
        *   `[x]` 3.3.5.2. تنفيذ دالة `calculateDosage(DrugEntity medicine, double weight, int age)` الرئيسية.
        *   `[x]` 3.3.5.3. تنفيذ منطق حساب جرعة الباراسيتامول (استنادًا إلى `External source`).
        *   `[x]` 3.3.5.4. تنفيذ منطق حساب جرعة الإيبوبروفين (استنادًا إلى `External source`).
        *   `[x]` 3.3.5.5. تنفيذ منطق حساب جرعة الأموكسيسيلين (استنادًا إلى `External source`).
        *   `[x]` 3.3.5.6. إضافة معالجة للأدوية غير المدعومة أو الأشكال الصيدلانية غير المتوقعة.
    *   `[x]` 3.3.6. **تكامل الخدمة مع `DoseCalculatorProvider`:** (تم التنفيذ بالفعل في `lib/presentation/bloc/dose_calculator_provider.dart`)
        *   `[x]` 3.3.6.1. حقن `DosageCalculatorService` في الـ Provider.
        *   `[x]` 3.3.6.2. استدعاء `calculateDosage` من الـ Provider عند تغيير المدخلات.
        *   `[x]` 3.3.6.3. تحديث حالة الـ Provider (`isLoading`, `dosageResult`, `error`).
    *   `[x]` 3.3.7. **تحديث واجهة المستخدم (`weight_calculator_screen.dart`):** (تم التنفيذ بالفعل)
        *   `[x]` 3.3.7.1. التأكد من وجود حقل لاختيار الدواء.
        *   `[x]` 3.3.7.2. ربط حقول الإدخال (الدواء، الوزن، العمر) بالـ Provider.
        *   `[x]` 3.3.7.3. عرض نتيجة الحساب (`dosageResult.dosage`) من الـ Provider.
        *   `[x]` 3.3.7.4. عرض التحذيرات (`dosageResult.warning`) والملاحظات (`dosageResult.notes`).
        *   `[x]` 3.3.7.5. عرض مؤشر التحميل وحالة الخطأ.
    *   `[~]` 3.3.8. زر "حفظ الحساب" (Premium). (UI added, logic deferred)
*   `[x]` **3.4. شاشة البدائل والأدوية المماثلة (`AlternativesScreen`):** (تم التحقق من عمل الشاشة والـ Provider والـ Use Case).
    *   `[x]` 3.4.1. `AlternativesProvider`/`Bloc`.
    *   `[x]` 3.4.2. استقبال `DrugEntity` الأصلي. (Handled by screen constructor)
    *   `[x]` 3.4.3. تنفيذ منطق إيجاد البدائل. (Refined logic to match active ingredient in UseCase)
    *   `[x]` 3.4.4. بناء `ListView` لعرض البدائل والمعلومات. (Implemented using AlternativeDrugCard)
*   `[~]` **3.5. (ميزة متقدمة - Premium؟) شاشة مدقق التفاعلات (`InteractionCheckerScreen`):** (UI Refactored based on Prototype, Logic exists)
    *   `[x]` 3.5.1. **تحديد هياكل البيانات:** (تم التعريف في `External source/drug_interaction/drug-interaction-model.dart`)
        *   `[x]` 3.5.1.1. تعريف/مراجعة فئات `ActiveIngredient`, `DrugInteraction`, وتعدادات `InteractionSeverity`, `InteractionType`.
    *   `[x]` 3.5.2. **بناء خدمة/مستودع بيانات التفاعلات:** (تم التنفيذ في `lib/data/repositories/interaction_repository_impl.dart`)
        *   `[x]` 3.5.2.1. إنشاء `InteractionRepositoryImpl`.
        *   `[x]` 3.5.2.2. تنفيذ تحميل بيانات التفاعلات من ملفات JSON (`active_ingredients.json`, `drug_interactions.json`).
        *   `[x]` 3.5.2.3. تنفيذ تحميل/ربط المكونات النشطة بالأدوية (من `medicine_ingredients.json`).
    *   `[x]` 3.5.3. **بناء خدمة تحليل التفاعلات (`InteractionCheckerService`):** (تم التنفيذ في `lib/domain/services/interaction_checker_service.dart` استنادًا إلى `External source`)
        *   `[x]` 3.5.3.1. إنشاء ملف الخدمة.
        *   `[x]` 3.5.3.2. تنفيذ دالة `analyzeInteractions(List<DrugEntity> medicines)` الرئيسية (للتحليل الثنائي).
        *   `[x]` 3.5.3.3. تنفيذ منطق البحث عن التفاعلات الثنائية.
        *   `[ ]` 3.5.3.4. (اختياري متقدم) تنفيذ منطق تحليل المسارات المتعددة باستخدام الرسم البياني (DFS).
        *   `[x]` 3.5.3.5. تنفيذ منطق توليد التوصيات والشدة الإجمالية.
    *   `[x]` 3.5.4. **إدارة الحالة (`InteractionProvider`):** (تم التنفيذ والتحديث)
        *   `[x]` 3.5.4.1. إنشاء Provider لإدارة قائمة الأدوية المختارة ونتائج التحليل (`isLoading`, `error`, `analysisResult`).
        *   `[x]` 3.5.4.2. حقن `InteractionCheckerService` و `InteractionRepository`.
        *   `[x]` 3.5.4.3. استدعاء خدمة التحليل عند تغيير قائمة الأدوية (مع التأكد من تحميل البيانات).
    *   `[~]` 3.5.5. **بناء واجهة المستخدم (`InteractionCheckerScreen`):** (UI Refactored based on Prototype)
        *   `[x]` 3.5.5.1. إنشاء ملف الشاشة.
        *   `[~]` 3.5.5.2. بناء واجهة لاختيار أدوية متعددة (باستخدام Chips و CustomSearchDelegate).
        *   `[x]` 3.5.5.3. ربط الواجهة بالـ Provider لعرض الأدوية المختارة.
        *   `[~]` 3.5.5.4. عرض نتائج التفاعلات (باستخدام Cards بناءً على Prototype).
        *   `[x]` 3.5.5.5. عرض مؤشر التحميل وحالة الخطأ.
*   `[~]` **3.6. شاشة الإعدادات (`SettingsScreen`):** (تمت إعادة الهيكلة بناءً على Prototype)
    *   `[x]` 3.6.1. `SettingsProvider`/`Bloc`.
    *   `[~]` 3.6.2. بناء الواجهة باستخدام `ListView` و `Card` للأقسام (ملف شخصي، عام، أمان، اشتراك، حول).
    *   `[x]` 3.6.3. تنفيذ تغيير اللغة والمظهر. (Theme change implemented, Language implemented)
    *   `[x]` 3.6.4. بناء واجهة إدارة الاشتراك. (Placeholder UI added)
    *   `[x]` 3.6.5. استخدام `url_launcher` للروابط. (Implemented for About, Privacy, Terms)
    *   `[x]` 3.6.6. زر "التحقق من التحديث". (Implemented in SettingsScreen)
    *   `[x]` 3.6.7. عرض تاريخ آخر تحديث. (Implemented in SettingsScreen using MedicineProvider)
*   **3.7. دعم العمل دون اتصال:**
    *   `[~]` 3.7.1. مراجعة الشاشات للتأكد من عملها بدون اتصال (بعد التحميل الأولي). (Current implementation is offline first)
    *   `[x]` 3.7.2. عرض رسالة مناسبة في حالة عدم وجود بيانات/اتصال. (Implemented initial load error handling)

---

### **المرحلة 4: تطوير الواجهة الخلفية - ميزات إضافية (الأسبوع 11)**

*   **4.1. تحسينات إدارة ملف Excel/CSV:**
    *   `[x]` 4.1.1. إضافة تحقق أكثر تفصيلاً (التحقق من الأعمدة باستخدام pandas في Backend).
    *   `[x]` 4.1.2. عرض رسائل خطأ واضحة (تم تضمينها في استجابة التحقق من الأعمدة).
    *   `[x]` 4.1.3. عرض معلومات إضافية عن الملف (تمت إضافة حجم الملف للاستجابة).
*   **4.2. إدارة الإعلانات (AdMob Config):**
    *   `[x]` 4.2.1. تصميم نموذج بيانات للإعدادات (تم إنشاء `AdMobConfig` model).
    *   `[x]` 4.2.2. بناء واجهة للأدمن في لوحة التحكم (تم تسجيل `AdMobConfig` في `admin.py`).
    *   `[x]` 4.2.3. إنشاء نقطة نهاية API `GET /api/v1/config/ads` (تم إنشاء Serializer, View, URL).
*   **4.3. إعدادات التطبيق العامة:**
    *   `[x]` 4.3.1. تصميم نموذج بيانات (روابط) (تم إنشاء `GeneralConfig` model).
    *   `[x]` 4.3.2. بناء واجهة للأدمن (تم تسجيل `GeneralConfig` في `admin.py`).
    *   `[x]` 4.3.3. إنشاء نقطة نهاية API `GET /api/v1/config/general` (تم إنشاء Serializer, View, URL).
*   **4.4. استقبال وتحليل الإحصائيات:**
    *   `[x]` 4.4.1. إنشاء `POST /api/v1/analytics/log` لاستقبال أنواع أحداث (تم إنشاء Model, Serializer, View, URL).
    *   `[x]` 4.4.2. بناء منطق تحليل البيانات (تم إنشاء `AnalyticsSummaryView` لعرض أكثر الكلمات بحثًا).

---

### **المرحلة 5: تطوير الواجهة الأمامية - الإعلانات والاشتراكات (الأسبوع 12-13)**

*   **5.1. جلب الإعدادات من الـ Backend:**
    *   `[x]` 5.1.1. بناء `ConfigRepository` و Use Cases لجلب الإعدادات (AdMob, General).
*   **5.2. تنفيذ الإعلانات:**
    *   `[ ]` 5.2.1. تهيئة `google_mobile_ads`.
    *   `[ ]` 5.2.2. بناء `BannerAdWidget`.
    *   `[ ]` 5.2.3. بناء خدمة لإدارة `InterstitialAd`.
*   **5.3. تنفيذ نظام الاشتراك (Premium):**
    *   `[x]` 5.3.1. تهيئة `in_app_purchase` (تمت إضافة الحزمة، إنشاء Provider، وتسجيله في Locator).
    *   `[x]` 5.3.2. عرض خيارات الشراء (تم إنشاء `SubscriptionScreen` لعرض المنتجات والحالة).
    *   `[x]` 5.3.3. تنفيذ عمليات الشراء والاستعادة (تم ربط الأزرار بالـ Provider).
    *   `[~]` 5.3.4. التحقق من صحة الإيصالات (تم إنشاء Backend Endpoint وربط Frontend Provider، يتطلب منطق التحقق الفعلي من المتاجر).
    *   `[ ]` 5.3.5. تحديث حالة المستخدم (Premium) (المنطق الأساسي موجود في Provider، يحتاج إلى تحسين/تخزين دائم).
    *   `[~]` 5.3.6. التحكم في عرض الإعلانات والميزات Premium (تم ربط أزرار المفضلة وحفظ الحساب بحالة الاشتراك).
*   **5.4. إرسال الإحصائيات التفصيلية:**
    *   `[x]` 5.4.1. بناء `AnalyticsService` (تم إنشاء الواجهة والتنفيذ وتسجيله في Locator).
    *   `[~]` 5.4.2. استدعاء `AnalyticsService` من الأماكن المناسبة (تم إضافة تتبع مشاهدة الشاشات الرئيسية).

---

### **المرحلة 6: تطبيق التصميم الجديد (Design Lab Implementation)**

*   **ملاحظة:** هذه المرحلة تستبدل أو تعيد تقييم مهام المرحلة 6.3 السابقة بناءً على التصميم الجديد في `medi-switch-design-lab-main`.
*   **6.1. تحليل التصميم الجديد:**
    *   `[~]` 6.1.1. استكشاف هيكل ملفات التصميم (`medi-switch-design-lab-main/src/`).
    *   `[~]` 6.1.2. تحديد الشاشات والمكونات الرئيسية في التصميم.
    *   `[~]` 6.1.3. استخلاص دليل الأسلوب (الألوان، الخطوط، الأيقونات) من ملفات التصميم (CSS/TSX).
*   **6.2. تطبيق الشاشات الرئيسية (بناءً على التصميم الجديد):**
    *   `[~]` 6.2.1. إعادة بناء `HomeScreen` (تم تحديث الهيكل، دمج Header/SearchBar/HorizontalListSection).
    *   `[ ]` 6.2.2. إعادة بناء `SearchScreen` و `FilterBottomSheet`.
    *   `[ ]` 6.2.3. إعادة بناء `DrugDetailsScreen` (مع التبويبات).
    *   `[ ]` 6.2.4. إعادة بناء `AlternativesScreen`.
    *   `[ ]` 6.2.5. إعادة بناء `WeightCalculatorScreen`.
    *   `[ ]` 6.2.6. إعادة بناء `InteractionCheckerScreen`.
    *   `[ ]` 6.2.7. إعادة بناء `SettingsScreen`.
    *   `[ ]` 6.2.8. إعادة بناء `SubscriptionScreen`.
    *   `[ ]` 6.2.9. إعادة بناء `OnboardingScreen`.
*   **6.3. تطبيق المكونات المشتركة (بناءً على التصميم الجديد):**
    *   `[~]` 6.3.1. إعادة بناء `DrugListItem` / `AlternativeDrugCard` (تم إضافة Semantics).
    *   `[x]` 6.3.2. إعادة بناء أو تعديل `SectionHeader` (تم إعادة استخدامه).
    *   `[~]` 6.3.3. إنشاء/تعديل أي Widgets مخصصة أخرى يتطلبها التصميم (تم إنشاء HomeHeader, HorizontalListSection, CategoryCard).
*   **6.4. تطبيق الأصول الجديدة:**
    *   `[ ]` 6.4.1. استخدام الأيقونات الجديدة من التصميم.
    *   `[ ]` 6.4.2. استخدام الصور التوضيحية الجديدة (إن وجدت).
    *   `[~]` 6.4.3. تحديث أيقونة التطبيق وشعار البداية باستخدام الأصول من التصميم (تم نسخ الشعار وإضافته).
*   **6.5. تطبيق Animations (بناءً على التصميم الجديد):**
    *   `[~]` 6.5.1. تنفيذ انتقالات الشاشات والتأثيرات المحددة في التصميم (تم إضافة animation لـ CategoryCard).
*   **6.6. مراجعة RTL والترجمة (بناءً على التصميم الجديد):**
    *   `[ ]` 6.6.1. التأكد من دعم RTL الكامل للتصميم الجديد.
    *   `[ ]` 6.6.2. (مؤجل) البدء في استخراج النصوص للترجمة.
*   **6.7. مراجعة Accessibility (بناءً على التصميم الجديد):**
    *   `[~]` 6.7.1. مراجعة Semantics و Contrast و Tap Targets للتصميم الجديد (تم إضافة Semantics أساسية للعناصر المخصصة: DrugListItem, AlternativeDrugCard, CategoryCard).

---
*ملاحظة: تم إيقاف العمل على مهام Phase 6.1, 6.2, 6.4, 6.5 السابقة مؤقتاً للتركيز على تطبيق التصميم الجديد.*

---

### **المرحلة 7: الاختبار والنشر (الأسبوع 15-16)**

*   **7.1. الاختبار الشامل:**
    *   `[ ]` 7.1.1. **Unit Tests:** كتابة اختبارات (Use Cases, Providers/Blocs, Repositories).
    *   `[ ]` 7.1.2. **Widget Tests:** كتابة اختبارات (Screens, Widgets).
    *   `[ ]` 7.1.3. **Integration Tests:** (اختياري) كتابة اختبارات للتدفقات الرئيسية.
    *   `[ ]` 7.1.4. **الاختبار اليدوي:** وظيفي، تحديث، توافق (Android 8+/iOS 13+, أحجام شاشات), ويب, أداء, عدم اتصال, إعلانات واشتراك.
    *   `[ ]` 7.1.5. **Beta Testing:** إعداد توزيع تجريبي وجمع الملاحظات.
*   **7.2. إعدادات النشر:**
    *   `[ ]` 7.2.1. تكوين `appicon` و `splash screen` (`flutter_native_splash`?).
    *   `[ ]` 7.2.2. مراجعة وتحديث `build.gradle` و `Info.plist`.
    *   `[ ]` 7.2.3. إنشاء وتأمين Android Keystore.
    *   `[ ]` 7.2.4. إنشاء وتكوين iOS Certificates & Provisioning Profiles.
    *   `[ ]` 7.2.5. تحليل حجم التطبيق (`flutter build ... --analyze-size`).
*   **7.3. النشر:**
    *   `[ ]` 7.3.1. نشر الـ Backend (Production).
    *   `[ ]` 7.3.2. إعداد CI/CD (GitHub Actions/Codemagic).
    *   `[ ]` 7.3.3. النشر اليدوي المبدئي أو باستخدام CI/CD للمتاجر والويب.

---

### **المرحلة 8: التوثيق والتسليم (الأسبوع 17)**

*   **8.1. توثيق الكود:**
    *   `[ ]` 8.1.1. التأكد من وجود DartDoc شامل للكود العام.
    *   `[ ]` 8.1.2. مراجعة التعليقات في Backend.
*   **8.2. توثيق المشروع:**
    *   `[ ]` 8.2.1. كتابة `ADMIN_GUIDE.md`.
    *   `[ ]` 8.2.2. كتابة `API_DOCS.md` أو استخدام Swagger/OpenAPI.
    *   `[ ]` 8.2.3. كتابة `DEVELOPER_GUIDE.md` للـ Frontend.
    *   `[ ]` 8.2.4. كتابة `USER_GUIDE.md` (اختياري).
*   **8.3. التسليم النهائي:**
    *   `[ ]` 8.3.1. مراجعة نهائية للكود والمستودعات.
    *   `[ ]` 8.3.2. تسليم الوصوليات.
    *   `[ ]` 8.3.3. اجتماع التسليم وشرح المشروع.

---

هذه الخطة الآن مُرقّمة فرعيًا لزيادة الوضوح وتسهيل المتابعة الدقيقة لكل مهمة فرعية.
