#!/bin/bash
set -e  # إيقاف التنفيذ في حال حدوث خطأ

echo "---------- بدء تحميل الحزم (flutter pub get) ----------"
flutter pub get

echo "---------- بدء بناء APK (Release) ----------"
flutter build apk --release

echo "---------- انتهى البناء ----------"
echo "APK المبني موجود في: build/app/outputs/flutter-apk/app-release.apk"
