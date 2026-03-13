import 'dart:developer';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Core/Repositories/practice_exam_repository.dart';
import 'package:turqappv2/Modules/Education/PracticeExams/sinav_model.dart';

class MyPracticeExamsController extends GetxController {
  final PracticeExamRepository _practiceExamRepository =
      PracticeExamRepository.ensure();

  final RxList<SinavModel> exams = <SinavModel>[].obs;
  final RxBool isLoading = true.obs;

  @override
  void onInit() {
    super.onInit();
    fetchExams();
  }

  Future<void> fetchExams({bool forceRefresh = false}) async {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (uid.isEmpty) {
      exams.clear();
      isLoading.value = false;
      return;
    }

    isLoading.value = true;
    try {
      final items = await _practiceExamRepository.fetchByOwner(
        uid,
        preferCache: !forceRefresh,
        forceRefresh: forceRefresh,
      );
      exams.assignAll(items);
    } catch (e) {
      log('MyPracticeExamsController.fetchExams error: $e');
      AppSnackbar('Hata', 'Sınavlar yüklenemedi.');
    } finally {
      isLoading.value = false;
    }
  }
}
