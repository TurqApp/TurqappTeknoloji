import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Repositories/post_repository.dart';
import 'package:turqappv2/Core/Services/user_summary_resolver.dart';
import 'package:turqappv2/Models/post_sharers_model.dart';

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

  Future<void> loadMoreSharers() async {
    if (_isFetching || !hasMore.value || _resolvedPostId.isEmpty) return;
    if (_usingFallbackSharers) {
      _appendFallbackPage();
      return;
    }
    _isFetching = true;
    isLoadingMore.value = true;

    try {
      final page = await _postRepository.fetchPostSharersPage(
        _resolvedPostId,
        lastDoc: _lastSharerDoc,
        limit: _pageSize,
      );
      if (page.items.isEmpty) {
        hasMore.value = false;
        return;
      }

      _lastSharerDoc = page.lastDoc;
      hasMore.value = page.hasMore;

      final existingKeys = postSharers
          .map(
              (item) => '${item.userID}_${item.sharedPostID}_${item.timestamp}')
          .toSet();
      final newItems = page.items.where((item) {
        final key = '${item.userID}_${item.sharedPostID}_${item.timestamp}';
        return existingKeys.add(key);
      }).toList(growable: false);

      if (newItems.isEmpty) {
        if (!page.hasMore) {
          hasMore.value = false;
        }
        return;
      }

      postSharers.addAll(newItems);
      final missingUserIds = newItems
          .map((item) => item.userID.trim())
          .where((id) => id.isNotEmpty && !usersData.containsKey(id))
          .toSet()
          .toList(growable: false);
      await loadUsersData(missingUserIds);
    } catch (_) {
    } finally {
      _isFetching = false;
      isLoadingMore.value = false;
    }
  }

  Future<void> loadUsersData(List<String> userIDs) async {
    if (userIDs.isEmpty) return;
    try {
      final userData = Map<String, Map<String, dynamic>>.from(usersData);
      final rawUsers =
          await _userSummaryResolver.resolveMany(userIDs.toSet().toList());
      for (final userID in userIDs.toSet()) {
        final data = rawUsers[userID];
        if (data == null) {
          userData[userID] = {
            'nickname': 'common.unknown_user'.tr,
            'avatarUrl': '',
            'fullName': 'common.unknown_user'.tr,
            'firstName': '',
            'lastName': '',
          };
          continue;
        }
        final fullName = data.displayName.trim();
        final nickname = data.nickname.trim();

        userData[userID] = {
          'nickname': nickname,
          'avatarUrl': data.avatarUrl,
          'fullName': fullName.isNotEmpty ? fullName : 'common.unknown_user'.tr,
          'firstName': fullName,
          'lastName': '',
        };
      }

      usersData.value = userData;
    } catch (_) {}
  }

  Future<void> refreshSharers() async {
    await loadPostSharers();
  }

  void _appendFallbackPage({bool reset = false}) {
    if (!_usingFallbackSharers) return;
    if (reset) {
      _fallbackOffset = 0;
      postSharers.clear();
      hasMore.value = _fallbackSharers.isNotEmpty;
    }
    if (_fallbackOffset >= _fallbackSharers.length) {
      hasMore.value = false;
      return;
    }

    final nextOffset = (_fallbackOffset + _pageSize) > _fallbackSharers.length
        ? _fallbackSharers.length
        : _fallbackOffset + _pageSize;
    final pageItems = _fallbackSharers.sublist(_fallbackOffset, nextOffset);
    _fallbackOffset = nextOffset;
    postSharers.addAll(pageItems);
    hasMore.value = _fallbackOffset < _fallbackSharers.length;

    final missingUserIds = pageItems
        .map((item) => item.userID.trim())
        .where((id) => id.isNotEmpty && !usersData.containsKey(id))
        .toSet()
        .toList(growable: false);
    if (missingUserIds.isEmpty) return;
    loadUsersData(missingUserIds);
  }

  void _onScroll() {
    if (!scrollController.hasClients || _isFetching || !hasMore.value) return;
    final position = scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 180) {
      loadMoreSharers();
    }
  }
}
