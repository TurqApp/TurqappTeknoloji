import 'dart:developer';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Core/Repositories/practice_exam_repository.dart';
import 'package:turqappv2/Modules/Education/PracticeExams/sinav_model.dart';

class SinavSonuclarimController extends GetxController {
  final PracticeExamRepository _practiceExamRepository =
      PracticeExamRepository.ensure();
  var list = <SinavModel>[].obs;
  var ustBar = true.obs;
  var isLoading = true.obs;
  final ScrollController scrollController = ScrollController();
  double _previousOffset = 0.0;

  @override
  void onInit() {
    super.onInit();
    scrolControlcu();
    findAndGetSinavlar();
  }

  void scrolControlcu() {
    scrollController.addListener(() {
      double currentOffset = scrollController.position.pixels;

      if (currentOffset > _previousOffset) {
        if (ustBar.value) ustBar.value = false;
      } else if (currentOffset < _previousOffset) {
        if (!ustBar.value) ustBar.value = true;
      }

      _previousOffset = currentOffset;
    });
  }

  Future<void> findAndGetSinavlar() async {
    isLoading.value = true;
    try {
      final currentUserID = FirebaseAuth.instance.currentUser!.uid;
      final exams = await _practiceExamRepository.fetchAnsweredByUser(
        currentUserID,
        preferCache: true,
      );
      list.assignAll(exams);
    } catch (e) {
      log("SinavSonuclarimController error: $e");
      AppSnackbar("Hata", "Sınav sonuçları yüklenemedi.");
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    scrollController.dispose();
    super.onClose();
  }
}
