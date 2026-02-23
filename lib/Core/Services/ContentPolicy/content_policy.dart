import 'package:get/get.dart';
import 'package:turqappv2/Core/Services/NetworkAwarenessService.dart';

enum ContentScreenKind {
  feed,
  shorts,
  explore,
  story,
}

class ContentPolicy {
  static const int feedInitialFromPool = 5;
  static const int mobileWarmWindow = 20;
  static const int mobileNextWindow = 10;
  static const int minGlobalCachedVideos = 50;
  static const int mobileInitialSegments = 2;
  static const int mobileAheadSegments = 3; // n + 3

  static bool get isOnWiFi {
    try {
      return Get.find<NetworkAwarenessService>().isOnWiFi;
    } catch (_) {
      return false;
    }
  }

  static bool get isOnCellular {
    try {
      return Get.find<NetworkAwarenessService>().isOnCellular;
    } catch (_) {
      return false;
    }
  }

  static bool get isConnected {
    try {
      return Get.find<NetworkAwarenessService>().isConnected;
    } catch (_) {
      return false;
    }
  }

  // Kullanıcı kararı: mobilde arka plan güncelleme olmasın.
  static bool allowBackgroundRefresh(ContentScreenKind screen) {
    if (screen == ContentScreenKind.story) {
      return isOnWiFi;
    }
    return isOnWiFi;
  }
}
