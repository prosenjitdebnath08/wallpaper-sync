import Foundation
import AppKit

class UniversalWallpaperSync {
    let projectId = "wallpaper-sync-app"
    var userEmail: String = ""
    var targetFolder: String = ""
    var lastCloudUrl: String = ""
    var lastAppliedPath: String = ""

    init() {
        let home = FileManager.default.homeDirectoryForCurrentUser.path

        // 1. Try to auto-detect Google Drive account and folder
        if let gdrive = UniversalWallpaperSync.detectGoogleDrive() {
            self.userEmail = gdrive.email
            self.targetFolder = gdrive.folder
            print("✓ Detected Google Drive account: \(self.userEmail)")
            print("✓ Wallpaper sync folder: \(self.targetFolder)")
        } else {
            // Check for saved email in ~/.wallpapersync/email.txt
            let emailFile = "\(home)/.wallpapersync/email.txt"
            if let saved = try? String(contentsOfFile: emailFile, encoding: .utf8) {
                self.userEmail = saved.trimmingCharacters(in: .whitespacesAndNewlines)
            }
            self.targetFolder = "\(home)/Pictures/WallpaperSync"
            print("Notice: Google Drive folder not detected. Using: \(self.targetFolder)")
        }

        // Ensure target folder exists
        try? FileManager.default.createDirectory(atPath: self.targetFolder, withIntermediateDirectories: true)
    }

    static func detectGoogleDrive() -> (email: String, folder: String)? {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        let cloudStoragePath = "\(home)/Library/CloudStorage"
        guard let items = try? FileManager.default.contentsOfDirectory(atPath: cloudStoragePath) else {
            return nil
        }
        for item in items where item.hasPrefix("GoogleDrive-") {
            let email = item.replacingOccurrences(of: "GoogleDrive-", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
            let folder = "\(cloudStoragePath)/\(item)/My Drive/Wallpaper"
            return (email, folder)
        }
        return nil
    }

    func start() {
        print("=========================================================")
        print("  Wallpaper Sync - Universal Mac Daemon Active")
        print("  User: \(userEmail.isEmpty ? "All (Shared)" : userEmail)")
        print("=========================================================")
        fflush(stdout)

        // Check immediately
        checkCloud()
        checkLocalFolder()

        // Poll every 2 seconds
        Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            self?.checkCloud()
            self?.checkLocalFolder()
        }
        RunLoop.current.run()
    }

