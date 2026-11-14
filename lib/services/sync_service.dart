import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:wallpaper_sync/models/device_model.dart';
import 'package:wallpaper_sync/models/wallpaper_model.dart';
import 'package:wallpaper_sync/services/wallpaper_service.dart';

class SyncService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  String? _deviceId;
  String? _deviceName;
  String? _platformName;
  String? _currentWallpaperUrl;
  bool _isAutoApplyEnabled = true;
  StreamSubscription? _wallpaperSubscription;

  String? get deviceId => _deviceId;
  String? get deviceName => _deviceName;
  String? get platformName => _platformName;
  String? get currentWallpaperUrl => _currentWallpaperUrl;
  bool get isAutoApplyEnabled => _isAutoApplyEnabled;

  void setAutoApply(bool enabled) {
    _isAutoApplyEnabled = enabled;
    notifyListeners();
  }

  /// Initialize device identity and register device with cloud backend
  Future<void> initialize(String userId) async {
    await _detectDeviceInfo();
    await _registerDevice(userId);
    _listenToActiveWallpaperChanges(userId);
  }

  Future<void> _detectDeviceInfo() async {
    final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    if (kIsWeb) {
      _platformName = 'web';
      _deviceName = 'Web Browser';
      _deviceId = 'web_${DateTime.now().millisecondsSinceEpoch}';
    } else if (Platform.isMacOS) {
      _platformName = 'macos';
      final macInfo = await deviceInfo.macOsInfo;
      _deviceName = macInfo.computerName;
      _deviceId = macInfo.systemGUID ?? 'mac_${macInfo.model}';
    } else if (Platform.isAndroid) {
      _platformName = 'android';
      final androidInfo = await deviceInfo.androidInfo;
      _deviceName = '${androidInfo.brand} ${androidInfo.model}';
      _deviceId = androidInfo.id;
    } else if (Platform.isIOS) {
      _platformName = 'ios';
      final iosInfo = await deviceInfo.iosInfo;
      _deviceName = iosInfo.name;
      _deviceId = iosInfo.identifierForVendor ?? 'ios_${iosInfo.model}';
    }
  }

  Future<void> _registerDevice(String userId) async {
    String fcmToken = '';
    try {
      // Notification permissions for push sync
      NotificationSettings settings = await _fcm.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        fcmToken = await _fcm.getToken() ?? '';
      }
    } catch (e) {
      debugPrint('FCM Token error: $e');
    }

    final deviceRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('devices')
        .doc(_deviceId);

    await deviceRef.set({
      'deviceName': _deviceName,
      'platform': _platformName,
      'fcmToken': fcmToken,
      'lastActive': FieldValue.serverTimestamp(),
      'autoApply': _isAutoApplyEnabled,
    }, SetOptions(merge: true));
  }

  /// Subscribes to changes in the active wallpaper document in Firestore
  void _listenToActiveWallpaperChanges(String userId) {
    _wallpaperSubscription?.cancel();
    _wallpaperSubscription = _firestore
        .collection('users')
        .doc(userId)
        .collection('active_state')
        .doc('current')
        .snapshots()
        .listen((snapshot) async {
      if (!snapshot.exists || snapshot.data() == null) return;

      final data = snapshot.data()!;
      final newUrl = data['url'] as String?;
      final sourceDeviceId = data['sourceDeviceId'] as String?;
      final title = data['title'] as String? ?? 'Cloud Wallpaper';

      if (newUrl == null || newUrl.isEmpty) return;
      if (newUrl == _currentWallpaperUrl) return;

      _currentWallpaperUrl = newUrl;
      notifyListeners();

      // If change came from ANOTHER device, automatically change this device's wallpaper!
      if (sourceDeviceId != _deviceId && _isAutoApplyEnabled) {
        debugPrint('New wallpaper received from another device ($sourceDeviceId). Auto-applying...');
        await WallpaperService.downloadAndApplyWallpaper(newUrl, title: title);
      }
    });
  }

  /// Update the wallpaper across all devices
  Future<void> publishWallpaper({
    required File imageFile,
    required String title,
    required String userId,
  }) async {
    try {
      // 1. Upload to Firebase Storage
      final String filename = '${DateTime.now().millisecondsSinceEpoch}_${title.replaceAll(' ', '_')}.jpg';
      final ref = _storage.ref().child('users/$userId/wallpapers/$filename');
      final uploadTask = await ref.putFile(imageFile);
      final String downloadUrl = await uploadTask.ref.getDownloadURL();

      // 2. Add to wallpaper collection
      final newDoc = _firestore
          .collection('users')
          .doc(userId)
          .collection('wallpapers')
          .doc();

      await newDoc.set({
        'url': downloadUrl,
        'title': title,
        'uploadedBy': userId,
        'sourceDevice': _deviceName ?? 'Unknown',
        'sourceDeviceId': _deviceId,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 3. Update the active wallpaper state (Triggers cross-device sync!)
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('active_state')
          .doc('current')
          .set({
        'wallpaperId': newDoc.id,
        'url': downloadUrl,
        'title': title,
        'sourceDevice': _deviceName,
        'sourceDeviceId': _deviceId,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // 4. Also immediately apply on this local device
      await WallpaperService.setWallpaperFromFile(imageFile.path);
      _currentWallpaperUrl = downloadUrl;
      notifyListeners();
    } catch (e) {
      debugPrint('Error publishing wallpaper: $e');
      rethrow;
    }
  }

  /// Switch to an existing wallpaper from gallery
  Future<void> setActiveWallpaper({
    required WallpaperModel wallpaper,
    required String userId,
  }) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('active_state')
          .doc('current')
          .set({
        'wallpaperId': wallpaper.id,
        'url': wallpaper.url,
        'title': wallpaper.title,
        'sourceDevice': _deviceName,
        'sourceDeviceId': _deviceId,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Apply locally
      await WallpaperService.downloadAndApplyWallpaper(
        wallpaper.url,
        title: wallpaper.title,
      );
      _currentWallpaperUrl = wallpaper.url;
      notifyListeners();
    } catch (e) {
      debugPrint('Error setting active wallpaper: $e');
      rethrow;
    }
  }

  @override
  void dispose() {
    _wallpaperSubscription?.cancel();
    super.dispose();
  }
}
