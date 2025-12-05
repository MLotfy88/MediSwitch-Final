# Phase 4: Admin Dashboard Implementation Plan

## Goal
Build a web-based Admin Dashboard to manage the MediSwitch application.
*   **Host:** Cloudflare Pages (Frontend) + Cloudflare Workers (Backend).
*   **Database:** Cloudflare D1 (Shared with App).
*   **Access:** Accessible from any browser via a secure URL.

## Architecture
*   **Frontend (UI):** React + Vite + TailwindCSS. Hosted on **Cloudflare Pages**.
    *   Provides the visual control panel.
*   **Backend (Logic):** Existing/Enhanced **Cloudflare Worker**.
    *   Exposes endpoints (`/api/stats`, `/api/config`) to be called by the Frontend.
*   **Security:** Cloudflare Access (Zero Trust) or simple specialized Auth header protection.

## User Review Required
> [!IMPORTANT]
> **Authentication Strategy:** To secure the dashboard, we will implement a lightweight "Admin Key" login first. For enterprise-grade security later, we can enable Cloudflare Access (requires Cloudflare account configuration).

## Proposed Changes

### 1. Backend: Enhance Cloudflare Worker
We will extend the existing worker (`cloudflare-worker/src/index.js`) to support admin functions.

#### [MODIFY] [cloudflare-worker/src/index.js](file:///home/adminlotfy/project/cloudflare-worker/src/index.js)
*   Add `GET /api/config`: Fetch AdMob IDs and Feature flags.
*   Add `POST /api/config`: Update AdMob IDs and Feature flags.
*   Enhance `GET /api/stats`: Return detailed sync logs and usage metrics.
*   **New D1 Table:** `app_config` to store key-value settings.

### 2. Database: Schema Updates
#### [NEW] [cloudflare-worker/schema_config.sql](file:///home/adminlotfy/project/cloudflare-worker/schema_config.sql)
```sql
CREATE TABLE IF NOT EXISTS app_config (
    key TEXT PRIMARY KEY,
    value TEXT,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
-- Seed default values
INSERT OR IGNORE INTO app_config (key, value) VALUES ('ad_banner_id', 'ca-app-pub-3940256099942544/6300978111');
INSERT OR IGNORE INTO app_config (key, value) VALUES ('ad_interstitial_id', 'ca-app-pub-3940256099942544/1033173712');
```

### 3. Frontend: React Dashboard
Create a new folder `admin-dashboard/` for the React project.

#### [NEW] `admin-dashboard/package.json`
*   Dependencies: `react`, `react-dom`, `recharts` (for charts), `lucide-react`.

#### [NEW] `admin-dashboard/src/App.jsx`
*   **Login Screen:** Simple password prompt (validates against a hashed key or API secret).
*   **Dashboard Home:**
    *   Chart: New Drugs Added (Last 30 Days).
    *   Chart: Price Updates (Last 30 Days).
    *   Stats: Total Users (if tracking), Total Drugs.
*   **Settings Page:**
    *   Input details for AdMob IDs.
    *   Toggles for "Premium Features".

### 4. Deployment Pipeline
#### [MODIFY] [.github/workflows/deploy-dashboard.yml](file:///home/adminlotfy/project/.github/workflows/deploy-dashboard.yml)
*   Build React App (`npm run build`).
*   Deploy to Cloudflare Pages using `cloudflare/pages-action`.

## Verification Plan
### Automated Tests
*   Verify API endpoints (`/api/config`) using `test_api.py`.
### Manual Verification
*   Launch Dashboard locally (`npm run dev`).
*   Log in.
*   Change AdMob ID -> Refresh App -> Verify change (simulated).
