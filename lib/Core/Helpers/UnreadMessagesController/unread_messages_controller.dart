import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:turqappv2/Core/Repositories/conversation_repository.dart';
import 'package:turqappv2/Services/current_user_service.dart';
import '../../Services/network_awareness_service.dart';

class UnreadMessagesController extends GetxController {
  final totalUnreadCount = 0.obs;
  Timer? _syncTimer;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _conversationsSub;
  bool _listenersStarted = false;
  String? _activeUid;
  final Map<String, int> _conversationUnreadByUser = {};
  final Map<String, int> _localReadCutoffByChatId = {};
  final Map<String, int> _persistedReadCutoffByChatId = {};
  bool _readStateReady = false;
  DateTime? _lastServerSyncAt;
  bool _isSyncing = false;
  final ConversationRepository _conversationRepository =
      ConversationRepository.ensure();

  NetworkAwarenessService? get _network =>
      Get.isRegistered<NetworkAwarenessService>()
          ? Get.find<NetworkAwarenessService>()
          : null;

  bool get _isOffline => _network?.currentNetwork == NetworkType.none;
  bool get _isOnWiFi => _network?.isOnWiFi ?? true;

  Duration get _serverSyncGap {
    if (_isOffline) return const Duration(days: 1);
    return _isOnWiFi ? const Duration(seconds: 6) : const Duration(seconds: 12);
  }

  @override
  void onInit() {
    super.onInit();
    if (CurrentUserService.instance.userId.isNotEmpty) {
      startListeners();
    }
  }

  void startListeners({bool force = false}) {
    final uid = CurrentUserService.instance.userId;
    if (uid.isEmpty) return;
    if (!force && _listenersStarted && _activeUid == uid) return;

    _cancelAllSubscriptions();
    _listenersStarted = true;
    _activeUid = uid;
    _readStateReady = false;
    totalUnreadCount.value = 0;
    unawaited(_startAfterReadStateHydrated(uid));
  }

  void _recomputeTotalUnread() {
    if (!_readStateReady) {
      totalUnreadCount.value = 0;
      return;
    }
    totalUnreadCount.value =
        _conversationUnreadByUser.values.where((v) => v > 0).length;
  }

  // Firestore read tetiklemeden, tek konuşmanın unread durumunu localde günceller.
  void updateConversationUnreadLocal({
    required String otherUid,
    required int unreadCount,
    String? chatId,
    int? seenAtMs,
  }) {
    final key = otherUid.trim();
    if (key.isEmpty) return;
    final normalizedChatId = (chatId ?? "").trim();
    if (unreadCount <= 0) {
      _conversationUnreadByUser.remove(key);
      if (normalizedChatId.isNotEmpty) {
        final cutoff = seenAtMs ?? DateTime.now().millisecondsSinceEpoch;
        _localReadCutoffByChatId[normalizedChatId] = cutoff;
        _persistedReadCutoffByChatId[normalizedChatId] = cutoff;
        unawaited(_persistReadCutoff(normalizedChatId, cutoff));
      }
    } else {
      _conversationUnreadByUser[key] = unreadCount;
      if (normalizedChatId.isNotEmpty) {
        _localReadCutoffByChatId.remove(normalizedChatId);
      }
    }
    _recomputeTotalUnread();
  }

  Future<void> refreshUnreadCount() async {
    await _syncUnread(forceServer: true);
  }

  Future<void> _syncUnread({required bool forceServer}) async {
    final uid = CurrentUserService.instance.userId;
    if (uid.isEmpty || _isSyncing) return;

    final cacheOnly = _isOffline;
    final shouldHitServer = !cacheOnly &&
        (forceServer ||
            _lastServerSyncAt == null ||
            DateTime.now().difference(_lastServerSyncAt!) > _serverSyncGap);
    _isSyncing = true;
    try {
      final docs = await _conversationRepository.fetchUserConversations(
        uid,
        preferCache: !shouldHitServer,
        cacheOnly: cacheOnly,
        includeLegacy: false,
      );
      _applyConversationDocs(docs, uid);
      if (shouldHitServer) {
        _lastServerSyncAt = DateTime.now();
      }
    } catch (_) {
      _recomputeTotalUnread();
    } finally {
      _isSyncing = false;
    }
  }

