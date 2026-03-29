import 'package:turqappv2/Models/Ads/ad_campaign.dart';
import 'package:turqappv2/Models/Ads/ad_creative.dart';
import 'package:turqappv2/Models/Ads/ad_enums.dart';

class AdEligibilityDecision {
  final String campaignId;
  final bool eligible;
  final List<AdDeliveryRejectReason> reasons;

  AdEligibilityDecision({
    required this.campaignId,
    required this.eligible,
    required List<AdDeliveryRejectReason> reasons,
  }) : reasons = List<AdDeliveryRejectReason>.from(
         reasons,
         growable: false,
       );

  Map<String, dynamic> toMap() {
    return {
      'campaignId': campaignId,
      'eligible': eligible,
      'reasons': reasons.map(enumToShort).toList(growable: false),
    };
  }
}

class AdDeliveryResult {
  final bool hasAd;
  final AdCampaign? campaign;
  final AdCreative? creative;
  final List<AdEligibilityDecision> decisions;
  final String message;

  AdDeliveryResult({
    required this.hasAd,
    this.campaign,
    this.creative,
    List<AdEligibilityDecision> decisions = const <AdEligibilityDecision>[],
    this.message = '',
  }) : decisions = List<AdEligibilityDecision>.from(
         decisions,
         growable: false,
       );

  static final empty = AdDeliveryResult(hasAd: false);

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
      'decisions': decisions.map((e) => e.toMap()).toList(growable: false),
      'createdAt': DateTime.now().millisecondsSinceEpoch,
    };
  }
}
