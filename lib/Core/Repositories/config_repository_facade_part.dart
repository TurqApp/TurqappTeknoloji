part of 'config_repository.dart';

extension ConfigRepositoryFacadePart on ConfigRepository {
  Future<Map<String, dynamic>?> getAdminConfigDoc(
    String docId, {
    bool preferCache = true,
    bool forceRefresh = false,
    Duration ttl = ConfigRepository._defaultTtl,
  }) =>
      _getAdminConfigDocImpl(
        docId,
        preferCache: preferCache,
        forceRefresh: forceRefresh,
        ttl: ttl,
      );

  Future<void> putAdminConfigDoc(
    String docId,
    Map<String, dynamic> data,
  ) =>
      _putAdminConfigDocImpl(docId, data);

  Future<void> invalidateAdminConfigDoc(String docId) =>
      _invalidateAdminConfigDocImpl(docId);

  Stream<Map<String, dynamic>> watchAdminConfigDoc(
    String docId, {
    Duration ttl = ConfigRepository._defaultTtl,
  }) =>
      _watchAdminConfigDocImpl(
        docId,
        ttl: ttl,
      );

  Future<Map<String, dynamic>?> getLegacyConfigDoc({
    required String collection,
    required String docId,
    bool preferCache = true,
    bool forceRefresh = false,
    Duration ttl = ConfigRepository._defaultTtl,
  }) =>
      _getLegacyConfigDocImpl(
        collection: collection,
        docId: docId,
        preferCache: preferCache,
        forceRefresh: forceRefresh,
        ttl: ttl,
      );
}
