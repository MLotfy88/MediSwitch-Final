# دليل نشر الواجهة الخلفية (Backend) لتطبيق MediSwitch (باستخدام Docker)

هذا الدليل يشرح بالتفصيل خطوات نشر الواجهة الخلفية لتطبيق MediSwitch المبنية باستخدام Django على خادم VPS (مثل Hetzner) باستخدام Docker و Docker Compose. يفترض الدليل أن لديك خادم VPS يعمل بنظام Linux (مثل Ubuntu) وأن لديك وصول SSH إليه.

**الهدف:** نشر التطبيق في مسار منفصل (`/home/adminlotfy/mediswitch_deployment/`) لتجنب التداخل مع مجلد الشيفرة المصدرية (`/home/adminlotfy/project/`).

---

## 1. المتطلبات الأساسية (على خادم VPS)

قبل البدء، تأكد من تثبيت البرامج التالية على خادم VPS الخاص بك:

*   **Docker:** محرك تشغيل الحاويات.
*   **Docker Compose:** أداة لإدارة تطبيقات Docker متعددة الحاويات.
*   **Nginx:** خادم ويب يعمل كـ Reverse Proxy (وكيل عكسي).
*   **Git:** (اختياري، لكن مفيد لسحب التحديثات).

**أوامر التثبيت (مثال على Ubuntu):**

```bash
# تحديث قائمة الحزم
sudo apt update

# تثبيت Docker
sudo apt install -y docker.io
sudo systemctl start docker
sudo systemctl enable docker

# تثبيت Docker Compose (تحقق من أحدث إصدار على GitHub)
# ملاحظة: استبدل 1.29.2 بأحدث إصدار مستقر إذا لزم الأمر
LATEST_COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
sudo curl -L "https://github.com/docker/compose/releases/download/${LATEST_COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
# أضف المستخدم الحالي إلى مجموعة Docker لتجنب استخدام sudo مع docker
sudo usermod -aG docker $USER
# تحتاج إلى تسجيل الخروج والدخول مرة أخرى لتطبيق تغيير المجموعة أو تشغيل newgrp docker

# تثبيت Nginx
sudo apt install -y nginx

# تثبيت Git (اختياري)
sudo apt install -y git
```

---

## 2. إعداد هيكل مجلدات النشر

سنقوم بإنشاء مجلد منفصل لإدارة ملفات النشر والبيانات الدائمة.

```bash
# الانتقال إلى المجلد الرئيسي للمستخدم
cd /home/adminlotfy/

# إنشاء مجلد النشر الرئيسي
mkdir mediswitch_deployment
cd mediswitch_deployment

# إنشاء مجلدات فرعية للبيانات الدائمة وإعدادات Nginx
mkdir postgres_data nginx_config media_files static_files
```

*   `postgres_data`: لتخزين بيانات قاعدة بيانات PostgreSQL بشكل دائم.
*   `nginx_config`: لوضع ملف إعدادات Nginx الخاص بالتطبيق.
*   `media_files`: لتخزين الملفات التي يتم رفعها من قبل المستخدم (مثل ملفات CSV/XLSX).
*   `static_files`: لتخزين الملفات الثابتة التي يجمعها Django (CSS, JS, etc.).

---

## 3. إعداد قاعدة البيانات (PostgreSQL)

نوصي باستخدام PostgreSQL كقاعدة بيانات للـ Backend. سنقوم بإدارتها باستخدام Docker Compose. لا تحتاج لتثبيتها مباشرة على الـ VPS.

---

## 4. إعداد متغيرات البيئة (Environment Variables)

متغيرات البيئة ضرورية لتكوين التطبيق بشكل آمن في بيئة الإنتاج. سنقوم بإنشاء ملف `.env` داخل مجلد النشر (`/home/adminlotfy/mediswitch_deployment/`).

```bash
# داخل مجلد /home/adminlotfy/mediswitch_deployment/
nano .env
```

أضف المحتوى التالي إلى الملف، **مع استبدال القيم بين علامات `<...>` بقيم حقيقية وآمنة:**

