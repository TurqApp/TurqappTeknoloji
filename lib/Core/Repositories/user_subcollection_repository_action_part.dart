part of 'user_subcollection_repository.dart';

extension UserSubcollectionRepositoryActionPart on UserSubcollectionRepository {
  Future<void> _upsertEntryImpl(
    String uid, {
    required String subcollection,
    required String docId,
    required Map<String, dynamic> data,
  }) async {
    if (uid.isEmpty || subcollection.isEmpty || docId.isEmpty) return;
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection(subcollection)
        .doc(docId)
        .set(data, SetOptions(merge: true));
    await _mergeEntryIntoExistingCacheImpl(
      uid,
      subcollection: subcollection,
      entry: UserSubcollectionEntry(
        id: docId,
        data: _cloneUserSubcollectionMap(data),
      ),
    );
  }

  Future<void> _deleteEntryImpl(
    String uid, {
    required String subcollection,
    required String docId,
  }) async {
    if (uid.isEmpty || subcollection.isEmpty || docId.isEmpty) return;
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection(subcollection)
        .doc(docId)
        .delete();
    await _removeEntryFromExistingCacheImpl(
      uid,
      subcollection: subcollection,
      docId: docId,
    );
  }
}
