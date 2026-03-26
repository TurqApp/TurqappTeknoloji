part of 'post_content_controller.dart';

class _PostContentIdentityState {
  _PostContentIdentityState.fromModel(PostsModel model)
      : nickname = model.authorNickname.trim().obs,
        username = (model.authorNickname.trim().isNotEmpty
                ? model.authorNickname.trim()
                : '')
            .obs,
        avatarUrl = (model.authorAvatarUrl.trim().isNotEmpty
                ? resolveAvatarUrl({'avatarUrl': model.authorAvatarUrl.trim()})
                : kDefaultAvatarUrl)
            .obs,
        fullName = model.authorDisplayName.trim().obs;

  final RxString nickname;
  final RxString username;
  final RxString avatarUrl;
  final RxString fullName;
}

class _PostContentControllerState {
  _PostContentControllerState(PostsModel model)
      : canSendAdminPush = AdminAccessService.isKnownAdminSync(),
        editTime = (model.editTime?.toInt() ?? 0).obs,
        currentModel = Rx<PostsModel?>(model);

  bool canSendAdminPush;
  final likes = <String>[].obs;
  final unLikes = <String>[].obs;
  final saved = false.obs;
  final comments = <String>[].obs;
  final reSharedUsers = <String>[].obs;
  final isFollowing = true.obs;
  final followLoading = false.obs;
  final token = ''.obs;
  final reShareUserNickname = ''.obs;
  final reShareUserUserID = ''.obs;
  final arsiv = false.obs;
  final gizlendi = false.obs;
  final sikayetEdildi = false.obs;
  final silindi = false.obs;
  final silindiOpacity = 1.0.obs;
  final RxInt editTime;
  final Rx<PostsModel?> currentModel;
  final yenidenPaylasildiMi = false.obs;
  PostRepositoryState? postState;
  StreamSubscription<DocumentSnapshot>? userSub;
  StreamSubscription<DocumentSnapshot>? likeDocSub;
  StreamSubscription<DocumentSnapshot>? savedDocSub;
  StreamSubscription<DocumentSnapshot>? reshareDocSub;
  StreamSubscription<DocumentSnapshot>? postDocSub;
  StreamSubscription<CurrentUserModel?>? currentUserStreamSub;
  Worker? followingWorker;
  Worker? interactionWorker;
  Worker? postDataWorker;
  Worker? myResharesWorker;
}

extension PostContentControllerFieldsPart on PostContentController {
  PostsModel get model => _shellState.model;
  bool get enableLegacyCommentSync => _shellState.enableLegacyCommentSync;
  bool get scrollFeedToTopOnReshare => _shellState.scrollFeedToTopOnReshare;
  _PostContentIdentityState get _identityState => _shellState.identityState;
  _PostContentControllerState get _controllerState =>
      _shellState.controllerState;
  AgendaController get agendaController =>
      _shellState.agendaController ??= _resolveAgendaController();
  bool get _canSendAdminPush => _controllerState.canSendAdminPush;
  set _canSendAdminPush(bool value) =>
      _controllerState.canSendAdminPush = value;
  RxList<String> get likes => _controllerState.likes;
  RxList<String> get unLikes => _controllerState.unLikes;
  RxBool get saved => _controllerState.saved;
  RxList<String> get comments => _controllerState.comments;
  RxList<String> get reSharedUsers => _controllerState.reSharedUsers;
  RxBool get isFollowing => _controllerState.isFollowing;
  RxBool get followLoading => _controllerState.followLoading;
  RxString get nickname => _identityState.nickname;
  RxString get username => _identityState.username;
  RxString get avatarUrl => _identityState.avatarUrl;
  RxString get fullName => _identityState.fullName;
  RxString get token => _controllerState.token;
  RxString get reShareUserNickname => _controllerState.reShareUserNickname;
  RxString get reShareUserUserID => _controllerState.reShareUserUserID;
  RxBool get arsiv => _controllerState.arsiv;
  RxBool get gizlendi => _controllerState.gizlendi;
  RxBool get sikayetEdildi => _controllerState.sikayetEdildi;
  RxBool get silindi => _controllerState.silindi;
  RxDouble get silindiOpacity => _controllerState.silindiOpacity;
  RxInt get editTime => _controllerState.editTime;
  Rx<PostsModel?> get currentModel => _controllerState.currentModel;
  RxBool get yenidenPaylasildiMi => _controllerState.yenidenPaylasildiMi;
  PostRepositoryState? get _postState => _controllerState.postState;
  set _postState(PostRepositoryState? value) =>
      _controllerState.postState = value;
  StreamSubscription<DocumentSnapshot>? get _userSub =>
      _controllerState.userSub;
  StreamSubscription<DocumentSnapshot>? get _likeDocSub =>
      _controllerState.likeDocSub;
  StreamSubscription<DocumentSnapshot>? get _savedDocSub =>
      _controllerState.savedDocSub;
  StreamSubscription<DocumentSnapshot>? get _reshareDocSub =>
      _controllerState.reshareDocSub;
  StreamSubscription<DocumentSnapshot>? get _postDocSub =>
      _controllerState.postDocSub;
  StreamSubscription<CurrentUserModel?>? get _currentUserStreamSub =>
      _controllerState.currentUserStreamSub;
  set _currentUserStreamSub(StreamSubscription<CurrentUserModel?>? value) =>
      _controllerState.currentUserStreamSub = value;
  Worker? get _followingWorker => _controllerState.followingWorker;
  set _followingWorker(Worker? value) =>
      _controllerState.followingWorker = value;
  Worker? get _interactionWorker => _controllerState.interactionWorker;
  set _interactionWorker(Worker? value) =>
      _controllerState.interactionWorker = value;
  Worker? get _postDataWorker => _controllerState.postDataWorker;
  set _postDataWorker(Worker? value) => _controllerState.postDataWorker = value;
  Worker? get _myResharesWorker => _controllerState.myResharesWorker;
  set _myResharesWorker(Worker? value) =>
      _controllerState.myResharesWorker = value;
}
