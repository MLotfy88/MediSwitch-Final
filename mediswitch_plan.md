بالتأكيد، سأقوم بإعادة كتابة الخطة مع إضافة ترقيم فرعي للمهام لتسهيل التتبع والمتابعة بشكل دقيق.

---

### **خطة عمل تطبيق MediSwitch (فائقة التفصيل مع ترقيم فرعي)**

**الاستراتيجية المعتمدة:**
*   **البيانات:** Excel/CSV كمصدر أساسي، يُعالج في الـ Frontend (تم التحول إلى SQLite).
*   **الأداء:** أولوية قصوى للمعالجة في الخلفية (Isolates)، هياكل بيانات مُحسّنة (SQLite + Indexes)، وتحسينات UI (Pagination).
*   **الجودة:** تطبيق Clean Architecture، كود نظيف، اختبارات شاملة، CI/CD.
*   **المرونة:** الاستعداد لتقييم DB محلي (Hive/Isar) لاحقًا إذا كان الأداء غير كافٍ.

---

### **المرحلة 0: التأسيس والتخطيط (الأسبوع 1)**

*   **0.1. تأكيد المتطلبات النهائية والتخطيط:**
    *   `[x]` 0.1.1. مراجعة واعتماد استراتيجية "Excel/CSV كقاعدة بيانات" للمعالجة في Frontend (تم التحول إلى SQLite).
    *   `[x]` 0.1.2. اعتماد HTTPS فقط لتأمين نقل الملفات.
    *   `[x]` 0.1.3. اعتماد آلية تحديث عبر فحص الإصدار عند التشغيل مع إشعار للمستخدم (تم التعطيل مؤقتاً).
    *   `[x]` 0.1.4. تحديد إطار عمل الـ Backend النهائي (مثل Node.js/Express أو Python/Django). (Django chosen)
    *   `[x]` 0.1.5. تحديد حل إدارة الحالة النهائي في Flutter (تم اعتماد Provider حالياً).
    *   `[x]` 0.1.6. تحديد وتطبيق حل حقن التبعيات النهائي (تم استخدام get_it).
        *   `[x]` 0.1.6.1. اختيار المكتبة النهائية (get_it).
        *   `[x]` 0.1.6.2. إعداد `locator.dart` وتسجيل التبعيات (DataSources, Repositories, UseCases, Providers).
        *   `[x]` 0.1.6.3. تحديث `main.dart` لتهيئة Locator وتوفير Providers.
        *   `[x]` 0.1.6.4. إعادة هيكلة الشاشات (مثل `DrugDetailsScreen`) لاستخدام Providers من Locator.
*   **0.2. إعداد بيئات التطوير والمستودعات:**
    *   `[ ]` 0.2.1. تثبيت/تحديث Flutter SDK (>= 3.x.x) وتكوين دعم Android/iOS/Web. (Assume user environment matches env.md)
    *   `[ ]` 0.2.2. تثبيت أدوات بناء الـ Backend المختارة. (Python/Django assumed installed)
    *   `[x]` 0.2.3. إعداد مستودع Git مركزي (Monorepo أو منفصل).
    *   `[ ]` 0.2.4. إعداد بيئة التطوير المحلية (IDE, API Client). (Assume user environment matches env.md)
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
    *   `[x]` 0.6.3. إنشاء نموذج أولي (Prototype) لاختبار قراءة Excel/CSV باستخدام `compute()`. (Implemented in CsvLocalDataSource, now uses SQLite)
