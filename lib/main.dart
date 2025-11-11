import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/sticker_provider.dart';
import 'screens/home_screen.dart';
import 'screens/splash_screen.dart';

void main() {
  runApp(const StickerShareApp());
}

class StickerShareApp extends StatefulWidget {
  const StickerShareApp({super.key});

  @override
  State<StickerShareApp> createState() => _StickerShareAppState();
}

class _StickerShareAppState extends State<StickerShareApp> {
  bool _showSplash = true;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => StickerProvider(),
      child: MaterialApp(
        title: 'Sticker Share',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
        ),
        home: _showSplash
            ? SplashScreen(
                onComplete: () {
                  setState(() {
                    _showSplash = false;
                  });
                },
              )
            : const HomeScreen(),
      ),
    );
  }
}
