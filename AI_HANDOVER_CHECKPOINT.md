# MediSwitch Project - AI Handover Checkpoint

**Objective:** Continue development of the MediSwitch mobile application (Flutter) and its supporting backend (Django).

**Core Project Documents:**

1.  **`@/app_prompt.md`**: This file contains the **overall project vision, features, UI/UX guidelines, technical requirements, and monetization strategy**. It defines *what* needs to be built. **Read this first to understand the project goals.**
2.  **`@/mediswitch_plan.md`**: This file contains a **detailed, phased implementation plan** with specific tasks broken down into sub-tasks. It defines *how* the project should be built and tracks progress using `[ ]`, `[~]`, and `[x]` markers. **Refer to this file constantly to understand the current status and determine the next logical step.**

**Current Status (Summary):**

*   **Frontend (Flutter):**
    *   Clean Architecture folder structure created (`lib/core`, `lib/data`, etc.).
    *   Existing basic UI code (screens, provider) has been refactored into this structure.
    *   Core data flow (DataSource -> Repository -> UseCase -> Provider) implemented for fetching initial data from a local CSV asset.
    *   CSV parsing is done in a background isolate using `compute`.
    *   Local file caching (for the initial asset) and timestamp saving (`shared_preferences`) are implemented in `CsvLocalDataSource`.
    *   Core dependencies added to `pubspec.yaml`.
*   **Backend (Django):**
    *   Project (`mediswitch_api`) and app (`api`) structure created.
    *   Dependencies installed (`requirements.txt`).
    *   Basic settings configured (`settings.py`), including REST Framework, Simple JWT, CORS.
    *   `.env` file created (needs secure keys for production).
    *   Initial database migrations applied.
    *   Basic API endpoints implemented:
        *   Admin registration (`/api/v1/auth/register/`)
        *   Admin login/token (`/api/v1/auth/token/`)
        *   Admin data upload (`/api/v1/admin/data/upload/`) - *Note: Version update logic (Task 1.2.2.6) is still pending.*
        *   Data version check (`/api/v1/data/version/`)
        *   Latest data download (`/api/v1/data/latest/`)

**Key Instructions for Continuing Development:**

1.  **Follow the Plan:** Adhere strictly to the `@/mediswitch_plan.md`. Identify the next incomplete task (`[ ]`) in the logical sequence and implement it step-by-step.
2.  **Ask Before Deciding:** **Do not make assumptions or decisions.** If a task is ambiguous, requires choosing between options (like library choices, implementation details not specified in the plan), or if you are unsure about the next step, **you MUST ask for clarification** using the `ask_followup_question` tool before proceeding. Follow the user's direction.
3.  **Validate Code (CRITICAL!):** After every code modification (using `write_to_file` or `apply_diff`), **you MUST check the result for any errors** (compiler errors, linter warnings reported by the system). **DO NOT proceed to the next step or update the plan if there are errors.** Fix all reported errors first. This is extremely important.
4.  **Update the Plan:** After successfully completing *each* task or sub-task **and ensuring the code is error-free**, immediately update the `@/mediswitch_plan.md` file by changing the corresponding marker from `[ ]` or `[~]` to `[x]`.
5.  **Maintain Workflow:** Follow the established pattern: **Implement Task -> Check for Errors -> Fix Errors (if any) -> Update Plan -> Proceed to Next Task.**
6.  **Use Tools Correctly:** Execute file operations, commands, and other actions using the available tools one step at a time, waiting for confirmation after each tool use. Pay close attention to file paths and command syntax.
7.  **Refer to Core Documents:** Constantly refer back to `@/app_prompt.md` for feature requirements and `@/mediswitch_plan.md` for implementation details and status.

**Next Logical Step (Based on `@/mediswitch_plan.md` as of last update):**

*   Implement the **frontend remote data source** (`lib/data/datasources/remote/drug_remote_data_source.dart`) to call the backend's `/api/v1/data/version` endpoint (**Task 2.1.1.1**).
*   Then, implement the logic in `DrugRepositoryImpl` (`lib/data/repositories/drug_repository_impl.dart`) to compare the remote version with the local timestamp and decide whether to trigger a download (**part of Task 2.1.3.1**).