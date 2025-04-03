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
    *   `[ ]` 0.1.5. تحديد حل إدارة الحالة النهائي في Flutter (مثل Provider, Riverpod, أو Bloc). (Provider is used, but maybe not final)
    *   `[ ]` 0.1.6. تحديد حل حقن التبعيات النهائي (مثل get_it).
*   **0.2. إعداد بيئات التطوير والمستودعات:**
    *   `[ ]` 0.2.1. تثبيت/تحديث Flutter SDK (>= 3.x.x) وتكوين دعم Android/iOS/Web.
    *   `[ ]` 0.2.2. تثبيت أدوات بناء الـ Backend المختارة. (Python/Django assumed installed)
    *   `[x]` 0.2.3. إعداد مستودع Git مركزي (Monorepo أو منفصل).
    *   `[ ]` 0.2.4. إعداد بيئة التطوير المحلية (IDE, API Client).
    *   `[ ]` 0.2.5. توثيق خطوات إعداد وتمكين Wi-Fi Debugging (ADB) في `README.md`.
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
    *   `[ ]` 0.7.1. البحث عن رابط Figma أو إنشاء Wireframes أساسية.
    *   `[ ]` 0.7.2. تحديد لوحة الألوان النهائية والخطوط.

---

### **المرحلة 1: تطوير الواجهة الخلفية - الوظائف الأساسية (الأسبوع 2-3)**

*   **1.1. نظام مصادقة الأدمن:**
    *   `[x]` 1.1.1. تصميم مخطط قاعدة بيانات الأدمن. (Using default Django User model)
    *   `[x]` 1.1.2. تنفيذ خدمة تجزئة كلمات المرور. (Using default Django hashing)
    *   `[x]` 1.1.3. بناء API Endpoint `POST /api/v1/admin/auth/login`. (Simple JWT endpoint configured)
    *   `[x]` 1.1.4. بناء API Endpoint `POST /api/v1/admin/auth/register` (اختياري). (Register endpoint created)
    *   `[ ]` 1.1.5. تنفيذ آلية تجديد التوكن. (Simple JWT refresh endpoint configured)
    *   `[x]` 1.1.6. بناء واجهة ويب بسيطة لتسجيل الدخول.
    *   `[ ]` 1.1.7. إنشاء Middleware للتحقق من JWT. (DRF/SimpleJWT handles basic checks)
*   **1.2. إدارة ملف Excel/CSV وتوفيره:**
    *   `[x]` 1.2.1. تحديد استراتيجية تخزين الملف (Local/Cloud Storage). (Local disk chosen for now)
    *   `[~]` 1.2.2. بناء API Endpoint `POST /api/v1/admin/data/upload`: (Endpoint created, needs version update logic)
        *   `[x]` 1.2.2.1. استقبال الملف. (Implemented)
        *   `[x]` 1.2.2.2. التحقق من الامتداد. (Implemented)
        *   `[ ]` 1.2.2.3. التحقق المتقدم من Headers/الأعمدة.
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
    *   `[ ]` 1.3.1. إعداد Dockerfile للـ Backend.
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

*   **3.1. الواجهة الأساسية والشاشة الرئيسية (`HomeScreen`):**
    *   `[x]` 3.1.1. `MaterialApp`: السمات، اللغات، التوجيه. (`main.dart` setup)
    *   `[x]` 3.1.2. `HomeScreen`: `Scaffold`, `AppBar`, `BottomNavigationBar`. (`home_screen.dart` exists)
    *   `[x]` 3.1.3. عرض حالة تحميل البيانات باستخدام `Consumer`/`BlocBuilder`. (`HomeScreen` does this)
    *   `[x]` 3.1.4. `BottomNavigationBar`: التنقل بين (الرئيسية، الحاسبة، الإعدادات) مع الحفاظ على الحالة. (`main_screen.dart` handles this)
    *   `[x]` 3.1.5. `CustomSearchBar`: ويدجت شريط البحث غير التفاعلي. (`HomeScreen` has search bar)
    *   `[x]` 3.1.6. بناء أقسام اختيارية (المحدثة/المفضلة/الشائعة). ('Recently Updated' section implemented)
    *   `[x]` 3.1.7. تطبيق التصميم المتجاوب. (Implemented LayoutBuilder for ListView/GridView switch)
