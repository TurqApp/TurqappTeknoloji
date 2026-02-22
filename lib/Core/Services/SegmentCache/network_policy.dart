import 'package:get/get.dart';
import '../NetworkAwarenessService.dart';

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
      return Get.find<NetworkAwarenessService>().isOnWiFi;
    } catch (_) {
      return false;
    }
  }

  /// Playlist fetch izni — playlist'ler küçük olduğu için cellular'da da izin ver.
  /// Segment fetch'ten farklı: m3u8 birkaç KB, segment onlarca MB olabilir.
  static bool get canFetchPlaylist {
    try {
      return Get.find<NetworkAwarenessService>().isConnected;
    } catch (_) {
      return false;
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
