part of 'page_line_bar.dart';

class PageLineBarController extends GetxController {
  final String pageName;
  PageLineBarController({required this.pageName});

  @override
  void onClose() {
    pageController.dispose();
    super.onClose();
  }
}

class _PageLineBarControllerState {
  final selection = 0.obs;
  final pageController = PageController();
}

final _pageLineBarControllerStates = Expando<_PageLineBarControllerState>(
  'pageLineBarControllerState',
);

extension PageLineBarControllerFieldsPart on PageLineBarController {
  _PageLineBarControllerState get _state =>
      _pageLineBarControllerStates[this] ??= _PageLineBarControllerState();
  RxInt get selection => _state.selection;
  PageController get pageController => _state.pageController;
}
