part of 'admob_banner_warmup_service.dart';

AdmobBannerWarmupService? maybeFindAdmobBannerWarmupService() {
  final isRegistered = Get.isRegistered<AdmobBannerWarmupService>();
  if (!isRegistered) return null;
  return Get.find<AdmobBannerWarmupService>();
}

AdmobBannerWarmupService ensureAdmobBannerWarmupService() {
  final existing = maybeFindAdmobBannerWarmupService();
  if (existing != null) return existing;
  return Get.put(AdmobBannerWarmupService(), permanent: true);
}
