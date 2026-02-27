import 'package:get/get.dart';
import 'package:turqappv2/hls_player/hls_video_adapter.dart';

/// Uygulama genelinde tek bir aktif ses kaynağı olmasını zorlar.
class AudioFocusCoordinator extends GetxService {
  static AudioFocusCoordinator get instance {
    if (!Get.isRegistered<AudioFocusCoordinator>()) {
      Get.put(AudioFocusCoordinator());
    }
    return Get.find<AudioFocusCoordinator>();
  }

  final Set<HLSVideoAdapter> _players = <HLSVideoAdapter>{};
  HLSVideoAdapter? _activePlayer;

  void register(HLSVideoAdapter player) {
    _players.add(player);
  }

  void unregister(HLSVideoAdapter player) {
    _players.remove(player);
    if (identical(_activePlayer, player)) {
      _activePlayer = null;
    }
  }

  Future<void> requestPlay(HLSVideoAdapter player) async {
    _activePlayer = player;

    final others = _players.where((p) => !identical(p, player)).toList();
    for (final p in others) {
      try {
        await p.pause();
      } catch (_) {}
    }
  }

  void requestPause(HLSVideoAdapter player) {
    if (identical(_activePlayer, player)) {
      _activePlayer = null;
    }
  }
}
