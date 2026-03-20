import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:turqappv2/Core/Repositories/conversation_repository.dart';
import 'package:turqappv2/Core/Utils/text_normalization_utils.dart';

import '../../../Models/chat_listing_model.dart';
import '../../../Core/Services/network_awareness_service.dart';
import '../../../Core/Services/user_profile_cache_service.dart';
import '../CreateChat/create_chat.dart';

class ChatListingController extends GetxController {
  RxList<ChatListingModel> list = <ChatListingModel>[].obs;
  RxList<ChatListingModel> filteredList = <ChatListingModel>[].obs;
  RxString selectedTab = "all".obs;

  TextEditingController search = TextEditingController();
  var waiting = false.obs;
  Timer? _searchDebounce;
  Timer? _syncTimer;
  Timer? _realtimeRefreshDebounce;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _conversationsSub;
  bool _isRefreshing = false;
  bool _cacheLoaded = false;
  final ConversationRepository _conversationRepository =
      ConversationRepository.ensure();

  NetworkAwarenessService? get _network =>
      Get.isRegistered<NetworkAwarenessService>()
          ? Get.find<NetworkAwarenessService>()
          : null;

  bool get _isOffline => _network?.currentNetwork == NetworkType.none;
  bool get _isOnWiFi => _network?.isOnWiFi ?? true;
  String get _uid => FirebaseAuth.instance.currentUser!.uid;
  Duration get _syncInterval {
    if (_isOffline) return const Duration(seconds: 25);
    return _isOnWiFi
        ? const Duration(seconds: 12)
        : const Duration(seconds: 18);
  }

  @override
  void onInit() {
    super.onInit();
    search.addListener(_onSearchChanged);
    _restoreCachedList();
    // Initial load is cache-first; realtime listener will hydrate fresh data.
    getList(forceServer: false);
    startConversationListener();
  }

  String get _cacheKey {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    return uid == null ? '' : 'chat_listing_cache_$uid';
  }

  Future<void> _restoreCachedList() async {
    if (_cacheLoaded) return;
    final cached = await _loadCachedList();
    if (cached == null || cached.isEmpty) return;
    list.value = cached;
    if (search.text.trim().isEmpty) {
      _applyTabFilter();
    } else {
      _onSearchChanged();
    }
    _cacheLoaded = true;
  }

