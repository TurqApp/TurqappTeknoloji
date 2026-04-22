part of 'chat_controller.dart';

class _ChatControllerState {
  _ChatControllerState({
    ChatConversationApplicationService? conversationApplicationService,
  }) : conversationApplicationService = conversationApplicationService ??
            ChatConversationApplicationService();

  final ChatConversationApplicationService conversationApplicationService;
  final nickname = ''.obs;
  final avatarUrl = ''.obs;
  final token = ''.obs;
  final fullName = ''.obs;
  final bio = ''.obs;
  final followersCount = 0.obs;
  final followingCount = 0.obs;
  final postCount = 0.obs;
  final selection = 0.obs;
  final textMesage = ''.obs;
  final uploadPercent = 0.0.obs;
  final messages = <MessageModel>[].obs;
  final lastSentMessageId = ''.obs;
  final lastSentText = ''.obs;
  final lastSentType = ''.obs;
  final lastSentMediaCount = 0.obs;
  final lastSentPrimaryMediaUrl = ''.obs;
  final lastSentVideoUrl = ''.obs;
  final lastSentAudioUrl = ''.obs;
  final lastMediaAction = ''.obs;
  final lastMediaFailureCode = ''.obs;
  final lastMediaFailureDetail = ''.obs;
  final textEditingController = TextEditingController();
  final scrollController = ScrollController();
  final pageController = PageController();
  final focus = FocusNode();
  bool didAutoFocusOnce = false;
  final currentPage = 0.obs;
  final picker = ImagePicker();
  final images = <File>[].obs;
  final pendingVideo = Rx<File?>(null);
  final selectedGifUrl = ''.obs;
  final replyingTo = Rxn<MessageModel>();
  final editingMessage = Rxn<MessageModel>();
  Timer? messageSyncTimer;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? messagesSubscription;
  DateTime? lastServerSyncAt;
  int deltaFloorTimestampMs = 0;
  bool isMessageSyncing = false;
  String realtimeHeadSignature = '';
  bool isLoadingOlderInternal = false;
  bool conversationHasMore = true;
  DocumentSnapshot<Map<String, dynamic>>? conversationOldestCursor;
  int deletedConversationCutoffMs = 0;
  final conversationMessages = <String, MessageModel>{};
  final localDeletedMessageIds = <String>{};
  final showScrollDownButton = false.obs;
  final scrollDownOpacity = 0.0.obs;
  final isLoadingOlder = false.obs;
  final hasMoreOlder = true.obs;
  final isOtherTyping = false.obs;
  final chatBgPaletteIndex = 0.obs;
  final isSelectionMode = false.obs;
  final selectedMessageIds = <String>{}.obs;
  final showStarredOnly = false.obs;
  final isUploading = false.obs;
  final isRecording = false.obs;
  final recordingDuration = 0.obs;
  Timer? typingDebounce;
  Timer? recordingTimer;
  StreamSubscription<DocumentSnapshot>? typingStream;
  StreamSubscription<CacheInvalidationEvent>? invalidationSubscription;
  bool typingActive = false;
  bool recipientMuted = false;
  int lastTypingHeartbeatMs = 0;
  final audioRecorder = AudioRecorder();
  String? recordingPath;
}

