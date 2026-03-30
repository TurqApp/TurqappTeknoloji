import 'package:turqappv2/Core/Services/AppPolicy/surface_policy.dart';
import 'package:turqappv2/Core/Services/AppPolicy/surface_policy_registry.dart';
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
  static int get feedInitialFromPool =>
      ReadBudgetRegistry.feedHomeInitialLimitValue;
  static int get mobileWarmWindow => ReadBudgetRegistry.mobileWarmWindow;
  static int get mobileNextWindow => ReadBudgetRegistry.mobileNextWindow;
  static int get minGlobalCachedVideos =>
      ReadBudgetRegistry.minGlobalCachedVideos;
  static int get mobileInitialSegments =>
      ReadBudgetRegistry.mobileInitialSegments;
  static int get mobileAheadSegments => ReadBudgetRegistry.mobileAheadSegments;

  static bool get isOnWiFi {
    return NetworkAwarenessService.maybeFind()?.isOnWiFi ?? false;
  }

  static bool get isOnCellular {
    return NetworkAwarenessService.maybeFind()?.isOnCellular ?? false;
  }

  static bool get isConnected {
    return NetworkAwarenessService.maybeFind()?.isConnected ?? false;
  }

  static SurfacePolicy _surfacePolicy(ContentScreenKind screen) {
    switch (screen) {
      case ContentScreenKind.feed:
        return SurfacePolicyRegistry.feedHomeSurface;
      case ContentScreenKind.shorts:
        return SurfacePolicyRegistry.shortHomeSurface;
      case ContentScreenKind.explore:
        return SurfacePolicyRegistry.exploreSurface;
      case ContentScreenKind.story:
        return SurfacePolicyRegistry.storySurface;
      case ContentScreenKind.profile:
        return SurfacePolicyRegistry.profilePostsSurface;
    }
  }

  static bool allowBackgroundRefresh(ContentScreenKind screen) {
    return _surfacePolicy(screen).allowBackgroundRefresh(onWiFi: isOnWiFi);
  }

  static bool shouldBootstrapNetwork(
    ContentScreenKind screen, {
    required bool hasLocalContent,
  }) {
    return _surfacePolicy(screen).shouldBootstrapNetwork(
      isConnected: isConnected,
      onWiFi: isOnWiFi,
      hasLocalContent: hasLocalContent,
    );
  }

  static int initialPoolLimit(ContentScreenKind screen) {
    return _surfacePolicy(screen).initialPoolLimitFor(onWiFi: isOnWiFi);
  }
}
