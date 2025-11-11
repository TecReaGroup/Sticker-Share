import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui' as ui;

/// Error-tolerant GIF widget - can skip corrupted frames and continue playback
class ErrorTolerantGifWidget extends StatefulWidget {
  final String assetPath;
  final String stickerName;
  final BoxFit fit;

  const ErrorTolerantGifWidget({
    super.key,
    required this.assetPath,
    required this.stickerName,
    this.fit = BoxFit.cover,
  });

  @override
  State<ErrorTolerantGifWidget> createState() => _ErrorTolerantGifWidgetState();
}

class _ErrorTolerantGifWidgetState extends State<ErrorTolerantGifWidget>
    with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  bool _hasError = false;
  String? _errorMessage;
  ui.Codec? _codec;
  List<ui.FrameInfo?> _frameCache = [];
  int _currentFrameIndex = 0;
  ui.Image? _currentImage;
  bool _isAnimating = false;

  @override
  void initState() {
    super.initState();
    _loadGif();
  }

  Future<void> _loadGif() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final ByteData data = await rootBundle.load(widget.assetPath);
      final Uint8List bytes = data.buffer.asUint8List();

      // Validate GIF signature
      if (bytes.length < 6 || String.fromCharCodes(bytes.sublist(0, 3)) != 'GIF') {
        throw Exception('Invalid GIF format');
      }

      // Initialize codec with no target size to preserve original quality
      _codec = await ui.instantiateImageCodec(
        bytes,
        allowUpscaling: false,
      );
      
      final frameCount = _codec!.frameCount;
      
      // Pre-allocate frame cache
      _frameCache = List.filled(frameCount, null);
      
      debugPrint('🎬 GIF loaded: $frameCount frames - ${widget.assetPath}');

      // Pre-load all frames sequentially with error handling
      await _preloadAllFrames();
      
      if (!mounted) return;

      // Start with first valid frame
      final firstValidFrame = _frameCache.firstWhere(
        (frame) => frame != null,
        orElse: () => null,
      );

      if (firstValidFrame == null) {
        throw Exception('No valid frames found');
      }

      setState(() {
        _isLoading = false;
        _currentImage = firstValidFrame.image;
      });

      _startAnimation();
    } catch (e) {
      debugPrint('❌ GIF load error: $e');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = 'Load failed';
      });
    }
  }

  /// Pre-load all frames to avoid codec state issues
  Future<void> _preloadAllFrames() async {
    int loadedCount = 0;
    int failedCount = 0;

    for (int i = 0; i < _frameCache.length; i++) {
      if (!mounted) break;
      
      try {
        final frame = await _codec!.getNextFrame();
        _frameCache[i] = frame;
        loadedCount++;
      } catch (e) {
        debugPrint('⚠️ Frame $i corrupted, skipping: $e');
        _frameCache[i] = null; // Mark as corrupted
        failedCount++;
      }
    }

    debugPrint('✅ Loaded $loadedCount/${_frameCache.length} frames ($failedCount failed)');
  }

  /// Start animation loop
  void _startAnimation() async {
    if (_isAnimating) return;
    _isAnimating = true;
    
    while (mounted && _isAnimating) {
      final frameIndex = _currentFrameIndex % _frameCache.length;
      final frame = _frameCache[frameIndex];
      
      // Skip null (corrupted) frames
      if (frame == null) {
        _currentFrameIndex++;
        continue;
      }
      
      if (mounted) {
        setState(() {
          _currentImage = frame.image;
        });
        
        // Use frame duration, with a minimum delay for stability
        final duration = frame.duration.inMilliseconds > 0
            ? frame.duration
            : const Duration(milliseconds: 100);
        
        await Future.delayed(duration);
      }
      
      _currentFrameIndex++;
    }
  }

  @override
  void dispose() {
    _isAnimating = false;
    _codec?.dispose();
    for (var frame in _frameCache) {
      frame?.image.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        color: Colors.grey[200],
        child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    if (_hasError) {
      return Container(
        color: Colors.grey[200],
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.gif_box, size: 32, color: Colors.grey),
            const SizedBox(height: 4),
            Text(
              widget.stickerName,
              style: const TextStyle(fontSize: 10),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              _errorMessage ?? 'Load failed',
              style: const TextStyle(fontSize: 8, color: Colors.red),
            ),
          ],
        ),
      );
    }

    if (_currentImage == null) {
      return Container(color: Colors.grey[200]);
    }

    return CustomPaint(
      painter: _GifFramePainter(_currentImage!, widget.fit),
      child: Container(),
    );
  }
}

/// Custom painter to render GIF frames
class _GifFramePainter extends CustomPainter {
  final ui.Image image;
  final BoxFit fit;

  _GifFramePainter(this.image, this.fit);

  @override
  void paint(Canvas canvas, Size size) {
    final src = Rect.fromLTWH(
      0,
      0,
      image.width.toDouble(),
      image.height.toDouble(),
    );

    final dst = _applyBoxFit(fit, src.size, size);
    
    canvas.drawImageRect(image, src, dst, Paint());
  }

  Rect _applyBoxFit(BoxFit fit, Size srcSize, Size dstSize) {
    final FittedSizes fittedSizes = applyBoxFit(fit, srcSize, dstSize);
    final Size outputSize = fittedSizes.destination;
    
    final double dx = (dstSize.width - outputSize.width) / 2.0;
    final double dy = (dstSize.height - outputSize.height) / 2.0;
    
    return Rect.fromLTWH(dx, dy, outputSize.width, outputSize.height);
  }

  @override
  bool shouldRepaint(_GifFramePainter oldDelegate) {
    return oldDelegate.image != image;
  }
}