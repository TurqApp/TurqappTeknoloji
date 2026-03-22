import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:async';
import 'package:turqappv2/Models/posts_model.dart';
import 'package:turqappv2/Core/follow_service.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Modules/Explore/explore_controller.dart';
import '../Agenda/agenda_controller.dart';
import '../Profile/MyProfile/profile_controller.dart';
import '../ShareGrid/share_grid.dart';
import '../../Services/post_delete_service.dart';
import 'short_controller.dart';
import '../../Services/post_interaction_service.dart';
import '../../Core/Repositories/post_repository.dart';
import '../../Core/Repositories/follow_repository.dart';
import '../../Core/Services/user_summary_resolver.dart';
import '../../Services/current_user_service.dart';

part 'short_content_controller_data_part.dart';
part 'short_content_controller_actions_part.dart';

class ShortContentController extends GetxController {
  static ShortContentController ensure({
    required String postID,
    required PostsModel model,
    String? tag,
    bool permanent = false,
  }) {
    final existing = maybeFind(tag: tag);
    if (existing != null) return existing;
    return Get.put(
      ShortContentController(postID: postID, model: model),
      tag: tag,
      permanent: permanent,
    );
  }

  static ShortContentController? maybeFind({String? tag}) {
    final isRegistered = Get.isRegistered<ShortContentController>(tag: tag);
    if (!isRegistered) return null;
    return Get.find<ShortContentController>(tag: tag);
  }

  String postID;
  PostsModel model;

  ShortContentController({
    required this.postID,
    required this.model,
  });

  var avatarUrl = "".obs;
  var nickname = "".obs;
  var fullName = "".obs;
  var token = "".obs;
  var takipEdiyorum = false.obs;
  var followLoading = false.obs;
  // yorumCount -> commentCount RxInt'e taşındı
  var pageCounter = 0.obs;
  // Yeni interaction service
  late PostInteractionService _interactionService;
  final UserSummaryResolver _userSummaryResolver = UserSummaryResolver.ensure();

  // Stats observables - PostsModel.stats'tan alinacak
  RxInt likeCount = 0.obs;
  RxInt commentCount = 0.obs;
  RxInt savedCount = 0.obs;
  RxInt retryCount = 0.obs;
  RxInt viewCount = 0.obs;
  RxInt reportCount = 0.obs;

  // User interaction status
  RxBool isLiked = false.obs;
  RxBool isSaved = false.obs;
  RxBool isReshared = false.obs;
  RxBool isReported = false.obs;
  var gizlendi = false.obs;
  var arsivlendi = false.obs;
  var silindi = false.obs;
  var silindiOpacity = 1.0.obs;
  var ilkPaylasanPfImage = "".obs;
  var ilkPaylasanNickname = "".obs;
  var ilkPaylasanUserID = "".obs;
  var fullscreen = true.obs;
  // Kaldırılan deprecated değişkenler:
  // yenidenPaylasildiMi -> isReshared
  // countManager -> PostInteractionService
  // retryCount, statsCount -> lokal RxInt'ler
  StreamSubscription<DocumentSnapshot>? _postDocSub;
  late final PostRepository _postRepository;
  PostRepositoryState? _postState;
  Worker? _interactionWorker;
  Worker? _postDataWorker;
  Timer? _deleteFadeTimer;
  Timer? _deleteRemoveTimer;
  String get _currentUserId => CurrentUserService.instance.effectiveUserId;

  @override
  void onInit() {
    super.onInit();

    // Initialize interaction service
    _interactionService = PostInteractionService.ensure();
    _postRepository = PostRepository.ensure();

    // Initialize stats from model
    _initializeStats();

    // Initialize other data
    getGizleArsivSikayetEdildi();
    avatarUrl.value = model.authorAvatarUrl.trim();
    nickname.value = model.authorNickname.trim();
    fullName.value = model.authorDisplayName.trim();
    fetchUserData(model.userID);

    // Record view and load user interaction status
    Future.microtask(() {
      if (isClosed) return;
      _interactionService.recordView(model.docID);
      _loadUserInteractionStatus();
    });

    // Bind listeners
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (isClosed) return;
      _bindPostStatsListener();
    });
  }

  @override
  void onClose() {
    _deleteFadeTimer?.cancel();
    _deleteRemoveTimer?.cancel();
    _interactionWorker?.dispose();
    _postDataWorker?.dispose();
    _postRepository.releasePost(model.docID);
    _postDocSub?.cancel();
    super.onClose();
  }
}
