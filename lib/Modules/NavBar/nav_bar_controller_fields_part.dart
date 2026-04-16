part of 'nav_bar_controller.dart';

class _NavBarControllerState {
  final selectedIndex = 0.obs;
  final showBar = true.obs;
  final mediaOverlayDepth = 0.obs;
  final Set<int> mountedPrimaryTabStackIndexes = <int>{0};
  ShortController? shortCtrl;
  final fullText = 'TurqApp';
  late Rx<AnimationController> typingController;
  late Rx<AnimationController> deletingController;
  late Rx<AnimationController> animationController;
  final visibleCharCount = 0.obs;
  final removeCharCount = 0.obs;
  final hideAcilis = false.obs;
  final uploadingPosts = false.obs;
  bool isDisposed = false;
  bool isForceUpdateVisible = false;
  bool ratingSheetShownThisSession = false;
  String androidMinVersion = '';
  String iosMinVersion = '';
  String updateTitle = 'app_update.title'.tr;
  String updateBody = 'app_update.body'.tr;
  String? androidStoreUrlOverride;
  String? iosStoreUrlOverride;
  bool ratingPromptEnabled = true;
  Duration ratingPromptEnabledAfter = const Duration(days: 7);
  Duration ratingPromptRepeatAfter = const Duration(days: 7);
  Duration ratingPromptStoreCooldown = const Duration(days: 90);
  Timer? backgroundCacheTimer;
  Timer? uploadIndicatorTimer;
  Timer? ratingPromptTimer;
  Timer? feedResumeRetryTimer;
  int feedResumeRetryEpoch = 0;
}

extension NavBarControllerFieldsPart on NavBarController {
  RxInt get selectedIndex => _state.selectedIndex;
  RxBool get showBar => _state.showBar;
  RxInt get _mediaOverlayDepth => _state.mediaOverlayDepth;
  ShortController get shortCtrl => _state.shortCtrl ??= ensureShortController();
  String get fullText => _state.fullText;
  Rx<AnimationController> get typingController => _state.typingController;
  set typingController(Rx<AnimationController> value) =>
      _state.typingController = value;
  Rx<AnimationController> get deletingController => _state.deletingController;
  set deletingController(Rx<AnimationController> value) =>
      _state.deletingController = value;
  Rx<AnimationController> get animationController => _state.animationController;
  set animationController(Rx<AnimationController> value) =>
      _state.animationController = value;
  RxInt get visibleCharCount => _state.visibleCharCount;
  RxInt get removeCharCount => _state.removeCharCount;
  RxBool get hideAcilis => _state.hideAcilis;
  RxBool get uploadingPosts => _state.uploadingPosts;
  bool get _isDisposed => _state.isDisposed;
  set _isDisposed(bool value) => _state.isDisposed = value;
  bool get _isForceUpdateVisible => _state.isForceUpdateVisible;
  set _isForceUpdateVisible(bool value) => _state.isForceUpdateVisible = value;
  bool get _ratingSheetShownThisSession => _state.ratingSheetShownThisSession;
  set _ratingSheetShownThisSession(bool value) =>
      _state.ratingSheetShownThisSession = value;
  String get _androidMinVersion => _state.androidMinVersion;
  set _androidMinVersion(String value) => _state.androidMinVersion = value;
  String get _iosMinVersion => _state.iosMinVersion;
  set _iosMinVersion(String value) => _state.iosMinVersion = value;
  String get _updateTitle => _state.updateTitle;
  set _updateTitle(String value) => _state.updateTitle = value;
  String get _updateBody => _state.updateBody;
  set _updateBody(String value) => _state.updateBody = value;
  String? get _androidStoreUrlOverride => _state.androidStoreUrlOverride;
  set _androidStoreUrlOverride(String? value) =>
      _state.androidStoreUrlOverride = value;
  String? get _iosStoreUrlOverride => _state.iosStoreUrlOverride;
  set _iosStoreUrlOverride(String? value) => _state.iosStoreUrlOverride = value;
  bool get _ratingPromptEnabled => _state.ratingPromptEnabled;
  set _ratingPromptEnabled(bool value) => _state.ratingPromptEnabled = value;
  Duration get _ratingPromptEnabledAfter => _state.ratingPromptEnabledAfter;
  set _ratingPromptEnabledAfter(Duration value) =>
      _state.ratingPromptEnabledAfter = value;
  Duration get _ratingPromptRepeatAfter => _state.ratingPromptRepeatAfter;
  set _ratingPromptRepeatAfter(Duration value) =>
      _state.ratingPromptRepeatAfter = value;
  Duration get _ratingPromptStoreCooldown => _state.ratingPromptStoreCooldown;
  set _ratingPromptStoreCooldown(Duration value) =>
      _state.ratingPromptStoreCooldown = value;
  Timer? get _backgroundCacheTimer => _state.backgroundCacheTimer;
  set _backgroundCacheTimer(Timer? value) =>
      _state.backgroundCacheTimer = value;
  Timer? get _uploadIndicatorTimer => _state.uploadIndicatorTimer;
  set _uploadIndicatorTimer(Timer? value) =>
      _state.uploadIndicatorTimer = value;
  Timer? get _ratingPromptTimer => _state.ratingPromptTimer;
  set _ratingPromptTimer(Timer? value) => _state.ratingPromptTimer = value;
  Timer? get _feedResumeRetryTimer => _state.feedResumeRetryTimer;
  set _feedResumeRetryTimer(Timer? value) => _state.feedResumeRetryTimer = value;
  int get _feedResumeRetryEpoch => _state.feedResumeRetryEpoch;
  set _feedResumeRetryEpoch(int value) => _state.feedResumeRetryEpoch = value;
  Set<int> get _mountedPrimaryTabStackIndexes =>
      _state.mountedPrimaryTabStackIndexes;

  bool get mediaOverlayActive => _mediaOverlayDepth.value > 0;

  bool isPrimaryTabStackMounted(int stackIndex) =>
      _mountedPrimaryTabStackIndexes.contains(stackIndex);

  void rememberPrimaryTabStackMounted(int stackIndex) {
    if (stackIndex < 0) return;
    _mountedPrimaryTabStackIndexes.add(stackIndex);
  }
}
