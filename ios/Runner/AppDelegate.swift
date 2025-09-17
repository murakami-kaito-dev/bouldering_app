import Flutter
import UIKit
import GoogleMaps  // 追加

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Config.plistからAPIキーを読み込み
    guard let configPath = Bundle.main.path(forResource: "Config", ofType: "plist"),
          let config = NSDictionary(contentsOfFile: configPath) else {
      fatalError("Config.plist not found or invalid")
    }
    
    // Build Configurationに基づいたAPIキー取得
    let bundleId = Bundle.main.bundleIdentifier ?? ""
    var apiKey = ""
    
    if bundleId.contains(".dev") {
      // 開発環境用APIキー
      apiKey = config["GOOGLE_MAPS_IOS_DEV_API_KEY"] as? String ?? ""
    } else {
      // 本番環境用APIキー
      apiKey = config["GOOGLE_MAPS_IOS_PROD_API_KEY"] as? String ?? ""
    }
    
    if apiKey.isEmpty {
      fatalError("Google Maps API key not found in Config.plist")
    }
    
    GMSServices.provideAPIKey(apiKey)
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
