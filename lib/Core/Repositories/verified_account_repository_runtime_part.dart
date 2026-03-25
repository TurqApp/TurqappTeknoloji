part of 'verified_account_repository.dart';

extension VerifiedAccountRepositoryRuntimePart on VerifiedAccountRepository {
  Future<bool> hasApplication(
    String uid, {
    bool preferCache = true,
    bool forceRefresh = false,
  }) async {
    if (uid.isEmpty) return false;
    final key = _verifiedAccountCacheKey(uid);
    if (!forceRefresh && preferCache) {
      final memory = _getVerifiedAccountFromMemory(this, key);
      if (memory != null) return memory;

      final disk = await _getVerifiedAccountFromPrefs(this, key);
      if (disk != null) {
        _memory[key] = _CachedVerifiedAccountStatus(
          exists: disk,
          cachedAt: DateTime.now(),
        );
        return disk;
      }
    }

    final doc = await _verifiedAccountCollection().doc(uid).get();
    final exists = doc.exists;
    await _storeVerifiedAccountStatus(this, uid, exists);
    return exists;
  }

  Future<VerifiedAccountApplicationState?> fetchApplicationState(
    String uid, {
    bool forceRefresh = false,
  }) async {
    if (uid.isEmpty) return null;
    final doc = await _verifiedAccountCollection()
        .doc(uid)
        .get(const GetOptions(source: Source.serverAndCache));
    if (!doc.exists) {
      if (forceRefresh) {
        await _storeVerifiedAccountStatus(this, uid, false);
      }
      return null;
    }
    final data = doc.data() ?? const <String, dynamic>{};
    final state = VerifiedAccountApplicationState(
      exists: true,
      status: (data['status'] ?? 'pending').toString().trim(),
      selected: (data['selected'] ?? '').toString().trim(),
      badgeExpiresAt: (data['badgeExpiresAt'] as num?)?.toInt() ?? 0,
      renewalOpensAt: (data['renewalOpensAt'] as num?)?.toInt() ?? 0,
    );
    await _storeVerifiedAccountStatus(this, uid, state.isPending);
    return state;
  }

  Future<void> submitApplication(Map<String, dynamic> payload) async {
    final uid = CurrentUserService.instance.effectiveUserId;
    if (uid.isEmpty) return;
    final ref = _verifiedAccountCollection().doc(uid);
    final existing = await ref.get();
    if (existing.exists) {
      final data = existing.data() ?? const <String, dynamic>{};
      final status = (data['status'] ?? 'pending').toString().trim();
      final canResubmit = status == 'renewal_open' ||
          status == 'expired' ||
          status == 'rejected' ||
          status == 'approved';
      if (!canResubmit) {
        throw FirebaseException(
          plugin: 'cloud_firestore',
          code: 'already-exists',
          message: 'become_verified.already_received'.tr,
        );
      }
      await ref.set(payload, SetOptions(merge: true));
      await _storeVerifiedAccountStatus(this, uid, true);
      return;
    }
    await ref.set(payload);
    await _storeVerifiedAccountStatus(this, uid, true);
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchApplications() {
    return _verifiedAccountCollection()
        .orderBy('timeStamp', descending: true)
        .snapshots();
  }
}