*   **3.2. شاشة البحث (`SearchScreen`) وتفاصيل الدواء (`DrugDetailsScreen`):**
    *   `[x]` 3.2.1. `SearchScreen`: `AppBar` مع `TextField`. (Implemented SearchScreen with TextField in AppBar)
    *   `[x]` 3.2.2. `SearchProvider`/`Bloc`: إدارة حالة البحث. (Search logic connected to MedicineProvider from SearchScreen)
    *   `[x]` 3.2.3. تطبيق `Debouncer` على `TextField`.
    *   `[x]` 3.2.4. تنفيذ منطق البحث/الفلترة في Provider/Bloc. (`MedicineProvider` handles this)
    *   `[x]` 3.2.5. بناء `FilterBottomSheet` وتطبيق الفلاتر. (Filters are ChoiceChips in HomeScreen)
    *   `[x]` 3.2.6. `ListView.builder` و `DrugCard` لعرض النتائج مع تمييز النص. (`HomeScreen` does this)
    *   `[~]` 3.2.7. `DrugDetailsScreen`: استقبال `DrugEntity`, `CustomScrollView`, `SliverAppBar`. (Details shown in ModalBottomSheet using DrugEntity)
    *   `[x]` 3.2.8. عرض المعلومات الأساسية وأقسام `ExpansionTile`. (Additional fields added to ModalBottomSheet)
    *   `[x]` 3.2.9. زر "إيجاد البدائل". (UI added and linked)
    *   `[~]` 3.2.10. زر "المفضلة" (Premium). (UI added, logic deferred)
    *   `[ ]` 3.2.11. استخدام `CachedNetworkImage`.
*   `[~]` **3.3. شاشة حاسبة الجرعة (`DoseCalculatorScreen`):** (Screen exists, uses DrugEntity, needs implementation) **[ON HOLD - Missing Dosing Data]**
    *   `[x]` 3.3.1. `DoseCalculatorProvider`/`Bloc`.
    *   `[x]` 3.3.2. بناء الفورم (`Form`, `TextFormField`, `Dropdown`/Search).
    *   `[x]` 3.3.3. إضافة `Form Validation`. (Basic validation added)
    *   `[x]` 3.3.4. تنفيذ منطق الحساب. (Placeholder logic implemented)
    *   `[~]` 3.3.5. عرض النتائج والتحذير (بصري وصوتي). (Basic result display added, Warning deferred pending safe dose data)
    *   `[~]` 3.3.6. زر "حفظ الحساب" (Premium). (UI added, logic deferred)
*   `[~]` **3.4. شاشة البدائل والأدوية المماثلة (`AlternativesScreen`):** (`dose_comparison_screen.dart` exists, uses DrugEntity, needs implementation)
    *   `[x]` 3.4.1. `AlternativesProvider`/`Bloc`.
    *   `[x]` 3.4.2. استقبال `DrugEntity` الأصلي. (Handled by screen constructor)
    *   `[x]` 3.4.3. تنفيذ منطق إيجاد البدائل. (Refined logic to match active ingredient in UseCase)
    *   `[x]` 3.4.4. بناء `ListView` لعرض البدائل والمعلومات. (Implemented using AlternativeDrugCard)
*   **3.5. (ميزة متقدمة - Premium؟) شاشة مدقق التفاعلات (`InteractionCheckerScreen`):**
    *   `[ ]` 3.5.1. بناء واجهة اختيار متعدد للأدوية.
    *   `[ ]` 3.5.2. `InteractionProvider`/`Bloc`.
    *   `[ ]` 3.5.3. تنفيذ منطق فحص التفاعلات.
    *   `[ ]` 3.5.4. عرض النتائج بوضوح.
*   `[~]` **3.6. شاشة الإعدادات (`SettingsScreen`):** (Screen exists, needs implementation)
    *   `[x]` 3.6.1. `SettingsProvider`/`Bloc`.
    *   `[x]` 3.6.2. بناء الواجهة (`ListTile`, `SwitchListTile`). (Basic UI with Theme toggle added)
    *   `[~]` 3.6.3. تنفيذ تغيير اللغة والمظهر. (Theme change implemented, Language deferred)
    *   `[ ]` 3.6.4. بناء واجهة إدارة الاشتراك.
    *   `[x]` 3.6.5. استخدام `url_launcher` للروابط. (Implemented for About, Privacy, Terms)
    *   `[x]` 3.6.6. زر "التحقق من التحديث". (Implemented in SettingsScreen)
    *   `[x]` 3.6.7. عرض تاريخ آخر تحديث. (Implemented in SettingsScreen using MedicineProvider)
*   **3.7. دعم العمل دون اتصال:**
    *   `[~]` 3.7.1. مراجعة الشاشات للتأكد من عملها بدون اتصال (بعد التحميل الأولي). (Current implementation is offline first)
    *   `[x]` 3.7.2. عرض رسالة مناسبة في حالة عدم وجود بيانات/اتصال. (Implemented initial load error handling)

---

### **المرحلة 4: تطوير الواجهة الخلفية - ميزات إضافية (الأسبوع 11)**

