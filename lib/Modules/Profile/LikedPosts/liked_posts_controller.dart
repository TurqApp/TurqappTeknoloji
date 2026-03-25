import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:turqappv2/Modules/Agenda/AgendaContent/agenda_content_controller.dart';
import 'package:turqappv2/Core/Services/silent_refresh_gate.dart';
import 'package:turqappv2/Models/posts_model.dart';
import 'package:turqappv2/Models/user_post_reference.dart';
import 'package:turqappv2/Services/user_post_link_service.dart';

part 'liked_posts_controller_lifecycle_part.dart';
part 'liked_posts_controller_data_part.dart';
part 'liked_posts_controller_navigation_part.dart';

class LikedPostControllers extends GetxController {
  static LikedPostControllers ensure() {
    final existing = maybeFind();
    if (existing != null) return existing;
    return Get.put(LikedPostControllers());
  }

  static LikedPostControllers? maybeFind() {
    final isRegistered = Get.isRegistered<LikedPostControllers>();
    if (!isRegistered) return null;
    return Get.find<LikedPostControllers>();
  }

  static const Duration _silentRefreshInterval = Duration(minutes: 5);

  final RxList<PostsModel> all = <PostsModel>[].obs;
  final selection = 0.obs;
  PageController pageController = PageController(initialPage: 0);
  final currentVisibleIndex = RxInt(-1);
  final centeredIndex = 0.obs;
  int? lastCenteredIndex;
  String? _pendingCenteredDocId;

  final UserPostLinkService _linkService = UserPostLinkService.ensure();
  StreamSubscription<User?>? _authSub;
  StreamSubscription<List<UserPostReference>>? _likedSub;
  final Map<String, GlobalKey> _postKeys = {};

  String? _currentUserId;
  List<UserPostReference> _latestRefs = const [];
  final isLoading = false.obs;

  List<PostsModel> get likedAll => all;

  List<PostsModel> get likedPostsOnly =>
      all.where((post) => !isSeriesPost(post)).toList(growable: false);

  List<PostsModel> get likedSeries =>
      all.where(isSeriesPost).toList(growable: false);

  static bool isSeriesPost(PostsModel post) => post.floodCount > 1;

  @override
  void onInit() {
    super.onInit();
    _LikedPostsControllerLifecyclePart(this).handleOnInit();
  }

  @override
  Future<void> refresh() async {
    await _LikedPostsControllerDataPart(this).refreshLikedPosts();
  }

  @override
  void onClose() {
    _LikedPostsControllerLifecyclePart(this).handleOnClose();
    super.onClose();
  }

  void goToPage(int index) =>
      _LikedPostsControllerNavigationPart(this).goToPage(index);

  GlobalKey getPostKey(String docId) =>
      _LikedPostsControllerNavigationPart(this).getPostKey(docId);

  String agendaInstanceTag(String docId) =>
      _LikedPostsControllerNavigationPart(this).agendaInstanceTag(docId);

  void disposeAgendaContentController(String docId) =>
      _LikedPostsControllerNavigationPart(this)
          .disposeAgendaContentController(docId);

  int resolveResumeCenteredIndex() =>
      _LikedPostsControllerNavigationPart(this).resolveResumeCenteredIndex();

  void resumeCenteredPost() =>
      _LikedPostsControllerNavigationPart(this).resumeCenteredPost();

  void capturePendingCenteredEntry({int? preferredIndex, PostsModel? model}) =>
      _LikedPostsControllerNavigationPart(this).capturePendingCenteredEntry(
        preferredIndex: preferredIndex,
        model: model,
      );
}
