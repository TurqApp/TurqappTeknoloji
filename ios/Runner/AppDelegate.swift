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

    // iOS beyaz ekrani native plugin register zincirinden izole etmek icin
    // ilk frame testinde otomatik plugin kaydini gecici olarak kapat.

    // iOS launch hattindaki native beyaz ekran davranisini izole etmek icin
    // ek native plugin/kurulum islerini gecici olarak ertele.

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
