import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:turqappv2/Core/Repositories/conversation_repository.dart';
import 'package:turqappv2/Core/Utils/text_normalization_utils.dart';
import 'package:turqappv2/Services/current_user_service.dart';

import '../../../Models/chat_listing_model.dart';
import '../../../Core/Services/network_awareness_service.dart';
import '../../../Core/Services/user_profile_cache_service.dart';
import '../chat_unread_policy.dart';
import '../CreateChat/create_chat.dart';

part 'chat_listing_controller_data_part.dart';
part 'chat_listing_controller_actions_part.dart';

class ChatListingController extends GetxController {
  static ChatListingController ensure() {
    final existing = maybeFind();
    if (existing != null) return existing;
    return Get.put(ChatListingController());
  }

  static ChatListingController? maybeFind() {
    final isRegistered = Get.isRegistered<ChatListingController>();
    if (!isRegistered) return null;
    return Get.find<ChatListingController>();
  }

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

  NetworkAwarenessService? get _network => NetworkAwarenessService.maybeFind();

  bool get _isOffline => _network?.currentNetwork == NetworkType.none;
  bool get _isOnWiFi => _network?.isOnWiFi ?? true;
  String get _uid => CurrentUserService.instance.effectiveUserId;
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
    final uid = CurrentUserService.instance.effectiveUserId;
    return uid.isEmpty ? '' : 'chat_listing_cache_$uid';
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