extension ChatControllerFieldsPart on ChatController {
  ChatConversationApplicationService get conversationApplicationService =>
      _state.conversationApplicationService;
  RxString get nickname => _state.nickname;
  RxString get avatarUrl => _state.avatarUrl;
  RxString get token => _state.token;
  RxString get fullName => _state.fullName;
  RxString get bio => _state.bio;
  RxInt get followersCount => _state.followersCount;
  RxInt get followingCount => _state.followingCount;
  RxInt get postCount => _state.postCount;
  RxInt get selection => _state.selection;
  RxString get textMesage => _state.textMesage;
  RxDouble get uploadPercent => _state.uploadPercent;
  RxList<MessageModel> get messages => _state.messages;
  RxString get lastSentMessageId => _state.lastSentMessageId;
  RxString get lastSentText => _state.lastSentText;
  RxString get lastSentType => _state.lastSentType;
  RxInt get lastSentMediaCount => _state.lastSentMediaCount;
  RxString get lastSentPrimaryMediaUrl => _state.lastSentPrimaryMediaUrl;
  RxString get lastSentVideoUrl => _state.lastSentVideoUrl;
  RxString get lastSentAudioUrl => _state.lastSentAudioUrl;
  RxString get lastMediaAction => _state.lastMediaAction;
  RxString get lastMediaFailureCode => _state.lastMediaFailureCode;
  RxString get lastMediaFailureDetail => _state.lastMediaFailureDetail;
  TextEditingController get textEditingController =>
      _state.textEditingController;
  ScrollController get scrollController => _state.scrollController;
  PageController get pageController => _state.pageController;
  FocusNode get focus => _state.focus;
  bool get didAutoFocusOnce => _state.didAutoFocusOnce;
  set didAutoFocusOnce(bool value) => _state.didAutoFocusOnce = value;
  RxInt get currentPage => _state.currentPage;
  ImagePicker get picker => _state.picker;
  RxList<File> get images => _state.images;
  Rx<File?> get pendingVideo => _state.pendingVideo;
  RxString get selectedGifUrl => _state.selectedGifUrl;
  Rxn<MessageModel> get replyingTo => _state.replyingTo;
  Rxn<MessageModel> get editingMessage => _state.editingMessage;
  Timer? get _messageSyncTimer => _state.messageSyncTimer;
  set _messageSyncTimer(Timer? value) => _state.messageSyncTimer = value;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
      get _messagesSubscription => _state.messagesSubscription;
  set _messagesSubscription(
          StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? value) =>
      _state.messagesSubscription = value;
  DateTime? get _lastServerSyncAt => _state.lastServerSyncAt;
  set _lastServerSyncAt(DateTime? value) => _state.lastServerSyncAt = value;
  int get _deltaFloorTimestampMs => _state.deltaFloorTimestampMs;
  set _deltaFloorTimestampMs(int value) => _state.deltaFloorTimestampMs = value;
  bool get _isMessageSyncing => _state.isMessageSyncing;
  set _isMessageSyncing(bool value) => _state.isMessageSyncing = value;
  String get _realtimeHeadSignature => _state.realtimeHeadSignature;
  set _realtimeHeadSignature(String value) =>
      _state.realtimeHeadSignature = value;
  bool get _conversationHasMore => _state.conversationHasMore;
  set _conversationHasMore(bool value) => _state.conversationHasMore = value;
  set _conversationOldestCursor(
          DocumentSnapshot<Map<String, dynamic>>? value) =>
      _state.conversationOldestCursor = value;
  int get _deletedConversationCutoffMs => _state.deletedConversationCutoffMs;
  set _deletedConversationCutoffMs(int value) =>
      _state.deletedConversationCutoffMs = value < 0 ? 0 : value;
  Map<String, MessageModel> get _conversationMessages =>
      _state.conversationMessages;
  Set<String> get _localDeletedMessageIds => _state.localDeletedMessageIds;
  RxBool get showScrollDownButton => _state.showScrollDownButton;
  RxDouble get scrollDownOpacity => _state.scrollDownOpacity;
  RxBool get isLoadingOlder => _state.isLoadingOlder;
  RxBool get hasMoreOlder => _state.hasMoreOlder;
  RxBool get isOtherTyping => _state.isOtherTyping;
  RxInt get chatBgPaletteIndex => _state.chatBgPaletteIndex;
  RxBool get isSelectionMode => _state.isSelectionMode;
  RxSet<String> get selectedMessageIds => _state.selectedMessageIds;
  RxBool get showStarredOnly => _state.showStarredOnly;
  RxBool get isUploading => _state.isUploading;
  RxBool get isRecording => _state.isRecording;
  RxInt get recordingDuration => _state.recordingDuration;
  Timer? get _typingDebounce => _state.typingDebounce;
  set _typingDebounce(Timer? value) => _state.typingDebounce = value;
  Timer? get _recordingTimer => _state.recordingTimer;
  set _recordingTimer(Timer? value) => _state.recordingTimer = value;
  StreamSubscription<DocumentSnapshot>? get _typingStream =>
      _state.typingStream;
  set _typingStream(StreamSubscription<DocumentSnapshot>? value) =>
      _state.typingStream = value;
  StreamSubscription<CacheInvalidationEvent>? get _invalidationSubscription =>
      _state.invalidationSubscription;
  set _invalidationSubscription(
    StreamSubscription<CacheInvalidationEvent>? value,
  ) =>
      _state.invalidationSubscription = value;
  bool get _typingActive => _state.typingActive;
  set _typingActive(bool value) => _state.typingActive = value;
  bool get _recipientMuted => _state.recipientMuted;
  set _recipientMuted(bool value) => _state.recipientMuted = value;
  int get _lastTypingHeartbeatMs => _state.lastTypingHeartbeatMs;
  set _lastTypingHeartbeatMs(int value) => _state.lastTypingHeartbeatMs = value;
  AudioRecorder get _audioRecorder => _state.audioRecorder;
  String? get _recordingPath => _state.recordingPath;
  set _recordingPath(String? value) => _state.recordingPath = value;
}
