part of 'notifications_repository.dart';

extension _NotificationsRepositoryHelpersX on NotificationsRepository {
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

  Map<String, dynamic> normalizeInboxPayload(
    String uid,
    Map<String, dynamic> payload,
  ) {
    final trimmedUid = uid.trim();
    final now = DateTime.now().millisecondsSinceEpoch;
    final imageUrl = _resolveInboxImageUrl(payload);
    final thumbnail = _firstNonEmptyString(<dynamic>[
      payload['thumbnail'],
      imageUrl,
    ]);
    return <String, dynamic>{
      ...payload,
      'userID': trimmedUid,
      'timeStamp': payload['timeStamp'] ?? now,
      'read': payload['read'] ?? false,
      'isRead': payload['isRead'] ?? payload['read'] ?? false,
      if (imageUrl.isNotEmpty) 'imageUrl': imageUrl,
      if (thumbnail.isNotEmpty) 'thumbnail': thumbnail,
    };
  }

  String _resolveInboxImageUrl(Map<String, dynamic> payload) {
    return _firstNonEmptyString(<dynamic>[
      payload['imageUrl'],
      payload['thumbnail'],
      payload['imageURL'],
      payload['avatarUrl'],
      payload['applicantPfImage'],
      payload['tutorImage'],
      payload['companyLogo'],
      payload['logo'],
      payload['coverImageUrl'],
      payload['img'],
      payload['images'],
    ]);
  }

  String _firstNonEmptyString(List<dynamic> values) {
    for (final value in values) {
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
      if (value is Iterable) {
        for (final entry in value) {
          if (entry is String && entry.trim().isNotEmpty) {
            return entry.trim();
          }
        }
      }
    }
    return '';
  }
}
