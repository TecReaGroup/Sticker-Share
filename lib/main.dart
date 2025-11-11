import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/sticker_provider.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const StickerShareApp());
}

class StickerShareApp extends StatelessWidget {
  const StickerShareApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) {
        final provider = StickerProvider();
        provider.initialize();
        return provider;
      },
      child: MaterialApp(
        title: 'Sticker Manager',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
        ),
        home: const HomeScreen(),
      ),
    );
  }
}
