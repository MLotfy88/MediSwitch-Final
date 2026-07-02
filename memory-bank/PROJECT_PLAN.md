# 📋 خطة المشروع المحدثة - MediSwitch

## ✅ المراحل المكتملة

### المرحلة 1: Flutter App Design Compliance ✅
- [x] Backdrop Blur
- [x] Hover Effects
- [x] 0 TypeScript/Dart errors
- [x] رفع على GitHub

### المرحلة 2: Infrastructure Setup ✅
- [x] حذف submodules القديمة
- [x] ربط admin-dashboard
- [x] npm environment setup
- [x] VS Code configuration

### 3. تحميل ومعالجة البيانات (GitHub Action)
- [x] إنشاء ملف Workflow: `.github/workflows/ddinter_scraper_test.yml`.
- [x] تطوير سكربت `bulk_scraper_v5.py`:
    - [x] استخراج اسم المادة الفعالة بشكل صريح.
    - [x] فصل البيانات (ATC Codes, External Links) في أعمدة منفصلة.
    - [x] تصحيح منطق اكتشاف التفاعلات (AJAX Discovery Fix) بجلب كافة النتائج (`length=5000`).
    - **إدارة المخرجات:** تحويل البيانات الهرمية إلى ملف JSON منظم، وإنتاج ملفات CSV مبسطة.
- **استراتيجية الموبايل (Mobile IP Rotation):** استخدام تطبيق Termux على نظام الأندرويد لسهولة تغيير الـ IP عبر تفعيل/تعطيل نمط الطيران (Airplane Mode).
- **الأرشفة المؤتمتة (Auto-Commit):** حفظ النتائج مباشرة في المستودع بعد كل تشغيل.
- **التعامل مع الأحجام الكبيرة:** تقسيم الملفات التي تتجاوز 50 ميجابايت إلى أجزاء مضغوطة صغيرة لضمان توافقها مع GitHub.
- **النسخة الصاروخية (Turbo Mode):** توفير نسخة بدون تأخيرات زمنية للتشغيل المحلي السريع مع تنبيه المستخدم بالمخاطر.
- [x] تنفيذ التشغيل التجريبي المحلي للتأكد من جودة البيانات.

### المرحلة 4: Admin Dashboard Build Fixes ✅
- [x] CSS import order
- [x] Configuration.tsx syntax
- [x] Local build success
- [x] Push to GitHub

### المرحلة 5: Specialized Screens Implementation ✅
- [x] HomeScreen Refactoring & Design System Integration
- [x] DrugDetailsScreen Implementation
- [x] SettingsScreen & ProfileScreen Updates
- [x] SearchScreen & SearchResultsScreen Logic
- [x] WeightCalculatorScreen Logic & UI
- [x] Core Entities Updates (DrugEntity, DosageResult)
- [x] Widget Refactoring (ModernDrugCard, ModernCategoryCard, SectionHeader)
- [x] Error Resolution (Imports, Params, Linter)

### المرحلة 5: Design Documentation Review & Compliance ✅
- [x] ModernBadge Component (100% Matched with badge.md)
- [x] ModernBottomNavBar (100% Matched with bottom-nav.md)
- [x] Badge Usages Review (ModernDrugCard, InteractionCard, WeightCalculatorScreen)
- [x] AppColors Verification (100% Matched with design-system.md)
- [x] All Screens Verified Against Design Docs

### المرحلة 6: Theme-Aware Colors Implementation ✅
- [x] ModernCategoryCard (theme-aware)
- [x] HomeScreen (theme-aware)
- [x] AppHeader (theme-aware)
- [x] ModernDrugCard (theme-aware)
- [x] SectionHeader (theme-aware)
- [x] DangerousDrugCard (theme-aware)
- [x] ModernSearchBar (theme-aware)
- [x] Medical Specialties (100% matched icons & counts)

### المرحلة 7: Backend & Admin Dashboard Integration ✅
- [x] Cloudflare Worker Setup & Deploy
- [x] D1 Database Schema Integration
- [x] Phase 7: Admin Dashboard Data Management Sync (All columns visible & toggleable)
- [x] Phase 8: UI & Performance Refinement (Splash screen update & Home screen caching)
- [x] Monetization System (Ads Granularity)
- [x] Notifications System (Backend & Frontend)

### المرحلة 8: Admin Dashboard "Strategy Command Center" Refactor ✅
- [x] Monetization 2.0 (Sponsored Drugs, IAP)
- [x] Clinical Lab (Unified Inventory, Dosage Wizard)
- [x] Phase 4: Runtime Stability & Bug Fixes (Completed 2025-12-23)
  - [x] Add missing D1 tables (analytics_daily, subscriptions)
  - [x] Implement price type safety in Worker & Dashboard
  - [x] Final production deployment verification
