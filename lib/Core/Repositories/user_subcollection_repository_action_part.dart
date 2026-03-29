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

    final current = await getEntries(
      uid,
      subcollection: subcollection,
      preferCache: true,
      forceRefresh: false,
    );
    final next = List<UserSubcollectionEntry>.from(current)
      ..removeWhere((e) => e.id == docId)
      ..add(
        UserSubcollectionEntry(
          id: docId,
          data: _cloneUserSubcollectionMap(data),
        ),
      );
    await setEntries(uid, subcollection: subcollection, items: next);
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

    final current = await getEntries(
      uid,
      subcollection: subcollection,
      preferCache: true,
      forceRefresh: false,
    );
    final next =
        current.where((entry) => entry.id != docId).toList(growable: false);
    await setEntries(uid, subcollection: subcollection, items: next);
  }
}
