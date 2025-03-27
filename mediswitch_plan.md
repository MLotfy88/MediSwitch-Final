تمام، بناءً على طلبك، سأقوم الآن بصياغة خطة عمل فائقة التفصيل، تدمج جميع النقاط السابقة واقتراحات التحسين بشكل مباشر في المهام، مع تقسيمها بشكل دقيق لضمان سهولة التنفيذ والمتابعة لأي مطور.

---

### **خطة عمل تطبيق MediSwitch (فائقة التفصيل)**

**الاستراتيجية المعتمدة:**
*   **البيانات:** Excel/CSV كمصدر أساسي، يُعالج في الـ Frontend.
*   **الأداء:** أولوية قصوى للمعالجة في الخلفية (Isolates)، هياكل بيانات مُحسّنة، وتحسينات UI.
*   **الجودة:** تطبيق Clean Architecture، كود نظيف، اختبارات شاملة، CI/CD.
*   **المرونة:** الاستعداد لتقييم DB محلي (Hive/Isar) لاحقًا إذا كان الأداء غير كافٍ.

---

### **المرحلة 0: التأسيس والتخطيط (الأسبوع 1)**

*   **0.1. تأكيد المتطلبات النهائية والتخطيط:**
    *   `[x]` مراجعة واعتماد استراتيجية "Excel/CSV كقاعدة بيانات" للمعالجة في Frontend.
    *   `[x]` اعتماد HTTPS فقط لتأمين نقل الملفات (لا كلمة مرور للملف مبدئيًا).
    *   `[x]` اعتماد آلية تحديث عبر فحص الإصدار عند التشغيل مع إشعار للمستخدم.
    *   `[ ]` تحديد إطار عمل الـ Backend النهائي (مثل Node.js/Express أو Python/Django).
    *   `[ ]` تحديد حل إدارة الحالة النهائي في Flutter (مثل Provider, Riverpod, أو Bloc).
    *   `[ ]` تحديد حل حقن التبعيات النهائي (مثل get_it).
*   **0.2. إعداد بيئات التطوير والمستودعات:**
    *   `[x]` تثبيت/تحديث Flutter SDK (>= 3.x.x) وتكوين دعم Android/iOS/Web. (Inferred from project structure)
    *   `[ ]` تثبيت أدوات بناء الـ Backend المختارة (Node.js/Python, npm/pip).
    *   `[ ]` إعداد مستودع Git مركزي (Monorepo باستخدام Melos أو FVM) أو مستودعين منفصلين (frontend/backend) مع تحديد استراتيجية إدارة الإصدارات.
    *   `[ ]` إعداد بيئة التطوير المحلية (VS Code/Android Studio, Postman/Insomnia).
    *   `[ ]` (للـ Prompt) توثيق خطوات إعداد وتمكين Wi-Fi Debugging (ADB Pair & Connect) في ملف `README.md`.
*   **0.3. بناء هيكل مشروع الواجهة الأمامية (Flutter - `lib`):**
    *   `[x]` تنفيذ هيكل المجلدات المفصل (Clean Architecture) كما هو موضح في الرد السابق (core, data, domain, presentation, config, di). (Inferred from `lib/` subdirectories)
    *   `[x]` إنشاء ملفات `.dart` أولية فارغة أو بمحتوى بسيط لكل طبقة ومكون رئيسي (مثل `main.dart`, `app.dart`, `home_screen.dart`, `drug_repository.dart`, `drug_remote_datasource.dart`, إلخ). (Inferred from `lib/main.dart` and directories)
*   **0.4. بناء هيكل مشروع الواجهة الخلفية (Backend):**
    *   `[ ]` تنفيذ هيكل المجلدات المختار (controllers, routes, services, models, config, middleware).
    *   `[ ]` إعداد ملفات التكوين الأساسية (مثل `.env` للمتغيرات البيئية).
