import 'package:turqappv2/Core/Services/network_awareness_service.dart';

enum ContentScreenKind {
  feed,
  shorts,
  explore,
  story,
  profile,
}

class ContentPolicy {
  static const int feedInitialFromPool = 5;
  static const int mobileWarmWindow = 20;
  static const int mobileNextWindow = 10;
  static const int minGlobalCachedVideos = 50;
  static const int mobileInitialSegments = 2;
  static const int mobileAheadSegments = 3; // n + 3

  static bool get isOnWiFi {
    return NetworkAwarenessService.maybeFind()?.isOnWiFi ?? false;
  }

  static bool get isOnCellular {
    return NetworkAwarenessService.maybeFind()?.isOnCellular ?? false;
  }

  static bool get isConnected {
    return NetworkAwarenessService.maybeFind()?.isConnected ?? false;
  }

  // Kullanıcı kararı: mobilde arka plan güncelleme olmasın.
  static bool allowBackgroundRefresh(ContentScreenKind screen) {
    if (screen == ContentScreenKind.story) {
      return isOnWiFi;
    }
    return isOnWiFi;
  }

  static bool shouldBootstrapNetwork(
    ContentScreenKind screen, {
    required bool hasLocalContent,
  }) {
    if (!isConnected) return false;
    if (isOnWiFi) return true;
    return !hasLocalContent;
  }

  static int initialPoolLimit(ContentScreenKind screen) {
    if (isOnWiFi) {
      switch (screen) {
        case ContentScreenKind.feed:
          return 12;
        case ContentScreenKind.shorts:
        case ContentScreenKind.explore:
        case ContentScreenKind.profile:
          return 30;
        case ContentScreenKind.story:
          return 10;
      }
    }

    switch (screen) {
      case ContentScreenKind.feed:
        return feedInitialFromPool;
      case ContentScreenKind.shorts:
      case ContentScreenKind.explore:
      case ContentScreenKind.profile:
        return mobileWarmWindow;
      case ContentScreenKind.story:
        return 10;
    }
  }
}
