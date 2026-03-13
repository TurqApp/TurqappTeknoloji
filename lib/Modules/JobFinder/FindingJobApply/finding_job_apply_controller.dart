import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Repositories/cv_repository.dart';

class FindingJobApplyController extends GetxController {
  final CvRepository _cvRepository = CvRepository.ensure();
  var cvVar = false.obs;
  var isFinding = false.obs;
  @override
  void onInit() {
    super.onInit();
    cvCheck();
  }

  Future<void> cvCheck() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      final data = await _cvRepository.getCv(uid, preferCache: true);
      cvVar.value = data != null;
      if (data != null) {
        isFinding.value = data["findingJob"] ?? false;
      }
    } catch (e) {
      print('CV kontrol hatası: $e');
    }
  }

  Future<void> toggleFindingJob() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || !cvVar.value) return;
    final next = !isFinding.value;
    isFinding.value = next;
    await _cvRepository.updateCvFields(uid, {"findingJob": next});
  }
}
