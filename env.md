# Development Environment Details

This document lists the key tools and their versions used in the MediSwitch project development environment.

## Flutter & Dart

*   **Flutter:** 3.29.2 (stable)
*   **Dart:** 3.7.2
*   **DevTools:** 2.42.3

## Java Development Kit (JDK)

*   **Version Used by Gradle:** 23.0.2
*   **Location:** `C:\Program Files\Java\jdk-23.0.2` (Detected via `gradlew --version`)

## Android SDK Components (`G:\App\myapps\setup\Android\Sdk`)

*   **Build Tools:**
    *   30.0.3
    *   33.0.1
    *   34.0.0
    *   36.0.0
*   **Platforms:**
    *   android-28
    *   android-29
    *   android-31
    *   android-33
    *   android-34
    *   android-35
*   **CMake:**
    *   3.22.1
*   **NDK:**
    *   25.1.8937393
    *   27.0.12077973

## Gradle (Project Specific)

*   **Gradle Wrapper Version:** 8.10.2 (defined in `android/gradle/wrapper/gradle-wrapper.properties`)

## Project Configuration (from `android/app/build.gradle`)

*   **compileSdk:** 35
*   **minSdk:** 28
*   **targetSdk:** 35
*   **Kotlin JVM Target:** 17
*   **Java Compatibility:** 17
*   **Explicit NDK Version (in build.gradle):** Not currently set (commented out)
