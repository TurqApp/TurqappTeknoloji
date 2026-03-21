import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Core/Helpers/UnreadMessagesController/unread_messages_controller.dart';
import 'package:turqappv2/Core/notification_service.dart';
import 'package:turqappv2/Core/Services/app_image_picker_service.dart';
import 'package:turqappv2/Core/Services/giphy_picker_service.dart';
import 'package:turqappv2/Core/Services/network_awareness_service.dart';
import 'package:turqappv2/Core/Services/user_moderation_guard.dart';
import 'package:turqappv2/Core/Services/user_summary_resolver.dart';
import 'package:turqappv2/Core/Repositories/conversation_repository.dart';
import 'package:turqappv2/Core/Services/market_notification_service.dart';
import 'package:turqappv2/Core/Services/user_profile_cache_service.dart';
import 'package:turqappv2/Core/Services/webp_upload_service.dart';
import 'package:turqappv2/Modules/Chat/ChatListing/chat_listing_controller.dart';
import 'package:turqappv2/Modules/InAppNotifications/notification_post_types.dart';
import 'package:turqappv2/Modules/InAppNotifications/in_app_notifications_controller.dart';
import 'package:turqappv2/Services/current_user_service.dart';
import 'package:uuid/uuid.dart';
import 'package:record/record.dart';
import 'package:video_compress/video_compress.dart';
import 'package:video_thumbnail/video_thumbnail.dart' as vt;
import 'package:shared_preferences/shared_preferences.dart';

import '../../Core/Camera/chat_camera_capture_view.dart';
import '../../Core/blocked_texts.dart';
import '../../Core/Services/optimized_nsfw_service.dart';
import '../../Models/message_model.dart';

part 'chat_controller_conversation.dart';
part 'chat_controller_actions_part.dart';
part 'chat_controller_forwarding_part.dart';
part 'chat_controller_media_part.dart';

class ChatController extends GetxController {
  String chatID;
  String userID;
  var nickname = "".obs;
  var avatarUrl = "".obs;
  var token = "".obs;
  var fullName = "".obs;
  var bio = "".obs;
  var followersCount = 0.obs;
  var followingCount = 0.obs;
  var postCount = 0.obs;
  var selection = 0.obs;
  var textMesage = ''.obs;
  var uploadPercent = 0.0.obs;
  RxList<MessageModel> messages = <MessageModel>[].obs;
  TextEditingController textEditingController = TextEditingController();
  ScrollController scrollController = ScrollController();
  PageController pageController = PageController();
  FocusNode focus = FocusNode();
  bool didAutoFocusOnce = false;
  var currentPage = 0.obs;
  final picker = ImagePicker();
  RxList<File> images = <File>[].obs;
  final Rx<File?> pendingVideo = Rx<File?>(null);
  final RxString selectedGifUrl = ''.obs;
  final ConversationRepository _conversationRepository =
      ConversationRepository.ensure();
  final replyingTo = Rxn<MessageModel>();
  final editingMessage = Rxn<MessageModel>();
  Timer? _messageSyncTimer;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
      _messagesSubscription;
  DateTime? _lastServerSyncAt;
  bool _isMessageSyncing = false;
  bool _isLoadingOlder = false;
  bool _conversationHasMore = true;
  DocumentSnapshot<Map<String, dynamic>>? _conversationOldestCursor;
  static const int _initialPageSize = 60;
  static const int _olderPageSize = 40;
  static const int _syncHeadSize = 40;
  final Map<String, MessageModel> _conversationMessages = {};
  var showScrollDownButton = false.obs;
  var scrollDownOpacity = 0.0.obs;
  var isLoadingOlder = false.obs;
  var hasMoreOlder = true.obs;
  var isOtherTyping = false.obs;
  var chatBgPaletteIndex = 0.obs;
  final RxBool isSelectionMode = false.obs;
  final RxSet<String> selectedMessageIds = <String>{}.obs;
  final RxBool showStarredOnly = false.obs;
  var isUploading = false.obs;
  var isRecording = false.obs;
  var recordingDuration = 0.obs;
  Timer? _typingDebounce;
  Timer? _recordingTimer;
  StreamSubscription<DocumentSnapshot>? _typingStream;
  bool _typingActive = false;
  int _lastTypingHeartbeatMs = 0;
  bool _recipientMuted = false;
  static const int _typingHeartbeatIntervalMs = 1500;
  final AudioRecorder _audioRecorder = AudioRecorder();
  String? _recordingPath;
  static const int _localChatWindowLimit = 180;

