# دليل نشر وتحديث الواجهة الخلفية لـ MediSwitch (خطوة بخطوة)

هذا الدليل يوحد جميع الخطوات اللازمة لنشر الواجهة الخلفية (Backend) وتحديثها، مع توضيح مكان تنفيذ كل خطوة وحل المشاكل الشائعة.

**الافتراضات:**

*   لديك مستودع GitHub منفصل لكود الـ Backend: `https://github.com/MLotfy88/MediSwitch_Backend.git` (سنستخدم رابط SSH).
*   لديك خادم VPS (IP: `37.27.185.59`) يعمل بنظام Ubuntu/Debian.
*   تم تثبيت Docker و Docker Compose و Git على الخادم المضيف (Host OS).
*   تم إعداد مفتاح SSH على الخادم المضيف وإضافته إلى حساب GitHub الخاص بك.
*   لديك اتصال VS Code يعمل داخل حاوية تطوير تحتوي على الكود المصدري في المسار `/home/adminlotfy/project/backend`.
*   لديك طرفية SSH منفصلة متصلة بالخادم المضيف (Host OS).

---

## الجزء الأول: الإعداد الأولي (يُنفذ مرة واحدة)

### 1. [على الخادم المضيف - Host OS Terminal] استنساخ مستودع الـ Backend

```bash
# تأكد من أنك في المجلد الرئيسي أو مكان مناسب
cd ~

# استنساخ باستخدام رابط SSH
git clone git@github.com:MLotfy88/MediSwitch_Backend.git /home/adminlotfy/mediswitch_backend_source
```
*(تم تنفيذ هذه الخطوة بنجاح)*

### 2. [على الخادم المضيف - Host OS Terminal] إنشاء مجلدات النشر

```bash
mkdir -p /home/adminlotfy/mediswitch_deployment/nginx_config
mkdir -p /home/adminlotfy/mediswitch_deployment/postgres_data
mkdir -p /home/adminlotfy/mediswitch_deployment/media_files
mkdir -p /home/adminlotfy/mediswitch_deployment/static_files
```
*(تم تنفيذ هذه الخطوة بنجاح)*

### 3. [على الخادم المضيف - Host OS Terminal] إنشاء ملف `.env`

```bash
# انتقل إلى مجلد النشر
cd /home/adminlotfy/mediswitch_deployment

# افتح محرر nano
nano .env
```

**ألصق المحتوى التالي في `nano`:**

```dotenv
# ملف متغيرات البيئة لـ MediSwitch Backend (Production)

# === Django Settings ===
# تحذير: احتفظ بهذا المفتاح سرياً!
SECRET_KEY='j#z!q@w*e$r%t^y&u*i(o)p_a+s=d-f_g!h@j#k$l%z^x&c*v(b)n_m+'
DEBUG=False
ALLOWED_HOSTS='37.27.185.59'

# === Database Settings ===
# استخدم نفس القيم في docker-compose.yml
DATABASE_URL='postgres://mediswitch_user:MediSwitchdb@159753@db:5432/mediswitch_db'

# === Other Settings ===
DJANGO_SETTINGS_MODULE='mediswitch_api.settings'
```

**احفظ واخرج من `nano`** (`Ctrl+X`, `Y`, `Enter`).
*(تم تنفيذ هذه الخطوة بنجاح)*

### 4. [على الخادم المضيف - Host OS Terminal] إنشاء ملف `docker-compose.yml`

```bash
# تأكد أنك في مجلد النشر
cd /home/adminlotfy/mediswitch_deployment

# افتح محرر nano
nano docker-compose.yml
```

**ألصق المحتوى التالي في `nano`:**

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
      POSTGRES_PASSWORD: 'MediSwitchdb@159753' # كلمة المرور من ملف .env
    restart: unless-stopped
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U mediswitch_user -d mediswitch_db"]
      interval: 10s
      timeout: 5s
      retries: 5

  backend:
    build:
      # المسار إلى مجلد backend في الشيفرة المصدرية المستنسخة على الخادم المضيف
      context: /home/adminlotfy/mediswitch_backend_source
      dockerfile: Dockerfile
    command: gunicorn mediswitch_api.wsgi:application --bind 0.0.0.0:8000
    volumes:
      # المسارات داخل الحاوية يجب أن تطابق STATIC_ROOT و MEDIA_ROOT في settings.py
      - static_files:/app/staticfiles
      - media_files:/app/media
    expose:
      - 8000
    env_file:
      - ./.env # تحميل متغيرات البيئة من ملف .env المحلي
    depends_on:
      db:
        condition: service_healthy
    restart: unless-stopped

  nginx:
    image: nginx:stable-alpine
    ports:
      - "80:80"
      # - "443:443" # لـ HTTPS لاحقاً
    volumes:
      - ./nginx_config:/etc/nginx/conf.d
      - static_files:/app/staticfiles:ro
      - media_files:/app/media:ro
    depends_on:
      - backend
    restart: unless-stopped

