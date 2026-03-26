part of 'page_line_bar.dart';

class PageLineBarController extends GetxController {
  final String pageName;
  PageLineBarController({required this.pageName});
  final _state = _PageLineBarControllerState();

  @override
  void onClose() {
    pageController.dispose();
    super.onClose();
  }
}
