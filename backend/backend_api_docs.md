# MediSwitch Backend API Documentation

This document outlines the API endpoints provided by the MediSwitch Django backend.

**Base URL:** `/api/v1/` (Assumed prefix, configured in main `urls.py`)

---

## Authentication

Authentication for admin-protected endpoints relies on JWT (JSON Web Tokens). Clients should obtain a token via the standard `djangorestframework-simplejwt` endpoints (likely `/api/token/` and `/api/token/refresh/`) and include the access token in the `Authorization: Bearer <token>` header for protected requests.

*   **`POST /auth/register/`**
    *   **Description:** Registers a new standard user (if needed in the future, currently only admin exists).
    *   **Permissions:** AllowAny
    *   **Request Body:** Standard Django User fields (username, password, email).
    *   **Response:** User details on success.

---

## Drug Data Management (Admin Only)

These endpoints require admin user authentication (JWT Bearer token).

*   **`POST /admin/data/update-prices/`**
    *   **Description:** Updates prices for existing drugs based on an uploaded CSV or XLSX file. The file must match the specified format. Finds drugs by `trade_name` (case-insensitive). Stores the current price in `old_price` before updating.
    *   **Permissions:** IsAdminUser
    *   **Request:** `multipart/form-data` with a file field named `file`.
    *   **File Format:** CSV/XLSX with columns (case-insensitive headers):
        *   `Cleaned Drug Name` (maps to `trade_name`)
        *   `السعر الجديد` (New Price)
        *   `السعر القديم` (Optional, currently ignored by view)
        *   `Formatted Date` (Optional, currently ignored by view)
    *   **Response (Success - 200 OK):**
        ```json
        {
          "message": "Price update process finished.",
          "updated_count": <number>,
          "not_found_drugs": ["drug_name1", ...],
          "processing_errors": ["error message1", ...]
        }
        ```
    *   **Response (Error - 400/500):** Standard error JSON.

*   **`POST /admin/data/add-drugs/`**
    *   **Description:** Adds new drugs to the database from an uploaded CSV or XLSX file. Skips drugs if a drug with the same `trade_name` (case-insensitive) already exists.
    *   **Permissions:** IsAdminUser
    *   **Request:** `multipart/form-data` with a file field named `file`.
    *   **File Format:** CSV/XLSX with columns matching the `Drug` model fields (see task description for format, case-insensitive headers): `trade_name`, `arabic_name`, `old_price`, `price`, `active`, `main_category`, `main_category_ar`, `category`, `category_ar`, `company`, `dosage_form`, `dosage_form_ar`, `unit`, `usage`, `usage_ar`, `description`, `last_price_update`.
    *   **Response (Success - 200 OK):**
        ```json
        {
          "message": "Add drugs process finished.",
          "added_count": <number>,
          "skipped_duplicates": <number>,
          "processing_errors": ["error message1", ...]
        }
        ```
    *   **Response (Error - 400/500):** Standard error JSON.

*   **Note:** Manual CRUD operations (Create, Read, Update, Delete) for individual drugs are available via the standard Django Admin interface at `/admin/api/drug/` for logged-in admin users.

---

## Core Functionality APIs (Placeholders)

These endpoints are placeholders and currently return a 501 Not Implemented status.

*   **`POST /drugs/check-interactions/`**
    *   **Description:** (Planned) Checks for potential interactions between a list of provided drugs.
    *   **Permissions:** AllowAny (or potentially Authenticated User)
    *   **Request Body:**
        ```json
        {
          "drugs": ["drug_identifier_1", "drug_identifier_2", ...] // Identifiers could be names or IDs
        }
        ```
    *   **Response (Planned Success - 200 OK):**
        ```json
        {
          "requested_drugs": [...],
          "interactions": [
            {
              "drug_pair": ["drug1", "drug2"],
              "severity": "Major/Moderate/Minor",
              "description": "Details about the interaction...",
              "recommendation": "Clinical recommendation..."
            },
            ...
          ]
        }
        ```
    *   **Current Response (501 Not Implemented):**
        ```json
        {
            "message": "Interaction check endpoint not yet implemented.",
            "requested_drugs": [...],
            "interactions": []
        }
        ```

*   **`POST /drugs/calculate-dosage/`**
    *   **Description:** (Planned) Calculates the appropriate dosage for a given drug based on patient parameters.
    *   **Permissions:** AllowAny (or potentially Authenticated User)
    *   **Request Body:**
        ```json
        {
          "drug_identifier": "drug_name_or_id",
          "patient_age": <number>, // units? (years/months)
          "patient_weight_kg": <number>, // optional?
          "dosage_form": "Syrup/Tablet/...", // optional?
          // other relevant parameters...
        }
        ```
    *   **Response (Planned Success - 200 OK):**
        ```json
        {
          "request_params": {...},
          "result": {
            "calculated_dose": "e.g., 5ml",
            "frequency": "e.g., 3 times daily",
            "notes": ["Warning...", "Administer with food..."],
            // other result fields...
          }
        }
        ```
     *   **Current Response (501 Not Implemented):**
        ```json
        {
            "message": "Dosage calculation endpoint not yet implemented.",
            "request_params": {...},
            "result": {}
        }
        ```

---

## Configuration APIs

*   **`GET /config/ads/`**
    *   **Description:** Retrieves the AdMob configuration (ad unit IDs, enabled status).
    *   **Permissions:** AllowAny
    *   **Response:** `AdMobConfig` serialized data.

*   **`GET /config/general/`**
    *   **Description:** Retrieves general app configuration (e.g., privacy policy URL).
    *   **Permissions:** AllowAny
    *   **Response:** `GeneralConfig` serialized data.

---

## Analytics & Subscriptions

*   **`POST /analytics/log/`**
    *   **Description:** Logs an analytics event sent from the client.
    *   **Permissions:** AllowAny
    *   **Request Body:**
        ```json
        {
          "event_type": "search | drug_view | calculation | ...",
          "details": { ... } // Optional JSON object with event-specific details
        }
        ```
    *   **Response (Success - 201 Created):** `{ "message": "Event logged successfully." }`

*   **`GET /analytics/summary/`**
    *   **Description:** Retrieves basic analytics summaries (e.g., top search queries).
    *   **Permissions:** IsAdminUser
    *   **Response:** JSON object with summary data.

*   **`POST /subscriptions/validate/`**
    *   **Description:** Validates an in-app purchase token with the respective app store (currently placeholder logic). Updates user subscription status on success.
    *   **Permissions:** AllowAny
    *   **Request Body:**
        ```json
        {
          "platform": "android | ios",
          "purchase_token": "...",
          "product_id": "..."
        }
        ```
    *   **Response:** JSON indicating validation success/failure and premium status.

---

## Legacy Data Endpoints (Review Needed)

These endpoints were part of the previous file-based data approach. Their relevance needs review in the context of the new database-driven model and frontend synchronization strategy.

*   **`GET /data/version/`**
    *   **Description:** Previously returned the version (timestamp) of the active data file. Might be adapted for the sync mechanism or deprecated.
    *   **Permissions:** AllowAny

*   **`GET /data/latest/`**
    *   **Description:** Previously served the entire active data file (CSV/XLSX). Likely deprecated in favor of API-driven data fetching and synchronization.
    *   **Permissions:** AllowAny

---