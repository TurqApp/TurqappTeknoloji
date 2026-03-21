import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Core/Repositories/practice_exam_repository.dart';
import 'package:turqappv2/Core/Services/user_summary_resolver.dart';
import 'package:turqappv2/Modules/Education/PracticeExams/SavedPracticeExams/saved_practice_exams_controller.dart';
import 'package:turqappv2/Modules/Education/PracticeExams/sinav_model.dart';
import 'package:turqappv2/Services/current_user_service.dart';

class DenemeSinaviPreviewController extends GetxController {
  final UserSummaryResolver _userSummaryResolver = UserSummaryResolver.ensure();
  final PracticeExamRepository _practiceExamRepository =
      PracticeExamRepository.ensure();
  var nickname = "".obs;
  var avatarUrl = "".obs;
  var dahaOnceBasvurdu = false.obs;
  var basvuranSayisi = 0.obs;
  var currentTime = DateTime.now().millisecondsSinceEpoch.obs;
  var showSucces = false.obs;
  var sinavaGirebilir = false.obs;
  var examTime = 0.obs;
  var isLoading = true.obs;
  var isInitialized = false.obs;
  var isSaved = false.obs;
  final int fifteenMinutes = 15 * 60 * 1000;

  final SinavModel model;
  String get _currentUserId => CurrentUserService.instance.userId;

  DenemeSinaviPreviewController({required this.model});

  @override
  void onInit() {
    super.onInit();
    examTime.value = model.timeStamp.toInt();
    fetchUserData();
    basvuruKontrol();
    getGecersizlikDurumu();
    syncSavedState();
  }

  Future<void> fetchUserData() async {
    try {
      final data = await _userSummaryResolver.resolve(
            model.userID,
            preferCache: true,
          ) ??
          _userSummaryResolver.resolveFromMaps(model.userID);
      nickname.value = data.preferredName;
      avatarUrl.value = data.avatarUrl;
    } catch (error) {
      AppSnackbar('common.error'.tr, 'practice.user_load_failed'.tr);
    } finally {
      isLoading.value = false;
      isInitialized.value = true;
    }
  }

  Future<void> getGecersizlikDurumu() async {
    try {
      final data = await _practiceExamRepository.fetchRawById(
        model.docID,
        preferCache: true,
      );

      if (data == null || !data.containsKey('gecersizSayilanlar')) {
        sinavaGirebilir.value = true;
        return;
      }

      List<String> gecersizSayilanlar = List<String>.from(
        data['gecersizSayilanlar'] ?? [],
      );
      sinavaGirebilir.value = !gecersizSayilanlar.contains(_currentUserId);
    } catch (error) {
      AppSnackbar('common.error'.tr, 'practice.invalidity_load_failed'.tr);
      sinavaGirebilir.value = true;
    }
  }

  Future<Map<String, num>?> _getLatestExamSummary() async {
    try {
      final uid = _currentUserId;
      if (uid.isEmpty) return null;
      final answers = await _practiceExamRepository.fetchAnswers(
        model.docID,
        preferCache: true,
      );
      final userAnswers = answers
          .where((doc) => (doc["userID"] ?? "").toString() == uid)
          .toList(growable: false);

      if (userAnswers.isEmpty) return null;

      Map<String, dynamic> latest = userAnswers.first;
      for (final doc in userAnswers) {
        final currentTs = (doc["timeStamp"] ?? 0) as num;
        final latestTs = (latest["timeStamp"] ?? 0) as num;
        if (currentTs > latestTs) {
          latest = doc;
        }
      }

      final latestId = (latest["_docId"] ?? latest["id"] ?? "").toString();
      if (latestId.isEmpty) return null;

      num dogru = 0;
      num yanlis = 0;
      num bos = 0;
      num net = 0;

      final results = await _practiceExamRepository.fetchLessonResults(
        model.docID,
        latestId,
        model.dersler,
      );
      for (final result in results) {
        dogru += result.dogru;
        yanlis += result.yanlis;
        bos += result.bos;
        net += result.net;
      }

      return {
        "dogru": dogru,
        "yanlis": yanlis,
        "bos": bos,
        "net": net,
      };
    } catch (_) {
      return null;
    }
  }