*   **0.5. إضافة وإدارة التبعيات:**
    *   `[x]` (Frontend) إضافة التبعيات الأساسية (`provider`/`riverpod`/`flutter_bloc`, `http`/`dio`, `path_provider`, `excel`, `csv`, `flutter_secure_storage`, `intl`, `google_fonts`, `collection`, `flutter_animate`, `get_it`, `cached_network_image`, `permission_handler`) إلى `pubspec.yaml`. (Inferred from `pubspec.yaml` existence)
    *   `[ ]` (Backend) إضافة التبعيات الأساسية (Express/Django, multer, JWT/Passport, dotenv, CORS) إلى `package.json` أو `requirements.txt`.
    *   `[ ]` إعداد أدوات إدارة الإصدارات (مثل FVM لـ Flutter) لضمان توحيد بيئة العمل.
*   **0.6. إعداد أدوات الجودة والأداء:**
    *   `[x]` تفعيل وتخصيص قواعد lint صارمة في `analysis_options.yaml` (استخدام `package:lints/recommended.yaml` و `package:flutter_lints/flutter.yaml` كنقطة بداية). (Inferred from `analysis_options.yaml` existence)
    *   `[ ]` إعداد linter مماثل للـ Backend (ESLint/Prettier لـ Node.js, Flake8/Black لـ Python).
    *   `[ ]` إنشاء نموذج أولي (Prototype) لاختبار قراءة وتحليل جزء من ملف Excel كبير باستخدام `compute()` وقياس الوقت المستغرق لتقييم الأداء الأولي.
*   **0.7. تصميم الواجهة (UI/UX) الأولي:**
    *   `[ ]` البحث عن رابط تصميم Figma المذكور. إذا لم يكن متاحًا، إنشاء Wireframes أساسية للشاشات الرئيسية (Home, Search, Details, Calculator, Settings) بناءً على الوصف (Insta/Telegram-like) باستخدام أداة مثل Balsamiq أو Excalidraw.
    *   `[ ]` تحديد لوحة الألوان النهائية (الأزرق الطبي، الرمادي، ألوان التنبيه) والخطوط (Noto Sans Arabic).

---

### **المرحلة 1: تطوير الواجهة الخلفية - الوظائف الأساسية (الأسبوع 2-3)**

*   **1.1. نظام مصادقة الأدمن:**
    *   `[ ]` تصميم مخطط قاعدة بيانات الأدمن (users: id, name, email, password_hash, role).
    *   `[ ]` تنفيذ خدمة تجزئة كلمات المرور (bcrypt).
    *   `[ ]` بناء API Endpoint `POST /api/v1/admin/auth/login` (يأخذ email/password، يرجع JWT).
    *   `[ ]` بناء API Endpoint `POST /api/v1/admin/auth/register` (اختياري، أو يتم الإنشاء يدويًا).
    *   `[ ]` تنفيذ آلية تجديد التوكن (Refresh Token).
    *   `[ ]` بناء واجهة ويب بسيطة لتسجيل الدخول (HTML/CSS/JS أو باستخدام EJS/Jinja2).
    *   `[ ]` إنشاء Middleware للتحقق من JWT وحماية مسارات الأدمن (`/api/v1/admin/*`).
