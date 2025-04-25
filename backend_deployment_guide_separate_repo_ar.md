# دليل نشر وتحديث الواجهة الخلفية (Backend) لـ MediSwitch (مستودع منفصل)

هذا الدليل يشرح خطوات نشر الواجهة الخلفية (Backend) لتطبيق MediSwitch وتحديثها باستخدام Docker و Docker Compose، بافتراض أن كود الـ Backend موجود في **مستودع GitHub منفصل وخاص به**.

https://github.com/MLotfy88/MediSwitch_Backend.git

**الافتراضات:**

*   لديك مستودع GitHub منفصل يحتوي فقط على كود مجلد `backend` الأصلي. سنسمي رابط هذا المستودع `GITHUB_BACKEND_REPO_URL` في الأمثلة.
*   لديك خادم VPS يعمل بنظام Linux (مثل Ubuntu) مع وصول SSH.
*   تم تثبيت Docker و Docker Compose و Nginx و Git على الخادم المضيف (Host OS).

---

## 1. الإعداد الأولي (يُنفذ مرة واحدة على الخادم المضيف)

### أ. استنساخ مستودع الـ Backend

قم باستنساخ مستودع الـ Backend المنفصل إلى مكان مخصص على الخادم المضيف. هذا المجلد سيحتوي على الكود المصدري الذي سيُستخدم لبناء صورة Docker.

```bash
# اختر مساراً مناسباً، مثلاً /home/adminlotfy/mediswitch_backend_source
BACKEND_SOURCE_DIR="/home/adminlotfy/mediswitch_backend_source"
git clone GITHUB_BACKEND_REPO_URL $BACKEND_SOURCE_DIR
```
*(استبدل `GITHUB_BACKEND_REPO_URL` بالرابط الفعلي لمستودع الـ backend الخاص بك)*

### ب. إعداد مجلد النشر

أنشئ مجلداً منفصلاً لإدارة ملفات النشر والبيانات الدائمة.

```bash
# الانتقال إلى المجلد الرئيسي للمستخدم (أو أي مكان مناسب)
cd /home/adminlotfy/

# إنشاء مجلد النشر الرئيسي
DEPLOYMENT_DIR="/home/adminlotfy/mediswitch_deployment"
mkdir -p $DEPLOYMENT_DIR/nginx_config
mkdir -p $DEPLOYMENT_DIR/postgres_data
mkdir -p $DEPLOYMENT_DIR/media_files
mkdir -p $DEPLOYMENT_DIR/static_files

cd $DEPLOYMENT_DIR
```

### ج. إنشاء ملف متغيرات البيئة (`.env`)

أنشئ ملف `.env` داخل مجلد النشر (`$DEPLOYMENT_DIR`).

```bash
# داخل مجلد $DEPLOYMENT_DIR
nano .env
```

أضف المحتوى التالي مع استبدال القيم اللازمة:

```dotenv
# ملف متغيرات البيئة لـ MediSwitch Backend

# === Django Settings ===
SECRET_KEY='<أنشئ مفتاح سري طويل وعشوائي جداً هنا>'
DEBUG=False
ALLOWED_HOSTS='<عنوان IP الخاص بالخادم>,<اسم النطاق الخاص بك إن وجد>'

# === Database Settings ===
# استخدم نفس القيم التي ستحددها في docker-compose.yml
DATABASE_URL='postgres://mediswitch_user:<كلمة مرور قوية لقاعدة البيانات>@db:5432/mediswitch_db'

# === Other Settings ===
DJANGO_SETTINGS_MODULE='mediswitch_api.settings' # تأكد أن هذا هو المسار الصحيح لوحدة الإعدادات
```

### د. إنشاء ملف `docker-compose.yml`

أنشئ ملف `docker-compose.yml` داخل مجلد النشر (`$DEPLOYMENT_DIR`).

```bash
# داخل مجلد $DEPLOYMENT_DIR
nano docker-compose.yml
```

أضف المحتوى التالي، **مع التأكد من تعديل `context` ليشير إلى مجلد الكود المصدري الذي استنسخته في الخطوة (أ)**:

```yaml
version: '3.8'

services:
  db:
    image: postgres:13-alpine
    volumes:
      - postgres_data:/var/lib/postgresql/data
    environment:
      POSTGRES_DB: mediswitch_db
      POSTGRES_USER: mediswitch_user
      POSTGRES_PASSWORD: '<نفس كلمة مرور قاعدة البيانات القوية في ملف .env>'
    restart: unless-stopped
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U mediswitch_user -d mediswitch_db"]
      interval: 10s
      timeout: 5s
      retries: 5

  backend:
    build:
      # !!! هام: تأكد أن هذا المسار صحيح لمكان استنساخ مستودع الـ backend على الخادم المضيف !!!
      context: /home/adminlotfy/mediswitch_backend_source # <--- عدّل هذا المسار إذا لزم الأمر
      dockerfile: Dockerfile # اسم ملف Dockerfile داخل مجلد المصدر
    command: gunicorn mediswitch_api.wsgi:application --bind 0.0.0.0:8000
    volumes:
      - static_files:/app/static # المسار داخل الحاوية يجب أن يطابق STATIC_ROOT في settings.py
      - media_files:/app/media   # المسار داخل الحاوية يجب أن يطابق MEDIA_ROOT في settings.py
    expose:
      - 8000
    env_file:
      - ./.env
    depends_on:
      db:
        condition: service_healthy
    restart: unless-stopped

  nginx:
    image: nginx:stable-alpine
    ports:
      - "80:80"
      - "443:443" # إذا كنت ستستخدم HTTPS
    volumes:
      - ./nginx_config:/etc/nginx/conf.d
      # المسارات هنا يجب أن تطابق المسارات داخل حاوية backend المحددة في volumes أعلاه
      - static_files:/app/static:ro
      - media_files:/app/media:ro
      # - ./certbot/conf:/etc/letsencrypt # (اختياري: لشهادات SSL)
      # - ./certbot/www:/var/www/certbot # (اختياري: لشهادات SSL)
    depends_on:
      - backend
    restart: unless-stopped

volumes: # تعريف المجلدات الدائمة
  postgres_data:
  static_files:
  media_files:

```

