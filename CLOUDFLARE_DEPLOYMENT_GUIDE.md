# 🚀 دليل نشر Cloudflare Workers + D1

## ✨ لماذا Cloudflare Workers؟
- ✅ **مجاني 100%** (حتى 100k requests/يوم)
- ✅ **سريع جداً** (Edge computing)
- ✅ **بدون صيانة** (Serverless)
- ✅ **D1 Database** = SQLite على الـ edge

---

## 📋 المتطلبات
- حساب Cloudflare (مجاني)
- Node.js مثبت
- Wrangler CLI

---

## 🎯 خطوات النشر السريعة

### 1. تثبيت Wrangler CLI
```bash
npm install -g wrangler
```

### 2. تسجيل الدخول
```bash
wrangler login
```

### 3. إنشاء D1 Database
```bash
cd cloudflare-worker
wrangler d1 create mediswitch-db
```

**Output:**
```
✅ Successfully created DB 'mediswitch-db'
binding = "DB"
database_name = "mediswitch-db"
database_id = "xxxx-xxxx-xxxx"
```

### 4. تحديث wrangler.toml
نسخ `database_id` من الخطوة السابقة وضعه في `wrangler.toml`:
```toml
[[d1_databases]]
binding = "DB"
database_name = "mediswitch-db"
database_id = "PASTE-YOUR-DATABASE-ID-HERE"
```

### 5. تطبيق Schema
```bash
wrangler d1 execute mediswitch-db --file=schema.sql
```

### 6. النشر
```bash
wrangler deploy
```

**Output:**
```
✨ Successfully published your Worker!
🌍 https://mediswitch-api.YOUR-USERNAME.workers.dev
```

---

## 🔐 إعداد API Key

### 1. إنشاء API Secret
```bash
wrangler secret put API_KEY
```

أدخل secret key قوي (احفظه للاستخدام لاحقاً).

---

## 🧪 اختبار Worker

### 1. اختبار Sync API
```bash
curl "https://mediswitch-api.YOUR-USERNAME.workers.dev/api/sync?since=2025-01-01"
```

### 2. اختبار Bulk Update (محمي)
```bash
curl -X POST "https://mediswitch-api.YOUR-USERNAME.workers.dev/api/update" \
  -H "Authorization: Bearer YOUR-API-KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "drugs": [
      {
        "id": 1,
        "trade_name": "Test Drug",
        "price": 100
      }
    ]
  }'
```

### 3. اختبار Statistics
```bash
curl "https://mediswitch-api.YOUR-USERNAME.workers.dev/api/stats"
```

---

## 📱 تحديث Flutter App

في `lib/services/sync_service.dart`:
```dart
static const String BASE_URL = 'https://mediswitch-api.YOUR-USERNAME.workers.dev';
```

---

## 🔄 إعداد GitHub Actions

### 1. إضافة Secrets
في GitHub → Settings → Secrets → Actions:

**WORKER_URL:**
```
https://mediswitch-api.YOUR-USERNAME.workers.dev
```

**WORKER_API_KEY:**
```
your-api-key-from-step-1
```

### 2. تحديث Workflow
الملف `.github/workflows/daily-update.yml` جاهز ومحدث!

---

## 📊 تحميل البيانات الأولية

### الطريقة 1: من Python Script
```bash
# تحويل CSV إلى JSON
python3 csv_to_json.py meds_enriched.csv drugs.json

# رفع للـ Worker
curl -X POST "https://mediswitch-api.YOUR-USERNAME.workers.dev/api/update" \
  -H "Authorization: Bearer YOUR-API-KEY" \
  -H "Content-Type: application/json" \
  -d @drugs.json
```

### الطريقة 2: من GitHub Action
```
GitHub → Actions → Daily Drug Price Update → Run workflow
```

---

## 🎛️ إدارة D1 Database

### عرض الجداول
```bash
wrangler d1 execute mediswitch-db --command="SELECT name FROM sqlite_master WHERE type='table'"
```

### عدد الأدوية
```bash
wrangler d1 execute mediswitch-db --command="SELECT COUNT(*) FROM drugs"
```

### حذف كل البيانات (احذر!)
```bash
wrangler d1 execute mediswitch-db --command="DELETE FROM drugs"
```

### Backup Database
```bash
wrangler d1 export mediswitch-db --output backup.sql
```

---

## 📈 المراقبة والـ Logs

### عرض Logs
```bash
wrangler tail
```

أو من Dashboard:
```
Cloudflare Dashboard → Workers → mediswitch-api → Logs
```

### Analytics
```
Dashboard → Workers → mediswitch-api → Analytics
```

يعرض:
- عدد الـ requests
- الأخطاء
- أوقات الاستجابة

---

## 🔧 Troubleshooting

### مشكلة: "Database not found"
```bash
# تأكد من database_id صحيح
wrangler d1 list
```

### مشكلة: "Unauthorized"
```bash
# تأكد من API_KEY
wrangler secret list
```

### مشكلة: "CORS error"
✅ الـ Worker يدعم CORS بالفعل (في index.js)

---

## 💰 الحدود المجانية

| المقياس | الحد المجاني |
|---------|--------------|
| Requests | 100,000/day |
| D1 Reads | 5 million/day |
| D1 Writes | 100,000/day |
| D1 Storage | 5 GB |

**للتطبيق:** أكثر من كافٍ! ✅

---

## 🚀 التحديث المستقبلي

### إضافة endpoint جديد
1. عدّل `src/index.js`
2. أضف الـ route
3. `wrangler deploy`

### تحديث Schema
```bash
# أضف migration في schema.sql
wrangler d1 execute mediswitch-db --file=migration.sql
```

---

## 📝 الخطوات التالية

✅ Worker منشور وجاهز  
✅ D1 Database محضّرة  
✅ GitHub Action مُعدّ  
⬜ رفع البيانات الأولية  
⬜ اختبار من Flutter  

---

**🎉 تم! Cloudflare Workers + D1 جاهزة للاستخدام - مجاناً 100%!**
