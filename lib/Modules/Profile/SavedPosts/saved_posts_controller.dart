import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:turqappv2/Core/Repositories/post_repository.dart';
import 'package:turqappv2/Core/Services/silent_refresh_gate.dart';
import 'package:turqappv2/Models/posts_model.dart';
import 'package:turqappv2/Models/user_post_reference.dart';
import 'package:turqappv2/Services/user_post_link_service.dart';

part 'saved_posts_controller_data_part.dart';

class SavedPostsController extends GetxController {
  static const Duration _silentRefreshInterval = Duration(minutes: 5);

  static SavedPostsController ensure({bool permanent = false}) {
    final existing = maybeFind();
    if (existing != null) return existing;
    return Get.put(
      SavedPostsController(),
      permanent: permanent,
    );
  }

  static SavedPostsController? maybeFind() {
    final isRegistered = Get.isRegistered<SavedPostsController>();
    if (!isRegistered) return null;
    return Get.find<SavedPostsController>();
  }

  final RxList<PostsModel> savedAgendas = <PostsModel>[].obs;
  final RxList<PostsModel> savedPostsOnly = <PostsModel>[].obs;
  final RxList<PostsModel> savedSeries = <PostsModel>[].obs;

  final isLoading = false.obs;
  final PageController pageController = PageController(initialPage: 0);

  StreamSubscription<User?>? _authSub;
  StreamSubscription<List<UserPostReference>>? _savedPostsSub;
  final UserPostLinkService _linkService = UserPostLinkService.ensure();
  final PostRepository _postRepository = PostRepository.ensure();

  String? _currentUserId;
  List<UserPostReference> _latestRefs = const [];

  @override
  void onInit() {
    super.onInit();
    _handleOnInit();
  }

  @override
  Future<void> refresh() async {
    await _refreshSavedPosts();
  }

  @override
  void onClose() {
    _handleOnClose();
    super.onClose();
  }
}
