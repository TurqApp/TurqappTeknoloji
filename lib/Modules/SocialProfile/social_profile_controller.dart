import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/follow_service.dart';
import 'package:turqappv2/Core/Repositories/follow_repository.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Core/BottomSheets/no_yes_alert.dart';
import 'package:turqappv2/Core/formatters.dart';
import 'package:turqappv2/Core/Services/performance_service.dart';
import 'package:turqappv2/Core/Services/runtime_invariant_guard.dart';
import 'package:turqappv2/Core/Services/user_summary_resolver.dart';
import 'package:turqappv2/Core/Services/visibility_policy_service.dart';
import 'package:turqappv2/Core/Utils/avatar_url.dart';
import 'package:turqappv2/Core/Repositories/profile_repository.dart';
import 'package:turqappv2/Core/Repositories/social_media_links_repository.dart';
import 'package:turqappv2/Core/Repositories/story_repository.dart';
import 'package:turqappv2/Core/Repositories/user_repository.dart';
import 'package:turqappv2/Core/Repositories/user_subcollection_repository.dart';
import 'package:turqappv2/Models/social_media_model.dart';
import 'package:turqappv2/Services/current_user_service.dart';
import '../../Models/posts_model.dart';
import '../../Models/user_post_reference.dart';
import '../../Services/user_post_link_service.dart';
import '../../Services/user_analytics_service.dart';
import 'package:turqappv2/Core/notification_service.dart';
import '../Agenda/AgendaContent/agenda_content_controller.dart';
import '../Profile/SocialMediaLinks/social_media_links_controller.dart';
import '../Story/StoryRow/story_user_model.dart';

part 'social_profile_controller_profile_part.dart';
part 'social_profile_controller_actions_part.dart';
part 'social_profile_controller_feed_part.dart';
part 'social_profile_controller_feed_selection_part.dart';
part 'social_profile_controller_runtime_part.dart';
part 'social_profile_controller_models_part.dart';
part 'social_profile_controller_support_part.dart';

class SocialProfileController extends GetxController {
  static SocialProfileController ensure({
    required String userID,
    String? tag,
    bool permanent = false,
  }) {
    final existing = maybeFind(tag: tag);
    if (existing != null) return existing;
    return Get.put(
      SocialProfileController(userID: userID),
      tag: tag,
      permanent: permanent,
    );
  }

  static SocialProfileController? maybeFind({String? tag}) {
    final isRegistered = Get.isRegistered<SocialProfileController>(tag: tag);
    if (!isRegistered) return null;
    return Get.find<SocialProfileController>(tag: tag);
  }

  var totalMarket = 0.obs;
  var totalPosts = 0.obs;
  var totalLikes = 0.obs;
  var totalFollower = 0.obs;
  var totalFollowing = 0.obs;
  var postSelection = 0.obs;

  final currentVisibleIndex = RxInt(-1);
  final centeredIndex = 0.obs;
  int? lastCenteredIndex;
  String? _pendingCenteredIdentity;

  final ScrollController scrollController = ScrollController();
  final RxList<SocialMediaModel> socialMediaList = <SocialMediaModel>[].obs;
  final RxList<PostsModel> reshares = <PostsModel>[].obs;
  StreamSubscription<List<UserPostReference>>? _resharesSub;
  final Map<String, GlobalKey> _postKeys = {};
  var showPfImage = false.obs;

  String userID;
  SocialProfileController({required this.userID});
  var nickname = "".obs;
  var displayName = "".obs;
  var avatarUrl = "".obs;
  var firstName = "".obs;
  var lastName = "".obs;
  var token = "".obs;
  var email = "".obs;
  var rozet = "".obs;
  var bio = "".obs;

  var adres = "".obs;
  var phoneNumber = "".obs;
  var mailIzin = false.obs;
  var aramaIzin = false.obs;
  var ban = false.obs;
  var gizliHesap = false.obs;
  var hesapOnayi = false.obs;
  var meslek = "".obs;
  var blockedUsers = <String>[].obs;
  var complatedCheck = false.obs;
  var takipEdiyorum = false.obs;
  var followLoading = false.obs;

  final RxList<PostsModel> allPosts = <PostsModel>[].obs;

  final RxList<PostsModel> photos = <PostsModel>[].obs;
  final RxList<PostsModel> scheduledPosts = <PostsModel>[].obs;

  final RxBool isLoadingPosts = false.obs;
  final RxBool hasMorePosts = true.obs;
  DocumentSnapshot? lastPostDoc;
  final int pageSize = 12;
  DocumentSnapshot<Map<String, dynamic>>? _lastPrimaryDoc;
  bool _hasMorePrimary = true;
  bool _isLoadingPrimary = false;

  final RxBool isLoadingPhoto = false.obs;
  final RxBool hasMorePhoto = true.obs;
  DocumentSnapshot? lastPostDocPhoto;
  final int pageSizePhoto = 12;

  // Scheduled (İz Bırak)
  final RxBool isLoadingScheduled = false.obs;
  final RxBool hasMoreScheduled = true.obs;
  DocumentSnapshot? lastScheduledDoc;
  final int pageSizeScheduled = 12;
  StoryUserModel? storyUserModel;
  // Yukarı butonu
  final RxBool showScrollToTop = false.obs;
  StreamSubscription<Map<String, dynamic>?>? _userDocSub;

  @override
  void onInit() {
    super.onInit();
    _handleLifecycleInit();
  }

  @override
  void onClose() {
    _handleLifecycleClose();
    super.onClose();
  }
}
