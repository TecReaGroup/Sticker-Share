import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lottie/lottie.dart';
import '../providers/sticker_provider.dart';
import '../models/sticker_model.dart';
import '../services/wechat_share_service.dart';
import 'package:flutter/services.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _isScrolling = false;
  Timer? _scrollEndTimer;

  @override
  void initState() {
    super.initState();
    
    _scrollController.addListener(_onScroll);
    
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = context.read<StickerProvider>();
      while (provider.isLoading) {
        await Future.delayed(const Duration(milliseconds: 50));
      }
      await provider.scanAndLoadAssets();
    });
  }

  void _onScroll() {
    _scrollEndTimer?.cancel();
    
    if (!_isScrolling) {
      setState(() => _isScrolling = true);
    }
    
    _scrollEndTimer = Timer(const Duration(milliseconds: 100), () {
      if (mounted) {
        setState(() => _isScrolling = false);
      }
    });
  }

  @override
  void dispose() {
    _scrollEndTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sticker Management'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: _ThemeSelector(),
        ),
        actions: [
          Consumer<StickerProvider>(
            builder: (context, provider, child) {
              return IconButton(
                icon: Icon(
                  provider.showFavoritesOnly 
                      ? Icons.favorite 
                      : Icons.favorite_border,
                ),
                onPressed: () {
                  provider.toggleFavoritesFilter();
                },
                tooltip: provider.showFavoritesOnly
                    ? 'Show All'
                    : 'Favorites Only',
              );
            },
          ),
        ],
      ),
      body: Consumer<StickerProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(provider.error!),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      provider.clearError();
                      provider.initialize();
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final stickers = provider.filteredStickers;

          if (stickers.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.sentiment_dissatisfied,
                      size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    provider.showFavoritesOnly
                        ? 'No favorite themes'
                        : 'No stickers',
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
            );
          }

          return GridView.builder(
            controller: _scrollController,
            key: ValueKey('grid_${provider.selectedThemeId}_${provider.showFavoritesOnly}'),
            padding: const EdgeInsets.all(8),
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 1,
            ),
            itemCount: stickers.length,
            itemBuilder: (context, index) {
              final sticker = stickers[index];
              return _StickerCard(
                sticker: sticker,
                isScrolling: _isScrolling,
              );
            },
          );
        },
      ),
    );
  }
}

class _ThemeSelector extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<StickerProvider>(
      builder: (context, provider, child) {
        final themes = provider.showFavoritesOnly 
            ? provider.favoriteThemes 
            : provider.themes;

        if (themes.isEmpty) {
          return const SizedBox(height: 60);
        }

        return Container(
          height: 60,
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            itemCount: themes.length,
            itemBuilder: (context, index) {
              final theme = themes[index];
              final isSelected = provider.selectedThemeId == theme.id;
              
              return GestureDetector(
                onTap: () {
                  // Only allow switching to a different theme
                  provider.selectTheme(theme.id);
                },
                onLongPress: () {
                  provider.toggleThemeFavorite(theme.id);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        theme.isFavorite ? 'Theme unfavorited' : 'Theme favorited',
                      ),
                      duration: const Duration(seconds: 1),
                    ),
                  );
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected 
                        ? Colors.white 
                        : Colors.white.withAlpha(70),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected ? Colors.white : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (theme.isFavorite)
                        const Padding(
                          padding: EdgeInsets.only(right: 4),
                          child: Icon(
                            Icons.favorite,
                            size: 16,
                            color: Colors.red,
                          ),
                        ),
                      Text(
                        theme.name,
                        style: TextStyle(
                          color: isSelected 
                              ? Colors.blue 
                              : Colors.white,
                          fontWeight: isSelected 
                              ? FontWeight.bold 
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _StickerCard extends StatefulWidget {
  final StickerModel sticker;
  final bool isScrolling;

  const _StickerCard({
    required this.sticker,
    required this.isScrolling,
  });

  @override
  State<_StickerCard> createState() => _StickerCardState();
}

class _StickerCardState extends State<_StickerCard> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showShareDialog(context, widget.sticker),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Lottie.asset(
            widget.sticker.localPath,
            fit: BoxFit.cover,
            repeat: true,
            animate: !widget.isScrolling,
            frameRate: FrameRate(60),
            renderCache: RenderCache.raster,
            errorBuilder: (context, error, stackTrace) {
              debugPrint('Lottie error for ${widget.sticker.localPath}: $error');
              return Container(
                color: Colors.grey[300],
                child: const Center(
                  child: Icon(Icons.error_outline, color: Colors.grey, size: 48),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  void _showShareDialog(BuildContext context, StickerModel sticker) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.wechat, color: Colors.green, size: 32),
              title: const Text('Share to WeChat'),
              subtitle: const Text('Preserve GIF animation'),
              onTap: () async {
                Navigator.pop(context);
                await _shareToWeChat(context, sticker);
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.share, color: Colors.blue, size: 32),
              title: const Text('Share to other apps'),
              onTap: () {
                Navigator.pop(context);
                _showComingSoon(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _shareToWeChat(BuildContext context, StickerModel sticker) async {
    try {
      // Check if WeChat is installed
      final isInstalled = await WeChatShareService.isWeChatInstalled();
      if (!isInstalled) {
        if (context.mounted) {
          _showError(context, 'WeChat not installed');
        }
        return;
      }

      // Show loading dialog
      if (context.mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: CircularProgressIndicator(),
          ),
        );
      }

      // Read GIF file for WeChat sharing
      final ByteData data = await rootBundle.load(sticker.gifPath);
      final Uint8List gifData = data.buffer.asUint8List();

      // Close loading dialog
      if (context.mounted) {
        Navigator.pop(context);
      }

      // Share to WeChat (replace with real AppID)
      final success = await WeChatShareService.shareGifToWeChat(
        gifData: gifData,
        appId: 'YOUR_WECHAT_APPID',
      );

      if (context.mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Opening WeChat...')),
          );
        } else {
          _showError(context, 'Share failed, please retry');
        }
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        _showError(context, 'Share failed: $e');
      }
    }
  }

  void _showError(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Coming soon')),
    );
  }
}