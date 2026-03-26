import 'package:turqappv2/Core/Services/Ads/ads_feature_flags_service.dart';
import 'package:turqappv2/Models/Ads/ads_models.dart';

class AdSlotService {
  const AdSlotService();

  AdSlot buildFeedSlot(int index) {
    final enabled = _isEnabledForPlacement(AdPlacementType.feed);
    return AdSlot(
      slotId: 'feed_$index',
      placement: AdPlacementType.feed,
      indexHint: index,
      enabled: enabled,
    );
  }

  AdSlot buildShortsSlot(int index) {
    final enabled = _isEnabledForPlacement(AdPlacementType.shorts);
    return AdSlot(
      slotId: 'shorts_$index',
      placement: AdPlacementType.shorts,
      indexHint: index,
      enabled: enabled,
    );
  }

  AdSlot buildExploreSlot(int index) {
    final enabled = _isEnabledForPlacement(AdPlacementType.explore);
    return AdSlot(
      slotId: 'explore_$index',
      placement: AdPlacementType.explore,
      indexHint: index,
      enabled: enabled,
    );
  }

  bool _isEnabledForPlacement(AdPlacementType _) {
    final flags = ensureAdsFeatureFlagsService().flags.value;
    // Public visibility kapalıysa kullanıcıya inject etme.
    return flags.adsInfrastructureEnabled &&
        flags.adsDeliveryEnabled &&
        flags.adsPublicVisibilityEnabled;
  }
}
