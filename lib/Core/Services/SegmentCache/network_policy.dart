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
  static PlaybackPolicyEngine? get _engine => maybeFindPlaybackPolicyEngine();

  /// Wi-Fi'de mi? Prefetch sadece Wi-Fi'de çalışır.
  static bool get canPrefetch {
    final engine = _engine;
    if (engine != null) {
      return engine.snapshot().allowBackgroundPrefetch;
    }
    return NetworkAwarenessService.maybeFind()?.isOnWiFi ?? false;
  }

  static PlaybackPolicySnapshot? get currentSnapshot {
    final engine = _engine;
    if (engine == null) return null;
    return engine.snapshot();
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
    final net = NetworkAwarenessService.maybeFind();
    if (net == null) {
      // Fail-open: policy servisleri geç yüklenirse oynatma kilitlenmesin.
      return true;
    }
    if (net.isOnWiFi) return true;

    // Mobilde oynatma akışını kilitlememek için on-demand segment'e izin ver.
    if (net.isOnCellular) {
      return net.isConnected;
    }
    // Bağlantı var ama tip net çözümlenemiyorsa oynatmayı bloklama.
    return net.isConnected;
  }

  /// Playlist fetch izni — playlist'ler küçük olduğu için cellular'da da izin ver.
  /// Segment fetch'ten farklı: m3u8 birkaç KB, segment onlarca MB olabilir.
  static bool get canFetchPlaylist {
    final engine = _engine;
    if (engine != null) {
      return engine.snapshot().allowPlaylistFetch;
    }
    return NetworkAwarenessService.maybeFind()?.isConnected ?? true;
  }

  /// Cache-only mod: offline veya kullanici mobil veride durdurduysa segment CDN fetch yapma.
  static bool get cacheOnlyMode {
    final engine = _engine;
    if (engine != null) {
      return engine.snapshot().cacheOnlyMode;
    }
    final net = NetworkAwarenessService.maybeFind();
    if (net == null) return true;
    if (!net.isConnected) return true;
    if (net.isOnWiFi) return false;
    if (net.isOnCellular) {
      return net.settings.pauseOnCellular;
    }
    return false;
  }

  static String get playlistFetchBlockedReason {
    final snapshot = currentSnapshot;
    if (snapshot != null) {
      if (snapshot.mode == PlaybackMode.offlineGuard) {
        return 'Offline - playlist not cached';
      }
      return 'Playback policy blocked playlist fetch';
    }
    return 'Offline - playlist not cached';
  }

  static String get segmentFetchBlockedReason {
    final snapshot = currentSnapshot;
    if (snapshot != null) {
      if (snapshot.mode == PlaybackMode.offlineGuard) {
        return 'Offline - segment not cached';
      }
      if (snapshot.cacheOnlyMode) {
        return 'Cache-only mode - segment not cached';
      }
      if (snapshot.mode == PlaybackMode.cellularGuard) {
        return 'Cellular guard blocked segment fetch';
      }
      return 'Playback policy blocked segment fetch';
    }
    return cacheOnlyMode
        ? 'Cache-only mode - segment not cached'
        : 'Segment fetch blocked by policy';
  }

  /// Mobil veri mi?
  static bool get isOnCellular {
    return NetworkAwarenessService.maybeFind()?.isOnCellular ?? false;
  }

  /// Herhangi bir bağlantı var mı? (wifi, cellular, vs)
  static bool get isConnected {
    return NetworkAwarenessService.maybeFind()?.isConnected ?? false;
  }
}
