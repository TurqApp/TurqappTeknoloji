import UIKit

final class PlaybackHealthStore {
    static let shared = PlaybackHealthStore()

    private let labelIdentifier = "playbackHealthStatusLabel"
    private weak var statusLabel: UILabel?
    private(set) var currentErrors = [String]()
    private(set) var currentStatus = "OK"
    private var lastSnapshot: [String: Any] = [
        "supported": true,
        "active": false,
        "firstFrameRendered": false,
        "errors": [String](),
        "status": "OK",
        "raw": ""
    ]

    private init() {}

    func installDebugLabelIfNeeded() {
        DispatchQueue.main.async {
            if let label = self.statusLabel, label.superview != nil {
                self.syncLabel(label, status: self.currentStatus)
                return
            }
            guard let window = Self.keyWindow() else { return }

            let label = UILabel(frame: CGRect(x: 0, y: 0, width: 2, height: 2))
            label.isAccessibilityElement = true
            label.accessibilityIdentifier = self.labelIdentifier
            label.accessibilityTraits = .staticText
            label.text = self.currentStatus
            label.textColor = .clear
            label.backgroundColor = .clear
            label.alpha = 0.02
            label.clipsToBounds = true
            window.addSubview(label)
            self.statusLabel = label
            self.syncLabel(label, status: self.currentStatus)
        }
    }

    func update(errors: [String], snapshot: [String: Any] = [:]) {
        currentErrors = NSOrderedSet(array: errors).array as? [String] ?? errors
        currentStatus = currentErrors.isEmpty ? "OK" : currentErrors.joined(separator: "|")
        var merged = snapshot
        merged["supported"] = true
        merged["active"] = true
        merged["errors"] = currentErrors
        merged["status"] = currentStatus
        merged["firstFrameRendered"] = snapshot["hasRenderedFirstFrame"] as? Bool ?? false
        merged["raw"] = "\(snapshot)"
        lastSnapshot = merged

        DispatchQueue.main.async {
            self.installDebugLabelIfNeeded()
            if let label = self.statusLabel {
                self.syncLabel(label, status: self.currentStatus)
            }
        }
    }

    func clear() {
        currentErrors.removeAll()
        currentStatus = "OK"
        lastSnapshot = [
            "supported": true,
            "active": false,
            "firstFrameRendered": false,
            "errors": [String](),
            "status": "OK",
            "raw": ""
        ]
        DispatchQueue.main.async {
            self.installDebugLabelIfNeeded()
            if let label = self.statusLabel {
                self.syncLabel(label, status: "OK")
            }
        }
    }

    func snapshot() -> [String: Any] {
        lastSnapshot
    }

    private static func keyWindow() -> UIWindow? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first(where: \.isKeyWindow)
    }

    private func syncLabel(_ label: UILabel, status: String) {
        label.text = status
        label.accessibilityLabel = status
        label.accessibilityValue = status
    }
}
