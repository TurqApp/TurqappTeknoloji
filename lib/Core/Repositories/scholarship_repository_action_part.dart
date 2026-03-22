part of 'scholarship_repository.dart';

extension ScholarshipRepositoryActionPart on ScholarshipRepository {
  Future<void> setUserAppliedCache(
    String scholarshipId,
    String userId,
    bool value,
  ) async {
    final cleanScholarshipId = scholarshipId.trim();
    final cleanUserId = userId.trim();
    if (cleanScholarshipId.isEmpty || cleanUserId.isEmpty) return;
    await _storeApply('$cleanScholarshipId::$cleanUserId', value);
  }

  Future<bool> toggleLike(
    String scholarshipId, {
    required String userId,
  }) async {
    return _toggleArrayMembership(
      scholarshipId,
      userId: userId,
      field: 'begeniler',
    );
  }

  Future<bool> toggleBookmark(
    String scholarshipId, {
    required String userId,
  }) async {
    return _toggleArrayMembership(
      scholarshipId,
      userId: userId,
      field: 'kaydedenler',
    );
  }

  Future<bool> _toggleArrayMembership(
    String scholarshipId, {
    required String userId,
    required String field,
  }) async {
    final cleanId = scholarshipId.trim();
    final cleanUserId = userId.trim();
    if (cleanId.isEmpty || cleanUserId.isEmpty) return false;
    final docRef = ScholarshipFirestorePath.doc(cleanId);
    final doc = await docRef.get();
    if (!doc.exists) return false;
    final current = List<String>.from(doc.data()?[field] ?? const <String>[]);
    final contains = current.contains(cleanUserId);
    final next = contains
        ? current.where((e) => e != cleanUserId).toList(growable: false)
        : <String>[...current, cleanUserId];
    await docRef.update({field: next});

    final existingRaw = await fetchRawById(
      cleanId,
      preferCache: true,
      forceRefresh: false,
    );
    if (existingRaw != null) {
      final updated = Map<String, dynamic>.from(existingRaw)..[field] = next;
      await _store(cleanId, updated);
    }
    await _invalidateQueryPrefix('query:membership:$field:$cleanUserId:');
    return !contains;
  }
}
