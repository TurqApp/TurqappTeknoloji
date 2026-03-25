import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/BottomSheets/no_yes_alert.dart';
import 'package:turqappv2/Core/Repositories/follow_repository.dart';
import 'package:turqappv2/Core/Repositories/profile_posts_snapshot_repository.dart';
import 'package:turqappv2/Core/Repositories/profile_repository.dart';
import 'package:turqappv2/Core/Repositories/social_media_links_repository.dart';
import 'package:turqappv2/Core/Repositories/user_repository.dart';
import 'package:turqappv2/Core/Services/CacheFirst/cached_resource.dart';
import 'package:turqappv2/Core/Services/feed_playback_selection_policy.dart';
import 'package:turqappv2/Core/Services/profile_render_coordinator.dart';
import 'package:turqappv2/Core/Services/runtime_invariant_guard.dart';
import 'package:turqappv2/Core/Services/turq_image_cache_manager.dart';
import 'package:turqappv2/Core/Services/user_summary_resolver.dart';
import 'package:turqappv2/Core/Services/video_state_manager.dart';
import 'package:turqappv2/Core/Services/visibility_policy_service.dart';
import 'package:turqappv2/Modules/Profile/SocialMediaLinks/social_media_links_controller.dart';
import 'package:turqappv2/Services/current_user_service.dart';
import '../../../Models/posts_model.dart';
import '../../../Models/user_post_reference.dart';
import '../../../Services/user_post_link_service.dart';
import '../../Agenda/AgendaContent/agenda_content_controller.dart';

part 'profile_controller_header_part.dart';
part 'profile_controller_primary_part.dart';
part 'profile_controller_cache_part.dart';
part 'profile_controller_lifecycle_part.dart';
part 'profile_controller_selection_part.dart';
part 'profile_controller_runtime_part.dart';
part 'profile_controller_support_part.dart';

class ProfileController extends GetxController {
  static ProfileController ensure() {
    final existing = maybeFind();
    if (existing != null) return existing;
    return Get.put(ProfileController());
  }

  static ProfileController? maybeFind() {
    final isRegistered = Get.isRegistered<ProfileController>();
    if (!isRegistered) return null;
    return Get.find<ProfileController>();
  }

  // 🎯 Using CurrentUserService for optimized user data access
  // Aktif oturum kullanıcısını izleyip veri setlerini dinamik yenilemek için
  String? _activeUid;
  StreamSubscription<User?>? _authSub;
  StreamSubscription<Map<String, dynamic>?>? _counterSub;
  Timer? _persistCacheTimer;
  Worker? _allPostsWorker;
  Worker? _photosWorker;
  Worker? _videosWorker;
  Worker? _resharesWorker;
  Worker? _scheduledWorker;
  Worker? _mergedPostsWorker;
  Worker? _postSelectionWorker;
  var postSelection = 0.obs;

  final currentVisibleIndex = RxInt(-1);
  final centeredIndex = 0.obs;
  int? lastCenteredIndex;
  String? _pendingCenteredIdentity;
  final Map<int, double> _visibleFractions = <int, double>{};
  Timer? _visibilityDebounce;

  var followerCount = 0.obs;
  var followingCount = 0.obs;
  final RxString headerNickname = ''.obs;
  final RxString headerRozet = ''.obs;
  final RxString headerDisplayName = ''.obs;
  final RxString headerAvatarUrl = ''.obs;
  final RxString headerFirstName = ''.obs;
  final RxString headerLastName = ''.obs;
  final RxString headerMeslek = ''.obs;
  final RxString headerBio = ''.obs;
  final RxString headerAdres = ''.obs;

  final RxList<PostsModel> allPosts = <PostsModel>[].obs;
  final RxList<Map<String, dynamic>> mergedPosts = <Map<String, dynamic>>[].obs;
  DocumentSnapshot? lastPostDoc;
  bool hasMorePosts = true;
  final int postLimit = 10;
  bool isLoadingMore = false;
  DocumentSnapshot<Map<String, dynamic>>? _lastPrimaryDoc;
  bool _hasMorePrimary = true;
  bool _isLoadingPrimary = false;

  // İz Bırak (gelecek tarihli) gönderiler
  final RxList<PostsModel> scheduledPosts = <PostsModel>[].obs;
  DocumentSnapshot? lastScheduledDoc;
  bool hasMoreScheduled = true;
  final int scheduledLimit = 10;
  bool isLoadingScheduled = false;

  final RxList<PostsModel> photos = <PostsModel>[].obs;
  DocumentSnapshot? lastPostDocPhotos;
  bool hasMorePostsPhotos = true;
  final int postLimitPhotos = 10;
  bool isLoadingMorePhotos = false;

  final RxList<PostsModel> videos = <PostsModel>[].obs;
  DocumentSnapshot? lastPostDocVideos;
  bool hasMorePostsVideos = true;
  final int postLimitVideos = 10;
  bool isLoadingMoreVideos = false;

  final RxList<PostsModel> reshares = <PostsModel>[].obs;
  StreamSubscription<List<UserPostReference>>? _resharesSub;
  final UserPostLinkService _linkService = UserPostLinkService.ensure();
  List<UserPostReference> _latestReshareRefs = const [];
  final Map<String, GlobalKey> _postKeys = {};

  var pausetheall = false.obs;
  final RxBool showScrollToTop = false.obs;
  final Map<int, ScrollController> _scrollControllers =
      <int, ScrollController>{};
  var showPfImage = false.obs;

  @override
  void onInit() {
    super.onInit();
    _performOnInit();
  }

  @override
  void onClose() {
    _performOnClose();
    super.onClose();
  }
}
