import 'package:cloud_functions/cloud_functions.dart';
import 'package:turqappv2/Models/Ads/ads_models.dart';

class AdsAnalyticsService {
  const AdsAnalyticsService();

  static final Set<String> _managedViewKeys = <String>{};

  Future<void> logEvent({
    required AdAnalyticsEventType event,
    required String campaignId,
    required String creativeId,
    required AdPlacementType placement,
    required bool isPreview,
    String userId = '',
    String destinationUrl = '',
    Map<String, dynamic>? extras,
  }) async {
    final payload = {
      'event': enumToShort(event),
      'campaignId': campaignId,
      'creativeId': creativeId,
      'placement': enumToShort(placement),
      'isPreview': isPreview,
      'userId': userId,
      'destinationUrl': destinationUrl,
      'extras': extras ?? const <String, dynamic>{},
    };

    try {
      await FirebaseFunctions.instanceFor(region: 'europe-west3')
          .httpsCallable('adsLogEvent')
          .call(payload);
    } catch (_) {
      // Güvenlik sebebiyle client-side fallback yazımı yok.
    }
  }

  Future<void> logImpression({
    required String campaignId,
    required String creativeId,
    required AdPlacementType placement,
    required bool isPreview,
    String userId = '',
  }) {
    return logEvent(
      event: AdAnalyticsEventType.impression,
      campaignId: campaignId,
      creativeId: creativeId,
      placement: placement,
      isPreview: isPreview,
      userId: userId,
    );
  }

  Future<void> logClick({
    required String campaignId,
    required String creativeId,
    required AdPlacementType placement,
    required bool isPreview,
    String destinationUrl = '',
    String userId = '',
  }) {
    return logEvent(
      event: AdAnalyticsEventType.click,
      campaignId: campaignId,
      creativeId: creativeId,
      placement: placement,
      isPreview: isPreview,
      destinationUrl: destinationUrl,
      userId: userId,
    );
  }

  Future<void> logManagedSliderView({
    required String sliderId,
    required String itemId,
    required String surfaceId,
    required String sourceType,
  }) async {
    final cleanSliderId = sliderId.trim();
    final cleanItemId = itemId.trim();
    final cleanSurfaceId = surfaceId.trim();
    final cleanSourceType = sourceType.trim();
    if (cleanSliderId.isEmpty ||
        cleanItemId.isEmpty ||
        cleanSurfaceId.isEmpty ||
        cleanSourceType.isEmpty) {
      return;
    }

    final viewKey =
        '$cleanSourceType::$cleanSurfaceId::$cleanSliderId::$cleanItemId';
    if (_managedViewKeys.contains(viewKey)) {
      return;
    }
    _managedViewKeys.add(viewKey);

    try {
      await FirebaseFunctions.instanceFor(region: 'europe-west3')
          .httpsCallable('adsLogManagedSliderView')
          .call({
        'sliderId': cleanSliderId,
        'itemId': cleanItemId,
        'surfaceId': cleanSurfaceId,
        'sourceType': cleanSourceType,
      });
    } catch (_) {
      _managedViewKeys.remove(viewKey);
    }
  }
}
