import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:turqappv2/Models/Ads/ads_models.dart';
import 'package:turqappv2/Services/current_user_service.dart';

class AdsTargetingService {
  const AdsTargetingService();

  Future<AdDeliveryContext> buildContext({
    required String userId,
    required AdPlacementType placement,
    bool isPreview = false,
    String? country,
    String? city,
    int? age,
  }) async {
    final current = CurrentUserService.instance.currentUser;
    final info = await PackageInfo.fromPlatform();

    return AdDeliveryContext(
      userId: userId,
      country: (country ?? current?.ulke ?? '').trim(),
      city: (city ?? current?.city ?? current?.il ?? '').trim(),
      age: age ?? _extractAge(current?.dogumTarihi),
      language: 'tr',
      gender: (current?.cinsiyet ?? '').trim(),
      devicePlatform: switch (defaultTargetPlatform) {
        TargetPlatform.android => 'android',
        TargetPlatform.iOS => 'ios',
        TargetPlatform.macOS => 'macos',
        TargetPlatform.windows => 'windows',
        TargetPlatform.linux => 'linux',
        TargetPlatform.fuchsia => 'fuchsia',
      },
      appVersion: info.version,
      placement: placement,
      isPreview: isPreview,
    );
  }

  int? _extractAge(String? rawBirth) {
    final raw = (rawBirth ?? '').trim();
    if (raw.isEmpty) return null;

    DateTime? birthDate;
    final asInt = int.tryParse(raw);
    if (asInt != null) {
      birthDate = raw.length >= 13
          ? DateTime.fromMillisecondsSinceEpoch(asInt)
          : DateTime.fromMillisecondsSinceEpoch(asInt * 1000);
    } else {
      birthDate = DateTime.tryParse(raw);
      if (birthDate == null && raw.contains('/')) {
        final p = raw.split('/');
        if (p.length == 3) {
          final d = int.tryParse(p[0]);
          final m = int.tryParse(p[1]);
          final y = int.tryParse(p[2]);
          if (d != null && m != null && y != null) {
            birthDate = DateTime(y, m, d);
          }
        }
      }
    }

    if (birthDate == null) return null;
    final now = DateTime.now();
    var age = now.year - birthDate.year;
    final hadBirthday = (now.month > birthDate.month) ||
        (now.month == birthDate.month && now.day >= birthDate.day);
    if (!hadBirthday) age--;
    if (age < 0 || age > 120) return null;
    return age;
  }
}
