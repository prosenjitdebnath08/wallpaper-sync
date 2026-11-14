import Foundation
import AppKit

class WallpaperCloudSync {
    let projectId: String
    var lastUrl: String = ""
    var timer: Timer?

    init(projectId: String) {
        self.projectId = projectId
    }

    func start() {
        print("==================================================")
        print("  Wallpaper Sync - Mac Cloud Service Started")
        print("  Connected to Firebase Project: \(projectId)")
        print("  Listening for new wallpapers from your phone...")
        print("==================================================")

        // Poll Firestore REST API every 4 seconds
        Timer.scheduledTimer(withTimeInterval: 4.0, repeats: true) { [weak self] _ in
            self?.checkCloudWallpaper()
        }
        RunLoop.current.run()
    }

    func checkCloudWallpaper() {
        let endpoint = "https://firestore.googleapis.com/v1/projects/\(projectId)/databases/(default)/documents/sync/current"
        guard let url = URL(string: endpoint) else { return }

        let task = URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard let self = self, let data = data, error == nil else { return }

            guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let fields = json["fields"] as? [String: Any],
                  let urlField = fields["url"] as? [String: Any],
                  let newWallpaperUrl = urlField["stringValue"] as? String else {
                return
            }

            if !newWallpaperUrl.isEmpty && newWallpaperUrl != self.lastUrl {
                print("🌟 New wallpaper received from cloud: \(newWallpaperUrl)")
                self.lastUrl = newWallpaperUrl
                self.applyWallpaper(from: newWallpaperUrl)
            }
        }
        task.resume()
    }

    func applyWallpaper(from urlString: String) {
        guard let url = URL(string: urlString) else { return }

        let downloadTask = URLSession.shared.downloadTask(with: url) { localUrl, _, error in
            guard let localUrl = localUrl, error == nil else {
                print("Failed to download image: \(error?.localizedDescription ?? "unknown")")
                return
            }

            let cacheDir = FileManager.default.temporaryDirectory.appendingPathComponent("wallpaper_sync")
            try? FileManager.default.createDirectory(at: cacheDir, withIntermediateDirectories: true)
            let finalFile = cacheDir.appendingPathComponent("active_wallpaper.jpg")
            try? FileManager.default.removeItem(at: finalFile)

            do {
                try FileManager.default.copyItem(at: localUrl, to: finalFile)
                DispatchQueue.main.async {
                    self.setMacDesktop(fileUrl: finalFile)
                }
            } catch {
                print("File error: \(error.localizedDescription)")
            }
        }
        downloadTask.resume()
    }

    func setMacDesktop(fileUrl: URL) {
        let workspace = NSWorkspace.shared
        for screen in NSScreen.screens {
            do {
                try workspace.setDesktopImageURL(
                    fileUrl,
                    for: screen,
                    options: [
                        .imageScaling: NSImageScaling.scaleProportionallyUpOrDown.rawValue,
                        .allowClipping: true
                    ]
                )
                print("✓ Successfully updated Mac desktop wallpaper on: \(screen.localizedName)")
            } catch {
                print("Error setting wallpaper: \(error.localizedDescription)")
            }
        }
    }
}

// Start Mac Background Listener
let sync = WallpaperCloudSync(projectId: "wallpaper-sync-app")
sync.start()
