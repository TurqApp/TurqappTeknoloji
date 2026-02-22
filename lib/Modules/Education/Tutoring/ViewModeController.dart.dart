import 'package:get/get.dart';

class ViewModeController extends GetxController {
  var isGridView = false.obs;

  void toggleView() {
    isGridView.value = !isGridView.value;
  }
}
