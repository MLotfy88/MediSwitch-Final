# السياق التقني للمشروع - MediSwitch (Tech Context)

## 📄 المراجع الأساسية
*   [env.md](file:///f:/App-Projects/mediswitch/memory-bank/env.md) - تفاصيل إصدارات وأدوات بيئة التطوير المحلية.
*   [database_architecture.md](file:///f:/App-Projects/mediswitch/memory-bank/database_architecture.md) - مخطط ومحرك البيانات.

---

## 💻 التقنيات والإصدارات الفعلية المستخدمة (Tech Stack)

### 1. تطبيق الجوال (Flutter Mobile App)
*   **إطار العمل**: Flutter إصدار `3.29.2` (Stable Channel).
*   **لغة البرمجة**: Dart إصدار `3.7.2`.
*   **المكتبات الأساسية (الاعتماديات الفعالة في `pubspec.yaml`)**:
    *   `provider`: لإدارة الحالة.
    *   `sqflite`: محرك التعامل مع قاعدة البيانات المحلية SQLite (الإصدار الحالي للسكيما هو **V16**).
    *   `http`: لإجراء الاتصالات مع الـ API الخلفي للـ Worker.
    *   `get_it`: لتسجيل وحقن الخدمات والتبعيات برمجياً.
    *   `google_mobile_ads`: لعرض الوحدات الإعلانية من AdMob.
    *   `in_app_purchase`: للتعامل مع عمليات الشراء داخل التطبيق والاشتراكات.
    *   `flutter_local_notifications`: لعرض الإشعارات المحلية عند استقبالها في الخلفية.
    *   `cached_network_image`: لتخزين صور الأدوية مؤقتاً في ذاكرة الهاتف.
    *   `shared_preferences`: لتخزين الإعدادات البسيطة مثل اللغات والسمات وتواريخ آخر تحديث ومسارات الإشعارات.
    *   `archive`: لفك ضغط سجلات الجرعات الكبيرة المضغوطة بـ zlib عند استرجاعها.
*   **إعدادات البناء لنظام الأندرويد**:
    *   `compileSdk`: 35
    *   `minSdk`: 28 (يتوافق مع أجهزة أندرويد 9.0 فما فوق)
    *   `targetSdk`: 35
    *   `Kotlin JVM Target`: 17
    *   `Java SDK (JDK)`: 23.0.2

### 2. الواجهة الخلفية (Backend - Cloudflare Serverless)
*   **خادم الـ API**: `Cloudflare Workers` (JavaScript / ES Module format).
*   **محرك قواعد البيانات**: `Cloudflare D1` (Distributed SQLite) مجزأ إلى قاعدتين:
    *   `mediswitsh-db` (الأساسية)
    *   `mediswitch-interactions` (التفاعلات الطبية)
*   **إصدار التوافق (Compatibility Date)**: `2024-12-08`
*   **التحليلات والتحديثات التلقائية**: تكامل كامل مع GitHub Actions لأرشفة البيانات وسحبها تلقائياً بـ Python.

### 3. لوحة التحكم (Admin Dashboard - Web)
*   **إطار العمل**: React مع Vite و TypeScript.
*   **التنسيق والتصميم**: Tailwind CSS مع مكتبة Lucide Icons وشاشات مخصصة تفاعلية.
*   **الاستضافة**: استضافة سحابية على خوادم **Cloudflare Pages**.

---

## 🛠️ عناوين الاتصال الرسمية (Endpoints)

*   **API Base URL (Default)**: `https://mediswitch-api.m-m-lotfy-88.workers.dev`
*   **Admin Dashboard URL**: `https://mediswitch-admin-dashboard.pages.dev/`
*   **Endpoints المستخدمة في التطبيق**:
    *   `/api/config`: لجلب إعدادات الوحدات الإعلانية AdMob من الخادم.
    *   `/api/v1/config/general/`: لجلب الروابط والسياسات العامة للتطبيق.
    *   `/api/sync/version`: للتحقق من وجود تحديثات دوائية جديدة.
    *   `/api/sync/drugs`: لسحب التعديلات الفروقية للأدوية (Delta Sync) بالاعتماد على تاريخ آخر تحديث.
    *   `/api/interactions`: لجلب التفاعلات الخاصة بالدواء عند الطلب.
    *   `/api/notifications`: لجلب الإشعارات الإدارية.
    *   `/api/admin/subscriptions`: لإدارة وعرض الاشتراكات (مفعل في لوحة التحكم).

---

## ⚠️ القيود والمحددات الفنية (Technical Constraints)

1.  **العمل دون اتصال**: الميزات الحيوية (البحث والبدائل وحساب الجرعات القياسية) يجب أن تعمل بالكامل أوفلاين.
2.  **الأمان المتقدم**:
    *   منع لقطات الشاشة أو تسجيل الفيديو لشاشات الجرعات الدوائية لحماية الخصوصية (في أجهزة Android).
    *   تشفير قواعد البيانات محلياً بـ SQLCipher (مخطط له وموثق في الرؤية العامة).
3.  **مساحة التخزين وحجم التطبيق**: لا يمكن حفظ تفاعلات الأدوية بالكامل (320,000+ سجل) داخل حزمة التطبيق، لذلك تم تطبيق بنية الـ Caching المحدودة للتفاعلات المطلوبة فقط لتفادي تضخم الحجم وضمان سرعة الهاتف.
