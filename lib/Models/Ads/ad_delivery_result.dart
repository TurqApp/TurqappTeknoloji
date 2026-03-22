import 'package:turqappv2/Models/Ads/ad_campaign.dart';
import 'package:turqappv2/Models/Ads/ad_creative.dart';
import 'package:turqappv2/Models/Ads/ad_enums.dart';

class AdEligibilityDecision {
  final String campaignId;
  final bool eligible;
  final List<AdDeliveryRejectReason> reasons;

  const AdEligibilityDecision({
    required this.campaignId,
    required this.eligible,
    required this.reasons,
  });

  Map<String, dynamic> toMap() {
    return {
      'campaignId': campaignId,
      'eligible': eligible,
      'reasons': reasons.map(enumToShort).toList(),
    };
  }
}

class AdDeliveryResult {
  final bool hasAd;
  final AdCampaign? campaign;
  final AdCreative? creative;
  final List<AdEligibilityDecision> decisions;
  final String message;

  const AdDeliveryResult({
    required this.hasAd,
    this.campaign,
    this.creative,
    this.decisions = const <AdEligibilityDecision>[],
    this.message = '',
  });

  static const empty = AdDeliveryResult(hasAd: false);

  Map<String, dynamic> toLogMap({
    required String userId,
    required String country,
    required String city,
    required int? age,
    required String placement,
    required bool isPreview,
  }) {
    return {
      'userId': userId,
      'country': country,
      'city': city,
      'age': age,
      'placement': placement,
      'isPreview': isPreview,
      'hasAd': hasAd,
      'selectedCampaignId': campaign?.id ?? '',
      'selectedCreativeId': creative?.id ?? '',
      'message': message,
      'decisions': decisions.map((e) => e.toMap()).toList(),
      'createdAt': DateTime.now().millisecondsSinceEpoch,
    };
  }
}
