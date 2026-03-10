import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Modules/Education/PracticeExams/sinav_model.dart';

class SavedPracticeExamsController extends GetxController {
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
      final savedSnap = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('saved_practice_exams')
          .orderBy('timeStamp', descending: true)
          .get();

      savedExamIds.assignAll(savedSnap.docs.map((doc) => doc.id));
      if (savedSnap.docs.isEmpty) {
        savedExams.clear();
        return;
      }

      final docs = await Future.wait(
        savedSnap.docs.map(
          (doc) => FirebaseFirestore.instance
              .collection('practiceExams')
              .doc(doc.id)
              .get(),
        ),
      );

      final exams = <SinavModel>[];
      for (final doc in docs) {
        if (!doc.exists) continue;
        final data = doc.data() ?? const <String, dynamic>{};
        exams.add(
          SinavModel(
            docID: doc.id,
            cover: (data["cover"] ?? '') as String,
            sinavTuru: (data["sinavTuru"] ?? '') as String,
            timeStamp: (data["timeStamp"] ?? 0) as num,
            sinavAciklama: (data["sinavAciklama"] ?? '') as String,
            sinavAdi: (data["sinavAdi"] ?? '') as String,
            kpssSecilenLisans: (data["kpssSecilenLisans"] ?? '') as String,
            dersler: List<String>.from(data['dersler'] ?? const []),
            userID: (data["userID"] ?? '') as String,
            public: (data["public"] ?? false) as bool,
            taslak: (data["taslak"] ?? false) as bool,
            soruSayilari: List<String>.from(data['soruSayilari'] ?? const []),
            bitis: (data["bitis"] ?? 0) as num,
            bitisDk: (data["bitisDk"] ?? 0) as num,
          ),
        );
      }
      savedExams.assignAll(exams);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> toggleSavedExam(String docId) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final ref = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('saved_practice_exams')
        .doc(docId);

    if (savedExamIds.contains(docId)) {
      savedExamIds.remove(docId);
      savedExams.removeWhere((exam) => exam.docID == docId);
      await ref.delete();
      return;
    }

    savedExamIds.add(docId);
    await ref.set({
      'timeStamp': DateTime.now().millisecondsSinceEpoch,
    });
  }
}
