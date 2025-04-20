# MediSwitch Backend Deployment Guide

This guide provides instructions and options for deploying the MediSwitch Django backend application.

---

## Deployment Options

There are several ways to deploy a Django application. The best choice depends on your technical expertise, budget, and scalability requirements.

1.  **Docker (Recommended):**
    *   **Pros:** Consistent environment, portable, scalable, utilizes the provided `Dockerfile`.
    *   **Cons:** Requires Docker knowledge, managing infrastructure (server, database, reverse proxy).
    *   **Suitable For:** Production deployments, developers comfortable with containers.

2.  **Platform-as-a-Service (PaaS):**
    *   **Examples:** Heroku, PythonAnywhere, Render, Google App Engine.
    *   **Pros:** Simplifies deployment, handles infrastructure (servers, scaling, databases often included or easily added), often have free/hobby tiers.
    *   **Cons:** Can be less flexible than managing your own server, potential vendor lock-in, costs can increase with scale.
    *   **Suitable For:** Faster deployments, developers who prefer less infrastructure management, projects starting small.

3.  **Virtual Private Server (VPS):**
    *   **Examples:** DigitalOcean, Linode, AWS EC2, Google Compute Engine.
    *   **Pros:** Full control over the server environment, cost-effective for predictable loads.
    *   **Cons:** Requires manual setup and maintenance of the OS, web server, database, security, etc.
    *   **Suitable For:** Developers comfortable with Linux server administration.

4.  **Cloudflare Pages (with limitations):**
    *   **Pros:** Excellent free tier, global CDN, great for static sites.
    *   **Cons:** **Primarily designed for static sites.** Deploying a dynamic Django backend directly is **not straightforward**. It would require workarounds like:
        *   Using Cloudflare Workers (serverless functions) to handle API requests, potentially interacting with a separate database service (like Cloudflare D1, Neon, Supabase, etc.). This essentially means rewriting parts of the backend logic in a serverless way.
        *   Using it *only* for the frontend (if built as a static site) and deploying the Django backend elsewhere (e.g., using Docker on a VPS or a PaaS).
    *   **Suitable For:** The *frontend* part of the application if it's built statically. Not ideal for the Django backend itself without significant architectural changes.

---

## Deployment Steps (Docker Approach - General Outline)

This uses the existing `backend/Dockerfile`.

1.  **Prerequisites:**
    *   Docker installed on your deployment server/machine.
    *   A production-ready database (PostgreSQL is highly recommended for Django).
    *   A reverse proxy (like Nginx or Caddy) is recommended for handling HTTPS, serving static/media files, and load balancing.

2.  **Build the Docker Image:**
    *   Navigate to the `backend` directory in your terminal.
    *   Run: `docker build -t mediswitch-backend .`

