import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:turqappv2/Models/Ads/ads_models.dart';
import 'package:turqappv2/Modules/Profile/Settings/AdsCenter/ads_center_application_service.dart';

void main() {
  group('AdsCenterApplicationService', () {
    test('loadDashboard merges managed metrics and tolerates managed failure',
        () async {
      final service = AdsCenterApplicationService(
        dashboardMetricsLoader: () async => <String, dynamic>{
          'activeCampaigns': 2,
        },
        managedDashboardMetricsLoader: () async {
          throw StateError('managed metrics unavailable');
        },
      );

      final metrics = await service.loadDashboard();

      expect(metrics, <String, dynamic>{
        'activeCampaigns': 2,
      });
    });

    test('saveCampaign returns campaign id and refreshed dashboard', () async {
      final service = AdsCenterApplicationService(
        upsertCampaign: (_) async => 'campaign-42',
        dashboardMetricsLoader: () async => <String, dynamic>{
          'activeCampaigns': 3,
        },
        managedDashboardMetricsLoader: () async => <String, dynamic>{
          'managedSliders': 2,
        },
      );

      final result = await service.saveCampaign(_campaign(id: ''));

      expect(result.campaignId, 'campaign-42');
      expect(result.dashboardMetrics, <String, dynamic>{
        'activeCampaigns': 3,
        'managedSliders': 2,
      });
    });

    test('updateCampaignStatus refreshes dashboard after mutation', () async {
      final steps = <String>[];
      final service = AdsCenterApplicationService(
        updateCampaignStatus: (campaignId, status) async {
          steps.add('status:$campaignId:${status.name}');
        },
        dashboardMetricsLoader: () async {
          steps.add('dashboard');
          return <String, dynamic>{'pausedCampaigns': 1};
        },
        managedDashboardMetricsLoader: () async => const <String, dynamic>{},
      );

      final metrics = await service.updateCampaignStatus(
        'campaign-9',
        AdCampaignStatus.paused,
      );

      expect(steps, <String>['status:campaign-9:paused', 'dashboard']);
      expect(metrics, <String, dynamic>{'pausedCampaigns': 1});
    });

    test('runPreview builds context and simulates delivery via service layer',
        () async {
      AdDeliveryContext? capturedContext;
      final result = AdDeliveryResult(
        hasAd: true,
        campaign: _campaign(id: 'campaign-7'),
        creative: _creative(id: 'creative-7'),
      );
      final service = AdsCenterApplicationService(
        previewContextBuilder: ({
          required String userId,
          required AdPlacementType placement,
          required String country,
          required String city,
          required int? age,
        }) async {
          return AdDeliveryContext(
            userId: userId,
            country: country,
            city: city,
            age: age,
            language: 'tr',
            gender: '',
            devicePlatform: 'android',
            appVersion: '1.0.0',
            placement: placement,
            isPreview: true,
          );
        },
        previewSimulator: (context) async {
          capturedContext = context;
          return result;
        },
      );

      final preview = await service.runPreview(
        placement: AdPlacementType.feed,
        country: 'TR',
        city: 'Istanbul',
        age: 21,
        userId: 'user-1',
      );

      expect(preview, same(result));
      expect(capturedContext?.userId, 'user-1');
      expect(capturedContext?.country, 'TR');
      expect(capturedContext?.placement, AdPlacementType.feed);
      expect(capturedContext?.isPreview, isTrue);
    });

    test('trackPreviewImpression logs only when preview selected an ad',
        () async {
      final calls = <String>[];
      final service = AdsCenterApplicationService(
        previewImpressionLogger: ({
          required String campaignId,
          required String creativeId,
          required AdPlacementType placement,
          required bool isPreview,
        }) async {
          calls.add('$campaignId/$creativeId/${placement.name}/$isPreview');
        },
      );

      await service
          .trackPreviewImpression(const AdDeliveryResult(hasAd: false));
      await service.trackPreviewImpression(
        AdDeliveryResult(
          hasAd: true,
          campaign: _campaign(id: 'campaign-11'),
          creative: _creative(id: 'creative-11'),
        ),
      );

      expect(calls, <String>['campaign-11/creative-11/feed/true']);
    });

    test('controller delegates dashboard and action orchestration to service',
        () {
      final actionsSource = File(
        '/Users/turqapp/Desktop/TurqApp/lib/Modules/Profile/Settings/AdsCenter/ads_center_controller_actions_part.dart',
      ).readAsStringSync();
      final streamSource = File(
        '/Users/turqapp/Desktop/TurqApp/lib/Modules/Profile/Settings/AdsCenter/ads_center_controller_stream_part.dart',
      ).readAsStringSync();

      expect(
        actionsSource,
        contains('controller.applicationService.saveCampaign'),
      );
      expect(
        actionsSource,
        contains('.updateCampaignStatus(campaignId, status)'),
      );
      expect(
        actionsSource,
        contains('controller.applicationService.runPreview'),
      );
      expect(
        actionsSource,
        contains('.trackPreviewImpression(controller.previewResult.value)'),
      );
      expect(streamSource, contains('applicationService.loadDashboard()'));
      expect(
        streamSource,
        isNot(
          contains(
            'TurqAppSuggestionConfigService.instance\n              .getManagedDashboardMetrics()',
          ),
        ),
      );
    });
  });
}

AdCampaign _campaign({required String id}) {
  final now = DateTime(2026, 3, 28, 12);
  return AdCampaign(
    id: id,
    advertiserId: 'advertiser-1',
    name: 'Demo campaign',
    status: AdCampaignStatus.active,
    placementTypes: const <AdPlacementType>[AdPlacementType.feed],
    budgetType: AdBudgetType.daily,
    totalBudget: 1000,
    dailyBudget: 100,
    spentAmount: 10,
    currency: 'TRY',
    startAt: now,
    endAt: now.add(const Duration(days: 7)),
    targeting: const AdTargeting(),
    creativeIds: const <String>['creative-1'],
    bidType: AdBidType.cpm,
    bidAmount: 2.5,
    priority: 10,
    isTestCampaign: false,
    deliveryEnabled: true,
    frequencyCapPerDay: 3,
    createdAt: now,
    updatedAt: now,
    createdBy: 'admin-1',
    approvedBy: 'admin-2',
  );
}

AdCreative _creative({required String id}) {
  final now = DateTime(2026, 3, 28, 12);
  return AdCreative(
    id: id,
    campaignId: 'campaign-1',
    type: AdCreativeType.image,
    storagePath: 'ads/$id.png',
    mediaURL: 'https://example.com/$id.png',
    hlsMasterURL: '',
    thumbnailURL: 'https://example.com/$id-thumb.png',
    aspectRatio: 1,
    durationSec: 0,
    headline: 'Headline',
    bodyText: 'Body',
    ctaText: 'Install',
    destinationURL: 'https://example.com',
    moderationStatus: AdModerationStatus.approved,
    reviewNotes: '',
    createdAt: now,
    updatedAt: now,
  );
}
