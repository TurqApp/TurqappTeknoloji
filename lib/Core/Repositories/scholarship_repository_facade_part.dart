part of 'scholarship_repository.dart';

ScholarshipRepository? _maybeFindScholarshipRepository() =>
    Get.isRegistered<ScholarshipRepository>()
        ? Get.find<ScholarshipRepository>()
        : null;

ScholarshipRepository _ensureScholarshipRepository() =>
    _maybeFindScholarshipRepository() ??
    Get.put(ScholarshipRepository(), permanent: true);

void _handleScholarshipRepositoryInit(ScholarshipRepository repository) {
  SharedPreferences.getInstance().then((prefs) => repository._prefs = prefs);
}

extension ScholarshipRepositoryFacadePart on ScholarshipRepository {
  Map<String, dynamic>? _readMemory(String docId) =>
      _ScholarshipRepositoryCacheX(this)._readMemory(docId);

  Future<Map<String, dynamic>?> _readPrefs(String docId) =>
      _ScholarshipRepositoryCacheX(this)._readPrefs(docId);

  Future<void> _store(String docId, Map<String, dynamic> data) =>
      _ScholarshipRepositoryCacheX(this)._store(docId, data);

  List<Map<String, dynamic>>? _readQueryMemory(String key) =>
      _ScholarshipRepositoryCacheX(this)._readQueryMemory(key);

  Future<List<Map<String, dynamic>>?> _readQueryPrefs(String key) =>
      _ScholarshipRepositoryCacheX(this)._readQueryPrefs(key);

  Future<void> _storeQueryDocs(
    String key,
    List<Map<String, dynamic>> items,
  ) =>
      _ScholarshipRepositoryCacheX(this)._storeQueryDocs(key, items);

  Future<void> _invalidateQueryPrefix(String prefix) =>
      _ScholarshipRepositoryCacheX(this)._invalidateQueryPrefix(prefix);

  bool? _readApplyMemory(String key) =>
      _ScholarshipRepositoryCacheX(this)._readApplyMemory(key);

  Future<bool?> _readApplyPrefs(String key) =>
      _ScholarshipRepositoryCacheX(this)._readApplyPrefs(key);

  Future<void> _storeApply(String key, bool value) =>
      _ScholarshipRepositoryCacheX(this)._storeApply(key, value);

  Future<void> _storeRawDoc(String cacheKey, Map<String, dynamic> data) =>
      _ScholarshipRepositoryCacheX(this)._storeRawDoc(cacheKey, data);

  Future<Map<String, dynamic>?> _getRawDoc(String cacheKey) =>
      _ScholarshipRepositoryCacheX(this)._getRawDoc(cacheKey);
}
