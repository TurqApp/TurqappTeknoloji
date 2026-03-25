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

  void goToPage(int index) {
    pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  GlobalKey getPostKey(String docId) {
    return _postKeys.putIfAbsent(
      docId,
      () => GlobalObjectKey('liked_post_$docId'),
    );
  }

  String agendaInstanceTag(String docId) => 'liked_post_$docId';

  void disposeAgendaContentController(String docId) {
    final tag = agendaInstanceTag(docId);
    if (AgendaContentController.maybeFind(tag: tag) != null) {
      Get.delete<AgendaContentController>(tag: tag, force: true);
    }
  }

  int resolveResumeCenteredIndex() {
    if (all.isEmpty) return -1;
    final pendingDocId = _pendingCenteredDocId;
    if (pendingDocId != null && pendingDocId.isNotEmpty) {
      final pendingIndex =
          all.indexWhere((post) => post.docID.trim() == pendingDocId);
      if (pendingIndex >= 0) {
        return pendingIndex;
      }
    }
    if (lastCenteredIndex != null &&
        lastCenteredIndex! >= 0 &&
        lastCenteredIndex! < all.length) {
      return lastCenteredIndex!;
    }
    if (centeredIndex.value >= 0 && centeredIndex.value < all.length) {
      return centeredIndex.value;
    }
    return 0;
  }

  void resumeCenteredPost() {
    final target = resolveResumeCenteredIndex();
    if (target < 0 || target >= all.length) return;
    lastCenteredIndex = target;
    centeredIndex.value = target;
    currentVisibleIndex.value = target;
    capturePendingCenteredEntry(preferredIndex: target);
  }

  void capturePendingCenteredEntry({int? preferredIndex, PostsModel? model}) {
    if (model != null) {
      final docId = model.docID.trim();
      _pendingCenteredDocId = docId.isEmpty ? null : docId;
      return;
    }
    final candidateIndex = preferredIndex ??
        (currentVisibleIndex.value >= 0
            ? currentVisibleIndex.value
            : lastCenteredIndex);
    if (candidateIndex == null ||
        candidateIndex < 0 ||
        candidateIndex >= all.length) {
      _pendingCenteredDocId = null;
      return;
    }
    final docId = all[candidateIndex].docID.trim();
    _pendingCenteredDocId = docId.isEmpty ? null : docId;
  }
}
