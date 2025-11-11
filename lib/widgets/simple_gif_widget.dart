import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Simple and efficient GIF widget, using Flutter native Image.memory
/// No fixed frame rate, let Flutter handle it automatically
class SimpleGifWidget extends StatefulWidget {
  final String assetPath;
  final String stickerName;
  final BoxFit fit;

  const SimpleGifWidget({
    super.key,
    required this.assetPath,
    required this.stickerName,
    this.fit = BoxFit.cover,
  });

  @override
  State<SimpleGifWidget> createState() => _SimpleGifWidgetState();
}

class _SimpleGifWidgetState extends State<SimpleGifWidget> {
  bool _isLoading = true;
  bool _hasError = false;
  String? _errorMessage;
  Uint8List? _gifData;

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

      if (bytes.length < 6 || String.fromCharCodes(bytes.sublist(0, 3)) != 'GIF') {
        throw Exception('Invalid GIF');
      }

      if (!mounted) return;

      setState(() {
        _gifData = bytes;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = 'Load failed';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        color: Colors.grey[200],
        child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    if (_hasError || _gifData == null) {
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

    // Key: Don't set frameRate, let Flutter handle it automatically
    return Image.memory(
      _gifData!,
      fit: widget.fit,
      gaplessPlayback: true,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          color: Colors.grey[200],
          child: const Icon(Icons.broken_image, color: Colors.grey),
        );
      },
    );
  }
}