import 'package:turqappv2/Models/Ads/ad_enums.dart';
import 'package:turqappv2/Models/Ads/ad_model_utils.dart';

class AdImpression {
  final String id;
  final String campaignId;
  final String creativeId;
  final String userId;
  final AdPlacementType placement;
  final DateTime createdAt;
  final String country;
  final String city;
  final int? age;
  final bool isPreview;

  const AdImpression({
    required this.id,
    required this.campaignId,
    required this.creativeId,
    required this.userId,
    required this.placement,
    required this.createdAt,
    required this.country,
    required this.city,
    required this.age,
    required this.isPreview,
  });

  factory AdImpression.fromMap(Map<String, dynamic> map, {required String id}) {
    return AdImpression(
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
      country: (map['country'] ?? '').toString(),
      city: (map['city'] ?? '').toString(),
      age: map['age'] == null ? null : parseInt(map['age']),
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
      'country': country,
      'city': city,
      'age': age,
      'isPreview': isPreview,
    };
  }
}