    func checkCloud() {
        // Prefer private user document if email is detected
        var endpoint = ""
        if !userEmail.isEmpty {
            let emailKey = userEmail.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
            endpoint = "https://firestore.googleapis.com/v1/projects/\(projectId)/databases/(default)/documents/users_sync/\(emailKey)"
        } else {
            endpoint = "https://firestore.googleapis.com/v1/projects/\(projectId)/databases/(default)/documents/sync/current"
        }

        guard let url = URL(string: endpoint) else { return }

        let task = URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard let self = self, let data = data, error == nil else { return }

            guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let fields = json["fields"] as? [String: Any],
                  let urlField = fields["url"] as? [String: Any],
                  let rawUrl = urlField["stringValue"] as? String,
                  !rawUrl.isEmpty else {
                // If user-specific document not found, try fallback global sync
                if !self.userEmail.isEmpty {
                    self.checkFallbackCloud()
                }
                return
            }

            if rawUrl != self.lastCloudUrl {
                self.lastCloudUrl = rawUrl
                print("🌟 New wallpaper from phone received: \(rawUrl)")
                fflush(stdout)
                self.resolveAndApply(rawUrl: rawUrl)
            }
        }
        task.resume()
    }

    func checkFallbackCloud() {
        let endpoint = "https://firestore.googleapis.com/v1/projects/\(projectId)/databases/(default)/documents/sync/current"
        guard let url = URL(string: endpoint) else { return }

        let task = URLSession.shared.dataTask(with: url) { [weak self] data, _, error in
            guard let self = self, let data = data, error == nil else { return }
            guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let fields = json["fields"] as? [String: Any],
                  let urlField = fields["url"] as? [String: Any],
                  let rawUrl = urlField["stringValue"] as? String,
                  !rawUrl.isEmpty else { return }

            if rawUrl != self.lastCloudUrl {
                self.lastCloudUrl = rawUrl
                print("🌟 New wallpaper received from cloud fallback: \(rawUrl)")
                fflush(stdout)
                self.resolveAndApply(rawUrl: rawUrl)
            }
        }
        task.resume()
    }

    func resolveAndApply(rawUrl: String) {
        if rawUrl.contains("tmpfiles.org") {
            let pageUrlString = rawUrl.replacingOccurrences(of: "tmpfiles.org/dl/", with: "tmpfiles.org/")
            guard let pageUrl = URL(string: pageUrlString) else {
                self.downloadAndSet(urlString: rawUrl)
                return
            }
            let task = URLSession.shared.dataTask(with: pageUrl) { [weak self] data, _, _ in
                guard let self = self else { return }
                if let data = data, let html = String(data: data, encoding: .utf8) {
                    if let range = html.range(of: "https://tmpfiles.org/dl/[^\"]+", options: .regularExpression) {
                        let directUrl = String(html[range])
                        print("Direct image URL resolved: \(directUrl)")
                        fflush(stdout)
                        self.downloadAndSet(urlString: directUrl)
                        return
                    }
                }
                self.downloadAndSet(urlString: rawUrl)
            }
            task.resume()
        } else {
            self.downloadAndSet(urlString: rawUrl)
        }
    }

    func downloadAndSet(urlString: String) {
        guard let url = URL(string: urlString) else { return }
        let task = URLSession.shared.downloadTask(with: url) { [weak self] tempUrl, _, error in
            guard let self = self, let tempUrl = tempUrl, error == nil else { return }

            let timestamp = Int(Date().timeIntervalSince1970)
            let dest = URL(fileURLWithPath: self.targetFolder).appendingPathComponent("phone_sync_\(timestamp).jpg")

            try? FileManager.default.removeItem(at: dest)
            do {
                try FileManager.default.copyItem(at: tempUrl, to: dest)
                DispatchQueue.main.async {
                    self.applyWallpaper(fileURL: dest)
                }
            } catch {
                print("Error copying wallpaper: \(error)")
                fflush(stdout)
            }
        }
        task.resume()
    }

    func checkLocalFolder() {
        let folderURL = URL(fileURLWithPath: targetFolder)
        guard let files = try? FileManager.default.contentsOfDirectory(
            at: folderURL,
            includingPropertiesForKeys: [.contentModificationDateKey],
            options: [.skipsHiddenFiles]
        ) else { return }

        let exts = ["jpg", "jpeg", "png", "heic", "webp"]
        let images = files.filter { exts.contains($0.pathExtension.lowercased()) }
        guard let newest = images.sorted(by: {
            let d1 = (try? $0.resourceValues(forKeys: [.contentModificationDateKey]))?.contentModificationDate ?? Date.distantPast
            let d2 = (try? $1.resourceValues(forKeys: [.contentModificationDateKey]))?.contentModificationDate ?? Date.distantPast
            return d1 > d2
        }).first else { return }

        if newest.path != lastAppliedPath {
            lastAppliedPath = newest.path
            DispatchQueue.main.async {
                self.applyWallpaper(fileURL: newest)
            }
        }
    }

    func applyWallpaper(fileURL: URL) {
        let workspace = NSWorkspace.shared
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
                self.lastAppliedPath = fileURL.path
                print("✓ Successfully updated Mac wallpaper: \(fileURL.lastPathComponent)")
                fflush(stdout)
            } catch {
                print("Error setting wallpaper: \(error)")
                fflush(stdout)
            }
        }
    }
}

let sync = UniversalWallpaperSync()
sync.start()
