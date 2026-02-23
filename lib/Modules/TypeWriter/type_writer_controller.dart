import 'package:get/get.dart';

class TypewriterController extends GetxController {
  final String fullText;
  final RxString displayedText = ''.obs;
  int _currentIndex = 0;

  TypewriterController(this.fullText);

  @override
  void onInit() {
    super.onInit();
    _startTyping();
  }

  void _startTyping() async {
    while (_currentIndex < fullText.length) {
      await Future.delayed(Duration(milliseconds: 100));
      displayedText.value += fullText[_currentIndex];
      _currentIndex++;
    }
  }
}
