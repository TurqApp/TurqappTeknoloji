import 'package:get/get.dart';
import 'package:turqappv2/Modules/Education/PracticeExams/sinav_model.dart';

class DenemeGridController extends GetxController {
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
