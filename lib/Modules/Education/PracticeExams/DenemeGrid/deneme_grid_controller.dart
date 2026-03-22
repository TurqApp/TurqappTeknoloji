import 'package:get/get.dart';
import 'package:turqappv2/Modules/Education/PracticeExams/sinav_model.dart';

class DenemeGridController extends GetxController {
  static DenemeGridController ensure({
    required String tag,
    bool permanent = false,
  }) {
    final existing = maybeFind(tag: tag);
    if (existing != null) return existing;
    return Get.put(DenemeGridController(), tag: tag, permanent: permanent);
  }

  static DenemeGridController? maybeFind({required String tag}) {
    final isRegistered = Get.isRegistered<DenemeGridController>(tag: tag);
    if (!isRegistered) return null;
    return Get.find<DenemeGridController>(tag: tag);
  }

  var toplamBasvuru = 0.obs;
  var currentTime = DateTime.now().millisecondsSinceEpoch.obs;
  var examTime = 0.obs;
  final int fifteenMinutes = 15 * 60 * 1000;
  String _initializedDocId = '';

  void initData(SinavModel model) {
    if (_initializedDocId == model.docID) {
      return;
    }
    _initializedDocId = model.docID;
    examTime.value = model.timeStamp.toInt();
    toplamBasvuru.value = model.participantCount.toInt();
  }
}
