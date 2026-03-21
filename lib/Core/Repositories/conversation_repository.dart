import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Models/market_item_model.dart';
import 'package:turqappv2/Modules/Chat/chat_constants.dart';

class ConversationRepository extends GetxService {
  static ConversationRepository? maybeFind() {
    final isRegistered = Get.isRegistered<ConversationRepository>();
    if (!isRegistered) return null;
    return Get.find<ConversationRepository>();
  }

  static ConversationRepository ensure() {
    final existing = maybeFind();
    if (existing != null) return existing;
    return Get.put(ConversationRepository(), permanent: true);
  }

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Map<String, int> _sanitizeUnreadMap(
    dynamic raw,
    List<String> participants,
  ) {
    final source = raw is Map ? raw : const <String, dynamic>{};
    final result = <String, int>{};
    for (final uid in participants) {
      final value = source[uid];
      if (value is int) {
        result[uid] = value < 0 ? 0 : value;
      } else if (value is num) {
        final parsed = value.toInt();
        result[uid] = parsed < 0 ? 0 : parsed;
      } else if (value is String) {
        final parsed = int.tryParse(value) ?? 0;
        result[uid] = parsed < 0 ? 0 : parsed;
      } else {
        result[uid] = 0;
      }
    }
    return result;
  }

  Map<String, bool> _sanitizeBoolParticipantMap(
    dynamic raw,
    List<String> participants, {
    bool defaultValue = false,
  }) {
    final source = raw is Map ? raw : const <String, dynamic>{};
    final result = <String, bool>{};
    for (final uid in participants) {
      final value = source[uid];
      if (value is bool) {
        result[uid] = value;
      } else if (value is num) {
        result[uid] = value != 0;
      } else {
        result[uid] = defaultValue;
      }
    }
    return result;
  }

  Map<String, int> _sanitizeIntParticipantMap(
    dynamic raw,
    List<String> participants, {
    int defaultValue = 0,
    bool nonNegative = true,
  }) {
    final source = raw is Map ? raw : const <String, dynamic>{};
    final result = <String, int>{};
    for (final uid in participants) {
      final value = source[uid];
      int parsed;
      if (value is int) {
        parsed = value;
      } else if (value is num) {
        parsed = value.toInt();
      } else if (value is String) {
        parsed = int.tryParse(value) ?? defaultValue;
      } else {
        parsed = defaultValue;
      }
      if (nonNegative && parsed < 0) parsed = 0;
      result[uid] = parsed;
    }
    return result;
  }

  String _resolveOtherUidFromConversationDoc(
    String currentUid,
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    final participants = List<String>.from(data["participants"] ?? const []);
    final otherFromParticipants = participants.firstWhere(
      (value) => value != currentUid,
      orElse: () => '',
    );
    if (otherFromParticipants.isNotEmpty) return otherFromParticipants;

    final userId1 = (data["userID1"] ?? "").toString().trim();
    final userId2 = (data["userID2"] ?? "").toString().trim();
    if (userId1.isNotEmpty && userId1 != currentUid) return userId1;
    if (userId2.isNotEmpty && userId2 != currentUid) return userId2;
    return '';
  }

  Map<String, bool> deriveArchiveOverridesFromConversationDocs(
    String currentUid,
    Iterable<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    final map = <String, bool>{};
    for (final doc in docs) {
      final data = doc.data();
      final otherUid = _resolveOtherUidFromConversationDoc(currentUid, doc);
      if (otherUid.isEmpty) continue;
      final archivedMap = data["archived"];
      if (archivedMap is! Map) continue;
      final raw = archivedMap[currentUid];
      if (raw is bool) {
        map[otherUid] = raw;
      } else if (raw is num) {
        map[otherUid] = raw != 0;
      }
    }
    return map;
  }

  Map<String, int> deriveDeletedOverridesFromConversationDocs(
    String currentUid,
    Iterable<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    final map = <String, int>{};
    for (final doc in docs) {
      final data = doc.data();
      final otherUid = _resolveOtherUidFromConversationDoc(currentUid, doc);
      if (otherUid.isEmpty) continue;
      final deletedMap = data["deletedAt"];
      if (deletedMap is! Map) continue;
      final raw = deletedMap[currentUid];
      final deletedAt = raw is int
          ? raw
          : raw is num
              ? raw.toInt()
              : int.tryParse("$raw") ?? 0;
      if (deletedAt > 0) {
        map[otherUid] = deletedAt;
      }
    }
    return map;
  }

