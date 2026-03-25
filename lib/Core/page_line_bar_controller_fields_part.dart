part of 'page_line_bar.dart';

class _PageLineBarControllerState {
  final selection = 0.obs;
  final pageController = PageController();
}

extension PageLineBarControllerFieldsPart on PageLineBarController {
  RxInt get selection => _state.selection;
  PageController get pageController => _state.pageController;
}
