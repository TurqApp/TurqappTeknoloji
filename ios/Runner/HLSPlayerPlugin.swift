import Flutter
import UIKit

public class HLSPlayerPlugin: NSObject, FlutterPlugin {
    // ✅ FIX: Singleton for Factory access
    static var shared: HLSPlayerPlugin?

    private var playerViews: [Int64: HLSPlayerView] = [:]
    private var methodChannel: FlutterMethodChannel?

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: "turqapp.hls_player/method",
            binaryMessenger: registrar.messenger()
        )

        let instance = HLSPlayerPlugin()
        instance.methodChannel = channel
        registrar.addMethodCallDelegate(instance, channel: channel)

        // ✅ FIX: Store shared instance for Factory
        HLSPlayerPlugin.shared = instance

        // Register platform view factory
        let factory = HLSPlayerFactory(messenger: registrar.messenger())
        registrar.register(
            factory,
            withId: "turqapp.hls_player/view"
        )
    }

    // Factory same module'de çağırıyor; public olmasına gerek yok.
    func registerView(viewId: Int64, view: HLSPlayerView) {
        playerViews[viewId] = view
        print("[HLSPlayerPlugin] Registered view \(viewId)")
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        if call.method == "getActiveSmokeSnapshot" {
            result([
                "supported": false,
                "active": false,
                "firstFrameRendered": false,
                "errors": [],
                "raw": ""
            ])
            return
        }

        guard let args = call.arguments as? [String: Any],
              let viewId = args["viewId"] as? Int64 else {
            result(FlutterError(
                code: "INVALID_ARGUMENTS",
                message: "ViewId is required",
                details: nil
            ))
            return
        }

        switch call.method {
        case "loadVideo":
            handleLoadVideo(args: args, viewId: viewId, result: result)

        case "play":
            handlePlay(viewId: viewId, result: result)

        case "pause":
            handlePause(viewId: viewId, result: result)

        case "seek":
            handleSeek(args: args, viewId: viewId, result: result)

        case "setMuted":
            handleSetMuted(args: args, viewId: viewId, result: result)

        case "setVolume":
            handleSetVolume(args: args, viewId: viewId, result: result)

        case "setLoop":
            handleSetLoop(args: args, viewId: viewId, result: result)

        case "getCurrentTime":
            handleGetCurrentTime(viewId: viewId, result: result)

        case "getDuration":
            handleGetDuration(viewId: viewId, result: result)

        case "isMuted":
            handleIsMuted(viewId: viewId, result: result)

        case "isPlaying":
            handleIsPlaying(viewId: viewId, result: result)

        case "isBuffering":
            handleIsBuffering(viewId: viewId, result: result)

        case "getPlaybackDiagnostics":
            handleGetPlaybackDiagnostics(viewId: viewId, result: result)

        case "getProcessDiagnostics":
            handleGetProcessDiagnostics(viewId: viewId, result: result)

        case "stopPlayback":
            handleStopPlayback(viewId: viewId, result: result)

        case "setPreferredBufferDuration":
            handleSetPreferredBufferDuration(args: args, viewId: viewId, result: result)

        case "dispose":
            handleDispose(viewId: viewId, result: result)

        default:
            result(FlutterMethodNotImplemented)
        }
    }

    // MARK: - Method Handlers

    private func handleLoadVideo(args: [String: Any], viewId: Int64, result: FlutterResult) {
        guard let url = args["url"] as? String,
              let playerView = playerViews[viewId] else {
            result(FlutterError(
                code: playerViews[viewId] == nil ? "NO_PLAYER" : "INVALID_ARGUMENTS",
                message: playerViews[viewId] == nil ? "Player view not found" : "URL is required",
                details: nil
            ))
            return
        }

        playerView.loadVideo(url: url)
        result(nil)
    }

    private func handlePlay(viewId: Int64, result: FlutterResult) {
        guard let playerView = playerViews[viewId] else {
            result(FlutterError(
                code: "NO_PLAYER",
                message: "Player view not found for viewId: \(viewId)",
                details: nil
            ))
            return
        }

        playerView.play()
        result(nil)
    }

    private func handlePause(viewId: Int64, result: FlutterResult) {
        guard let playerView = playerViews[viewId] else {
            result(FlutterError(
                code: "NO_PLAYER",
                message: "Player view not found",
                details: nil
            ))
            return
        }

        playerView.pause()
        result(nil)
    }

    private func handleSeek(args: [String: Any], viewId: Int64, result: FlutterResult) {
        guard let playerView = playerViews[viewId],
              let seconds = args["seconds"] as? Double else {
            result(FlutterError(
                code: "INVALID_ARGUMENTS",
                message: "Seconds parameter is required",
                details: nil
            ))
            return
        }

        playerView.seek(to: seconds)
        result(nil)
    }

    private func handleSetMuted(args: [String: Any], viewId: Int64, result: FlutterResult) {
        guard let playerView = playerViews[viewId],
              let muted = args["muted"] as? Bool else {
            result(FlutterError(
                code: "INVALID_ARGUMENTS",
                message: "Muted parameter is required",
                details: nil
            ))
            return
        }

        playerView.setMuted(muted)
        result(nil)
    }

    private func handleSetVolume(args: [String: Any], viewId: Int64, result: FlutterResult) {
        guard let playerView = playerViews[viewId],
              let volume = args["volume"] as? Double else {
            result(FlutterError(
                code: "INVALID_ARGUMENTS",
                message: "Volume parameter is required",
                details: nil
            ))
            return
        }

        playerView.setVolume(volume)
        result(nil)
    }

    private func handleSetLoop(args: [String: Any], viewId: Int64, result: FlutterResult) {
        guard let playerView = playerViews[viewId],
              let loop = args["loop"] as? Bool else {
            result(FlutterError(
                code: "INVALID_ARGUMENTS",
                message: "Loop parameter is required",
                details: nil
            ))
            return
        }

        playerView.setLoop(loop)
        result(nil)
    }

    private func handleGetCurrentTime(viewId: Int64, result: FlutterResult) {
        guard let playerView = playerViews[viewId] else {
            result(FlutterError(
                code: "NO_PLAYER",
                message: "Player view not found",
                details: nil
            ))
            return
        }

        result(playerView.getCurrentTime())
    }

    private func handleGetDuration(viewId: Int64, result: FlutterResult) {
        guard let playerView = playerViews[viewId] else {
            result(FlutterError(
                code: "NO_PLAYER",
                message: "Player view not found",
                details: nil
            ))
            return
        }

        result(playerView.getDuration())
    }

    private func handleIsMuted(viewId: Int64, result: FlutterResult) {
        guard let playerView = playerViews[viewId] else {
            result(FlutterError(
                code: "NO_PLAYER",
                message: "Player view not found",
                details: nil
            ))
            return
        }

        result(playerView.isMuted())
    }

    private func handleIsPlaying(viewId: Int64, result: FlutterResult) {
        guard let playerView = playerViews[viewId] else {
            result(FlutterError(
                code: "NO_PLAYER",
                message: "Player view not found",
                details: nil
            ))
            return
        }

        result(playerView.isPlaying())
    }

    private func handleIsBuffering(viewId: Int64, result: FlutterResult) {
        guard let playerView = playerViews[viewId] else {
            result(FlutterError(
                code: "NO_PLAYER",
                message: "Player view not found",
                details: nil
            ))
            return
        }

        result(playerView.isBuffering())
    }

    private func handleGetPlaybackDiagnostics(viewId: Int64, result: FlutterResult) {
        guard let playerView = playerViews[viewId] else {
            result(FlutterError(
                code: "NO_PLAYER",
                message: "Player view not found",
                details: nil
            ))
            return
        }

        result(playerView.getPlaybackDiagnostics())
    }

    private func handleGetProcessDiagnostics(viewId: Int64, result: FlutterResult) {
        guard let playerView = playerViews[viewId] else {
            result(FlutterError(
                code: "NO_PLAYER",
                message: "Player view not found",
                details: nil
            ))
            return
        }

        result(playerView.getProcessDiagnostics())
    }

    private func handleStopPlayback(viewId: Int64, result: FlutterResult) {
        guard let playerView = playerViews[viewId] else {
            result(FlutterError(code: "NO_PLAYER", message: "Player view not found", details: nil))
            return
        }
        playerView.stopPlayback()
        result(nil)
    }

    private func handleSetPreferredBufferDuration(args: [String: Any], viewId: Int64, result: FlutterResult) {
        guard let playerView = playerViews[viewId],
              let duration = args["duration"] as? Double else {
            result(FlutterError(code: "INVALID_ARGUMENTS", message: "duration parameter is required", details: nil))
            return
        }
        playerView.setPreferredBufferDuration(duration)
        result(nil)
    }

    private func handleDispose(viewId: Int64, result: FlutterResult) {
        if let playerView = playerViews[viewId] {
            playerView.dispose()
            playerViews.removeValue(forKey: viewId)
            print("[HLSPlayerPlugin] Disposed view \(viewId)")
        }
        result(nil)
    }

    deinit {
        // Clean up all player views
        playerViews.values.forEach { $0.dispose() }
        playerViews.removeAll()
    }
}