```dotenv
# ملف متغيرات البيئة لـ MediSwitch Backend

# === Django Settings ===
SECRET_KEY='<أنشئ مفتاح سري طويل وعشوائي جداً هنا>'
DEBUG=False
ALLOWED_HOSTS='<عنوان IP الخاص بالخادم>,<اسم النطاق الخاص بك إن وجد, مثال: api.yourdomain.com>'

# === Database Settings ===
# استخدم اسم المستخدم وكلمة المرور وقاعدة البيانات التي ستحددها في docker-compose.yml
DATABASE_URL='postgres://mediswitch_user:<كلمة مرور قوية لقاعدة البيانات>@db:5432/mediswitch_db'

# === Email Settings (Optional - إذا كنت تحتاج لإرسال إيميلات) ===
# EMAIL_BACKEND='django.core.mail.backends.smtp.EmailBackend'
# EMAIL_HOST='smtp.example.com'
# EMAIL_PORT=587
# EMAIL_USE_TLS=True
# EMAIL_HOST_USER='your-email@example.com'
# EMAIL_HOST_PASSWORD='your-email-password'

# === CORS Settings (إذا كان الـ Frontend على نطاق مختلف) ===
# CORS_ALLOWED_ORIGINS='http://localhost:3000,https://yourfrontenddomain.com'

# === Other Settings ===
DJANGO_SETTINGS_MODULE='mediswitch_api.settings'
```

**ملاحظات هامة:**

*   **`SECRET_KEY`**: يجب أن يكون سرياً وفريداً. يمكنك استخدام مولدات المفاتيح السرية عبر الإنترنت أو الأمر `openssl rand -base64 32`.
*   **`ALLOWED_HOSTS`**: حدد عناوين IP أو أسماء النطاقات المسموح لها بالوصول للـ Backend.
*   **`DATABASE_URL`**:
    *   `mediswitch_user`: اسم مستخدم قاعدة البيانات.
    *   `<كلمة مرور قوية لقاعدة البيانات>`: كلمة مرور آمنة.
    *   `db`: اسم خدمة قاعدة البيانات كما سيتم تعريفه في `docker-compose.yml`.
    *   `5432`: المنفذ الافتراضي لـ PostgreSQL.
    *   `mediswitch_db`: اسم قاعدة البيانات.
*   **لا تقم أبداً** بمشاركة ملف `.env` أو وضعه في نظام إدارة الإصدارات (Git). قم بإضافته إلى ملف `.gitignore` في مشروعك إذا لم يكن موجوداً بالفعل.

---

## 5. إعداد Docker Compose

أنشئ ملف `docker-compose.yml` في مجلد النشر (`/home/adminlotfy/mediswitch_deployment/`).

```bash
# داخل مجلد /home/adminlotfy/mediswitch_deployment/
nano docker-compose.yml
```

أضف المحتوى التالي:

```yaml
version: '3.8'

services:
  db:
    image: postgres:13-alpine # استخدام إصدار محدد وموثوق
    volumes:
      - postgres_data:/var/lib/postgresql/data # ربط المجلد المحلي لتخزين بيانات DB
    environment:
      POSTGRES_DB: mediswitch_db # اسم قاعدة البيانات (يجب أن يطابق .env)
      POSTGRES_USER: mediswitch_user # اسم المستخدم (يجب أن يطابق .env)
      POSTGRES_PASSWORD: '<نفس كلمة مرور قاعدة البيانات القوية في ملف .env>' # كلمة المرور (يجب أن تطابق .env)
    restart: unless-stopped # إعادة التشغيل تلقائياً إلا إذا تم إيقافه يدوياً
    healthcheck: # فحص صحة قاعدة البيانات قبل بدء الـ backend
      test: ["CMD-SHELL", "pg_isready -U mediswitch_user -d mediswitch_db"]
      interval: 10s
      timeout: 5s
      retries: 5

  backend:
    build:
      context: /home/adminlotfy/project/backend # المسار إلى مجلد backend في الشيفرة المصدرية
      dockerfile: Dockerfile
    command: gunicorn mediswitch_api.wsgi:application --bind 0.0.0.0:8000 # تشغيل Gunicorn
    volumes:
      - static_files:/app/static # ربط مجلد الملفات الثابتة
      - media_files:/app/media   # ربط مجلد ملفات الميديا (الملفات المرفوعة)
    expose:
      - 8000 # فتح المنفذ داخل شبكة Docker
    env_file:
      - ./.env # تحميل متغيرات البيئة من ملف .env
    depends_on: # تأكد من تشغيل قاعدة البيانات وأنها صحية أولاً
      db:
        condition: service_healthy
    restart: unless-stopped

  nginx:
    image: nginx:stable-alpine
    ports:
      - "80:80"   # ربط منفذ 80 للمضيف بمنفذ 80 للحاوية (HTTP)
      - "443:443" # ربط منفذ 443 للمضيف بمنفذ 443 للحاوية (HTTPS)
    volumes:
      - ./nginx_config:/etc/nginx/conf.d # ربط مجلد إعدادات Nginx
      - static_files:/app/static:ro # مشاركة مجلد الملفات الثابتة للقراءة فقط
      - media_files:/app/media:ro   # مشاركة مجلد الميديا للقراءة فقط
      # - ./certbot/conf:/etc/letsencrypt # (اختياري: لشهادات SSL من Certbot)
      # - ./certbot/www:/var/www/certbot # (اختياري: لشهادات SSL من Certbot)
    depends_on:
      - backend
    restart: unless-stopped

volumes: # تعريف المجلدات الدائمة
  postgres_data:
  static_files:
  media_files:

```

**شرح:**

*   **`services`**: يعرف الحاويات التي سيتم تشغيلها (db, backend, nginx).
*   **`db`**: خدمة قاعدة بيانات PostgreSQL.
    *   `image`: اسم وصيغة صورة Docker المستخدمة.
    *   `volumes`: يربط المجلد المحلي `postgres_data` داخل الحاوية للحفاظ على البيانات.
    *   `environment`: يضبط اسم قاعدة البيانات والمستخدم وكلمة المرور (يجب أن تطابق ملف `.env`).
    *   `healthcheck`: يتأكد من أن قاعدة البيانات جاهزة لاستقبال الاتصالات قبل بدء خدمة `backend`.
*   **`backend`**: خدمة تطبيق Django.
    *   `build`: يحدد مكان بناء صورة Docker (مجلد `backend` في مشروعك).
    *   `command`: الأمر الذي يتم تشغيله عند بدء الحاوية (Gunicorn).
    *   `volumes`: يربط المجلدات المحلية `static_files` و `media_files` داخل الحاوية.
    *   `expose`: يفتح المنفذ 8000 داخل شبكة Docker للتواصل مع Nginx.
    *   `env_file`: يقرأ متغيرات البيئة من ملف `.env`.
    *   `depends_on`: يضمن تشغيل خدمة `db` وأنها في حالة صحية (`service_healthy`) قبل بدء خدمة `backend`.
