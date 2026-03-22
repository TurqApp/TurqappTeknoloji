import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Models/market_item_model.dart';
import 'package:turqappv2/Modules/Chat/chat_constants.dart';

part 'conversation_repository_query_part.dart';
part 'conversation_repository_message_part.dart';
part 'conversation_repository_state_part.dart';

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

  bool participantBoolValue(
    dynamic raw,
    String uid, {
    bool defaultValue = false,
  }) {
    return _sanitizeBoolParticipantMap(
          raw,
          <String>[uid],
          defaultValue: defaultValue,
        )[uid] ??
        defaultValue;
  }

  int participantIntValue(
    dynamic raw,
    String uid, {
    int defaultValue = 0,
    bool nonNegative = true,
  }) {
    return _sanitizeIntParticipantMap(
          raw,
          <String>[uid],
          defaultValue: defaultValue,
          nonNegative: nonNegative,
        )[uid] ??
        defaultValue;
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

  Map<String, dynamic> _buildConversationEnvelope({
    required Map<String, dynamic>? existing,
    required String currentUid,
    required String otherUid,
    required String lastMessage,
    required int nowMs,
  }) {
    final participants = [currentUid, otherUid]..sort();
    if (existing == null) {
      return {
        "participants": participants,
        "userID1": participants.first,
        "userID2": participants.last,
        "lastMessage": lastMessage,
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
      };
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
    return {
      if (!hasCanonicalParticipants) "participants": participants,
      if (!hasCanonicalParticipants) "userID1": participants.first,
      if (!hasCanonicalParticipants) "userID2": participants.last,
      "lastMessage": lastMessage,
      "lastMessageAt": nowMs,
      "lastMessageAtMs": nowMs,
      "lastSenderId": currentUid,
      "archived": archived,
      "unread": unread,
      "typing": typing,
      "muted": muted,
      "pinned": pinned,
      "chatBg": chatBg,
    };
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
