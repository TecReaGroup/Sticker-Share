import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'providers/sticker_provider.dart';
import 'screens/home_screen.dart';
import 'screens/splash_screen.dart';

Future<void> main() async {
  // Ensure Flutter binding is initialized
  WidgetsFlutterBinding.ensureInitialized();
  
  // Configure system UI for Android
  if (Platform.isAndroid) {
    final deviceInfo = DeviceInfoPlugin();
    final androidInfo = await deviceInfo.androidInfo;
    final androidSdkInt = androidInfo.version.sdkInt;
    
    // Only use full transparency on Android 10 (API 29) and above
    final bool edgeToEdge = androidSdkInt >= 29;
    
    // Enable edge-to-edge mode
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    
    // Set system UI overlay style
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        // Key: Use transparent only on Android 10+, otherwise use white
        systemNavigationBarColor: edgeToEdge ? Colors.transparent : Colors.white,
        // Critical: Disable forced contrast (fixes Xiaomi devices like Redmi K50)
        systemNavigationBarContrastEnforced: false,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );
  }
  
  runApp(const StickerShareApp());
}

class StickerShareApp extends StatefulWidget {
  const StickerShareApp({super.key});

  @override
  State<StickerShareApp> createState() => _StickerShareAppState();
}

class _StickerShareAppState extends State<StickerShareApp> {
  // Provider created early to avoid white screen
  late final StickerProvider _stickerProvider;

  @override
  void initState() {
    super.initState();
    // Create provider immediately in initState
    _stickerProvider = StickerProvider();
  }

  @override
  void dispose() {
    _stickerProvider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _stickerProvider,
      child: MaterialApp(
        title: 'Sticker Share',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
          scaffoldBackgroundColor: Colors.white,
          // Ensure AppBar uses surface tint mode for Material 3
          appBarTheme: const AppBarTheme(
            systemOverlayStyle: SystemUiOverlayStyle(
              statusBarColor: Colors.transparent,
              statusBarIconBrightness: Brightness.dark,
            ),
          ),
        ),
        home: const SplashWrapper(),
      ),
    );
  }
}

class SplashWrapper extends StatefulWidget {
  const SplashWrapper({super.key});

  @override
  State<SplashWrapper> createState() => _SplashWrapperState();
}

class _SplashWrapperState extends State<SplashWrapper> {
  bool _showSplash = true;

  @override
  Widget build(BuildContext context) {
    if (_showSplash) {
      return SplashScreen(
        onComplete: () {
          if (mounted) {
            setState(() {
              _showSplash = false;
            });
          }
        },
      );
    }

    return const HomeScreen();
  }
}
