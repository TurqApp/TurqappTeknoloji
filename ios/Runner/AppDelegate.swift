import Flutter
import UIKit
import FirebaseMessaging
import GoogleMaps
import AVFAudio
import AVFoundation
import UserNotifications

private final class DeepLinkStreamHandler: NSObject, FlutterStreamHandler {
  var sink: FlutterEventSink?
  var pendingLink: String?

  func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    sink = events
    if let pendingLink, !pendingLink.isEmpty {
      events(pendingLink)
      self.pendingLink = nil
    }
    return nil
  }

  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    sink = nil
    return nil
  }

  func emit(_ link: String) {
    guard !link.isEmpty else { return }
    if let sink {
      sink(link)
    } else {
      pendingLink = link
    }
  }
}

@main
@objc class AppDelegate: FlutterAppDelegate {
  private let deepLinkMethodChannelName = "turqapp.deep_link/method"
  private let deepLinkEventChannelName = "turqapp.deep_link/events"
  private let deepLinkStreamHandler = DeepLinkStreamHandler()
  private var initialDeepLink: String?

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
    initialDeepLink = extractInitialDeepLink(from: launchOptions)
    installDeepLinkBridgeIfPossible()
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

  override func application(
    _ app: UIApplication,
    open url: URL,
    options: [UIApplication.OpenURLOptionsKey: Any] = [:]
  ) -> Bool {
    emitDeepLink(url)
    return super.application(app, open: url, options: options)
  }

  override func application(
    _ application: UIApplication,
    continue userActivity: NSUserActivity,
    restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void
  ) -> Bool {
    if userActivity.activityType == NSUserActivityTypeBrowsingWeb {
      emitDeepLink(userActivity.webpageURL)
    }
    return super.application(
      application,
      continue: userActivity,
      restorationHandler: restorationHandler
    )
  }

  private func installDeepLinkBridgeIfPossible() {
    guard let controller = window?.rootViewController as? FlutterViewController else {
      return
    }
    let messenger = controller.binaryMessenger
    let methodChannel = FlutterMethodChannel(
      name: deepLinkMethodChannelName,
      binaryMessenger: messenger
    )
    methodChannel.setMethodCallHandler { [weak self] call, result in
      guard let self else {
        result(nil)
        return
      }
      switch call.method {
      case "getInitialLink":
        let link = self.initialDeepLink ?? self.deepLinkStreamHandler.pendingLink
        self.initialDeepLink = nil
        self.deepLinkStreamHandler.pendingLink = nil
        result(link)
      default:
        result(FlutterMethodNotImplemented)
      }
    }

    let eventChannel = FlutterEventChannel(
      name: deepLinkEventChannelName,
      binaryMessenger: messenger
    )
    eventChannel.setStreamHandler(deepLinkStreamHandler)
  }

  private func emitDeepLink(_ url: URL?) {
    guard let link = normalizeDeepLink(url) else { return }
    deepLinkStreamHandler.emit(link)
  }

  private func normalizeDeepLink(_ url: URL?) -> String? {
    guard let link = url?.absoluteString.trimmingCharacters(in: .whitespacesAndNewlines),
          !link.isEmpty else {
      return nil
    }
    return link
  }

  private func extractInitialDeepLink(
    from launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> String? {
    if let url = launchOptions?[.url] as? URL {
      return normalizeDeepLink(url)
    }
    if let activities = launchOptions?[.userActivityDictionary] as? [AnyHashable: Any] {
      for value in activities.values {
        guard let userActivity = value as? NSUserActivity,
              userActivity.activityType == NSUserActivityTypeBrowsingWeb,
              let link = normalizeDeepLink(userActivity.webpageURL) else {
          continue
        }
        return link
      }
    }
    return nil
  }
}
