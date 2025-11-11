import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class WeChatShareService {
  static const MethodChannel _channel =
      MethodChannel('com.stickershare/wechat_share');

  /// Share GIF to WeChat (keep animation)
  /// [gifData] GIF file byte data
  /// [appId] AppID from WeChat Open Platform
  /// [scene] Share scene: 'session'(chat), 'timeline'(moments), 'favorite'(favorites)
  static Future<bool> shareGifToWeChat({
    required Uint8List gifData,
    required String appId,
    String scene = 'session',
  }) async {
    try {
      final result = await _channel.invokeMethod('shareGif', {
        'gifData': gifData,
        'appId': appId,
        'scene': scene,
      });
      return result == true;
    } on PlatformException catch (e) {
      debugPrint('Share failed: ${e.message}');
      return false;
    } catch (e) {
      debugPrint('Share failed: $e');
      return false;
    }
  }

  /// Check if WeChat is installed
  static Future<bool> isWeChatInstalled() async {
    try {
      final result = await _channel.invokeMethod('isWeChatInstalled');
      return result == true;
    } on PlatformException catch (e) {
      debugPrint('Failed to check WeChat installation: ${e.message}');
      return false;
    } catch (e) {
      debugPrint('Failed to check WeChat installation: $e');
      return false;
    }
  }

  /// Get WeChat version (optional feature)
  static Future<String?> getWeChatVersion() async {
    try {
      final result = await _channel.invokeMethod('getWeChatVersion');
      return result as String?;
    } catch (e) {
      debugPrint('Failed to get WeChat version: $e');
      return null;
    }
  }
}