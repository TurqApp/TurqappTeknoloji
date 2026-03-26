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

  @override
  void onInit() {
    super.onInit();
    unawaited(_initialize());
  }
}