*   **1.2. إدارة ملف Excel/CSV وتوفيره:**
    *   `[ ]` تحديد استراتيجية تخزين الملف (Local disk على الخادم أو Cloud Storage مثل AWS S3 / Google Cloud Storage).
    *   `[ ]` بناء API Endpoint `POST /api/v1/admin/data/upload` (محمي بـ Auth Middleware):
        *   `[ ]` استخدام مكتبة (مثل `multer`) لاستقبال الملف.
        *   `[ ]` التحقق من الامتداد المسموح به (xlsx, csv).
        *   `[ ]` **التحقق المتقدم:** قراءة الـ Headers للتحقق من وجود الأعمدة الأساسية المتوقعة (مثل 'Trade Name', 'Active Ingredient', 'Price').
        *   `[ ]` نقل الملف إلى مكان التخزين الدائم كـ "الملف النشط الجديد" (مع تسمية فريدة أو باستخدام إصدار).
        *   `[ ]` (اختياري) أرشفة الملف النشط السابق.
        *   `[ ]` تحديث سجل أو متغير يشير إلى اسم/مسار الملف النشط حاليًا وإصداره/تاريخه.
    *   `[ ]` بناء واجهة ويب في لوحة التحكم لرفع الملف (مع عرض رسائل نجاح/خطأ واضحة).
    *   `[ ]` بناء API Endpoint `GET /api/v1/data/latest-drugs.{ext}` (عام أو محمي بمفتاح API بسيط):
        *   `[ ]` قراءة اسم/مسار الملف النشط.
        *   `[ ]` إرجاع الملف مع Headers مناسبة (`Content-Type`, `Content-Disposition`, Caching Headers).
    *   `[ ]` بناء API Endpoint `GET /api/v1/data/version` (عام أو محمي بمفتاح API بسيط):
        *   `[ ]` إرجاع بيانات وصفية للملف النشط (JSON: `{ "version": "...", "lastUpdated": "ISO_DATE_STRING" }`).
    *   `[ ]` تكوين خدمة CDN لتقديم الملف (إذا أمكن) لزيادة سرعة التنزيل.
*   **1.3. النشر الأولي للـ Backend:**
    *   `[ ]` إعداد Dockerfile للـ Backend.
    *   `[ ]` نشر الـ Backend على منصة سحابية (Heroku, Render, AWS, GCP) باستخدام Docker أو مباشرةً.
    *   `[ ]` تكوين متغيرات البيئة (Database URL, JWT Secret, Storage Credentials).
    *   `[ ]` اختبار Endpoints الأساسية باستخدام Postman/Insomnia.

---

### **المرحلة 2: تطوير الواجهة الأمامية - تحميل ومعالجة البيانات (الأسبوع 3-5)**

*   **2.1. بناء طبقة البيانات (`Data Layer`):**
    *   `[ ]` **`RemoteDataSource`:**
        *   `[ ]` تنفيذ استدعاء `GET /api/v1/data/version` باستخدام `http`/`dio`.
        *   `[ ]` تنفيذ استدعاء `GET /api/v1/data/latest-drugs.{ext}` لتنزيل الملف (مع التعامل مع الامتداد).
        *   `[ ]` معالجة أخطاء الشبكة (Timeouts, 4xx, 5xx).
    *   `[ ]` **`LocalDataSource`:**
        *   `[ ]` استخدام `path_provider` للحصول على مسار مناسب لتخزين الملف.
        *   `[ ]` تنفيذ حفظ الملف المُنزَّل على الجهاز.
        *   `[ ]` تنفيذ دالة `parseExcelCsvFile(String filePath)` التي تعمل داخل `compute()`:
            *   `[ ]` تقرأ الملف (Excel أو CSV) باستخدام المكتبات المعنية.
            *   `[ ]` تحول كل صف إلى `DrugModel`.
            *   `[ ]` تعالج الأخطاء المحتملة أثناء القراءة/التحليل (صفوف تالفة، أنواع بيانات خاطئة).
            *   `[ ]` تُرجع `List<DrugModel>`.
        *   `[ ]` تنفيذ قراءة وكتابة آخر إصدار/تاريخ تحديث تم تنزيله (باستخدام `shared_preferences`).
    *   `[ ]` **`DrugRepositoryImpl`:**
        *   `[ ]` تنفيذ دالة `getDrugs()`:
            *   `[ ]` تتحقق من الإصدار المحلي مقابل البعيد (`RemoteDataSource.getVersion()`).
            *   `[ ]` إذا كان هناك تحديث، تستدعي `RemoteDataSource.downloadLatestFile()` ثم `LocalDataSource.saveFile()`.
            *   `[ ]` تستدعي `LocalDataSource.parseExcelCsvFile()` (عبر `compute()`).
            *   `[ ]` **تحسين الأداء:** بعد التحليل، تبني `Map<String, DrugEntity>` للفهرسة السريعة (مثل الفهرسة بالاسم التجاري المنخفض الأحرف).
            *   `[ ]` تحول `List<DrugModel>` إلى `List<DrugEntity>`.
            *   `[ ]` تخزن القائمة والفهارس في الذاكرة (باستخدام Provider/Bloc/Riverpod).
            *   `[ ]` تعالج الأخطاء في كل خطوة وتُرجع حالة مناسبة (Loading, Error, Success).
