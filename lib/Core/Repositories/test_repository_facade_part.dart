part of 'test_repository.dart';

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
