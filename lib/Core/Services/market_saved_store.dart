import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:turqappv2/Core/Repositories/market_repository.dart';

class MarketSavedStore {
  MarketSavedStore._();
  static MarketSavedStore? _instance;
  static MarketSavedStore? maybeFind() => _instance;

  static MarketSavedStore ensure() =>
      maybeFind() ?? (_instance = MarketSavedStore._());

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

  static DocumentReference<Map<String, dynamic>> _itemDoc(String itemId) {
    return _firestore.collection('marketStore').doc(itemId);
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
    await _firestore.runTransaction((transaction) async {
      final savedRef = _userSavedDoc(uid, itemId);
      final favoriteRef = _favoriteDoc(itemId, uid);
      final itemRef = _itemDoc(itemId);
      final savedSnap = await transaction.get(savedRef);
      if (savedSnap.exists) return;
      transaction.set(savedRef, {
        'itemId': itemId,
        'userId': uid,
        'createdAt': now,
      });
      transaction.set(favoriteRef, {
        'itemId': itemId,
        'userId': uid,
        'createdAt': now,
      });
      transaction.set(
          itemRef,
          {
            'favoriteCount': FieldValue.increment(1),
            'updatedAt': now,
          },
          SetOptions(merge: true));
    });
    await MarketRepository.ensure().invalidateItemCaches(
      userId: uid,
      docId: itemId,
    );
  }

  static Future<void> unsave(String uid, String itemId) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await _firestore.runTransaction((transaction) async {
      final savedRef = _userSavedDoc(uid, itemId);
      final favoriteRef = _favoriteDoc(itemId, uid);
      final itemRef = _itemDoc(itemId);
      final savedSnap = await transaction.get(savedRef);
      if (!savedSnap.exists) return;
      transaction.delete(savedRef);
      transaction.delete(favoriteRef);
      transaction.set(
          itemRef,
          {
            'favoriteCount': FieldValue.increment(-1),
            'updatedAt': now,
          },
          SetOptions(merge: true));
    });
    await MarketRepository.ensure().invalidateItemCaches(
      userId: uid,
      docId: itemId,
    );
  }
}