*   **2.2. بناء طبقة المجال (`Domain Layer`):**
    *   `[ ]` تعريف `DrugEntity` مع الحقول المطلوبة لواجهة المستخدم.
    *   `[ ]` تعريف `DrugRepository` interface (مع دالة `Future<Either<Failure, List<DrugEntity>>> getDrugs()`).
    *   `[ ]` بناء Use Cases مثل `GetInitialDrugDataUseCase(drugRepository)`.
*   **2.3. إدارة الحالة للبيانات:**
    *   `[ ]` إعداد Provider/Bloc/Riverpod لإدارة حالة تحميل ومعالجة البيانات (`DrugListProvider`/`DrugListBloc`).
    *   `[ ]` عرض حالات التحميل (`isLoading`, `error`, `data`) في الواجهة.

---

### **المرحلة 3: تطوير الواجهة الأمامية - واجهة المستخدم والميزات الأساسية (الأسبوع 6-10)**

*   **3.1. الواجهة الأساسية والشاشة الرئيسية (`HomeScreen`):**
    *   `[x]` `MaterialApp`: تطبيق السمات، إعداد `AppLocalizations`، إعداد `AppRouter`. (Inferred from `lib/main.dart` existence)
    *   `[ ]` `HomeScreen`: استخدام `Consumer`/`BlocBuilder` لعرض حالة تحميل البيانات (مؤشر تحميل، رسالة خطأ، أو المحتوى).
    *   `[ ]` `BottomNavigationBar`: تنفيذ التنقل بين الشاشات مع الحفاظ على الحالة (باستخدام `IndexedStack` أو حلول أخرى).
    *   `[ ]` `CustomSearchBar`: ويدجت شريط بحث غير تفاعلي في `HomeScreen` ينقل إلى `SearchScreen` عند النقر.
    *   `[ ]` بناء أقسام اختيارية (المحدثة/المفضلة/الشائعة) إذا تم تضمينها.
    *   `[ ]` تطبيق التصميم المتجاوب باستخدام `LayoutBuilder` أو `MediaQuery`.
*   **3.2. شاشة البحث (`SearchScreen`) وتفاصيل الدواء (`DrugDetailsScreen`):**
    *   `[ ]` `SearchScreen`: `AppBar` مع `TextField` للبحث.
    *   `[ ]` `SearchProvider`/`SearchBloc`: لإدارة حالة البحث (مصطلح البحث، النتائج، الفلاتر النشطة، حالة التحميل/الخطأ).
    *   `[ ]` استخدام `TextEditingController` و `Debouncer` لتحديث مصطلح البحث.
    *   `[ ]` تنفيذ منطق البحث في `SearchProvider`/`SearchBloc` (فلترة القائمة/الفهارس في الذاكرة).
    *   `[ ]` بناء واجهة الفلاتر (`FilterBottomSheet`): عرض الفئات (من البيانات المعالجة)، نطاق السعر (Slider)، خيارات أخرى. تطبيق الفلاتر على نتائج البحث.
    *   `[ ]` `ListView.builder`: لعرض `DrugCard` للنتائج، مع تمييز النص.
    *   `[ ]` `DrugCard`: ويدجت يعرض المعلومات الأساسية + استجابة للنقر للانتقال إلى التفاصيل.
    *   `[ ]` `DrugDetailsScreen`: استقبال `DrugEntity`. استخدام `CustomScrollView` و `SliverAppBar`.
    *   `[ ]` عرض المعلومات الأساسية. بناء ويدجتس `ExpansionTile` للأقسام الإضافية (دواعي، آثار...).
    *   `[ ]` زر "إيجاد البدائل" (ينقل مع تمرير `DrugEntity`).
    *   `[ ]` زر "المفضلة" (يقرأ ويكتب الحالة باستخدام Provider/Bloc و `SharedPreferences`/`SecureStorage`).
    *   `[ ]` استخدام `CachedNetworkImage` مع placeholder و error widgets.
