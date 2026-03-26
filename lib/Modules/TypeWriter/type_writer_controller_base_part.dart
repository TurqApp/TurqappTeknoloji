part of 'type_writer_controller.dart';

abstract class _TypewriterControllerBase extends GetxController {
  _TypewriterControllerBase(String fullText)
      : _state = _TypewriterControllerState(fullText);

  final _TypewriterControllerState _state;

  @override
  void onInit() {
    super.onInit();
    _startTyping();
  }

  void _startTyping() async {
    while (_state.currentIndex < _state.fullText.length) {
      await Future.delayed(const Duration(milliseconds: 100));
      _state.displayedText.value += _state.fullText[_state.currentIndex];
      _state.currentIndex++;
    }
  }
}
