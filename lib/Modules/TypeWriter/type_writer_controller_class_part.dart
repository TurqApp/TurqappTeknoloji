part of 'type_writer_controller.dart';

class TypewriterController extends GetxController {
  TypewriterController(String fullText)
      : _state = _TypewriterControllerState(fullText);

  final _TypewriterControllerState _state;

  @override
  void onInit() {
    super.onInit();
    _startTyping();
  }

  void _startTyping() async {
    while (_currentIndex < fullText.length) {
      await Future.delayed(const Duration(milliseconds: 100));
      displayedText.value += fullText[_currentIndex];
      _currentIndex++;
    }
  }
}
