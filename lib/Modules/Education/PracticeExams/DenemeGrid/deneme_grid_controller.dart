import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Modules/Education/PracticeExams/sinav_model.dart';

class DenemeGridController extends GetxController {
  var pfImage = ''.obs;
  var nickname = ''.obs;
  var toplamBasvuru = 0.obs;
  var currentTime = DateTime.now().millisecondsSinceEpoch.obs;
  var examTime = 0.obs;
  var isLoadingProfile = true.obs;
  var isLoadingApplicants = true.obs;
  final int fifteenMinutes = 15 * 60 * 1000;
  String _initializedDocId = '';
  String _initializedUserId = '';

  void initData(SinavModel model) {
    if (_initializedDocId == model.docID &&
        _initializedUserId == model.userID) {
      return;
    }
    _initializedDocId = model.docID;
    _initializedUserId = model.userID;
    examTime.value = model.timeStamp.toInt();
    fetchProfileData(model.userID);
    fetchApplicantCount(model.docID);
  }

  Future<void> fetchProfileData(String userID) async {
    isLoadingProfile.value = true;
    try {
      final doc = await FirebaseFirestore.instance
          .collection("users")
          .doc(userID)
          .get();
      pfImage.value = doc.get("pfImage") ?? '';
      nickname.value = doc.get("nickname") ?? '';
    } catch (e) {
      debugPrint('[DenemeGrid] profile fetch failed for $userID: $e');
      pfImage.value = '';
      nickname.value = '';
    } finally {
      isLoadingProfile.value = false;
    }
  }

  Future<void> fetchApplicantCount(String docID) async {
    isLoadingApplicants.value = true;
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection("practiceExams")
          .doc(docID)
          .collection("Basvurular")
          .get();
      toplamBasvuru.value = snapshot.docs.length;
    } catch (e) {
      debugPrint('[DenemeGrid] applicant count fetch failed for $docID: $e');
      toplamBasvuru.value = 0;
    } finally {
      isLoadingApplicants.value = false;
    }
  }
}
