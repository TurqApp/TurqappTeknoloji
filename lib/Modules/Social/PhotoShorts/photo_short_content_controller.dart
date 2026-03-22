import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:async';
import 'package:turqappv2/Core/follow_service.dart';
import 'package:turqappv2/Core/Repositories/follow_repository.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Modules/Explore/explore_controller.dart';
import 'package:uuid/uuid.dart';
import '../../../Models/posts_model.dart';
import '../../../Services/reshare_helper.dart';
import '../../../Services/post_count_manager.dart';
import '../../../Services/post_interaction_service.dart';
import '../../Agenda/agenda_controller.dart';
import '../../Profile/MyProfile/profile_controller.dart';
import '../../ShareGrid/share_grid.dart';
import '../../Short/short_controller.dart';
import '../Comments/post_comments.dart';
import '../../../Services/post_delete_service.dart';
import '../../../Core/Services/admin_access_service.dart';
import '../../../Core/Repositories/post_repository.dart';
import '../../../Core/Repositories/admin_push_repository.dart';
import '../../../Core/Repositories/user_repository.dart';
import '../../../Core/Services/user_summary_resolver.dart';
import '../../../Core/Services/typesense_post_service.dart';
import '../../../Services/current_user_service.dart';

part 'photo_short_content_controller_post_part.dart';
part 'photo_short_content_controller_social_part.dart';

class PhotoShortsContentController extends GetxController {
  static PhotoShortsContentController ensure({
    required PostsModel model,
    String? tag,
    bool permanent = false,
  }) {
    final existing = maybeFind(tag: tag);
    if (existing != null) return existing;
    return Get.put(
      PhotoShortsContentController(model: model),
      tag: tag,
      permanent: permanent,
    );
  }

  static PhotoShortsContentController? maybeFind({String? tag}) {
    final isRegistered =
        Get.isRegistered<PhotoShortsContentController>(tag: tag);
    if (!isRegistered) return null;
    return Get.find<PhotoShortsContentController>(tag: tag);
  }

  PostsModel model;
  final UserSummaryResolver _userSummaryResolver = UserSummaryResolver.ensure();

  PhotoShortsContentController({required this.model});

  bool get canSendAdminPush {
    return AdminAccessService.isKnownAdminSync();
  }

  ({String title, String body}) _buildPostPushCopy() {
    final senderName = fullName.value.trim().isNotEmpty
        ? fullName.value.trim()
        : nickname.value.trim();
    final safeSender = senderName.isNotEmpty ? senderName : 'app.name'.tr;
    final hasVideo = model.video.trim().isNotEmpty;
    final hasImage = model.img.isNotEmpty;
    final text = model.metin.trim();

    final preview =
        text.length > 90 ? '${text.substring(0, 90).trim()}...' : text;
    final title = '$safeSender yeni bir gonderi paylasti';
    final body = preview.isNotEmpty
        ? preview
        : hasVideo
            ? 'Yeni video gonderisi'
            : hasImage
                ? 'Yeni fotograf gonderisi'
                : 'Yeni gonderi paylasti';
    return (title: title, body: body);
  }

  String? _pushPreviewImageUrl() {
    if (model.img.isNotEmpty) {
      final firstImage = model.img.first.trim();
      if (firstImage.isNotEmpty) return firstImage;
    }
    final thumbnail = model.thumbnail.trim();
    if (thumbnail.isNotEmpty) return thumbnail;
    return null;
  }

  var avatarUrl = "".obs;
  var nickname = "".obs;
  var token = "".obs;
  var fullName = "".obs;
  var takipEdiyorum = false.obs;
  var followLoading = false.obs;
  var fullScreen = false.obs;

  var likes = [].obs;
  var unLikes = [].obs;
  var saved = [].obs;
  var comments = [].obs;
  var seens = [].obs;
  var reSharedUsers = [].obs;
  var userComments = [].obs; // Kullanıcının yaptığı yorumlar
  RxBool isLiked = false.obs;
  RxBool isSaved = false.obs;
  RxBool isReshared = false.obs;
  RxBool isReported = false.obs;
  final agendaController = AgendaController.ensure();
  final countManager = PostCountManager.instance;
  late final PostInteractionService _interactionService;
  late final PostRepository _postRepository;
  late final AdminPushRepository _adminPushRepository;
  PostRepositoryState? _postState;
  StreamSubscription<DocumentSnapshot>? _likeDocSub;
  StreamSubscription<DocumentSnapshot>? _savedDocSub;
  StreamSubscription<DocumentSnapshot>? _reshareDocSub;
  StreamSubscription<DocumentSnapshot>? _postDocSub;
  Worker? _interactionWorker;
  String get _currentUserId => CurrentUserService.instance.effectiveUserId;

