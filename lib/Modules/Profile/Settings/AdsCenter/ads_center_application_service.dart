import 'package:turqappv2/Core/Services/Ads/ads_analytics_service.dart';
import 'package:turqappv2/Core/Services/Ads/ads_delivery_service.dart';
import 'package:turqappv2/Core/Services/Ads/ads_repository_service.dart';
import 'package:turqappv2/Core/Services/Ads/ads_targeting_service.dart';
import 'package:turqappv2/Core/Services/Ads/turqapp_suggestion_config_service.dart';
import 'package:turqappv2/Models/Ads/ads_models.dart';

class AdsCampaignMutationResult {
  const AdsCampaignMutationResult({
    required this.campaignId,
    required this.dashboardMetrics,
  });

  final String campaignId;
  final Map<String, dynamic> dashboardMetrics;
}

class AdsCenterApplicationService {
  AdsCenterApplicationService({
    AdsRepositoryService? repository,
    AdsDeliveryService? deliveryService,
    AdsTargetingService? targetingService,
    AdsAnalyticsService? analyticsService,
    Future<Map<String, dynamic>> Function()? dashboardMetricsLoader,
    Future<Map<String, dynamic>> Function()? managedDashboardMetricsLoader,
    Future<String> Function(AdCampaign campaign)? upsertCampaign,
    Future<void> Function(
      String campaignId,
      AdCampaignStatus status,
    )? updateCampaignStatus,
    Future<AdDeliveryContext> Function({
      required String userId,
      required AdPlacementType placement,
      required String country,
      required String city,
      required int? age,
    })? previewContextBuilder,
    Future<AdDeliveryResult> Function(AdDeliveryContext context)?
        previewSimulator,
    Future<void> Function({
      required String campaignId,
      required String creativeId,
      required AdPlacementType placement,
      required bool isPreview,
    })? previewImpressionLogger,
  })  : _repository = repository ?? const AdsRepositoryService(),
        _deliveryService = deliveryService ?? AdsDeliveryService(),
        _targetingService = targetingService ?? const AdsTargetingService(),
        _analyticsService = analyticsService ?? const AdsAnalyticsService(),
        _dashboardMetricsLoader = dashboardMetricsLoader ??
            (repository ?? const AdsRepositoryService()).getDashboardMetrics,
        _managedDashboardMetricsLoader = managedDashboardMetricsLoader ??
            (() async {
              return TurqAppSuggestionConfigService.instance
                  .getManagedDashboardMetrics();
            }),
        _upsertCampaign = upsertCampaign ??
            (repository ?? const AdsRepositoryService()).upsertCampaign,
        _updateCampaignStatus = updateCampaignStatus ??
            (repository ?? const AdsRepositoryService()).updateCampaignStatus,
        _previewContextBuilder = previewContextBuilder ??
            _buildPreviewContextBuilder(
              targetingService ?? const AdsTargetingService(),
            ),
        _previewSimulator = previewSimulator ??
            (deliveryService ?? AdsDeliveryService()).simulateForAdmin,
        _previewImpressionLogger = previewImpressionLogger ??
            (analyticsService ?? const AdsAnalyticsService()).logImpression;

  final AdsRepositoryService _repository;
  final AdsDeliveryService _deliveryService;
  final AdsTargetingService _targetingService;
  final AdsAnalyticsService _analyticsService;
  final Future<Map<String, dynamic>> Function() _dashboardMetricsLoader;
  final Future<Map<String, dynamic>> Function() _managedDashboardMetricsLoader;
  final Future<String> Function(AdCampaign campaign) _upsertCampaign;
  final Future<void> Function(
    String campaignId,
    AdCampaignStatus status,
  ) _updateCampaignStatus;
  final Future<AdDeliveryContext> Function({
    required String userId,
    required AdPlacementType placement,
    required String country,
    required String city,
    required int? age,
  }) _previewContextBuilder;
  final Future<AdDeliveryResult> Function(AdDeliveryContext context)
      _previewSimulator;
  final Future<void> Function({
    required String campaignId,
    required String creativeId,
    required AdPlacementType placement,
    required bool isPreview,
  }) _previewImpressionLogger;

  AdsRepositoryService get repository => _repository;
  AdsDeliveryService get deliveryService => _deliveryService;
  AdsTargetingService get targetingService => _targetingService;
  AdsAnalyticsService get analyticsService => _analyticsService;

  static Future<AdDeliveryContext> Function({
    required String userId,
    required AdPlacementType placement,
    required String country,
    required String city,
    required int? age,
  }) _buildPreviewContextBuilder(AdsTargetingService targetingService) {
    return ({
      required String userId,
      required AdPlacementType placement,
      required String country,
      required String city,
      required int? age,
    }) {
      return targetingService.buildContext(
        userId: userId,
        placement: placement,
        isPreview: true,
        country: country,
        city: city,
        age: age,
      );
    };
  }

  Future<Map<String, dynamic>> loadDashboard() async {
    final metrics = await _dashboardMetricsLoader();
    try {
      metrics.addAll(await _managedDashboardMetricsLoader());
    } catch (_) {}
    return metrics;
  }

  Future<AdsCampaignMutationResult> saveCampaign(
    AdCampaign campaign,
  ) async {
    final campaignId = await _upsertCampaign(campaign);
    final dashboardMetrics = await loadDashboard();
    return AdsCampaignMutationResult(
      campaignId: campaignId,
      dashboardMetrics: dashboardMetrics,
    );
  }

  Future<Map<String, dynamic>> updateCampaignStatus(
    String campaignId,
    AdCampaignStatus status,
  ) async {
    await _updateCampaignStatus(campaignId, status);
    return loadDashboard();
  }

  Future<AdDeliveryResult> runPreview({
    required AdPlacementType placement,
    required String country,
    required String city,
    required int? age,
    required String userId,
  }) async {
    final context = await _previewContextBuilder(
      userId: userId,
      placement: placement,
      country: country,
      city: city,
      age: age,
    );
    return _previewSimulator(context);
  }

  Future<void> trackPreviewImpression(AdDeliveryResult result) async {
    if (!result.hasAd || result.campaign == null || result.creative == null) {
      return;
    }
    await _previewImpressionLogger(
      campaignId: result.campaign!.id,
      creativeId: result.creative!.id,
      placement: result.campaign!.placementTypes.first,
      isPreview: true,
    );
  }
}
