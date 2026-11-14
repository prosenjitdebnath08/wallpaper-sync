import Foundation
import AppKit

class GoogleDriveWallpaperWatcher {
    let folderURL: URL
    var lastAppliedFilePath: String = ""

    init(folderPath: String) {
        self.folderURL = URL(fileURLWithPath: folderPath)
    }

    func start() {
        print("=========================================================")
        print(" Google Drive Wallpaper Watcher Started!")
        print(" Watching folder: \(folderURL.path)")
        print(" Any new photo dropped from your phone will apply instantly!")
        print("=========================================================")

        // Check immediately on startup
        checkAndApplyNewestWallpaper()

        // Check every 3 seconds for new/modified files
        Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { [weak self] _ in
            self?.checkAndApplyNewestWallpaper()
        }

        RunLoop.current.run()
    }

    func checkAndApplyNewestWallpaper() {
        let fileManager = FileManager.default
        guard let files = try? fileManager.contentsOfDirectory(
            at: folderURL,
            includingPropertiesForKeys: [.contentModificationDateKey, .isRegularFileKey],
            options: [.skipsHiddenFiles]
        ) else { return }

        let supportedExtensions = ["jpg", "jpeg", "png", "heic", "webp"]

        // Filter for image files
        let imageFiles = files.filter { url in
            supportedExtensions.contains(url.pathExtension.lowercased())
        }

        guard !imageFiles.isEmpty else { return }

        // Find the newest file by modification date
        let sortedByDate = imageFiles.sorted { url1, url2 in
            let date1 = (try? url1.resourceValues(forKeys: [.contentModificationDateKey]))?.contentModificationDate ?? Date.distantPast
            let date2 = (try? url2.resourceValues(forKeys: [.contentModificationDateKey]))?.contentModificationDate ?? Date.distantPast
            return date1 > date2
        }

        guard let newestImage = sortedByDate.first else { return }

        if newestImage.path != lastAppliedFilePath {
            lastAppliedFilePath = newestImage.path
            applyWallpaper(fileURL: newestImage)
        }
    }

    func applyWallpaper(fileURL: URL) {
        let workspace = NSWorkspace.shared
        print("🌟 Setting new desktop wallpaper: \(fileURL.lastPathComponent)")

        for screen in NSScreen.screens {
            do {
                try workspace.setDesktopImageURL(
                    fileURL,
                    for: screen,
                    options: [
                        .imageScaling: NSImageScaling.scaleProportionallyUpOrDown.rawValue,
                        .allowClipping: true
                    ]
                )
                print("✓ Successfully set wallpaper on: \(screen.localizedName)")
            } catch {
                print("Error setting wallpaper: \(error.localizedDescription)")
            }
        }
    }
}

// Target folder in Google Drive
let gdriveFolder = "/Users/prosenjitdebnath/Library/CloudStorage/GoogleDrive-prosenjitdebnath08@gmail.com/My Drive/Wallpaper"
let watcher = GoogleDriveWallpaperWatcher(folderPath: gdriveFolder)
watcher.start()
