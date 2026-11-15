# 📱💻 Wallpaper Sync

> **Seamless, real-time two-way wallpaper synchronization across Android and macOS.**  
> Pick a photo on your Android phone, tap **Sync Everywhere**, and your MacBook desktop wallpaper automatically changes in **3 seconds**.

---

## ⚡ Quick Start (Ready to Use in 60 Seconds)

You and your friends can use this app immediately with zero setup or coding required:

### 📱 1. On your Android Phone:
1. Download **[`WallpaperSync.apk`](https://github.com/prosenjitdebnath08/wallpaper-sync/releases/latest)**.
2. Tap **Install** (or Update).
3. Open the app and tap **"Sign in with Google"**.

### 💻 2. On your MacBook:
1. Download **[`WallpaperSync-Mac.zip`](https://github.com/prosenjitdebnath08/wallpaper-sync/releases/latest)**.
2. Unzip it and double-click **`Install_Mac.command`**.
3. Press **[Enter]** when prompted. 
4. *Done! The background sync agent is now permanently active.*

### 🚀 3. Test Sync:
- In the mobile app, tap **"Upload & Change on All Devices"**.
- Pick any photo from your gallery and tap **"Sync Everywhere"**.
- Watch your MacBook desktop update automatically within **3 seconds**!

---

## ✨ Features

- **Private & Multi-User:** Every person's wallpapers sync only to their own devices based on their Google account.
- **Zero Billing / 100% Free:** Uses high-speed free cloud image hosting — no credit cards, Blaze plans, or paid subscriptions required.
- **24/7 Silent Mac Background Daemon:** Runs natively using Apple's `NSWorkspace` APIs and macOS `launchd`. It works quietly in the background without needing Terminal open.
- **Auto-Detects Google Drive:** Automatically detects any user's Google Drive folder (`~/Library/CloudStorage/GoogleDrive-*`) and backs up wallpapers locally.
- **Minimalist Clean UI:** Shows only your active wallpaper preview with a single tap to change it everywhere.

---

## 🛠️ Architecture

```
                      ┌──────────────────────────────────────────────┐
                      │          Firebase & Free Cloud               │
                      │  • Google OAuth (Firebase Auth)              │
                      │  • Cloud Firestore (Active state & sync)     │
                      │  • Zero-Billing Direct Image Hosting         │
                      └──────────────────────┬───────────────────────┘
                                             │
             ┌───────────────────────────────┴──────────────────────────────┐
             │                                                              │
             ▼                                                              ▼
    ┌─────────────────┐                                            ┌─────────────────┐
    │     macOS       │                                            │     Android     │
    │  MacBook / Mac  │                                            │   Phone / Tablet│
    ├─────────────────┤                                            ├─────────────────┤
    │ NSWorkspace API │                                            │ WallpaperManager│
    │ launchd Agent   │                                            │ Flutter App     │
    │ 100% Background │                                            │ 1-Tap Sync      │
    └─────────────────┘                                            └─────────────────┘
```

---

## 📂 Repository Structure

```
wallpaper_sync/
├── lib/
│   ├── main.dart                  # App bootstrap & auth gate
│   ├── screens/
│   │   ├── home_screen.dart       # Clean active wallpaper preview & upload
│   │   └── login_screen.dart      # 1-tap Google Sign-In
│   └── services/
│       ├── auth_service.dart      # Google OAuth authentication
│       ├── sync_service.dart      # Real-time Firestore sync & cloud upload
│       └── wallpaper_service.dart # Native wallpaper platform channels
├── macos/
│   ├── Install_Mac.command        # 1-Click double-clickable Mac installer
│   ├── Uninstall_Mac.command      # 1-Click Mac uninstaller
│   └── macos_agent/
│       └── universal_sync.swift   # Native Swift background sync daemon
├── android/
│   └── app/                       # Android Flutter wrapper & native channels
└── WallpaperSync-Mac.zip          # Packaged 1-click Mac bundle
```

---

## 🗑️ How to Uninstall

- **Android:** Long press the **Wallpaper Sync** icon on your phone and tap **Uninstall**.
- **Mac:** Double-click **`Uninstall_Mac.command`** in the Mac bundle.