*   **0.7. تصميم الواجهة (UI/UX) الأولي:**
    *   `[x]` 0.7.1. استخدام النموذج الأولي للواجهة (`medi-switch-design-lab-main`) كمرجع أساسي للـ Wireframes والتصميم.
    *   `[x]` 0.7.2. اعتماد لوحة الألوان والخطوط المحددة في (`medi-switch-design-lab-main`).

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
        *   `[x]` 2.1.1.1. تنفيذ استدعاء `GET /api/v1/data/version`.
        *   `[x]` 2.1.1.2. تنفيذ استدعاء `GET /api/v1/data/latest-drugs.{ext}`.
        *   `[x]` 2.1.1.3. معالجة أخطاء الشبكة.
    *   `[x]` 2.1.2. **`LocalDataSource`:** (تم التحول إلى `SqliteLocalDataSource`)
        *   `[x]` 2.1.2.1. استخدام `path_provider` للحصول على مسار التخزين (يتم داخلياً في sqflite).
        *   `[x]` 2.1.2.2. تنفيذ حفظ الملف المُنزَّل (يتم عبر `saveDownloadedCsv` الذي يحول إلى SQLite).
        *   `[x]` 2.1.2.3. تنفيذ دالة `parseExcelCsvFile(filePath)` (تم استبدالها بـ `_parseCsvForSeed` و `insertMedicinesBatch`).
        *   `[x]` 2.1.2.4. تنفيذ قراءة/كتابة آخر إصدار/تاريخ تحديث محلي (`shared_preferences`).
    *   `[x]` 2.1.3. **`DrugRepositoryImpl`:**
        *   `[x]` 2.1.3.1. تنفيذ دالة `getAllDrugs()` للتحقق من التحديث، التنزيل، التحليل (تم التعطيل مؤقتاً).
        *   `[x]` 2.1.3.2. بناء فهارس (تم إضافتها في `DatabaseHelper._onCreate`).
        *   `[x]` 2.1.3.3. تحويل `List<MedicineModel>` إلى `List<DrugEntity>`.
        *   `[x]` 2.1.3.4. تخزين البيانات في SQLite (لا يتم التخزين في الذاكرة).
        *   `[x]` 2.1.3.5. معالجة الأخطاء وإرجاع حالة مناسبة (`Either<Failure, ...>`).
*   **2.2. بناء طبقة المجال (`Domain Layer`):**
    *   `[x]` 2.2.1. تعريف `DrugEntity` (تم التحديث ليشمل `oldPrice`).
    *   `[x]` 2.2.2. تعريف `DrugRepository` interface (تم التحديث لدعم Pagination).
    *   `[x]` 2.2.3. بناء Use Cases الأساسية (GetAllDrugs, SearchDrugs, FilterDrugsByCategory, GetAvailableCategories, FindDrugAlternatives).
*   **2.3. إدارة الحالة للبيانات:**
    *   `[x]` 2.3.1. إعداد `MedicineProvider` (تم التحديث لدعم Pagination).
    *   `[x]` 2.3.2. ربط حالات التحميل (`isLoading`, `error`, `data`) بالواجهة.

---

### **المرحلة 3: تطوير الواجهة الأمامية - واجهة المستخدم والميزات الأساسية (الأسبوع 6-10)**

*   **3.1. الواجهة الأساسية والشاشة الرئيسية (`HomeScreen`):** (تمت إعادة الهيكلة بناءً على Design Lab - انظر المرحلة 6)
    *   `[x]` 3.1.1. `MaterialApp`: السمات، اللغات، التوجيه (تم تحديث Theme).
    *   `[x]` 3.1.2. `HomeScreen`: استخدام `CustomScrollView` و `HomeHeader`.
    *   `[x]` 3.1.3. عرض حالة تحميل البيانات.
    *   `[x]` 3.1.4. `BottomNavigationBar`: التنقل بين الشاشات الرئيسية (`MainScreen`).
    *   `[x]` 3.1.5. بناء `HomeHeader` و `SearchBarButton`.
    *   `[x]` 3.1.6. بناء أقسام أفقية (الفئات).
    *   `[x]` 3.1.7. تطبيق التصميم المتجاوب (ListView/GridView).
