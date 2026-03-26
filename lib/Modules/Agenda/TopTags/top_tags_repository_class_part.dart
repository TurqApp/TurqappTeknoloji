part of 'top_tags_repository.dart';

class TopTagsRepository extends GetxService {
  final FirebaseFirestore _db;
  static const int _defaultTrendWindowHours = 24;
  static const int _defaultTrendThreshold = 1;
  static const Duration _ttl = Duration(hours: 1);
  static const String _prefsKey = 'top_tags_repository_v1';
  List<HashtagModel>? _memory;
  DateTime? _memoryAt;
  final List<PostsModel> _feedMemory = <PostsModel>[];
  DocumentSnapshot<Map<String, dynamic>>? _lastFeedDoc;
  SharedPreferences? _prefs;

  TopTagsRepository({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  static TopTagsRepository? maybeFind() {
    final isRegistered = Get.isRegistered<TopTagsRepository>();
    if (!isRegistered) return null;
    return Get.find<TopTagsRepository>();
  }

  static TopTagsRepository ensure() {
    final existing = maybeFind();
    if (existing != null) return existing;
    return Get.put(TopTagsRepository(), permanent: true);
  }

  @override
  void onInit() {
    super.onInit();
    SharedPreferences.getInstance().then((prefs) => _prefs = prefs);
  }

  Future<void> _store(List<HashtagModel> items) =>
      _TopTagsRepositoryCacheX(this)._store(items);

  List<HashtagModel>? _readMemory({required int limit}) =>
      _TopTagsRepositoryCacheX(this)._readMemory(limit: limit);

  Future<List<HashtagModel>?> _readPrefs({required int limit}) =>
      _TopTagsRepositoryCacheX(this)._readPrefs(limit: limit);

  int _resolveLastSeenActivityTs(int rawLastSeenTs, int windowMs, int nowMs) =>
      _TopTagsRepositoryCacheX(this)
          ._resolveLastSeenActivityTs(rawLastSeenTs, windowMs, nowMs);

  Future<List<PostsModel>> fetchImagePostsPage({
    int limit = 15,
    bool reset = false,
  }) =>
      _TopTagsRepositoryCacheX(this).fetchImagePostsPage(
        limit: limit,
        reset: reset,
      );
}
