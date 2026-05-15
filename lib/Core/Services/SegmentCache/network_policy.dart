import '../PlaybackIntelligence/playback_policy_engine.dart';
import '../network_awareness_service.dart';

/// Cache sistemi için ağ politikası.
/// NetworkAwarenessService'i sarmalayarak cache-specific kararlar verir.
///
/// Politika:
/// - Connected network: prefetch + on-demand CDN fetch
/// - Offline: sadece cache'den serv et
class CacheNetworkPolicy {
  static PlaybackPolicyEngine? get _engine => maybeFindPlaybackPolicyEngine();

  /// Playback cache davranisi icin her bagli ag Wi-Fi gibi davranir.
  /// Kota ve data usage tarafinda actual cellular bilgisi ayrica korunur.
  static bool get canPrefetch {
    final engine = _engine;
    if (engine != null) {
      return engine.snapshot().allowBackgroundPrefetch;
    }
    return NetworkAwarenessService.maybeFind()?.isConnected ?? false;
  }

  static PlaybackPolicySnapshot? get currentSnapshot {
    final engine = _engine;
    if (engine == null) return null;
    return engine.snapshot();
  }

  static bool get usesWifiPlaybackBehavior {
    final engine = _engine;
    if (engine != null) {
      final snapshot = engine.snapshot();
      return snapshot.allowBackgroundPrefetch && !snapshot.cacheOnlyMode;
    }
    return NetworkAwarenessService.maybeFind()?.isConnected ?? false;
  }

  /// On-demand CDN fetch izni.
  /// Her bagli agda oynatma akisini Wi-Fi gibi kilitsiz tut.
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
    return net.isConnected;
  }

  /// Playlist fetch izni.
  static bool get canFetchPlaylist {
    final engine = _engine;
    if (engine != null) {
      return engine.snapshot().allowPlaylistFetch;
    }
    return NetworkAwarenessService.maybeFind()?.isConnected ?? true;
  }

  /// Cache-only mod sadece offline icin.
  static bool get cacheOnlyMode {
    final engine = _engine;
    if (engine != null) {
      return engine.snapshot().cacheOnlyMode;
    }
    final net = NetworkAwarenessService.maybeFind();
    if (net == null) return true;
    if (!net.isConnected) return true;
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
