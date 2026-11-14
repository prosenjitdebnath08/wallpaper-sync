import AppIntents
import UIKit

// App Intent for Apple Shortcuts (iOS 16+)
// Allows iOS Shortcuts Automation to retrieve the synced image and pass it to "Set Wallpaper" action
@available(iOS 16.0, *)
struct GetSyncedWallpaperIntent: AppIntent {
    static var title: LocalizedStringResource = "Get Active Synced Wallpaper"
    static var description = IntentDescription("Fetches the latest synced wallpaper image to set as your iOS background.")

    static var openAppWhenRun: Bool = false

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<IntentFile?> {
        let fileManager = FileManager.default
        let appGroupId = "group.com.wallpapersync.app"

        var imageURL: URL? = nil
        if let groupURL = fileManager.containerURL(forSecurityApplicationGroupIdentifier: appGroupId) {
            let candidate = groupURL.appendingPathComponent("active_wallpaper.png")
            if fileManager.fileExists(atPath: candidate.path) {
                imageURL = candidate
            }
        }

        if imageURL == nil {
            let docURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
            let candidate = docURL.appendingPathComponent("active_wallpaper.png")
            if fileManager.fileExists(atPath: candidate.path) {
                imageURL = candidate
            }
        }

        guard let targetURL = imageURL else {
            return .result(value: nil)
        }

        let file = IntentFile(fileURL: targetURL, filename: "active_wallpaper.png")
        return .result(value: file)
    }
}

@available(iOS 16.0, *)
struct WallpaperSyncShortcutsProvider: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: GetSyncedWallpaperIntent(),
            phrases: ["Update wallpaper from Wallpaper Sync", "Sync my wallpaper"],
            shortTitle: "Sync Wallpaper",
            systemImageName: "wallpaper"
        )
    }
}
