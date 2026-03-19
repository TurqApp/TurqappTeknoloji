import 'dart:developer';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Repositories/answer_key_snapshot_repository.dart';
import 'package:turqappv2/Models/Education/booklet_model.dart';
import 'package:turqappv2/Modules/Education/AnswerKey/BookletPreview/booklet_preview.dart';

class SearchAnswerKeyController extends GetxController {
  final searchController = TextEditingController();
  final filteredList = <BookletModel>[].obs;
  final isLoading = false.obs;
  final AnswerKeySnapshotRepository _answerKeySnapshotRepository =
      AnswerKeySnapshotRepository.ensure();
  int _searchToken = 0;

  @override
  void onInit() {
    super.onInit();
    searchController.addListener(() {
      onSearchChanged(searchController.text);
    });
  }

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }

  Future<void> onSearchChanged(String value) async {
    final normalized = value.trim();
    final token = ++_searchToken;
    if (normalized.length < 2) {
      filteredList.clear();
      isLoading.value = false;
      return;
    }

    isLoading.value = true;
    try {
      final resource = await _answerKeySnapshotRepository.search(
        query: normalized,
        userId: FirebaseAuth.instance.currentUser?.uid ?? '',
        limit: 40,
        forceSync: true,
      );
      if (token != _searchToken) return;
      final results = resource.data ?? const <BookletModel>[];
      filteredList.assignAll(results);
    } catch (e) {
      log("Answer key typesense search error: $e");
      if (token == _searchToken) {
        filteredList.clear();
      }
    } finally {
      if (token == _searchToken) {
        isLoading.value = false;
      }
    }
  }

  void navigateToPreview(BookletModel model) {
    Get.to(() => BookletPreview(model: model));
  }
}