### هـ. إنشاء ملف إعدادات Nginx

أنشئ ملف `nginx_config/mediswitch.conf` داخل مجلد النشر (`$DEPLOYMENT_DIR`).

```bash
# داخل مجلد $DEPLOYMENT_DIR
nano nginx_config/mediswitch.conf
```

استخدم محتوى ملف Nginx من الدليل السابق (`backend_deployment_guide_ar.md` القسم 6)، مع التأكد من تعديل `server_name` واستخدام المسارات الصحيحة للملفات الثابتة والميديا (`/app/static/` و `/app/media/` كما هي معرفة في `volumes` داخل `docker-compose.yml`).

---

## 2. عملية النشر الأولية (تُنفذ مرة واحدة على الخادم المضيف)

```bash
# انتقل إلى مجلد النشر
cd /home/adminlotfy/mediswitch_deployment

# 1. بناء صورة Docker للـ backend (باستخدام الكود المستنسخ)
docker-compose build backend

# 2. تشغيل جميع الخدمات في الخلفية
docker-compose up -d

# --- انتظر قليلاً حتى تبدأ الخدمات ---

# 3. تطبيق Migrations (إنشاء جداول قاعدة البيانات)
docker-compose exec backend python3 manage.py migrate

# 4. جمع الملفات الثابتة (ليتمكن Nginx من خدمتها)
docker-compose exec backend python3 manage.py collectstatic --noinput

# 5. إنشاء مستخدم Admin (إذا لم يكن موجوداً)
# يمكنك استخدام الطريقة التفاعلية أو غير التفاعلية من الدليل السابق
docker-compose exec backend python3 manage.py createsuperuser
# أو:
# docker-compose exec backend python3 manage.py shell -c "from django.contrib.auth import get_user_model; User = get_user_model(); User.objects.filter(username='admin').exists() or User.objects.create_superuser('admin', 'admin@example.com', 'admin123')"

```
**الآن يجب أن يكون الـ Backend يعمل ويمكن الوصول إليه.**

---

## 3. عملية تحديث الـ Backend (تُنفذ عند نشر تغييرات جديدة)

عندما تقوم بعمل تعديلات على كود الـ Backend وتدفعها (push) إلى مستودع الـ Backend المنفصل على GitHub، اتبع الخطوات التالية لنشر التحديثات على الخادم المضيف:

```bash
# 1. تحديث الكود المصدري على الخادم المضيف
# انتقل إلى مجلد الكود المصدري للـ backend الذي استنسخته سابقاً
cd /home/adminlotfy/mediswitch_backend_source # <--- تأكد من أن هذا هو المسار الصحيح
git checkout main # أو اسم الفرع الذي تعمل عليه
git pull origin main # سحب آخر التعديلات من GitHub

# 2. العودة إلى مجلد النشر
cd /home/adminlotfy/mediswitch_deployment

# 3. إعادة بناء صورة Docker للـ backend فقط
docker-compose build backend

# 4. إعادة تشغيل خدمة backend فقط (مع الحفاظ على البيانات)
# سيقوم Docker Compose بإيقاف الحاوية القديمة وإنشاء وتشغيل حاوية جديدة بالصورة المحدثة
# مع إعادة ربط نفس المجلدات الدائمة (Volumes) تلقائياً.
docker-compose up -d --no-deps backend
# --no-deps: يمنع إعادة تشغيل الخدمات التي تعتمد عليها (مثل db)
# backend: اسم الخدمة التي نريد تحديثها

# --- انتظر قليلاً حتى تبدأ الخدمة المحدثة ---

# 5. تطبيق أي Migrations جديدة (إذا كانت التغييرات تتضمن تعديلات على الموديل)
docker-compose exec backend python3 manage.py migrate

# 6. إعادة جمع الملفات الثابتة (إذا أضفت أو عدلت ملفات CSS/JS/Images)
docker-compose exec backend python3 manage.py collectstatic --noinput

```

**بهذه الطريقة، يتم تحديث كود التطبيق فقط في الحاوية الجديدة، بينما تظل قاعدة البيانات وملفات الميديا كما هي في المجلدات الدائمة (Volumes)، مما يضمن عدم فقدان أي بيانات.**

---