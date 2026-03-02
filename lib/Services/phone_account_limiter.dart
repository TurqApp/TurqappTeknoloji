import 'package:cloud_firestore/cloud_firestore.dart';

class PhoneAccountLimitReached implements Exception {
  final String message;
  PhoneAccountLimitReached([this.message = 'Bu telefon numarası için limit dolu.']);
  @override
  String toString() => message;
}

class PhoneAccountLimiter {
  static const int defaultLimit = 5;
  static const String collectionName = 'phoneAccounts';

  String normalize(String raw) {
    final digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
    // App currently uses 10-digit TR numbers starting with '5'
    if (digits.length >= 10) {
      return digits.substring(digits.length - 10);
    }
    return digits;
  }

  DocumentReference<Map<String, dynamic>> _phoneDocRef(String phone) {
    final normalized = normalize(phone);
    return FirebaseFirestore.instance
        .collection(collectionName)
        .doc(normalized);
  }

  Future<({bool allowed, int count, int limit})> checkCanCreate(String phone) async {
    final ref = _phoneDocRef(phone);
    final snap = await ref.get();
    if (!snap.exists) {
      return (allowed: true, count: 0, limit: defaultLimit);
    }
    final data = snap.data() ?? {};
    final int count = (data['count'] ?? 0) as int;
    final int limit = (data['limit'] ?? defaultLimit) as int;
    return (allowed: count < limit, count: count, limit: limit);
  }

  Future<void> createUserWithLimit({
    required String uid,
    required String phone,
    required Map<String, dynamic> userData,
  }) async {
    final phoneRef = _phoneDocRef(phone);
    final userRef = FirebaseFirestore.instance.collection('users').doc(uid);

    await FirebaseFirestore.instance.runTransaction((tx) async {
      final phoneSnap = await tx.get(phoneRef);
      final data = phoneSnap.data() ?? <String, dynamic>{};
      final int count = (data['count'] ?? 0) as int;
      final int limit = (data['limit'] ?? defaultLimit) as int;
      if (count >= limit) {
        throw PhoneAccountLimitReached();
      }

      // Set user document
      tx.set(userRef, userData);

      final now = DateTime.now().millisecondsSinceEpoch;
      if (phoneSnap.exists) {
        tx.update(phoneRef, {
          'count': FieldValue.increment(1),
          'accounts': FieldValue.arrayUnion([uid]),
          'lastCreatedAt': now,
        });
      } else {
        tx.set(phoneRef, {
          'phone': normalize(phone),
          'count': 1,
          'limit': defaultLimit,
          'accounts': [uid],
          'createdAt': now,
          'lastCreatedAt': now,
        });
      }
    });
  }

  Future<void> moveUserToNewPhone({
    required String uid,
    required String oldPhone,
    required String newPhone,
  }) async {
    final oldRef = _phoneDocRef(oldPhone);
    final newRef = _phoneDocRef(newPhone);

    await FirebaseFirestore.instance.runTransaction((tx) async {
      final newSnap = await tx.get(newRef);
      final newData = newSnap.data() ?? <String, dynamic>{};
      final int newCount = (newData['count'] ?? 0) as int;
      final int newLimit = (newData['limit'] ?? defaultLimit) as int;
      if (newCount >= newLimit) {
        throw PhoneAccountLimitReached();
      }

      // Decrement from old (if exists)
      final oldSnap = await tx.get(oldRef);
      if (oldSnap.exists) {
        final oldCount = (oldSnap.data()?['count'] ?? 0) as int;
        final dec = oldCount > 0 ? -1 : 0;
        tx.update(oldRef, {
          if (dec != 0) 'count': FieldValue.increment(dec),
          'accounts': FieldValue.arrayRemove([uid]),
          'lastUpdatedAt': DateTime.now().millisecondsSinceEpoch,
        });
      }

      // Increment to new
      final now = DateTime.now().millisecondsSinceEpoch;
      if (newSnap.exists) {
        tx.update(newRef, {
          'count': FieldValue.increment(1),
          'accounts': FieldValue.arrayUnion([uid]),
          'lastUpdatedAt': now,
          'lastCreatedAt': now,
        });
      } else {
        tx.set(newRef, {
          'phone': normalize(newPhone),
          'count': 1,
          'limit': defaultLimit,
          'accounts': [uid],
          'createdAt': now,
          'lastCreatedAt': now,
        });
      }
    });
  }

  Future<void> decrementOnUserDelete({
    required String uid,
    required String phone,
  }) async {
    final ref = _phoneDocRef(phone);
    await FirebaseFirestore.instance.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) return;
      final data = snap.data() ?? {};
      final int count = (data['count'] ?? 0) as int;
      final dec = count > 0 ? -1 : 0;
      tx.update(ref, {
        if (dec != 0) 'count': FieldValue.increment(dec),
        'accounts': FieldValue.arrayRemove([uid]),
        'lastUpdatedAt': DateTime.now().millisecondsSinceEpoch,
      });
    });
  }
}
