# Admin Dashboard Design Brief - MediSwitch

**Project:** MediSwitch Admin Dashboard
**Platform:** Web (Responsive - Desktop & Mobile)
**Framework (Technical Context):** React + TailwindCSS (Cloudflare Pages)
**Target Audience:** Admin Users (Pharmacists/Developers managing the app)

## Objective
Design a modern, professional, and high-utility Admin Dashboard for managing the MediSwitch mobile application. The design should feel premium, data-driven, and intuitive.

**Primary Goal:** Provide a visual interface to manage drug data, view analytics (missed searches, price updates), and control app configuration (Ads, Alerts) without touching code.

## Design Aesthetics
*   **Theme:** Professional Medical/Tech. Clean, high contrast, readable data tables.
*   **Colors:** Align with the mobile app's "Medical Blue" brand but adapted for a dashboard interface. Support for Dark Mode is a plus.
*   **Vibe:** "Control Center". Efficient, dense but not cluttered.

## Required Pages & Features

### 1. Login Screen
*   **Concept:** Secure entry point.
*   **Elements:** Branding (Logo), Password Input (Masked), "Login" Button.
*   **Details:** Simple, centered card layout.

### 2. Dashboard Home (Overview)
*   **Concept:** At-a-glance health of the system.
*   **Key Stats (Cards):**
    *   Total Drugs (e.g., 24,500)
    *   Total Users (Active Last 30 Days)
    *   Total Revenue (AdMob Est.)
    *   Recent Updates (Count of price changes today)
*   **Charts:**
    *   **Price Updates Trend:** Line chart showing number of price changes over the last 30 days.
    *   **Search Volume:** Bar chart of daily search queries.

### 3. Drug Management (Headless CMS)
*   **Concept:** Search, view, and edit drug data.
*   **Data Grid:** Table showing: Trade Name, Price, Active Ingredient, Category, Last Update.
*   **Actions:**
    *   **Search/Filter:** Powerful search bar.
    *   **Quick Edit:** Inline editing for Price and Name.
    *   **Toggle Visibility:** "Hide/Show" switch (e.g., for recalled drugs).
    *   **Edit Details:** Button to open a full form for deep editing.
*   **Add New Drug:** Modal or separate page to input all drug fields manually.

### 4. Intelligence & Analytics (Critical Feature)
*   **Concept:** Actionable insights to improve the app.
*   **sections:**
    *   **Missed Searches (Top Priority):** A list of terms users searched for but found NO results. (Helps identify missing stock).
    *   **Top Trending Drugs:** What are people searching for most this week?
    *   **User Feedback:** (Future placeholder)

### 5. Monetization & Ads Control
*   **Concept:** Manage revenue streams without app updates.
*   **Controls:**
    *   **AdMob IDs:** Input fields to update Banner/Interstitial Unit IDs remotely.
    *   **Ad Frequency:** Slider or Input (e.g., "Show Interstitial every X clicks").
    *   **Premium Features:** Toggle switches to Enable/Disable specific paid features globally (e.g., "Enable Dosage Calculator").

### 6. App Configuration & Broadcasting
*   **Concept:** Remote control of the app instance.
*   **Global Alert:** Text input to send a banner message to all users (e.g., "Server Maintenance at 10 PM").
*   **Force Update:** Input field for "Minimum Supported Version".
*   **Maintenance Mode:** Big "Emergency Stop" toggle to show a maintenance screen on the app.

## Deliverables Required
The designer should provide the following in Markdown (`.md`) format to facilitate developer handoff:

1.  **`DESIGN_SYSTEM.md`**:
    *   Color Palette (Hex codes for Primary, Surface, Error, Success).
    *   Typography (Font Family, Scale for Headings/Body).
    *   Component Specs (Button styles, Card shadows, Input field states).
2.  **`ASSETS_LIST.md`**:
    *   List of icons needed (preferably Lucide/Phosphor).
    *   List of any custom illustrations.
3.  **`LAYOUT_SPECS.md`**:
    *   Description of the Layout Structure (Sidebar vs Topbar, Responsive behavior).
4.  **Mockups (Images):** Visual representations of the pages described above.

**Note to Designer:**
*   Focus strictly on **UI/UX Design**.
*   The technical implementation (React/Code) will be handled by the developer.
*   Think "Atomic Design" – reusable components are preferred.
