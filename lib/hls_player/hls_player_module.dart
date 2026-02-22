/// HLS Video Player Module
///
/// Native iOS AVPlayer tabanlı, production-ready HLS video oynatıcı modülü.
///
/// Kullanım:
/// ```dart
/// import 'package:turqappv2/hls_player/hls_player_module.dart';
///
/// final controller = HLSController();
///
/// HLSPlayer(
///   url: 'https://example.com/video.m3u8',
///   controller: controller,
/// )
/// ```

library;

// Core exports
export 'hls_controller.dart';
export 'hls_player.dart';

// Example export
export 'hls_player_example.dart';
