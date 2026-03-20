import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Services/user_summary_resolver.dart';
import 'package:turqappv2/Modules/Education/PracticeExams/sinav_model.dart';

class DenemeGridController extends GetxController {
  final UserSummaryResolver _userSummaryResolver = UserSummaryResolver.ensure();
  var avatarUrl = ''.obs;
  var nickname = ''.obs;
  var toplamBasvuru = 0.obs;
  var currentTime = DateTime.now().millisecondsSinceEpoch.obs;
  var examTime = 0.obs;
  var isLoadingProfile = true.obs;
  var isLoadingApplicants = false.obs;
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
    toplamBasvuru.value = model.participantCount.toInt();
    fetchProfileData(model.userID);
  }

  Future<void> fetchProfileData(String userID) async {
    isLoadingProfile.value = true;
    try {
      final user = await _userSummaryResolver.resolve(
        userID,
        preferCache: true,
      );
      avatarUrl.value = user?.avatarUrl ?? '';
      nickname.value = user?.preferredName ?? '';
    } catch (e) {
      debugPrint('[DenemeGrid] profile fetch failed: $e');
      avatarUrl.value = '';
      nickname.value = '';
    } finally {
      isLoadingProfile.value = false;
    }
  }
}
