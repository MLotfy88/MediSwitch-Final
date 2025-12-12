# 🏗️ هيكل المشروع - Project Structure

/root/workspace/project
├── .devcontainer/             # إعدادات بيئة التطوير (VS Code Dev Container)
├── .github/                   # GitHub Actions (CI/CD)
├── .gemini/                   # ذاكرة المساعد الذكي (Memory Bank)
├── memory-bank/               # توثيق المشروع (Memory Bank Documentation)
├── android/                   # ملفات بناء Android Native
├── ios/                       # ملفات بناء iOS Native
├── lib/                       # كود تطبيق Flutter (Dart)
│   ├── core/                  # المكونات الأساسية (Errors, UseCases, Utils)
│   ├── data/                  # طبقة البيانات (Repositories Impl, DataSources, Models)
│   ├── domain/                # طبقة المجال (Entities, Repositories Interfaces, UseCases)
│   ├── presentation/          # طبقة العرض (Screens, Widgets, Providers)
│   └── main.dart              # نقطة دخول التطبيق
├── assets/                    # الموارد (Images, Data JSONs, Icons)
│   └── data/                  # بيانات أولية (Interactions, Ingredients)
├── cloudflare-worker/         # ✅ الواجهة الخلفية (Backend API)
│   ├── src/                   # كود الـ Worker (JavaScript)
│   ├── schema_users.sql       # مخطط قاعدة بيانات المستخدمين (D1)
│   ├── schema_config.sql      # مخطط إعدادات التطبيق والإعلانات
│   ├── schema_interactions.sql# مخطط التفاعلات الدوائية
│   ├── schema_notifications.sql # مخطط الإشعارات
│   ├── wrangler.toml          # إعدادات النشر على Cloudflare
│   └── package.json           # تبعيات الـ Worker
├── admin-dashboard/           # ✅ لوحة التحكم (React + Vite)
│   ├── src/                   # كود واجهة لوحة التحكم
│   ├── public/                # الملفات العامة للوحة التحكم
│   └── vite.config.ts         # إعدادات البناء (Vite)
├── app_prompt.md              # الأوامر الأساسية للمساعد
└── pubspec.yaml               # ملف تعريف مشروع Flutter والتبعيات

---

## 🚀 هيكلية النشر (Deployment Architecture)

### 1. 📱 تطبيق الجوال (Flutter App)
- **المنصة:** Android & iOS.
- **تخزين البيانات:**
    - **محلياً:** `sqflite` (بيانات الأدوية، المفضلة).
    - **سحابياً:** المزامنة مع Cloudflare D1 عبر Worker API.

### 2. ⚡ الواجهة الخلفية (Backend - Cloudflare Workers)
- **التقنية:** Serverless Functions (JavaScript).
- **الاستضافة:** شبكة Cloudflare العالمية (Edge Network).
- **المسارات:** `https://mediswitch-api.admin-lotfy.workers.dev`
- **الوظائف:**
    - مصادقة المشرفين (Admin Auth).
    - إدارة الاشتراكات والمستخدمين.
    - مزامنة البيانات (Delta Sync).
    - إرسال الإشعارات.

### 3. 💾 قاعدة البيانات (Cloudflare D1)
- **النوع:** SQL موزعة (Distributed SQLite).
- **الاستخدام:** تخزين مركزي للمستخدمين، الإعدادات، الإشعارات، وسجلات التغييرات.

### 4. 🖥️ لوحة التحكم (Admin Dashboard - Cloudflare Pages)
- **التقنية:** React, TypeScript, Vite, TailwindCSS.
- **الاستضافة:** Cloudflare Pages (Static Site Hosting).
- **الرابط:** متصل بالنطاق الفرعي للمشروع (e.g., `admin.mediswitch...`).
- **المميزات:**
    - إدارة كاملة للمحتوى.
    - تحكم في الإعلانات (Granular Control).
    - إرسال إشعارات فورية.
    - مراقبة الإحصائيات.