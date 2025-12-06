# Mobile App Redesign Brief - MediSwitch

**Project:** MediSwitch Mobile App Redesign
**Platform:** Android & iOS (Mobile)
**Role:** UI/UX Designer
**Output Required:** Figma/XD Designs + Design System (No Coding Required)

## 1. Project Overview
MediSwitch is a pharmaceutical directory app used by pharmacists and patients to search for drugs, check prices, find alternatives, and view drug interactions.
**Goal:** We need a **complete visual overhaul**. The current design is functional but needs to be more modern, premium, and trustworthy.

> **Important for Designer:**
> You do **NOT** need to know Flutter or coding.
> Your job is to create the raw **Visual Design** (UI) and **User Experience** (UX).
> Our development team will handle the implementation code.
> **Key Constraint:** Design for standard mobile densities (375x812 or similar).

## 2. Design System Requirements
Before designing screens, please establish a cohesive visual language:
*   **Color Palette:**
    *   **Primary:** Medical Blue (Trustworthy, Professional).
    *   **Secondary/Accent:** For buttons and highlights.
    *   **Semantic Colors:**
        *   🔴 **Danger/High Risk:** For dangerous drugs and strict warnings.
        *   🟡 **Warning:** For moderate interactions.
        *   🟢 **Success/Safe:** For compatible drugs or "New" badges.
*   **Typography:** Modern sans-serif (English) and a matching clean Arabic font (e.g., Cairo, Almarai) as the app is **Bilingual (RTL/LTR)**.
*   **Components:**
    *   **Cards:** Drug cards, Category cards.
    *   **Badges:** "New", "Popular", "Price Drop", "Interaction Alert".
    *   **Inputs:** Search fields, Dropdowns.

## 3. Screen Specifications & Data Points
Please redesign the following screens including all the listed data points.

### A. Home Screen (Dashboard)
*   **Header:** App Logo, Notification Bell, "Last Updated" Date.
*   **Search Entry:** Large, prominent search bar (Text: "Search by Trade Name or Active Ingredient...").
*   **Quick Stats:** "Today's Updates: +30 Drugs" (Small summary widget).
*   **Sections:**
    1.  **Medical Specialties (Categories):** Horizontal scrollable list (e.g., Dental, Cardiac, Derma).
    2.  **Most Dangerous Drugs:** **Critical Section**. Needs to look cautionary. Horizontal list of drugs with known severe interactions.
    3.  **Recently Added:** List of new drugs.

### B. Search Results Screen
*   **Layout:** Vertical list of Drug Cards.
*   **Filters:** Filter by Price, Form (Tablet/Syrup), Company.
*   **The Drug Card (Most Important Component):**
    *   **Must Show:**
        *   Trade Name (En & Ar).
        *   Type/Form (Icon + Text, e.g., "Tablet").
        *   Active Ingredient (Scientific Name).
        *   **Price:** Current Price + Old Price (strikethrough) + Percentage Change (e.g., "📉 -10%").
        *   **Badges:** [NEW], [POPULAR], [⚠️ Interaction Warning].
        *   **Actions:** "Add to Favorites" (Heart icon).

### C. Drug Details Screen (The Core)
*   **Header (Hero Section):** Big clear Trade Name, Form Icon, and Company Name.
*   **Tabbed Interface (5 Tabs):**
    1.  **Info:** Description, Manufacturer, Registration Number.
    2.  **Dosage:**
        *   **Strength:** (e.g., 500mg).
        *   **Standard Dose:** (e.g., "1 Tablet every 12 hours").
        *   **Instructions:** (e.g., "Take after food").
    3.  **Alternatives (Similar Drugs):** List of other drugs with the SAME active ingredient but cheaper/different company.
    4.  **Interactions:** **Critical Safety Info**.
        *   List of drugs that conflict with this one.
        *   Severity Levels: Major (Red), Moderate (Yellow), Minor (Blue).
    5.  **Price History:** Chart or list showing price changes over time.

## 4. Deliverables
1.  **High-Fidelity Mockups:** For all screens above in Light and Dark mode.
2.  **Clickable Prototype:** linking the screens (Optional but preferred).
3.  **Assets Folder:** All icons and illustrations used (SVG/PNG).
4.  **Documentation:** A brief explanation of the "Color Logic" (why red here? why blue here?).

## 5. Notes
*   The app supports **Arabic (Right-to-Left)** and **English (Left-to-Right)**. Please demonstrate at least one screen in Arabic layout.
*   Focus on **Accessibility**: Text must be readable, buttons easy to tap.
