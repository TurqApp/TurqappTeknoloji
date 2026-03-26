import 'package:turqappv2/Core/Services/Ads/ads_feature_flags_service.dart';
import 'package:turqappv2/Core/Services/Ads/ads_admin_guard.dart';
import 'package:turqappv2/Models/Ads/ads_models.dart';

class AdSlotService {
  const AdSlotService();

  AdSlot buildFeedSlot(int index) {
    final enabled = _isEnabledForPlacement(AdPlacementType.feed);
    return AdSlot('feed_$index', AdPlacementType.feed, index, enabled);
  }

  AdSlot buildShortsSlot(int index) {
    final enabled = _isEnabledForPlacement(AdPlacementType.shorts);
    return AdSlot('shorts_$index', AdPlacementType.shorts, index, enabled);
  }

  AdSlot buildExploreSlot(int index) {
    final enabled = _isEnabledForPlacement(AdPlacementType.explore);
    return AdSlot('explore_$index', AdPlacementType.explore, index, enabled);
  }

  bool _isEnabledForPlacement(AdPlacementType _) {
    final flags = ensureAdsFeatureFlagsService().flags.value;
    final allowAdminTest =
        flags.adsAdminTestModeEnabled && AdsAdminGuard.canAccessAdsCenterSync();
    return flags.adsInfrastructureEnabled &&
        flags.adsDeliveryEnabled &&
        (flags.adsPublicVisibilityEnabled || allowAdminTest);
  }
}