- [x] User Intelligence (Persona Mapping, Churn Sentinel)
- [x] Feedback Hub & System Watch
- [x] Campaign Commander Wizard
- [x] Space Command Aesthetic Integration

### المرحلة 9: D1 Sync System & Flutter Alignment ✅
- [x] Cloudflare Worker update for D1 multi-table sync
- [x] Flutter Models refactoring (Clinical Interaction Rules)
- [x] Manual & Background (2:00 AM) Sync Logic
- [x] Compilation Error Resolution (Entity/Repo/UI)

### المرحلة 10: Monetization & Notifications 3.0 ✅
- [x] تفعيل نظام Feature Gating (التحكم في الميزات لكل اشتراك)
- [x] تحديث واجهة إدارة الـ IAP لإضافة الصلاحيات (Permissions)
- [x] إصلاح نظام الإشعارات في Flutter (Background Polling)
- [x] تحسين إدارة الأدوية الممولة (Company field & payload fix)
- [x] النشر النهائي للإنتاج (Cloudflare Pages/Worker/D1)

### المرحلة 11: Database Data Integrity & Scraper v11 ✅
- [x] فحص شامل لقاعدة بيانات DDInter واكتشاف الأعمدة الفارغة (ATC, Disease Interactions).
- [x] تحديث سكربت `ultimate_scraper_v10.py` لدعم جلب البيانات الناقصة.
- [x] إضافة دعم جلب "تفاعلات الأدوية مع الأمراض" (Drug-Disease Interactions).
- [x] دعم استخراج الـ ATC Codes والروابط الخارجية وبنية الـ SVG.
- [x] التحقق من نجاح الجلب عبر تشغيل تجريبي على 5 أدوية.
- [x] تحديث لوحة التحكم (Admin Dashboard) لإضافة إدارة تفاعلات الأمراض (Disease Interactions).
- [x] تحديث بنية الـ Worker API لدعم البيانات الجديدة.
- [x] إصلاح أخطاء الـ `DrugRepositoryImpl` في Flutter.
- [x] تحديث ملف `.gitignore` لاستبعاد الملفات الضخمة.

---

## 🔄 المرحلة الحالية: Maintenance & Optimization

### Flutter App
- [x] Implement `NotificationsScreen`
- [x] Interaction Checker & Dosage Calculator tools
- [x] Ad Config Integration
- [x] **Phase 6: UI Refinement**
  - [x] Refactor interactions into compact cards.
  - [x] Integrate detailed bottom sheet for all interaction types (Drug-Drug, Food, Disease).
  - [x] Add severity support for disease interactions.
- [x] Unified Sync System (Manual & Background)
- [x] Fix High Risk Ingredient Names & Badge Display Issues (Dec 25, 2025)
  - Fixed SQL query to return original case ingredient names using MAX Length logic
  - Verified meds.csv visits data
  - Added `_applyDrugFlags` helper in MedicineProvider
  - Applied flags across all drug loading methods
  - Removed duplicate `copyWith` code from UI screens
  - **Fixed Parsing Bug:** Filtered out "interactions", "pro", etc. during seeding by blocking invalid ingredient names.

---

### المرحلة 12: Admin Dashboard & Cloudflare D1 Finalization ✅
- [x] إدارة تفاعلات الأمراض (Admin UI & API)
- [x] تحديث هيكل تفاعلات الأدوية (Risk Level, Management, Mechanism)
- [x] حل مشكلة البيانات الثابتة في التفاعلات (Seeding Fix)
- [x] حذف شاشة الـ Onboarding وتبسيط مسار التشغيل
- [x] إصلاح أخطاء الـ Repository في Flutter وتحسين الـ Lints

---

## 📅 الجدول الزمني

### المرحلة 13: Cloudflare Worker & Dashboard CRUD Finalization ✅ (Jan 02, 2026)
- [x] **Cloudflare Worker Audit**: تم فحص الكود ومعالجة الدوال المفقودة (`create`, `get`, `delete`).
- [x] **26-Column Support**: توسيع نطاق الـ API ليشمل كافة بيانات الأدوية (السريرية والإدارية).
- [x] **Flutter Alignment**: تصحيح تسمية `trade_name` لضمان التوافق التام مع واجهة الـ API.
- [x] **Admin Dashboard CRUD**: بناء واجهة إضافة وتعديل متكاملة (Dialog) تدعم كافة حقول البيانات.
- [x] **Production Deployment**: نشر الـ Worker ولوحة التحكم بنجاح باستخدام رموز الوصول (Tokens) الرسمية.

---

