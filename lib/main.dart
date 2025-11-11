import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/emoji_provider.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const StickerShareApp());
}

class StickerShareApp extends StatelessWidget {
  const StickerShareApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => EmojiProvider(),
      child: MaterialApp(
        title: '表情包管理',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
        ),
        home: const HomeScreen(),
      ),
    );
  }
}
