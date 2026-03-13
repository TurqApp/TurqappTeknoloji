import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Repositories/test_repository.dart';
import 'package:turqappv2/Models/Education/tests_model.dart';

class SearchTestsController extends GetxController {
  final TestRepository _testRepository = TestRepository.ensure();
  final list = <TestsModel>[].obs;
  final filteredList = <TestsModel>[].obs;
  final searchController = TextEditingController();
  final focusNode = FocusNode();

  @override
  void onInit() {
    super.onInit();
    getData();
    Future.delayed(const Duration(milliseconds: 100), () {
      Get.focusScope?.requestFocus(focusNode);
    });
  }

  @override
  void onClose() {
    searchController.dispose();
    focusNode.dispose();
    super.onClose();
  }

  Future<void> getData() async {
    list.clear();
    filteredList.clear();

    list.assignAll(await _testRepository.fetchAll(preferCache: true));
    filteredList.assignAll(list);
  }

  void filterSearchResults(String query) {
    if (query.isEmpty) {
      filteredList.assignAll(list);
    } else {
      filteredList.assignAll(
        list.where(
          (test) =>
              test.aciklama.toLowerCase().contains(query.toLowerCase()) ||
              test.testTuru.toLowerCase().contains(query.toLowerCase()) ||
              test.dersler.any(
                (ders) => ders.toLowerCase().contains(query.toLowerCase()),
              ),
        ),
      );
    }
  }
}