*   **4.1. تحسينات إدارة ملف Excel/CSV:**
    *   `[ ]` 4.1.1. إضافة تحقق أكثر تفصيلاً.
    *   `[ ]` 4.1.2. عرض رسائل خطأ واضحة.
    *   `[ ]` 4.1.3. عرض معلومات إضافية عن الملف.
*   **4.2. إدارة الإعلانات (AdMob Config):**
    *   `[ ]` 4.2.1. تصميم نموذج بيانات للإعدادات.
    *   `[ ]` 4.2.2. بناء واجهة للأدمن في لوحة التحكم.
    *   `[ ]` 4.2.3. إنشاء نقطة نهاية API `GET /api/v1/config/ads`.
*   **4.3. إعدادات التطبيق العامة:**
    *   `[ ]` 4.3.1. تصميم نموذج بيانات (روابط).
    *   `[ ]` 4.3.2. بناء واجهة للأدمن.
    *   `[ ]` 4.3.3. إنشاء نقطة نهاية API `GET /api/v1/config/general`.
*   **4.4. استقبال وتحليل الإحصائيات:**
    *   `[ ]` 4.4.1. تحسين `POST /api/v1/analytics/log` لاستقبال أنواع أحداث.
    *   `[ ]` 4.4.2. بناء منطق تحليل البيانات (الأكثر بحثًا، البحث الفاشل).

---

### **المرحلة 5: تطوير الواجهة الأمامية - الإعلانات والاشتراكات (الأسبوع 12-13)**

*   **5.1. جلب الإعدادات من الـ Backend:**
    *   `[ ]` 5.1.1. بناء `ConfigRepository` و Use Cases لجلب الإعدادات.
*   **5.2. تنفيذ الإعلانات:**
    *   `[ ]` 5.2.1. تهيئة `google_mobile_ads`.
    *   `[ ]` 5.2.2. بناء `BannerAdWidget`.
    *   `[ ]` 5.2.3. بناء خدمة لإدارة `InterstitialAd`.
*   **5.3. تنفيذ نظام الاشتراك (Premium):**
    *   `[ ]` 5.3.1. تهيئة `in_app_purchase`.
    *   `[ ]` 5.3.2. عرض خيارات الشراء.
    *   `[ ]` 5.3.3. تنفيذ عمليات الشراء والاستعادة.
    *   `[ ]` 5.3.4. التحقق من صحة الإيصالات.
    *   `[ ]` 5.3.5. تحديث حالة المستخدم (Premium).
    *   `[ ]` 5.3.6. التحكم في عرض الإعلانات والميزات Premium.
*   **5.4. إرسال الإحصائيات التفصيلية:**
    *   `[ ]` 5.4.1. بناء `AnalyticsService`.
    *   `[ ]` 5.4.2. استدعاء `AnalyticsService` من الأماكن المناسبة.

---

### **المرحلة 6: التحسينات النهائية والأمان (الأسبوع 14)**

*   **6.1. تحسين الأداء:**
    *   `[ ]` 6.1.1. إجراء Profiling باستخدام Flutter DevTools.
    *   `[ ]` 6.1.2. تطبيق تحسينات (const, rebuilds, algorithms).
    *   `[ ]` 6.1.3. اختبار الأداء على أجهزة ضعيفة.
*   **6.2. تعزيز الأمان:**
    *   `[ ]` 6.2.1. مراجعة استخدام HTTPS.
    *   `[ ]` 6.2.2. مراجعة استخدام `flutter_secure_storage`.
    *   `[ ]` 6.2.3. تنفيذ `FLAG_SECURE` (Android).
*   **6.3. اللمسات النهائية لواجهة المستخدم:**
    *   `[ ]` 6.3.1. إضافة Hero animations / `flutter_animate`.
    *   `[ ]` 6.3.2. إنشاء ملفات الأيقونات والشعار (`flutter_launcher_icons`?).
    *   `[ ]` 6.3.3. مراجعة شاملة لـ UX/UI والتناسق.
    *   `[ ]` 6.3.4. مراجعة نهائية للترجمات ودعم RTL.
    *   `[ ]` 6.3.5. بناء وتضمين شاشات Onboarding (`introduction_screen`?).
    *   `[ ]` 6.3.6. مراجعة أساسيات الوصولية.
*   **6.4. تطوير وعرض الإحصائيات في الـ Backend:**
    *   `[ ]` 6.4.1. بناء واجهة عرض الإحصائيات المحسوبة في لوحة التحكم.
*   **6.5. إضافة تسجيل الأخطاء:**
    *   `[ ]` 6.5.1. تهيئة Sentry/Firebase Crashlytics SDK.
    *   `[ ]` 6.5.2. استخدام `try-catch` مع `Sentry.captureException`.

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
