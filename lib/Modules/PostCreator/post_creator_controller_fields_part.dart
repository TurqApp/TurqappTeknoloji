part of 'post_creator_controller.dart';

class _PostCreatorControllerState {
  final postList = <PostCreatorModel>[PostCreatorModel(index: 0, text: '')].obs;
  int nextComposerItemIndex = 1;
  final isKeyboardOpen = false.obs;
  final isPublishing = false.obs;
  final selectedIndex = 0.obs;
  final comment = true.obs;
  final commentVisibility = 0.obs;
  final paylasimSelection = 0.obs;
  final publishMode = 0.obs;
  final izBirakDateTime = Rx<DateTime?>(null);
  bool sharedSourceApplied = false;
  String sharedSourceFingerprint = '';
  bool isSharedAsPost = false;
  String sharedOriginalUserID = '';
  String sharedOriginalPostID = '';
  String sharedSourcePostID = '';
  bool isQuotedPost = false;
  String quotedOriginalText = '';
  String quotedSourceUserID = '';
  String quotedSourceDisplayName = '';
  String quotedSourceUsername = '';
  String quotedSourceAvatarUrl = '';
  bool editSourceApplied = false;
  final isEditMode = false.obs;
  final editingPostID = ''.obs;
  final isSavingEdit = false.obs;
  Timer? autoSaveTimer;
  Timer? queueRingTimer;
  String preparedRouteId = '';
}

extension PostCreatorControllerFieldsPart on PostCreatorController {
  bool get isQuotedPost => _isQuotedPost;
  String get quotedOriginalText => _quotedOriginalText;
  String get quotedSourceUserID => _quotedSourceUserID;
  String get quotedSourceDisplayName => _quotedSourceDisplayName;
  String get quotedSourceUsername => _quotedSourceUsername;
  String get quotedSourceAvatarUrl => _quotedSourceAvatarUrl;
  String get sharedOriginalUserID => _sharedOriginalUserID;
  String get sharedOriginalPostID => _sharedOriginalPostID;
  RxList<PostCreatorModel> get postList => _state.postList;
  int get _nextComposerItemIndex => _state.nextComposerItemIndex;
  set _nextComposerItemIndex(int value) => _state.nextComposerItemIndex = value;
  RxBool get isKeyboardOpen => _state.isKeyboardOpen;
  RxBool get isPublishing => _state.isPublishing;
  RxInt get selectedIndex => _state.selectedIndex;
  RxBool get comment => _state.comment;
  RxInt get commentVisibility => _state.commentVisibility;
  RxInt get paylasimSelection => _state.paylasimSelection;
  RxInt get publishMode => _state.publishMode;
  Rx<DateTime?> get izBirakDateTime => _state.izBirakDateTime;
  bool get _sharedSourceApplied => _state.sharedSourceApplied;
  set _sharedSourceApplied(bool value) => _state.sharedSourceApplied = value;
  String get _sharedSourceFingerprint => _state.sharedSourceFingerprint;
  set _sharedSourceFingerprint(String value) =>
      _state.sharedSourceFingerprint = value;
  bool get _isSharedAsPost => _state.isSharedAsPost;
  set _isSharedAsPost(bool value) => _state.isSharedAsPost = value;
  String get _sharedOriginalUserID => _state.sharedOriginalUserID;
  set _sharedOriginalUserID(String value) =>
      _state.sharedOriginalUserID = value;
  String get _sharedOriginalPostID => _state.sharedOriginalPostID;
  set _sharedOriginalPostID(String value) =>
      _state.sharedOriginalPostID = value;
  String get _sharedSourcePostID => _state.sharedSourcePostID;
  set _sharedSourcePostID(String value) => _state.sharedSourcePostID = value;
  bool get _isQuotedPost => _state.isQuotedPost;
  set _isQuotedPost(bool value) => _state.isQuotedPost = value;
  String get _quotedOriginalText => _state.quotedOriginalText;
  set _quotedOriginalText(String value) => _state.quotedOriginalText = value;
  String get _quotedSourceUserID => _state.quotedSourceUserID;
  set _quotedSourceUserID(String value) => _state.quotedSourceUserID = value;
  String get _quotedSourceDisplayName => _state.quotedSourceDisplayName;
  set _quotedSourceDisplayName(String value) =>
      _state.quotedSourceDisplayName = value;
  String get _quotedSourceUsername => _state.quotedSourceUsername;
  set _quotedSourceUsername(String value) =>
      _state.quotedSourceUsername = value;
  String get _quotedSourceAvatarUrl => _state.quotedSourceAvatarUrl;
  set _quotedSourceAvatarUrl(String value) =>
      _state.quotedSourceAvatarUrl = value;
  bool get _editSourceApplied => _state.editSourceApplied;
  set _editSourceApplied(bool value) => _state.editSourceApplied = value;
  RxBool get isEditMode => _state.isEditMode;
  RxString get editingPostID => _state.editingPostID;
  RxBool get isSavingEdit => _state.isSavingEdit;
  Timer? get _autoSaveTimer => _state.autoSaveTimer;
  set _autoSaveTimer(Timer? value) => _state.autoSaveTimer = value;
  Timer? get _queueRingTimer => _state.queueRingTimer;
  set _queueRingTimer(Timer? value) => _state.queueRingTimer = value;
  String get _preparedRouteId => _state.preparedRouteId;
  set _preparedRouteId(String value) => _state.preparedRouteId = value;
}
