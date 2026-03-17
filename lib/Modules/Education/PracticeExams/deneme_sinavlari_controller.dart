import 'dart:developer';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Core/Repositories/practice_exam_repository.dart';
import 'package:turqappv2/Core/Repositories/user_repository.dart';
import 'package:turqappv2/Core/Services/typesense_education_service.dart';
import 'package:turqappv2/Core/rozet_permissions.dart';
import 'package:turqappv2/Modules/Education/PracticeExams/sinav_model.dart';

class DenemeSinavlariController extends GetxController {
  final UserRepository _userRepository = UserRepository.ensure();
  final PracticeExamRepository _practiceExamRepository =
      PracticeExamRepository.ensure();
  var list = <SinavModel>[].obs;
  var okul = false.obs;
  var showButons = false.obs;
  var ustBar = true.obs;
  var showOkulAlert = false.obs;
  var isLoading = true.obs;
  var isSearchLoading = false.obs;
  var isLoadingMore = false.obs;
  var hasMore = true.obs;
  final ScrollController scrollController = ScrollController();
  double _previousOffset = 0.0;
  final RxDouble scrollOffset = 0.0.obs;
  final RxString searchQuery = ''.obs;
  final RxList<SinavModel> searchResults = <SinavModel>[].obs;
  DocumentSnapshot? _lastDocument;
  static const int _pageSize = 30;
  Timer? _searchDebounce;
  int _searchToken = 0;

  bool get hasActiveSearch => searchQuery.value.trim().length >= 2;

  @override
  void onInit() {
    super.onInit();
    scrolControlcu();
    getOkulBilgisi();
    unawaited(_bootstrapInitialData());
  }

  Future<void> _bootstrapInitialData() async {
    try {
      final cached = await _practiceExamRepository.fetchPage(
        limit: _pageSize,
        cacheOnly: true,
      );
      if (cached.items.isNotEmpty) {
        list.assignAll(cached.items);
        _lastDocument = cached.lastDocument;
        hasMore.value = cached.hasMore;
        isLoading.value = false;
        await getData();
        return;
      }
    } catch (_) {}
    await getData();
  }

  void scrolControlcu() {
    scrollController.addListener(() {
      double currentOffset = scrollController.position.pixels;

      if (currentOffset > _previousOffset) {
        if (showButons.value) showButons.value = false;
        if (ustBar.value) ustBar.value = false;
      } else if (currentOffset < _previousOffset) {
        if (showButons.value) showButons.value = false;
        if (!ustBar.value) ustBar.value = true;
      }

      if (scrollController.position.pixels >=
              scrollController.position.maxScrollExtent - 200 &&
          !hasActiveSearch &&
          !isLoadingMore.value &&
          hasMore.value) {
        loadMore();
      }

      _previousOffset = currentOffset;
    });
  }

  Future<void> getOkulBilgisi() async {
    try {
      final data = await _userRepository.getUserRaw(
            FirebaseAuth.instance.currentUser!.uid,
          ) ??
          const <String, dynamic>{};
      final rozet = data["rozet"] as String?;
      okul.value =
          hasRozetPermission(currentRozet: rozet, minimumRozet: "Sarı");
    } catch (e) {
      AppSnackbar("Hata", "Okul bilgisi alınamadı.");
    }
  }

  Future<void> getData() async {
    final hadLocalItems = list.isNotEmpty;
    if (!hadLocalItems) {
      isLoading.value = true;
    }
    hasMore.value = true;
    _lastDocument = null;
    try {
      final page = await _practiceExamRepository.fetchPage(limit: _pageSize);
      list.assignAll(page.items);
      _lastDocument = page.lastDocument;
      hasMore.value = page.hasMore;
    } catch (e) {
      log("DenemeSinavlariController.getData error: $e");
      AppSnackbar("Hata", "Veriler yüklenemedi.");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadMore() async {
    if (_lastDocument == null || isLoadingMore.value || !hasMore.value) return;

    isLoadingMore.value = true;
    try {
      final page = await _practiceExamRepository.fetchPage(
        startAfter: _lastDocument,
        limit: _pageSize,
      );
      list.addAll(page.items);
      _lastDocument = page.lastDocument;
      hasMore.value = page.hasMore;
    } catch (e) {
      log("DenemeSinavlariController.loadMore error: $e");
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
      final docIds =
          await TypesenseEducationSearchService.instance.searchDocIds(
        entity: EducationTypesenseEntity.practiceExam,
        query: normalized,
        limit: 40,
      );
      if (token != _searchToken || searchQuery.value.trim() != normalized)
        return;

      final results = await _fetchByDocIds(docIds);
      if (token != _searchToken || searchQuery.value.trim() != normalized)
        return;
      searchResults.assignAll(results);
    } catch (e) {
      log("Deneme typesense search error: $e");
      if (token == _searchToken) {
        searchResults.clear();
      }
    } finally {
      if (token == _searchToken) {
        isSearchLoading.value = false;
      }
    }
  }

  Future<List<SinavModel>> _fetchByDocIds(List<String> docIds) async {
    return _practiceExamRepository.fetchByIds(docIds);
  }

  @override
  void onClose() {
    _searchDebounce?.cancel();
    scrollController.dispose();
    super.onClose();
  }
}