  // Reactive count variables using centralized manager
  RxInt get likeCount => countManager.getLikeCount(model.docID);
  RxInt get commentCount => countManager.getCommentCount(model.docID);
  RxInt get savedCount => countManager.getSavedCount(model.docID);
  RxInt get retryCount => countManager.getRetryCount(model.docID);

  var arsiv = false.obs;
  var gizlendi = false.obs;
  var sikayetEdildi = false.obs;
  var silindi = false.obs;
  var silindiOpacity = 1.0.obs;

  var yenidenPaylasildiMi = false.obs;

  @override
  void onInit() {
    super.onInit();
    _interactionService = PostInteractionService.ensure();
    _postRepository = PostRepository.ensure();
    _adminPushRepository = AdminPushRepository.ensure();
    // Initialize counts after current build to avoid Obx update during build
    Future.microtask(() {
      countManager.initializeCounts(
        model.docID,
        likeCount: model.stats.likeCount.toInt(),
        commentCount: model.stats.commentCount.toInt(),
        savedCount: model.stats.savedCount.toInt(),
        retryCount: model.stats.retryCount.toInt(),
        statsCount: model.stats.statsCount.toInt(),
      );
      _initializeStats();
      _loadUserInteractionStatus();
    });

    getGizleArsivSikayetEdildi();
    avatarUrl.value = model.authorAvatarUrl.trim();
    nickname.value = model.authorNickname.trim();
    fullName.value = model.authorDisplayName.trim();
    fetchUserData(model.userID);
    getReSharedUsers(model.docID);
    getYenidenPaylasBilgisi();
    // Deprecated method calls removed - real-time listeners handle data updates
    // getComments(), getLikes(), getSaved() are replaced by reactive listeners
    getSeens();
    saveSeeing();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _bindMembershipListeners();
      _bindReshareListener();
      _bindPostDocCounts();
    });
  }

  @override
  void onClose() {
    _interactionWorker?.dispose();
    _postRepository.releasePost(model.docID);
    _likeDocSub?.cancel();
    _savedDocSub?.cancel();
    _reshareDocSub?.cancel();
    _postDocSub?.cancel();
    super.onClose();
  }

  void _bindMembershipListeners() {
    _postState ??= _postRepository.attachPost(model);
    _syncSharedInteractionState();
    _interactionWorker?.dispose();
    if (_postState != null) {
      _interactionWorker = everAll([
        _postState!.liked,
        _postState!.saved,
        _postState!.reshared,
      ], (_) {
        _syncSharedInteractionState();
      });
    }
  }

  void _bindReshareListener() {
    _syncSharedInteractionState();
  }

  void _bindPostDocCounts() {
    _postState ??= _postRepository.attachPost(model);
  }

  void _syncSharedInteractionState() {
    final uid = _currentUserId;
    if (_postState == null) return;
    final liked = _postState!.liked.value;
    final savedState = _postState!.saved.value;
    final reshared = _postState!.reshared.value;
    if (uid.isNotEmpty) {
      if (liked) {
        if (!likes.contains(uid)) likes.add(uid);
      } else {
        likes.remove(uid);
      }
      if (savedState) {
        if (!saved.contains(uid)) saved.add(uid);
      } else {
        saved.remove(uid);
      }
    }
    isLiked.value = liked;
    isSaved.value = savedState;
    isReshared.value = reshared;
    yenidenPaylasildiMi.value = reshared;
  }

  void _initializeStats() {
    likeCount.value = model.stats.likeCount.toInt();
    commentCount.value = model.stats.commentCount.toInt();
    savedCount.value = model.stats.savedCount.toInt();
    retryCount.value = model.stats.retryCount.toInt();
  }

  Future<void> _loadUserInteractionStatus() async {
    _postState ??= _postRepository.attachPost(model);
    _syncSharedInteractionState();
    isReported.value = _postState?.reported.value ?? false;
  }
}
