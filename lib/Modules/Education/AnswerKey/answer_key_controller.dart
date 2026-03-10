import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Models/Education/booklet_model.dart';

class AnswerKeyController extends GetxController {
  var isLoading = false.obs;
  var isLoadingMore = false.obs;
  var hasMore = true.obs;
  var bookList = <BookletModel>[].obs;
  ScrollController scrollController = ScrollController();
  final RxDouble scrollOffset = 0.0.obs;
  DocumentSnapshot? _lastDocument;
  static const int _pageSize = 30;

  @override
  void onInit() {
    super.onInit();
    scrollController.addListener(_onScroll);
    refreshData();
  }

  void _onScroll() {
    if (scrollController.position.pixels >=
            scrollController.position.maxScrollExtent - 200 &&
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

  BookletModel _fromDoc(QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return BookletModel.fromMap(data, doc.id);
  }

  Future<void> refreshData() async {
    isLoading.value = true;
    hasMore.value = true;
    _lastDocument = null;
    try {
      final snapshots = await FirebaseFirestore.instance
          .collection("books")
          .orderBy("timeStamp", descending: true)
          .limit(_pageSize)
          .get();

      bookList.assignAll(snapshots.docs.map(_fromDoc).toList());

      if (snapshots.docs.isNotEmpty) _lastDocument = snapshots.docs.last;
      if (snapshots.docs.length < _pageSize) hasMore.value = false;

      log("Çekilen kitapçık sayısı: ${bookList.length}");
    } catch (e) {
      log("Veri çekme hatası: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadMore() async {
    if (_lastDocument == null || isLoadingMore.value || !hasMore.value) return;

    isLoadingMore.value = true;
    try {
      final snapshots = await FirebaseFirestore.instance
          .collection("books")
          .orderBy("timeStamp", descending: true)
          .startAfterDocument(_lastDocument!)
          .limit(_pageSize)
          .get();

      bookList.addAll(snapshots.docs.map(_fromDoc).toList());

      if (snapshots.docs.isNotEmpty) _lastDocument = snapshots.docs.last;
      if (snapshots.docs.length < _pageSize) hasMore.value = false;
    } catch (e) {
      log("AnswerKeyController.loadMore error: $e");
    } finally {
      isLoadingMore.value = false;
    }
  }
}
