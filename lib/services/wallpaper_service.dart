import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class WallpaperService {
  static const MethodChannel _channel =
      MethodChannel('com.wallpapersync.app/wallpaper');

  /// Applies wallpaper directly using local file path via native platform channels
  static Future<bool> setWallpaperFromFile(
    String filePath, {
    bool setHome = true,
    bool setLock = true,
  }) async {
    try {
      final bool result = await _channel.invokeMethod('setWallpaper', {
        'filePath': filePath,
        'setHome': setHome,
        'setLock': setLock,
      });
      return result;
    } on PlatformException catch (e) {
      debugPrint('Failed to set wallpaper via native channel: ${e.message}');
      return false;
    }
  }

  /// Downloads remote image and automatically applies it as the active wallpaper
  static Future<bool> downloadAndApplyWallpaper(
    String imageUrl, {
    String? title,
    bool setHome = true,
    bool setLock = true,
  }) async {
    try {
      debugPrint('Downloading wallpaper from: $imageUrl');
      final response = await http.get(Uri.parse(imageUrl));
      if (response.statusCode != 200) {
        throw Exception('Failed to download image: HTTP ${response.statusCode}');
      }

      final Directory tempDir = await getTemporaryDirectory();
      final String filename = 'sync_wallpaper_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final File localFile = File('${tempDir.path}/$filename');
      await localFile.writeAsBytes(response.bodyBytes);

      debugPrint('Downloaded to: ${localFile.path}. Calling native setter...');
      final bool success = await setWallpaperFromFile(
        localFile.path,
        setHome: setHome,
        setLock: setLock,
      );

      return success;
    } catch (e) {
      debugPrint('Error in downloadAndApplyWallpaper: $e');
      return false;
    }
  }

  /// For iOS: Prepares image for Apple Shortcuts Automation
  static Future<String?> exportWallpaperForShortcuts(String imageUrl) async {
    if (!Platform.isIOS) return null;
    try {
      final response = await http.get(Uri.parse(imageUrl));
      if (response.statusCode == 200) {
        final resultPath = await _channel.invokeMethod<String>('saveToSharedContainer', {
          'bytes': response.bodyBytes,
          'filename': 'active_wallpaper.png',
        });
        return resultPath;
      }
    } catch (e) {
      debugPrint('Error exporting wallpaper for iOS Shortcuts: $e');
    }
    return null;
  }
}
