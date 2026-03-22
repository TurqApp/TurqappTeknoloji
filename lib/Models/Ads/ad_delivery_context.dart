import 'package:turqappv2/Models/Ads/ad_enums.dart';

class AdDeliveryContext {
  final String userId;
  final String country;
  final String city;
  final int? age;
  final String language;
  final String gender;
  final String devicePlatform;
  final String appVersion;
  final AdPlacementType placement;
  final bool isPreview;

  const AdDeliveryContext({
    required this.userId,
    required this.country,
    required this.city,
    required this.age,
    required this.language,
    required this.gender,
    required this.devicePlatform,
    required this.appVersion,
    required this.placement,
    this.isPreview = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'country': country,
      'city': city,
      'age': age,
      'language': language,
      'gender': gender,
      'devicePlatform': devicePlatform,
      'appVersion': appVersion,
      'placement': placement.name,
      'isPreview': isPreview,
    };
  }
}
