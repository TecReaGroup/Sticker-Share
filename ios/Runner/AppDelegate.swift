import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    
    // Register WeChat share plugin
    let controller = window?.rootViewController as! FlutterViewController
    WeChatSharePlugin.register(with: registrar(forPlugin: "WeChatSharePlugin")!)
    
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
