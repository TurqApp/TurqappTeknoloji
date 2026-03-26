part of 'interest_controller.dart';

class InterestsController extends GetxController {
  final RxList<String> selecteds = <String>[].obs;
  final RxString searchText = "".obs;
  final RxBool isReady = false.obs;
  final CurrentUserService _userService = CurrentUserService.instance;
  static const int minSelection = 3;
  static const int maxSelection = 15;
  bool _selectionLimitShown = false;

  @override
  void onInit() {
    super.onInit();
    _handleInterestsOnInit();
  }
}
