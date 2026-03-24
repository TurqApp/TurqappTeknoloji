part of 'follow_repository.dart';

extension FollowRepositoryActionPart on FollowRepository {
  Future<void> applyToggle(
    String currentUid,
    String otherUid, {
    required bool nowFollowing,
  }) async {
    if (currentUid.isEmpty || otherUid.isEmpty) return;
    final current = await getFollowingIds(
      currentUid,
      preferCache: true,
      forceRefresh: false,
    );
    final next = current.toSet();
    if (nowFollowing) {
      next.add(otherUid);
    } else {
      next.remove(otherUid);
    }
    await _persistRelation(_relationKey(currentUid, 'followings'), next);
  }

  Future<void> createRelationPair({
    required String currentUid,
    required String otherUid,
    int? timestampMs,
  }) async {
    if (currentUid.isEmpty || otherUid.isEmpty || currentUid == otherUid) {
      return;
    }
    final firestore = FirebaseFirestore.instance;
    final now = timestampMs ?? DateTime.now().millisecondsSinceEpoch;
    final followingRef = firestore
        .collection('users')
        .doc(currentUid)
        .collection('followings')
        .doc(otherUid);
    final followerRef = firestore
        .collection('users')
        .doc(otherUid)
        .collection('followers')
        .doc(currentUid);
    final currentRootRef = firestore.collection('users').doc(currentUid);
    final otherRootRef = firestore.collection('users').doc(otherUid);
    await firestore.runTransaction((tx) async {
      final existing = await tx.get(followingRef);
      if (existing.exists) return;
      tx.set(followingRef, {'timeStamp': now}, SetOptions(merge: true));
      tx.set(followerRef, {'timeStamp': now}, SetOptions(merge: true));
      tx.set(currentRootRef, {
        'counterOfFollowings': FieldValue.increment(1),
      }, SetOptions(merge: true));
      tx.set(otherRootRef, {
        'counterOfFollowers': FieldValue.increment(1),
      }, SetOptions(merge: true));
    });
    await applyToggle(currentUid, otherUid, nowFollowing: true);
  }

  Future<void> deleteRelationPair({
    required String currentUid,
    required String otherUid,
  }) async {
    if (currentUid.isEmpty || otherUid.isEmpty || currentUid == otherUid) {
      return;
    }
    final firestore = FirebaseFirestore.instance;
    final followingRef = firestore
        .collection('users')
        .doc(currentUid)
        .collection('followings')
        .doc(otherUid);
    final followerRef = firestore
        .collection('users')
        .doc(otherUid)
        .collection('followers')
        .doc(currentUid);
    final currentRootRef = firestore.collection('users').doc(currentUid);
    final otherRootRef = firestore.collection('users').doc(otherUid);
    await firestore.runTransaction((tx) async {
      final existing = await tx.get(followingRef);
      if (!existing.exists) return;
      final currentRootSnap = await tx.get(currentRootRef);
      final otherRootSnap = await tx.get(otherRootRef);
      tx.delete(followingRef);
      tx.delete(followerRef);
      final currentCount =
          (currentRootSnap.data()?['counterOfFollowings'] as num?)?.toInt() ??
              0;
      final otherCount =
          (otherRootSnap.data()?['counterOfFollowers'] as num?)?.toInt() ?? 0;
      if (currentCount > 0) {
        tx.set(currentRootRef, {
          'counterOfFollowings': FieldValue.increment(-1),
        }, SetOptions(merge: true));
      }
      if (otherCount > 0) {
        tx.set(otherRootRef, {
          'counterOfFollowers': FieldValue.increment(-1),
        }, SetOptions(merge: true));
      }
    });
    await applyToggle(currentUid, otherUid, nowFollowing: false);
  }

