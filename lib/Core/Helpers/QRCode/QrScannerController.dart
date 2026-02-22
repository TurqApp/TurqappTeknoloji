import 'package:get/get.dart';

class QrScannerController extends GetxController {
  var scannedUserID = "".obs;

  void onDetect(String code) {
    scannedUserID.value = code;
    Get.back();
  }
}
