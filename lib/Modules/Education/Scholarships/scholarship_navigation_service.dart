import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:turqappv2/Ads/admob_intersitital.dart';
import 'package:turqappv2/Modules/Education/Scholarships/ScholarshipDetail/scholarship_detail_view.dart';

class ScholarshipNavigationService {
  ScholarshipNavigationService._();

  static const String _cooldownPrefsKey =
      'scholarship_detail_interstitial_last_shown_at_ms';
  static const Duration _interstitialCooldown = Duration(minutes: 30);

  static Future<void> openDetail(
    Map<String, dynamic> scholarshipData,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final lastShownAtMs = prefs.getInt(_cooldownPrefsKey);
    final shouldAttemptInterstitial =
        lastShownAtMs == null ||
        now
                .difference(
                  DateTime.fromMillisecondsSinceEpoch(lastShownAtMs),
                ) >=
            _interstitialCooldown;

    if (shouldAttemptInterstitial) {
      final didShowInterstitial = await showUnskippableInterstitialAd();
      if (didShowInterstitial) {
        await prefs.setInt(
          _cooldownPrefsKey,
          DateTime.now().millisecondsSinceEpoch,
        );
      }
    }

    await Get.to(
      () => ScholarshipDetailView(),
      arguments: scholarshipData,
    );
  }
}
