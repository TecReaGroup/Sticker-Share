import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A robust GIF widget with multiple rendering strategies and fallback mechanisms
/// to handle frame corruption issues across different platforms.
/// 
/// Strategy 1: Use Flutter's built-in Image.memory with gaplessPlayback
/// Strategy 2: Use gif_view package (current implementation)
/// Strategy 3: Use Image.asset as final fallback
class RobustGifWidget extends StatefulWidget {
  final String assetPath;
  final String stickerName;
  final BoxFit fit;
  final bool autoPlay;

  const RobustGifWidget({
    super.key,
    required this.assetPath,
    required this.stickerName,
    this.fit = BoxFit.cover,
    this.autoPlay = true,
  });

  @override
  State<RobustGifWidget> createState() => _RobustGifWidgetState();
}

class _RobustGifWidgetState extends State<RobustGifWidget> {
  bool _isLoading = true;
  bool _hasError = false;
  String? _errorMessage;
  Uint8List? _gifData;
  RenderStrategy _currentStrategy = RenderStrategy.imageMemory;

  @override
  void initState() {
    super.initState();
    _loadGifData();
  }

  @override
  void didUpdateWidget(RobustGifWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.assetPath != widget.assetPath) {
      _loadGifData();
    }
  }

  Future<void> _loadGifData() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = null;
    });

    try {
      final ByteData data = await rootBundle.load(widget.assetPath);
      final Uint8List bytes = data.buffer.asUint8List();

      // Validate GIF
      if (bytes.length < 6) {
        throw Exception('File too small');
      }

      final signature = String.fromCharCodes(bytes.sublist(0, 3));
      if (signature != 'GIF') {
        throw Exception('Invalid GIF format');
      }

      // Log GIF info
      final version = String.fromCharCodes(bytes.sublist(0, 6));
      debugPrint('✅ Loaded GIF: ${widget.assetPath}');
      debugPrint('   Size: ${bytes.length} bytes, Version: $version');

      if (!mounted) return;

      setState(() {
        _gifData = bytes;
        _isLoading = false;
        _hasError = false;
      });
    } catch (e) {
      debugPrint('❌ GIF load error: $e');
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = _parseErrorMessage(e);
      });
    }
  }

  String _parseErrorMessage(dynamic error) {
    final errorStr = error.toString().toLowerCase();
    
    if (errorStr.contains('asset') || errorStr.contains('not found')) {
      return 'GIF file not found';
    } else if (errorStr.contains('signature') || errorStr.contains('invalid')) {
      return 'Invalid GIF format';
    } else {
      return 'Load failed';
    }
  }

  void _tryNextStrategy() {
    if (_currentStrategy == RenderStrategy.imageMemory) {
      debugPrint('⚠️ Strategy 1 failed, trying Image.asset fallback');
      setState(() {
        _currentStrategy = RenderStrategy.imageAsset;
      });
    } else {
      setState(() {
        _hasError = true;
        _errorMessage = 'All rendering strategies failed';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingWidget();
    }

    if (_hasError || _gifData == null) {
      return _buildErrorWidget();
    }

    return _buildGifWidget();
  }

  Widget _buildLoadingWidget() {
    return Container(
      color: Colors.grey[200],
      child: const Center(
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Container(
      color: Colors.grey[200],
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.gif_box, size: 32, color: Colors.grey),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              widget.stickerName,
              style: const TextStyle(fontSize: 10, color: Colors.black87),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _errorMessage ?? 'Load failed',
            style: const TextStyle(fontSize: 8, color: Colors.red),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          InkWell(
            onTap: () {
              setState(() {
                _currentStrategy = RenderStrategy.imageMemory;
              });
              _loadGifData();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.blue, width: 1),
              ),
              child: const Text(
                'Retry',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.blue,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGifWidget() {
    switch (_currentStrategy) {
      case RenderStrategy.imageMemory:
        return _buildImageMemoryWidget();
      case RenderStrategy.imageAsset:
        return _buildImageAssetWidget();
    }
  }

  /// Strategy 1: Use Image.memory with gaplessPlayback
  /// This is the most compatible method and handles most GIF issues
  Widget _buildImageMemoryWidget() {
    return Image.memory(
      _gifData!,
      fit: widget.fit,
      gaplessPlayback: true,
      filterQuality: FilterQuality.medium,
      errorBuilder: (context, error, stackTrace) {
        debugPrint('❌ Image.memory failed: $error');
        // Try next strategy on error
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _tryNextStrategy();
        });
        return _buildLoadingWidget();
      },
    );
  }

  /// Strategy 2: Use Image.asset as fallback
  /// Direct asset loading as last resort
  Widget _buildImageAssetWidget() {
    return Image.asset(
      widget.assetPath,
      fit: widget.fit,
      gaplessPlayback: true,
      filterQuality: FilterQuality.medium,
      errorBuilder: (context, error, stackTrace) {
        debugPrint('❌ Image.asset failed: $error');
        // All strategies failed
        WidgetsBinding.instance.addPostFrameCallback((_) {
          setState(() {
            _hasError = true;
            _errorMessage = 'All rendering methods failed';
          });
        });
        return _buildErrorWidget();
      },
    );
  }
}

enum RenderStrategy {
  imageMemory,
  imageAsset,
}