import Foundation
import ImageIO
import UIKit
import UniformTypeIdentifiers
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

    downloadTask = URLSession.shared.dataTask(with: imageURL) { [weak self] data, _, _ in
      guard let self else { return }
      defer { self.contentHandler?(bestAttemptContent) }

      guard let data else {
        return
      }

      let prepared = Self.preparedImageData(
        from: data,
        originalExtension: imageURL.pathExtension
      )
      guard let fileData = prepared.data else {
        return
      }

      let tempURL = URL(fileURLWithPath: NSTemporaryDirectory())
        .appendingPathComponent(UUID().uuidString)
        .appendingPathExtension(prepared.fileExtension)

      do {
        try fileData.write(to: tempURL)
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

  private static func preparedImageData(
    from data: Data,
    originalExtension: String
  ) -> (data: Data?, fileExtension: String) {
    if let image = Self.decodedImage(from: data) {
      if let jpeg = image.jpegData(compressionQuality: 0.92) {
        return (jpeg, "jpg")
      }
      if let png = image.pngData() {
        return (png, "png")
      }
    }
    let normalizedExtension = originalExtension.trimmingCharacters(
      in: .whitespacesAndNewlines
    ).lowercased()
    return (data, normalizedExtension.isEmpty ? "jpg" : normalizedExtension)
  }

  private static func decodedImage(from data: Data) -> UIImage? {
    if let image = UIImage(data: data) {
      return image
    }

    guard let source = CGImageSourceCreateWithData(data as CFData, nil),
          let cgImage = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
      return nil
    }

    return UIImage(cgImage: cgImage)
  }
}
