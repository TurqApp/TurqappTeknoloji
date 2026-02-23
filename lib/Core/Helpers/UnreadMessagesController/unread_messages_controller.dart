import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import '../../Services/network_awareness_service.dart';

class UnreadMessagesController extends GetxController {
  final totalUnreadCount = 0.obs;
  Timer? _syncTimer;
  bool _listenersStarted = false;
  String? _activeUid;
  final Map<String, int> _conversationUnreadByUser = {};
  DateTime? _lastServerSyncAt;
  bool _isSyncing = false;

  NetworkAwarenessService? get _network =>
      Get.isRegistered<NetworkAwarenessService>()
          ? Get.find<NetworkAwarenessService>()
          : null;

  bool get _isOffline => _network?.currentNetwork == NetworkType.none;
  bool get _isOnWiFi => _network?.isOnWiFi ?? true;

  Duration get _serverSyncGap {
    if (_isOffline) return const Duration(days: 1);
    return _isOnWiFi
        ? const Duration(seconds: 6)
        : const Duration(seconds: 12);
  }

  @override
  void onInit() {
    super.onInit();
    if (FirebaseAuth.instance.currentUser?.uid != null) {
      startListeners();
    }
  }

  void startListeners({bool force = false}) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    if (!force && _listenersStarted && _activeUid == uid) return;

    _cancelAllSubscriptions();
    _listenersStarted = true;
    _activeUid = uid;
    unawaited(_syncUnread(forceServer: true));
    _syncTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      unawaited(_syncUnread(forceServer: false));
    });
  }

  void _recomputeTotalUnread() {
    totalUnreadCount.value =
        _conversationUnreadByUser.values.where((v) => v > 0).length;
  }

  Future<void> refreshUnreadCount() async {
    await _syncUnread(forceServer: true);
  }

  Future<void> _syncUnread({required bool forceServer}) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || _isSyncing) return;

    final cacheOnly = _isOffline;
    final shouldHitServer = !cacheOnly &&
        (forceServer ||
        _lastServerSyncAt == null ||
        DateTime.now().difference(_lastServerSyncAt!) >
            _serverSyncGap);
    _isSyncing = true;
    try {
      final convQuery = FirebaseFirestore.instance
          .collection("conversations")
          .where("participants", arrayContains: uid);
      final convSnap = await _getWithCachePreference(
        convQuery,
        preferCache: !shouldHitServer,
        cacheOnly: cacheOnly,
      );
      _conversationUnreadByUser.clear();
      for (final doc in convSnap.docs) {
        final data = doc.data();
        final unreadMap = Map<String, dynamic>.from(data["unread"] ?? {});
        final value = unreadMap[uid];
        final unread =
            value is num ? value.toInt() : int.tryParse("$value") ?? 0;
        if (unread <= 0) continue;
        final participants = List<String>.from(data["participants"] ?? []);
        final otherUid = participants.firstWhere(
          (v) => v != uid,
          orElse: () => doc.id,
        );
        _conversationUnreadByUser[otherUid] = unread;
      }

      _recomputeTotalUnread();
      if (shouldHitServer) {
        _lastServerSyncAt = DateTime.now();
      }
    } catch (_) {
      _recomputeTotalUnread();
    } finally {
      _isSyncing = false;
    }
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

  void _cancelAllSubscriptions() {
    _syncTimer?.cancel();
    _syncTimer = null;
    _conversationUnreadByUser.clear();
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