*   **3.2. شاشة البحث (`SearchScreen`) وتفاصيل الدواء (`DrugDetailsScreen`):** (تمت إعادة الهيكلة بناءً على Design Lab - انظر المرحلة 6)
    *   `[x]` 3.2.1. `SearchScreen`: `AppBar` مخصص مع حقل بحث نشط وزر فلترة.
    *   `[x]` 3.2.2. `SearchProvider`/`Bloc`: إدارة حالة البحث.
    *   `[x]` 3.2.3. تطبيق `Debouncer` على `TextField`.
    *   `[x]` 3.2.4. تنفيذ منطق البحث/الفلترة في Provider/Bloc.
    *   `[x]` 3.2.5. بناء `FilterBottomSheet`.
    *   `[x]` 3.2.6. `ListView.builder`/`GridView.builder` لعرض النتائج.
    *   `[x]` 3.2.7. `DrugDetailsScreen`: شاشة مخصصة مع `NestedScrollView` و `TabBar`.
        *   `[x]` 3.2.7.1. بناء `Header` لعرض معلومات الدواء الأساسية والصورة.
        *   `[x]` 3.2.7.2. بناء قسم السعر (جزء من Header).
        *   `[x]` 3.2.7.3. بناء `TabBar` و `TabBarView` للأقسام.
        *   `[x]` 3.2.7.4. بناء محتوى تبويب "معلومات".
        *   `[x]` 3.2.7.5. بناء محتوى تبويب "البدائل".
        *   `[x]` 3.2.7.6. بناء محتوى تبويب "الجرعات".
        *   `[x]` 3.2.7.7. بناء محتوى تبويب "التفاعلات".
    *   `[x]` 3.2.8. عرض المعلومات الأساسية (في تبويب "معلومات").
    *   `[x]` 3.2.9. زر "إيجاد البدائل" (في تبويب "البدائل").
    *   `[x]` 3.2.10. زر "المفضلة" (Premium) (UI مضاف، المنطق مؤجل).
    *   `[x]` 3.2.11. استخدام `CachedNetworkImage`.
*   `[ ]` **3.3. شاشة حاسبة الجرعة (`weight_calculator_screen.dart`):** (مؤجلة لإصدار 1.1 - MVP 1.0 يتضمن زر معطل/رسالة "قريباً").
    *   `[x]` 3.3.1. `DoseCalculatorProvider`. (الكود موجود لكن الميزة مؤجلة)
    *   `[x]` 3.3.2. بناء الفورم. (الكود موجود لكن الميزة مؤجلة)
    *   `[x]` 3.3.3. إضافة `Form Validation`.
    *   `[x]` 3.3.4. تحديد هياكل البيانات.
    *   `[x]` 3.3.5. بناء خدمة حساب الجرعات.
    *   `[x]` 3.3.6. تكامل الخدمة مع Provider.
    *   `[x]` 3.3.7. تحديث واجهة المستخدم.
    *   `[x]` 3.3.8. زر "حفظ الحساب" (Premium) (UI مضاف، المنطق مؤجل).
*   `[x]` **3.4. شاشة البدائل والأدوية المماثلة (`AlternativesScreen`):** (تم دمجها في `DrugDetailsScreen`).
*   `[ ]` **3.5. شاشة مدقق التفاعلات (`InteractionCheckerScreen`):** (مؤجلة لإصدار 1.2 - MVP 1.0 يتضمن زر معطل/رسالة "قريباً").
    *   `[x]` 3.5.1. تحديد هياكل البيانات. (الكود موجود لكن الميزة مؤجلة)
    *   `[x]` 3.5.2. بناء خدمة/مستودع بيانات التفاعلات. (الكود موجود لكن الميزة مؤجلة)
    *   `[x]` 3.5.3. بناء خدمة تحليل التفاعلات.
    *   `[x]` 3.5.4. إدارة الحالة (`InteractionProvider`).
    *   `[x]` 3.5.5. بناء واجهة المستخدم. (الكود موجود لكن الميزة مؤجلة)
