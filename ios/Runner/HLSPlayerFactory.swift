import Flutter
import UIKit

class HLSPlayerFactory: NSObject, FlutterPlatformViewFactory {
    private var messenger: FlutterBinaryMessenger
    private var eventChannels: [Int64: FlutterEventChannel] = [:]

    init(messenger: FlutterBinaryMessenger) {
        self.messenger = messenger
        super.init()
    }

    func create(
        withFrame frame: CGRect,
        viewIdentifier viewId: Int64,
        arguments args: Any?
    ) -> FlutterPlatformView {
        // Create event channel for this specific player instance
        let eventChannel = FlutterEventChannel(
            name: "turqapp.hls_player/events_\(viewId)",
            binaryMessenger: messenger
        )
        eventChannels[viewId] = eventChannel

        // Create player view
        let playerView = HLSPlayerView(
            frame: frame,
            viewIdentifier: viewId,
            arguments: args,
            binaryMessenger: messenger,
            eventChannel: eventChannel
        )

        // ✅ FIX: Register view with plugin
        // This connects Flutter MethodChannel to Swift view
        HLSPlayerPlugin.shared?.registerView(viewId: viewId, view: playerView)

        return playerView
    }

    func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
        return FlutterStandardMessageCodec.sharedInstance()
    }

    deinit {
        // Clean up event channels
        eventChannels.removeAll()
    }
}
