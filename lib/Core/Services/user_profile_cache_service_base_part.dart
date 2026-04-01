part of 'user_profile_cache_service.dart';

abstract class _UserProfileCacheServiceBase extends GetxService {
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
    unawaited((this as UserProfileCacheService)._initialize());
  }
}
