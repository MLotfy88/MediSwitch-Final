# نظرة عامة على إعداد مشروع MediSwitch

هذا المستند يقدم نظرة عامة على كيفية إعداد وتشغيل بيئة تطوير ونشر مشروع MediSwitch.

## مكونات المشروع الرئيسية

يتكون المشروع من جزأين رئيسيين:

1.  **تطبيق Flutter (الواجهة الأمامية - Frontend):**
    *   الكود موجود في المستودع الرئيسي: `https://github.com/MLotfy88/MediSwitch-Final.git`
    *   يعمل على نظامي Android و iOS.
    *   يحتوي على واجهات المستخدم ومنطق العرض الخاص بالتطبيق.
    *   يتصل بالواجهة الخلفية (Backend) للحصول على بيانات الأدوية والإعدادات.

2.  **الواجهة الخلفية (Backend - Django):**
    *   الكود موجود في مستودع منفصل: `https://github.com/MLotfy88/MediSwitch_Backend.git`
    *   مبني باستخدام إطار عمل Django (Python).
    *   مسؤول عن إدارة قاعدة بيانات الأدوية، توفير API للتطبيق، وتوفير لوحة تحكم لإدارة البيانات.

## بيئة التطوير

*   **الأساس:** يتم استخدام حاوية Docker مخصصة (`flutter-container`) مبنية من صورة `flutter-dev-env`.
*   **المحتويات:** تحتوي هذه الحاوية على جميع الأدوات اللازمة لتطوير Flutter (Flutter SDK, Android SDK, Java, Gradle, etc.).
*   **الكود:** عند بدء تشغيل الحاوية، يقوم سكريبت `setup.sh` باستنساخ المستودع الرئيسي (`MediSwitch-Final`) إلى المسار `/home/adminlotfy/project` *داخل الحاوية*. (ملاحظة: كود الـ backend داخل هذا المسار هو الآن مستودع Git منفصل أيضاً).
*   **الوصول:** يتم الوصول إلى بيئة التطوير هذه عبر VS Code باستخدام امتداد Remote - SSH، حيث يتصل VS Code بخدمة SSH التي تعمل داخل الحاوية على المنفذ 2222 (المربوط من الخادم المضيف).
*   **التعديلات:** تتم تعديلات الكود (Flutter و Backend) داخل هذه الحاوية باستخدام VS Code.

## بيئة النشر (الإنتاج - Production)

*   **الموقع:** تعمل هذه البيئة مباشرة على الخادم المضيف (Host OS - VPS IP: `37.27.185.59`).
*   **الإدارة:** يتم إدارتها باستخدام Docker Compose.
*   **المجلدات:**
    *   **الكود المصدري للـ Backend:** يتم استنساخه من مستودع `MediSwitch_Backend` إلى `/home/adminlotfy/mediswitch_backend_source` على الخادم المضيف.
    *   **ملفات النشر والبيانات:** يتم تخزينها في `/home/adminlotfy/mediswitch_deployment` على الخادم المضيف، وتحتوي على:
        *   `.env`: متغيرات البيئة والأسرار.
        *   `docker-compose.yml`: ملف تعريف الخدمات والحاويات.
        *   `nginx_config/`: ملفات إعداد Nginx.
        *   `postgres_data/`: بيانات قاعدة بيانات PostgreSQL (Volume).
        *   `media_files/`: الملفات المرفوعة (Volume).
        *   `static_files/`: الملفات الثابتة المجمعة (Volume).
*   **الخدمات (الحاويات):**
    1.  `db`: حاوية قاعدة بيانات PostgreSQL.
    2.  `backend`: حاوية تطبيق Django/Gunicorn (تُبنى باستخدام `Dockerfile` من مجلد المصدر).
    3.  `nginx`: حاوية Nginx تعمل كـ Reverse Proxy وتخدم الملفات الثابتة والميديا.
*   **الوصول:**
    *   يتم الوصول إلى الـ API ولوحة التحكم عبر عنوان IP العام للخادم: `http://37.27.185.59`.
    *   Nginx يستقبل الطلبات على المنفذ 80 ويمررها إلى حاوية الـ backend.
*   **التحديث:** يتم عن طريق:
    1.  دفع التغييرات إلى مستودع Git الخاص بالـ Backend.
    2.  سحب التغييرات (`git pull`) في مجلد المصدر على الخادم المضيف.
    3.  إعادة بناء صورة الـ backend (`docker-compose build backend`) في مجلد النشر.
    4.  إعادة تشغيل الخدمات (`docker-compose down && docker-compose up -d`) في مجلد النشر.

هذه النظرة العامة توضح الفصل بين بيئة التطوير النشطة وبيئة النشر المستقرة.