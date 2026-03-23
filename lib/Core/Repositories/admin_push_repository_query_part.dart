part of 'admin_push_repository.dart';

extension AdminPushRepositoryQueryPart on AdminPushRepository {
  Stream<List<AdminPushReport>> _watchReportsImpl({required int limit}) {
    return _reportsRef
        .orderBy('createdDate', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map(
                (doc) => AdminPushReport(
                  id: doc.id,
                  data: Map<String, dynamic>.from(doc.data()),
                ),
              )
              .toList(growable: false),
        );
  }

  Future<List<String>> _resolveTargetUidsImpl({
    required AdminPushTargetFilters filters,
  }) async {
    final uid = filters.uid.trim();
    if (uid.isNotEmpty) {
      final data =
          await _userRepository.getUserRaw(uid) ?? const <String, dynamic>{};
      if (data.isEmpty) return <String>[];
      return _isEligiblePushTargetImpl(uid, data) ? <String>[uid] : <String>[];
    }

    final meslekLc = normalizeSearchText(filters.meslek);
    final konumLc = normalizeSearchText(filters.konum);
    final genderLc = normalizeSearchText(filters.gender);
    final minAge = filters.minAge;
    final maxAge = filters.maxAge;

    final targets = <String>[];
    final seen = <String>{};

    bool matchesFilters(String userId, Map<String, dynamic> data) {
      if (seen.contains(userId)) return false;
      if (!_isEligiblePushTargetImpl(userId, data)) return false;
      final userMeslek = normalizeSearchText(
        (data['meslekKategori'] ?? '').toString(),
      );
      final userGender = normalizeSearchText(
        (data['cinsiyet'] ?? '').toString(),
      );
      final locations = _collectLocationValuesImpl(data);
      final age = _extractAgeImpl(data);
      final meslekOk = meslekLc.isEmpty || userMeslek == meslekLc;
      final konumOk = konumLc.isEmpty || locations.any((v) => v == konumLc);
      final genderOk = genderLc.isEmpty || userGender == genderLc;
      final minAgeOk = minAge == null || (age != null && age >= minAge);
      final maxAgeOk = maxAge == null || (age != null && age <= maxAge);
      final ok = meslekOk && konumOk && genderOk && minAgeOk && maxAgeOk;
      if (ok) seen.add(userId);
      return ok;
    }

    const pageSize = 350;
    Query<Map<String, dynamic>> query = FirebaseFirestore.instance
        .collection('users')
        .where('createdDate', isGreaterThanOrEqualTo: pushTargetCutoffMs)
        .orderBy('createdDate')
        .limit(pageSize);

    while (true) {
      final users = await query.get();
      if (users.docs.isEmpty) break;

      for (final doc in users.docs) {
        final data = doc.data();
        await _userRepository.seedUser(UserSummary.fromMap(doc.id, data));
        if (matchesFilters(doc.id, data)) {
          targets.add(doc.id);
        }
      }

      if (users.docs.length < pageSize) break;
      query = FirebaseFirestore.instance
          .collection('users')
          .where('createdDate', isGreaterThanOrEqualTo: pushTargetCutoffMs)
          .orderBy('createdDate')
          .startAfterDocument(users.docs.last)
          .limit(pageSize);
    }

    final senderUid = CurrentUserService.instance.effectiveUserId;
    return targets
        .where((targetUid) => targetUid.isNotEmpty && targetUid != senderUid)
        .toList(growable: false);
  }
}
