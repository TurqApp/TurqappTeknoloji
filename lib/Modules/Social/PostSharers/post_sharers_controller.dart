import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Repositories/post_repository.dart';
import 'package:turqappv2/Core/Services/user_summary_resolver.dart';
import 'package:turqappv2/Models/post_sharers_model.dart';

part 'post_sharers_controller_paging_part.dart';

class PostSharersController extends GetxController {
  static const int _pageSize = 20;

  static PostSharersController ensure({
    required String postID,
    String? tag,
    bool permanent = false,
  }) {
    final existing = maybeFind(tag: tag);
    if (existing != null) return existing;
    return Get.put(
      PostSharersController(postID: postID),
      tag: tag,
      permanent: permanent,
    );
  }

  static PostSharersController? maybeFind({String? tag}) {
    final isRegistered = Get.isRegistered<PostSharersController>(tag: tag);
    if (!isRegistered) return null;
    return Get.find<PostSharersController>(tag: tag);
  }

  final String postID;

  PostSharersController({required this.postID});

  final RxList<PostSharersModel> postSharers = <PostSharersModel>[].obs;
  final RxMap<String, Map<String, dynamic>> usersData =
      <String, Map<String, dynamic>>{}.obs;
  final RxBool isLoading = true.obs;
  final RxBool isLoadingMore = false.obs;
  final RxBool hasMore = true.obs;
  final ScrollController scrollController = ScrollController();
  final UserSummaryResolver _userSummaryResolver = UserSummaryResolver.ensure();
  final PostRepository _postRepository = PostRepository.ensure();
  DocumentSnapshot<Map<String, dynamic>>? _lastSharerDoc;
  String _resolvedPostId = '';
  bool _isFetching = false;
  bool _usingFallbackSharers = false;
  List<PostSharersModel> _fallbackSharers = const <PostSharersModel>[];
  int _fallbackOffset = 0;

  @override
  void onInit() {
    super.onInit();
    scrollController.addListener(_onScroll);
    loadPostSharers();
  }

  @override
  void onClose() {
    scrollController.removeListener(_onScroll);
    scrollController.dispose();
    super.onClose();
  }

  Future<void> loadPostSharers() async {
    if (_isFetching) return;
    _isFetching = true;
    try {
      isLoading.value = true;
      isLoadingMore.value = false;
      _lastSharerDoc = null;
      hasMore.value = true;
      postSharers.clear();
      usersData.clear();
      _usingFallbackSharers = false;
      _fallbackSharers = const <PostSharersModel>[];
      _fallbackOffset = 0;

      _resolvedPostId = postID.trim();
      var targetPostId = _resolvedPostId;
      var page = await _postRepository.fetchPostSharersPage(
        targetPostId,
        limit: _pageSize,
      );
      if (page.items.isEmpty && targetPostId.isNotEmpty) {
        final model = await _postRepository.fetchPostById(
          targetPostId,
          preferCache: true,
        );
        final originalPostId = model?.originalPostID.trim() ?? '';
        if (originalPostId.isNotEmpty && originalPostId != targetPostId) {
          targetPostId = originalPostId;
          page = await _postRepository.fetchPostSharersPage(
            targetPostId,
            limit: _pageSize,
          );
        }
      }
      _resolvedPostId = targetPostId;
      if (page.items.isEmpty && targetPostId.isNotEmpty) {
        final fallbackSharers =
            await _postRepository.fetchSharedAsPostSharersFallback(
          targetPostId,
        );
        if (fallbackSharers.isNotEmpty) {
          _usingFallbackSharers = true;
          _fallbackSharers = fallbackSharers;
          _appendFallbackPage(reset: true);
          return;
        }
      }
      _lastSharerDoc = page.lastDoc;
      hasMore.value = page.hasMore;
      postSharers.assignAll(page.items);

      final userIds = page.items
          .map((sharer) => sharer.userID.trim())
          .where((id) => id.isNotEmpty)
          .toSet()
          .toList(growable: false);
      await loadUsersData(userIds);
    } catch (_) {
    } finally {
      _isFetching = false;
      isLoading.value = false;
    }
  }
}
