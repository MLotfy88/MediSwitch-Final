# دليل رفع قاعدة البيانات إلى Cloudflare D1

## المشكلة
التطبيق يُنشأ بقاعدة بيانات كاملة، لكن D1 على Cloudflare فارغة. عند المزامنة، البيانات المحلية تُمسح.

## الحل السريع: استخدام GitHub Actions

### الخطوات:

#### 1️⃣ تصدير قاعدة البيانات (تم ✅)
```bash
python3 scripts/export_to_d1.py
```
✅ **نجح!** تم إنشاء `d1_import.sql` (7.4 MB، 25,500 دواء)

#### 2️⃣ رفع الملف للريبو
```bash
git add d1_import.sql .github/workflows/sync-d1-once.yml
git commit -m "Add D1 full sync workflow"
git push
```

#### 3️⃣ إعداد Cloudflare API Token

1. افتح [Cloudflare Dashboard](https://dash.cloudflare.com/)
2. اذهب إلى **My Profile** → **API Tokens**
3. اضغط **Create Token**
4. اختر **Edit Cloudflare Workers** template
5. أو أنشئ custom token بصلاحيات:
   - `Account.D1` - Edit
   - `Account.Workers Scripts` - Edit
6. انسخ الـ Token

#### 4️⃣ إضافة Secret في GitHub

1. افتح الريبو في GitHub
2. اذهب **Settings** → **Secrets and variables** → **Actions**
3. اضغط **New repository secret**
4. الاسم: `CLOUDFLARE_API_TOKEN`
5. القيمة: الصق الـ Token
6. Save

#### 5️⃣ تشغيل Workflow

1. اذهب إلى تبويب **Actions** في الريبو
2. اختر **Sync Full Database to D1 (One-time)**
3. اضغط **Run workflow** → **Run workflow**
4. انتظر 3-5 دقائق
5. تحقق من النتيجة في Slack

---

## طريقة بديلة: استخدام Cloudflare Dashboard

إذا كان ملف `d1_import.sql` صغير (<1 MB)، يمكنك رفعه من Dashboard:

1. افتح [Cloudflare Dashboard](https://dash.cloudflare.com/)
2. اذهب **Workers & Pages** → **D1**
3. افتح قاعدة البيانات `mediswitch-db`
4. اذهب إلى تبويب **Console**
5. الصق محتوى `d1_import.sql` (⚠️ الملف كبير قد لا يعمل)

---

## التحقق من النجاح

بعد الرفع:

```bash
# إذا كان wrangler مثبت محلياً
cd cloudflare-worker
wrangler d1 execute mediswitch-db --command="SELECT COUNT(*) FROM drugs;" --remote
```

يجب أن تظهر: **25,500 سجل** (أو قريب من هذا العدد)

---

## الخطوات التالية

بعد رفع البيانات بنجاح:

✅ D1 الآن تحتوي على البيانات الكاملة  
✅ المزامنة التلقائية لن تمسح البيانات  
✅ التحديثات اليومية من GitHub Actions ستدمج البيانات (لا تستبدلها)

---

## ملاحظات مهمة

⚠️ **هذا Workflow يُشغل مرة واحدة فقط**  
⚠️ **لا تشغله مرة أخرى إلا إذا احتجت إعادة بناء D1 بالكامل**  
⚠️ **التحديثات اليومية تتم عبر `daily-update.yml` تلقائياً**
