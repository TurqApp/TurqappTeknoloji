import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';

class NotificationsRepository extends GetxService {
  static NotificationsRepository ensure() {
    if (Get.isRegistered<NotificationsRepository>()) {
      return Get.find<NotificationsRepository>();
    }
    return Get.put(NotificationsRepository(), permanent: true);
  }

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> _settingsRef(String uid) => _firestore
      .collection('users')
      .doc(uid)
      .collection('settings')
      .doc('notifications');

  CollectionReference<Map<String, dynamic>> _notificationsRef(String uid) =>
      _firestore.collection('users').doc(uid).collection('notifications');

  DocumentReference<Map<String, dynamic>> inboxDoc(
    String uid, {
    String? docId,
  }) {
    final trimmedUid = uid.trim();
    return docId == null || docId.trim().isEmpty
        ? _notificationsRef(trimmedUid).doc()
        : _notificationsRef(trimmedUid).doc(docId.trim());
  }

  Future<void> createInboxItem(
    String uid,
    Map<String, dynamic> payload,
  ) async {
    if (uid.trim().isEmpty || payload.isEmpty) return;
    final now = DateTime.now().millisecondsSinceEpoch;
    final data = <String, dynamic>{
      'userID': uid.trim(),
      'timeStamp': payload['timeStamp'] ?? now,
      'read': payload['read'] ?? false,
      'isRead': payload['isRead'] ?? payload['read'] ?? false,
      ...payload,
    };
    await inboxDoc(uid.trim()).set(data);
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> watchSettings(String uid) {
    return _settingsRef(uid).snapshots();
  }

  Future<QuerySnapshot<Map<String, dynamic>>> fetchCachedNotifications(
    String uid, {
    int limit = 300,
  }) {
    return _notificationsRef(uid)
        .orderBy('timeStamp', descending: true)
        .limit(limit)
        .get(const GetOptions(source: Source.cache));
  }

  Future<QuerySnapshot<Map<String, dynamic>>> fetchServerNotifications(
    String uid, {
    int limit = 300,
  }) {
    return _notificationsRef(uid)
        .orderBy('timeStamp', descending: true)
        .limit(limit)
        .get(const GetOptions(source: Source.server));
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchCachedNotifications(
    String uid, {
    int limit = 300,
  }) {
    return _notificationsRef(uid)
        .orderBy('timeStamp', descending: true)
        .limit(limit)
        .snapshots(source: ListenSource.cache);
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchNotificationHead(
      String uid) {
    return _notificationsRef(uid)
        .orderBy('timeStamp', descending: true)
        .limit(1)
        .snapshots();
  }

  Future<QuerySnapshot<Map<String, dynamic>>> fetchOnlyNewNotifications(
    String uid, {
    required int latestTs,
    int limit = 120,
  }) {
    Query<Map<String, dynamic>> query = _notificationsRef(uid)
        .orderBy('timeStamp', descending: false)
        .limit(limit);
    if (latestTs > 0) {
      query = query.where('timeStamp', isGreaterThan: latestTs);
    }
    return query.get(const GetOptions(source: Source.server));
  }

  Future<void> delete(String uid, String docId) {
    return _notificationsRef(uid).doc(docId).delete();
  }

  Future<void> deleteMany(String uid, List<String> docIds) async {
    if (docIds.isEmpty) return;
    final uniqueIds = docIds.toSet().toList(growable: false);
    for (var i = 0; i < uniqueIds.length; i += 450) {
      final batch = _firestore.batch();
      final chunk = uniqueIds.skip(i).take(450);
      for (final docID in chunk) {
        batch.delete(_notificationsRef(uid).doc(docID));
      }
      await batch.commit();
    }
  }

  Future<void> markRead(String uid, String docId) {
    return _notificationsRef(uid)
        .doc(docId)
        .set({'read': true, 'isRead': true}, SetOptions(merge: true));
  }

  Future<void> markManyRead(String uid, List<String> docIds) async {
    if (docIds.isEmpty) return;
    final uniqueIds = docIds.toSet().toList(growable: false);
    for (var i = 0; i < uniqueIds.length; i += 450) {
      final batch = _firestore.batch();
      final chunk = uniqueIds.skip(i).take(450);
      for (final docID in chunk) {
        batch.set(
          _notificationsRef(uid).doc(docID),
          {'read': true, 'isRead': true},
          SetOptions(merge: true),
        );
      }
      await batch.commit();
    }
  }

  Future<void> deleteAll(String uid) async {
    while (true) {
      final snapshot = await _notificationsRef(uid).limit(500).get();
      if (snapshot.docs.isEmpty) break;
      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
      await Future.delayed(const Duration(milliseconds: 100));
    }
  }
}
