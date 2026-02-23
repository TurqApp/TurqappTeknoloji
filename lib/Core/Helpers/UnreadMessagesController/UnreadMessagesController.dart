import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

class UnreadMessagesController extends GetxController {
  final totalUnreadCount = 0.obs;
  StreamSubscription<QuerySnapshot>? _conversationSubscription;
  StreamSubscription<QuerySnapshot>? _legacyAsUser1Subscription;
  StreamSubscription<QuerySnapshot>? _legacyAsUser2Subscription;
  bool _listenersStarted = false;
  final Map<String, int> _conversationUnreadByUser = {};
  final Map<String, int> _legacyUnreadByUser = {};

  @override
  void onInit() {
    super.onInit();
    if (FirebaseAuth.instance.currentUser?.uid != null) {
      startListeners();
    }
  }

  void startListeners() {
    if (_listenersStarted) return;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    _listenersStarted = true;
    _conversationSubscription?.cancel();
    _legacyAsUser1Subscription?.cancel();
    _legacyAsUser2Subscription?.cancel();
    _conversationSubscription = FirebaseFirestore.instance
        .collection("conversations")
        .where("participants", arrayContains: uid)
        .snapshots()
        .listen((snapshot) {
      _conversationUnreadByUser.clear();
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final unreadMap = Map<String, dynamic>.from(data["unread"] ?? {});
        final value = unreadMap[uid];
        final unread = value is int ? value : int.tryParse("$value") ?? 0;
        if (unread <= 0) continue;
        final participants = List<String>.from(data["participants"] ?? []);
        final otherUid = participants.firstWhere(
          (v) => v != uid,
          orElse: () => doc.id,
        );
        _conversationUnreadByUser[otherUid] = unread;
      }
      _recomputeTotalUnread();
    }, onError: (_) {
      _conversationUnreadByUser.clear();
      _recomputeTotalUnread();
    });

    _legacyAsUser1Subscription = FirebaseFirestore.instance
        .collection("message")
        .where("userID1", isEqualTo: uid)
        .snapshots()
        .listen((snapshot) => _processLegacySnapshot(snapshot, uid),
            onError: (_) {});

    _legacyAsUser2Subscription = FirebaseFirestore.instance
        .collection("message")
        .where("userID2", isEqualTo: uid)
        .snapshots()
        .listen((snapshot) => _processLegacySnapshot(snapshot, uid),
            onError: (_) {});
  }

  void _processLegacySnapshot(
    QuerySnapshot snapshot,
    String currentUid,
  ) {
    for (final doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final user1 = (data["userID1"] ?? "").toString();
      final user2 = (data["userID2"] ?? "").toString();
      final otherUid = user1 == currentUid ? user2 : user1;
      if (otherUid.isEmpty) continue;
      final unread = _legacyUnreadCountFromRoot(data, currentUid);
      if (unread > 0) {
        _legacyUnreadByUser[otherUid] = unread;
      } else {
        _legacyUnreadByUser.remove(otherUid);
      }
    }
    _recomputeTotalUnread();
  }

  int _legacyUnreadCountFromRoot(
    Map<String, dynamic> data,
    String currentUid,
  ) {
    final forceUnread = Map<String, dynamic>.from(data["forceUnread"] ?? {});
    if (forceUnread[currentUid] == true) {
      return 1;
    }
    final unreadMap = Map<String, dynamic>.from(data["unread"] ?? {});
    final rawUnread = unreadMap[currentUid];
    final unread =
        rawUnread is int ? rawUnread : int.tryParse("$rawUnread") ?? 0;
    return unread < 0 ? 0 : unread;
  }

  void _recomputeTotalUnread() {
    final allUsers = <String>{
      ..._conversationUnreadByUser.keys,
      ..._legacyUnreadByUser.keys,
    };
    totalUnreadCount.value = allUsers
        .where((u) =>
            (_conversationUnreadByUser[u] ?? 0) > 0 ||
            (_legacyUnreadByUser[u] ?? 0) > 0)
        .length;
  }

  Future<void> refreshUnreadCount() async {
    _conversationSubscription?.cancel();
    _listenersStarted = false;
    startListeners();
  }

  void _cancelAllSubscriptions() {
    _conversationSubscription?.cancel();
    _legacyAsUser1Subscription?.cancel();
    _legacyAsUser2Subscription?.cancel();
    _conversationSubscription = null;
    _legacyAsUser1Subscription = null;
    _legacyAsUser2Subscription = null;
    _conversationUnreadByUser.clear();
    _legacyUnreadByUser.clear();
    totalUnreadCount.value = 0;
    _listenersStarted = false;
  }

  @override
  void onClose() {
    _cancelAllSubscriptions();
    super.onClose();
  }
}
