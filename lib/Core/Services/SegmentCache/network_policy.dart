import 'package:get/get.dart';
import '../PlaybackIntelligence/playback_policy_engine.dart';
import '../network_awareness_service.dart';

/// Cache sistemi için ağ politikası.
/// NetworkAwarenessService'i sarmalayarak cache-specific kararlar verir.
///
/// Politika:
/// - Wi-Fi: prefetch + on-demand CDN fetch
/// - Cellular: arka plan prefetch kapalı, on-demand segment fetch açık
/// - Offline: sadece cache'den serv et
class CacheNetworkPolicy {
  static PlaybackPolicyEngine? get _engine {
    try {
      return Get.find<PlaybackPolicyEngine>();
    } catch (_) {
      return null;
    }
  }

  /// Wi-Fi'de mi? Prefetch sadece Wi-Fi'de çalışır.
  static bool get canPrefetch {
    final engine = _engine;
    if (engine != null) {
      return engine.snapshot().allowBackgroundPrefetch;
    }
    try {
      return Get.find<NetworkAwarenessService>().isOnWiFi;
    } catch (_) {
      return false;
    }
  }

  /// On-demand CDN fetch izni.
  /// Wi-Fi'de her zaman true.
  /// Cellular'da sadece oynatma anındaki cache-miss segmentleri için true.
  /// (Arka plan prefetch yine canPrefetch ile Wi-Fi'a bağlıdır.)
  static bool get canFetchOnDemand {
    final engine = _engine;
    if (engine != null) {
      return engine.snapshot().allowOnDemandSegmentFetch;
    }
    try {
      final net = Get.find<NetworkAwarenessService>();
      if (net.isOnWiFi) return true;

      // Mobilde oynatma akışını kilitlememek için on-demand segment'e izin ver.
      if (net.isOnCellular) {
        return net.isConnected;
      }
      // Bağlantı var ama tip net çözümlenemiyorsa oynatmayı bloklama.
      return net.isConnected;
    } catch (_) {
      // Fail-open: policy servisleri geç yüklenirse oynatma kilitlenmesin.
      return true;
    }
  }

  /// Playlist fetch izni — playlist'ler küçük olduğu için cellular'da da izin ver.
  /// Segment fetch'ten farklı: m3u8 birkaç KB, segment onlarca MB olabilir.
  static bool get canFetchPlaylist {
    final engine = _engine;
    if (engine != null) {
      return engine.snapshot().allowPlaylistFetch;
    }
    try {
      return Get.find<NetworkAwarenessService>().isConnected;
    } catch (_) {
      return true;
    }
  }

  /// Cache-only mod: cellular veya offline ise segment CDN fetch yapma.
  static bool get cacheOnlyMode {
    final engine = _engine;
    if (engine != null) {
      return engine.snapshot().cacheOnlyMode;
    }
    try {
      final net = Get.find<NetworkAwarenessService>();
      return !net.isOnWiFi; // Wi-Fi değilse sadece cache'den serv et
    } catch (_) {
      return true;
    }
  }

  /// Mobil veri mi?
  static bool get isOnCellular {
    try {
      return Get.find<NetworkAwarenessService>().isOnCellular;
    } catch (_) {
      return false;
    }
  }

  /// Herhangi bir bağlantı var mı? (wifi, cellular, vs)
  static bool get isConnected {
    try {
      return Get.find<NetworkAwarenessService>().isConnected;
    } catch (_) {
      return false;
    }
  }
}
