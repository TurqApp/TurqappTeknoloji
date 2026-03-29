part of 'conversation_repository.dart';

extension ConversationRepositoryHelpersPart on ConversationRepository {
  List<String> _sanitizeParticipantIds(dynamic raw) {
    if (raw is! List) return const <String>[];
    return raw
        .map((item) => item?.toString().trim() ?? '')
        .where((item) => item.isNotEmpty)
        .toSet()
        .toList(growable: false);
  }

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
    final participants = _sanitizeParticipantIds(data["participants"]);
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

    final existingParticipants = _sanitizeParticipantIds(
      existing["participants"],
    );
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
