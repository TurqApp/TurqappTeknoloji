import 'dart:async';

import 'package:get/get.dart';
import 'package:turqappv2/Core/Services/Ads/ads_admin_guard.dart';
import 'package:turqappv2/Core/Services/Ads/ads_analytics_service.dart';
import 'package:turqappv2/Core/Services/Ads/ads_delivery_service.dart';
import 'package:turqappv2/Core/Services/Ads/ads_feature_flags_service.dart';
import 'package:turqappv2/Core/Services/Ads/ads_repository_service.dart';
import 'package:turqappv2/Core/Services/Ads/ads_targeting_service.dart';
import 'package:turqappv2/Models/Ads/ads_models.dart';
import 'package:turqappv2/Modules/Profile/Settings/AdsCenter/ads_center_utils.dart';

part 'ads_center_controller_stream_part.dart';

class AdsCenterController extends GetxController {
  static AdsCenterController ensure({bool permanent = false}) {
    final existing = maybeFind();
    if (existing != null) return existing;
    return Get.put(
      AdsCenterController(),
      permanent: permanent,
    );
  }

  static AdsCenterController? maybeFind() {
    final isRegistered = Get.isRegistered<AdsCenterController>();
    if (!isRegistered) return null;
    return Get.find<AdsCenterController>();
  }

  final AdsRepositoryService repository;
  final AdsDeliveryService deliveryService;
  final AdsTargetingService targetingService;
  final AdsAnalyticsService analyticsService;

  AdsCenterController({
    AdsRepositoryService? repository,
    AdsDeliveryService? deliveryService,
    AdsTargetingService? targetingService,
    AdsAnalyticsService? analyticsService,
  })  : repository = repository ?? const AdsRepositoryService(),
        deliveryService = deliveryService ?? AdsDeliveryService(),
        targetingService = targetingService ?? const AdsTargetingService(),
        analyticsService = analyticsService ?? const AdsAnalyticsService();

  final RxBool canAccess = false.obs;
  final RxBool loading = false.obs;
  final RxnString errorText = RxnString();

  final RxMap<String, dynamic> dashboard = <String, dynamic>{}.obs;
  final RxList<AdCampaign> campaigns = <AdCampaign>[].obs;
  final RxList<AdCreative> creatives = <AdCreative>[].obs;
  final RxList<AdAdvertiser> advertisers = <AdAdvertiser>[].obs;
  final RxList<AdStatsSnapshot> dailyStats = <AdStatsSnapshot>[].obs;
  final RxList<Map<String, dynamic>> deliveryLogs =
      <Map<String, dynamic>>[].obs;

  final Rx<AdDeliveryResult> previewResult = AdDeliveryResult.empty.obs;
  final RxBool previewLoading = false.obs;

  final Rxn<AdCampaignStatus> filterStatus = Rxn<AdCampaignStatus>();
  final Rxn<AdPlacementType> filterPlacement = Rxn<AdPlacementType>();
  final RxBool filterIncludeTest = true.obs;

  StreamSubscription<List<AdCampaign>>? _campaignSub;
  StreamSubscription<List<AdCreative>>? _creativeSub;
  StreamSubscription<List<AdAdvertiser>>? _advertiserSub;
  StreamSubscription<List<AdStatsSnapshot>>? _statsSub;
  StreamSubscription<List<Map<String, dynamic>>>? _logSub;

  @override
  void onInit() {
    super.onInit();
    unawaited(_init());
  }

  @override
  void onClose() {
    _campaignSub?.cancel();
    _creativeSub?.cancel();
    _advertiserSub?.cancel();
    _statsSub?.cancel();
    _logSub?.cancel();
    super.onClose();
  }

  Future<String> saveCampaign(AdCampaign campaign) async {
    final id = await repository.upsertCampaign(campaign);
    await refreshDashboard();
    return id;
  }

  Future<String> saveCreative(AdCreative creative) async {
    final id = await repository.upsertCreative(creative);
    return id;
  }

  Future<void> reviewCreative({
    required String creativeId,
    required AdModerationStatus status,
    required String note,
  }) async {
    await repository.reviewCreative(
      creativeId,
      status: status,
      note: note,
    );
  }

  Future<void> updateCampaignStatus(
    String campaignId,
    AdCampaignStatus status,
  ) async {
    await repository.updateCampaignStatus(campaignId, status);
    await refreshDashboard();
  }

  Future<void> saveFlags(AdFeatureFlags flags) async {
    await AdsFeatureFlagsService.to.setFlags(flags);
  }

  Future<void> runPreview({
    required AdPlacementType placement,
    required String country,
    required String city,
    required int? age,
    required String userId,
  }) async {
    previewLoading.value = true;
    try {
      final ctx = await targetingService.buildContext(
        userId: userId,
        placement: placement,
        isPreview: true,
        country: country,
        city: city,
        age: age,
      );

      final res = await deliveryService.simulateForAdmin(ctx);
      previewResult.value = res;
    } finally {
      previewLoading.value = false;
    }
  }

  Future<void> trackPreviewImpression() async {
    final result = previewResult.value;
    if (!result.hasAd || result.campaign == null || result.creative == null) {
      return;
    }
    await analyticsService.logImpression(
      campaignId: result.campaign!.id,
      creativeId: result.creative!.id,
      placement: result.campaign!.placementTypes.first,
      isPreview: true,
    );
  }
}
