part of 'admob_banner_warmup_service.dart';

AdmobBannerWarmupService? maybeFindAdmobBannerWarmupService() =>
    Get.isRegistered<AdmobBannerWarmupService>()
        ? Get.find<AdmobBannerWarmupService>()
        : null;

AdmobBannerWarmupService ensureAdmobBannerWarmupService() =>
    maybeFindAdmobBannerWarmupService() ??
    Get.put(AdmobBannerWarmupService(), permanent: true);