  DocumentReference<Map<String, dynamic>> _messageRef(
    String chatId,
    String messageId,
  ) {
    return _firestore
        .collection("conversations")
        .doc(chatId)
        .collection("messages")
        .doc(messageId);
  }

  Future<Map<String, bool>> fetchArchiveOverrides(
    String uid, {
    required bool preferCache,
    required bool cacheOnly,
  }) async {
    try {
      final query =
          _firestore.collection("users").doc(uid).collection("chatArchives");
      final snap = await _getWithCachePreference(
        query,
        preferCache: preferCache,
        cacheOnly: cacheOnly,
      );
      final map = <String, bool>{};
      for (final doc in snap.docs) {
        final data = doc.data();
        final userId = (data["userID"] ?? "").toString();
        if (userId.isEmpty) continue;
        map[userId] = data["archived"] == true;
      }
      return map;
    } catch (_) {
      return <String, bool>{};
    }
  }

  Future<Map<String, int>> fetchDeletedOverrides(
    String uid, {
    required bool preferCache,
    required bool cacheOnly,
  }) async {
    try {
      final query =
          _firestore.collection("users").doc(uid).collection("chatDeletions");
      final snap = await _getWithCachePreference(
        query,
        preferCache: preferCache,
        cacheOnly: cacheOnly,
      );
      final map = <String, int>{};
      for (final doc in snap.docs) {
        final data = doc.data();
        final userId = (data["userID"] ?? "").toString();
        if (userId.isEmpty) continue;
        final rawDeletedAt = data["deletedAt"];
        final deletedAt = rawDeletedAt is num
            ? rawDeletedAt.toInt()
            : int.tryParse("$rawDeletedAt") ?? 0;
        if (deletedAt > 0) {
          map[userId] = deletedAt;
        }
      }
      return map;
    } catch (_) {
      return <String, int>{};
    }
  }

  Future<void> setArchived({
    required String currentUid,
    required String otherUserId,
    required String chatId,
    required bool archived,
  }) async {
    await _firestore
        .collection("users")
        .doc(currentUid)
        .collection("chatArchives")
        .doc(otherUserId)
        .set({
      "userID": otherUserId,
      "chatID": chatId,
      "archived": archived,
      "updatedDate": DateTime.now().millisecondsSinceEpoch,
    }, SetOptions(merge: true));
    try {
      await _firestore.collection("conversations").doc(chatId).set({
        "archived.$currentUid": archived,
      }, SetOptions(merge: true));
    } catch (_) {}
  }

  Future<void> setUnreadCount({
    required String chatId,
    required String currentUid,
    required int unreadCount,
  }) async {
    await _firestore.collection("conversations").doc(chatId).set({
      "unread.$currentUid": unreadCount < 0 ? 0 : unreadCount,
    }, SetOptions(merge: true));
  }

  Future<void> setPinned({
    required String chatId,
    required String currentUid,
    required bool pinned,
  }) async {
    await _firestore.collection("conversations").doc(chatId).set({
      "pinned.$currentUid": pinned,
    }, SetOptions(merge: true));
  }

  Future<void> setMuted({
    required String chatId,
    required String currentUid,
    required bool muted,
  }) async {
    await _firestore.collection("conversations").doc(chatId).set({
      "muted.$currentUid": muted,
    }, SetOptions(merge: true));
  }

