import 'package:turqappv2/Models/Ads/ad_model_utils.dart';

class AdTargeting {
  final List<String> countries;
  final List<String> cities;
  final List<String> languages;
  final int? minAge;
  final int? maxAge;
  final List<String> genders;
  final List<String> interests;
  final List<String> devicePlatforms;
  final List<String> appVersions;
  final List<String> includeUserIds;
  final List<String> excludeUserIds;

  const AdTargeting({
    this.countries = const <String>[],
    this.cities = const <String>[],
    this.languages = const <String>[],
    this.minAge,
    this.maxAge,
    this.genders = const <String>[],
    this.interests = const <String>[],
    this.devicePlatforms = const <String>[],
    this.appVersions = const <String>[],
    this.includeUserIds = const <String>[],
    this.excludeUserIds = const <String>[],
  });

  factory AdTargeting.fromMap(Map<String, dynamic>? map) {
    final data = map ?? const <String, dynamic>{};
    final minAgeRaw = data['minAge'];
    final maxAgeRaw = data['maxAge'];
    return AdTargeting(
      countries: parseStringList(data['countries']),
      cities: parseStringList(data['cities']),
      languages: parseStringList(data['languages']),
      minAge: minAgeRaw == null ? null : parseInt(minAgeRaw, fallback: 0),
      maxAge: maxAgeRaw == null ? null : parseInt(maxAgeRaw, fallback: 0),
      genders: parseStringList(data['genders']),
      interests: parseStringList(data['interests']),
      devicePlatforms: parseStringList(data['devicePlatforms']),
      appVersions: parseStringList(data['appVersions']),
      includeUserIds: parseStringList(data['includeUserIds']),
      excludeUserIds: parseStringList(data['excludeUserIds']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'countries': countries,
      'cities': cities,
      'languages': languages,
      'minAge': minAge,
      'maxAge': maxAge,
      'genders': genders,
      'interests': interests,
      'devicePlatforms': devicePlatforms,
      'appVersions': appVersions,
      'includeUserIds': includeUserIds,
      'excludeUserIds': excludeUserIds,
    };
  }

  bool _matchList(List<String> allowed, String? value) {
    if (allowed.isEmpty) return true;
    final normalized = (value ?? '').trim().toLowerCase();
    if (normalized.isEmpty) return false;
    return allowed.map((e) => e.toLowerCase()).contains(normalized);
  }

  bool matches({
    required String userId,
    String? country,
    String? city,
    int? age,
    String? language,
    String? gender,
    String? devicePlatform,
    String? appVersion,
  }) {
    if (excludeUserIds.contains(userId)) return false;
    if (includeUserIds.isNotEmpty && !includeUserIds.contains(userId)) {
      return false;
    }

    if (!_matchList(countries, country)) return false;
    if (!_matchList(cities, city)) return false;
    if (!_matchList(languages, language)) return false;
    if (!_matchList(genders, gender)) return false;
    if (!_matchList(devicePlatforms, devicePlatform)) return false;

    if (appVersions.isNotEmpty) {
      final normalized = (appVersion ?? '').trim();
      if (normalized.isEmpty || !appVersions.contains(normalized)) {
        return false;
      }
    }

    if (age != null) {
      if (minAge != null && age < minAge!) return false;
      if (maxAge != null && age > maxAge!) return false;
    } else if (minAge != null || maxAge != null) {
      return false;
    }

    return true;
  }
}
