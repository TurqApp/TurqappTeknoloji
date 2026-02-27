import Flutter
import UIKit
import GoogleMaps
import AVFAudio
import AVFoundation

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    // Register native HLS player plugin
    if let registrar = self.registrar(forPlugin: "HLSPlayerPlugin") {
      HLSPlayerPlugin.register(with: registrar)
    }

    // Google Maps API key (Info.plist: GMSApiKey)
    if let mapsKey = Bundle.main.object(forInfoDictionaryKey: "GMSApiKey") as? String,
       !mapsKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
      DispatchQueue.main.async {
        GMSServices.provideAPIKey(mapsKey)
      }
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
