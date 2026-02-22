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
    GMSServices.provideAPIKey("<REDACTED_GOOGLE_MAPS_API_KEY>")

    GeneratedPluginRegistrant.register(with: self)

    // Register native HLS player plugin
    if let registrar = self.registrar(forPlugin: "HLSPlayerPlugin") {
      HLSPlayerPlugin.register(with: registrar)
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
