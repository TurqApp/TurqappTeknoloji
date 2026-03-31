part of 'type_writer_controller.dart';

class _TypewriterControllerState {
  _TypewriterControllerState(this.fullText);
  final String fullText;
  final RxString displayedText = ''.obs;
  int currentIndex = 0;
}

extension TypewriterControllerFieldsPart on TypewriterController {
  String get fullText => _state.fullText;
  RxString get displayedText => _state.displayedText;
}
