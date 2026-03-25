import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:turqappv2/Core/Repositories/conversation_repository.dart';
import 'package:turqappv2/Modules/Chat/chat_unread_policy.dart';
import 'package:turqappv2/Services/current_user_service.dart';
import '../../Services/network_awareness_service.dart';

part 'unread_messages_controller_sync_part.dart';

class UnreadMessagesController extends GetxController {
  static UnreadMessagesController ensure() {
    final existing = maybeFind();
    if (existing != null) return existing;
    return Get.put(UnreadMessagesController());
  }

  static UnreadMessagesController? maybeFind() {
    final isRegistered = Get.isRegistered<UnreadMessagesController>();
    if (!isRegistered) return null;
    return Get.find<UnreadMessagesController>();
  }

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

  NetworkAwarenessService? get _network => NetworkAwarenessService.maybeFind();
  String get _currentUid => CurrentUserService.instance.effectiveUserId;

  bool get _isOffline => _network?.currentNetwork == NetworkType.none;
  bool get _isOnWiFi => _network?.isOnWiFi ?? true;

  Duration get _serverSyncGap {
    if (_isOffline) return const Duration(days: 1);
    return _isOnWiFi ? const Duration(seconds: 6) : const Duration(seconds: 12);
  }

  @override
  void onInit() {
    super.onInit();
    if (_currentUid.isNotEmpty) {
      startListeners();
    }
  }

  void _recomputeTotalUnread() {
    if (!_readStateReady) {
      totalUnreadCount.value = 0;
      return;
    }
    totalUnreadCount.value =
        _conversationUnreadByUser.values.where((v) => v > 0).length;
  }

  @override
  void onClose() {
    _cancelAllSubscriptions();
    super.onClose();
  }
}
