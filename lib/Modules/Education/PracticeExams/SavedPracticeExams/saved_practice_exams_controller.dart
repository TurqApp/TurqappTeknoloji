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
    loadSavedExams();
  }

  Future<void> loadSavedExams() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    isLoading.value = true;
    try {
      final savedEntries = await _subcollectionRepository.getEntries(
        uid,
        subcollection: 'saved_practice_exams',
        orderByField: 'timeStamp',
        descending: true,
        preferCache: true,
        forceRefresh: false,
      );

      savedExamIds.assignAll(savedEntries.map((doc) => doc.id));
      if (savedEntries.isEmpty) {
        savedExams.clear();
        return;
      }

      final exams = await _practiceExamRepository.fetchByIds(
        savedEntries.map((doc) => doc.id).toList(growable: false),
        preferCache: true,
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
