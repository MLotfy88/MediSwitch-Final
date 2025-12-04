# دليل رفع قاعدة البيانات إلى Cloudflare D1

# لرفع قاعدة البيانات
python3 scripts/upload_d1_global_key.py m.m.lotfy.88@gmail.com eedf653449abdca28e865ddf3511dd4c62ed2

# لمعرفة عدد الاسطر
python3 scripts/check_d1_count.py m.m.lotfy.88@gmail.com eedf653449abdca28e865ddf3511dd4c62ed2

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

yy-vk8KC4yth3Cn2lpva1AgrP2kGMJrQQrGIUM1-
yy-vk8KC4yth3Cn2lpva1AgrP2kGMJrQQrGIUM1-

eedf653449abdca28e865ddf3511dd4c62ed2

curl "https://api.cloudflare.com/client/v4/user/tokens/verify" \ -H "Authorization: Bearer yy-vk8KC4yth3Cn2lpva1AgrP2kGMJrQQrGIUM1-"

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





مافيش ولا تعديل واحد اتنفذ:
## ملحوظة مهمه ## الصفحة الئيسية شئ وصفحة البحث شئ اخر
> الصفحة الرئيسية
- قسم الادوية الاكثر خطورة لا يظهر
- ارتفاع كروت الادوية صغير جدا مما يجعل المحتوى يخرج عن الكروت
- فى قسم الادوية الاكثر تغيرا فى السعر العملة ج.م تظهر فى النسخة العربية والانجليزية. المفروض تظهر فى العربى ج.م وفى الانجليزى L.E
- كروت التخصصات يجب ان تظهر جميعها بحجم واحد والافضل ان يكون هذا الحجم مناسب لعرض اكبر كلمة فى اسماء التخصصات. كما ان الايقونات لازالت مكررة وغير فريدة لكل قسم ولا ترتبط باسم التخصص

> صفحة تفاصيل الدواء
- اسم الدواء ملتصق تماما بال header. كما ان ال header كبير قليلا
- يوجد ايضا نفس المشكلة التى تخص ج.م و L.E
- تبويبة تفاصيل الدواء الكروت التى بها غير محددة ولون اطارها غير واضح. كما انه بينها وبين عنوان التبويبة كبير جدا
- تبويبة السعر لا يوجد بها احصائيات التغير فى السعر كما هى موجودة فى التصميم المرجعى design.md
- تبويبة الجرعات لا يوجد بها ايضا تفاصيل الجرعة القياسية كما هى موجودة فى التصميم المرجعى المذكور سابقا
- عناوين التبويبات تظهر باللغة العربية فى نسخة التطبيق الانجليزية. يجب ان يحترم لغة التطبيق واتجاه اللغة

> صفحة البحث
- ارتفاع الكارت كبير جدا ودة لانك نفذت تعليمات خاطئة
- نفس مشكلة العملة ج.م و L.E
- نفس مشكلة اللغة ايضا فى بيانات السعر وموعد التحديث


ركز ونفذ المطلوب بالظبط
التزم بمعالجة جميع النقاط بالكامل دون اى استثناء