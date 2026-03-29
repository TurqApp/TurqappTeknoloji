import 'package:turqappv2/Core/Services/network_awareness_service.dart';
import 'package:turqappv2/Core/Services/read_budget_registry.dart';

enum ContentScreenKind {
  feed,
  shorts,
  explore,
  story,
  profile,
}

class ContentPolicy {
  static const int feedInitialFromPool =
      ReadBudgetRegistry.feedHomeInitialLimit;
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
    if (screen == ContentScreenKind.feed) return true;
    if (isOnWiFi) return true;
    return !hasLocalContent;
  }

  static int initialPoolLimit(ContentScreenKind screen) {
    if (isOnWiFi) {
      switch (screen) {
        case ContentScreenKind.feed:
          return ReadBudgetRegistry.feedInitialPoolLimit(onWiFi: true);
        case ContentScreenKind.shorts:
          return ReadBudgetRegistry.shortInitialPoolLimit(onWiFi: true);
        case ContentScreenKind.explore:
          return ReadBudgetRegistry.exploreInitialPoolLimit(onWiFi: true);
        case ContentScreenKind.profile:
          return ReadBudgetRegistry.profileInitialPoolLimit(onWiFi: true);
        case ContentScreenKind.story:
          return ReadBudgetRegistry.storyInitialPoolLimit(onWiFi: true);
      }
    }

    switch (screen) {
      case ContentScreenKind.feed:
        return ReadBudgetRegistry.feedInitialPoolLimit(onWiFi: false);
      case ContentScreenKind.shorts:
        return ReadBudgetRegistry.shortInitialPoolLimit(onWiFi: false);
      case ContentScreenKind.explore:
        return ReadBudgetRegistry.exploreInitialPoolLimit(onWiFi: false);
      case ContentScreenKind.profile:
        return ReadBudgetRegistry.profileInitialPoolLimit(onWiFi: false);
      case ContentScreenKind.story:
        return ReadBudgetRegistry.storyInitialPoolLimit(onWiFi: false);
    }
  }
}
