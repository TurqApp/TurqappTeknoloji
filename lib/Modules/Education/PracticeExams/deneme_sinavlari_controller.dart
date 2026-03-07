import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Modules/Education/PracticeExams/sinav_model.dart';

class DenemeSinavlariController extends GetxController {
  var list = <SinavModel>[].obs;
  var okul = false.obs;
  var showButons = false.obs;
  var ustBar = true.obs;
  var showOkulAlert = false.obs;
  var isLoading = true.obs;
  var isLoadingMore = false.obs;
  var hasMore = true.obs;
  final ScrollController scrollController = ScrollController();
  double _previousOffset = 0.0;
  final RxDouble scrollOffset = 0.0.obs;
  DocumentSnapshot? _lastDocument;
  static const int _pageSize = 30;

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
      final rozet = doc.get("rozet");
      okul.value = rozet == "Mavi";
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

  @override
  void onClose() {
    scrollController.dispose();
    super.onClose();
  }
}
