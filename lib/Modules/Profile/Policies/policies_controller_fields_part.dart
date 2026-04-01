part of 'policies_controller.dart';

class _PoliciesControllerState {
  final privacyPolicy = ''.obs;
  final eula = ''.obs;
  final ad = ''.obs;
  final selection = 0.obs;
  final pageController = PageController(initialPage: 0);
}

extension PoliciesControllerFieldsPart on PoliciesController {
  RxString get privacyPolicy => _state.privacyPolicy;
  RxString get eula => _state.eula;
  RxString get ad => _state.ad;
  RxInt get selection => _state.selection;
  PageController get pageController => _state.pageController;
}
