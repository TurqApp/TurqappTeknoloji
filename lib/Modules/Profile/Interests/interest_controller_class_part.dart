part of 'interest_controller.dart';

class InterestsController extends GetxController {
  static InterestsController ensure({
    String? tag,
    bool permanent = false,
  }) {
    final existing = maybeFind(tag: tag);
    if (existing != null) return existing;
    return Get.put(
      InterestsController(),
      tag: tag,
      permanent: permanent,
    );
  }

  static InterestsController? maybeFind({String? tag}) {
    final isRegistered = Get.isRegistered<InterestsController>(tag: tag);
    if (!isRegistered) return null;
    return Get.find<InterestsController>(tag: tag);
  }

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
