#!/bin/bash
set -e

echo "=========================================="
echo " Setting up Android and Mac build files..."
echo "=========================================="

flutter create . --org com.wallpapersync --platforms=android,macos

echo "Restoring custom Wallpaper Sync native implementations..."
cp -f custom_backup/android/app/google-services.json android/app/
cp -f custom_backup/android/app/src/main/AndroidManifest.xml android/app/src/main/
mkdir -p android/app/src/main/kotlin/com/wallpapersync/app
cp -f custom_backup/android/app/src/main/kotlin/com/wallpapersync/app/* android/app/src/main/kotlin/com/wallpapersync/app/
cp -f custom_backup/macos/Runner/MainFlutterWindow.swift macos/Runner/
cp -f custom_backup/macos/Runner/GoogleService-Info.plist macos/Runner/

# Ensure minSdkVersion is at least 21 for Firebase
if [ -f "android/app/build.gradle" ]; then
    sed -i '' 's/minSdkVersion = flutter.minSdkVersion/minSdkVersion = 21/g' android/app/build.gradle 2>/dev/null || true
    sed -i '' 's/minSdk = flutter.minSdk/minSdk = 21/g' android/app/build.gradle 2>/dev/null || true
fi

echo ""
echo "=========================================="
echo " Setup complete! Ready to build and run."
echo "=========================================="
