part of 'interest_controller.dart';

const int interestsMinSelection = 3;
const int interestsMaxSelection = 15;

class _InterestsControllerState {
  final RxList<String> selecteds = <String>[].obs;
  final RxString searchText = ''.obs;
  final RxBool isReady = false.obs;
  final CurrentUserService userService = CurrentUserService.instance;
  bool selectionLimitShown = false;
}

extension InterestsControllerFieldsPart on InterestsController {
  RxList<String> get selecteds => _state.selecteds;
  RxString get searchText => _state.searchText;
  RxBool get isReady => _state.isReady;
  CurrentUserService get _userService => _state.userService;
  bool get _selectionLimitShown => _state.selectionLimitShown;
  set _selectionLimitShown(bool value) => _state.selectionLimitShown = value;
}