  NetworkAwarenessService? get _network => NetworkAwarenessService.maybeFind();
  final UserSummaryResolver _userSummaryResolver = UserSummaryResolver.ensure();

  bool get _isOffline => _network?.currentNetwork == NetworkType.none;
  bool get _isOnWiFi => _network?.isOnWiFi ?? true;

  Duration get _serverSyncGap {
    if (_isOffline) return const Duration(days: 1);
    return _isOnWiFi
        ? const Duration(seconds: 12)
        : const Duration(seconds: 30);
  }

  ChatController({required this.chatID, required this.userID});

  @override
  void onInit() {
    super.onInit();
    getUserData();
    loadChatBackgroundPreference();
    unawaited(getData());
    _clearConversationUnread();
    _syncUnreadIndicatorsLocal();
    unawaited(_markConversationOpenedNow());
    textEditingController.addListener(() {
      textMesage.value = textEditingController.text;
      _onTypingChanged();
    });
    _listenTypingState();
    scrollController.addListener(() {
      final offset = scrollController.offset;
      final visible = offset > 500;
      showScrollDownButton.value = visible;
      if (!visible) {
        scrollDownOpacity.value = 0.0;
      } else {
        final strength = ((offset - 500) / 900).clamp(0.0, 1.0);
        scrollDownOpacity.value = (0.45 + (strength * 0.55)).clamp(0.45, 1.0);
      }
      if (scrollController.hasClients &&
          scrollController.position.maxScrollExtent > 0 &&
          offset > (scrollController.position.maxScrollExtent - 280)) {
        loadOlderMessages();
      }
    });
  }

  Future<void> _clearConversationUnread() =>
      _ChatControllerConversationX(this)._clearConversationUnread();

  void _syncUnreadIndicatorsLocal() =>
      _ChatControllerConversationX(this)._syncUnreadIndicatorsLocal();

  @override
  void onClose() {
    unawaited(_markConversationOpenedNow());
    _messageSyncTimer?.cancel();
    _messagesSubscription?.cancel();
    _typingStream?.cancel();
    _typingDebounce?.cancel();
    _recordingTimer?.cancel();
    _audioRecorder.dispose();
    textEditingController.dispose();
    scrollController.dispose();
    pageController.dispose();
    focus.dispose();
    _clearTyping();
    super.onClose();
  }

  Future<void> _markConversationOpenedNow() =>
      _ChatControllerConversationX(this)._markConversationOpenedNow();

  Future<void> _markConversationOpenedAt(int timestampMs) =>
      _ChatControllerConversationX(this)._markConversationOpenedAt(
        timestampMs,
      );

  void getUserData() => _ChatControllerConversationX(this).getUserData();

  void scrollToBottom() => _ChatControllerConversationX(this).scrollToBottom();

  void _onTypingChanged() =>
      _ChatControllerConversationX(this)._onTypingChanged();

  void _clearTyping() => _ChatControllerConversationX(this)._clearTyping();

  void _listenTypingState() =>
      _ChatControllerConversationX(this)._listenTypingState();

  Future<void> getData() => _ChatControllerConversationX(this).getData();

  Future<void> loadChatBackgroundPreference() =>
      _ChatControllerConversationX(this).loadChatBackgroundPreference();

  Future<void> setChatBackgroundPreference(int index) =>
      _ChatControllerConversationX(this).setChatBackgroundPreference(index);

  Future<void> _syncMessages({required bool forceServer}) =>
      _ChatControllerConversationX(this)
          ._syncMessages(forceServer: forceServer);

  Future<void> loadOlderMessages() =>
      _ChatControllerConversationX(this).loadOlderMessages();

  Future<void> jumpToMessageByRawId(String rawId) =>
      _ChatControllerConversationX(this).jumpToMessageByRawId(rawId);

  Future<void> archiveCurrentChat() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      final convDoc = await _conversationRepository.getConversation(
        chatID,
        preferCache: true,
        cacheOnly: false,
      );
      if (convDoc != null) {
        await _conversationRepository.setArchived(
          currentUid: uid,
          otherUserId: userID,
          chatId: chatID,
          archived: true,
        );
      }
    } catch (_) {}
  }
}
