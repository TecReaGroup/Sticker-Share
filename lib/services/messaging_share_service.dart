import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

enum MessagingApp {
  wechat('com.tencent.mm', 'WeChat'),
  qq('com.tencent.mobileqq', 'QQ'),
  x('com.twitter.android', 'X'),
  messenger('com.facebook.orca', 'Messenger'),
  line('jp.naver.line.android', 'LINE'),
  whatsapp('com.whatsapp', 'WhatsApp'),
  discord('com.discord', 'Discord'),
  telegram('org.telegram.messenger', 'Telegram'),
  ;

  final String packageName;
  final String displayName;
  
  const MessagingApp(this.packageName, this.displayName);
}

class MessagingShareService {
  static const MethodChannel _channel =
      MethodChannel('com.stickershare/messaging_share');

  /// Share GIF to specific messaging app
  static Future<bool> shareGifToApp({
    required Uint8List gifData,
    required String packageName,
  }) async {
    try {
      final result = await _channel.invokeMethod('shareGif', {
        'gifData': gifData,
        'packageName': packageName,
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

  /// Share GIF with system share sheet (no specific app)
  static Future<bool> shareGifGeneric({
    required Uint8List gifData,
  }) async {
    try {
      final result = await _channel.invokeMethod('shareGifGeneric', {
        'gifData': gifData,
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

  /// Get list of installed messaging apps
  static Future<List<MessagingApp>> getInstalledApps() async {
    try {
      final result = await _channel.invokeMethod('getInstalledApps');
      final List<String> installedPackages = List<String>.from(result ?? []);
      
      return MessagingApp.values
          .where((app) => installedPackages.contains(app.packageName))
          .toList();
    } catch (e) {
      debugPrint('Failed to get installed apps: $e');
      return [];
    }
  }

  /// Check if specific app is installed
  static Future<bool> isAppInstalled(String packageName) async {
    try {
      final result = await _channel.invokeMethod('isAppInstalled', {
        'packageName': packageName,
      });
      return result == true;
    } catch (e) {
      debugPrint('Failed to check app installation: $e');
      return false;
    }
  }
}