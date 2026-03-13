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
    // iOS beyaz ekrani native plugin register zincirinden izole etmek icin
    // ilk frame testinde otomatik plugin kaydini gecici olarak kapat.

    // iOS launch hattindaki native beyaz ekran davranisini izole etmek icin
    // ek native plugin/kurulum islerini gecici olarak ertele.

    GeneratedPluginRegistrant.register(with: self)
    if let hlsRegistrar = self.registrar(forPlugin: "HLSPlayerPlugin") {
      HLSPlayerPlugin.register(with: hlsRegistrar)
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
