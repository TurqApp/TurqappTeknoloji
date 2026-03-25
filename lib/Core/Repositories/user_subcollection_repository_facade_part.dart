part of 'user_subcollection_repository.dart';

extension UserSubcollectionRepositoryFacadePart on UserSubcollectionRepository {
  Future<List<UserSubcollectionEntry>> getEntries(
    String uid, {
    required String subcollection,
    String? orderByField,
    int? limit,
    bool descending = true,
    bool preferCache = true,
    bool forceRefresh = false,
    bool cacheOnly = false,
  }) =>
      _getEntriesImpl(
        uid,
        subcollection: subcollection,
        orderByField: orderByField,
        limit: limit,
        descending: descending,
        preferCache: preferCache,
        forceRefresh: forceRefresh,
        cacheOnly: cacheOnly,
      );

  Future<void> setEntries(
    String uid, {
    required String subcollection,
    required List<UserSubcollectionEntry> items,
  }) =>
      _setEntriesImpl(
        uid,
        subcollection: subcollection,
        items: items,
      );

  Future<UserSubcollectionEntry?> getEntry(
    String uid, {
    required String subcollection,
    required String docId,
    bool preferCache = true,
    bool forceRefresh = false,
    bool cacheOnly = false,
  }) =>
      _getEntryImpl(
        uid,
        subcollection: subcollection,
        docId: docId,
        preferCache: preferCache,
        forceRefresh: forceRefresh,
        cacheOnly: cacheOnly,
      );

  Future<void> invalidate(
    String uid, {
    required String subcollection,
  }) =>
      _invalidateImpl(
        uid,
        subcollection: subcollection,
      );

  Future<void> upsertEntry(
    String uid, {
    required String subcollection,
    required String docId,
    required Map<String, dynamic> data,
  }) =>
      _upsertEntryImpl(
        uid,
        subcollection: subcollection,
        docId: docId,
        data: data,
      );

  Future<void> deleteEntry(
    String uid, {
    required String subcollection,
    required String docId,
  }) =>
      _deleteEntryImpl(
        uid,
        subcollection: subcollection,
        docId: docId,
      );
}
