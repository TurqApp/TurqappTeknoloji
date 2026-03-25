part of 'photo_short_content_controller.dart';

class _PhotoShortsControllerState {
  final avatarUrl = ''.obs;
  final nickname = ''.obs;
  final token = ''.obs;
  final fullName = ''.obs;
  final takipEdiyorum = false.obs;
  final followLoading = false.obs;
  final fullScreen = false.obs;
  final likes = <dynamic>[].obs;
  final unLikes = <dynamic>[].obs;
  final saved = <dynamic>[].obs;
  final comments = <dynamic>[].obs;
  final seens = <dynamic>[].obs;
  final reSharedUsers = <dynamic>[].obs;
  final userComments = <dynamic>[].obs;
  final isLiked = false.obs;
  final isSaved = false.obs;
  final isReshared = false.obs;
  final isReported = false.obs;
  PostRepositoryState? postState;
  StreamSubscription<DocumentSnapshot>? likeDocSub;
  StreamSubscription<DocumentSnapshot>? savedDocSub;
  StreamSubscription<DocumentSnapshot>? reshareDocSub;
  StreamSubscription<DocumentSnapshot>? postDocSub;
  Worker? interactionWorker;
  final arsiv = false.obs;
  final gizlendi = false.obs;
  final sikayetEdildi = false.obs;
  final silindi = false.obs;
  final silindiOpacity = 1.0.obs;
  final yenidenPaylasildiMi = false.obs;
}

extension PhotoShortsContentControllerFieldsPart
    on PhotoShortsContentController {
  RxString get avatarUrl => _state.avatarUrl;
  RxString get nickname => _state.nickname;
  RxString get token => _state.token;
  RxString get fullName => _state.fullName;
  RxBool get takipEdiyorum => _state.takipEdiyorum;
  RxBool get followLoading => _state.followLoading;
  RxBool get fullScreen => _state.fullScreen;
  RxList<dynamic> get likes => _state.likes;
  RxList<dynamic> get unLikes => _state.unLikes;
  RxList<dynamic> get saved => _state.saved;
  RxList<dynamic> get comments => _state.comments;
  RxList<dynamic> get seens => _state.seens;
  RxList<dynamic> get reSharedUsers => _state.reSharedUsers;
  RxList<dynamic> get userComments => _state.userComments;
  RxBool get isLiked => _state.isLiked;
  RxBool get isSaved => _state.isSaved;
  RxBool get isReshared => _state.isReshared;
  RxBool get isReported => _state.isReported;
  PostRepositoryState? get _postState => _state.postState;
  set _postState(PostRepositoryState? value) => _state.postState = value;
  StreamSubscription<DocumentSnapshot>? get _likeDocSub => _state.likeDocSub;
  StreamSubscription<DocumentSnapshot>? get _savedDocSub => _state.savedDocSub;
  StreamSubscription<DocumentSnapshot>? get _reshareDocSub =>
      _state.reshareDocSub;
  StreamSubscription<DocumentSnapshot>? get _postDocSub => _state.postDocSub;
  Worker? get _interactionWorker => _state.interactionWorker;
  set _interactionWorker(Worker? value) => _state.interactionWorker = value;
  RxBool get arsiv => _state.arsiv;
  RxBool get gizlendi => _state.gizlendi;
  RxBool get sikayetEdildi => _state.sikayetEdildi;
  RxBool get silindi => _state.silindi;
  RxDouble get silindiOpacity => _state.silindiOpacity;
  RxBool get yenidenPaylasildiMi => _state.yenidenPaylasildiMi;
}
