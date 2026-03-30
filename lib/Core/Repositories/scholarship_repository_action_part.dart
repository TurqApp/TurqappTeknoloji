part of 'scholarship_repository.dart';

extension ScholarshipRepositoryActionPart on ScholarshipRepository {
  List<String> _asNormalizedStringList(dynamic value) {
    if (value is! List) return const <String>[];
    return value
        .map((item) => item?.toString().trim() ?? '')
        .where((item) => item.isNotEmpty)
        .toSet()
        .toList(growable: false);
  }

  Future<List<String>> _updateApplicantCaches(
    String scholarshipId,
    String userId, {
    required bool applied,
  }) async {
    final cleanId = scholarshipId.trim();
    final cleanUserId = userId.trim();
    if (cleanId.isEmpty || cleanUserId.isEmpty) return const <String>[];

    final existingRaw = await fetchRawById(
      cleanId,
      preferCache: true,
      forceRefresh: false,
    );
    final currentApplicants = _asNormalizedStringList(
      existingRaw?['basvurular'],
    );
    final nextApplicants = applied
        ? <String>{...currentApplicants, cleanUserId}.toList(growable: false)
        : currentApplicants
            .where((id) => id != cleanUserId)
            .toList(growable: false);

    if (existingRaw != null) {
      final updated = Map<String, dynamic>.from(existingRaw)
        ..['basvurular'] = nextApplicants;
      await _store(cleanId, updated);
    }
    await _storeRawDoc(
      'applicants:$cleanId',
      <String, dynamic>{'ids': nextApplicants},
    );
    await _storeApply('$cleanId::$cleanUserId', applied);
    await _invalidateQueryPrefix('query:applied:$cleanUserId:');
    return nextApplicants;
  }

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

  Future<void> applyForScholarship({
    required String scholarshipId,
    required String userId,
  }) async {
    final cleanId = scholarshipId.trim();
    final cleanUserId = userId.trim();
    if (cleanId.isEmpty || cleanUserId.isEmpty) return;
    final docRef = ScholarshipFirestorePath.doc(cleanId);

    await docRef.collection('Basvurular').doc(cleanUserId).set({
      'timeStamp': DateTime.now().millisecondsSinceEpoch,
    });
    await docRef.update({
      'basvurular': FieldValue.arrayUnion([cleanUserId]),
    });

    await _updateApplicantCaches(
      cleanId,
      cleanUserId,
      applied: true,
    );
    await maybeFindScholarshipSnapshotRepository()
        ?.invalidateUserScopedSurfaces(cleanUserId);
  }

  Future<void> cancelScholarshipApplication({
    required String scholarshipId,
    required String userId,
  }) async {
    final cleanId = scholarshipId.trim();
    final cleanUserId = userId.trim();
    if (cleanId.isEmpty || cleanUserId.isEmpty) return;
    final docRef = ScholarshipFirestorePath.doc(cleanId);

    await docRef.collection('Basvurular').doc(cleanUserId).delete();
    await docRef.update({
      'basvurular': FieldValue.arrayRemove([cleanUserId]),
    });

    await _updateApplicantCaches(
      cleanId,
      cleanUserId,
      applied: false,
    );
    await maybeFindScholarshipSnapshotRepository()
        ?.invalidateUserScopedSurfaces(cleanUserId);
  }

  Future<void> deleteScholarship({
    required String scholarshipId,
    required String actorUserId,
  }) async {
    final cleanId = scholarshipId.trim();
    final cleanActorUserId = actorUserId.trim();
    if (cleanId.isEmpty) return;

    final docRef = ScholarshipFirestorePath.doc(cleanId);
    final doc =
        await docRef.get(const GetOptions(source: Source.serverAndCache));
    if (!doc.exists) return;

    final data = doc.data() ?? const <String, dynamic>{};
    final ownerUserId = (data['userID'] ?? '').toString().trim();
    final appliedUserIds = _asNormalizedStringList(data['basvurular']);
    final likedUserIds = _asNormalizedStringList(data['begeniler']);
    final savedUserIds = _asNormalizedStringList(data['kaydedenler']);

    await docRef.delete();

    await _removeDocCache(cleanId);
    await _removeRawDoc(_scholarshipRepositoryCountKey);
    await _removeRawDoc('applicants:$cleanId');

    if (ownerUserId.isNotEmpty) {
      await _invalidateQueryPrefix('query:owner:$ownerUserId:');
    }

    for (final userId in appliedUserIds) {
      await _removeApply('$cleanId::$userId');
      await _invalidateQueryPrefix('query:applied:$userId:');
    }

    for (final userId in likedUserIds) {
      await _invalidateQueryPrefix('query:membership:begeniler:$userId:');
    }

    for (final userId in savedUserIds) {
      await _invalidateQueryPrefix('query:membership:kaydedenler:$userId:');
    }

    if (cleanActorUserId.isNotEmpty) {
      await maybeFindScholarshipSnapshotRepository()
          ?.invalidateUserScopedSurfaces(cleanActorUserId);
    }

    await TypesenseEducationSearchService.instance.invalidateEntity(
      EducationTypesenseEntity.scholarship,
    );
  }
}
