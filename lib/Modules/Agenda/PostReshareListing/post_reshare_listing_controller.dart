import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

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

  final String postID;
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

    Query<Map<String, dynamic>> query = FirebaseFirestore.instance
        .collection('Posts')
        .doc(postID)
        .collection('reshares')
        .orderBy('timeStamp', descending: true)
        .limit(_pageSize);

    if (_lastReshareDoc != null) {
      query = query.startAfterDocument(_lastReshareDoc!);
    }

    try {
      final snap = await query.get();
      if (snap.docs.isEmpty) {
        hasMoreReshares.value = false;
        return;
      }

      _lastReshareDoc = snap.docs.last;
      if (snap.docs.length < _pageSize) {
        hasMoreReshares.value = false;
      }

      final fetched = await Future.wait(
        snap.docs.map(
          (doc) => _fetchUserItem(
            (doc.data()['userID'] ?? doc.id).toString(),
          ),
        ),
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
      while (newItems.length < _pageSize && hasMoreQuotes.value) {
        Query<Map<String, dynamic>> query = FirebaseFirestore.instance
            .collection('Posts')
            .doc(postID)
            .collection('postSharers')
            .orderBy('timestamp', descending: true)
            .limit(_pageSize);

        if (_lastQuoteSharerDoc != null) {
          query = query.startAfterDocument(_lastQuoteSharerDoc!);
        }

        final snap = await query.get();
        if (snap.docs.isEmpty) {
          hasMoreQuotes.value = false;
          break;
        }

        _lastQuoteSharerDoc = snap.docs.last;
        if (snap.docs.length < _pageSize) {
          hasMoreQuotes.value = false;
        }

        for (final doc in snap.docs) {
          final data = doc.data();
          final userID = (data['userID'] ?? doc.id).toString().trim();
          final sharedPostID = (data['sharedPostID'] ?? '').toString().trim();
          if (userID.isEmpty || sharedPostID.isEmpty) continue;
          if (existingIds.contains(userID)) continue;

          final sharedPostSnap = await FirebaseFirestore.instance
              .collection('Posts')
              .doc(sharedPostID)
              .get();
          final sharedPostData = sharedPostSnap.data() ?? const {};
          final isQuoted = sharedPostData['quotedPost'] == true;
          final isDeleted = sharedPostData['deletedPost'] == true;
          if (!isQuoted || isDeleted) continue;

          final item = await _fetchUserItem(userID);
          if (item != null && existingIds.add(item.userID)) {
            newItems.add(item);
          }
          if (newItems.length >= _pageSize) break;
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
      final doc =
          await FirebaseFirestore.instance.collection('users').doc(userID).get();
      final data = doc.data() ?? const <String, dynamic>{};
      final nickname =
          (data['nickname'] ?? data['username'] ?? data['displayName'] ?? '')
              .toString()
              .trim();
      final fullName =
          '${(data['firstName'] ?? '').toString()} ${(data['lastName'] ?? '').toString()}'
              .trim();
      final avatarUrl = (data['avatarUrl'] ?? '').toString().trim();
      return ReshareUserItem(
        userID: userID,
        nickname: nickname,
        fullName: fullName,
        avatarUrl: avatarUrl,
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
