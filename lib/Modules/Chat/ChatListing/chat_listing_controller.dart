import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:async';

import '../../../Models/chat_listing_model.dart';
import '../../../Core/Services/network_awareness_service.dart';
import '../CreateChat/create_chat.dart';

class ChatListingController extends GetxController {
  RxList<ChatListingModel> list = <ChatListingModel>[].obs;
  RxList<ChatListingModel> filteredList = <ChatListingModel>[].obs;
  RxString selectedTab = "all".obs;

  TextEditingController search = TextEditingController();
  var waiting = false.obs;
  Timer? _searchDebounce;
  Timer? _syncTimer;
  DateTime? _lastServerSyncAt;
  bool _isRefreshing = false;

  NetworkAwarenessService? get _network =>
      Get.isRegistered<NetworkAwarenessService>()
          ? Get.find<NetworkAwarenessService>()
          : null;

  bool get _isOffline => _network?.currentNetwork == NetworkType.none;
  bool get _isOnWiFi => _network?.isOnWiFi ?? true;

  Duration get _serverSyncGap {
    if (_isOffline) return const Duration(days: 1);
    return _isOnWiFi
        ? const Duration(seconds: 8)
        : const Duration(seconds: 15);
  }

  @override
  void onInit() {
    super.onInit();
    search.addListener(_onSearchChanged);
    getList(forceServer: true);
    startConversationListener();
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
    final q = query.trim().toLowerCase();
    final base = _tabbedList();
    if (q.isEmpty) {
      filteredList.value = base;
      return;
    }

    waiting.value = true;
    try {
      // Cache-first arama: lokal listeden eşleşme (ek Firestore sorgusu yok)
      final direct = base.where((item) {
        return item.nickname.toLowerCase().contains(q) ||
            item.fullName.toLowerCase().contains(q) ||
            item.lastMessage.toLowerCase().contains(q);
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
      final shouldHitServer = !cacheOnly &&
          (forceServer ||
          _lastServerSyncAt == null ||
          DateTime.now().difference(_lastServerSyncAt!) >
              _serverSyncGap);

      final archiveOverrides = await _fetchArchiveOverrides(
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
        if (forcedArchiveValue == true &&
            !item.deleted.contains("__archived__")) {
          item.deleted = [...item.deleted, "__archived__"];
        } else if (forcedArchiveValue == false &&
            item.deleted.contains("__archived__")) {
          item.deleted =
              item.deleted.where((e) => e != "__archived__").toList();
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

        final currentTs = int.tryParse(item.timeStamp) ?? 0;
        final existingTs = int.tryParse(existing.timeStamp) ?? 0;
        final shouldReplace = currentTs >= existingTs;
        if (shouldReplace) {
          if (item.lastMessage.isEmpty && existing.lastMessage.isNotEmpty) {
            item.lastMessage = existing.lastMessage;
          }
          if (item.unreadCount == 0 && existing.unreadCount > 0) {
            item.unreadCount = existing.unreadCount;
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
      if (shouldHitServer) {
        _lastServerSyncAt = DateTime.now();
      }
    } finally {
      _isRefreshing = false;
      if (!silent) waiting.value = false;
    }
  }

  Future<Map<String, bool>> _fetchArchiveOverrides({
    required bool preferCache,
    required bool cacheOnly,
  }) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    try {
      final query = FirebaseFirestore.instance
          .collection("users")
          .doc(uid)
          .collection("chatArchives");
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
        final archived = data["archived"] == true;
        map[userId] = archived;
      }
      return map;
    } catch (_) {
      return <String, bool>{};
    }
  }

  Future<List<ChatListingModel>> _fetchConversations({
    required bool preferCache,
    required bool cacheOnly,
  }) async {
    final tempList = <ChatListingModel>[];
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final usersRef = FirebaseFirestore.instance.collection("users");

    final query = FirebaseFirestore.instance
        .collection("conversations")
        .where("participants", arrayContains: uid);
    final snap = await _getWithCachePreference(
      query,
      preferCache: preferCache,
      cacheOnly: cacheOnly,
    );

    for (final doc in snap.docs) {
      final data = doc.data();
      final archivedMap = Map<String, dynamic>.from(data["archived"] ?? {});
      final pinnedMap = Map<String, dynamic>.from(data["pinned"] ?? {});
      final mutedMap = Map<String, dynamic>.from(data["muted"] ?? {});
      final isArchived = archivedMap[uid] == true;
      final isPinned = pinnedMap[uid] == true;
      final isMuted = mutedMap[uid] == true;
      final participants = List<String>.from(data["participants"] ?? []);
      final otherUserId = participants.firstWhereOrNull((v) => v != uid);
      if (otherUserId == null || otherUserId.isEmpty) continue;
      final userDoc = await _getDocWithCachePreference(
        usersRef.doc(otherUserId),
        preferCache: preferCache,
        cacheOnly: cacheOnly,
      );
      if (!userDoc.exists) continue;
      final userData = userDoc.data() ?? {};
      final unreadMap = Map<String, dynamic>.from(data["unread"] ?? {});
      final rawUnread = unreadMap[uid];
      final unreadCount =
          rawUnread is int ? rawUnread : int.tryParse("$rawUnread") ?? 0;
      final lastMessageAt = data["lastMessageAt"];
      int ts = 0;
      if (lastMessageAt is Timestamp) {
        ts = lastMessageAt.millisecondsSinceEpoch;
      } else {
        final fallbackTs = data["lastMessageAtMs"];
        ts = fallbackTs is int ? fallbackTs : int.tryParse("$fallbackTs") ?? 0;
      }

      tempList.add(ChatListingModel(
        chatID: doc.id,
        userID: otherUserId,
        timeStamp: ts.toString(),
        deleted: isArchived ? const ["__archived__"] : const [],
        nickname: userData["nickname"] ?? "",
        fullName: "${userData["firstName"] ?? ""} ${userData["lastName"] ?? ""}"
            .trim(),
        pfImage: userData["pfImage"] ?? "",
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
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      getList(forceServer: false, silent: true);
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

  Future<DocumentSnapshot<Map<String, dynamic>>> _getDocWithCachePreference(
    DocumentReference<Map<String, dynamic>> ref, {
    required bool preferCache,
    required bool cacheOnly,
  }) async {
    if (preferCache) {
      try {
        final cached = await ref.get(const GetOptions(source: Source.cache));
        if (cached.exists) return cached;
      } catch (_) {}
    }
    if (cacheOnly) {
      return ref.get(const GetOptions(source: Source.cache));
    }
    return ref.get(const GetOptions(source: Source.server));
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
    if (selectedTab.value == "archive") {
      return source.where((e) => e.deleted.contains("__archived__")).toList();
    }
    final base =
        source.where((e) => !e.deleted.contains("__archived__")).toList();
    if (selectedTab.value == "unread") {
      return base.where((e) => e.unreadCount > 0).toList();
    }
    if (selectedTab.value == "favorites") {
      return base;
    }
    return base;
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
    search.removeListener(_onSearchChanged);
    search.dispose();
    super.onClose();
  }
}
