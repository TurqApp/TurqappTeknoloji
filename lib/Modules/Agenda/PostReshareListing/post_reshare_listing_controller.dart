import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Repositories/post_repository.dart';
import 'package:turqappv2/Core/Services/user_summary_resolver.dart';

class ReshareUserItem {
  const ReshareUserItem({
    required this.userID,
    required this.nickname,
    required this.fullName,
    required this.avatarUrl,
  });

  final String userID;
  final String nickname;
  final String fullName;
  final String avatarUrl;
}

class PostReshareListingController extends GetxController {
  PostReshareListingController({required this.postID});

  static const int _pageSize = 20;

  static PostReshareListingController ensure({required String tag}) {
    final existing = maybeFind(tag: tag);
    if (existing != null) return existing;
    return Get.put(PostReshareListingController(postID: tag), tag: tag);
  }

  static PostReshareListingController? maybeFind({required String tag}) {
    final isRegistered =
        Get.isRegistered<PostReshareListingController>(tag: tag);
    if (!isRegistered) return null;
    return Get.find<PostReshareListingController>(tag: tag);
  }

  final String postID;
  final PostRepository _postRepository = PostRepository.ensure();
  final UserSummaryResolver _userSummaryResolver = UserSummaryResolver.ensure();
  final RxList<ReshareUserItem> reshareUsers = <ReshareUserItem>[].obs;
  final RxList<ReshareUserItem> quoteUsers = <ReshareUserItem>[].obs;
  final RxBool isLoadingReshares = false.obs;
  final RxBool isLoadingQuotes = false.obs;
  final RxBool isLoadingMoreReshares = false.obs;
  final RxBool isLoadingMoreQuotes = false.obs;
  final RxBool hasMoreReshares = true.obs;
  final RxBool hasMoreQuotes = true.obs;
  final ScrollController reshareScrollController = ScrollController();
  final ScrollController quoteScrollController = ScrollController();

  DocumentSnapshot<Map<String, dynamic>>? _lastReshareDoc;
  DocumentSnapshot<Map<String, dynamic>>? _lastQuoteSharerDoc;
  bool _fetchingReshares = false;
  bool _fetchingQuotes = false;
  bool _quotesInitialized = false;

  @override
  void onInit() {
    super.onInit();
    reshareScrollController.addListener(_onReshareScroll);
    quoteScrollController.addListener(_onQuoteScroll);
    loadMoreReshares(initial: true);
  }

  @override
  void onClose() {
    reshareScrollController.removeListener(_onReshareScroll);
    quoteScrollController.removeListener(_onQuoteScroll);
    reshareScrollController.dispose();
    quoteScrollController.dispose();
    super.onClose();
  }

  void ensureQuotesLoaded() {
    if (_quotesInitialized) return;
    _quotesInitialized = true;
    loadMoreQuotes(initial: true);
  }

  Future<void> loadMoreReshares({bool initial = false}) async {
    if (_fetchingReshares || !hasMoreReshares.value) return;
    _fetchingReshares = true;
    if (initial) {
      isLoadingReshares.value = true;
    } else {
      isLoadingMoreReshares.value = true;
    }

    try {
      final page = await _postRepository.fetchReshareUserIdsPage(
        postID,
        lastDoc: _lastReshareDoc,
        limit: _pageSize,
      );
      if (page.userIds.isEmpty) {
        hasMoreReshares.value = false;
        return;
      }

      _lastReshareDoc = page.lastDoc;
      hasMoreReshares.value = page.hasMore;

      final fetched = await Future.wait(
        page.userIds.map(_fetchUserItem),
      );
      final existingIds = reshareUsers.map((e) => e.userID).toSet();
      reshareUsers.addAll(
        fetched.whereType<ReshareUserItem>().where(
              (item) => existingIds.add(item.userID),
            ),
      );
    } finally {
      _fetchingReshares = false;
      isLoadingReshares.value = false;
      isLoadingMoreReshares.value = false;
    }
  }

  Future<void> loadMoreQuotes({bool initial = false}) async {
    if (_fetchingQuotes || !hasMoreQuotes.value) return;
    _fetchingQuotes = true;
    if (initial) {
      isLoadingQuotes.value = true;
    } else {
      isLoadingMoreQuotes.value = true;
    }

    final newItems = <ReshareUserItem>[];
    final existingIds = quoteUsers.map((e) => e.userID).toSet();

    try {
      final page = await _postRepository.fetchQuoteUserIdsPage(
        postID,
        lastDoc: _lastQuoteSharerDoc,
        limit: _pageSize,
      );
      _lastQuoteSharerDoc = page.lastDoc;
      hasMoreQuotes.value = page.hasMore;

      final fetched = await Future.wait(page.userIds.map(_fetchUserItem));
      for (final item in fetched.whereType<ReshareUserItem>()) {
        if (existingIds.add(item.userID)) {
          newItems.add(item);
        }
      }

      quoteUsers.addAll(newItems);
    } finally {
      _fetchingQuotes = false;
      isLoadingQuotes.value = false;
      isLoadingMoreQuotes.value = false;
    }
  }

  Future<ReshareUserItem?> _fetchUserItem(String userID) async {
    try {
      final summary = await _userSummaryResolver.resolve(
        userID,
        preferCache: true,
      );
      if (summary == null) return null;
      return ReshareUserItem(
        userID: userID,
        nickname: summary.nickname.trim(),
        fullName: summary.displayName.trim(),
        avatarUrl: summary.avatarUrl.trim(),
      );
    } catch (_) {
      return null;
    }
  }

  void _onReshareScroll() {
    if (!reshareScrollController.hasClients ||
        _fetchingReshares ||
        !hasMoreReshares.value) {
      return;
    }
    final position = reshareScrollController.position;
    if (position.pixels >= position.maxScrollExtent - 180) {
      loadMoreReshares();
    }
  }

  void _onQuoteScroll() {
    if (!quoteScrollController.hasClients ||
        _fetchingQuotes ||
        !hasMoreQuotes.value) {
      return;
    }
    final position = quoteScrollController.position;
    if (position.pixels >= position.maxScrollExtent - 180) {
      loadMoreQuotes();
    }
  }
}
