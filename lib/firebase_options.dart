import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
/// Generated for project: wallpaper-sync-app
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDWV5I2zpJs6pocOS821557RGGgPxfkqaY',
    appId: '1:793432872703:web:d2518ddfc9390c5c365eca',
    messagingSenderId: '793432872703',
    projectId: 'wallpaper-sync-app',
    storageBucket: 'wallpaper-sync-app.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDWV5I2zpJs6pocOS821557RGGgPxfkqaY',
    appId: '1:793432872703:android:d2518ddfc9390c5c365eca',
    messagingSenderId: '793432872703',
    projectId: 'wallpaper-sync-app',
    storageBucket: 'wallpaper-sync-app.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDWV5I2zpJs6pocOS821557RGGgPxfkqaY',
    appId: '1:793432872703:ios:d2518ddfc9390c5c365eca',
    messagingSenderId: '793432872703',
    projectId: 'wallpaper-sync-app',
    storageBucket: 'wallpaper-sync-app.firebasestorage.app',
    iosBundleId: 'com.wallpapersync.app',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyDWV5I2zpJs6pocOS821557RGGgPxfkqaY',
    appId: '1:793432872703:ios:d2518ddfc9390c5c365eca',
    messagingSenderId: '793432872703',
    projectId: 'wallpaper-sync-app',
    storageBucket: 'wallpaper-sync-app.firebasestorage.app',
    iosBundleId: 'com.wallpapersync.app',
  );
}
