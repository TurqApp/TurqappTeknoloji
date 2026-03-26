part of 'my_tutorings_controller.dart';

class MyTutoringsController extends GetxController {
  static MyTutoringsController ensure({
    String? tag,
    bool permanent = false,
  }) {
    final existing = maybeFind(tag: tag);
    if (existing != null) return existing;
    return Get.put(
      MyTutoringsController(),
      tag: tag,
      permanent: permanent,
    );
  }

  static MyTutoringsController? maybeFind({String? tag}) {
    final isRegistered = Get.isRegistered<MyTutoringsController>(tag: tag);
    if (!isRegistered) return null;
    return Get.find<MyTutoringsController>(tag: tag);
  }

  static const Duration _silentRefreshInterval = Duration(minutes: 5);

  final UserSummaryResolver _userSummaryResolver = UserSummaryResolver.ensure();
  final TutoringRepository _tutoringRepository = TutoringRepository.ensure();
  final RxList<TutoringModel> myTutorings = <TutoringModel>[].obs;
  final RxMap<String, Map<String, dynamic>> users =
      <String, Map<String, dynamic>>{}.obs;
  final RxString errorMessage = ''.obs;
  final RxList<TutoringModel> activeTutorings = <TutoringModel>[].obs;
  final RxList<TutoringModel> expiredTutorings = <TutoringModel>[].obs;
  final PageController pageController = PageController();
  final RxInt selection = 0.obs;
  final RxBool isLoading = true.obs;

  @override
  void onInit() {
    super.onInit();
    _handleMyTutoringsInit();
  }

  @override
  void onClose() {
    _handleMyTutoringsClose();
    super.onClose();
  }
}
