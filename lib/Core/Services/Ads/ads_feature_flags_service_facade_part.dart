part of 'ads_feature_flags_service.dart';

AdsFeatureFlagsService? maybeFindAdsFeatureFlagsService() {
  final isRegistered = Get.isRegistered<AdsFeatureFlagsService>();
  if (!isRegistered) return null;
  return Get.find<AdsFeatureFlagsService>();
}

AdsFeatureFlagsService ensureAdsFeatureFlagsService({
  bool permanent = false,
}) {
  final existing = maybeFindAdsFeatureFlagsService();
  if (existing != null) return existing;
  return Get.put(
    AdsFeatureFlagsService(),
    permanent: permanent,
  );
}
