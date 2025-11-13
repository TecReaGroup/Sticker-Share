import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../providers/sticker_provider.dart';

class SplashScreen extends StatefulWidget {
  final VoidCallback onComplete;

  const SplashScreen({super.key, required this.onComplete});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // Setup fade-in animation for splash screen
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );

    // Start fade-in animation
    _fadeController.forward();

    // Use addPostFrameCallback to ensure first frame renders before loading
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    try {
      // Ensure context is still valid
      if (!mounted) return;

      final provider = context.read<StickerProvider>();

      // Scan and load assets (sticker packs and stickers metadata only)
      await provider.scanAndLoadAssets();

      // Wait minimum 1.5 seconds for better UX
      await Future.delayed(const Duration(milliseconds: 1500));

      if (mounted) {
        widget.onComplete();
        // Start background loading after navigation
        provider.startBackgroundLoading();
      }
    } catch (e) {
      debugPrint('Error loading data: $e');
      // Still navigate even if error
      if (mounted) {
        widget.onComplete();
      }
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                // SVG Icon with fade-in effect
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 60.0),
                    child: Center(
                      child: SvgPicture.asset(
                        'assets/icon/icon.svg',
                        width: MediaQuery.of(context).size.width * 0.5,
                        height: MediaQuery.of(context).size.width * 0.5,
                        fit: BoxFit.contain,
                        placeholderBuilder: (context) =>
                            const CircularProgressIndicator(),
                      ),
                    ),
                  ),
                ),

                // Loading text with fade-in effect
                Expanded(
                  flex: 1,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
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
                      const SizedBox(height: 36),
                      Text(
                        'Tips: Long press the stickerPack to like',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                          fontStyle: FontStyle.italic,
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
      ),
    );
  }
}
