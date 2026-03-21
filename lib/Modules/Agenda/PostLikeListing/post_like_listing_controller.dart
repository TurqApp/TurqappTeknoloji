import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Repositories/post_repository.dart';
import 'package:turqappv2/Core/Services/user_summary_resolver.dart';
import 'package:turqappv2/Core/Utils/text_normalization_utils.dart';

class LikeUserItem {
  const LikeUserItem({
    required this.userID,
    required this.nickname,
    required this.fullName,
    required this.avatarUrl,
    required this.searchText,
  });

  final String userID;
  final String nickname;
  final String fullName;
  final String avatarUrl;
  final String searchText;
}

class PostLikeListingController extends GetxController {
  PostLikeListingController({required this.postID});
  static const int _pageSize = 20;

  static PostLikeListingController ensure({required String tag}) {
    final existing = maybeFind(tag: tag);
    if (existing != null) return existing;
    return Get.put(PostLikeListingController(postID: tag), tag: tag);
  }

  static PostLikeListingController? maybeFind({required String tag}) {
    if (!Get.isRegistered<PostLikeListingController>(tag: tag)) return null;
    return Get.find<PostLikeListingController>(tag: tag);
  }

  final String postID;
  final PostRepository _postRepository = PostRepository.ensure();
  final UserSummaryResolver _userSummaryResolver = UserSummaryResolver.ensure();
  final RxList<LikeUserItem> users = <LikeUserItem>[].obs;
  final RxList<LikeUserItem> filteredUsers = <LikeUserItem>[].obs;
  final RxString query = ''.obs;
  final TextEditingController searchController = TextEditingController();
  final ScrollController scrollController = ScrollController();
  final RxBool isLoadingMore = false.obs;
  final RxBool hasMore = true.obs;
  DocumentSnapshot<Map<String, dynamic>>? _lastLikeDoc;
  bool _isFetching = false;

  @override
  void onInit() {
    super.onInit();
    searchController.addListener(_syncQueryFromInput);
    scrollController.addListener(_onScroll);
    ever<List<LikeUserItem>>(users, (_) => _applyFilter());
    ever<String>(query, (_) => _applyFilter());
    getLikes();
  }

  @override
  void onClose() {
    searchController.removeListener(_syncQueryFromInput);
    searchController.dispose();
    scrollController.removeListener(_onScroll);
    scrollController.dispose();
    super.onClose();
  }

  void onSearchChanged(String value) {
    final normalized = normalizeSearchText(value);
    if (query.value == normalized) return;
    query.value = normalized;
  }

  void _syncQueryFromInput() {
    onSearchChanged(searchController.text);
  }

  Future<void> getLikes() async {
    if (_isFetching || !hasMore.value) return;
    _isFetching = true;
    isLoadingMore.value = users.isNotEmpty;

    try {
      final page = await _postRepository.fetchLikeUserIdsPage(
        postID,
        lastDoc: _lastLikeDoc,
        limit: _pageSize,
      );
      if (page.userIds.isEmpty) {
        hasMore.value = false;
        return;
      }

      _lastLikeDoc = page.lastDoc;
      hasMore.value = page.hasMore;
      final fetched = await Future.wait(page.userIds.map(_fetchUserItem));
      users.addAll(fetched.whereType<LikeUserItem>());
      _applyFilter();
    } finally {
      _isFetching = false;
      isLoadingMore.value = false;
    }
  }

  Future<LikeUserItem?> _fetchUserItem(String userID) async {
    try {
      final summary = await _userSummaryResolver.resolve(
        userID,
        preferCache: true,
      );
      if (summary == null) return null;
      final nickname = summary.nickname.trim();
      final username = summary.preferredName.trim();
      final fullName = summary.displayName.trim();
      final avatarUrl = summary.avatarUrl.trim();
      final searchText = normalizeSearchText([
        nickname,
        username,
        fullName,
        userID,
      ].join(' '));

      return LikeUserItem(
        userID: userID,
        nickname: nickname,
        fullName: fullName,
        avatarUrl: avatarUrl,
        searchText: searchText,
      );
    } catch (_) {
      return null;
    }
  }

  void _applyFilter() {
    final term = normalizeSearchText(query.value);
    if (term.isEmpty) {
      filteredUsers.assignAll(users);
    } else {
      filteredUsers.assignAll(
        users.where((user) => user.searchText.contains(term)),
      );
    }
  }

  void _onScroll() {
    if (!scrollController.hasClients || _isFetching || !hasMore.value) return;
    final position = scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 180) {
      getLikes();
    }
  }
}
