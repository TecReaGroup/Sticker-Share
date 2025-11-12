import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import '../providers/sticker_provider.dart';
import '../models/sticker_model.dart';

class SplashScreen extends StatefulWidget {
  final VoidCallback onComplete;
  
  const SplashScreen({
    super.key,
    required this.onComplete,
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _textController;
  late Animation<double> _fadeAnimation;
  
  @override
  void initState() {
    super.initState();
    
    // Setup text fade animation
    _textController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _textController,
      curve: Curves.easeInOut,
    ));
    
    // Start animation
    _textController.repeat(reverse: true);
    
    // Preload data
    _preloadData();
  }
  
  Future<void> _preloadData() async {
    try {
      final provider = context.read<StickerProvider>();
      
      // Scan and load assets (themes and stickers)
      await provider.scanAndLoadAssets();
      
      // Preload Lottie compositions for faster initial rendering
      await _preloadLottieCompositions(provider.stickers);
      
      // Wait minimum 2 seconds for better UX
      await Future.delayed(const Duration(seconds: 2));
      
      if (mounted) {
        widget.onComplete();
      }
    } catch (e) {
      debugPrint('Error preloading data: $e');
      // Still navigate even if error
      if (mounted) {
        widget.onComplete();
      }
    }
  }
  
  /// Preload Lottie compositions to cache them for instant display
  Future<void> _preloadLottieCompositions(List<StickerModel> stickers) async {
    if (stickers.isEmpty) return;
    
    try {
      debugPrint('Preloading ${stickers.length} Lottie compositions...');
      
      // Preload compositions in batches to avoid overwhelming the system
      const batchSize = 10;
      int loadedCount = 0;
      
      for (int i = 0; i < stickers.length; i += batchSize) {
        final batch = stickers.skip(i).take(batchSize).toList();
        
        // Load batch concurrently
        await Future.wait(
          batch.map((sticker) async {
            try {
              // Load and cache the composition
              await AssetLottie(sticker.localPath).load();
              loadedCount++;
            } catch (e) {
              debugPrint('Failed to preload ${sticker.localPath}: $e');
            }
          }),
        );
        
        debugPrint('Preloaded $loadedCount/${stickers.length} compositions');
      }
      
      debugPrint('Lottie preloading complete!');
    } catch (e) {
      debugPrint('Error preloading Lottie compositions: $e');
      // Don't throw - we can still proceed without preloading
    }
  }
  
  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Lottie animation
              Expanded(
                flex: 3,
                child: Center(
                  child: Lottie.asset(
                    'assets/animations/launch.json',
                    width: MediaQuery.of(context).size.width * 0.7,
                    height: MediaQuery.of(context).size.width * 0.7,
                    fit: BoxFit.contain,
                    repeat: true,
                    animate: true,
                  ),
                ),
              ),
              
              // Loading text with animation
              Expanded(
                flex: 1,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: Column(
                        children: [
                          Text(
                            'Loading',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w600,
                              color: Colors.blue[700],
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: 120,
                            child: LinearProgressIndicator(
                              backgroundColor: Colors.blue[100],
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.blue[400]!,
                              ),
                              minHeight: 3,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
