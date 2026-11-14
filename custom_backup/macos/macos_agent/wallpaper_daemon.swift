import Foundation
import AppKit

struct WallpaperSyncMacOS {
    static func setWallpaper(from url: URL) -> Bool {
        let workspace = NSWorkspace.shared
        var success = true

        for (index, screen) in NSScreen.screens.enumerated() {
            do {
                try workspace.setDesktopImageURL(
                    url,
                    for: screen,
                    options: [
                        .imageScaling: NSImageScaling.scaleProportionallyUpOrDown.rawValue,
                        .allowClipping: true
                    ]
                )
                print("✓ Successfully updated wallpaper on Display \(index + 1) (\(screen.localizedName))")
            } catch {
                print("✗ Failed to update Display \(index + 1): \(error.localizedDescription)")
                success = false
            }
        }
        return success
    }

    static func downloadAndSetWallpaper(from remoteURLString: String) {
        guard let remoteURL = URL(string: remoteURLString) else {
            print("Invalid URL: \(remoteURLString)")
            exit(1)
        }

        print("Downloading wallpaper from: \(remoteURLString)...")
        let semaphore = DispatchSemaphore(value: 0)

        let task = URLSession.shared.downloadTask(with: remoteURL) { localTempURL, response, error in
            defer { semaphore.signal() }
            if let error = error {
                print("Download error: \(error.localizedDescription)")
                return
            }

            guard let localTempURL = localTempURL else {
                print("No file downloaded.")
                return
            }

            let fileManager = FileManager.default
            let homeDir = fileManager.homeDirectoryForCurrentUser
            let destDir = homeDir.appendingPathComponent("Pictures/WallpaperSync")
            try? fileManager.createDirectory(at: destDir, withIntermediateDirectories: true)

            let destURL = destDir.appendingPathComponent("current_wallpaper.jpg")
            try? fileManager.removeItem(at: destURL)

            do {
                try fileManager.copyItem(at: localTempURL, to: destURL)
                print("Saved wallpaper to: \(destURL.path)")
                _ = setWallpaper(from: destURL)
            } catch {
                print("File error: \(error.localizedDescription)")
            }
        }
        task.resume()
        semaphore.wait()
    }
}

// CLI Argument Handling
let args = CommandLine.arguments
if args.count < 2 {
    print("""
    WallpaperSync macOS Native CLI
    Usage:
      wallpaper_sync_mac <file_path_or_url>
      
    Examples:
      wallpaper_sync_mac /path/to/my_wallpaper.jpg
      wallpaper_sync_mac https://images.unsplash.com/photo-1506744038136-46273834b3fb
    """)
    exit(0)
}

let target = args[1]
if target.hasPrefix("http://") || target.hasPrefix("https://") {
    WallpaperSyncMacOS.downloadAndSetWallpaper(from: target)
} else {
    let localURL = URL(fileURLWithPath: target)
    if FileManager.default.fileExists(atPath: localURL.path) {
        _ = WallpaperSyncMacOS.setWallpaper(from: localURL)
    } else {
        print("File does not exist: \(target)")
        exit(1)
    }
}
