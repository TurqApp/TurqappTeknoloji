import 'dart:async';
import 'dart:collection';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:turqappv2/Core/Services/PlaybackIntelligence/metadata_cache_policy.dart';
import 'package:turqappv2/Core/Services/PlaybackIntelligence/metadata_read_policy.dart';
import 'package:turqappv2/Core/Utils/avatar_url.dart';
import 'package:turqappv2/Core/Utils/nickname_utils.dart';

import 'turq_image_cache_manager.dart';

part 'user_profile_cache_service_fetch_part.dart';
part 'user_profile_cache_service_storage_part.dart';

class UserProfileCacheService extends GetxService {
  static const String _prefsKey = 'user_profile_cache_v2';
  static const int _maxEntries = 2000;
  Duration get _ttl =>
      MetadataCachePolicy.ttlFor(MetadataCacheBucket.userProfileSummary);

  final LinkedHashMap<String, _CachedUserProfile> _memory =
      LinkedHashMap<String, _CachedUserProfile>();

  SharedPreferences? _prefs;
  Timer? _persistTimer;
  bool _dirty = false;

  static UserProfileCacheService ensure() {
    final existing = maybeFind();
    if (existing != null) return existing;
    return Get.put(UserProfileCacheService(), permanent: true);
  }

  static UserProfileCacheService? maybeFind() {
    final isRegistered = Get.isRegistered<UserProfileCacheService>();
    if (!isRegistered) return null;
    return Get.find<UserProfileCacheService>();
  }

  static Future<void> invalidateIfRegistered(String uid) async {
    await maybeFind()?.invalidateUser(uid);
  }

  @override
  void onInit() {
    super.onInit();
    unawaited(_initialize());
  }
}

class _CachedUserProfile {
  final Map<String, dynamic> data;
  final DateTime cachedAt;

  _CachedUserProfile({
    required this.data,
    required this.cachedAt,
  });
}