volumes: # تعريف المجلدات الدائمة
  postgres_data:
  static_files:
  media_files:
```

**احفظ واخرج من `nano`** (`Ctrl+X`, `Y`, `Enter`).
*(تم تنفيذ هذه الخطوة بنجاح)*

### 5. [على الخادم المضيف - Host OS Terminal] إنشاء ملف إعدادات Nginx

```bash
# تأكد أنك في مجلد النشر
cd /home/adminlotfy/mediswitch_deployment

# افتح محرر nano
nano nginx_config/mediswitch.conf
```

**ألصق المحتوى التالي في `nano`:**

```nginx
# /home/adminlotfy/mediswitch_deployment/nginx_config/mediswitch.conf

# تعريف خدمة الـ backend التي سيتم تمرير الطلبات إليها
upstream mediswitch_backend {
    # اسم خدمة backend ومنفذها كما في docker-compose.yml
    server backend:8000;
}

server {
    listen 80;
    # استبدل هذا بعنوان IP أو اسم النطاق الخاص بخادمك
    server_name 37.27.185.59;

    # زيادة حجم رفع الملفات (مهم لرفع ملفات CSV/XLSX الكبيرة)
    client_max_body_size 50M; # مثال: 50 ميجابايت، عدل حسب الحاجة

    # تقديم الملفات الثابتة مباشرة بواسطة Nginx
    location /static/ {
        # المسار داخل حاوية Nginx (مطابق لـ volumes في docker-compose)
        alias /app/staticfiles/;
        expires 7d; # تحديد مدة التخزين المؤقت للملفات الثابتة
        add_header Pragma public;
        add_header Cache-Control "public, must-revalidate, proxy-revalidate";
    }

    # تقديم ملفات الميديا مباشرة بواسطة Nginx
    location /media/ {
        # المسار داخل حاوية Nginx (مطابق لـ volumes في docker-compose)
        alias /app/media/;
        expires 7d;
        add_header Pragma public;
        add_header Cache-Control "public, must-revalidate, proxy-revalidate";
    }

    # تمرير باقي الطلبات إلى Django backend
    location / {
        proxy_pass http://mediswitch_backend; # تمرير الطلبات إلى خدمة backend
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme; # مهم لـ Django لمعرفة HTTPS إذا استخدمته لاحقاً
        proxy_set_header Host $host;
        proxy_redirect off;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade"; # لدعم WebSockets إذا احتجت إليها
    }
}
```

**احفظ واخرج من `nano`** (`Ctrl+X`, `Y`, `Enter`).
*(تم تنفيذ هذه الخطوة بنجاح)*

---

## الجزء الثاني: تصحيح الكود ونشره (يُنفذ الآن لحل المشاكل)

### 6. [داخل حاوية VS Code] تعديل `requirements.txt` و `settings.py`

*   تأكد أن ملف `/home/adminlotfy/project/backend/requirements.txt` يحتوي على:
    ```
    dj-database-url>=2.0,<3.0
    psycopg2-binary>=2.9,<3.0
    ```
*   تأكد أن ملف `/home/adminlotfy/project/backend/mediswitch_api/settings.py` تم تعديله لـ:
    *   إزالة `load_dotenv`.
    *   إضافة `import dj_database_url`.
    *   استبدال قسم `DATABASES` بالكود الذي يقرأ `DATABASE_URL`.
    *   التأكد من أن `ALLOWED_HOSTS` و `DEBUG` تقرأ من `os.getenv`.
*(تم تنفيذ هذه الخطوات بنجاح)*

### 7. [داخل حاوية VS Code] حفظ التغييرات في Git ودفعها

```bash
# انتقل إلى مجلد الـ backend داخل الحاوية
cd /home/adminlotfy/project/backend

# إضافة الملفات المعدلة (إذا لم تكن قد أضفتها بالفعل)
git add requirements.txt mediswitch_api/settings.py

# عمل Commit (إذا لم تكن قد فعلت)
git commit -m "Fix: Add psycopg2 and configure settings for production env vars"

# دفع التغييرات للمستودع المنفصل
git push origin main
```
*(تم تنفيذ هذه الخطوات بنجاح)*

### 8. [على الخادم المضيف - Host OS Terminal] سحب التحديثات

```bash
# انتقل إلى مجلد الكود المصدري على الخادم المضيف
cd /home/adminlotfy/mediswitch_backend_source

