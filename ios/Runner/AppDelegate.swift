import Flutter
import UIKit
import GoogleMaps
import AVFAudio
import AVFoundation

@main
@objc class AppDelegate: FlutterAppDelegate {
  private func resolvedGoogleMapsApiKey() -> String? {
    // Prefer explicit iOS Maps key from Info.plist.
    if let mapsKey = Bundle.main.object(forInfoDictionaryKey: "GMSApiKey") as? String {
      let trimmed = mapsKey.trimmingCharacters(in: .whitespacesAndNewlines)
      if !trimmed.isEmpty {
        return trimmed
      }
    }

    // Fallback: avoid hard crash when map is opened but GMSApiKey is empty.
    if let path = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist"),
       let dict = NSDictionary(contentsOfFile: path),
       let firebaseApiKey = dict["API_KEY"] as? String {
      let trimmed = firebaseApiKey.trimmingCharacters(in: .whitespacesAndNewlines)
      if !trimmed.isEmpty {
        NSLog("[TurqApp] GMSApiKey missing in Info.plist, using GoogleService-Info API_KEY fallback.")
        return trimmed
      }
    }

    return nil
  }

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    if let mapsKey = resolvedGoogleMapsApiKey() {
      GMSServices.provideAPIKey(mapsKey)
    } else {
      NSLog("[TurqApp] WARNING: Google Maps API key is missing. GoogleMap can crash without a valid key.")
    }

    GeneratedPluginRegistrant.register(with: self)

    // Register native HLS player plugin
    if let registrar = self.registrar(forPlugin: "HLSPlayerPlugin") {
      HLSPlayerPlugin.register(with: registrar)
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
