part of 'short_content_controller.dart';

class _ShortContentControllerState {
  _ShortContentControllerState({
    required this.postID,
    required this.model,
  });

  String postID;
  PostsModel model;
  final avatarUrl = ''.obs;
  final nickname = ''.obs;
  final fullName = ''.obs;
  final token = ''.obs;
  final takipEdiyorum = false.obs;
  final followLoading = false.obs;
  final pageCounter = 0.obs;
  final likeCount = 0.obs;
  final commentCount = 0.obs;
  final savedCount = 0.obs;
  final retryCount = 0.obs;
  final viewCount = 0.obs;
  final reportCount = 0.obs;
  final isLiked = false.obs;
  final isSaved = false.obs;
  final isReshared = false.obs;
  final isReported = false.obs;
  final gizlendi = false.obs;
  final arsivlendi = false.obs;
  final silindi = false.obs;
  final silindiOpacity = 1.0.obs;
  final ilkPaylasanPfImage = ''.obs;
  final ilkPaylasanNickname = ''.obs;
  final ilkPaylasanUserID = ''.obs;
  final fullscreen = true.obs;
  StreamSubscription<DocumentSnapshot>? postDocSub;
  PostRepositoryState? postState;
  Worker? interactionWorker;
  Worker? postDataWorker;
  Timer? deleteFadeTimer;
  Timer? deleteRemoveTimer;
}

extension ShortContentControllerFieldsPart on ShortContentController {
  String get postID => _state.postID;
  set postID(String value) => _state.postID = value;
  PostsModel get model => _state.model;
  set model(PostsModel value) => _state.model = value;
  RxString get avatarUrl => _state.avatarUrl;
  RxString get nickname => _state.nickname;
  RxString get fullName => _state.fullName;
  RxString get token => _state.token;
  RxBool get takipEdiyorum => _state.takipEdiyorum;
  RxBool get followLoading => _state.followLoading;
  RxInt get pageCounter => _state.pageCounter;
  RxInt get likeCount => _state.likeCount;
  RxInt get commentCount => _state.commentCount;
  RxInt get savedCount => _state.savedCount;
  RxInt get retryCount => _state.retryCount;
  RxInt get viewCount => _state.viewCount;
  RxInt get reportCount => _state.reportCount;
  RxBool get isLiked => _state.isLiked;
  RxBool get isSaved => _state.isSaved;
  RxBool get isReshared => _state.isReshared;
  RxBool get isReported => _state.isReported;
  RxBool get gizlendi => _state.gizlendi;
  RxBool get arsivlendi => _state.arsivlendi;
  RxBool get silindi => _state.silindi;
  RxDouble get silindiOpacity => _state.silindiOpacity;
  RxString get ilkPaylasanPfImage => _state.ilkPaylasanPfImage;
  RxString get ilkPaylasanNickname => _state.ilkPaylasanNickname;
  RxString get ilkPaylasanUserID => _state.ilkPaylasanUserID;
  RxBool get fullscreen => _state.fullscreen;
  StreamSubscription<DocumentSnapshot>? get _postDocSub => _state.postDocSub;
  PostRepositoryState? get _postState => _state.postState;
  set _postState(PostRepositoryState? value) => _state.postState = value;
  Worker? get _interactionWorker => _state.interactionWorker;
  set _interactionWorker(Worker? value) => _state.interactionWorker = value;
  Worker? get _postDataWorker => _state.postDataWorker;
  set _postDataWorker(Worker? value) => _state.postDataWorker = value;
  Timer? get _deleteFadeTimer => _state.deleteFadeTimer;
  set _deleteFadeTimer(Timer? value) => _state.deleteFadeTimer = value;
  Timer? get _deleteRemoveTimer => _state.deleteRemoveTimer;
  set _deleteRemoveTimer(Timer? value) => _state.deleteRemoveTimer = value;
}
