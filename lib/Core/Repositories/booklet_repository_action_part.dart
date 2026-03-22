part of 'booklet_repository.dart';

extension BookletRepositoryActionPart on BookletRepository {
  Future<void> replaceAnswerKeys(
    String bookletId,
    List<Map<String, dynamic>> items,
  ) async {
    final ref = _firestore.collection('books').doc(bookletId);
    final answersRef = ref.collection('CevapAnahtarlari');
    final old = await fetchAnswerKeys(
      bookletId,
      preferCache: false,
      forceRefresh: true,
    );
    final batch = _firestore.batch();
    for (final answer in old) {
      final id = (answer['id'] ?? '').toString();
      if (id.isEmpty) continue;
      batch.delete(answersRef.doc(id));
    }
    final cachedItems = <Map<String, dynamic>>[];
    for (final item in items) {
      final data = Map<String, dynamic>.from(item);
      final docRef = answersRef.doc();
      batch.set(docRef, data);
      cachedItems.add(<String, dynamic>{
        'id': docRef.id,
        'data': data,
      });
    }
    await batch.commit();
    await _storeRawList('answers:$bookletId', cachedItems);
  }
}