*   **`nginx`**: خدمة Reverse Proxy.
    *   `ports`: يربط منافذ الخادم (80, 443) بمنافذ الحاوية.
    *   `volumes`: يربط مجلد الإعدادات المحلي `nginx_config` وملفات static/media للقراءة فقط (`:ro`) بواسطة Nginx. (إضافة مجلدات Certbot إذا كنت ستستخدم Let's Encrypt مع Docker).
*   **`volumes`**: يعرف المجلدات المسماة لضمان بقاء البيانات عند إعادة تشغيل الحاويات.

---

## 6. إعداد Nginx (Reverse Proxy)

أنشئ ملف إعدادات Nginx داخل المجلد الذي أنشأناه (`/home/adminlotfy/mediswitch_deployment/nginx_config/`). اسم الملف يجب أن ينتهي بـ `.conf`، مثلاً `mediswitch.conf`.

```bash
# داخل مجلد /home/adminlotfy/mediswitch_deployment/
nano nginx_config/mediswitch.conf
```

أضف المحتوى التالي (هذا مثال أساسي لـ HTTP، ستحتاج لتعديله لـ HTTPS):

```nginx
upstream mediswitch_backend {
    server backend:8000; # اسم خدمة backend ومنفذها كما في docker-compose.yml
}

server {
    listen 80;
    # listen 443 ssl http2; # قم بتفعيل هذا لـ HTTPS
    server_name <عنوان IP الخاص بالخادم أو اسم النطاق>; # استبدل هذا

    # ssl_certificate /etc/letsencrypt/live/<your_domain>/fullchain.pem; # (اختياري: مسار شهادة SSL)
    # ssl_certificate_key /etc/letsencrypt/live/<your_domain>/privkey.pem; # (اختياري: مسار مفتاح SSL)
    # include /etc/letsencrypt/options-ssl-nginx.conf; # (اختياري: إعدادات SSL الموصى بها)
    # ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem; # (اختياري: لـ Diffie-Hellman)

    # زيادة حجم رفع الملفات (مهم لرفع ملفات CSV/XLSX الكبيرة)
    client_max_body_size 50M; # مثال: 50 ميجابايت، عدل حسب الحاجة

    # تقديم الملفات الثابتة مباشرة بواسطة Nginx
    location /static/ {
        alias /app/static/; # المسار داخل حاوية Nginx (مطابق لـ volumes في docker-compose)
        expires 7d; # تحديد مدة التخزين المؤقت للملفات الثابتة
        add_header Pragma public;
        add_header Cache-Control "public, must-revalidate, proxy-revalidate";
    }

    # تقديم ملفات الميديا مباشرة بواسطة Nginx
    location /media/ {
        alias /app/media/; # المسار داخل حاوية Nginx (مطابق لـ volumes في docker-compose)
        expires 7d;
        add_header Pragma public;
        add_header Cache-Control "public, must-revalidate, proxy-revalidate";
    }

    # تمرير باقي الطلبات إلى Django
    location / {
        proxy_pass http://mediswitch_backend; # تمرير الطلبات إلى خدمة backend
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme; # مهم لـ Django لمعرفة HTTPS
        proxy_set_header Host $host;
        proxy_redirect off;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
    }

    # (اختياري: إعدادات Certbot لتجديد شهادات SSL)
    # location ~ /.well-known/acme-challenge/ {
    #     root /var/www/certbot;
    #     allow all;
    # }
}
```

**شرح:**

*   `upstream`: يعرف مجموعة الخوادم التي سيتم تمرير الطلبات إليها (حاوية backend).
*   `server`: كتلة الإعدادات الرئيسية للخادم.
    *   `listen`: المنافذ التي يستمع إليها Nginx (80 لـ HTTP، 443 لـ HTTPS).
    *   `server_name`: عنوان IP أو اسم النطاق الخاص بك.
    *   `ssl_*`: إعدادات HTTPS (تحتاج إلى تفعيلها وإعداد شهادات SSL باستخدام أداة مثل Certbot/Let's Encrypt).
    *   `client_max_body_size`: يحدد أقصى حجم للملفات المرفوعة.
    *   `location /static/` و `location /media/`: يخبر Nginx بتقديم هذه الملفات مباشرة من المجلدات المشتركة (أكثر كفاءة من Django). تم إضافة headers للتحكم في التخزين المؤقت.
    *   `location /`: يمرر جميع الطلبات الأخرى إلى حاوية Django (backend).
    *   `proxy_*`: إعدادات ضرورية لتمرير الطلبات بشكل صحيح، بما في ذلك دعم WebSockets إذا لزم الأمر مستقبلاً.

**لإعداد HTTPS (موصى به بشدة):**

1.  تأكد من أن اسم النطاق الخاص بك يوجه إلى عنوان IP الخاص بالخادم.
2.  استخدم أداة مثل **Certbot** للحصول على شهادة SSL مجانية من Let's Encrypt وتكوين Nginx تلقائياً. (ابحث عن "certbot nginx ubuntu" للحصول على إرشادات مفصلة). ستحتاج غالباً لتعديل `docker-compose.yml` لمشاركة مجلدات Certbot مع حاوية Nginx.

---

## 7. بناء وتشغيل التطبيق

الآن بعد إعداد كل شيء، يمكننا بناء صورة Docker (إذا لم تكن موجودة) وتشغيل الحاويات.

```bash
# داخل مجلد /home/adminlotfy/mediswitch_deployment/

# بناء أو إعادة بناء صورة backend (إذا قمت بتغيير Dockerfile أو الكود)
# قد تحتاج لسحب أحدث التغييرات من Git أولاً إذا كنت تستخدمه
# cd /home/adminlotfy/project/
# git pull origin main # أو اسم الفرع الخاص بك
# cd /home/adminlotfy/mediswitch_deployment/
docker-compose build backend

# تشغيل جميع الخدمات في الخلفية (-d)
docker-compose up -d
```

---

## 8. الإعداد الأولي للتطبيق (بعد التشغيل)

بعد تشغيل الحاويات لأول مرة، نحتاج لتنفيذ بعض الأوامر داخل حاوية `backend`:

```bash
# داخل مجلد /home/adminlotfy/mediswitch_deployment/

# 1. تطبيق Migrations (إنشاء جداول قاعدة البيانات)
docker-compose exec backend python3 manage.py migrate

# 2. جمع الملفات الثابتة (ليتمكن Nginx من خدمتها)
docker-compose exec backend python3 manage.py collectstatic --noinput

# 3. إنشاء مستخدم Admin (إذا لم تكن قد أنشأته بالفعل)
# الأمر التالي ينشئ المستخدم admin@example.com بكلمة مرور admin123 إذا لم يكن موجوداً
docker-compose exec backend python3 manage.py shell -c "from django.contrib.auth import get_user_model; User = get_user_model(); User.objects.filter(username='admin').exists() or User.objects.create_superuser('admin', 'admin@example.com', 'admin123')"

# يمكنك أيضاً إنشاؤه بشكل تفاعلي:
# docker-compose exec backend python3 manage.py createsuperuser
```

**الآن يجب أن يكون الـ Backend جاهزاً ويمكن الوصول إليه عبر عنوان IP أو اسم النطاق الخاص بالخادم.** يمكنك الدخول إلى لوحة تحكم Django Admin عبر `/admin/`.

---

## 9. نقل الـ Backend إلى خادم VPS آخر

إذا احتجت لنقل التطبيق إلى خادم VPS جديد، اتبع الخطوات التالية لضمان عدم فقدان البيانات:

**على الخادم القديم:**

1.  **إيقاف التطبيق:**
    ```bash
    # داخل مجلد /home/adminlotfy/mediswitch_deployment/
    docker-compose down
    ```
2.  **أخذ نسخة احتياطية من قاعدة البيانات:**
    ```bash
    # داخل مجلد /home/adminlotfy/mediswitch_deployment/
    # اسم ملف النسخة الاحتياطية (مثال: backup_YYYYMMDD.sql)
    BACKUP_FILE="db_backup_$(date +%Y%m%d).sql"
    # تنفيذ أمر pg_dump داخل حاوية db (تأكد من أن الحاوية تعمل إذا أوقفتها بالخطأ)
    # docker-compose up -d db # إذا كانت متوقفة
    docker-compose exec -T db pg_dump -U mediswitch_user -d mediswitch_db > $BACKUP_FILE
    echo "Database backup created: $BACKUP_FILE"
    ```
    *   `-T`: يمنع تخصيص TTY، ضروري عند توجيه الإخراج.
    *   `-U mediswitch_user`: اسم مستخدم قاعدة البيانات.
    *   `-d mediswitch_db`: اسم قاعدة البيانات.
3.  **أخذ نسخة احتياطية من ملفات الميديا:**
    ```bash
    # داخل مجلد /home/adminlotfy/mediswitch_deployment/
    tar -czvf media_files_backup.tar.gz media_files
    echo "Media files backup created: media_files_backup.tar.gz"
    ```
4.  **نسخ الملفات الهامة:** انسخ الملفات التالية من الخادم القديم إلى جهازك المحلي أو مباشرة إلى الخادم الجديد باستخدام `scp` أو `rsync`:
    *   ملف النسخة الاحتياطية لقاعدة البيانات (`db_backup_....sql`).
    *   ملف النسخة الاحتياطية للميديا (`media_files_backup.tar.gz`).
    *   ملف `docker-compose.yml`.
    *   ملف `.env` (هام جداً!).
    *   مجلد `nginx_config` بالكامل.
    *   (اختياري) مجلد `postgres_data` بالكامل إذا كنت تفضل نسخ الملفات بدلاً من dump/restore.
    *   (اختياري) مجلد `static_files` إذا أردت تجنب خطوة `collectstatic` على الخادم الجديد.

**على الخادم الجديد:**

1.  **تثبيت المتطلبات:** تأكد من تثبيت Docker, Docker Compose, Nginx على الخادم الجديد (انظر الخطوة 1).
2.  **إنشاء مجلد النشر:**
    ```bash
    mkdir -p /home/adminlotfy/mediswitch_deployment/nginx_config
    cd /home/adminlotfy/mediswitch_deployment
    ```
3.  **نقل الملفات المنسوخة:** انقل الملفات التي نسختها من الخادم القديم إلى مجلد `/home/adminlotfy/mediswitch_deployment/` على الخادم الجديد.
4.  **استعادة ملفات الميديا:**
    ```bash
    # داخل مجلد /home/adminlotfy/mediswitch_deployment/
    tar -xzvf media_files_backup.tar.gz
    # تأكد من أن المالك والمجموعة صحيحان إذا لزم الأمر
    # sudo chown -R <user>:<group> media_files
    ```
5.  **(الطريقة الموصى بها) استعادة قاعدة البيانات:**
    *   **تشغيل حاوية قاعدة البيانات فقط:**
        ```bash
        # داخل مجلد /home/adminlotfy/mediswitch_deployment/
        docker-compose up -d db
        # انتظر بضع ثواني حتى تبدأ قاعدة البيانات وتصبح صحية (healthcheck)
        ```
    *   **استعادة النسخة الاحتياطية:**
        ```bash
        # داخل مجلد /home/adminlotfy/mediswitch_deployment/
        # اسم ملف النسخة الاحتياطية الذي نقلته
        BACKUP_FILE="<اسم ملف النسخة الاحتياطية.sql>"
        # تنفيذ أمر psql داخل حاوية db لاستعادة النسخة
        cat $BACKUP_FILE | docker-compose exec -T db psql -U mediswitch_user -d mediswitch_db
        echo "Database restored from $BACKUP_FILE"
        ```
6.  **(طريقة بديلة) استعادة قاعدة البيانات عن طريق نسخ المجلد:**
    *   إذا قمت بنسخ مجلد `postgres_data` من الخادم القديم، انقله إلى `/home/adminlotfy/mediswitch_deployment/` على الخادم الجديد. تأكد من أن الأذونات صحيحة. هذه الطريقة قد تكون أسرع لقواعد البيانات الكبيرة جداً ولكنها أقل مرونة بين إصدارات PostgreSQL المختلفة.
7.  **تشغيل باقي الخدمات:**
    ```bash
    # داخل مجلد /home/adminlotfy/mediswitch_deployment/
    # قد تحتاج لبناء الصورة إذا كان الخادم الجديد بمعمارية مختلفة أو إذا لم تنسخ مجلد الشيفرة المصدرية
    # docker-compose build backend
    docker-compose up -d
    ```
8.  **تحديث DNS:** قم بتحديث سجلات DNS لاسم النطاق الخاص بك ليوجه إلى عنوان IP الخاص بالخادم الجديد.
9.  **اختبار:** تأكد من أن كل شيء يعمل كما هو متوقع. قد تحتاج لتشغيل `collectstatic` مرة أخرى إذا لم تكن قد نسخت مجلد `static_files`.

بهذه الطريقة، يمكنك نقل الـ Backend بالكامل مع الحفاظ على جميع البيانات والإعدادات.