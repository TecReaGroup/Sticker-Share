import 'package:flutter/services.dart';

class WeChatShareService {
  static const MethodChannel _channel =
      MethodChannel('com.stickershare/wechat_share');

  /// 分享GIF到微信（保持动画）
  /// [gifData] GIF文件的字节数据
  /// [appId] 微信开放平台申请的AppID
  /// [scene] 分享场景: 'session'(聊天), 'timeline'(朋友圈), 'favorite'(收藏)
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
      print('分享失败: ${e.message}');
      return false;
    } catch (e) {
      print('分享失败: $e');
      return false;
    }
  }

  /// 检查微信是否安装
  static Future<bool> isWeChatInstalled() async {
    try {
      final result = await _channel.invokeMethod('isWeChatInstalled');
      return result == true;
    } on PlatformException catch (e) {
      print('检查微信安装状态失败: ${e.message}');
      return false;
    } catch (e) {
      print('检查微信安装状态失败: $e');
      return false;
    }
  }

  /// 获取微信版本（可选功能）
  static Future<String?> getWeChatVersion() async {
    try {
      final result = await _channel.invokeMethod('getWeChatVersion');
      return result as String?;
    } catch (e) {
      print('获取微信版本失败: $e');
      return null;
    }
  }
}