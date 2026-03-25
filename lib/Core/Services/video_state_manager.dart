import 'dart:async';

import 'package:get/get.dart';
import 'package:video_player/video_player.dart';
import 'package:turqappv2/Core/Services/playback_handle.dart';
import 'package:turqappv2/Core/Services/audio_focus_coordinator.dart';

part 'video_state_manager_playback_part.dart';
part 'video_state_manager_facade_part.dart';
part 'video_state_manager_models_part.dart';

/// Instagram tarzı akıcı video deneyimi için video durumu yöneticisi
/// Her videonun oynatma pozisyonunu ve durumunu bellekte tutar
class VideoStateManager extends GetxController {
  static VideoStateManager? maybeFind() {
    final isRegistered = Get.isRegistered<VideoStateManager>();
    if (!isRegistered) return null;
    return Get.find<VideoStateManager>();
  }

  static VideoStateManager ensure() {
    final existing = maybeFind();
    if (existing != null) return existing;
    return Get.put(VideoStateManager());
  }

  static VideoStateManager get instance {
    return ensure();
  }

  // Video docID -> VideoState mapping
  final Map<String, VideoState> _videoStates = {};

  // TÜM video controller'ları track et (PlaybackHandle abstract)
  // Max 30 entry — daha eski kayıtlar LRU mantığıyla silinir (bellek sızıntısı önleme)
  static const int _maxTrackedControllers = 30;
  final Map<String, PlaybackHandle> _allVideoControllers = {};

  // GLOBAL VIDEO CONTROL: Şu anda çalan video
  String? _currentPlayingDocID;
  bool _exclusiveMode = false;
  String? _exclusiveDocID;
  Timer? _pendingPlayTimer;
  static const Duration _playResumeDelay = Duration(milliseconds: 140);
  int _playRequestSeq = 0;

  /// Şu anda çalan video ID'sini döndür
  String? get currentPlayingDocID => _currentPlayingDocID;

  @override
  void onClose() {
    _pendingPlayTimer?.cancel();
    _pendingPlayTimer = null;
    super.onClose();
  }
}