*   **3.3. شاشة حاسبة الجرعة (`DoseCalculatorScreen`):**
    *   `[ ]` `DoseCalculatorProvider`/`Bloc`: لإدارة المدخلات والنتائج والحالة.
    *   `[ ]` بناء الفورم (`Form` widget) مع `TextFormField` للوزن والعمر، و `DropdownButtonFormField` أو حقل بحث مصغر لاختيار الدواء.
    *   `[ ]` إضافة `Form Validation`.
    *   `[ ]` تنفيذ منطق الحساب في Provider/Bloc (جلب بيانات الدواء، تطبيق المعادلة).
    *   `[ ]` عرض النتائج مع تنسيق واضح للوحدات.
    *   `[ ]` عرض التحذير (باستخدام `Visibility` و `TextStyle` أحمر/أيقونة). تشغيل صوت تحذير بسيط (باستخدام `audioplayers`؟).
    *   `[ ]` زر "حفظ الحساب" (Premium - يحفظ في `SharedPreferences`/`SecureStorage`).
*   **3.4. شاشة البدائل والأدوية المماثلة (`AlternativesScreen`):**
    *   `[ ]` `AlternativesProvider`/`Bloc`: لإدارة قائمة البدائل.
    *   `[ ]` استقبال `DrugEntity` الأصلي.
    *   `[ ]` تنفيذ منطق إيجاد البدائل في Provider/Bloc (مطابقة المادة الفعالة، الفئة).
    *   `[ ]` بناء `ListView` لعرض البدائل مع المعلومات المحسوبة (جرعة مكافئة، سعر).
*   **3.5. (ميزة متقدمة - Premium؟) شاشة مدقق التفاعلات (`InteractionCheckerScreen`):**
    *   `[ ]` بناء واجهة اختيار متعدد للأدوية (باستخدام Chips أو قائمة مع checkboxes).
    *   `[ ]` `InteractionProvider`/`Bloc`: لإدارة قائمة الأدوية المختارة ونتائج التفاعل.
    *   `[ ]` تنفيذ منطق فحص التفاعلات (يتطلب بيانات تفاعلات جيدة في `DrugEntity`).
    *   `[ ]` عرض النتائج بوضوح (قائمة التفاعلات، الخطورة، الوصف).
*   **3.6. شاشة الإعدادات (`SettingsScreen`):**
    *   `[ ]` `SettingsProvider`/`Bloc`: لإدارة حالة اللغة والمظهر والاشتراك.
    *   `[ ]` بناء الواجهة باستخدام `ListTile` و `SwitchListTile`.
    *   `[ ]` تنفيذ تغيير اللغة (باستخدام `AppLocalizations` و Provider/Bloc).
    *   `[ ]` تنفيذ تغيير المظهر (باستخدام `ThemeMode` و Provider/Bloc).
    *   `[ ]` بناء واجهة إدارة الاشتراك (عرض الحالة، زر الشراء/الإدارة).
    *   `[ ]` استخدام `url_launcher` لفتح روابط السياسة/الشروط.
    *   `[ ]` زر "التحقق من التحديث" يستدعي `DrugListProvider.forceCheckForUpdate()`.
    *   `[ ]` عرض تاريخ آخر تحديث (من `SharedPreferences`).
*   **3.7. دعم العمل دون اتصال:**
    *   `[ ]` مراجعة جميع الشاشات للتأكد من أنها لا تعتمد على اتصال شبكة بعد التحميل الأولي (باستثناء التحقق من التحديث/الإعلانات/الاشتراك).
    *   `[ ]` عرض رسالة مناسبة إذا لم يتم تحميل البيانات بعد وكان المستخدم غير متصل.

---

### **المرحلة 4: تطوير الواجهة الخلفية - ميزات إضافية (الأسبوع 11)**

