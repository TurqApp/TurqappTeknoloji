import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Core/Repositories/practice_exam_repository.dart';
import 'package:turqappv2/Modules/Education/PracticeExams/sinav_model.dart';

class SearchDenemeController extends GetxController {
  final PracticeExamRepository _practiceExamRepository =
      PracticeExamRepository.ensure();
  var list = <SinavModel>[].obs;
  var filteredList = <SinavModel>[].obs;
  var isLoading = true.obs;
  final TextEditingController searchController = TextEditingController();
  final FocusNode focusNode = FocusNode();

  @override
  void onInit() {
    super.onInit();
    getData();
    Future.delayed(const Duration(milliseconds: 100), () {
      focusNode.requestFocus();
    });
  }

  Future<void> getData() async {
    isLoading.value = true;
    try {
      list.assignAll(await _practiceExamRepository.fetchAll(preferCache: true));
      filteredList.assignAll(list);
    } catch (e) {
      AppSnackbar("Hata", "Veriler yüklenemedi.");
    } finally {
      isLoading.value = false;
    }
  }

  void filterSearchResults(String query) {
    if (query.isEmpty) {
      filteredList.assignAll(list);
    } else {
      filteredList.assignAll(
        list.where((test) {
          return test.sinavAciklama.toLowerCase().contains(
                    query.toLowerCase(),
                  ) ||
              test.sinavTuru.toLowerCase().contains(query.toLowerCase()) ||
              test.sinavAdi.toLowerCase().contains(query.toLowerCase()) ||
              test.dersler.any(
                (ders) => ders.toLowerCase().contains(query.toLowerCase()),
              );
        }).toList(),
      );
    }
  }

  @override
  void onClose() {
    searchController.dispose();
    focusNode.dispose();
    super.onClose();
  }
}
