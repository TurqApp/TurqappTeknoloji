import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
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
import 'package:turqappv2/Core/Services/integration_media_test_harness.dart';
import 'package:turqappv2/Core/Services/network_awareness_service.dart';
import 'package:turqappv2/Core/Services/user_moderation_guard.dart';
import 'package:turqappv2/Core/Services/user_summary_resolver.dart';
import 'package:turqappv2/Core/Repositories/conversation_repository.dart';
import 'package:turqappv2/Core/Services/market_notification_service.dart';
import 'package:turqappv2/Core/Services/user_profile_cache_service.dart';
import 'package:turqappv2/Core/Services/webp_upload_service.dart';
import 'package:turqappv2/Modules/Chat/chat_realtime_sync_policy.dart';
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
part 'chat_controller_conversation_sync_part.dart';
part 'chat_controller_actions_part.dart';
part 'chat_controller_composer_part.dart';
part 'chat_controller_forwarding_part.dart';
part 'chat_controller_local_cache_part.dart';
part 'chat_controller_media_part.dart';
part 'chat_controller_runtime_part.dart';
part 'chat_controller_send_part.dart';
part 'chat_controller_support_part.dart';

class ChatController extends GetxController {
  static String? _activeTag;

  static ChatController ensure({
    required String chatID,
    required String userID,
    String? tag,
    bool permanent = false,
  }) {
    final existing = maybeFind(tag: tag);
    if (existing != null) {
      _activeTag = tag ?? chatID;
      return existing;
    }
    final created = Get.put(
      ChatController(chatID: chatID, userID: userID),
      tag: tag,
      permanent: permanent,
    );
    _activeTag = tag ?? chatID;
    return created;
  }

  static ChatController? maybeFind({String? tag}) {
    final resolvedTag = (tag ?? _activeTag)?.trim();
    final isRegistered = Get.isRegistered<ChatController>(
      tag: resolvedTag?.isEmpty == true ? null : resolvedTag,
    );
    if (!isRegistered) return null;
    return Get.find<ChatController>(
      tag: resolvedTag?.isEmpty == true ? null : resolvedTag,
    );
  }

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
  final RxString lastSentMessageId = ''.obs;
  final RxString lastSentText = ''.obs;
  final RxString lastSentType = ''.obs;
  final RxInt lastSentMediaCount = 0.obs;
  final RxString lastSentPrimaryMediaUrl = ''.obs;
  final RxString lastSentVideoUrl = ''.obs;
  final RxString lastSentAudioUrl = ''.obs;
  final RxString lastMediaAction = ''.obs;
  final RxString lastMediaFailureCode = ''.obs;
  final RxString lastMediaFailureDetail = ''.obs;
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
  String _realtimeHeadSignature = '';
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
  final UserSummaryResolver _userSummaryResolver = UserSummaryResolver.ensure();

  ChatController({required this.chatID, required this.userID});

  @override
  void onInit() {
    super.onInit();
    _initializeChatRuntime();
  }

  @override
  void onClose() {
    _disposeChatRuntimeResources();
    super.onClose();
  }
}
