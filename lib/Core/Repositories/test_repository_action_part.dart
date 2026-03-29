part of 'test_repository_parts.dart';

extension TestRepositoryActionPart on TestRepository {
  List<String> _sanitizeStringList(dynamic raw) {
    if (raw is! List) return const <String>[];
    return raw
        .map((item) => item?.toString().trim() ?? '')
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
  }

  Future<void> submitAnswers(
    String testId, {
    required String userId,
    required List<String> answers,
  }) async {
    await _firestore
        .collection('Testler')
        .doc(testId)
        .collection('Yanitlar')
        .doc(DateTime.now().millisecondsSinceEpoch.toString())
        .set({
      'cevaplar': answers,
      'timeStamp': DateTime.now().millisecondsSinceEpoch,
      'userID': userId,
    });
    _memory.remove('answers:$testId');
  }

  Future<bool> toggleFavorite(
    String testId, {
    required String userId,
  }) async {
    final docRef = _firestore.collection('Testler').doc(testId);
    final docSnapshot = await docRef.get();
    if (!docSnapshot.exists) return false;

    final favorites = _sanitizeStringList(docSnapshot.data()?['favoriler']);
    final isFavorite = favorites.contains(userId);
    await docRef.update({
      'favoriler': isFavorite
          ? FieldValue.arrayRemove([userId])
          : FieldValue.arrayUnion([userId]),
    });

    final updated = Map<String, dynamic>.from(docSnapshot.data() ?? const {})
      ..['favoriler'] = isFavorite
          ? favorites.where((e) => e != userId).toList(growable: false)
          : <String>[...favorites, userId];
    await _storeRawDoc('raw:$testId', updated);
    return !isFavorite;
  }
}