*   `[x]` **3.6. شاشة الإعدادات (`SettingsScreen`):** (تم تحديث التصميم - انظر المرحلة 6).
    *   `[x]` 3.6.1. `SettingsProvider`.
    *   `[x]` 3.6.2. بناء الواجهة.
    *   `[x]` 3.6.3. تنفيذ تغيير اللغة والمظهر.
    *   `[x]` 3.6.4. بناء واجهة إدارة الاشتراك.
    *   `[x]` 3.6.5. استخدام `url_launcher` للروابط.
    *   `[x]` 3.6.6. زر "التحقق من التحديث".
    *   `[x]` 3.6.7. عرض تاريخ آخر تحديث.
*   **3.7. دعم العمل دون اتصال:**
    *   `[x]` 3.7.1. مراجعة الشاشات للتأكد من عملها بدون اتصال (يعتمد على SQLite).
    *   `[x]` 3.7.2. عرض رسالة مناسبة في حالة عدم وجود بيانات/اتصال.

---

### **المرحلة 4: تطوير الواجهة الخلفية - ميزات إضافية (الأسبوع 11)**

*   **4.1. تحسينات إدارة ملف Excel/CSV:**
    *   `[x]` 4.1.1. إضافة تحقق أكثر تفصيلاً.
    *   `[x]` 4.1.2. عرض رسائل خطأ واضحة.
    *   `[x]` 4.1.3. عرض معلومات إضافية عن الملف.
*   **4.2. إدارة الإعلانات (AdMob Config):**
    *   `[x]` 4.2.1. تصميم نموذج بيانات للإعدادات.
    *   `[x]` 4.2.2. بناء واجهة للأدمن في لوحة التحكم.
    *   `[x]` 4.2.3. إنشاء نقطة نهاية API `GET /api/v1/config/ads`.
*   **4.3. إعدادات التطبيق العامة:**
    *   `[x]` 4.3.1. تصميم نموذج بيانات (روابط).
    *   `[x]` 4.3.2. بناء واجهة للأدمن.
    *   `[x]` 4.3.3. إنشاء نقطة نهاية API `GET /api/v1/config/general`.
*   **4.4. استقبال وتحليل الإحصائيات:**
    *   `[x]` 4.4.1. إنشاء `POST /api/v1/analytics/log` لاستقبال أنواع أحداث.
    *   `[x]` 4.4.2. بناء منطق تحليل البيانات.

---

### **المرحلة 5: تطوير الواجهة الأمامية - الإعلانات والاشتراكات (الأسبوع 12-13)**

*   **5.1. جلب الإعدادات من الـ Backend:**
    *   `[x]` 5.1.1. بناء `ConfigRepository` و Use Cases لجلب الإعدادات.
*   `[x]` **5.2. تنفيذ الإعلانات:** (مكتمل لـ MVP 1.0 باستخدام Test IDs)
    *   `[x]` 5.2.1. تهيئة `google_mobile_ads`.
    *   `[x]` 5.2.2. بناء `BannerAdWidget`.
    *   `[x]` 5.2.3. بناء خدمة لإدارة `InterstitialAd`.
*   **5.3. تنفيذ نظام الاشتراك (Premium):** (مؤجل لما بعد MVP 1.0)
    *   `[x]` 5.3.1. تهيئة `in_app_purchase`.
    *   `[x]` 5.3.2. عرض خيارات الشراء (`SubscriptionScreen`).
    *   `[x]` 5.3.3. تنفيذ عمليات الشراء والاستعادة.
    *   `[~]` 5.3.4. التحقق من صحة الإيصالات (يتطلب Backend).
    *   `[~]` 5.3.5. تحديث حالة المستخدم (Premium) (المنطق الأساسي موجود).
    *   `[~]` 5.3.6. التحكم في عرض الإعلانات والميزات Premium.
