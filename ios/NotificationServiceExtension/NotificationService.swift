import Foundation
import UserNotifications

final class NotificationService: UNNotificationServiceExtension {
  private var contentHandler: ((UNNotificationContent) -> Void)?
  private var bestAttemptContent: UNMutableNotificationContent?
  private var downloadTask: URLSessionDataTask?

  override func didReceive(
    _ request: UNNotificationRequest,
    withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void
  ) {
    self.contentHandler = contentHandler
    bestAttemptContent = (request.content.mutableCopy() as? UNMutableNotificationContent)

    guard let bestAttemptContent else {
      contentHandler(request.content)
      return
    }

    guard let imageUrlString = extractImageURL(from: request.content.userInfo),
          let imageURL = URL(string: imageUrlString) else {
      contentHandler(bestAttemptContent)
      return
    }

    downloadTask = URLSession.shared.dataTask(with: imageURL) { [weak self] data, response, _ in
      guard let self else { return }
      defer { self.contentHandler?(bestAttemptContent) }

      guard let data,
            let response,
            let mimeType = response.mimeType,
            let fileExtension = Self.fileExtension(for: mimeType) else {
        return
      }

      let tempURL = URL(fileURLWithPath: NSTemporaryDirectory())
        .appendingPathComponent(UUID().uuidString)
        .appendingPathExtension(fileExtension)

      do {
        try data.write(to: tempURL)
        let attachment = try UNNotificationAttachment(
          identifier: "post-image",
          url: tempURL,
          options: nil
        )
        bestAttemptContent.attachments = [attachment]
      } catch {
        return
      }
    }
    downloadTask?.resume()
  }

  override func serviceExtensionTimeWillExpire() {
    downloadTask?.cancel()
    if let bestAttemptContent {
      contentHandler?(bestAttemptContent)
    }
  }

  private func extractImageURL(from userInfo: [AnyHashable: Any]) -> String? {
    if let direct = userInfo["imageUrl"] as? String, !direct.isEmpty {
      return direct
    }

    if let fcmOptions = userInfo["fcm_options"] as? [String: Any],
       let image = fcmOptions["image"] as? String,
       !image.isEmpty {
      return image
    }

    return nil
  }

  private static func fileExtension(for mimeType: String) -> String? {
    switch mimeType.lowercased() {
    case "image/jpeg", "image/jpg":
      return "jpg"
    case "image/png":
      return "png"
    case "image/gif":
      return "gif"
    case "image/webp":
      return "webp"
    default:
      return nil
    }
  }
}
