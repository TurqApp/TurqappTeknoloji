import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Repositories/booklet_repository.dart';
import 'package:turqappv2/Core/Services/typesense_education_service.dart';
import 'package:turqappv2/Models/Education/booklet_model.dart';
import 'package:turqappv2/Modules/Education/AnswerKey/BookletPreview/booklet_preview.dart';

class SearchAnswerKeyController extends GetxController {
  final searchController = TextEditingController();
  final filteredList = <BookletModel>[].obs;
  final isLoading = false.obs;
  final BookletRepository _bookletRepository = BookletRepository.ensure();
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
      final docIds =
          await TypesenseEducationSearchService.instance.searchDocIds(
        entity: EducationTypesenseEntity.answerKey,
        query: normalized,
        limit: 40,
      );
      if (token != _searchToken) return;
      final results = await _bookletRepository.fetchByIds(docIds);
      if (token != _searchToken) return;
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