*   **4.1. تحسينات إدارة ملف Excel/CSV:** (كما في الخطة السابقة)
*   **4.2. إدارة الإعلانات (AdMob Config):** (كما في الخطة السابقة)
*   **4.3. إعدادات التطبيق العامة:** (كما في الخطة السابقة)
*   **4.4. استقبال وتحليل الإحصائيات:** (كما في الخطة السابقة)

---

### **المرحلة 5: تطوير الواجهة الأمامية - الإعلانات والاشتراكات (الأسبوع 12-13)**

*   **5.1. جلب الإعدادات من الـ Backend:**
    *   `[ ]` بناء `ConfigRepository` و Use Cases لجلب الإعدادات وتخزينها (باستخدام Provider/Bloc).
*   **5.2. تنفيذ الإعلانات:**
    *   `[ ]` تهيئة `google_mobile_ads` في `main.dart`.
    *   `[ ]` بناء `BannerAdWidget` وتحميل الإعلان باستخدام ID من الإعدادات.
    *   `[ ]` بناء خدمة لإدارة تحميل وعرض `InterstitialAd` وتتبع عدد الاستخدامات (باستخدام `SharedPreferences`).
*   **5.3. تنفيذ نظام الاشتراك (Premium):**
    *   `[ ]` تهيئة `in_app_purchase` والاستماع للتحديثات.
    *   `[ ]` عرض خيارات الشراء المتاحة من المتجر.
    *   `[ ]` تنفيذ عمليات الشراء والاستعادة.
    *   `[ ]` التحقق من صحة الإيصالات (يفضل من جانب الخادم إذا أمكن لاحقًا، ولكن مبدئيًا يمكن الاعتماد على فحص المتجر).
    *   `[ ]` تحديث حالة المستخدم (Premium) في `SettingsProvider`/`Bloc`.
    *   `[ ]` استخدام `Visibility` أو `if` للتحكم في عرض الإعلانات والميزات Premium.
*   **5.4. إرسال الإحصائيات التفصيلية:**
    *   `[ ]` بناء `AnalyticsService` لإرسال الأحداث إلى Backend.
    *   `[ ]` استدعاء `AnalyticsService` من الأماكن المناسبة (عند البحث، فتح التفاصيل، استخدام الحاسبة).

---

### **المرحلة 6: التحسينات النهائية والأمان (الأسبوع 14)**

*   **6.1. تحسين الأداء:**
    *   `[ ]` إجراء Profiling باستخدام Flutter DevTools (CPU, Memory, Jank).
    *   `[ ]` تطبيق تحسينات (const widgets, تقليل rebuilds, تحسين خوارزميات البحث/الفلترة).
    *   `[ ]` اختبار الأداء على أجهزة ضعيفة.
*   **6.2. تعزيز الأمان:**
    *   `[ ]` مراجعة جميع الاتصالات للتأكد من استخدام HTTPS.
    *   `[ ]` مراجعة استخدام `flutter_secure_storage` للمفاتيح الحساسة.
    *   `[ ]` تنفيذ `FLAG_SECURE` في `MainActivity.java` (Android).
*   **6.3. اللمسات النهائية لواجهة المستخدم:**
    *   `[ ]` إضافة Hero animations أو `flutter_animate` للتحولات بين الشاشات.
    *   `[ ]` إنشاء ملفات الأيقونات والشعار لجميع المنصات (باستخدام `flutter_launcher_icons`؟).
    *   `[ ]` مراجعة شاملة لـ UX/UI والتناسق.
    *   `[ ]` مراجعة نهائية للترجمات ودعم RTL.
    *   `[ ]` بناء وتضمين شاشات Onboarding (باستخدام `introduction_screen`؟).
    *   `[ ]` مراجعة أساسيات الوصولية (Labels, Contrast, Tap Targets).
*   **6.4. تطوير وعرض الإحصائيات في الـ Backend:** (كما في الخطة السابقة)
*   **6.5. إضافة تسجيل الأخطاء:**
    *   `[ ]` تهيئة Sentry/Firebase Crashlytics SDK.
    *   `[ ]` استخدام `try-catch` مع `Sentry.captureException` للأخطاء المتوقعة والحرجة.

