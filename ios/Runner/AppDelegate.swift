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
#if DEBUG
    // flutter run -> devicectl launch akışında scheme env aktarılmadığı için
    // App Check debug token'ı process env'e elle set ediyoruz.
    setenv("FIRAAppCheckDebugToken", "5E0932DD-33D6-44AB-B373-7E5EEEA9B36E", 1)
#endif

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
