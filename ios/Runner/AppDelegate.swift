import UIKit
import Flutter

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
    let wallpaperChannel = FlutterMethodChannel(
      name: "com.wallpapersync.app/wallpaper",
      binaryMessenger: controller.binaryMessenger
    )

    wallpaperChannel.setMethodCallHandler { (call: FlutterMethodCall, result: @escaping FlutterResult) in
      if call.method == "saveToSharedContainer" {
        guard let args = call.arguments as? [String: Any],
              let flutterData = args["bytes"] as? FlutterStandardTypedData,
              let filename = args["filename"] as? String else {
          result(FlutterError(code: "INVALID_ARGS", message: "Bytes and filename required", details: nil))
          return
        }

        // Shared App Group Container allows iOS Shortcuts to read the image directly
        let fileManager = FileManager.default
        let appGroupId = "group.com.wallpapersync.app"
        guard let groupURL = fileManager.containerURL(forSecurityApplicationGroupIdentifier: appGroupId) else {
          // Fallback to Documents directory if App Group not configured
          let docURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
          let fileURL = docURL.appendingPathComponent(filename)
          do {
            try flutterData.data.write(to: fileURL)
            result(fileURL.path)
          } catch {
            result(FlutterError(code: "WRITE_ERROR", message: error.localizedDescription, details: nil))
          }
          return
        }

        let destinationURL = groupURL.appendingPathComponent(filename)
        do {
          try flutterData.data.write(to: destinationURL)
          print("Saved synced wallpaper to App Group: \(destinationURL.path)")
          result(destinationURL.path)
        } catch {
          result(FlutterError(code: "WRITE_ERROR", message: error.localizedDescription, details: nil))
        }
      } else {
        result(FlutterMethodNotImplemented)
      }
    }

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
