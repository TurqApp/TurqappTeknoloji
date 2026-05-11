import UIKit

final class PlaybackHealthStore {
    static let shared = PlaybackHealthStore()

    private let labelIdentifier = "playbackHealthStatusLabel"
    private weak var statusLabel: UILabel?
    private weak var activeMonitor: PlaybackHealthMonitor?
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

    func activate(
        monitor: PlaybackHealthMonitor,
        snapshot: [String: Any]? = nil
    ) {
        activeMonitor = monitor
        if let snapshot {
            update(monitor: monitor, errors: monitor.getErrors(), snapshot: snapshot)
        }
    }

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

    func update(
        monitor: PlaybackHealthMonitor,
        errors: [String],
        snapshot: [String: Any] = [:]
    ) {
        guard let activeMonitor, activeMonitor === monitor else {
            return
        }
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

    func updateVisualPhase(_ payload: [String: Any]) {
        var merged = lastSnapshot
        let now = Int64(Date().timeIntervalSince1970 * 1000.0)
        let phaseStartedAt = payload["phaseStartedAtEpochMs"] as? Int64 ?? now
        merged["supported"] = true
        merged["active"] = true
        merged["visualPhase"] = payload["phase"] as? String ?? ""
        merged["visualPhaseSource"] = payload["source"] as? String ?? ""
        merged["visualPhaseStartedAtEpochMs"] = phaseStartedAt
        merged["visualPhaseDurationMs"] = max(Int64(0), now - phaseStartedAt)
        merged["overlayVisible"] = payload["overlayVisible"] as? Bool ?? false
        merged["preferResumePoster"] = payload["preferResumePoster"] as? Bool ?? false
        merged["didRenderFirstFrame"] = payload["didRenderFirstFrame"] as? Bool ?? false
        merged["url"] = payload["url"] as? String ?? ""
        merged["raw"] = "\(merged)"
        lastSnapshot = merged
    }

    func clear(monitor: PlaybackHealthMonitor? = nil) {
        if let monitor, let activeMonitor, activeMonitor !== monitor {
            return
        }
        activeMonitor = nil
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
