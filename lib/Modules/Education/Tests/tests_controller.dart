import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Models/Education/tests_model.dart';

class TestsController extends GetxController {
  final list = <TestsModel>[].obs;
  final showButtons = false.obs;
  final ustBar = true.obs;
  final scrollController = ScrollController();
  final _previousOffset = 0.0.obs;
  final isLoading = true.obs;
  final isLoadingMore = false.obs;
  final hasMore = true.obs;
  final RxDouble scrollOffset = 0.0.obs;
  DocumentSnapshot? _lastDocument;
  static const int _pageSize = 30;

  @override
  void onInit() {
    super.onInit();
    getData();
    _scrollControl();
  }

  @override
  void onClose() {
    scrollController.dispose();
    super.onClose();
  }

  void _scrollControl() {
    scrollController.addListener(() {
      final currentOffset = scrollController.position.pixels;

      if (currentOffset > _previousOffset.value) {
        if (showButtons.value) {
          showButtons.value = false;
        }
        ustBar.value = false;
      } else if (currentOffset < _previousOffset.value) {
        if (showButtons.value) {
          showButtons.value = false;
        }
        ustBar.value = true;
      }

      if (currentOffset >= scrollController.position.maxScrollExtent - 200 &&
          !isLoadingMore.value &&
          hasMore.value) {
        loadMore();
      }

      _previousOffset.value = currentOffset;
    });
  }

  TestsModel _fromDoc(QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TestsModel(
      userID: (data["userID"] ?? '') as String,
      timeStamp: (data["timeStamp"] ?? '') as String,
      aciklama: (data["aciklama"] ?? '') as String,
      dersler: List<String>.from(data['dersler'] ?? []),
      img: (data["img"] ?? '') as String,
      docID: doc.id,
      paylasilabilir: (data["paylasilabilir"] ?? false) as bool,
      testTuru: (data["testTuru"] ?? '') as String,
      taslak: (data["taslak"] ?? false) as bool,
    );
  }

  Future<void> getData() async {
    isLoading.value = true;
    hasMore.value = true;
    _lastDocument = null;
    try {
      final snap = await FirebaseFirestore.instance
          .collection("Testler")
          .where("paylasilabilir", isEqualTo: true)
          .orderBy("timeStamp", descending: true)
          .limit(_pageSize)
          .get();

      list.assignAll(snap.docs.map(_fromDoc).toList());

      if (snap.docs.isNotEmpty) _lastDocument = snap.docs.last;
      if (snap.docs.length < _pageSize) hasMore.value = false;
    } catch (e) {
      log("TestsController.getData error: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadMore() async {
    if (_lastDocument == null || isLoadingMore.value || !hasMore.value) return;

    isLoadingMore.value = true;
    try {
      final snap = await FirebaseFirestore.instance
          .collection("Testler")
          .where("paylasilabilir", isEqualTo: true)
          .orderBy("timeStamp", descending: true)
          .startAfterDocument(_lastDocument!)
          .limit(_pageSize)
          .get();

      list.addAll(snap.docs.map(_fromDoc).toList());

      if (snap.docs.isNotEmpty) _lastDocument = snap.docs.last;
      if (snap.docs.length < _pageSize) hasMore.value = false;
    } catch (e) {
      log("TestsController.loadMore error: $e");
    } finally {
      isLoadingMore.value = false;
    }
  }
}
