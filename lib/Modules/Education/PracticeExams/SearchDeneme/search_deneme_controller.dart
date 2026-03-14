import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Repositories/practice_exam_repository.dart';
import 'package:turqappv2/Core/Services/typesense_education_service.dart';
import 'package:turqappv2/Modules/Education/PracticeExams/sinav_model.dart';

class SearchDenemeController extends GetxController {
  final PracticeExamRepository _practiceExamRepository =
      PracticeExamRepository.ensure();
  final filteredList = <SinavModel>[].obs;
  final isLoading = false.obs;
  final TextEditingController searchController = TextEditingController();
  final FocusNode focusNode = FocusNode();
  int _searchToken = 0;

  @override
  void onInit() {
    super.onInit();
    Future.delayed(const Duration(milliseconds: 100), () {
      focusNode.requestFocus();
    });
  }

  Future<void> getData() async {
    await filterSearchResults(searchController.text);
  }

  Future<void> filterSearchResults(String query) async {
    final normalized = query.trim();
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
        entity: EducationTypesenseEntity.practiceExam,
        query: normalized,
        limit: 40,
      );
      if (token != _searchToken) return;
      final results = await _practiceExamRepository.fetchByIds(docIds);
      if (token != _searchToken) return;
      filteredList.assignAll(results);
    } finally {
      if (token == _searchToken) {
        isLoading.value = false;
      }
    }
  }

  @override
  void onClose() {
    searchController.dispose();
    focusNode.dispose();
    super.onClose();
  }
}
