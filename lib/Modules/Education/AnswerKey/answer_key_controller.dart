import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:turqappv2/Core/Repositories/answer_key_snapshot_repository.dart';
import 'package:turqappv2/Core/Repositories/booklet_repository.dart';
import 'package:turqappv2/Core/Services/CacheFirst/cached_resource.dart';
import 'package:turqappv2/Models/Education/booklet_model.dart';
import 'package:turqappv2/Modules/Education/AnswerKey/AnswerKeyContent/answer_key_content_controller.dart';
import 'package:turqappv2/Services/current_user_service.dart';

class AnswerKeyController extends GetxController {
  static AnswerKeyController ensure({bool permanent = false}) {
    final existing = maybeFind();
    if (existing != null) return existing;
    return Get.put(AnswerKeyController(), permanent: permanent);
  }

  static AnswerKeyController? maybeFind() {
    final isRegistered = Get.isRegistered<AnswerKeyController>();
    if (!isRegistered) return null;
    return Get.find<AnswerKeyController>();
  }

  static const String _listingSelectionPrefKeyPrefix =
      'pasaj_answer_key_listing_selection';
  final AnswerKeySnapshotRepository _answerKeySnapshotRepository =
      AnswerKeySnapshotRepository.ensure();
  final BookletRepository _bookletRepository = BookletRepository.ensure();
  var isLoading = false.obs;
  var isSearchLoading = false.obs;
  var isLoadingMore = false.obs;
  var hasMore = true.obs;
  final RxInt listingSelection = 0.obs;
  final RxBool listingSelectionReady = false.obs;
  var bookList = <BookletModel>[].obs;
  var searchResults = <BookletModel>[].obs;
  final RxString searchQuery = ''.obs;
  ScrollController scrollController = ScrollController();
  final RxDouble scrollOffset = 0.0.obs;
  DocumentSnapshot? _lastDocument;
  static const int _pageSize = 30;
  StreamSubscription<CachedResource<List<BookletModel>>>? _homeSnapshotSub;
  Timer? _searchDebounce;
  int _searchToken = 0;

  bool _sameBookletList(List<BookletModel> next) {
    return _sameBookletEntries(bookList, next);
  }

  bool _sameBookletEntries(
    List<BookletModel> current,
    List<BookletModel> next,
  ) {
    final currentKeys = current
        .map(
          (item) => [
            item.docID,
            item.baslik,
            item.sinavTuru,
            item.yayinEvi,
            item.basimTarihi,
            item.dil,
            item.timeStamp,
            item.viewCount,
            item.cover,
          ].join('::'),
        )
        .toList(growable: false);
    final nextKeys = next
        .map(
          (item) => [
            item.docID,
            item.baslik,
            item.sinavTuru,
            item.yayinEvi,
            item.basimTarihi,
            item.dil,
            item.timeStamp,
            item.viewCount,
            item.cover,
          ].join('::'),
        )
        .toList(growable: false);
    return listEquals(currentKeys, nextKeys);
  }

  String _listingSelectionKeyFor(String uid) =>
      '${_listingSelectionPrefKeyPrefix}_$uid';

  Future<void> _restoreListingSelection() async {
    final uid = CurrentUserService.instance.userId;
    if (uid.isEmpty) {
      listingSelection.value = 0;
      listingSelectionReady.value = true;
      return;
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      listingSelection.value =
          (prefs.getInt(_listingSelectionKeyFor(uid)) ?? 0) == 1 ? 1 : 0;
    } catch (_) {
      listingSelection.value = 0;
    } finally {
      listingSelectionReady.value = true;
    }
  }

