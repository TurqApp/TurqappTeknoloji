import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:async';

import '../../../Models/ChatListingModel.dart';
import '../CreateChat/CreateChat.dart';

class ChatListingController extends GetxController {
  RxList<ChatListingModel> list = <ChatListingModel>[].obs;
  RxList<ChatListingModel> filteredList = <ChatListingModel>[].obs;
  RxString selectedTab = "all".obs;

  TextEditingController search = TextEditingController();
  var waiting = false.obs;
  StreamSubscription<QuerySnapshot>? _conversationListener;
  StreamSubscription<QuerySnapshot>? _legacyListenerAsUser1;
  StreamSubscription<QuerySnapshot>? _legacyListenerAsUser2;
  Timer? _searchDebounce;

  @override
  void onInit() {
    super.onInit();
    search.addListener(_onSearchChanged);
    getList();
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
      // Hızlı eşleşme: kullanıcı adı/ad soyad/son mesaj
      final direct = base.where((item) {
        return item.nickname.toLowerCase().contains(q) ||
            item.fullName.toLowerCase().contains(q) ||
            item.lastMessage.toLowerCase().contains(q);
      }).toList();

      // Mesaj içi eşleşme: her sohbette yakın geçmişten tarama
      final deepMatched = <ChatListingModel>[];
      final candidates = base.take(100).toList(); // kapsamlı ama kontrollü
      final checks = await Future.wait(
        candidates.map((item) => _chatHasMessageMatch(item, q)),
      );
      for (var i = 0; i < candidates.length; i++) {
        if (checks[i]) deepMatched.add(candidates[i]);
      }

      final byUser = <String, ChatListingModel>{};
      for (final item in [...direct, ...deepMatched]) {
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

  Future<bool> _chatHasMessageMatch(ChatListingModel item, String q) async {
    try {
      if (item.isConversation) {
        final snap = await FirebaseFirestore.instance
            .collection("conversations")
            .doc(item.chatID)
            .collection("messages")
            .orderBy("createdAt", descending: true)
            .limit(25)
            .get();
        for (final d in snap.docs) {
          final text = (d.data()["text"] ?? "").toString().toLowerCase();
          if (text.contains(q)) return true;
        }
        return false;
      }

      final snap = await FirebaseFirestore.instance
          .collection("Mesajlar")
          .doc(item.chatID)
          .collection("Chat")
          .orderBy("timeStamp", descending: true)
          .limit(25)
          .get();
      for (final d in snap.docs) {
        final text = (d.data()["metin"] ?? "").toString().toLowerCase();
        if (text.contains(q)) return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<void> getList() async {
    waiting.value = true;
    try {
      final archiveOverrides = await _fetchArchiveOverrides();
      List<ChatListingModel> conversations = <ChatListingModel>[];
      List<ChatListingModel> legacy = <ChatListingModel>[];
      try {
        conversations = await _fetchConversations();
      } catch (_) {}
      try {
        legacy = await _fetchLegacyChats();
      } catch (_) {}

      final mergedByUser = <String, ChatListingModel>{};
      for (final item in [...legacy, ...conversations]) {
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
    } finally {
      waiting.value = false;
    }
  }

  Future<Map<String, bool>> _fetchArchiveOverrides() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    try {
      final snap = await FirebaseFirestore.instance
          .collection("users")
          .doc(uid)
          .collection("chatArchives")
          .get();
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

  Future<List<ChatListingModel>> _fetchConversations() async {
    final tempList = <ChatListingModel>[];
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final usersRef = FirebaseFirestore.instance.collection("users");

    final snap = await FirebaseFirestore.instance
        .collection("conversations")
        .where("participants", arrayContains: uid)
        .get();

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
      final userDoc = await usersRef.doc(otherUserId).get();
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

  Future<List<ChatListingModel>> _fetchLegacyChats() async {
    final tempList = <ChatListingModel>[];
    final uid = FirebaseAuth.instance.currentUser!.uid;

    final snap1 = await FirebaseFirestore.instance
        .collection("Mesajlar")
        .where("userID1", isEqualTo: uid)
        .get();
    for (var doc in snap1.docs) {
      final data = doc.data();
      final deletedRaw = data["deleted"];
      final deletedList = deletedRaw is List
          ? deletedRaw.map((e) => "$e").toList()
          : <String>[];
      final archivedMap = Map<String, dynamic>.from(data["archived"] ?? {});
      final pinnedMap = Map<String, dynamic>.from(data["pinned"] ?? {});
      final mutedMap = Map<String, dynamic>.from(data["muted"] ?? {});
      if (archivedMap[uid] == true && !deletedList.contains("__archived__")) {
        deletedList.add("__archived__");
      }
      if (!deletedList.contains(uid)) {
        final docc = await FirebaseFirestore.instance
            .collection("users")
            .doc(doc.get("userID2"))
            .get();
        if (!docc.exists) continue;
        final userData = docc.data() ?? {};
        final unreadCount = _legacyUnreadCountFromRoot(data, uid);
        tempList.add(ChatListingModel(
          chatID: doc.id,
          userID: doc.get("userID2"),
          timeStamp: "${data["timeStamp"] ?? 0}",
          deleted: deletedList,
          nickname: (userData["nickname"] ?? "").toString(),
          fullName:
              "${(userData["firstName"] ?? "").toString()} ${(userData["lastName"] ?? "").toString()}"
                  .trim(),
          pfImage: (userData["pfImage"] ?? "").toString(),
          lastMessage: (data["lastMessage"] ?? "").toString(),
          unreadCount: unreadCount,
          isConversation: false,
          isPinned: pinnedMap[uid] == true,
          isMuted: mutedMap[uid] == true,
        ));
      }
    }

    final snap2 = await FirebaseFirestore.instance
        .collection("Mesajlar")
        .where("userID2", isEqualTo: uid)
        .get();
    for (var doc in snap2.docs) {
      final data = doc.data();
      final deletedRaw = data["deleted"];
      final deletedList = deletedRaw is List
          ? deletedRaw.map((e) => "$e").toList()
          : <String>[];
      final archivedMap = Map<String, dynamic>.from(data["archived"] ?? {});
      final pinnedMap = Map<String, dynamic>.from(data["pinned"] ?? {});
      final mutedMap = Map<String, dynamic>.from(data["muted"] ?? {});
      if (archivedMap[uid] == true && !deletedList.contains("__archived__")) {
        deletedList.add("__archived__");
      }
      if (!deletedList.contains(uid)) {
        final docc = await FirebaseFirestore.instance
            .collection("users")
            .doc(doc.get("userID1"))
            .get();
        if (!docc.exists) continue;
        final userData = docc.data() ?? {};
        final unreadCount = _legacyUnreadCountFromRoot(data, uid);
        tempList.add(ChatListingModel(
          chatID: doc.id,
          userID: doc.get("userID1"),
          timeStamp: "${data["timeStamp"] ?? 0}",
          deleted: deletedList,
          nickname: (userData["nickname"] ?? "").toString(),
          fullName:
              "${(userData["firstName"] ?? "").toString()} ${(userData["lastName"] ?? "").toString()}"
                  .trim(),
          pfImage: (userData["pfImage"] ?? "").toString(),
          lastMessage: (data["lastMessage"] ?? "").toString(),
          unreadCount: unreadCount,
          isConversation: false,
          isPinned: pinnedMap[uid] == true,
          isMuted: mutedMap[uid] == true,
        ));
      }
    }

    tempList.sort((a, b) {
      if (a.isPinned != b.isPinned) {
        return a.isPinned ? -1 : 1;
      }
      final aTs = int.tryParse(a.timeStamp) ?? 0;
      final bTs = int.tryParse(b.timeStamp) ?? 0;
      return bTs.compareTo(aTs);
    });

    return tempList;
  }

  int _legacyUnreadCountFromRoot(Map<String, dynamic> data, String uid) {
    final forceUnread = Map<String, dynamic>.from(data["forceUnread"] ?? {});
    if (forceUnread[uid] == true) {
      return 1;
    }
    final unreadMap = Map<String, dynamic>.from(data["unread"] ?? {});
    final rawUnread = unreadMap[uid];
    final unread =
        rawUnread is int ? rawUnread : int.tryParse("$rawUnread") ?? 0;
    return unread < 0 ? 0 : unread;
  }

  void startConversationListener() {
    _conversationListener?.cancel();
    _legacyListenerAsUser1?.cancel();
    _legacyListenerAsUser2?.cancel();
    final uid = FirebaseAuth.instance.currentUser!.uid;

    _conversationListener = FirebaseFirestore.instance
        .collection("conversations")
        .where("participants", arrayContains: uid)
        .snapshots()
        .listen((_) {
      getList();
    });

    _legacyListenerAsUser1 = FirebaseFirestore.instance
        .collection("Mesajlar")
        .where("userID1", isEqualTo: uid)
        .snapshots()
        .listen((_) => getList());

    _legacyListenerAsUser2 = FirebaseFirestore.instance
        .collection("Mesajlar")
        .where("userID2", isEqualTo: uid)
        .snapshots()
        .listen((_) => getList());
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
    _conversationListener?.cancel();
    _legacyListenerAsUser1?.cancel();
    _legacyListenerAsUser2?.cancel();
    search.removeListener(_onSearchChanged);
    search.dispose();
    super.onClose();
  }
}
