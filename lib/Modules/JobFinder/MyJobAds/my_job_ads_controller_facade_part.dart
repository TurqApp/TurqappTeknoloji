part of 'my_job_ads_controller.dart';

MyJobAdsController ensureMyJobAdsController({
  String? tag,
  bool permanent = false,
}) {
  final existing = maybeFindMyJobAdsController(tag: tag);
  if (existing != null) return existing;
  return Get.put(
    MyJobAdsController(),
    tag: tag,
    permanent: permanent,
  );
}

MyJobAdsController? maybeFindMyJobAdsController({String? tag}) {
  final isRegistered = Get.isRegistered<MyJobAdsController>(tag: tag);
  if (!isRegistered) return null;
  return Get.find<MyJobAdsController>(tag: tag);
}
