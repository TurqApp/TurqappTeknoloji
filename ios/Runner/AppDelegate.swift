import Flutter
import UIKit
import FirebaseMessaging
import GoogleMaps
import AVFAudio
import AVFoundation
import UserNotifications

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
    PlaybackHealthStore.shared.installDebugLabelIfNeeded()
    UNUserNotificationCenter.current().delegate = self
    application.registerForRemoteNotifications()

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  override func application(
    _ application: UIApplication,
    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
  ) {
    Messaging.messaging().apnsToken = deviceToken
    super.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
  }

  override func application(
    _ application: UIApplication,
    didFailToRegisterForRemoteNotificationsWithError error: Error
  ) {
    super.application(application, didFailToRegisterForRemoteNotificationsWithError: error)
  }
}
