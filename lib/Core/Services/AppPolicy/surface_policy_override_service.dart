import 'dart:convert';

import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SurfacePolicyOverrideKeys {
  const SurfacePolicyOverrideKeys._();

  static const String feedHomeInitialLimit = 'feed_home_initial_limit';
  static const String shortHomeInitialLimit = 'short_home_initial_limit';
  static const String recommendedUsersInitialLimit =
      'recommended_users_initial_limit';
  static const String marketOwnerInitialLimit = 'market_owner_initial_limit';
  static const String jobOwnerInitialLimit = 'job_owner_initial_limit';
  static const String testAnsweredInitialLimit = 'test_answered_initial_limit';
  static const String testFavoritesInitialLimit =
      'test_favorites_initial_limit';
  static const String practiceExamAnsweredInitialLimit =
      'practice_exam_answered_initial_limit';
  static const String opticalFormAnsweredInitialLimit =
      'optical_form_answered_initial_limit';
  static const String startupFeedPrefetchDocLimit =
      'startup_feed_prefetch_doc_limit';
  static const String startupShortPrefetchDocLimit =
      'startup_short_prefetch_doc_limit';
  static const String startupListingWarmLimitOnWiFi =
      'startup_listing_warm_limit_wifi';
  static const String startupListingWarmLimitOnCellular =
      'startup_listing_warm_limit_cellular';
  static const String mobileWarmWindow = 'mobile_warm_window';
  static const String mobileNextWindow = 'mobile_next_window';
  static const String minGlobalCachedVideos = 'min_global_cached_videos';
  static const String mobileInitialSegments = 'mobile_initial_segments';
  static const String mobileAheadSegments = 'mobile_ahead_segments';
}

SurfacePolicyOverrideService ensureSurfacePolicyOverrideService({
  bool permanent = true,
}) =>
    maybeFindSurfacePolicyOverrideService() ??
    Get.put(
      SurfacePolicyOverrideService(),
      permanent: permanent,
    );

SurfacePolicyOverrideService? maybeFindSurfacePolicyOverrideService() =>
    Get.isRegistered<SurfacePolicyOverrideService>()
        ? Get.find<SurfacePolicyOverrideService>()
        : null;

class SurfacePolicyOverrideService extends GetxService {
  static const String _prefsKey = 'surface_policy_overrides_v1';

  SharedPreferences? _prefs;
  Map<String, int> _overrides = const <String, int>{};

  Future<void> ensureReady({SharedPreferences? prefs}) async {
    _prefs ??= prefs ?? await SharedPreferences.getInstance();
    _overrides = _decode(_prefs!.getString(_prefsKey));
  }

  Map<String, int> snapshot() => Map<String, int>.unmodifiable(_overrides);

  int readInt(String key, int fallback) {
    final value = _overrides[key];
    if (value == null || value < 1) return fallback;
    return value;
  }

  Future<void> replaceAll(Map<String, int> values) async {
    await ensureReady();
    final normalized = <String, int>{};
    values.forEach((key, value) {
      if (key.trim().isEmpty || value < 1) return;
      normalized[key] = value;
    });
    _overrides = Map<String, int>.unmodifiable(normalized);
    await _persist();
  }

  Future<void> clearAll() async {
    await ensureReady();
    _overrides = const <String, int>{};
    await _prefs!.remove(_prefsKey);
  }

  Future<void> _persist() async {
    final payload = jsonEncode(_overrides);
    await _prefs!.setString(_prefsKey, payload);
  }

  Map<String, int> _decode(String? raw) {
    if (raw == null || raw.trim().isEmpty) return const <String, int>{};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return const <String, int>{};
      final values = <String, int>{};
      decoded.forEach((key, value) {
        final normalizedKey = key.toString().trim();
        if (normalizedKey.isEmpty) return;
        final normalizedValue = _asPositiveInt(value);
        if (normalizedValue == null) return;
        values[normalizedKey] = normalizedValue;
      });
      return Map<String, int>.unmodifiable(values);
    } catch (_) {
      return const <String, int>{};
    }
  }

  int? _asPositiveInt(Object? value) {
    if (value is int) {
      return value > 0 ? value : null;
    }
    if (value is num) {
      final normalized = value.toInt();
      return normalized > 0 ? normalized : null;
    }
    final normalized = value?.toString().trim() ?? '';
    if (normalized.isEmpty) return null;
    final parsed = int.tryParse(normalized);
    if (parsed != null && parsed > 0) return parsed;
    final parsedNum = num.tryParse(normalized);
    if (parsedNum == null) return null;
    final asInt = parsedNum.toInt();
    return asInt > 0 ? asInt : null;
  }
}
