import Flutter
import UIKit

public class WeChatSharePlugin: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: "com.stickershare/wechat_share",
            binaryMessenger: registrar.messenger()
        )
        let instance = WeChatSharePlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "shareGif":
            shareGif(call: call, result: result)
        case "isWeChatInstalled":
            result(canOpenWeChat())
        case "getWeChatVersion":
            result(getWeChatVersion())
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    private func shareGif(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let gifData = args["gifData"] as? FlutterStandardTypedData,
              let appId = args["appId"] as? String else {
            result(FlutterError(code: "INVALID_ARGS", message: "Missing required arguments", details: nil))
            return
        }
        
        let scene = args["scene"] as? String ?? "session"
        let sceneValue = getSceneValue(scene: scene)
        
        // 构造微信分享数据包
        let messageDict: [String: Any] = [
            "objectType": "8",  // GIF类型标识
            "fileData": gifData.data,
            "thumbData": getThumbnail(from: gifData.data),
            "command": "1010",
            "scene": sceneValue,
            "result": "1",
            "returnFromApp": "1",
            "sdkver": "1.5"
        ]
        
        // 序列化为PropertyList格式
        guard let plistData = try? PropertyListSerialization.data(
            fromPropertyList: [appId: messageDict],
            format: .binary,
            options: 0
        ) else {
            result(FlutterError(code: "SERIALIZATION_ERROR", message: "Failed to serialize data", details: nil))
            return
        }
        
        // 写入剪贴板（类型必须是 "content"）
        UIPasteboard.general.setData(plistData, forPasteboardType: "content")
        
        // 跳转微信
        let urlString = "weixin://app/\(appId)/sendreq/?"
        if let url = URL(string: urlString),
           UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url) { success in
                result(success)
            }
        } else {
            result(FlutterError(code: "WECHAT_NOT_INSTALLED", message: "WeChat is not installed", details: nil))
        }
    }
    
    private func getThumbnail(from gifData: Data) -> Data {
        guard let image = UIImage(data: gifData) else {
            return Data()
        }
        
        // 创建缩略图 (100x100)
        let size = CGSize(width: 100, height: 100)
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        image.draw(in: CGRect(origin: .zero, size: size))
        let thumbnail = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return thumbnail?.jpegData(compressionQuality: 0.7) ?? Data()
    }
    
    private func getSceneValue(scene: String) -> String {
        switch scene {
        case "timeline":
            return "1"  // 朋友圈
        case "favorite":
            return "2"  // 收藏
        default:
            return "0"  // 聊天（默认）
        }
    }
    
    private func canOpenWeChat() -> Bool {
        guard let url = URL(string: "weixin://") else { return false }
        return UIApplication.shared.canOpenURL(url)
    }
    
    private func getWeChatVersion() -> String? {
        // 尝试获取微信版本（可选功能）
        if canOpenWeChat() {
            return "installed"  // 简化实现，实际可通过其他方式获取版本号
        }
        return nil
    }
}