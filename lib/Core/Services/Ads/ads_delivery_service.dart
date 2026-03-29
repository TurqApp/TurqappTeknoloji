import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Services/Ads/ads_collections.dart';
import 'package:turqappv2/Core/Services/Ads/ads_feature_flags_service.dart';
import 'package:turqappv2/Core/Services/Ads/ads_repository_service.dart';
import 'package:turqappv2/Models/Ads/ads_models.dart';

class AdsDeliveryService {
  AdsDeliveryService({
    AdsRepositoryService? repository,
  }) : _repository = repository ?? const AdsRepositoryService();

  final AdsRepositoryService _repository;

  static dynamic _cloneValue(dynamic value) {
    if (value is Map) {
      return value.map(
        (key, nestedValue) => MapEntry(
          key.toString(),
          _cloneValue(nestedValue),
        ),
      );
    }
    if (value is List) {
      return value.map(_cloneValue).toList(growable: false);
    }
    return value;
  }

  static Map<String, dynamic> _cloneMap(Map source) {
    return source.map(
      (key, value) => MapEntry(key.toString(), _cloneValue(value)),
    );
  }

  Future<AdDeliveryResult> simulateForAdmin(AdDeliveryContext context) async {
    final flags = ensureAdsFeatureFlagsService().flags.value;
    if (!flags.adsInfrastructureEnabled || !flags.adsAdminPanelEnabled) {
      return AdDeliveryResult(
        hasAd: false,
        message: 'ads_delivery.infrastructure_disabled'.tr,
      );
    }
    if (!flags.adsPreviewModeEnabled) {
      return AdDeliveryResult(
        hasAd: false,
        message: 'ads_delivery.preview_disabled'.tr,
      );
    }

    // Önce callable ile dene (server-side authority), hata olursa local fallback.
    try {
      final callable = FirebaseFunctions.instanceFor(region: 'europe-west3')
          .httpsCallable('adsSimulateDelivery');
      final res = await callable.call(context.toMap());
      final data = _cloneMap(res.data as Map? ?? const <String, dynamic>{});
      final hasAd = data['hasAd'] == true;
      final campaignMap =
          data['campaign'] is Map ? _cloneMap(data['campaign'] as Map) : null;
      final creativeMap =
          data['creative'] is Map ? _cloneMap(data['creative'] as Map) : null;
      final decisionRaw = (data['decisions'] as List?) ?? const [];
      final decisions = decisionRaw.map((row) {
        final m = _cloneMap(row as Map? ?? const <String, dynamic>{});
        final reasons = ((m['reasons'] as List?) ?? const [])
            .map((v) => parseEnum(v.toString(), AdDeliveryRejectReason.values,
                AdDeliveryRejectReason.userIneligible))
            .toList(growable: false);
        return AdEligibilityDecision(
          campaignId: (m['campaignId'] ?? '').toString(),
          eligible: m['eligible'] == true,
          reasons: reasons,
        );
      }).toList(growable: false);

      return AdDeliveryResult(
        hasAd: hasAd,
        campaign: campaignMap == null
            ? null
            : AdCampaign.fromMap(campaignMap,
                id: (campaignMap['id'] ?? '').toString()),
        creative: creativeMap == null
            ? null
            : AdCreative.fromMap(creativeMap,
                id: (creativeMap['id'] ?? '').toString()),
        decisions: decisions,
        message: (data['message'] ?? '').toString(),
      );
    } catch (_) {
      final local = await _simulateLocal(context);
      await _logDelivery(context, local);
      return local;
    }
  }

  Future<AdDeliveryResult> _simulateLocal(AdDeliveryContext context) async {
    final campaigns = await _repository.getCampaignsOnce();
    if (campaigns.isEmpty) {
      return AdDeliveryResult(
          hasAd: false, message: 'ads_delivery.no_campaign'.tr);
    }

    final now = DateTime.now();
    final decisions = <AdEligibilityDecision>[];
    final eligible = <AdCampaign>[];

    for (final c in campaigns) {
      final reasons = <AdDeliveryRejectReason>[];

      if (!c.deliveryEnabled) {
        reasons.add(AdDeliveryRejectReason.featureDisabled);
      }
      if (!c.isStatusDeliverable) {
        reasons.add(AdDeliveryRejectReason.campaignInactive);
      }
      if (!c.isScheduleActive(now)) {
        reasons.add(AdDeliveryRejectReason.scheduleMismatch);
      }
      if (!c.placementTypes.contains(context.placement)) {
        reasons.add(AdDeliveryRejectReason.placementMismatch);
      }

      final today = await _repository.getTodayStatsForCampaign(c.id);
      final dailySpent = today?.spend ?? 0;
      if (!c.isBudgetAvailable(dailySpent: dailySpent)) {
        reasons.add(AdDeliveryRejectReason.budgetExhausted);
      }

      final targetingOk = c.targeting.matches(
        userId: context.userId,
        country: context.country,
        city: context.city,
        age: context.age,
        language: context.language,
        gender: context.gender,
        devicePlatform: context.devicePlatform,
        appVersion: context.appVersion,
      );
      if (!targetingOk) {
        reasons.add(AdDeliveryRejectReason.targetingMismatch);
      }

      final isEligible = reasons.isEmpty;
      decisions.add(AdEligibilityDecision(
          campaignId: c.id, eligible: isEligible, reasons: reasons));
      if (isEligible) {
        eligible.add(c);
      }
    }

    if (eligible.isEmpty) {
      return AdDeliveryResult(
        hasAd: false,
        message: 'ads_delivery.no_ad'.tr,
        decisions: decisions,
      );
    }

    eligible.sort((a, b) {
      final p = b.priority.compareTo(a.priority);
      if (p != 0) return p;
      return b.bidAmount.compareTo(a.bidAmount);
    });

    final selected = eligible.first;
    final creatives = await _repository.getCreativesByIds(selected.creativeIds);
    final approved =
        creatives.where((c) => c.isApproved).toList(growable: false);
    if (approved.isEmpty) {
      decisions.add(
        AdEligibilityDecision(
          campaignId: selected.id,
          eligible: false,
          reasons: const [AdDeliveryRejectReason.creativeNotApproved],
        ),
      );
      return AdDeliveryResult(
        hasAd: false,
        message: 'ads_delivery.creative_missing'.tr,
        decisions: decisions,
      );
    }

    return AdDeliveryResult(
      hasAd: true,
      campaign: selected,
      creative: approved.first,
      decisions: decisions,
      message: 'ads_delivery.ad_found'.tr,
    );
  }

  Future<void> _logDelivery(
      AdDeliveryContext context, AdDeliveryResult result) async {
    try {
      await FirebaseFirestore.instance
          .collection(AdsCollections.deliveryLogs)
          .add(
            result.toLogMap(
              userId: context.userId,
              country: context.country,
              city: context.city,
              age: context.age,
              placement: context.placement.name,
              isPreview: context.isPreview,
            ),
          );
    } catch (_) {}
  }
}