  Future<void> setDeletedCutoff({
    required String currentUid,
    required String otherUserId,
    required String chatId,
    required int deletedAt,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final conversationRef = _firestore.collection("conversations").doc(chatId);
    await _firestore
        .collection("users")
        .doc(currentUid)
        .collection("chatDeletions")
        .doc(otherUserId)
        .set({
      "userID": otherUserId,
      "chatID": chatId,
      "deletedAt": deletedAt,
      "updatedDate": now,
    }, SetOptions(merge: true));

    await _firestore
        .collection("users")
        .doc(currentUid)
        .collection("chatArchives")
        .doc(otherUserId)
        .set({
      "userID": otherUserId,
      "chatID": chatId,
      "archived": false,
      "updatedDate": now,
    }, SetOptions(merge: true));

    await conversationRef.set({
      "deletedAt.$currentUid": deletedAt,
      "archived.$currentUid": false,
    }, SetOptions(merge: true));
  }

  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>>
      fetchUserConversations(
    String uid, {
    required bool preferCache,
    required bool cacheOnly,
    bool includeLegacy = true,
  }) async {
    final docsById = <String, QueryDocumentSnapshot<Map<String, dynamic>>>{};

    Future<void> mergeQuery(Query<Map<String, dynamic>> query) async {
      try {
        final snap = await _getWithCachePreference(
          query,
          preferCache: preferCache,
          cacheOnly: cacheOnly,
        );
        for (final doc in snap.docs) {
          docsById[doc.id] = doc;
        }
      } catch (_) {}
    }

    await mergeQuery(
      _firestore.collection("conversations").where(
            "participants",
            arrayContains: uid,
          ),
    );

    if (includeLegacy) {
      await mergeQuery(
        _firestore.collection("conversations").where(
              "userID1",
              isEqualTo: uid,
            ),
      );
      await mergeQuery(
        _firestore.collection("conversations").where(
              "userID2",
              isEqualTo: uid,
            ),
      );
    }

    return docsById.values.toList(growable: false);
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchUserConversations(
      String uid) {
    return _firestore
        .collection("conversations")
        .where("participants", arrayContains: uid)
        .snapshots();
  }

  Future<void> deleteMessageForUser({
    required String chatId,
    required String messageId,
    required String currentUid,
  }) async {
    await _messageRef(chatId, messageId).set({
      "deletedFor": FieldValue.arrayUnion([currentUid]),
    }, SetOptions(merge: true));
  }

  Future<void> unsendMessage({
    required String chatId,
    required String messageId,
  }) async {
    await _messageRef(chatId, messageId).update({
      "unsent": true,
      "text": "",
      "mediaUrls": <String>[],
      "videoUrl": "",
      "videoThumbnail": "",
      "audioUrl": "",
      "audioDurationMs": 0,
      "location": FieldValue.delete(),
      "contact": FieldValue.delete(),
      "postRef": FieldValue.delete(),
      "replyTo": FieldValue.delete(),
    });
  }

  Future<void> toggleMessageLike({
    required String chatId,
    required String messageId,
    required String currentUid,
    required bool isLiked,
  }) async {
    await _messageRef(chatId, messageId).update({
      "likes": isLiked
          ? FieldValue.arrayRemove([currentUid])
          : FieldValue.arrayUnion([currentUid]),
    });
  }

  Future<void> removeMessageImage({
    required String chatId,
    required String messageId,
    required String imgUrl,
  }) async {
    await _messageRef(chatId, messageId).update({
      "mediaUrls": FieldValue.arrayRemove([imgUrl]),
    });
  }

  Future<Map<String, dynamic>?> getConversation(
    String chatId, {
    bool preferCache = true,
    bool cacheOnly = false,
  }) async {
    if (chatId.trim().isEmpty) return null;
    final ref = _firestore.collection("conversations").doc(chatId.trim());
    if (preferCache) {
      try {
        final cached = await ref.get(const GetOptions(source: Source.cache));
        if (cached.exists) {
          return Map<String, dynamic>.from(
            cached.data() ?? const <String, dynamic>{},
          );
        }
      } catch (_) {}
    }
    if (cacheOnly) return null;
    final doc = await ref.get();
    if (!doc.exists) return null;
    return Map<String, dynamic>.from(doc.data() ?? const <String, dynamic>{});
  }

  Future<void> setMarketContext({
    required String chatId,
    required MarketItemModel item,
  }) async {
    if (chatId.trim().isEmpty || item.id.trim().isEmpty) return;
    await _firestore.collection('conversations').doc(chatId.trim()).set({
      'marketContext': {
        'itemId': item.id,
        'title': item.title,
        'coverImageUrl': item.coverImageUrl,
        'sellerId': item.userId,
      },
    }, SetOptions(merge: true));
  }

  Future<void> ensureConversationForPostShare({
    required String chatId,
    required String currentUid,
    required String otherUid,
    required int nowMs,
  }) async {
    final existing = await getConversation(
      chatId,
      preferCache: true,
      cacheOnly: false,
    );
    final participants = [currentUid, otherUid]..sort();

    if (existing == null) {
      await _firestore.collection("conversations").doc(chatId).set({
        "participants": participants,
        "userID1": participants.first,
        "userID2": participants.last,
        "lastMessage": kConversationPostMessageMarker,
        "lastMessageAt": nowMs,
        "lastMessageAtMs": nowMs,
        "lastSenderId": currentUid,
        "archived": {
          currentUid: false,
          otherUid: false,
        },
        "unread": {
          currentUid: 0,
          otherUid: 1,
        },
        "typing": {
          currentUid: 0,
          otherUid: 0,
        },
        "muted": {
          currentUid: false,
          otherUid: false,
        },
        "pinned": {
          currentUid: false,
          otherUid: false,
        },
        "chatBg": {
          currentUid: 0,
          otherUid: 0,
        },
      });
      return;
    }

    final existingParticipants = existing["participants"] is List
        ? List<String>.from(
            (existing["participants"] as List).map((e) => e.toString()),
          )
        : <String>[];
    final hasCanonicalParticipants = existingParticipants.length == 2 &&
        existingParticipants.contains(currentUid) &&
        existingParticipants.contains(otherUid);
    final unread = _sanitizeUnreadMap(existing["unread"], participants);
    unread[currentUid] = 0;
    unread[otherUid] = (unread[otherUid] ?? 0) + 1;
    final archived = _sanitizeBoolParticipantMap(
      existing["archived"],
      participants,
      defaultValue: false,
    );
    archived[currentUid] = false;
    archived[otherUid] = false;
    final typing = _sanitizeIntParticipantMap(
      existing["typing"],
      participants,
      defaultValue: 0,
      nonNegative: true,
    );
    final muted = _sanitizeBoolParticipantMap(
      existing["muted"],
      participants,
      defaultValue: false,
    );
    final pinned = _sanitizeBoolParticipantMap(
      existing["pinned"],
      participants,
      defaultValue: false,
    );
    final chatBg = _sanitizeIntParticipantMap(
      existing["chatBg"],
      participants,
      defaultValue: 0,
      nonNegative: true,
    );
    await _firestore.collection("conversations").doc(chatId).set({
      if (!hasCanonicalParticipants) "participants": participants,
      if (!hasCanonicalParticipants) "userID1": participants.first,
      if (!hasCanonicalParticipants) "userID2": participants.last,
      "lastMessage": kConversationPostMessageMarker,
      "lastMessageAt": nowMs,
      "lastMessageAtMs": nowMs,
      "lastSenderId": currentUid,
      "archived": archived,
      "unread": unread,
      "typing": typing,
      "muted": muted,
      "pinned": pinned,
      "chatBg": chatBg,
    }, SetOptions(merge: true));
  }

  Future<void> addPostShareMessage({
    required String chatId,
    required String currentUid,
    required String postId,
    required String postType,
  }) async {
    await _firestore
        .collection("conversations")
        .doc(chatId)
        .collection("messages")
        .add({
      "senderId": currentUid,
      "text": "",
      "createdDate": DateTime.now().millisecondsSinceEpoch,
      "seenBy": [currentUid],
      "type": "post",
      "mediaUrls": [],
      "likes": <String>[],
      "isDeleted": false,
      "isEdited": false,
      "audioUrl": "",
      "postRef": {
        "postId": postId,
        "postType": postType,
        "previewText": "",
        "previewImageUrl": "",
      }
    });
  }

  Future<QuerySnapshot<Map<String, dynamic>>> _getWithCachePreference(
    Query<Map<String, dynamic>> query, {
    required bool preferCache,
    required bool cacheOnly,
  }) async {
    if (preferCache) {
      try {
        return await query.get(const GetOptions(source: Source.cache));
      } catch (_) {}
    }
    if (cacheOnly) {
      return query.get(const GetOptions(source: Source.cache));
    }
    return query.get(const GetOptions(source: Source.server));
  }
}
