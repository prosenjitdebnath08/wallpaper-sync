# Wallpaper Sync (macOS • Android • iOS)

A unified, real-time cross-device wallpaper synchronization app. When you change or upload a wallpaper on any device (MacBook, Android phone/tablet, or iPhone), all other connected devices logged into your Google Account automatically update their wallpaper.

---

## Architecture Overview

```
                      ┌──────────────────────────────────────────────┐
                      │          Firebase / Google Cloud             │
                      │  • Google OAuth (Firebase Auth)              │
                      │  • Cloud Firestore (Active state & devices)  │
                      │  • Firebase Storage (High-res wallpapers)    │
                      │  • Cloud Functions (FCM push triggers)       │
                      └──────────────────────┬───────────────────────┘
                                             │
             ┌───────────────────────────────┼──────────────────────────────┐
             │                               │                              │
             ▼                               ▼                              ▼
    ┌─────────────────┐             ┌─────────────────┐            ┌─────────────────┐
    │     macOS       │             │     Android     │            │       iOS       │
    │  MacBook / Mac  │             │   Phone / Tablet│            │  iPhone / iPad  │
    ├─────────────────┤             ├─────────────────┤            ├─────────────────┤
    │ NSWorkspace API │             │ WallpaperManager│            │ Apple Shortcuts │
    │ 100% Background │             │ 100% Background │            │ & App Intents   │
    │ Desktop update  │             │ Silent FCM sync │            │ Zero-Tap sync   │
    └─────────────────┘             └─────────────────┘            └─────────────────┘
```

---

## Platform Automation Details

| Platform | Automation Engine | Behavior |
| :--- | :--- | :--- |
| **macOS** | `NSWorkspace.shared.setDesktopImageURL(...)` | **100% Automatic & Silent**. Runs in the background (status menu bar). Updates wallpaper across all connected monitors simultaneously. |
| **Android** | `WallpaperFCMService` + `WallpaperManager` | **100% Automatic & Unattended**. Receives high-priority silent FCM push messages in the background, downloads the image, and sets Home and Lock screens without user interaction. |
| **iOS** | `GetSyncedWallpaperIntent` + Apple Shortcuts Automation | **Zero-Tap Automated**. Bypasses Apple's 3rd-party sandbox restrictions via iOS Personal Automation in Apple Shortcuts (see [iOS Setup Guide](file:///Users/prosenjitdebnath/.gemini/antigravity/scratch/wallpaper_sync/ios/AUTOMATION_SETUP.md)). |

---

## Project Structure

```
wallpaper_sync/
├── lib/
│   ├── main.dart                  # App bootstrap, auth gate & FCM background handler
│   ├── models/
│   │   ├── device_model.dart      # Device registry model (macOS, Android, iOS)
│   │   └── wallpaper_model.dart   # Wallpaper metadata model
│   ├── screens/
│   │   ├── home_screen.dart       # Current wallpaper preview, library, upload & broadcast
│   │   ├── login_screen.dart      # Google Sign-In onboarding screen
│   │   ├── device_list_screen.dart# Real-time list of connected devices
│   │   └── settings_screen.dart   # Auto-apply toggles & platform options
│   └── services/
│       ├── auth_service.dart      # Google OAuth & Firebase Authentication
│       ├── sync_service.dart      # Firestore real-time listener & broadcasting
│       └── wallpaper_service.dart # Native platform channel bridge
├── macos/
│   ├── Runner/
│   │   └── MainFlutterWindow.swift # Native macOS Swift NSWorkspace integration
│   └── macos_agent/
│       ├── wallpaper_daemon.swift  # Native Swift CLI / daemon source
│       └── wallpaper_sync_mac     # Pre-compiled native macOS test executable
├── android/
│   └── app/src/main/
│       ├── AndroidManifest.xml    # Permissions (SET_WALLPAPER, WAKE_LOCK, etc.)
│       └── kotlin/.../
│           ├── MainActivity.kt    # Android WallpaperManager method channel
│           └── WallpaperFCMService.kt # Silent background sync FCM receiver
├── ios/
│   ├── Runner/
│   │   ├── AppDelegate.swift      # Shared App Group container storage
│   │   ├── WallpaperAppIntent.swift# iOS 16+ App Intents for Apple Shortcuts
│   │   └── Info.plist             # Background fetch & push notification config
│   └── AUTOMATION_SETUP.md        # Step-by-step Apple Shortcuts automation guide
└── backend/
    ├── functions/index.js         # Firebase Cloud Functions (FCM broadcast trigger)
    ├── firestore.rules            # Security rules for device and user data
    └── storage.rules              # Security rules for image uploads
```

---

## Testing the Native macOS Wallpaper Engine

A pre-compiled native macOS engine is available right now:

```bash
# 1. Test setting wallpaper with any local image:
/Users/prosenjitdebnath/.gemini/antigravity/scratch/wallpaper_sync/macos/macos_agent/wallpaper_sync_mac /path/to/any_image.jpg

# 2. Or test setting wallpaper directly from a remote image URL:
/Users/prosenjitdebnath/.gemini/antigravity/scratch/wallpaper_sync/macos/macos_agent/wallpaper_sync_mac https://images.unsplash.com/photo-1506744038136-46273834b3fb
```

---

## Setup & Running the Flutter App

### 1. Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) installed.
- A Firebase project with **Authentication (Google)**, **Cloud Firestore**, **Storage**, and **Cloud Messaging** enabled.

### 2. Configure Firebase
- Place your `google-services.json` into `android/app/`.
- Place your `GoogleService-Info.plist` into `ios/Runner/` and `macos/Runner/`.

### 3. Run the App
```bash
cd /Users/prosenjitdebnath/.gemini/antigravity/scratch/wallpaper_sync

# Fetch dependencies
flutter pub get

# Run on macOS
flutter run -d macos

# Run on Android
flutter run -d android

# Run on iOS
flutter run -d ios
```
