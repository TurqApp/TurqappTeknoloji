import 'package:turqappv2/Models/Ads/ad_enums.dart';
import 'package:turqappv2/Models/Ads/ad_model_utils.dart';

class AdClick {
  final String id;
  final String campaignId;
  final String creativeId;
  final String userId;
  final AdPlacementType placement;
  final DateTime createdAt;
  final bool ctaTap;
  final String destinationURL;
  final bool isPreview;

  const AdClick({
    required this.id,
    required this.campaignId,
    required this.creativeId,
    required this.userId,
    required this.placement,
    required this.createdAt,
    required this.ctaTap,
    required this.destinationURL,
    required this.isPreview,
  });

  factory AdClick.fromMap(Map<String, dynamic> map, {required String id}) {
    return AdClick(
      id: id,
      campaignId: (map['campaignId'] ?? '').toString(),
      creativeId: (map['creativeId'] ?? '').toString(),
      userId: (map['userId'] ?? '').toString(),
      placement: parseEnum(
        (map['placement'] ?? '').toString(),
        AdPlacementType.values,
        AdPlacementType.feed,
      ),
      createdAt: parseDateTimeOrNow(map['createdAt']),
      ctaTap: parseBool(map['ctaTap']),
      destinationURL: (map['destinationURL'] ?? '').toString(),
      isPreview: parseBool(map['isPreview']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'campaignId': campaignId,
      'creativeId': creativeId,
      'userId': userId,
      'placement': enumToShort(placement),
      'createdAt': createdAt.millisecondsSinceEpoch,
      'ctaTap': ctaTap,
      'destinationURL': destinationURL,
      'isPreview': isPreview,
    };
  }
}