*   **5.4. إرسال الإحصائيات التفصيلية:**
    *   `[x]` 5.4.1. بناء `AnalyticsService`.
    *   `[~]` 5.4.2. استدعاء `AnalyticsService` من الأماكن المناسبة.

---

### **المرحلة 6: تطبيق التصميم الجديد (Design Lab Implementation)**

*   **6.1. تحليل التصميم الجديد:**
    *   `[x]` 6.1.1. استكشاف هيكل ملفات التصميم.
    *   `[x]` 6.1.2. تحديد الشاشات والمكونات الرئيسية.
    *   `[x]` 6.1.3. استخلاص دليل الأسلوب.
*   **6.2. تطبيق الشاشات الرئيسية:** (ملاحظة: التطابق العام ~80-85% مع التصميم المرجعي)
    *   `[~]` 6.2.1. إعادة بناء `HomeScreen`. (مكتملة بشكل كبير، تحتاج مراجعة للتباعدات الدقيقة وتأثيرات التحويم)
    *   `[~]` 6.2.2. إعادة بناء `SearchScreen` و `FilterBottomSheet`. (مكتملة بشكل كبير، `FilterBottomSheet` تختلف عن التصميم - BottomSheet بدلاً من Side Sheet)
    *   `[~]` 6.2.3. إعادة بناء `DrugDetailsScreen`. (مكتملة بشكل كبير، تحتاج مراجعة للتباعدات الدقيقة وتأثيرات التحويم، عنصر حجم العبوة مفقود)
    *   `[x]` 6.2.4. إعادة بناء `AlternativesScreen` (مدمجة).
    *   `[~]` 6.2.5. إعادة بناء `WeightCalculatorScreen`. (مكتملة بشكل كبير، تحتاج مراجعة للتباعدات الدقيقة وتأثيرات التحويم)
    *   `[~]` 6.2.6. إعادة بناء `InteractionCheckerScreen`. (مكتملة بشكل كبير، تحتاج مراجعة للتباعدات الدقيقة وتأثيرات التحويم)
    *   `[~]` 6.2.7. إعادة بناء `SettingsScreen`. (مكتملة بشكل كبير، تحتاج مراجعة للتباعدات الدقيقة وتأثيرات التحويم)
    *   `[~]` 6.2.8. إعادة بناء `SubscriptionScreen`. (مكتملة بشكل كبير، تحتاج مراجعة للتباعدات الدقيقة وتأثيرات التحويم)
    *   `[x]` 6.2.9. إعادة بناء `OnboardingScreen`.
*   **6.3. تطبيق المكونات المشتركة:**
    *   `[~]` 6.3.1. إعادة بناء `DrugCard`. (مكتملة بشكل كبير، تحتاج مراجعة للتباعدات الدقيقة، علامة "شائع" وشارة "بديل" مفقودة)
    *   `[~]` 6.3.2. إعادة بناء أو تعديل `SectionHeader`. (مكتملة بشكل كبير، تحتاج مراجعة للتباعدات الدقيقة)
    *   `[~]` 6.3.3. إنشاء/تعديل Widgets مخصصة أخرى (`HomeHeader`, `HorizontalListSection`, `CategoryCard`, `SearchBarButton`, `CustomBadge`). (مكتملة بشكل كبير، تحتاج مراجعة للتباعدات الدقيقة، `CategoryCard` بعرض ثابت)
*   **6.4. تطبيق الأصول الجديدة:**
    *   `[x]` 6.4.1. استخدام الأيقونات الجديدة (Lucide Icons).
    *   `[x]` 6.4.2. استخدام الصور التوضيحية (لا يوجد).
    *   `[x]` 6.4.3. تحديث أيقونة التطبيق وشعار البداية.
*   **6.5. تطبيق Animations:**
    *   `[~]` 6.5.1. تنفيذ انتقالات الشاشات والتأثيرات (تم إضافة أساسيات، تأثيرات التحويم غير مطبقة).
