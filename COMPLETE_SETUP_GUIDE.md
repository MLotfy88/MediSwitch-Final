# 📚 دليل MediSwitch الشامل - من الصفر للنشر

## 🎯 نظرة عامة

هذا الدليل يغطي **كل شيء** من البداية للنهاية:
1. ✅ إعداد GitHub Actions للتحديث اليومي
2. ✅ نشر Cloudflare Worker + D1
3. ✅ تحديث قاعدة بيانات التطبيق
4. ✅ دفع الكود لجميع المستودعات

---

## 📋 الجزء الأول: إعداد GitHub Actions

### ✅ الخطوة 1: التحقق من الملفات الموجودة

تأكد من وجود هذه الملفات:
```
✓ scraper.py
✓ enrich_data.py  
✓ csv_to_json.py
✓ requirements.txt
✓ .github/workflows/daily-update.yml
```

### ✅ الخطوة 2: إعداد GitHub Secrets

اذهب إلى: **GitHub Repository → Settings → Secrets and variables → Actions**

أضف هذه Secrets:

| Key | Value | الوصف |
|-----|-------|-------|
| `DWAPRICES_PHONE` | `01558166440` | رقم الهاتف لموقع dwaprices |
| `DWAPRICES_TOKEN` | `bfwh2025-03-17` | Token للتسجيل |
| `WORKER_URL` | `https://mediswitch-api.YOUR-USERNAME.workers.dev` | URL الـ Worker (بعد النشر) |
| `WORKER_API_KEY` | `your-secure-api-key` | API Key للـ Worker (بعد الإعداد) |

### ✅ الخطوة 3: اختبار GitHub Action يدوياً

```
1. اذهب لـ GitHub → Actions
2. اختر "Daily Drug Price Update"
3. اضغط "Run workflow"
4. انتظر الإكمال (حوالي 15 دقيقة)
```

**ملاحظة:** سيفشل أول مرة لأن Worker لم يُنشر بعد - هذا طبيعي!

---

## 📋 الجزء الثاني: نشر Cloudflare Worker + D1 (من المتصفح)

> 💡 **لا حاجة لتثبيت Node.js أو Wrangler** - كل شيء من المتصفح!

### ✅ الخطوة 1: إنشاء حساب Cloudflare

