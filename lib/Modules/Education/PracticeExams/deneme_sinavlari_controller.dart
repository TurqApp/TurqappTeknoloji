import 'dart:developer';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Core/Services/typesense_education_service.dart';
import 'package:turqappv2/Core/rozet_permissions.dart';
import 'package:turqappv2/Modules/Education/PracticeExams/sinav_model.dart';

class DenemeSinavlariController extends GetxController {
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
    getData();
    scrolControlcu();
    getOkulBilgisi();
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
      final doc = await FirebaseFirestore.instance
          .collection("users")
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .get();
      final rozet =
          (doc.data() ?? const <String, dynamic>{})["rozet"] as String?;
      okul.value =
          hasRozetPermission(currentRozet: rozet, minimumRozet: "Sarı");
    } catch (e) {
      AppSnackbar("Hata", "Okul bilgisi alınamadı.");
    }
  }

  SinavModel _fromDoc(QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SinavModel(
      docID: doc.id,
      cover: (data["cover"] ?? '') as String,
      sinavTuru: (data["sinavTuru"] ?? '') as String,
      timeStamp: (data["timeStamp"] ?? 0) as num,
      sinavAciklama: (data["sinavAciklama"] ?? '') as String,
      sinavAdi: (data["sinavAdi"] ?? '') as String,
      kpssSecilenLisans: (data["kpssSecilenLisans"] ?? '') as String,
      dersler: List<String>.from(data['dersler'] ?? []),
      userID: (data["userID"] ?? '') as String,
      public: (data["public"] ?? false) as bool,
      taslak: (data["taslak"] ?? false) as bool,
      soruSayilari: List<String>.from(data['soruSayilari'] ?? []),
      bitis: (data["bitis"] ?? 0) as num,
      bitisDk: (data["bitisDk"] ?? 0) as num,
    );
  }

  Future<void> getData() async {
    isLoading.value = true;
    hasMore.value = true;
    _lastDocument = null;
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection("practiceExams")
          .orderBy("timeStamp", descending: true)
          .limit(_pageSize)
          .get();

      list.assignAll(snapshot.docs.map(_fromDoc).toList());

      if (snapshot.docs.isNotEmpty) _lastDocument = snapshot.docs.last;
      if (snapshot.docs.length < _pageSize) hasMore.value = false;
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
      final snapshot = await FirebaseFirestore.instance
          .collection("practiceExams")
          .orderBy("timeStamp", descending: true)
          .startAfterDocument(_lastDocument!)
          .limit(_pageSize)
          .get();

      list.addAll(snapshot.docs.map(_fromDoc).toList());

      if (snapshot.docs.isNotEmpty) _lastDocument = snapshot.docs.last;
      if (snapshot.docs.length < _pageSize) hasMore.value = false;
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
    final orderedIds = docIds.where((id) => id.trim().isNotEmpty).toList();
    if (orderedIds.isEmpty) return const [];

    final byId = <String, SinavModel>{};
    const chunkSize = 10;
    for (var i = 0; i < orderedIds.length; i += chunkSize) {
      final end = (i + chunkSize > orderedIds.length)
          ? orderedIds.length
          : i + chunkSize;
      final chunk = orderedIds.sublist(i, end);
      final snapshot = await FirebaseFirestore.instance
          .collection("practiceExams")
          .where(FieldPath.documentId, whereIn: chunk)
          .get();
      for (final doc in snapshot.docs) {
        byId[doc.id] = _fromDoc(doc);
      }
    }
    return orderedIds.where(byId.containsKey).map((id) => byId[id]!).toList();
  }

  @override
  void onClose() {
    _searchDebounce?.cancel();
    scrollController.dispose();
    super.onClose();
  }
}