*   **6.6. مراجعة RTL والترجمة:**
    *   `[~]` 6.6.1. التأكد من دعم RTL الكامل. (مطبق بشكل عام، يحتاج مراجعة نهائية)
    *   `[ ]` 6.6.2. (مؤجل) البدء في استخراج النصوص للترجمة.
*   **6.7. مراجعة Accessibility:**
    *   `[~]` 6.7.1. مراجعة Semantics و Contrast و Tap Targets (تم إضافة أساسيات، يحتاج مراجعة نهائية).
    *   [ ] **التحكم الديناميكي في الواجهة عبر الـ Backend:** (ميزة مستقبلية لزيادة المرونة)
        *   [ ] (Backend) تصميم وإضافة Models ونقاط API لإدارة إعدادات الواجهة المختلفة.
        *   [ ] (Frontend) تعديل التطبيق لجلب هذه الإعدادات وتطبيقها ديناميكيًا.
        *   **أمثلة على الإعدادات الممكنة:**
            *   تغيير ألوان الثيم الأساسية (Primary, Secondary, Background...).
            *   تغيير ألوان وأحجام النصوص الأساسية.
            *   إظهار/إخفاء أقسام معينة في الشاشة الرئيسية (مثل بانر ترويجي، قسم مميز).
            *   تغيير ترتيب ظهور الأقسام في الشاشة الرئيسية.
            *   تحديد عدد العناصر الأقصى في القوائم الأفقية (الأدوية المحدثة/الشائعة).
            *   تفعيل/تعطيل ميزات تجريبية (Feature Flags).

---

### **المرحلة 7: الاختبار والنشر (الأسبوع 15-16)**

*   **7.1. الاختبار الشامل:**
    *   `[ ]` 7.1.1. **Unit Tests**.
    *   `[ ]` 7.1.2. **Widget Tests**.
    *   `[ ]` 7.1.3. **Integration Tests**.
    *   `[ ]` 7.1.4. **الاختبار اليدوي**.
    *   `[ ]` 7.1.5. **Beta Testing**.
*   **7.2. إعدادات النشر:**
    *   `[x]` 7.2.1. تكوين `appicon` و `splash screen`.
    *   `[ ]` 7.2.2. مراجعة وتحديث `build.gradle` و `Info.plist`.
    *   `[ ]` 7.2.3. إنشاء وتأمين Android Keystore.
    *   `[ ]` 7.2.4. إنشاء وتكوين iOS Certificates & Provisioning Profiles.
    *   `[ ]` 7.2.5. تحليل حجم التطبيق.
*   **7.3. النشر:**
    *   `[ ]` 7.3.1. نشر الـ Backend (Production).
    *   `[ ]` 7.3.2. إعداد CI/CD.
    *   `[ ]` 7.3.3. النشر اليدوي المبدئي أو باستخدام CI/CD.

---

### **المرحلة 8: التوثيق والتسليم (الأسبوع 17)**

*   **8.1. توثيق الكود:**
    *   `[ ]` 8.1.1. التأكد من وجود DartDoc شامل.
    *   `[ ]` 8.1.2. مراجعة التعليقات في Backend.
*   **8.2. توثيق المشروع:**
    *   `[ ]` 8.2.1. كتابة `ADMIN_GUIDE.md`.
    *   `[ ]` 8.2.2. كتابة `API_DOCS.md`.
    *   `[ ]` 8.2.3. كتابة `DEVELOPER_GUIDE.md`.
    *   `[ ]` 8.2.4. كتابة `USER_GUIDE.md`.
*   **8.3. التسليم النهائي:**
    *   `[ ]` 8.3.1. مراجعة نهائية للكود والمستودعات.
    *   `[ ]` 8.3.2. تسليم الوصوليات.
    *   `[ ]` 8.3.3. اجتماع التسليم وشرح المشروع.

---

هذه الخطة الآن مُحدّثة لتعكس التقدم المحرز في تطبيق التصميم الجديد وملاحظات مراجعة التصميم.