  Future<void> _persistListingSelection() async {
    final uid = CurrentUserService.instance.userId;
    if (uid.isEmpty) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(
        _listingSelectionKeyFor(uid),
        listingSelection.value == 1 ? 1 : 0,
      );
    } catch (_) {}
  }

  bool get hasActiveSearch => searchQuery.value.trim().length >= 2;

  @override
  void onInit() {
    super.onInit();
    unawaited(_restoreListingSelection());
    scrollController.addListener(_onScroll);
    unawaited(_bootstrapInitialData());
  }

  void toggleListingSelection() {
    listingSelection.value = listingSelection.value == 0 ? 1 : 0;
    unawaited(_persistListingSelection());
  }

  Future<void> _bootstrapInitialData() async {
    await AnswerKeyContentController.warmSavedIdsForCurrentUser();
    final userId = CurrentUserService.instance.userId;
    _homeSnapshotSub?.cancel();
    _homeSnapshotSub = _answerKeySnapshotRepository
        .openHome(
          userId: userId,
          limit: _pageSize,
        )
        .listen(_applyHomeSnapshotResource);
  }

  void _onScroll() {
    scrollOffset.value = scrollController.offset;
    if (scrollController.position.pixels >=
            scrollController.position.maxScrollExtent - 200 &&
        !hasActiveSearch &&
        !isLoadingMore.value &&
        hasMore.value) {
      loadMore();
    }
  }

  List<String> lessons = [
    "LGS",
    "TYT",
    "AYT",
    "YDT",
    "YDS",
    "ALES",
    "DGS",
    "KPSS",
    "DUS",
    "TUS",
    "Dil",
    "Yazılım",
    "Spor",
    "Tasarım",
  ];

  final List<Color> colors = [
    Colors.deepPurple,
    Colors.indigo,
    Colors.teal,
    Colors.deepOrange,
    Colors.pink,
    Colors.cyan.shade700,
    Colors.blueGrey,
    Colors.pink.shade900,
  ];

  List<Color> lessonsColors = [
    Colors.lightBlue.shade700,
    Colors.pink.shade600,
    Colors.green.shade700,
    Colors.orange.shade700,
    Colors.red.shade800,
    Colors.indigo.shade800,
    Colors.lime.shade700,
    Colors.brown.shade800,
    Colors.blue.shade800,
    Colors.cyan.shade800,
    Colors.purple.shade700,
    Colors.teal.shade700,
    Colors.red.shade700,
    Colors.deepOrange.shade700,
  ];

  List<IconData> lessonsIcons = [
    Icons.psychology,
    Icons.school,
    Icons.library_books,
    Icons.translate,
    Icons.language,
    Icons.book_online,
    Icons.calculate,
    Icons.assignment,
    Icons.health_and_safety,
    Icons.medical_services,
    Icons.translate,
    Icons.code,
    Icons.sports_basketball,
    Icons.design_services,
  ];

  Future<void> refreshData() async {
    final hadLocalItems = bookList.isNotEmpty;
    if (!hadLocalItems) {
      isLoading.value = true;
    }
    hasMore.value = true;
    _lastDocument = null;
    try {
      final resource = await _answerKeySnapshotRepository.loadHome(
        userId: CurrentUserService.instance.userId,
        limit: _pageSize,
      );
      final items = resource.data ?? const <BookletModel>[];
      if (!_sameBookletList(items)) {
        bookList.assignAll(items);
      }
      hasMore.value = items.length >= _pageSize;
    } catch (_) {
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadMore() async {
    if (_lastDocument == null || isLoadingMore.value || !hasMore.value) return;

    isLoadingMore.value = true;
    try {
      final page = await _bookletRepository.fetchPage(
        startAfter: _lastDocument,
        limit: _pageSize,
      );
      bookList.addAll(page.items);
      _lastDocument = page.lastDocument;
      hasMore.value = page.hasMore;
    } catch (_) {
    } finally {
      isLoadingMore.value = false;
    }
  }

  void setSearchQuery(String query) {
    searchQuery.value = query.trim();
    _searchDebounce?.cancel();
    if (!hasActiveSearch) {
      isSearchLoading.value = false;
      searchResults.clear();
      _searchToken++;
      return;
    }

    final token = ++_searchToken;
    isSearchLoading.value = true;
    _searchDebounce = Timer(const Duration(milliseconds: 150), () async {
      await _searchFromTypesense(searchQuery.value, token);
    });
  }

  Future<void> _searchFromTypesense(String query, int token) async {
    final normalized = query.trim();
    try {
      final resource = await _answerKeySnapshotRepository.search(
        query: normalized,
        userId: CurrentUserService.instance.userId,
        limit: 40,
        forceSync: true,
      );
      if (token != _searchToken || searchQuery.value.trim() != normalized)
        return;

      final results = resource.data ?? const <BookletModel>[];
      if (token != _searchToken || searchQuery.value.trim() != normalized)
        return;
      if (!_sameBookletEntries(searchResults, results)) {
        searchResults.assignAll(results);
      }
    } catch (_) {
      if (token == _searchToken) {
        searchResults.clear();
      }
    } finally {
      if (token == _searchToken) {
        isSearchLoading.value = false;
      }
    }
  }

  void _applyHomeSnapshotResource(
    CachedResource<List<BookletModel>> resource,
  ) {
    final items = resource.data ?? const <BookletModel>[];
    if (items.isNotEmpty) {
      if (!_sameBookletList(items)) {
        bookList.assignAll(items);
      }
      hasMore.value = items.length >= _pageSize;
    }

    if (!resource.isRefreshing || items.isNotEmpty) {
      isLoading.value = false;
      return;
    }
    if (bookList.isEmpty) {
      isLoading.value = true;
    }
  }

  @override
  void onClose() {
    _homeSnapshotSub?.cancel();
    _searchDebounce?.cancel();
    scrollController.dispose();
    super.onClose();
  }
}