### المرحلة 14: Hybrid Architecture & D1 Database Split ✅ (Jan 03, 2026)
- [x] **D1 Database Split**: إنشاء قاعدة `mediswitch-interactions` ونقل 320,000 سجل تفاعلات إليها.
- [x] **Storage Limit Fix**: حذف جداول التفاعلات من قاعدة البيانات الرئيسية لتوفير مساحة لتحديثات الأسعار.
- [x] **App Size Reduction**: حذف ملفات الـ JSON الضخمة من المشروع (تحويل الحجم من 250MB إلى 40MB).
- [x] **Hybrid Data Flow**: تطبيق منطق الجلب من الـ API عند الحاجة مع التخزين المؤقت (Local Caching).
- [x] **Worker API Refactor**: تحديث الـ Worker لدعم توجيه الطلبات للقاعدة الجديدة تلقائياً.

### Phase 15: Dosage Tab Clinical Accuracy (UI Refinement & Data Integrity) ✅ (Jan 04, 2026)
- [x] **UI Redesign**: إعادة تصميم واجهة الجرعات لمنع بتر النصوص الطويلة.
- [x] **Full Visibility**: فصل التعليمات الطبية في سطر مستقل لضمان ظهورها كاملة.
- [x] **Calculator Integration**: ربط الحاسبة باقتراحات الجرعات المباشرة من قاعدة البيانات.
- [x] **Null-Safety & Stability**: إصلاح كافة أخطاء البرمجة والتحقق لضمان استقرار التبويبة.

### Phase 16: WikEM + NCBI Dosage Integration ✅ (Jan 12, 2026)
- [x] **جلب بيانات WikEM**: استخدام scraper موجود لجلب 3,214 دواء من wikem.org
- [x] **معالجة WikEM**: تحليل وaستخراج 2,513 سجل جرعات منظمة (min/max dose, route, frequency)
- [x] **مطابقة NCBI**: مطابقة 250 مكون فعال بقاعدة StatPearls
- [x] **دمج NCBI**: استخراج 37,080 سجل جرعات سريرية (indications, administration, contraindications)
- [x] **تحديث السكيما**: إضافة أعمدة `wikem_*` و `ncbi_*` لفصل المصادر
- [x] **تحديث Flutter**: تعديل DosageTab و Models لقراءة البيانات الجديدة
- [x] **إزالة Attribution**: حذف كل إشارات أسماء المصادر من الواجهة
- [x] **التحقق**: تأكيد تغطية 69.5% من قاعدة البيانات (17,745 من 25,538 دواء)
- [x] **Phase 17: Dosage UI & D1 Sync Repair** (Jan 13, 2026)
    - [x] **D1 Repair**: Resolved `UNIQUE constraint` by excluding local IDs and `SQLITE_TOOBIG` by truncating blobs (10KB limit).
    - [x] **UI Enhancement**: Removed gradient, added structured cards (Route, Category, Dose, Freq), and deduplicated instructions.
    - [x] **Structural Fix**: Repaired Dart syntax errors in `dosage_tab.dart`.

---

## 📅 الجدول الزمني

| المهمة | الحالة | التاريخ |
|:---|:---:|:---|
| Design Compliance | ✅ | Dec 6 |
| Admin Build Fix | ✅ | Dec 6 |
| Specialized Screens | ✅ | Dec 7 |
| Design Doc Review | ✅ | Dec 7 |
| UI Design Fixes | ✅ | Dec 8 |
| Final Testing & Release Prep | ✅ | Dec 18 |
| Interaction & Dosage Tools | ✅ | Dec 19 |
| Strategy Command Center Deploy | ✅ | Dec 23 |
| D1 Sync & Flutter Alignment | ✅ | Dec 23 |
| Admin Dashboard & D1 Finalization | ✅ | Dec 30 |
| Interaction UI & Sync Optimization | ✅ | Jan 10 |
| Cloudflare CRUD & Deploy | ✅ | Jan 02 |
| Hybrid Architecture & D1 Split | ✅ | Jan 03 |
| Dosage Tab Clinical Accuracy | ✅ | Jan 04 |

---

## 🎯 الأولويات القادمة

1. **فحص واختبار لوحة التحكم**: تشغيل React Dashboard محلياً وإجراء الفحوصات الحية للعمليات (CRUD) والتحكم بالإعدادات ومزامنة التغييرات مع قواعد البيانات السحابية D1.
2. **التحكم برخص الميزات (Feature Gating)**: ربط حالة `SubscriptionProvider.isPremiumUser` برمجياً لإلغاء الإعلانات تلقائياً في شاشات الجوال وقفل/فتح المفضلات المتقدمة.
3. **تفعيل بوابة التحقق للاشتراكات**: إضافة مسار `/api/subscriptions/verify` في الـ Worker السحابي لاستقبال تفاصيل الشراء من الجوال وتخزينها سحابياً.
4. **اختبار المزامنة اليدوية**: إجراء اختبارات حية للمزامنة الفروقية اليدوية عبر الضغط على التحديث في الهاتف وملاحظة سرعة وسلامة تدفق البيانات.
5. **تهيئة ملفات النشر النهائي للمتاجر (Google Play / App Store)**.
