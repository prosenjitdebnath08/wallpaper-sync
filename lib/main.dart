import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wallpaper_sync/firebase_options.dart';
import 'package:wallpaper_sync/screens/home_screen.dart';
import 'package:wallpaper_sync/screens/login_screen.dart';
import 'package:wallpaper_sync/services/auth_service.dart';
import 'package:wallpaper_sync/services/sync_service.dart';
import 'package:wallpaper_sync/services/wallpaper_service.dart';

// Top-level FCM background handler for Android/iOS silent data pushes
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  debugPrint('Handling background FCM message: ${message.data}');

  if (message.data['action'] == 'SET_WALLPAPER') {
    final String? imageUrl = message.data['url'];
    final String? title = message.data['title'];
    if (imageUrl != null && imageUrl.isNotEmpty) {
      debugPrint('Background sync triggered! Downloading and setting wallpaper...');
      await WallpaperService.downloadAndApplyWallpaper(imageUrl, title: title);
    }
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase with unified cross-platform options
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  } catch (e) {
    debugPrint('Firebase initialization notice: $e');
  }

  runApp(const WallpaperSyncApp());
}

class WallpaperSyncApp extends StatelessWidget {
  const WallpaperSyncApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => SyncService()),
      ],
      child: MaterialApp(
        title: 'Wallpaper Sync',
        debugShowCheckedModeBanner: false,
        themeMode: ThemeMode.dark,
        darkTheme: ThemeData(
          brightness: Brightness.dark,
          scaffoldBackgroundColor: const Color(0xFF121212),
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.deepPurple,
            brightness: Brightness.dark,
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF1A1A1A),
            elevation: 0,
          ),
          useMaterial3: true,
        ),
        home: const AuthGate(),
      ),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);

    return StreamBuilder(
      stream: auth.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasData && snapshot.data != null) {
          // Initialize sync service for logged in user
          final userId = snapshot.data!.uid;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Provider.of<SyncService>(context, listen: false).initialize(userId);
          });
          return const HomeScreen();
        }

        return const LoginScreen();
      },
    );
  }
}
