import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gif_view/gif_view.dart';

/// A robust GIF preview widget with comprehensive error handling
/// and resource management using the gif_view package.
class GifPreviewWidget extends StatefulWidget {
  /// The asset path of the GIF file
  final String assetPath;
  
  /// The name of the sticker for display in error states
  final String stickerName;
  
  /// How the GIF should fit in the container
  final BoxFit fit;
  
  /// Whether to automatically start playing the GIF
  final bool autoPlay;
  
  /// Number of times to loop the GIF (0 = infinite)
  final int loopCount;

  const GifPreviewWidget({
    super.key,
    required this.assetPath,
    required this.stickerName,
    this.fit = BoxFit.cover,
    this.autoPlay = true,
    this.loopCount = 0,
  });

  @override
  State<GifPreviewWidget> createState() => _GifPreviewWidgetState();
}

class _GifPreviewWidgetState extends State<GifPreviewWidget> {
  GifController? _controller;
  bool _isLoading = true;
  bool _hasError = false;
  String? _errorMessage;
  Uint8List? _gifData;

  @override
  void initState() {
    super.initState();
    _loadGifData();
  }

  @override
  void didUpdateWidget(GifPreviewWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reload if the asset path changes
    if (oldWidget.assetPath != widget.assetPath) {
      _disposeController();
      _loadGifData();
    }
  }

  /// Load GIF data from assets with comprehensive error handling
  Future<void> _loadGifData() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = null;
    });

    try {
      // Validate asset path
      if (widget.assetPath.isEmpty) {
        throw Exception('Asset path is empty');
      }

      if (!widget.assetPath.toLowerCase().endsWith('.gif')) {
        throw Exception('File is not a GIF format');
      }

      // Load the GIF file data
      final ByteData data = await rootBundle.load(widget.assetPath);
      final Uint8List bytes = data.buffer.asUint8List();

      // Validate GIF data (check minimum size and GIF header)
      if (bytes.length < 6) {
        throw Exception('File is too small to be a valid GIF');
      }

      // Check GIF signature (GIF87a or GIF89a)
      final signature = String.fromCharCodes(bytes.sublist(0, 3));
      final version = String.fromCharCodes(bytes.sublist(0, 6));
      if (signature != 'GIF') {
        throw Exception('Invalid GIF file signature');
      }

      // Log GIF details for debugging
      debugPrint('🔍 GIF Debug Info for ${widget.assetPath}:');
      debugPrint('  - File size: ${bytes.length} bytes');
      debugPrint('  - Version: $version');
      debugPrint('  - First 20 bytes: ${bytes.sublist(0, 20).map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ')}');

      // Check for corrupted or empty data
      if (bytes.length < 100) {
        throw Exception('GIF file appears to be corrupted or incomplete');
      }

      if (!mounted) return;

      setState(() {
        _gifData = bytes;
        _isLoading = false;
        _hasError = false;
      });

      // Initialize the GIF controller after data is loaded
      _initializeController();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = _parseErrorMessage(e);
      });
    }
  }

  /// Initialize the GIF controller with proper configuration
  void _initializeController() {
    if (_gifData == null || !mounted) return;

    try {
      _controller = GifController();
      if (widget.autoPlay) {
        _controller?.play();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = 'Failed to initialize GIF controller: ${e.toString()}';
        });
      }
    }
  }

  /// Parse error message to provide user-friendly feedback
  String _parseErrorMessage(dynamic error) {
    final errorStr = error.toString().toLowerCase();
    
    if (errorStr.contains('asset') || errorStr.contains('not found')) {
      return 'GIF file not found';
    } else if (errorStr.contains('signature') || errorStr.contains('invalid')) {
      return 'Invalid GIF format';
    } else if (errorStr.contains('corrupted') || errorStr.contains('incomplete')) {
      return 'Partial frame corruption';
    } else if (errorStr.contains('memory') || errorStr.contains('size')) {
      return 'File too large';
    } else {
      return 'Load failed';
    }
  }

  /// Dispose the controller to free resources
  void _disposeController() {
    _controller?.dispose();
    _controller = null;
  }

  @override
  void dispose() {
    _disposeController();
    _gifData = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Loading state
    if (_isLoading) {
      return _buildLoadingWidget();
    }

    // Error state
    if (_hasError || _gifData == null) {
      return _buildErrorWidget();
    }

    // Success state - display GIF
    return _buildGifWidget();
  }

  /// Build the loading indicator
  Widget _buildLoadingWidget() {
    return Container(
      color: Colors.grey[200],
      child: const Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
        ),
      ),
    );
  }

  /// Build the error display widget
  Widget _buildErrorWidget() {
    return Container(
      color: Colors.grey[200],
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.gif_box,
            size: 32,
            color: Colors.grey,
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              widget.stickerName,
              style: const TextStyle(
                fontSize: 10,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _errorMessage ?? 'Load failed',
            style: const TextStyle(
              fontSize: 8,
              color: Colors.red,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          // Retry button for error recovery
          InkWell(
            onTap: _loadGifData,
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

  /// Build the GIF display widget using gif_view package
  Widget _buildGifWidget() {
    if (_gifData == null || _controller == null) {
      return _buildErrorWidget();
    }

    return SizedBox(
      width: double.infinity,
      height: double.infinity,
      child: GifView.memory(
        _gifData!,
        controller: _controller,
        frameRate: 30, // Optimize frame rate for smooth playback
      ),
    );
  }
}