  void _applyConversationDocs(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
    String uid,
  ) {
    _conversationUnreadByUser.clear();
    for (final doc in docs) {
      final data = doc.data();
      final unreadMap = Map<String, dynamic>.from(data["unread"] ?? {});
      final value = unreadMap[uid];
      final serverUnreadRaw =
          value is num ? value.toInt() : int.tryParse("$value") ?? 0;
      var unread = serverUnreadRaw;
      final lastSenderId = (data["lastSenderId"] ?? "").toString();

      int lastMessageAtMs = 0;
      final lastMessageAt = data["lastMessageAt"];
      if (lastMessageAt is Timestamp) {
        lastMessageAtMs = lastMessageAt.millisecondsSinceEpoch;
      } else {
        final fallback = data["lastMessageAtMs"];
        lastMessageAtMs =
            fallback is int ? fallback : int.tryParse("$fallback") ?? 0;
      }
      final localReadCutoff = _localReadCutoffByChatId[doc.id] ?? 0;
      final persistedReadCutoff = _persistedReadCutoffByChatId[doc.id] ?? 0;
      final effectiveReadCutoff = localReadCutoff > persistedReadCutoff
          ? localReadCutoff
          : persistedReadCutoff;
      final shouldForceRead =
          lastMessageAtMs > 0 && effectiveReadCutoff >= lastMessageAtMs;
      final sentBySelf = lastSenderId.isNotEmpty && lastSenderId == uid;
      if (sentBySelf) {
        unread = 0;
      }
      if (shouldForceRead) {
        unread = 0;
      }
      if (unread <= 0) continue;
      final participants = List<String>.from(data["participants"] ?? []);
      final otherUid = participants.firstWhere(
        (v) => v != uid,
        orElse: () => doc.id,
      );
      _conversationUnreadByUser[otherUid] = unread;
    }
    _recomputeTotalUnread();
  }

  Future<void> _startAfterReadStateHydrated(String uid) async {
    await _hydratePersistedReadState(uid);
    if (!_listenersStarted || _activeUid != uid) return;
    _readStateReady = true;
    _conversationsSub = _conversationRepository
        .watchUserConversations(uid)
        .listen((snapshot) {
      _applyConversationDocs(snapshot.docs, uid);
    }, onError: (_) {});
    // snapshots() already delivers initial state; avoid duplicate startup read.
    if (_isOffline) {
      unawaited(_syncUnread(forceServer: false));
    }
    if (_isOffline) {
      _syncTimer = Timer.periodic(const Duration(seconds: 20), (_) {
        unawaited(_syncUnread(forceServer: false));
      });
    }
  }

  Future<void> _hydratePersistedReadState(String uid) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final prefix = "chat_last_opened_${uid}_";
      final next = <String, int>{};
      for (final key in prefs.getKeys()) {
        if (!key.startsWith(prefix)) continue;
        final chatId = key.substring(prefix.length).trim();
        if (chatId.isEmpty) continue;
        final ms = prefs.getInt(key) ?? 0;
        if (ms <= 0) continue;
        next[chatId] = ms;
      }
      _persistedReadCutoffByChatId
        ..clear()
        ..addAll(next);
      if (_activeUid == uid && _listenersStarted) {
        unawaited(_syncUnread(forceServer: false));
      }
    } catch (_) {}
  }

  Future<void> _persistReadCutoff(String chatId, int cutoffMs) async {
    final uid = CurrentUserService.instance.userId;
    if (uid.isEmpty || chatId.trim().isEmpty || cutoffMs <= 0) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt("chat_last_opened_${uid}_$chatId", cutoffMs);
    } catch (_) {}
  }
  void _cancelAllSubscriptions() {
    _syncTimer?.cancel();
    _syncTimer = null;
    _conversationsSub?.cancel();
    _conversationsSub = null;
    _conversationUnreadByUser.clear();
    _localReadCutoffByChatId.clear();
    _persistedReadCutoffByChatId.clear();
    _readStateReady = false;
    totalUnreadCount.value = 0;
    _listenersStarted = false;
    _activeUid = null;
  }

  @override
  void onClose() {
    _cancelAllSubscriptions();
    super.onClose();
  }
}
