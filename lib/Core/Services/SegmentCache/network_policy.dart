import 'package:get/get.dart';
import 'package:turqappv2/Core/Services/ContentPolicy/content_policy.dart';
import 'cache_manager.dart';
import '../network_awareness_service.dart';

/// Cache sistemi için ağ politikası.
/// NetworkAwarenessService'i sarmalayarak cache-specific kararlar verir.
///
/// Politika:
/// - Wi-Fi: prefetch + on-demand CDN fetch
/// - Cellular: sadece cache'den serv et (cache miss = oynatma yok)
/// - Offline: sadece cache'den serv et
class CacheNetworkPolicy {
  /// Wi-Fi'de mi? Prefetch sadece Wi-Fi'de çalışır.
  static bool get canPrefetch {
    try {
      return Get.find<NetworkAwarenessService>().isOnWiFi;
    } catch (_) {
      return false;
    }
  }

  /// On-demand CDN fetch izni.
  /// SADECE Wi-Fi'de true — mobil veride cache miss olursa CDN'e gitmez.
  static bool get canFetchOnDemand {
    try {
      final net = Get.find<NetworkAwarenessService>();
      if (net.isOnWiFi) return true;

      // Mobilde istisna: keş 50 videonun altındaysa, izlenen videodan
      // gelen anlık segment isteğine izin ver (izledikçe keş dolsun).
      if (net.isOnCellular) {

        // Cache manager henüz ayağa kalkmadıysa bootstrap için izin ver.
        if (!Get.isRegistered<SegmentCacheManager>()) {
          return true;
        }
        final cache = Get.find<SegmentCacheManager>();
        return cache.cachedVideoCount < ContentPolicy.minGlobalCachedVideos;
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
    try {
      return Get.find<NetworkAwarenessService>().isConnected;
    } catch (_) {
      return true;
    }
  }

  /// Cache-only mod: cellular veya offline ise segment CDN fetch yapma.
  static bool get cacheOnlyMode {
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