1. اذهب لـ [dash.cloudflare.com/sign-up](https://dash.cloudflare.com/sign-up)
2. سجل حساب مجاني
3. فعّل الحساب عبر الإيميل

### ✅ الخطوة 2: إنشاء Worker

1. في Dashboard اختر **Workers & Pages**
2. اضغط **Create Application**
3. اختر **Create Worker**
4. اسم Worker: `mediswitch-api`
5. اضغط **Deploy**

### ✅ الخطوة 3: نسخ كود Worker

1. في صفحة Worker اضغط **Quick Edit**
2. احذف الكود الموجود بالكامل
3. افتح ملف `cloudflare-worker/src/index.js` من المشروع
4. انسخ **كل المحتوى** والصقه في المحرر
5. اضغط **Save and Deploy**

**ستحصل على URL:**
```
https://mediswitch-api.YOUR-SUBDOMAIN.workers.dev
```
**احفظ هذا الرابط!** ← ستحتاجه لاحقاً

### ✅ الخطوة 4: إنشاء D1 Database

1. Dashboard → **Workers & Pages** → **D1**
2. اضغط **Create Database**
3. اسم Database: `mediswitch-db`
4. اضغط **Create**

### ✅ الخطوة 5: تطبيق Schema

في صفحة D1 Database:

1. اختر تبويب **Console**
2. افتح ملف `cloudflare-worker/schema.sql`
3. انسخ **كل المحتوى** والصقه في Console
4. اضغط **Execute**

**النتيجة المتوقعة:**
```
✅ Table 'drugs' created successfully
Rows affected: 0
```

### ✅ الخطوة 6: ربط Database بـ Worker

1. ارجع لصفحة Worker
2. **Settings** → **Variables**
3. تحت **D1 Database Bindings**:
   - Variable name: `DB`
   - D1 database: اختر `mediswitch-db`
4. اضغط **Save**

### ✅ الخطوة 7: إضافة API Key

في نفس صفحة Settings → Variables:

1. تحت **Environment Variables** → اضغط **Add variable**
2. املأ:
   - Variable name: `API_KEY`
   - Value: `mediswitch_2025_secure_xyz123` (أي key قوي)
   - ✅ اختر **Encrypt** (مهم!)
3. اضغط **Save**

**احفظ الـ API Key!** ← ستحتاجه في GitHub

### ✅ الخطوة 8: اختبار Worker

```bash
# اختبار Stats API
curl "https://mediswitch-api.YOUR-SUBDOMAIN.workers.dev/api/stats"
```

**النتيجة المتوقعة:**
```json
{
  "total_drugs": 0,
  "total_companies": 0,
  "recent_updates_7d": 0
}
```

✅ إذا ظهرت هذه النتيجة → Worker يعمل بنجاح!

---

## 📋 الجزء الثالث: رفع البيانات الأولية

### ✅ الخطوة 1: تحويل CSV إلى JSON

```bash
cd /home/adminlotfy/project
python3 csv_to_json.py meds_enriched.csv drugs.json
```

### ✅ الخطوة 2: رفع للـ Worker

```bash
curl -X POST "https://YOUR-WORKER-URL/api/update" \
  -H "Authorization: Bearer YOUR-API-KEY" \
  -H "Content-Type: application/json" \
  -d @drugs.json \
  -o response.json

# عرض النتيجة
cat response.json
```

**ستستغرق 2-3 دقائق** لرفع 25,500 دواء

**النتيجة المتوقعة:**
```json
{
  "success": true,
  "updated": 25500,
  "message": "Successfully updated 25500 drugs"
}
```

### ✅ الخطوة 3: التحقق

```bash
curl "https://YOUR-WORKER-URL/api/stats"
```

**يجب أن ترى:**
```json
{
  "total_drugs": 25500,
  "total_companies": 4649,
  "recent_updates_7d": 25500
}
```

✅ **تم!** البيانات الآن على الـ Edge!

---

## 📋 الجزء الرابع: ربط GitHub Actions مع Worker

### ✅ الخطوة 1: تحديث GitHub Secrets

ارجع لـ GitHub Secrets وحدّث:

| Key | Value |
|-----|-------|
| `WORKER_URL` | `https://mediswitch-api.YOUR-USERNAME.workers.dev` |
| `WORKER_API_KEY` | `mediswitch_2025_secure_key_xyz123` |

### ✅ الخطوة 2: تشغيل GitHub Action مرة أخرى

```
GitHub → Actions → Daily Drug Price Update → Run workflow
```

**الآن يجب أن ينجح!** ✅

### ✅ الخطوة 3: التحقق من رفع البيانات

```bash
curl "https://mediswitch-api.YOUR-USERNAME.workers.dev/api/stats"
```

**يجب أن ترى:**
```json
{
  "total_drugs": 25500,
  "total_companies": 4649,
  "recent_updates_7d": 25500
}
```

---

## 📋 الجزء الرابع: تحديث قاعدة بيانات التطبيق

### ✅ الخطوة 1: التحقق من البيانات المُجلوبة

```bash
# تحقق من عدد الأسطر
wc -l meds_enriched.csv

# عرض أول 5 أسطر
head -5 meds_enriched.csv
```

### ✅ الخطوة 2: تحديث قاعدة البيانات الأساسية للتطبيق

**ملف قاعدة البيانات:** `assets/meds.csv`

```bash
# نسخ البيانات المحدثة لملف التطبيق
cp meds_enriched.csv assets/meds.csv

# التحقق
ls -lh assets/meds.csv
wc -l assets/meds.csv  # يجب أن يكون 25501 سطر (25500 + header)
```

**النتيجة:**
✅ ملف `assets/meds.csv` الآن محدث بـ **25,500 دواء كامل**

---

## 📋 الجزء الخامس: تحديث Flutter App

### ✅ الخطوة 1: تحديث BASE_URL

افتح `lib/services/sync_service.dart`:

```dart
static const String BASE_URL = 'https://mediswitch-api.YOUR-USERNAME.workers.dev';
```

ضع Worker URL الحقيقي!

### ✅ الخطوة 2: اختبار المزامنة

```dart
// في main.dart أو أي screen
final syncService = SyncService();
final result = await syncService.sync();
print(result); // يجب أن يعرض عدد الأدوية المزامنة
```

---

## 📋 الجزء السادس: دفع الكود لجميع المستودعات

### ✅ الخطوة 1: التحقق من المستودعات المرتبطة

```bash
git remote -v
```

### ✅ الخطوة 2: إضافة جميع الملفات

```bash
# إضافة جميع التغييرات
git add .

# عرض الملفات المتغيرة
git status
```

### ✅ الخطوة 3: Commit

```bash
git commit -m "Complete Cloudflare Workers integration with auto-sync

- Added Cloudflare Worker API with D1 Database
- Implemented GitHub Actions daily scraper
- Added Flutter SyncService for automatic sync
- Updated localization files (fixed priceLabel)
- Added comprehensive deployment guides
- Enriched 25,500 drugs with full data (20 columns)

Ready for production deployment!"
```

### ✅ الخطوة 4: دفع لجميع المستودعات

```bash
# إذا كان عندك remote واحد
git push origin main

# إذا كان عندك عدة remotes
git remote | xargs -I {} git push {} main

# أو يدوياً لكل واحد
git push origin main
git push backup main
git push production main
```

**لإضافة remote جديد:**
```bash
git remote add backup https://github.com/YOUR-USERNAME/MediSwitch-Backup.git
git push backup main
```

---

## 🧪 الجزء السابع: الاختبار النهائي

### ✅ 1. اختبار Cloudflare Worker

```bash
# Stats
curl "https://YOUR-WORKER-URL/api/stats"

# Sync (آخر 7 أيام)
curl "https://YOUR-WORKER-URL/api/sync?since=2025-11-25"

# عدد الأدوية
curl "https://YOUR-WORKER-URL/api/drugs?limit=1" | jq '.pagination.total'
```

### ✅ 2. اختبار GitHub Action

- ✅ يعمل يومياً الساعة 2 صباحاً UTC
- ✅ يجلب البيانات الجديدة
- ✅ يرفعها للـ Worker
- ✅ يحدث الإحصائيات

### ✅ 3. اختبار Flutter App

- ✅ المزامنة تعمل عند فتح التطبيق
- ✅ Offline mode يعمل
- ✅ البيانات محدثة

---

## 📊 ملخص النظام النهائي

```mermaid
graph TB
    subgraph "Daily Updates (Automated)"
        A1[GitHub Action<br/>2 AM UTC Daily] --> A2[Scraper.py]
        A2 --> A3[Enrich Data]
        A3 --> A4[Convert to JSON]
        A4 --> A5[POST to Worker]
    end
    
    subgraph "Cloudflare (Free 100%)"
        B1[Worker API] --> B2[D1 Database<br/>25,500 Drugs]
    end
    
    subgraph "Flutter App"
        C1[SyncService] --> C2{Internet?}
        C2 -->|Yes| C3[GET /api/sync]
        C2 -->|No| C4[Local SQLite]
        C3 --> C5[Update Local DB]
        C5 --> C6[Display Data]
        C4 --> C6
    end
    
    A5 --> B1
    C3 --> B1
```

---

## ✅ Checklist النهائي

### إعداد أولي
- [ ] تثبيت Wrangler CLI
- [ ] تسجيل دخول Cloudflare
- [ ] إنشاء D1 Database
- [ ] تطبيق Schema
- [ ] إعداد API Key

### النشر
- [ ] نشر Worker
- [ ] اختبار Worker
- [ ] إضافة GitHub Secrets
- [ ] تشغيل GitHub Action
- [ ] التحقق من رفع البيانات

### التطبيق
- [ ] تحديث BASE_URL في Flutter
- [ ] تحديث قاعدة البيانات المحلية
- [ ] اختبار المزامنة
- [ ] Build للإنتاج

### Git
- [ ] Commit جميع التغييرات
- [ ] دفع لجميع المستودعات
- [ ] التأكد من Sync النجاح

---

## 🆘 استكشاف الأخطاء

### مشكلة: "Database not found"
```bash
wrangler d1 list  # تحقق من الـ databases
```

### مشكلة: "Unauthorized" في Worker
```bash
wrangler secret list  # تحقق من API_KEY
```

### مشكلة: GitHub Action يفشل
- تحقق من GitHub Secrets
- تحقق من logs في Actions → Build

### مشكلة: Flutter لا يزامن
- تحقق من BASE_URL
- تحقق من Internet connection
- افحص console logs

---

## 📞 روابط مفيدة

- **Cloudflare Dashboard:** https://dash.cloudflare.com
- **Worker Logs:** Dashboard → Workers → mediswitch-api → Logs
- **D1 Console:** Dashboard → D1 → mediswitch-db
- **GitHub Actions:** Repository → Actions

---

## 💰 التكلفة النهائية

| الخدمة | التكلفة |
|--------|---------|
| Cloudflare Workers | **مجاني** |
| D1 Database | **مجاني** |
| GitHub Actions | **مجاني** |
| **المجموع** | **0 ج.م / شهر** 🎉 |

---

**تم! 🎊**

نظامك الآن:
- ✅ يحدث البيانات تلقائياً يومياً
- ✅ يعمل مجاناً 100%
- ✅ سريع جداً (Edge Computing)
- ✅ مزامنة ذكية في التطبيق
- ✅ جاهز للإنتاج

**أي سؤال؟ اسأل! 😊**