3.  **Prepare Environment Variables:**
    *   Django requires several environment variables for production:
        *   `SECRET_KEY`: A long, random, secret string. **Do not use the development key.**
        *   `DEBUG`: Set to `False`.
        *   `ALLOWED_HOSTS`: Comma-separated list of domains/IPs the site can be served from (e.g., `yourdomain.com,www.yourdomain.com`).
        *   `DATABASE_URL`: Connection string for your production database (e.g., `postgres://user:password@host:port/dbname`).
        *   `DJANGO_SETTINGS_MODULE`: Should be `mediswitch_api.settings` (usually default).
        *   `MEDIA_ROOT`: Path *inside the container* where uploaded files are stored (e.g., `/app/media`). Needs a persistent volume.
        *   `STATIC_ROOT`: Path *inside the container* where collected static files are stored (e.g., `/app/static`). WhiteNoise will serve these.
        *   (Optional) Email settings, CORS settings, etc.
    *   These can be set using a `.env` file (ensure it's *not* committed to Git) and passed to the container, or via Docker run commands (`-e`), or Docker Compose.

4.  **Run Database Migrations:**
    *   Before starting the main application container, run the migrations against your production database.
    *   `docker run --rm -e DATABASE_URL='<your_prod_db_url>' -e SECRET_KEY='<your_prod_secret_key>' mediswitch-backend python3 manage.py migrate`

5.  **Create Superuser (if needed):**
    *   `docker run --rm -it -e DATABASE_URL='<your_prod_db_url>' -e SECRET_KEY='<your_prod_secret_key>' mediswitch-backend python3 manage.py createsuperuser`

6.  **Run the Application Container:**
    *   This command runs the `gunicorn` server defined in the `Dockerfile`'s `CMD`.
    *   You need to map the container port (e.g., 8000) to a host port and mount volumes for persistent media files.
    *   Example:
        ```bash
        docker run -d \
          --name mediswitch-app \
          -p 8001:8000 \
          -v mediswitch_media:/app/media \
          -e SECRET_KEY='<your_prod_secret_key>' \
          -e DEBUG=False \
          -e ALLOWED_HOSTS='yourdomain.com,www.yourdomain.com' \
          -e DATABASE_URL='<your_prod_db_url>' \
          # Add other environment variables as needed
          mediswitch-backend
        ```
    *   `-d`: Run detached (in background).
    *   `--name`: Assign a name.
    *   `-p 8001:8000`: Map host port 8001 to container port 8000 (where Gunicorn listens).
    *   `-v mediswitch_media:/app/media`: Mount a named volume `mediswitch_media` to the container's `/app/media` directory to persist uploaded files.
    *   `-e`: Set environment variables.

7.  **Configure Reverse Proxy (e.g., Nginx):**
    *   Set up Nginx (or Caddy) to:
        *   Listen on ports 80 and 443.
        *   Handle SSL/TLS certificates (e.g., using Let's Encrypt).
        *   Proxy requests to the Django application container (e.g., `proxy_pass http://127.0.0.1:8001;`).
        *   Serve static files directly (optional but efficient) by mapping the `STATIC_ROOT` location.
        *   Serve media files directly by mapping the `MEDIA_ROOT` volume location.
        *   Set appropriate headers (`Host`, `X-Forwarded-For`, `X-Forwarded-Proto`).

---

## Deployment Steps (PaaS - General Outline)

Platforms like Heroku, PythonAnywhere, and Render have specific workflows, but generally involve:

1.  **Sign Up & Create App:** Create an account and a new application on the platform.
2.  **Connect Git Repository:** Link your Git repository (GitHub, GitLab, etc.) to the PaaS application.
3.  **Configure Buildpacks/Runtime:** Specify that it's a Python/Django application.
4.  **Add Database:** Provision a database add-on (usually PostgreSQL).
5.  **Set Environment Variables:** Configure `SECRET_KEY`, `DATABASE_URL`, `ALLOWED_HOSTS`, etc., through the platform's dashboard or CLI.
6.  **Procfile:** Create a `Procfile` in your `backend` directory tells the PaaS how to run your app:
    ```
    web: gunicorn mediswitch_api.wsgi --log-file -
    release: python manage.py migrate
    ```
    *(The `release` command runs migrations automatically on Heroku during deployment).*
7.  **Static Files:** Configure static file handling (often using WhiteNoise, which is already set up). Ensure `collectstatic` runs during deployment (might be automatic or part of the `release` phase).
8.  **Deploy:** Push your code to the connected Git branch or use the platform's CLI to deploy.

**Refer to the specific documentation for your chosen PaaS provider.**

*   **Heroku:** [Deploying Python Applications with Gunicorn](https://devcenter.heroku.com/articles/deploying-python)
*   **PythonAnywhere:** [Deploying an existing Django project on PythonAnywhere](https://help.pythonanywhere.com/pages/DeployExistingDjangoProject/)
*   **Render:** [Deploy Django](https://render.com/docs/deploy-django)

---

## Important Considerations

*   **Security:**
    *   **NEVER** commit your `SECRET_KEY` or database credentials to version control. Use environment variables.
    *   Set `DEBUG = False` in production.
    *   Configure `ALLOWED_HOSTS` correctly.
    *   Use HTTPS (SSL/TLS).
    *   Keep Django and dependencies updated.
    *   Configure CORS headers (`django-cors-headers`) if your frontend is served from a different domain.
*   **Database:** Use PostgreSQL or MySQL in production. SQLite is not suitable for concurrent access in most production scenarios.
*   **Static & Media Files:** Ensure these are served correctly, either by your web server (Nginx) or a dedicated service (like AWS S3, DigitalOcean Spaces) via `django-storages`. WhiteNoise handles static files well for simpler setups.
*   **Logging:** Configure Django logging to capture errors and important information in production.

---