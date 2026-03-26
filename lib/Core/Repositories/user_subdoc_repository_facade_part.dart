part of 'user_subdoc_repository.dart';

UserSubdocRepository? maybeFindUserSubdocRepository() {
  final isRegistered = Get.isRegistered<UserSubdocRepository>();
  if (!isRegistered) return null;
  return Get.find<UserSubdocRepository>();
}

UserSubdocRepository ensureUserSubdocRepository() {
  final existing = maybeFindUserSubdocRepository();
  if (existing != null) return existing;
  return Get.put(UserSubdocRepository(), permanent: true);
}

extension UserSubdocRepositoryFacadePart on UserSubdocRepository {
  Future<Map<String, dynamic>> getDoc(
    String uid, {
    required String collection,
    required String docId,
    bool preferCache = true,
    bool forceRefresh = false,
    Duration ttl = UserSubdocRepository._defaultTtl,
  }) =>
      _getUserSubdocDoc(
        uid,
        collection: collection,
        docId: docId,
        preferCache: preferCache,
        forceRefresh: forceRefresh,
        ttl: ttl,
      );

  Future<void> putDoc(
    String uid, {
    required String collection,
    required String docId,
    required Map<String, dynamic> data,
  }) {
    return _putUserSubdoc(
      this,
      uid,
      collection: collection,
      docId: docId,
      data: data,
    );
  }

  Future<void> setDoc(
    String uid, {
    required String collection,
    required String docId,
    required Map<String, dynamic> data,
    bool merge = true,
  }) =>
      _setUserSubdocDoc(
        uid,
        collection: collection,
        docId: docId,
        data: data,
        merge: merge,
      );

  Future<void> invalidate(
    String uid, {
    required String collection,
    required String docId,
  }) {
    return _invalidateUserSubdoc(
      this,
      uid,
      collection: collection,
      docId: docId,
    );
  }
}
