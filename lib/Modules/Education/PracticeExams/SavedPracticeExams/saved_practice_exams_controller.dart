import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Repositories/practice_exam_repository.dart';
import 'package:turqappv2/Core/Repositories/user_subcollection_repository.dart';
import 'package:turqappv2/Modules/Education/PracticeExams/sinav_model.dart';

class SavedPracticeExamsController extends GetxController {
  final PracticeExamRepository _practiceExamRepository =
      PracticeExamRepository.ensure();
  final UserSubcollectionRepository _subcollectionRepository =
      UserSubcollectionRepository.ensure();
  final RxList<String> savedExamIds = <String>[].obs;
  final RxList<SinavModel> savedExams = <SinavModel>[].obs;
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    unawaited(_bootstrapData());
  }

  Future<void> _bootstrapData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final savedEntries = await _subcollectionRepository.getEntries(
      uid,
      subcollection: 'saved_practice_exams',
      orderByField: 'timeStamp',
      descending: true,
      cacheOnly: true,
    );
    savedExamIds.assignAll(savedEntries.map((doc) => doc.id));
    if (savedEntries.isNotEmpty) {
      final exams = await _practiceExamRepository.fetchByIds(
        savedEntries.map((doc) => doc.id).toList(growable: false),
        cacheOnly: true,
      );
      if (exams.isNotEmpty) {
        savedExams.assignAll(exams);
        isLoading.value = false;
        await loadSavedExams(silent: true, forceRefresh: true);
        return;
      }
    }
    await loadSavedExams();
  }

  Future<void> loadSavedExams({
    bool silent = false,
    bool forceRefresh = false,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    if (!silent || savedExams.isEmpty) {
      isLoading.value = true;
    }
    try {
      final savedEntries = await _subcollectionRepository.getEntries(
        uid,
        subcollection: 'saved_practice_exams',
        orderByField: 'timeStamp',
        descending: true,
        preferCache: !forceRefresh,
        forceRefresh: forceRefresh,
      );

      savedExamIds.assignAll(savedEntries.map((doc) => doc.id));
      if (savedEntries.isEmpty) {
        savedExams.clear();
        return;
      }

      final exams = await _practiceExamRepository.fetchByIds(
        savedEntries.map((doc) => doc.id).toList(growable: false),
        preferCache: !forceRefresh,
      );
      savedExams.assignAll(exams);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> toggleSavedExam(String docId) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    if (savedExamIds.contains(docId)) {
      savedExamIds.remove(docId);
      savedExams.removeWhere((exam) => exam.docID == docId);
      await _subcollectionRepository.deleteEntry(
        uid,
        subcollection: 'saved_practice_exams',
        docId: docId,
      );
      return;
    }

    savedExamIds.add(docId);
    await _subcollectionRepository.upsertEntry(
      uid,
      subcollection: 'saved_practice_exams',
      docId: docId,
      data: {
        'timeStamp': DateTime.now().millisecondsSinceEpoch,
      },
    );
  }
}
