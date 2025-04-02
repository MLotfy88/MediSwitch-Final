# هيكل المشروع

/root/workspace/project
├── .devcontainer/
│   ├── Dockerfile
│   └── devcontainer.json
├── .github/
│   └── workflows/
│       └── build_apk.yml
├── .gitignore
├── .gitpod.yml
├── .gitpod/
│   └── Dockerfile
├── .metadata
├── AI_HANDOVER_CHECKPOINT.md
├── Project Structure.md
├── analysis_options.yaml
├── android/
│   ├── .gitignore
│   ├── app/
│   │   ├── build.gradle
│   │   ├── build.gradle.kts
│   │   ├── proguard-rules.pro
│   │   └── src/
│   │       ├── debug/
│   │       │   └── AndroidManifest.xml
│   │       ├── main/
│   │       │   ├── AndroidManifest.xml
│   │       │   ├── java/
│   │       │   │   └── io/
│   │       │   │       └── flutter/
│   │       │   │           └── plugins/
│   │       │   ├── kotlin/
│   │       │   │   └── com/
│   │       │   │       └── example/
│   │       │   │           └── mediswitch/
│   │       │   │               └── MainActivity.kt
│   │       │   └── res/
│   │       │       ├── drawable-v21/
│   │       │       │   └── launch_background.xml
│   │       │       ├── drawable/
│   │       │       │   └── launch_background.xml
│   │       │       ├── mipmap-hdpi/
│   │       │       │   └── ic_launcher.png
│   │       │       ├── mipmap-mdpi/
│   │       │       │   └── ic_launcher.png
│   │       │       ├── mipmap-xhdpi/
│   │       │       │   └── ic_launcher.png
│   │       │       ├── mipmap-xxhdpi/
│   │       │       │   └── ic_launcher.png
│   │       │       ├── mipmap-xxxhdpi/
│   │       │       │   └── ic_launcher.png
│   │       │       ├── values-night/
│   │       │       │   └── styles.xml
│   │       │       └── values/
│   │       │           └── styles.xml
│   │       └── profile/
│   │           └── AndroidManifest.xml
│   ├── build.gradle
│   ├── gradle.properties
│   ├── gradle/
│   │   └── wrapper/
│   │       └── gradle-wrapper.properties
│   └── settings.gradle
├── app_prompt.md
├── assets/
│   └── meds.csv
├── backend/
│   ├── .gitignore
│   ├── api/
│   │   ├── models.py
│   │   ├── serializers.py
│   │   ├── urls.py
│   │   └── views.py
│   ├── manage.py
│   ├── mediswitch_api/
│   │   ├── __init__.py
│   │   ├── asgi.py
│   │   ├── settings.py
│   │   ├── urls.py
│   │   └── wsgi.py
│   ├── requirements.txt
│   └── templates/
│       ├── admin_login.html
│       └── admin_upload.html
├── env.md
├── ios/
│   ├── .gitignore
│   ├── Flutter/
│   │   ├── AppFrameworkInfo.plist
│   │   ├── Debug.xcconfig
│   │   └── Release.xcconfig
│   ├── Runner.xcodeproj/
│   │   ├── project.pbxproj
│   │   ├── project.xcworkspace/
│   │   │   ├── contents.xcworkspacedata
│   │   │   └── xcshareddata/
│   │   │       ├── IDEWorkspaceChecks.plist
│   │   │       └── WorkspaceSettings.xcsettings
│   │   └── xcshareddata/
│   │       └── xcschemes/
│   │           └── Runner.xcscheme
│   ├── Runner.xcworkspace/
│   │   ├── contents.xcworkspacedata
│   │   └── xcshareddata/
│   │       ├── IDEWorkspaceChecks.plist
│   │       └── WorkspaceSettings.xcsettings
│   ├── Runner/
│   │   ├── AppDelegate.swift
│   │   ├── Assets.xcassets/
│   │   │   ├── AppIcon.appiconset/
│   │   │   │   ├── Contents.json
│   │   │   │   ├── Icon-App-1024x1024@1x.png
│   │   │   │   ├── Icon-App-20x20@1x.png
│   │   │   │   ├── Icon-App-20x20@2x.png
│   │   │   │   ├── Icon-App-20x20@3x.png
│   │   │   │   ├── Icon-App-29x29@1x.png
│   │   │   │   ├── Icon-App-29x29@2x.png
│   │   │   │   ├── Icon-App-29x29@3x.png
│   │   │   │   ├── Icon-App-40x40@1x.png
│   │   │   │   ├── Icon-App-40x40@2x.png
│   │   │   │   ├── Icon-App-40x40@3x.png
│   │   │   │   ├── Icon-App-60x60@2x.png
│   │   │   │   ├── Icon-App-60x60@3x.png
│   │   │   │   ├── Icon-App-76x76@1x.png
│   │   │   │   ├── Icon-App-76x76@2x.png
│   │   │   │   └── Icon-App-83.5x83.5@2x.png
│   │   │   └── LaunchImage.imageset/
│   │   │       ├── Contents.json
│   │   │       ├── LaunchImage.png
│   │   │       ├── LaunchImage@2x.png
│   │   │       ├── LaunchImage@3x.png
│   │   │       └── README.md
│   │   ├── Base.lproj/
│   │   │   ├── LaunchScreen.storyboard
│   │   │   └── Main.storyboard
│   │   ├── Info.plist
│   │   └── Runner-Bridging-Header.h
│   └── RunnerTests/
│       └── RunnerTests.swift
├── lib/
│   ├── core/
│   │   ├── error/
│   │   │   └── failures.dart
│   │   └── usecases/
│   │       └── usecase.dart
│   ├── data/
│   │   ├── datasources/
│   │   │   ├── local/
│   │   │   │   └── csv_local_data_source.dart
│   │   │   └── remote/
│   │   │       └── drug_remote_data_source.dart
│   │   ├── models/
│   │   │   └── medicine_model.dart
│   │   └── repositories/
│   │       └── drug_repository_impl.dart
│   ├── domain/
│   │   ├── entities/
│   │   │   └── drug_entity.dart
│   │   ├── repositories/
│   │   │   └── drug_repository.dart
│   │   └── usecases/
│   │       ├── filter_drugs_by_category.dart
│   │       ├── find_drug_alternatives.dart
│   │       ├── get_all_drugs.dart
│   │       ├── get_available_categories.dart
│   │       ├── get_last_update_timestamp.dart
│   │       └── search_drugs.dart
│   ├── main.dart
│   └── presentation/
│       ├── bloc/
│       │   ├── alternatives_provider.dart
│       │   ├── dose_calculator_provider.dart
│       │   ├── medicine_provider.dart
│       │   └── settings_provider.dart
│       ├── screens/
│       │   ├── alternatives_screen.dart
│       │   ├── dose_comparison_screen.dart
│       │   ├── home_screen.dart
│       │   ├── main_screen.dart
│       │   ├── search_screen.dart
│       │   ├── settings_screen.dart
│       │   └── weight_calculator_screen.dart
│       └── widgets/
│           ├── alternative_drug_card.dart
│           ├── drug_list_item.dart
│           ├── drug_search_delegate.dart
│           └── filter_bottom_sheet.dart
├── linux/
│   ├── .gitignore
│   ├── CMakeLists.txt
│   ├── flutter/
│   │   ├── CMakeLists.txt
│   │   ├── generated_plugin_registrant.cc
│   │   ├── generated_plugin_registrant.h
│   │   └── generated_plugins.cmake
│   └── runner/
│       ├── CMakeLists.txt
│       ├── main.cc
│       ├── my_application.cc
│       └── my_application.h
├── macos/
│   ├── .gitignore
│   ├── Flutter/
│   │   ├── Flutter-Debug.xcconfig
│   │   ├── Flutter-Release.xcconfig
│   │   └── GeneratedPluginRegistrant.swift
│   ├── Runner.xcodeproj/
│   │   ├── project.pbxproj
│   │   ├── project.xcworkspace/
│   │   │   └── xcshareddata/
│   │   │       └── IDEWorkspaceChecks.plist
│   │   └── xcshareddata/
│   │       └── xcschemes/
│   │           └── Runner.xcscheme
│   ├── Runner.xcworkspace/
│   │   ├── contents.xcworkspacedata
│   │   └── xcshareddata/
│   │       └── IDEWorkspaceChecks.plist
│   ├── Runner/
│   │   ├── AppDelegate.swift
│   │   ├── Assets.xcassets/
│   │   │   └── AppIcon.appiconset/
│   │   │       ├── Contents.json
│   │   │       ├── app_icon_1024.png
│   │   │       ├── app_icon_128.png
│   │   │       ├── app_icon_16.png
│   │   │       ├── app_icon_256.png
│   │   │       ├── app_icon_32.png
│   │   │       ├── app_icon_512.png
│   │   │       └── app_icon_64.png
│   │   ├── Base.lproj/
│   │   │   └── MainMenu.xib
│   │   ├── Configs/
│   │   │   ├── AppInfo.xcconfig
│   │   │   ├── Debug.xcconfig
│   │   │   ├── Release.xcconfig
│   │   │   └── Warnings.xcconfig
│   │   ├── DebugProfile.entitlements
│   │   ├── Info.plist
│   │   ├── MainFlutterWindow.swift
│   │   └── Release.entitlements
│   └── RunnerTests/
│       └── RunnerTests.swift
├── mediswitch_plan.md
├── pubspec.lock
├── pubspec.yaml
├── test/
│   └── widget_test.dart
├── web/
│   ├── favicon.png
│   ├── icons/
│   │   ├── Icon-192.png
│   │   ├── Icon-512.png
│   │   ├── Icon-maskable-192.png
│   │   └── Icon-maskable-512.png
│   ├── index.html
│   └── manifest.json
└── windows/
    ├── .gitignore
    ├── CMakeLists.txt
    ├── flutter/
    │   ├── CMakeLists.txt
    │   ├── generated_plugin_registrant.cc
    │   ├── generated_plugin_registrant.h
    │   └── generated_plugins.cmake
    └── runner/
        ├── CMakeLists.txt
        ├── Runner.rc
        ├── flutter_window.cpp
        ├── flutter_window.h
        ├── main.cpp
        ├── resource.h
        ├── resources/
        │   └── app_icon.ico
        ├── runner.exe.manifest
        ├── utils.cpp
        ├── utils.h
        ├── win32_window.cpp
        └── win32_window.h