part of 'test_repository_parts.dart';

class _TimedTests {
  const _TimedTests({required this.items, required this.cachedAt});

  final List<TestsModel> items;
  final DateTime cachedAt;
}

class TestPageResult {
  const TestPageResult({
    required this.items,
    required this.lastDocument,
    required this.hasMore,
  });

  final List<TestsModel> items;
  final DocumentSnapshot? lastDocument;
  final bool hasMore;
}

class TestRepository extends GetxService {
  TestRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;
  static const Duration _ttl = Duration(hours: 12);
  static const String _prefsPrefix = 'test_repository_v1';
  final Map<String, _TimedTests> _memory = <String, _TimedTests>{};
  SharedPreferences? _prefs;

  @override
  void onInit() {
    super.onInit();
    _handleTestRepositoryInit(this);
  }
}

TestRepository? maybeFindTestRepository() => _maybeFindTestRepository();

TestRepository ensureTestRepository() => _ensureTestRepository();

TestRepository? _maybeFindTestRepository() =>
    Get.isRegistered<TestRepository>() ? Get.find<TestRepository>() : null;

TestRepository _ensureTestRepository() =>
    _maybeFindTestRepository() ?? Get.put(TestRepository(), permanent: true);

void _handleTestRepositoryInit(TestRepository repository) {
  SharedPreferences.getInstance().then((prefs) => repository._prefs = prefs);
}

extension TestRepositoryFacadePart on TestRepository {
  TestsModel _fromDoc(String id, Map<String, dynamic> data) =>
      _TestRepositoryCacheX(this)._fromDoc(id, data);

  Future<void> _store(String cacheKey, List<TestsModel> items) =>
      _TestRepositoryCacheX(this)._store(cacheKey, items);

  Future<void> _storeRawDoc(String cacheKey, Map<String, dynamic> data) =>
      _TestRepositoryCacheX(this)._storeRawDoc(cacheKey, data);

  Future<void> _storeRawList(
    String cacheKey,
    List<Map<String, dynamic>> data,
  ) =>
      _TestRepositoryCacheX(this)._storeRawList(cacheKey, data);

  Future<List<Map<String, dynamic>>?> _getRawList(String cacheKey) =>
      _TestRepositoryCacheX(this)._getRawList(cacheKey);

  Future<Map<String, dynamic>?> _getRawDoc(String cacheKey) =>
      _TestRepositoryCacheX(this)._getRawDoc(cacheKey);

  List<TestsModel>? _getFromMemory(String cacheKey) =>
      _TestRepositoryCacheX(this)._getFromMemory(cacheKey);

  Future<_TimedTests?> _getTimedFromPrefs(String cacheKey) =>
      _TestRepositoryCacheX(this)._getTimedFromPrefs(cacheKey);

  List<List<String>> _chunkIds(List<String> ids, int size) =>
      _TestRepositoryCacheX(this)._chunkIds(ids, size);

  TestReadinessModel? _questionFromMap(Map<String, dynamic> raw) =>
      _TestRepositoryCacheX(this)._questionFromMap(raw);
}
