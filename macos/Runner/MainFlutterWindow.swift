import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    RegisterGeneratedPlugins(registry: flutterViewController)

    // Register custom wallpaper method channel
    let wallpaperChannel = FlutterMethodChannel(
      name: "com.wallpapersync.app/wallpaper",
      binaryMessenger: flutterViewController.engine.binaryMessenger
    )

    wallpaperChannel.setMethodCallHandler { (call: FlutterMethodCall, result: @escaping FlutterResult) in
      if call.method == "setWallpaper" {
        guard let args = call.arguments as? [String: Any],
              let filePath = args["filePath"] as? String else {
          result(FlutterError(code: "INVALID_ARGS", message: "filePath is required", details: nil))
          return
        }

        let fileURL = URL(fileURLWithPath: filePath)
        let success = MacOSWallpaperManager.setDesktopWallpaper(fileURL: fileURL)
        result(success)
      } else {
        result(FlutterMethodNotImplemented)
      }
    }

    super.awakeFromNib()
  }
}

class MacOSWallpaperManager {
  static func setDesktopWallpaper(fileURL: URL) -> Bool {
    let workspace = NSWorkspace.shared
    var allSuccessful = true

    // Iterate through all connected displays / monitors
    for screen in NSScreen.screens {
      do {
        // Set wallpaper for this screen
        try workspace.setDesktopImageURL(
          fileURL,
          for: screen,
          options: [
            .imageScaling: NSImageScaling.scaleProportionallyUpOrDown.rawValue,
            .allowClipping: true
          ]
        )
        print("Successfully set wallpaper for screen: \(screen.localizedName)")
      } catch {
        print("Failed to set wallpaper for screen \(screen.localizedName): \(error.localizedDescription)")
        allSuccessful = false
      }
    }
    return allSuccessful
  }
}
