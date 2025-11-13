import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lottie/lottie.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../providers/sticker_provider.dart';
import '../models/sticker_model.dart';
import '../services/messaging_share_service.dart';
import 'package:flutter/services.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _isScrolling = false;
  bool _isFingerDown = false; // Track if finger is touching the screen
  Timer? _resumeAnimationTimer; // Timer for delayed animation resume
  
  // Theme swipe state
  double _horizontalDragOffset = 0.0;
  static const double _swipeThreshold = 4.0; // Minimum drag distance to trigger switch

  @override
  void initState() {
    super.initState();
    // Data is already preloaded in splash screen, no need to load again
  }

  bool _handleScrollNotification(ScrollNotification notification) {
    // Only pause animations during ScrollUpdate if finger is still down
    if (notification is ScrollUpdateNotification) {
      if (_isFingerDown && !_isScrolling) {
        setState(() => _isScrolling = true);
      }
    }

    return false;
  }

  @override
  void dispose() {
    _resumeAnimationTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarContrastEnforced: false,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        extendBody: true, // Allow content to extend behind navigation bar
        appBar: AppBar(
        title: const Text('Sticker Management'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: _PackSelector(),
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
                      provider.scanAndLoadAssets();
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final stickers = provider.filteredStickers;
          final packs = provider.showFavoritesOnly
              ? provider.favoriteStickerPacks
              : provider.stickerPacks;

          if (stickers.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 100),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.sentiment_dissatisfied,
                      size: 64,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      provider.showFavoritesOnly
                          ? 'Long press a stickerPack to add favorites'
                          : 'No stickers',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
            );
          }

          return GestureDetector(
            onHorizontalDragStart: (details) {
              setState(() {
                _horizontalDragOffset = 0.0;
              });
            },
            onHorizontalDragUpdate: (details) {
              setState(() {
                final currentIndex = packs.indexWhere((p) => p.id == provider.selectedPackId);
                
                // Completely prevent dragging at boundaries
                if (currentIndex == 0 && details.delta.dx > 0) {
                  // At first pack, don't allow right drag
                  return;
                }
                
                if (currentIndex == packs.length - 1 && details.delta.dx < 0) {
                  // At last pack, don't allow left drag
                  return;
                }
                
                // Add resistance effect (slower movement when dragging)
                _horizontalDragOffset += details.delta.dx * 0.85;
                
                // Normal clamp for middle themes
                _horizontalDragOffset = _horizontalDragOffset.clamp(-150.0, 150.0);
              });
            },
            onHorizontalDragEnd: (details) {
              final currentIndex = packs.indexWhere((p) => p.id == provider.selectedPackId);
              
              // Determine if should switch pack
              if (_horizontalDragOffset.abs() >= _swipeThreshold) {
                if (_horizontalDragOffset > 0 && currentIndex > 0) {
                  // Swipe right - go to previous pack
                  provider.selectStickerPack(packs[currentIndex - 1].id);
                } else if (_horizontalDragOffset < 0 && currentIndex < packs.length - 1) {
                  // Swipe left - go to next pack
                  provider.selectStickerPack(packs[currentIndex + 1].id);
                }
              }
              
              // Reset state
              setState(() {
                _horizontalDragOffset = 0.0;
              });
            },
            child: Stack(
              children: [
                // Main content with transform
                Transform.translate(
                  offset: Offset(_horizontalDragOffset, 0),
                  child: Listener(
                    onPointerDown: (_) {
                      // Finger touches screen - pause animations immediately
                      _resumeAnimationTimer?.cancel();
                      if (!_isFingerDown) {
                        setState(() {
                          _isFingerDown = true;
                          _isScrolling = true;
                        });
                      }
                    },
                    onPointerUp: (_) {
                      // Finger leaves screen - mark finger as up but keep animations paused
                      setState(() {
                        _isFingerDown = false;
                      });

                      // Schedule animation resume after delay (150ms)
                      // This prevents flicker on quick swipes while still being responsive
                      _resumeAnimationTimer?.cancel();
                      _resumeAnimationTimer = Timer(
                        const Duration(milliseconds: 100),
                        () {
                          if (mounted && !_isFingerDown) {
                            setState(() => _isScrolling = false);
                          }
                        },
                      );
                    },
                    child: NotificationListener<ScrollNotification>(
                      onNotification: _handleScrollNotification,
                      child: GridView.builder(
                        controller: _scrollController,
                        key: ValueKey(
                          'grid_${provider.selectedPackId}_${provider.showFavoritesOnly}',
                        ),
                        padding: const EdgeInsets.all(8),
                        physics: const ClampingScrollPhysics(
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
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
      ),
    );
  }
}

class _PackSelector extends StatefulWidget {
  @override
  State<_PackSelector> createState() => _PackSelectorState();
}

class _PackSelectorState extends State<_PackSelector> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToSelectedPack(String? selectedPackId, List packs) {
    if (selectedPackId == null || packs.isEmpty) return;

    final selectedIndex = packs.indexWhere((p) => p.id == selectedPackId);
    if (selectedIndex == -1) return;

    // Use post frame callback to ensure layout is complete
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;

      // Calculate approximate item width (padding + text)
      const itemWidth = 120.0; // Approximate width
      final viewportWidth = _scrollController.position.viewportDimension;
      
      // Calculate target scroll position to center the item
      final targetOffset = (selectedIndex * itemWidth) - (viewportWidth / 2) + (itemWidth / 2);
      
      // Clamp to valid scroll range
      final maxScroll = _scrollController.position.maxScrollExtent;
      final clampedOffset = targetOffset.clamp(0.0, maxScroll);

      _scrollController.animateTo(
        clampedOffset,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<StickerProvider>(
      builder: (context, provider, child) {
        final packs = provider.showFavoritesOnly
            ? provider.favoriteStickerPacks
            : provider.stickerPacks;

        if (packs.isEmpty) {
          return const SizedBox(height: 60);
        }

        // Scroll to selected pack when it changes
        _scrollToSelectedPack(provider.selectedPackId, packs);

        return Container(
          height: 60,
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: ListView.builder(
            controller: _scrollController,
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            itemCount: packs.length,
            itemBuilder: (context, index) {
              final pack = packs[index];
              final isSelected = provider.selectedPackId == pack.id;

              return GestureDetector(
                onTap: () {
                  // Only allow switching to a different pack
                  provider.selectStickerPack(pack.id);
                },
                onLongPress: () {
                  provider.toggleStickerPackFavorite(pack.id);
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
                      if (pack.isFavorite)
                        const Padding(
                          padding: EdgeInsets.only(right: 4),
                          child: Icon(
                            Icons.favorite,
                            size: 16,
                            color: Colors.red,
                          ),
                        ),
                      Text(
                        pack.name,
                        style: TextStyle(
                          color: isSelected ? Colors.blue : Colors.white,
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

  const _StickerCard({required this.sticker, required this.isScrolling});

  @override
  State<_StickerCard> createState() => _StickerCardState();
}

class _StickerCardState extends State<_StickerCard>
    with TickerProviderStateMixin {
  AnimationController? _lottieController;
  late AnimationController _fadeController;
  LottieComposition? _composition;
  bool _isLottieLoaded = false;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    
    // Controller for fade-in transition
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    
    // Load composition asynchronously
    _loadComposition();
  }
  
  Future<void> _loadComposition() async {
    try {
      final composition = await AssetLottie(widget.sticker.localPath).load();
      
      if (mounted && !_isDisposed) {
        // Create controller with composition duration
        _lottieController = AnimationController(
          vsync: this,
          duration: composition.duration,
        );
        
        // Start animation only if not scrolling
        if (!widget.isScrolling) {
          _lottieController!.repeat();
        }
        
        setState(() {
          _composition = composition;
          _isLottieLoaded = true;
        });
        
        // Start fade-in animation
        _fadeController.forward();
      }
    } catch (e) {
      debugPrint('Error loading Lottie: $e');
      if (mounted && !_isDisposed) {
        setState(() => _isLottieLoaded = true);
      }
    }
  }

  @override
  void didUpdateWidget(_StickerCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Handle scroll state changes to pause/resume animation
    if (_lottieController != null &&
        widget.isScrolling != oldWidget.isScrolling) {
      if (widget.isScrolling) {
        _lottieController!.stop();
      } else {
        _lottieController!.repeat();
      }
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _lottieController?.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showShareDialog(context, widget.sticker),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Main Lottie animation with fade-in (no placeholder)
              if (_composition != null && _lottieController != null)
                FadeTransition(
                  opacity: _fadeController,
                  child: Lottie(
                    composition: _composition,
                    controller: _lottieController,
                    fit: BoxFit.cover,
                    frameRate: FrameRate(60),
                  ),
                ),
              
              // Error state
              if (_isLottieLoaded && _composition == null)
                Container(
                  color: Colors.grey[300],
                  child: const Center(
                    child: Icon(
                      Icons.error_outline,
                      color: Colors.grey,
                      size: 48,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showShareDialog(BuildContext context, StickerModel sticker) async {
    // Get installed apps
    debugPrint('=== Share Dialog Debug START ===');
    final installedApps = await MessagingShareService.getInstalledApps();
    debugPrint('Detected ${installedApps.length} messaging apps');
    for (var app in installedApps) {
      debugPrint('  - ${app.displayName} (${app.packageName})');
    }
    debugPrint('=== Share Dialog Debug END ===');
    
    if (!context.mounted) return;
    
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (BuildContext modalContext) {
        debugPrint('>>> Building bottom sheet with ${installedApps.length} apps');
        final widgets = <Widget>[];
        
        // Build widgets for each installed app
        for (var app in installedApps) {
          debugPrint('>>> Creating ListTile for ${app.displayName}');
          widgets.add(
            ListTile(
              leading: Icon(_getAppIcon(app), color: _getAppColor(app), size: 32),
              title: Text('Share to ${app.displayName}'),
              subtitle: const Text('Preserve GIF animation'),
              onTap: () async {
                Navigator.pop(modalContext);
                await _shareToApp(context, sticker, app);
              },
            ),
          );
        }
        
        // Add divider if there are installed apps
        if (installedApps.isNotEmpty) {
          widgets.add(const Divider());
        }
        
        // Add generic share option
        widgets.add(
          ListTile(
            leading: const Icon(Icons.share, color: Colors.blue, size: 32),
            title: const Text('Share to other apps'),
            onTap: () async {
              Navigator.pop(modalContext);
              await _shareGeneric(context, sticker);
            },
          ),
        );
        
        debugPrint('>>> Total widgets created: ${widgets.length}');
        
        // Calculate initial size to show N complete items + 0.5 of last item
        final screenHeight = MediaQuery.of(context).size.height;
        const double listTileHeight = 72.0;
        const double topPadding = 16.0;
        const double targetVisibleItems = 5.5; // 3 complete + 0.5 partial
        final targetHeight = topPadding + (listTileHeight * targetVisibleItems);
        final calculatedSize = (targetHeight / screenHeight).clamp(0.3, 0.6);
        
        return DraggableScrollableSheet(
          initialChildSize: calculatedSize,
          minChildSize: 0.3,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 0),
              child: Column(
                children: [
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      children: widgets,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  IconData _getAppIcon(MessagingApp app) {
    switch (app) {
      case MessagingApp.wechat:
        return FontAwesomeIcons.weixin;
      case MessagingApp.qq:
        return FontAwesomeIcons.qq;
      case MessagingApp.whatsapp:
        return FontAwesomeIcons.whatsapp;
      case MessagingApp.telegram:
        return FontAwesomeIcons.telegram;
      case MessagingApp.discord:
        return FontAwesomeIcons.discord;
      case MessagingApp.messenger:
        return FontAwesomeIcons.facebookMessenger;
      case MessagingApp.line:
        return FontAwesomeIcons.line;
      case MessagingApp.x:
        return FontAwesomeIcons.xTwitter;
    }
  }

  Color _getAppColor(MessagingApp app) {
    final colors = {
      MessagingApp.wechat: Colors.green,
      MessagingApp.qq: Colors.blue,
      MessagingApp.whatsapp: const Color(0xFF25D366),
      MessagingApp.telegram: const Color(0xFF0088CC),
      MessagingApp.discord: const Color(0xFF5865F2),
      MessagingApp.messenger: const Color(0xFF0084FF),
      MessagingApp.line: const Color(0xFF00B900),
      MessagingApp.x: Colors.black,
    };
    return colors[app] ?? Colors.grey;
  }

  Future<void> _shareToApp(
    BuildContext context,
    StickerModel sticker,
    MessagingApp app,
  ) async {
    try {
      // Show loading dialog
      if (context.mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) =>
              const Center(child: CircularProgressIndicator()),
        );
      }

      // Read GIF file
      final ByteData data = await rootBundle.load(sticker.gifPath);
      final Uint8List gifData = data.buffer.asUint8List();

      // Close loading dialog
      if (context.mounted) {
        Navigator.pop(context);
      }

      // Share to app
      final success = await MessagingShareService.shareGifToApp(
        gifData: gifData,
        packageName: app.packageName,
      );

      if (context.mounted) {
        if (!success) {
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

  Future<void> _shareGeneric(
    BuildContext context,
    StickerModel sticker,
  ) async {
    try {
      // Show loading dialog
      if (context.mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) =>
              const Center(child: CircularProgressIndicator()),
        );
      }

      // Read GIF file
      final ByteData data = await rootBundle.load(sticker.gifPath);
      final Uint8List gifData = data.buffer.asUint8List();

      // Close loading dialog
      if (context.mounted) {
        Navigator.pop(context);
      }

      // Share generically
      final success = await MessagingShareService.shareGifGeneric(
        gifData: gifData,
      );

      if (context.mounted) {
        if (!success) {
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

}

