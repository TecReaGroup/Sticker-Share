import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/sticker_provider.dart';
import 'screens/home_screen.dart';
import 'screens/splash_screen.dart';

void main() {
  // Ensure Flutter binding is initialized
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const StickerShareApp());
}

class StickerShareApp extends StatelessWidget {
  const StickerShareApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sticker Share',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const SplashWrapper(),
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
  StickerProvider? _provider;

  @override
  void initState() {
    super.initState();
    // Create provider lazily, only when needed
    _provider = StickerProvider();
  }

  @override
  Widget build(BuildContext context) {
    if (_showSplash) {
      return ChangeNotifierProvider.value(
        value: _provider!,
        child: SplashScreen(
          onComplete: () {
            if (mounted) {
              setState(() {
                _showSplash = false;
              });
            }
          },
        ),
      );
    }

    return ChangeNotifierProvider.value(
      value: _provider!,
      child: const HomeScreen(),
    );
  }

  @override
  void dispose() {
    _provider?.dispose();
    super.dispose();
  }
}