  Future<void> sinaviBitirAlert() async {
    FirebaseFirestore.instance
        .collection("practiceExams")
        .doc(model.docID)
        .collection("SinaviBitenler")
        .doc(DateTime.now().millisecondsSinceEpoch.toString())
        .set({
      "userID": _currentUserId,
      "timeStamp": DateTime.now().millisecondsSinceEpoch,
    });
    SetOptions(merge: true);

    final summary = await _getLatestExamSummary();
    final resultText = summary == null
        ? 'practice.result_unavailable'.tr
        : 'practice.result_summary'.trParams({
            'correct': '${summary["dogru"]?.toInt() ?? 0}',
            'wrong': '${summary["yanlis"]?.toInt() ?? 0}',
            'blank': '${summary["bos"]?.toInt() ?? 0}',
            'net': (summary["net"] ?? 0).toStringAsFixed(2),
          });

    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'practice.congrats_title'.tr,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 18,
                fontFamily: "MontserratBold",
              ),
            ),
            const SizedBox(height: 10),
            Text(
              resultText,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 15,
                fontFamily: "MontserratMedium",
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      Get.back(); // Close bottom sheet
                      Get.back(); // Close screen
                    },
                    child: Container(
                      height: 50,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                      ),
                      child: Text(
                        'common.ok'.tr,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontFamily: "MontserratBold",
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
    );
  }

  void showGecersizAlert() {
    AppSnackbar(
      'practice.removed_title'.tr,
      'practice.removed_body'.tr,
    );
  }

  Future<void> addBasvuru() async {
    try {
      final currentUid = _currentUserId;
      if (currentUid.isEmpty) return;
      final examRef = FirebaseFirestore.instance
          .collection("practiceExams")
          .doc(model.docID);
      final applicationRef = examRef.collection("Basvurular").doc(currentUid);
      var alreadyApplied = false;

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final applicationDoc = await transaction.get(applicationRef);
        if (applicationDoc.exists) {
          alreadyApplied = true;
          return;
        }

        final examDoc = await transaction.get(examRef);
        final currentCount =
            ((examDoc.data() ?? const <String, dynamic>{})['participantCount']
                    as num?) ??
                0;

        transaction.set(applicationRef, {
          "userID": currentUid,
          "timeStamp": DateTime.now().millisecondsSinceEpoch,
        });
        transaction.update(examRef, {
          "participantCount": currentCount.toInt() + 1,
        });
      });

      if (alreadyApplied) {
        AppSnackbar(
          'practice.applied_title'.tr,
          'practice.applied_body'.tr,
        );
      } else {
        showSucces.value = true;
        dahaOnceBasvurdu.value = true;
        basvuranSayisi.value = basvuranSayisi.value + 1;
      }
    } catch (error) {
      AppSnackbar('common.error'.tr, 'practice.apply_failed'.tr);
    }
  }

  Future<void> basvuruKontrol() async {
    try {
      basvuranSayisi.value = await _practiceExamRepository.fetchParticipantCount(
        model.docID,
        preferCache: true,
      );
      dahaOnceBasvurdu.value = await _practiceExamRepository.hasApplication(
        model.docID,
        _currentUserId,
      );
    } catch (error) {
      AppSnackbar('common.error'.tr, 'practice.application_check_failed'.tr);
    }
  }

  Future<void> refreshData() async {
    currentTime.value = DateTime.now().millisecondsSinceEpoch;
    await fetchUserData();
    await basvuruKontrol();
    await syncSavedState();
  }

  Future<void> syncSavedState() async {
    final savedController = Get.put(SavedPracticeExamsController());
    if (savedController.savedExamIds.isEmpty && !savedController.isLoading.value) {
      await savedController.loadSavedExams();
    }
    isSaved.value = savedController.savedExamIds.contains(model.docID);
  }

  Future<void> toggleSaved() async {
    final savedController = Get.put(SavedPracticeExamsController());
    await savedController.toggleSavedExam(model.docID);
    isSaved.value = savedController.savedExamIds.contains(model.docID);
  }
}