  Future<FollowWriteResult> toggleRelation({
    required String currentUid,
    required String otherUid,
    required int dailyLimit,
    required String todayKey,
  }) async {
    final firestore = FirebaseFirestore.instance;
    final myFollowingRef = firestore
        .collection('users')
        .doc(currentUid)
        .collection('followings')
        .doc(otherUid);
    final otherFollowersRef = firestore
        .collection('users')
        .doc(otherUid)
        .collection('followers')
        .doc(currentUid);
    final myRootRef = firestore.collection('users').doc(currentUid);
    final otherRootRef = firestore.collection('users').doc(otherUid);
    final counterRef = firestore
        .collection('users')
        .doc(currentUid)
        .collection('private')
        .doc('followDaily');

    final result =
        await firestore.runTransaction<FollowWriteResult>((transaction) async {
      final myFollowSnap = await transaction.get(myFollowingRef);

      if (myFollowSnap.exists) {
        final myRootSnap = await transaction.get(myRootRef);
        final otherRootSnap = await transaction.get(otherRootRef);
        transaction.delete(myFollowingRef);
        transaction.delete(otherFollowersRef);
        final myCount =
            (myRootSnap.data()?['counterOfFollowings'] as num?)?.toInt() ?? 0;
        final otherCount =
            (otherRootSnap.data()?['counterOfFollowers'] as num?)?.toInt() ?? 0;
        if (myCount > 0) {
          transaction.set(myRootRef, {
            'counterOfFollowings': FieldValue.increment(-1),
          }, SetOptions(merge: true));
        }
        if (otherCount > 0) {
          transaction.set(otherRootRef, {
            'counterOfFollowers': FieldValue.increment(-1),
          }, SetOptions(merge: true));
        }
        return const FollowWriteResult(
          nowFollowing: false,
          limitReached: false,
        );
      }

      int currentCount = 0;
      var storedDay = todayKey;
      final counterSnap = await transaction.get(counterRef);
      if (counterSnap.exists) {
        final data = counterSnap.data();
        storedDay = (data?['date'] as String?) ?? todayKey;
        if (storedDay == todayKey) {
          final raw = data?['count'];
          if (raw is int) currentCount = raw;
        }
      }

      if (currentCount >= dailyLimit) {
        return const FollowWriteResult(nowFollowing: false, limitReached: true);
      }

      final now = DateTime.now().millisecondsSinceEpoch;
      transaction.set(
        myFollowingRef,
        {'timeStamp': now},
        SetOptions(merge: true),
      );
      transaction.set(
        otherFollowersRef,
        {'timeStamp': now},
        SetOptions(merge: true),
      );
      transaction.set(
        myRootRef,
        {'counterOfFollowings': FieldValue.increment(1)},
        SetOptions(merge: true),
      );
      transaction.set(
        otherRootRef,
        {'counterOfFollowers': FieldValue.increment(1)},
        SetOptions(merge: true),
      );
      transaction.set(
        counterRef,
        {'date': todayKey, 'count': currentCount + 1},
        SetOptions(merge: true),
      );
      return const FollowWriteResult(nowFollowing: true, limitReached: false);
    });

    await applyToggle(
      currentUid,
      otherUid,
      nowFollowing: result.nowFollowing,
    );
    return result;
  }

  Future<bool> ensureRelation({
    required String currentUid,
    required String otherUid,
    required bool bypassDailyLimit,
    required int dailyLimit,
    required String todayKey,
  }) async {
    final firestore = FirebaseFirestore.instance;
    final myFollowingRef = firestore
        .collection('users')
        .doc(currentUid)
        .collection('followings')
        .doc(otherUid);
    final otherFollowersRef = firestore
        .collection('users')
        .doc(otherUid)
        .collection('followers')
        .doc(currentUid);
    final myRootRef = firestore.collection('users').doc(currentUid);
    final otherRootRef = firestore.collection('users').doc(otherUid);
    final counterRef = firestore
        .collection('users')
        .doc(currentUid)
        .collection('private')
        .doc('followDaily');

    final created = await firestore.runTransaction<bool>((transaction) async {
      final existing = await transaction.get(myFollowingRef);
      if (existing.exists) return false;

      if (!bypassDailyLimit) {
        int currentCount = 0;
        var storedDay = todayKey;
        final counterSnap = await transaction.get(counterRef);
        if (counterSnap.exists) {
          final data = counterSnap.data();
          storedDay = (data?['date'] as String?) ?? todayKey;
          if (storedDay == todayKey) {
            final raw = data?['count'];
            if (raw is int) currentCount = raw;
          }
        }

        if (currentCount >= dailyLimit) {
          return false;
        }
        transaction.set(
          counterRef,
          {'date': todayKey, 'count': currentCount + 1},
          SetOptions(merge: true),
        );
      }

      final now = DateTime.now().millisecondsSinceEpoch;
      transaction.set(
        myFollowingRef,
        {'timeStamp': now},
        SetOptions(merge: true),
      );
      transaction.set(
        otherFollowersRef,
        {'timeStamp': now},
        SetOptions(merge: true),
      );
      transaction.set(
        myRootRef,
        {'counterOfFollowings': FieldValue.increment(1)},
        SetOptions(merge: true),
      );
      transaction.set(
        otherRootRef,
        {'counterOfFollowers': FieldValue.increment(1)},
        SetOptions(merge: true),
      );
      return true;
    });

    if (created) {
      await applyToggle(
        currentUid,
        otherUid,
        nowFollowing: true,
      );
    }
    return created;
  }

  Future<void> invalidate(String uid) async {
    if (uid.isEmpty) return;
    _memory.remove(uid);
    _relationMemory.remove(_relationKey(uid, 'followings'));
    _relationMemory.remove(_relationKey(uid, 'followers'));
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs?.remove(_prefsKey(uid));
    await _prefs?.remove(_relationPrefsKey(_relationKey(uid, 'followings')));
    await _prefs?.remove(_relationPrefsKey(_relationKey(uid, 'followers')));
  }

  Future<void> clearAll() async {
    final keys = _memory.keys.toList();
    _memory.clear();
    final relationKeys = _relationMemory.keys.toList();
    _relationMemory.clear();
    _prefs ??= await SharedPreferences.getInstance();
    for (final uid in keys) {
      await _prefs?.remove(_prefsKey(uid));
    }
    for (final relationKey in relationKeys) {
      await _prefs?.remove(_relationPrefsKey(relationKey));
    }
  }
}