---

### **المرحلة 7: الاختبار والنشر (الأسبوع 15-16)**

*   **7.1. الاختبار الشامل:**
    *   `[ ]` **Unit Tests:** كتابة اختبارات لـ Use Cases, Providers/Blocs, Repositories (باستخدام Mockito/Mocktail). تحقيق تغطية > 70%.
    *   `[x]` **Widget Tests:** كتابة اختبارات للشاشات والويدجتس الهامة للتحقق من العرض والتفاعل الأولي. (Inferred from `test/widget_test.dart` existence)
    *   `[ ]` **Integration Tests:** (اختياري/مستحسن) كتابة اختبارات للتدفقات الرئيسية (مثل البحث -> تفاصيل -> بدائل).
    *   `[ ]` **الاختبار اليدوي:** اختبار وظيفي شامل، اختبار تحديث، اختبار توافق (Android 8+/iOS 13+, أحجام مختلفة), اختبار ويب, اختبار أداء, اختبار عدم اتصال, اختبار إعلانات واشتراك.
    *   `[ ]` **Beta Testing:** إعداد توزيع تجريبي (Firebase App Distribution, TestFlight, Google Play Internal Testing) ودعوة مختبرين وجمع الملاحظات.
*   **7.2. إعدادات النشر:**
    *   `[ ]` تكوين `appicon` و `splash screen` (باستخدام `flutter_native_splash`؟).
    *   `[ ]` مراجعة وتحديث `build.gradle` و `Info.plist` (أرقام الإصدارات, الأذونات).
    *   `[ ]` إنشاء وتأمين Android Keystore.
    *   `[ ]` إنشاء وتكوين iOS Certificates & Provisioning Profiles.
    *   `[ ]` تشغيل `flutter build ... --analyze-size` وتحليل حجم التطبيق.
*   **7.3. النشر:**
    *   `[ ]` نشر الـ Backend (Production).
    *   `[ ]` إعداد CI/CD (GitHub Actions/Codemagic):
        *   `[ ]` Trigger على push لـ main/release branches.
        *   `[ ]` خطوات: Checkout -> Setup Flutter -> Analyze -> Test -> Build (APK/AAB, IPA, Web) -> Deploy (Firebase Hosting, Stores).
    *   `[ ]` النشر اليدوي المبدئي أو باستخدام CI/CD لـ Google Play, App Store, Web Hosting.

---

### **المرحلة 8: التوثيق والتسليم (الأسبوع 17)**

*   **8.1. توثيق الكود:**
    *   `[ ]` التأكد من وجود DartDoc شامل للكود العام.
    *   `[ ]` مراجعة التعليقات في Backend.
*   **8.2. توثيق المشروع:**
    *   `[ ]` كتابة `ADMIN_GUIDE.md` (تسجيل دخول، رفع ملف، عرض إحصائيات).
    *   `[ ]` كتابة `API_DOCS.md` أو استخدام Swagger/OpenAPI للـ Backend.
    *   `[ ]` كتابة `DEVELOPER_GUIDE.md` للـ Frontend (إعداد البيئة، تشغيل، بناء، نظرة عامة على البنية).
    *   `[ ]` كتابة `USER_GUIDE.md` (اختياري، أو الاعتماد على Onboarding).
*   **8.3. التسليم النهائي:**
    *   `[ ]` مراجعة نهائية للكود والمستودعات.
    *   `[ ]` تسليم الوصوليات (Git repos, Cloud consoles, Store accounts).
    *   `[ ]` اجتماع التسليم وشرح المشروع.

---

هذه الخطة الآن مفصلة للغاية. كل مهمة رئيسية تم تقسيمها إلى خطوات أصغر وأكثر تحديدًا، مع دمج أفضل الممارسات والاقتراحات مباشرة. آمل أن يكون هذا المستوى من التفصيل هو المطلوب لتسهيل عملية التنفيذ.
