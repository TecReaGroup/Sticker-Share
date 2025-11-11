import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;

/// An improved GIF preview widget with multiple rendering strategies
/// to handle frame corruption issues across different platforms.
class ImprovedGifPreviewWidget extends StatefulWidget {
  final String assetPath;
  final String stickerName;
  final BoxFit fit;
  final bool autoPlay;

  const ImprovedGifPreviewWidget({
    super.key,
    required this.assetPath,
    required this.stickerName,
    this.fit = BoxFit.cover,
    this.autoPlay = true,
  });

  @override
  State<ImprovedGifPreviewWidget> createState() => _ImprovedGifPreviewWidgetState();
}

class _ImprovedGifPreviewWidgetState extends State<ImprovedGifPreviewWidget>
    with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  bool _hasError = false;
  String? _errorMessage;
  List<img.Image>? _frames;
  List<int>? _durations;
  int _currentFrame = 0;
  AnimationController? _controller;

  @override
  void initState() {
    super.initState();
    _loadAndDecodeGif();
  }

  @override
  void didUpdateWidget(ImprovedGifPreviewWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.assetPath != widget.assetPath) {
      _cleanup();
      _loadAndDecodeGif();
    }
  }

  /// Load and decode GIF with robust error handling
  Future<void> _loadAndDecodeGif() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = null;
    });

    try {
      // Load GIF data
      final ByteData data = await rootBundle.load(widget.assetPath);
      final Uint8List bytes = data.buffer.asUint8List();

      if (bytes.length < 6) {
        throw Exception('File too small');
      }

      // Validate GIF signature
      final signature = String.fromCharCodes(bytes.sublist(0, 3));
      if (signature != 'GIF') {
        throw Exception('Invalid GIF format');
      }

      // Try to decode frames using image package
      final decoder = img.GifDecoder();
      final gifImage = decoder.decode(bytes);

      if (gifImage == null) {
        throw Exception('Failed to decode GIF');
      }

      // Extract frames with error tolerance
      final List<img.Image> frames = [];
      final List<int> durations = [];

      // Get frame count
      final numFrames = gifImage.numFrames;
      debugPrint('🎬 GIF has $numFrames frames: ${widget.assetPath}');

      for (int i = 0; i < numFrames; i++) {
        try {
          final frame = gifImage.frames[i];
          frames.add(frame);
          
          // Get frame duration (default to 100ms if not specified)
          final duration = frame.frameDuration;
          durations.add(duration);
        } catch (e) {
          debugPrint('⚠️ Skipping corrupted frame $i: $e');
          // Skip corrupted frames but continue processing
          continue;
        }
      }

      if (frames.isEmpty) {
        throw Exception('No valid frames found');
      }

      if (!mounted) return;

      setState(() {
        _frames = frames;
        _durations = durations;
        _isLoading = false;
        _hasError = false;
      });

      // Start animation if autoPlay is enabled
      if (widget.autoPlay) {
        _startAnimation();
      }
    } catch (e) {
      debugPrint('❌ GIF loading error: $e');
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = _parseErrorMessage(e);
      });
    }
  }

  /// Start frame animation
  void _startAnimation() {
    if (_frames == null || _durations == null || _frames!.isEmpty) return;

    // Calculate total animation duration
    final totalDuration = _durations!.reduce((a, b) => a + b);
    
    _controller = AnimationController(
      duration: Duration(milliseconds: totalDuration),
      vsync: this,
    )..addListener(() {
      if (!mounted) return;
      
      // Calculate current frame based on animation progress
      int elapsed = (_controller!.value * totalDuration).floor();
      int frameIndex = 0;
      int accumulator = 0;

      for (int i = 0; i < _durations!.length; i++) {
        accumulator += _durations![i];
        if (elapsed < accumulator) {
          frameIndex = i;
          break;
        }
      }

      if (frameIndex != _currentFrame && frameIndex < _frames!.length) {
        setState(() {
          _currentFrame = frameIndex;
        });
      }
    });

    _controller!.repeat();
  }

  String _parseErrorMessage(dynamic error) {
    final errorStr = error.toString().toLowerCase();
    
    if (errorStr.contains('asset') || errorStr.contains('not found')) {
      return 'GIF file not found';
    } else if (errorStr.contains('signature') || errorStr.contains('invalid')) {
      return 'Invalid GIF format';
    } else if (errorStr.contains('decode') || errorStr.contains('frame')) {
      return 'Decode failed';
    } else {
      return 'Load failed';
    }
  }

  void _cleanup() {
    _controller?.dispose();
    _controller = null;
    _frames = null;
    _durations = null;
  }

  @override
  void dispose() {
    _cleanup();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingWidget();
    }

    if (_hasError) {
      return _buildErrorWidget();
    }

    return _buildFrameWidget();
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
            onTap: _loadAndDecodeGif,
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

  Widget _buildFrameWidget() {
    if (_frames == null || _frames!.isEmpty) {
      return _buildErrorWidget();
    }

    try {
      final currentFrame = _frames![_currentFrame % _frames!.length];
      final imageBytes = Uint8List.fromList(img.encodePng(currentFrame));

      return Image.memory(
        imageBytes,
        fit: widget.fit,
        gaplessPlayback: true,
        errorBuilder: (context, error, stackTrace) {
          debugPrint('Frame render error: $error');
          return _buildErrorWidget();
        },
      );
    } catch (e) {
      debugPrint('Frame display error: $e');
      return _buildErrorWidget();
    }
  }
}