part of 'user_profile_cache_service.dart';

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
