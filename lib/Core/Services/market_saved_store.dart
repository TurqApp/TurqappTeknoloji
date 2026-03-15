import 'package:cloud_firestore/cloud_firestore.dart';

class MarketSavedStore {
  MarketSavedStore._();

  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static DocumentReference<Map<String, dynamic>> _userSavedDoc(
    String uid,
    String itemId,
  ) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('savedMarket')
        .doc(itemId);
  }

  static DocumentReference<Map<String, dynamic>> _favoriteDoc(
    String itemId,
    String uid,
  ) {
    return _firestore
        .collection('marketStore')
        .doc(itemId)
        .collection('favorites')
        .doc(uid);
  }

  static Future<bool> isSaved(String uid, String itemId) async {
    try {
      final snap = await _userSavedDoc(uid, itemId).get();
      return snap.exists;
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') return false;
      rethrow;
    }
  }

  static Future<Set<String>> getSavedItemIds(String uid) async {
    try {
      final snap = await _firestore
          .collection('users')
          .doc(uid)
          .collection('savedMarket')
          .get();
      return snap.docs
          .map((doc) => (doc.data()['itemId'] ?? doc.id).toString())
          .where((id) => id.trim().isNotEmpty)
          .toSet();
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') return <String>{};
      rethrow;
    }
  }

  static Future<void> save(String uid, String itemId) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final batch = _firestore.batch();
    batch.set(_userSavedDoc(uid, itemId), {
      'itemId': itemId,
      'userId': uid,
      'createdAt': now,
    });
    batch.set(_favoriteDoc(itemId, uid), {
      'itemId': itemId,
      'userId': uid,
      'createdAt': now,
    });
    await batch.commit();
  }

  static Future<void> unsave(String uid, String itemId) async {
    final batch = _firestore.batch();
    batch.delete(_userSavedDoc(uid, itemId));
    batch.delete(_favoriteDoc(itemId, uid));
    await batch.commit();
  }
}
