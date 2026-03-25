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
part 'short_content_controller_runtime_part.dart';

final PostInteractionService _shortInteractionService =
    PostInteractionService.ensure();
final PostRepository _shortPostRepository = PostRepository.ensure();
final UserSummaryResolver _shortUserSummaryResolver =
    UserSummaryResolver.ensure();

String get _shortCurrentUserId => CurrentUserService.instance.effectiveUserId;

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
  var pageCounter = 0.obs;
  RxInt likeCount = 0.obs;
  RxInt commentCount = 0.obs;
  RxInt savedCount = 0.obs;
  RxInt retryCount = 0.obs;
  RxInt viewCount = 0.obs;
  RxInt reportCount = 0.obs;
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
  StreamSubscription<DocumentSnapshot>? _postDocSub;
  PostRepositoryState? _postState;
  Worker? _interactionWorker;
  Worker? _postDataWorker;
  Timer? _deleteFadeTimer;
  Timer? _deleteRemoveTimer;

  @override
  void onInit() {
    super.onInit();
    _handleRuntimeInit();
  }

  @override
  void onClose() {
    _handleRuntimeClose();
    super.onClose();
  }
}