  Future<List<ChatListingModel>?> _loadCachedList() async {
    final key = _cacheKey;
    if (key.isEmpty) return null;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(key);
      if (raw == null || raw.isEmpty) return null;
      final decoded = jsonDecode(raw);
      if (decoded is! List) return null;
      return decoded
          .whereType<Map<String, dynamic>>()
          .map(ChatListingModel.fromJson)
          .toList();
    } catch (_) {
      return null;
    }
  }

  Future<void> _saveCachedList(List<ChatListingModel> items) async {
    if (items.isEmpty) return;
    final key = _cacheKey;
    if (key.isEmpty) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final payload = jsonEncode(items.map((e) => e.toJson()).toList());
      await prefs.setString(key, payload);
    } catch (_) {}
  }

  void _onSearchChanged() {
    final query = search.text.trim();

    if (query.isEmpty) {
      _applyTabFilter();
      return;
    }

    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 280), () async {
      await _searchInChats(query);
    });
  }

  Future<void> _searchInChats(String query) async {
    final q = normalizeSearchText(query);
    final base = _tabbedList();
    if (q.isEmpty) {
      filteredList.value = base;
      return;
    }

    waiting.value = true;
    try {
      // Cache-first arama: lokal listeden eşleşme (ek Firestore sorgusu yok)
      final direct = base.where((item) {
        return normalizeSearchText(item.nickname).contains(q) ||
            normalizeSearchText(item.fullName).contains(q) ||
            normalizeSearchText(item.lastMessage).contains(q);
      }).toList();

      final byUser = <String, ChatListingModel>{};
      for (final item in direct) {
        byUser[item.userID] = item;
      }
      filteredList.value = byUser.values.toList()
        ..sort((a, b) {
          final aTs = int.tryParse(a.timeStamp) ?? 0;
          final bTs = int.tryParse(b.timeStamp) ?? 0;
          return bTs.compareTo(aTs);
        });
    } finally {
      waiting.value = false;
    }
  }

  Future<void> getList({bool forceServer = false, bool silent = false}) async {
    if (_isRefreshing) return;
    _isRefreshing = true;
    if (!silent) waiting.value = true;
    try {
      final cacheOnly = _isOffline;
      // Online'da sadece zorlandığında server'a git; realtime stream değişim
      // geldiğinde çoğu durumda cache-first yeterlidir.
      final shouldHitServer = !cacheOnly && forceServer;

      final archiveOverrides = await _fetchArchiveOverrides(
        preferCache: !shouldHitServer,
        cacheOnly: cacheOnly,
      );
      final deletedOverrides = await _fetchDeletedOverrides(
        preferCache: !shouldHitServer,
        cacheOnly: cacheOnly,
      );
      List<ChatListingModel> conversations = <ChatListingModel>[];
      try {
        conversations = await _fetchConversations(
          preferCache: !shouldHitServer,
          cacheOnly: cacheOnly,
        );
      } catch (_) {}

      final mergedByUser = <String, ChatListingModel>{};
      for (final item in conversations) {
        final existing = mergedByUser[item.userID];
        final forcedArchiveValue = archiveOverrides[item.userID];
        final deletedUntil = deletedOverrides[item.userID];
        if (forcedArchiveValue == true &&
            !item.deleted.contains("__archived__")) {
          item.deleted = [...item.deleted, "__archived__"];
        } else if (forcedArchiveValue == false &&
            item.deleted.contains("__archived__")) {
          item.deleted =
              item.deleted.where((e) => e != "__archived__").toList();
        }
        final itemTs = int.tryParse(item.timeStamp) ?? 0;
        final itemIsDeleted = deletedUntil != null && itemTs <= deletedUntil;
        if (itemIsDeleted && !item.deleted.contains("__deleted__")) {
          item.deleted = [...item.deleted, "__deleted__"];
        } else if (!itemIsDeleted && item.deleted.contains("__deleted__")) {
          item.deleted = item.deleted.where((e) => e != "__deleted__").toList();
        }
        if (existing == null) {
          mergedByUser[item.userID] = item;
          continue;
        }

        final archivedEither = existing.deleted.contains("__archived__") ||
            item.deleted.contains("__archived__");
        final archivedForced = forcedArchiveValue == true;
        final unarchivedForced = forcedArchiveValue == false;
        final pinnedEither = existing.isPinned || item.isPinned;
        final mutedEither = existing.isMuted || item.isMuted;

        final currentTs = itemTs;
        final existingTs = int.tryParse(existing.timeStamp) ?? 0;
        final existingIsDeleted =
            deletedUntil != null && existingTs <= deletedUntil;
        final shouldReplace = currentTs >= existingTs;
        if (shouldReplace) {
          if (item.lastMessage.isEmpty && existing.lastMessage.isNotEmpty) {
            item.lastMessage = existing.lastMessage;
          }
          if ((archivedEither || archivedForced) &&
              !unarchivedForced &&
              !item.deleted.contains("__archived__")) {
            item.deleted = [...item.deleted, "__archived__"];
          } else if (unarchivedForced &&
              item.deleted.contains("__archived__")) {
            item.deleted =
                item.deleted.where((e) => e != "__archived__").toList();
          }
          if (itemIsDeleted && !item.deleted.contains("__deleted__")) {
            item.deleted = [...item.deleted, "__deleted__"];
          } else if (!itemIsDeleted && item.deleted.contains("__deleted__")) {
            item.deleted =
                item.deleted.where((e) => e != "__deleted__").toList();
          }
          item.isPinned = pinnedEither;
          item.isMuted = mutedEither;
          mergedByUser[item.userID] = item;
        } else {
          if ((archivedEither || archivedForced) &&
              !unarchivedForced &&
              !existing.deleted.contains("__archived__")) {
            existing.deleted = [...existing.deleted, "__archived__"];
          } else if (unarchivedForced &&
              existing.deleted.contains("__archived__")) {
            existing.deleted =
                existing.deleted.where((e) => e != "__archived__").toList();
          }
          if (existingIsDeleted && !existing.deleted.contains("__deleted__")) {
            existing.deleted = [...existing.deleted, "__deleted__"];
          } else if (!existingIsDeleted &&
              existing.deleted.contains("__deleted__")) {
            existing.deleted =
                existing.deleted.where((e) => e != "__deleted__").toList();
          }
          existing.isPinned = pinnedEither;
          existing.isMuted = mutedEither;
          mergedByUser[item.userID] = existing;
        }
      }

      final tempList = mergedByUser.values.toList()
        ..sort((a, b) {
          if (a.isPinned != b.isPinned) {
            return a.isPinned ? -1 : 1;
          }
          final aTs = int.tryParse(a.timeStamp) ?? 0;
          final bTs = int.tryParse(b.timeStamp) ?? 0;
          return bTs.compareTo(aTs);
        });

      list.value = tempList;
      if (search.text.trim().isEmpty) {
        _applyTabFilter();
      } else {
        _onSearchChanged();
      }
    } finally {
      _isRefreshing = false;
      if (!silent) waiting.value = false;
    }
    _saveCachedList(list.toList());
  }

  Future<Map<String, bool>> _fetchArchiveOverrides({
    required bool preferCache,
    required bool cacheOnly,
  }) async {
    return _conversationRepository.fetchArchiveOverrides(
      _uid,
      preferCache: preferCache,
      cacheOnly: cacheOnly,
    );
  }

  Future<Map<String, int>> _fetchDeletedOverrides({
    required bool preferCache,
    required bool cacheOnly,
  }) async {
    return _conversationRepository.fetchDeletedOverrides(
      _uid,
      preferCache: preferCache,
      cacheOnly: cacheOnly,
    );
  }

  Future<List<ChatListingModel>> _fetchConversations({
    required bool preferCache,
    required bool cacheOnly,
  }) async {
    final tempList = <ChatListingModel>[];
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final prefs = await SharedPreferences.getInstance();
    final docs = await _conversationRepository.fetchUserConversations(
      uid,
      preferCache: preferCache,
      cacheOnly: cacheOnly,
      includeLegacy: true,
    );
    if (docs.isEmpty) {
      return tempList;
    }

    final userCache = Get.find<UserProfileCacheService>();
    for (final doc in docs) {
      final data = doc.data();
      final archivedMap = data["archived"] is Map
          ? Map<String, dynamic>.from(data["archived"] as Map)
          : <String, dynamic>{};
      final pinnedMap = data["pinned"] is Map
          ? Map<String, dynamic>.from(data["pinned"] as Map)
          : <String, dynamic>{};
      final mutedMap = data["muted"] is Map
          ? Map<String, dynamic>.from(data["muted"] as Map)
          : <String, dynamic>{};
      final isArchived = archivedMap[uid] == true;
      final isPinned = pinnedMap[uid] == true;
      final isMuted = mutedMap[uid] == true;
      final userID1 = (data["userID1"] ?? "").toString().trim();
      final userID2 = (data["userID2"] ?? "").toString().trim();
      var participants = data["participants"] is List
          ? List<String>.from(
              (data["participants"] as List).map((e) => e.toString().trim()),
            ).where((e) => e.isNotEmpty).toList()
          : <String>[];

      if (participants.length != 2 || !participants.contains(uid)) {
        final inferred = <String>{};
        if (userID1.isNotEmpty) inferred.add(userID1);
        if (userID2.isNotEmpty) inferred.add(userID2);
        for (final part in doc.id.split('_')) {
          final cleaned = part.trim();
          if (cleaned.isNotEmpty) inferred.add(cleaned);
        }
        if (inferred.length == 2 && inferred.contains(uid)) {
          participants = inferred.toList()..sort();
          unawaited(
            FirebaseFirestore.instance
                .collection("conversations")
                .doc(doc.id)
                .set({
              "participants": participants,
              "userID1": participants.first,
              "userID2": participants.last,
            }, SetOptions(merge: true)),
          );
        }
      }

      String? otherUserId = participants.firstWhereOrNull((v) => v != uid);
      if ((otherUserId == null || otherUserId.isEmpty) &&
          userID1.isNotEmpty &&
          userID2.isNotEmpty) {
        if (userID1 == uid) otherUserId = userID2;
        if (userID2 == uid) otherUserId = userID1;
      }
      if (otherUserId == null || otherUserId.isEmpty) continue;
      final userData = await userCache.getProfile(
        otherUserId,
        preferCache: preferCache,
        cacheOnly: cacheOnly,
      );
      if (userData == null) continue;
      final unreadMap = data["unread"] is Map
          ? Map<String, dynamic>.from(data["unread"] as Map)
          : <String, dynamic>{};
      final rawUnread = unreadMap[uid];
      final serverUnread = rawUnread is num
          ? rawUnread.toInt()
          : int.tryParse("$rawUnread") ?? 0;
      final lastMessageAt = data["lastMessageAt"];
      int ts = 0;
      if (lastMessageAt is Timestamp) {
        ts = lastMessageAt.millisecondsSinceEpoch;
      } else {
        final fallbackTs = data["lastMessageAtMs"];
        ts = fallbackTs is int ? fallbackTs : int.tryParse("$fallbackTs") ?? 0;
      }
      final lastSenderId = (data["lastSenderId"] ?? "").toString();
      final seenKey = "chat_last_opened_${uid}_${doc.id}";
      final seenTs = prefs.getInt(seenKey) ?? 0;
      final localUnread =
          lastSenderId.isNotEmpty && lastSenderId != uid && ts > seenTs;
      final seenCoversLatestMessage = ts > 0 && seenTs >= ts;
      final unreadCount = seenCoversLatestMessage
          ? 0
          : math.max(serverUnread, localUnread ? 1 : 0);

      tempList.add(ChatListingModel(
        chatID: doc.id,
        userID: otherUserId,
        timeStamp: ts.toString(),
        deleted: isArchived ? const ["__archived__"] : const [],
        nickname: (userData["nickname"] ??
                userData["username"] ??
                userData["displayName"] ??
                "")
            .toString(),
        fullName: "${userData["firstName"] ?? ""} ${userData["lastName"] ?? ""}"
            .trim(),
        avatarUrl: (userData["avatarUrl"] ??
                userData["avatarUrl"] ??
                userData["avatarUrl"] ??
                "")
            .toString(),
        lastMessage: data["lastMessage"] ?? "",
        unreadCount: unreadCount,
        isConversation: true,
        isPinned: isPinned,
        isMuted: isMuted,
      ));
    }

    return tempList;
  }

  void startConversationListener() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    _syncTimer?.cancel();
    _conversationsSub?.cancel();
    if (uid == null) return;

    if (!_isOffline) {
      _conversationsSub = _conversationRepository
          .watchUserConversations(uid)
          .listen((_) {
        _realtimeRefreshDebounce?.cancel();
        _realtimeRefreshDebounce = Timer(const Duration(milliseconds: 350), () {
          getList(forceServer: false, silent: true);
        });
      }, onError: (_) {});
      return;
    }

    _syncTimer = Timer.periodic(_syncInterval, (_) {
      getList(forceServer: false, silent: true);
    });
  }

  void updateUnreadLocal({
    required String chatId,
    required int unreadCount,
  }) {
    bool changed = false;
    for (final item in list) {
      if (item.chatID == chatId) {
        if (item.unreadCount != unreadCount) {
          item.unreadCount = unreadCount;
          changed = true;
        }
      }
    }
    if (!changed) return;

    // Rx list observers refresh
    list.refresh();
    if (search.text.trim().isEmpty) {
      _applyTabFilter();
    } else {
      _onSearchChanged();
    }
    _saveCachedList(list.toList());
  }

  void setTab(String tab) {
    selectedTab.value = tab;
    if (search.text.trim().isEmpty) {
      _applyTabFilter();
    } else {
      _onSearchChanged();
    }
  }

  List<ChatListingModel> _tabbedList() {
    return _applyTabFilterOn(list);
  }

  void _applyTabFilter() {
    filteredList.value = _tabbedList();
  }

  List<ChatListingModel> _applyTabFilterOn(List<ChatListingModel> source) {
    final visible =
        source.where((e) => !e.deleted.contains("__deleted__")).toList();
    if (selectedTab.value == "archive") {
      return visible.where((e) => e.deleted.contains("__archived__")).toList();
    }
    final base =
        visible.where((e) => !e.deleted.contains("__archived__")).toList();
    if (selectedTab.value == "unread") {
      return base.where((e) => e.unreadCount > 0).toList();
    }
    if (selectedTab.value == "favorites") {
      return base;
    }
    return base;
  }

  Future<void> deleteChat(ChatListingModel item) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final conversationTs = int.tryParse(item.timeStamp) ?? 0;
    final deletedCutoff = conversationTs > now ? conversationTs : now;
    await _conversationRepository.setDeletedCutoff(
      currentUid: _uid,
      otherUserId: item.userID,
      chatId: item.chatID,
      deletedAt: deletedCutoff,
    );

    for (final entry in list) {
      if (entry.chatID != item.chatID) continue;
      entry.deleted = entry.deleted
          .where((value) => value != "__archived__" && value != "__deleted__")
          .toList()
        ..add("__deleted__");
    }
    list.refresh();
    if (search.text.trim().isEmpty) {
      _applyTabFilter();
    } else {
      _onSearchChanged();
    }
    _saveCachedList(list.toList());
  }

  void showCreateChatBottomSheet() {
    Get.bottomSheet(
      CreateChat(),
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
    );
  }

  @override
  void onClose() {
    _searchDebounce?.cancel();
    _syncTimer?.cancel();
    _realtimeRefreshDebounce?.cancel();
    _conversationsSub?.cancel();
    search.removeListener(_onSearchChanged);
    search.dispose();
    super.onClose();
  }
}
