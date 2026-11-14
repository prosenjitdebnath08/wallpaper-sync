# iOS Zero-Tap Wallpaper Automation Guide

Because Apple strictly forbids 3rd-party apps from programmatically overwriting the iOS Lock Screen or Home Screen in the background without user consent, **Apple Shortcuts Personal Automation** is the official, Apple-approved way to achieve **100% automated wallpaper updates**.

---

## How It Works

1. When any device changes the wallpaper, Wallpaper Sync saves the new image into the shared container `active_wallpaper.png`.
2. A silent background push notification or scheduled automation in Apple Shortcuts activates.
3. Apple Shortcuts runs the native system action **"Set Wallpaper"** pointing to this image.
4. Your Lock Screen and Home Screen update with **zero manual tapping**.

---

## 2-Minute Setup in Apple Shortcuts

### Method A: App-Triggered Automation (Instant)
1. Open the built-in **Shortcuts** app on your iPhone.
2. Tap the **Automation** tab at the bottom.
3. Tap **New Automation** (or the **+** icon in the top right).
4. Scroll down and select **App**.
5. Tap **Choose** and select **Wallpaper Sync**.
6. Check **Is Closed** (or **Is Opened**).
7. Select **Run Immediately** (disable *Ask Before Running* and turn off *Notify When Run*).
8. Tap **Next** $\rightarrow$ tap **New Blank Automation**.
9. Tap **Add Action** $\rightarrow$ search for **"Wallpaper Sync"** or choose action **"Get Active Synced Wallpaper"**.
10. Add a second action: search for **"Set Wallpaper"** (the built-in iOS action).
11. Set the image to the output of step 9 $\rightarrow$ Tap **Done**.

### Method B: Scheduled Daily / Hourly Automation
1. In **Shortcuts** $\rightarrow$ **Automation** $\rightarrow$ **+**.
2. Select **Time of Day** (e.g. 7:00 AM, or multiple times per day).
3. Select **Run Immediately**.
4. Add action: **"Get Active Synced Wallpaper"** $\rightarrow$ **"Set Wallpaper"**.
5. Tap **Done**.

---

Your iPhone will now automatically update its wallpaper whenever synced from your MacBook or Android!