# سحب آخر التعديلات من GitHub
git pull origin main
```
*(تم تنفيذ هذه الخطوة بنجاح)*

### 9. [على الخادم المضيف - Host OS Terminal] إعادة بناء صورة الـ Backend (بدون Cache)

```bash
# انتقل إلى مجلد النشر
cd /home/adminlotfy/mediswitch_deployment

# أعد بناء صورة backend بدون cache لحل مشكلة DisallowedHost
echo "INFO: Rebuilding backend image without cache..."
docker-compose build --no-cache backend
```
*(**يرجى تنفيذ هذا الأمر الآن**)*

### 10. [على الخادم المضيف - Host OS Terminal] إيقاف وتشغيل الخدمات

```bash
# تأكد أنك في مجلد النشر
cd /home/adminlotfy/mediswitch_deployment

# أوقف وأزل الحاويات الحالية (سيحتفظ بالـ volumes)
echo "INFO: Stopping and removing existing containers..."
docker-compose down

# شغل جميع الخدمات بالصورة المحدثة
echo "INFO: Starting all services..."
docker-compose up -d
```
*(نفذ هذين الأمرين بعد نجاح الخطوة 9)*

### 11. [على الخادم المضيف - Host OS Terminal] تطبيق Migrations (احتياطي)

```bash
# تأكد أنك في مجلد النشر
cd /home/adminlotfy/mediswitch_deployment

echo "INFO: Applying database migrations..."
docker-compose exec backend python3 manage.py migrate
```
*(نفذ هذا الأمر بعد نجاح الخطوة 10)*

### 12. [على الخادم المضيف - Host OS Terminal] جمع الملفات الثابتة (احتياطي)

```bash
# تأكد أنك في مجلد النشر
cd /home/adminlotfy/mediswitch_deployment

echo "INFO: Collecting static files..."
docker-compose exec backend python3 manage.py collectstatic --noinput
```
*(نفذ هذا الأمر بعد نجاح الخطوة 11)*

### 13. [على الخادم المضيف - Host OS Terminal] إنشاء مستخدم Admin (إذا لم يتم إنشاؤه سابقاً)

```bash
# تأكد أنك في مجلد النشر
cd /home/adminlotfy/mediswitch_deployment

echo "INFO: Ensuring admin user exists..."
docker-compose exec backend python3 manage.py shell -c "from django.contrib.auth import get_user_model; User = get_user_model(); User.objects.filter(username='admin').exists() or User.objects.create_superuser('admin', 'admin@example.com', 'admin123')"
```


docker-compose exec backend python3 manage.py createsuperuser


*(نفذ هذا الأمر بعد نجاح الخطوة 12)*

### 14. [على جهازك المحلي - متصفح الويب] الاختبار النهائي

*   انتظر بضع ثوانٍ بعد اكتمال الخطوة 13.
*   افتح متصفح الويب وانتقل إلى `http://37.27.185.59/admin/`.
*   حاول تسجيل الدخول باستخدام `admin` و `admin123`.

---

## الجزء الثالث: تحديث الـ Backend لاحقاً (عند وجود تغييرات جديدة في الكود)

1.  **[داخل حاوية VS Code]** قم بإجراء التعديلات اللازمة على الكود.
2.  **[داخل حاوية VS Code]** نفذ أوامر Git لحفظ ودفع التغييرات:
    ```bash
    cd /home/adminlotfy/project/backend
    git add .
    git commit -m "وصف التغييرات الجديدة"
    git push origin main
    ```
3.  **[على الخادم المضيف - Host OS Terminal]** اسحب التحديثات:
    ```bash
    cd /home/adminlotfy/mediswitch_backend_source
    git pull origin main
    ```
4.  **[على الخادم المضيف - Host OS Terminal]** أعد بناء صورة الـ Backend:
    ```bash
    cd /home/adminlotfy/mediswitch_deployment
    docker-compose build backend
    ```
5.  **[على الخادم المضيف - Host OS Terminal]** أوقف وشغل الخدمات:
    ```bash
    # (الطريقة الأضمن)
    docker-compose down
    docker-compose up -d
    # (أو الطريقة الأسرع إذا لم تحدث مشاكل ContainerConfig)
    # docker-compose up -d --no-deps backend
    ```
6.  **[على الخادم المضيف - Host OS Terminal]** طبق الـ Migrations إذا كانت التغييرات تتضمن تعديلات على الموديل:
    ```bash
    docker-compose exec backend python3 manage.py migrate
    ```
7.  **[على الخادم المضيف - Host OS Terminal]** أعد جمع الملفات الثابتة إذا أضفت أو عدلت ملفات static:
    ```bash
    docker-compose exec backend python3 manage.py collectstatic --noinput
    ```

---

بهذا الدليل، يجب أن تكون عملية النشر والتحديث واضحة ومنظمة.