#!/usr/bin/env bash
# Linux/Mac/GitHub ke liye. (Windows par tools/setup.dart wale commands use karein, README dekhein.)
set -euo pipefail

command -v flutter >/dev/null || { echo "Flutter install nahi hai: https://docs.flutter.dev/get-started/install"; exit 1; }

[ -f lib/main.dart ] || { echo "lib/main.dart nahi mili. Files ka folder structure check karein."; exit 1; }

flutter create --platforms=android --org com.example --project-name simple_player .
flutter pub get
dart tools/setup.dart
flutter build apk --release

echo
echo "APK tayyar: build/app/outputs/flutter-apk/app-release.apk"
